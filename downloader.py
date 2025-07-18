import os
import json
import requests
import argparse
import datetime
import re
import pandas as pd


def sendRequest(url, data, apiKey = None):  
    pos = url.rfind('/') + 1
    endpoint = url[pos:]
    json_data = json.dumps(data)
    
    if apiKey == None:
        response = requests.post(url, json_data)
    else:
        headers = {'X-Auth-Token': apiKey}              
        response = requests.post(url, json_data, headers = headers)    
    output = response.json()
    return output['data']

def downloadFile(url, path):
    try:        
        response = requests.get(url, stream=True)
        disposition = response.headers['content-disposition']
        filename = re.findall("filename=(.+)", disposition)[0].strip("\"")
        print(f"Downloading {filename} ...\n")
        open(path + '/' + filename, 'wb').write(response.content)
        print(f"Downloaded {filename}\n")
    except:
        print('Download Failed')
    

if __name__ == '__main__': 
    
    # user input    
    parser = argparse.ArgumentParser()
    # parser.add_argument('--username', required=True, help='ERS Username')
    # parser.add_argument('--token', required=True, help='ERS application token')
    # parser.add_argument('--bbox', type=float, nargs=4, required=True, help='Box bounds in the order xmin, ymin, xmax, ymax')
    # parser.add_argument('--start_date', type=str, required=True, help='Start date in the form yyyy-mm-dd')
    # parser.add_argument('--end_date', type=str, required=True, help='End date in the form yyyy-mm-dd')
    parser.add_argument('--city', type=str, default='Bologna', help='Path to the directory where the data is stored') 
    args = parser.parse_args()
    
    token='C7djdvyQ9PEJ6dc232fj!X_8N7rQ4KdhihGDq36L1n7wXiKTKFBAiYqhUjIM!gCG'
    username='Matteo22'
    xmin, xmax, ymin, ymax = 11.22962, 11.43361, 44.42105, 44.55609
    start = '2024-07-01'
    end = '2024-08-01'
    datasetName = 'landsat_ot_c2_l2'
    bandNames = {'QA_PIXEL', 'ST_B10', 'ST_B6'}
    # username, token = args.username, ""
    # xmin, ymin, xmax, ymax = args.bbox[0], args.bbox[1], args.bbox[2], args.bbox[3]
    # start = args.start_date
    # end = args.end_date
    serviceUrl = "https://m2m.cr.usgs.gov/api/api/json/stable/"

    # Request access
    payload = {'username' : username, 'token' : token}
    apiKey = sendRequest(serviceUrl + "login-token", payload)

    # Request Scenes
    payload = {
    'datasetName': datasetName,
    'sceneFilter' : {
        'acquisitionFilter' : {'start' : start, 'end' : end},
        'spatialFilter' : {'filterType' : 'mbr', 'lowerLeft' : {'latitude' : xmin, 'longitude' : ymin}, 'upperRight' : {'latitude' : xmax, 'longitude' : ymax}}
        }
    }
    scenes = sendRequest(serviceUrl + "scene-search", payload, apiKey)
    
    # Request Download Options
    sceneIds = [scene['entityId'] for scene in scenes['results']]
    payload = {'datasetName' : datasetName, 'entityIds' : sceneIds, 'includeSecondaryFileGroups' : True}
    downloadOptions = sendRequest(serviceUrl + "download-options", payload, apiKey)
    downloadOptions = pd.json_normalize(downloadOptions) 
    downloads = []

    for _, option in downloadOptions.iterrows():
        if option['secondaryDownloads'] is not None and len(option["secondaryDownloads"]) > 0:
            for secondaryDownload in option["secondaryDownloads"]:
                for bandName in bandNames:
                    if secondaryDownload["bulkAvailable"] and bandName in secondaryDownload['displayId']:
                        downloads.append({"entityId": secondaryDownload["entityId"], "productId": secondaryDownload["id"]})

    # # Request Download 
    # downloads = [{'entityId' : product['entityId'], 'productId' : product['id']} for product in downloadOptions if product['available'] == True]
    # print(downloads)
    # import sys
    # sys.exit()  
    label = datetime.datetime.now().strftime("%Y%m%d_%H%M%S") 
    payload = {'downloads' : downloads, 'label' : label}
    requestResults = sendRequest(serviceUrl + "download-request", payload, apiKey)          
                      
    # Download 
    print(f'{len(requestResults["availableDownloads"])} avaialble files')
    os.makedirs(f'{args.city}/Processing/{start}', exist_ok=True)
    for download in requestResults['availableDownloads']:
        downloadFile(download['url'], path=f'{args.city}/Processing/{start}')
    print("Complete Downloading")

    folder = f'{args.city}/Processing/{start}'
    for filename in os.listdir(folder):
        infilename = os.path.join(folder, filename)
        if not os.path.isfile(infilename): 
            continue
        oldbase = os.path.splitext(filename)
        newname = infilename.replace('.TIF', '.tif')
        output = os.rename(infilename, newname)

