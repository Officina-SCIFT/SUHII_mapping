import os
import sys
import json
import requests
import argparse
import datetime
import re
import pandas as pd

# ---------- Core helpers ----------

def sendRequest(url, data, apiKey=None):
    json_data = json.dumps(data)
    headers = {'Content-Type': 'application/json'}
    if apiKey:
        headers['X-Auth-Token'] = apiKey
    response = requests.post(url, data=json_data, headers=headers)
    response.raise_for_status()
    output = response.json()
    # M2M wraps results under 'data'
    return output.get('data')

def downloadFile(url, path):
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        disposition = response.headers.get('content-disposition', '')
        matches = re.findall(r"filename=(.+)", disposition)
        if not matches:
            print("Could not find filename in content-disposition header.")
            return
        filename = matches[0].strip("\"")
        print(f"Downloading {filename} ...")
        with open(os.path.join(path, filename), 'wb') as f:
            f.write(response.content)
        print(f"Downloaded {filename}")
    except Exception as e:
        print(f"Download Failed: {e}")

def get_valid_datasets(start_date, end_date):
    valid = set()
    start = datetime.datetime.strptime(start_date, "%Y-%m-%d").date()
    end = datetime.datetime.strptime(end_date, "%Y-%m-%d").date()

    def overlaps(s1, e1, s2, e2):
        return max(s1, s2) <= min(e1, e2)

    # Landsat 4 & 5: TM → 1982–2011
    if overlaps(start, end, datetime.date(1982, 7, 16), datetime.date(2011, 6, 5)):
        valid.add("landsat_tm_c2_l2")

    # Landsat 7: ETM+ → 1999–2022
    if overlaps(start, end, datetime.date(1999, 4, 15), datetime.date(2022, 4, 6)):
        valid.add("landsat_etm_c2_l2")

    # Landsat 8 & 9: OLI/TIRS → 2013–
    if overlaps(start, end, datetime.date(2013, 2, 11), datetime.date.today()):
        valid.add("landsat_ot_c2_l2")

    return list(valid)

# ---------- NEW: metadata filter discovery ----------

def find_cloud_cover_land_field(filters):
    """
    Find the 'cloudCoverLand' field from dataset-filters output.
    The M2M response is a list of dicts describing fields/filters.
    We try robust matching on either 'fieldName' or a label mentioning land cloud.
    """
    if not filters:
        return None
    # Direct match on fieldName
    for f in filters:
        if str(f.get("fieldName", "")).strip().lower() == "cloudcover":
            return f

    # Fallback: look for labels mentioning cloud cover over land
    keywords = ("cloud cover land", "cloud cover over land", "land cloud")
    for f in filters:
        label = " ".join([
            str(f.get("fieldLabel", "")),
            str(f.get("fieldName", "")),
            str(f.get("additionalInfo", "")),
        ]).lower()
        if any(k in label for k in keywords):
            return f

    return None

def get_cloud_cover_land_field_id(serviceUrl, datasetName, apiKey):
    """
    Calls dataset-filters and returns the fieldId for cloudCoverLand if present.
    """
    payload = {"datasetName": datasetName}
    filters = sendRequest(serviceUrl + "dataset-filters", payload, apiKey)
    # Some APIs return {'fields': [...]}—normalize to a list of fields
    if isinstance(filters, dict) and "fields" in filters:
        filters = filters["fields"]
    field = find_cloud_cover_land_field(filters)
    return field.get("fieldId") if field else None

