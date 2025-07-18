import rasterio
from pyproj import Transformer
from shapely.geometry import Point
from rasterio.warp import reproject, Resampling
from datetime import datetime


class CRSTransformer:
    def __init__(self, to_crs, from_crs='EPSG:4326'):
        self.transformer = Transformer.from_crs(from_crs, to_crs, always_xy=True)

    def transform(self, point):
        lon, lat = point.x, point.y
        x_new, y_new = self.transformer.transform(lon, lat)
        return Point(x_new, y_new)
    
def project(path_src, path_dst, path_out):
    with rasterio.open(path_dst) as f_dst:
        profile = f_dst.profile
        with rasterio.open(path_src) as f_src:
            with rasterio.open(path_out, "w", **profile) as f_out:
                for i in range(1, f_src.count + 1):
                    reproject(
                        source=rasterio.band(f_src, i),
                        destination=rasterio.band(f_out, i),
                        src_transform=f_src.transform,
                        src_crs=f_src.crs,
                        dst_transform=f_dst.transform,
                        dst_crs=f_dst.crs,
                        resampling=Resampling.nearest
                    )


def get_time_window():
    today = datetime.today()
    month = today.month
    year = today.year

    if 3 <= month <= 5:
        start = f"{year-1}-12-01"
        end = f"{year}-03-01"
    elif 6 <= month <= 8:
        start = f"{year}-03-01"
        end = f"{year}-01-06"
    elif 9 <= month <= 11:
        start = f"{year}-06-01"
        end = f"{year}-09-01"
    else:
        if month == 12:
            start = f"{year}-09-01"
            end = f"{year}-12-01"
        else:
            start = f"{year-1}-09-01"
            end = f"{year-1}-12-01"

    return start, end
