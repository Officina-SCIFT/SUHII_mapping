import os, sys
import src.python.settings as settings
import json
import requests
import argparse
import datetime
import re
import tarfile
import pandas as pd
import osmnx as ox
import matplotlib.pyplot as plt
from shapely.geometry.polygon import Polygon


class LandsatDownloader:
    def __init__(self, username, token):
        self.username = username
        self.token = token
        self.apiKey = None
        self.serviceUrl = 'https://m2m.cr.usgs.gov/api/api/json/stable/'
        self.datasetName = 'landsat_ot_c2_l2'
        self.bandNames = {'QA_PIXEL', 'ST_B10', 'ST_B6'}

    def login(self):
        payload = {'username' : self.username, 'token' : self.token}
        self.apiKey = self._sendRequest('login-token', payload)

    def download(self, xmin, ymin, xmax, ymax, start, end, path):
        # Request Scenes
        payload = {
        'datasetName': self.datasetName,
        'sceneFilter' : {
            'acquisitionFilter' : {'start' : start, 'end' : end},
            'spatialFilter' : {'filterType' : 'mbr', 'lowerLeft' : {'longitude' : xmin, 'latitude' : ymin}, 'upperRight' : {'longitude' : xmax, 'latitude' : ymax}}
            }
        }
        scenes = self._sendRequest("scene-search", payload)
        
        # Request Download Options
        sceneIds = [scene['entityId'] for scene in scenes['results']]
        payload = {'datasetName' : self.datasetName, 'entityIds' : sceneIds, 'includeSecondaryFileGroups' : True}
        downloadOptions = self._sendRequest("download-options", payload)
        downloadOptions = pd.json_normalize(downloadOptions) 

        downloads = []
        for _, option in downloadOptions.iterrows():
            if option['secondaryDownloads'] is not None and len(option["secondaryDownloads"]) > 0:
                for secondaryDownload in option["secondaryDownloads"]:
                    for bandName in self.bandNames:
                        if secondaryDownload["bulkAvailable"] and bandName in secondaryDownload['displayId']:
                            downloads.append({"entityId": secondaryDownload["entityId"], "productId": secondaryDownload["id"]})

        # Request Download 
        label = datetime.datetime.now().strftime("%Y%m%d_%H%M%S") 
        payload = {'downloads' : downloads, 'label' : label}
        requestResults = self._sendRequest("download-request", payload)          

        # Download 
        print(f'{len(requestResults["availableDownloads"])} avaialble files')
        os.makedirs(path, exist_ok=True)
        for download in requestResults['availableDownloads']:
            self._downloadFile(download['url'], path=path)
        print("Complete Downloading")
    
    def _sendRequest(self, action, data):  
        url = self.serviceUrl + action
        json_data = json.dumps(data)
        
        if self.apiKey == None:
            response = requests.post(url, json_data)
        else:
            headers = {'X-Auth-Token': self.apiKey}              
            response = requests.post(url, json_data, headers = headers)    
        output = response.json()
        return output['data']

    def _downloadFile(self, url, path):
        try:        
            response = requests.get(url, stream=True)
            disposition = response.headers['content-disposition']
            filename = re.findall("filename=(.+)", disposition)[0].strip("\"")
            print(f"Downloading {filename} ...\n")
            open(path + '/' + filename, 'wb').write(response.content)
            print(f"Downloaded {filename}\n")
        except:
            print('Download Failed')


class DemDownloader:
    def __init__(self, key='f2db7bf1924b62aef1bc49b45e00b564'):
        self.key = key
        self.url = 'https://portal.opentopography.org/API/globaldem'
        # self.dem_type = ['SRTM15Plus', 'AW3D30', 'SRTMGL3', 'SRTMGL1']
        self.dem_type = 'SRTMGL1'

    def download(self, xmin, ymin, xmax, ymax, path):
        params = {'demtype': self.dem_type, 'API_Key': self.key, 'west': xmin, 'east': xmax, 'south': ymin, 'north': ymax, 'outputFormat': 'GTiff'}
        response = requests.get(self.url, params=params, stream=True)

        if response.status_code == 200:
            with open(path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=1024):
                    f.write(chunk)
            print('Download Completed')


class OSMDownloader:
    def __init__(self, city: str):
        self.city = city

    def download(self, path: str):
        graph_city = ox.graph_from_place(self.city)
        self.nodes = ox.graph_to_gdfs(graph_city, edges=False)
        polygon = self.nodes.geometry

        polygon.to_file(f'{path}/city.shp', driver='ESRI Shapefile')

        # bbox 
        bbox = {}
        bbox['xmin'] = self.nodes['x'].min()
        bbox['xmax'] = self.nodes['x'].max()
        bbox['ymin'] = self.nodes['y'].min()
        bbox['ymax'] = self.nodes['y'].max()

        def linestring_to_polygon(x):
            try:
                return Polygon(x)
            except:
                pass

        # extracting features TODO:- super inefficient
        natural_areas = ox.features.features_from_place(self.city, settings.natural).loc['way']
        natural_areas['geometry'].apply(linestring_to_polygon).to_file(f'{path}/natural_areas.shp', driver='ESRI Shapefile')
        semi_natual_areas = ox.features.features_from_place(self.city, settings.semi_natural)
        semi_natual_areas['geometry'].apply(linestring_to_polygon).to_file(f'{path}/semi_natural_areas.shp', driver='ESRI Shapefile')
        green_areas = ox.features.features_from_place(self.city, settings.green)
        green_areas.drop('node', inplace=True)
        green_areas['geometry'].apply(linestring_to_polygon).to_file(f'{path}/green_areas.shp', driver='ESRI Shapefile')
        urban_areas = ox.features.features_from_place(self.city, settings.urban).loc['way']
        urban_areas['geometry'].apply(linestring_to_polygon).to_file(f'{path}/urban_areas.shp', driver='ESRI Shapefile')
        amenity_areas = ox.features.features_from_place(self.city, settings.amenity).loc['way']
        amenity_areas['geometry'].apply(linestring_to_polygon).apply(lambda x: Polygon(x)).to_file(f'{path}/amenity_areas.shp', driver='ESRI Shapefile')
        building_areas = ox.features.features_from_place(self.city, settings.building)
        building_areas.loc['way']['geometry'].apply(linestring_to_polygon).to_file(f'{path}/building_areas.shp', driver='ESRI Shapefile')
        tourism_areas = ox.features.features_from_place(self.city, settings.tourism).loc['way']
        tourism_areas['geometry'].apply(linestring_to_polygon).to_file(f'{path}/tourism_areas.shp', driver='ESRI Shapefile')
        highway_areas = ox.features.features_from_place(self.city, settings.highway).loc['way']
        highway_areas['geometry'].apply(linestring_to_polygon).to_file(f'{path}/highway_areas.shp', driver='ESRI Shapefile')
        amusement_areas = ox.features.features_from_place(self.city, settings.amusement).loc['way']
        amusement_areas['geometry'].apply(linestring_to_polygon).to_file(f'{path}/amusement_areas.shp', driver='ESRI Shapefile')
        aeroway_areas = ox.features.features_from_place(self.city, settings.aeroway).loc['way']
        aeroway_areas['geometry'].apply(linestring_to_polygon).to_file(f'{path}/aeroway_areas.shp', driver='ESRI Shapefile')

        return graph_city, bbox, polygon
        
    @staticmethod
    def plot(self, graph_city, tags):
        # plotting 
        fig, ax = ox.plot_graph(graph_city, show=False, close=False)
        for tag in tags:
            tag.plot(ax=ax)

        plt.show()