# ---------- Main ----------

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--username', required=True, help='ERS Username')
    parser.add_argument('--token', required=True, help='ERS application token')
    parser.add_argument('--bbox', type=float, nargs=4, required=True,
                        help='Bounding box as xmin ymin xmax ymax (lon_min lat_min lon_max lat_max)')
    parser.add_argument('--start_date', type=str, required=True, help='Start date (yyyy-mm-dd)')
    parser.add_argument('--end_date', type=str, required=True, help='End date (yyyy-mm-dd)')
    parser.add_argument('--city', type=str, default='Bologna', help='City name (not used for folders here).')
    parser.add_argument('--out_dir', type=str, default='.',
                        help='Directory where the downloaded images will be saved. Default is current directory.')
    parser.add_argument('--max_cloud', type=int, default=70,
                        help='Maximum overall and land-only cloud cover percentage (default 30).')
    args = parser.parse_args()

    username = args.username
    token = args.token
    xmin, ymin, xmax, ymax = args.bbox
    start = args.start_date
    end = args.end_date
    out_dir = args.out_dir
    max_cloud = args.max_cloud

    datasetNames = get_valid_datasets(start, end)
    if not datasetNames:
        print("No valid datasets for the requested time range.")
        sys.exit(0)

    print(f"Using datasets: {datasetNames}")

    bandNames = ['QA_PIXEL', 'ST_B10', 'ST_B6']
    serviceUrl = "https://m2m.cr.usgs.gov/api/api/json/stable/"

    # Login
    payload = {'username': username, 'token': token}
    apiKey = sendRequest(serviceUrl + "login-token", payload)

    all_downloads = []

    for datasetName in datasetNames:
        print(f"\n--- Dataset: {datasetName} ---")

        # 1) Discover fieldId for cloudCoverLand
        ccl_field_id = get_cloud_cover_land_field_id(serviceUrl, datasetName, apiKey)
        if ccl_field_id:
            print(f"cloudCoverLand fieldId for {datasetName}: {ccl_field_id}")
        else:
            print(f"WARNING: cloudCoverLand fieldId not found for {datasetName}. "
                  f"Proceeding with overall cloud filter only.")

        # 2) Build sceneFilter with BOTH overall cloud and (if available) land-only metadata filter
        sceneFilter = {
            'acquisitionFilter': {'start': start, 'end': end},
            'spatialFilter': {
                'filterType': 'mbr',
                'lowerLeft':  {'latitude': ymin, 'longitude': xmin},
                'upperRight': {'latitude': ymax, 'longitude': xmax}
            },
            'cloudCoverFilter': {'min': 0, 'max': max_cloud, 'includeUnknown': False}
        }

        if ccl_field_id:
            sceneFilter['metadataFilter'] = [
                {
                    "filterType": "between",
                    "fieldId": ccl_field_id,
                    "firstValue": "0",
                    "secondValue": str(max_cloud)
                }
            ]

        # 3) Search scenes
        payload = {'datasetName': datasetName, 'sceneFilter': sceneFilter}
        scenes = sendRequest(serviceUrl + "scene-search", payload, apiKey)

        results = (scenes or {}).get('results', [])
        if not results:
            print(f"No scenes found in {datasetName}")
            continue

        # Optional: quick sanity print to verify filtering
        print(f"Found {len(results)} scenes in {datasetName}. Showing first 5 cloud values:")
        for s in results[:5]:
            print("  ", s.get('entityId'), "overallCloud=", s.get('cloudCover'))

        sceneIds = [scene['entityId'] for scene in results]

        # 4) Download options
        payload = {
            'datasetName': datasetName,
            'entityIds': sceneIds,
            'includeSecondaryFileGroups': True
        }

        try:
            options = sendRequest(serviceUrl + "download-options", payload, apiKey)
        except Exception as e:
            print(f"Error fetching download options for {datasetName}: {e}")
            continue

        # Normalize to DataFrame for easier iteration
        df = pd.json_normalize(options)
        # Iterate robustly over possibly missing/None 'secondaryDownloads'
        for _, row in df.iterrows():
            secondary = row.get('secondaryDownloads')
            if not isinstance(secondary, list):
                continue
            for item in secondary:
                display_id = item.get('displayId', '') or ''
                if not item.get("bulkAvailable"):
                    continue
                for bandName in bandNames:
                    if bandName in display_id:
                        all_downloads.append({
                            "entityId": item.get("entityId"),
                            "productId": item.get("id")
                        })

    if not all_downloads:
        print("No valid downloads found.")
        sys.exit(0)

    # 5) Submit download request
    label = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    payload = {'downloads': all_downloads, 'label': label}
    requestResults = sendRequest(serviceUrl + "download-request", payload, apiKey)
    available = requestResults.get("availableDownloads", [])

    print(f"\n{len(available)} files ready for download.")
    os.makedirs(out_dir, exist_ok=True)

    for item in available:
        downloadFile(item['url'], path=out_dir)

    # 6) Normalize extension case
    for filename in os.listdir(out_dir):
        infilename = os.path.join(out_dir, filename)
        if os.path.isfile(infilename):
            oldbase, ext = os.path.splitext(filename)
            if ext.upper() == '.TIF':
                os.rename(infilename, os.path.join(out_dir, oldbase + '.tif'))

    print("Download complete.")
