import numpy as np 
import geopandas as gpd
from src.python.settings import PATH

import rasterio
from rasterio.mask import mask
from rasterio.merge import merge
import src.python.utils as utils

from src.python.downloader import *

import matplotlib.pyplot as plt


class Processing:

    def __init__(self, city: str, start_date, end_date):
        self.city = city
        self.start_date = start_date
        self.end_date = end_date

    def download(self, path: str):
        # 2.1 - OpenStreeMap: 
        osmd = OSMDownloader(self.city)
        # if city.shp exists, it will not download it again
        graph_city, bbox, polygon = osmd.download(path=path)
        polygon = gpd.read_file(f'{path}/city.shp').geometry

        # 2.2 - Landsat Collection 2 Level 2
        # username = os.environ.get('LANDSAT_USERNAME')
        # token = os.environ.get('LANDSAT_TOKEN')
        username='Matteo22'
        token='C7djdvyQ9PEJ6dc232fj!X_8N7rQ4KdhihGDq36L1n7wXiKTKFBAiYqhUjIM!gCG'
        ld = LandsatDownloader(username=username, token=token)
        ld.login()
        ld.download(
            xmin=bbox['xmin'],
            ymin=bbox['ymin'], 
            xmax=bbox['xmax'],
            ymax=bbox['ymax'],
            start=self.start_date,
            end=self.end_date,
            path=path
        )

        #2.3 - OpenTopography
        if not os.path.exists(f'{path}/dem.tif'):
            dd = DemDownloader()
            dd.download(
                xmin=np.floor(bbox['xmin']),
                ymin=np.floor(bbox['ymin']), 
                xmax=np.ceil(bbox['xmax']),
                ymax=np.ceil(bbox['ymax']),
                path=f'{path}/dem.tif'
        )

    def process(self, path: str):
        self.download(path)
        filenames = []
        for filename in os.listdir(path):
            if 'ST_B' in filename:
                filenames.append(filename)
        self._compute_lst_mean(filenames)
        utils.project(
            path_src=f'{path}/dem.tif', 
            path_dst=f'{path}/lst_mean.tif', 
            path_out=f'{path}/dem_reproject.tif'
        )

        reproject = rasterio.open(f'{path}/dem_reproject.tif')
        # print(reproject.read(1))
        # sys.exit()

        lst_mean = rasterio.open(f'{path}/lst_mean.tif')
        shape = lst_mean.shape  
        crs = lst_mean.crs
        transform = lst_mean.transform
        lst_mean = lst_mean.read(1)

        urban_areas_path = f'{path}/urban_areas.shp'
        urban_areas = gpd.read_file(urban_areas_path)
        urban_areas = urban_areas.to_crs(crs)
        urban_mask = rasterio.features.rasterize(
            [(geom, 1) for geom in urban_areas.geometry],
            out_shape=shape,
            transform=transform,
            fill=0,
            dtype=np.uint8
        )

        natural_areas = gpd.read_file(f'{path}/natural_areas.shp')
        semi_natural_areas = gpd.read_file(f'{path}/semi_natural_areas.shp')
        rural_areas = pd.concat([natural_areas, semi_natural_areas], ignore_index=True)
        rural_areas = rural_areas.to_crs(crs)
        reference_areas = rural_areas
        reference_areas = rural_areas.dissolve()
        # Rasterize the reference areas
        reference_mask = rasterio.features.rasterize(
            [(geom, 1) for geom in reference_areas.geometry],
            out_shape=shape,
            transform=transform,
            fill=0,
            dtype=np.uint8
        )

        # Clean overlaps between urban and reference areas
        urban_mask = np.ma.masked_where(reference_mask == 1, urban_mask)

        # Buffer urban areas by 100m
        buffered_urban_areas = urban_areas.buffer(100)
        buffered_urban_areas = np.where(
            buffered_urban_areas == 0, np.nan, buffered_urban_areas
        )
        urban_buffer_mask = rasterio.features.rasterize(
            [(geom, 1) for geom in buffered_urban_areas],
            out_shape=shape,
            transform=transform,
            fill=0,
            dtype=np.uint8
        )

        # Mask reference areas to excluSUHIsde 100m buffer zone
        reference_mask = np.ma.masked_where(urban_mask == 1, urban_buffer_mask)

        with rasterio.open(f'{path}/dem_reproject.tif') as dem:
            
            dem_profile = dem.profile  
            dem = dem.read(1)
        #     print(dem)
        #     plt.imshow(dem)
        #     plt.show()
        #     max_altitude = np.max(dem)   
        #     min_altitude = np.min(dem)
            dem_urb = np.ma.masked_where(urban_mask == 0, dem)
        #     dem_urb = np.where(np.isnan(dem_urb), 0, dem_urb)
        max_altitude = np.max(dem_urb)   
        min_altitude = np.min(dem_urb)
        lst_bands = self.altitude_bands_processing(dem, lst_mean, max_altitude, min_altitude, dem_profile)
        thermal_anomalies = self.thermal_anomaly(lst_bands, urban_mask, reference_mask, dem_profile)
        SUHIs = self.SUHI(lst_bands, dem_profile)

        # merge thermal anomalies
        thermal_anomalies_files = [f for f in os.listdir(path) if f.startswith('thermal_anomaly_band_')]
        thermal_anomalies = [rasterio.open(f'{path}/{f}') for f in thermal_anomalies_files]
        mosaic, out_transform = merge(thermal_anomalies)
        out_meta = thermal_anomalies[0].meta.copy()
        out_meta.update({
            "driver": "GTiff",
            "height": mosaic.shape[1],
            "width": mosaic.shape[2],
            "transform": out_transform
        })

        with rasterio.open(f'{path}/thermal_anomalies.tif', 'w', **dem_profile) as f:
            f.write(mosaic)

        # merge SUHIs
        SUHI_files = [f for f in os.listdir(path) if f.startswith('SUHI_band_')]
        SUHIs = [rasterio.open(f'{path}/{f}') for f in SUHI_files]
        mosaic, out_transform = merge(SUHIs)
        out_meta = SUHIs[0].meta.copy()
        out_meta.update({
            "driver": "GTiff",
            "height": mosaic.shape[1],
            "width": mosaic.shape[2],
            "transform": out_transform
        })

        with rasterio.open(f'{path}/SUHIs.tif', 'w', **dem_profile) as f:
            f.write(mosaic)

        # merge LST bands
        lst_bands_files = [f for f in os.listdir(path) if f.startswith('lst_mean_')]
        lst_bands = [rasterio.open(f'{path}/{f}') for f in lst_bands_files]
        mosaic, out_transform = merge(lst_bands)
        out_meta = lst_bands[0].meta.copy()
        out_meta.update({
            "driver": "GTiff",
            "height": mosaic.shape[1],
            "width": mosaic.shape[2],
            "transform": out_transform
        })

        with rasterio.open(f'{path}/lst_bands.tif', 'w', **dem_profile) as f:
            f.write(mosaic)

    @staticmethod
    def mask(to_mask, mask, inverse: bool = False):
        if inverse:
             np.ma.masked_array(mask == 1, to_mask)
        return np.ma.masked_array(mask == 0, to_mask)

    @staticmethod
    def rasterize(
        shp_file: gpd.GeoDataFrame,
        # path: str,
        # crs: str,
        out_shape,
        out_transform
    ):
        # shp_file = gpd.read_file(path)
        # shp_file = shp_file.to_crs(crs)
        shp_raster = rasterio.features.rasterize(
            [(geom, 1) for geom in shp_file.geometry],
            out_shape=out_shape,
            transform=out_transform,
            fill=0,
            dtype=np.uint8
        )
        return shp_raster
    
    @staticmethod
    def altitude_bands_processing(dem, lst, max_altitude, min_altitude, profile):
        # Calculate altitude bands
        altitude_band_height = 100
        altitude_bands = round((max_altitude - min_altitude) / altitude_band_height)
        lst_bands = []
        min_alt = round(min_altitude, -1)
        max_alt = min_alt + altitude_band_height
        for i in range(1, altitude_bands + 1):
            
            dem_band = np.copy(dem).astype(np.float32)
            dem_band[dem_band > max_alt] = 0
            dem_band[dem_band <= min_alt] = 0

            lst_masked = np.ma.masked_where(dem_band == 0, lst)
   
            lst_bands.append(lst_masked)

            with rasterio.open(f'{PATH}/lst_mean_{i}.tif', 'w', **profile) as dst:
                dst.write(lst_masked, 1)
            
            min_alt += altitude_band_height
            max_alt += altitude_band_height
        return lst_bands
    
    @staticmethod
    def thermal_anomaly(lst_bands, urban_mask, reference_mask, profile):
        thermal_anomalies = []
        for i, lst_band in enumerate(lst_bands):
            urban_masked = np.ma.masked_where(urban_mask == 0, lst_band)
            mean_temp_urban = np.nanmean(np.copy(urban_masked))
        
            rural_masked = np.copy(np.ma.masked_where(reference_mask == 0, lst_band))
            rural_masked = np.ma.masked_where(urban_mask != 0, rural_masked)
            mean_temp_rural = np.nanmean(rural_masked)

            thermal_anomaly = lst_band - mean_temp_rural
            thermal_anomalies.append(thermal_anomaly)
            with rasterio.open(f'{PATH}/thermal_anomaly_band_{i}.tif', 'w', **profile) as dst:
                dst.write(thermal_anomaly, 1)

        return thermal_anomalies
    
    @staticmethod
    def SUHI(lst_bands, profile):
        SUHIs = []
        for i, lst_band in enumerate(lst_bands):
            LSTmax = np.nanmax(lst_band)
            LSTmin = np.nanmin(lst_band)
            SUHI = (lst_band  - LSTmin) / (LSTmax - LSTmin)   
            SUHIs.append(SUHI)
            with rasterio.open(f'{PATH}/SUHI_band_{i}.tif', 'w', **profile) as dst:
                dst.write(SUHI, 1)
        return SUHIs       
            
    @staticmethod
    def _compute_lst_mean(filenames):
        polygon = gpd.read_file(f'{PATH}/city.shp').geometry
        lsts = []
        for filename in filenames:
            scene = filename[0:40]
            sensor = filename[2:4]

            with rasterio.open(f'{PATH}/{scene}_QA_PIXEL.TIF') as f:
                profile = f.profile
                crst = utils.CRSTransformer(from_crs=polygon.crs, to_crs=f.crs)
                polygon_trans = polygon.apply(crst.transform)
                xmin, ymin, xmax, ymax = polygon_trans.total_bounds
                polygon_trans = [{"type": "Polygon", "coordinates": [
                    [[xmin, ymin], [xmax, ymin], [xmax, ymax], [xmin, ymax], [xmin, ymin]]]}
                ]
                qa, transform = mask(f, polygon_trans, crop=True)
                qa = qa[0]
                qa = qa.astype(float)
            
            if sensor in ['08', '09']:
                qa[qa!=21824] = np.nan
                with rasterio.open(f'{PATH}/{scene}_ST_B10.TIF') as f:
                    st, _ = mask(f, polygon_trans, crop=True)
                    st = st[0]
                    st = st.astype(float)
            else:
                qa[qa!=5440] = np.nan
                with rasterio.open(f'{PATH}/{scene}_ST_B6.TIF') as f:
                    st, _ = mask(f, polygon_trans, crop=True)
                    st = st[0]
                    st = st.astype(float)

            if np.sum(np.isnan(qa))/qa.size < 0.7:
                lst = ((st * 0.00341802) + 149.0) - 273.15
                lst = np.ma.masked_array(lst, np.isnan(qa))
                lsts.append(lst)

        lst = np.ma.stack(lsts, axis=0)
        lst_mean = lst.mean(axis=0).filled(np.nan)

        profile.update(
            dtype=lst_mean.dtype,
            nodata=np.nan, 
            width=lst_mean.shape[1],
            height=lst_mean.shape[0], 
            transform=transform
        )

        with rasterio.open(f'{PATH}/lst_mean.tif', 'w', **profile) as f:
            f.write(lst_mean, 1)

        return lst_mean
