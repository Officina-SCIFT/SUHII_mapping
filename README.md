# Surface Urban Heat Island Intensity (SUHII) Mapping

This repository contains tools for automating the production of surface urban heat island (SUHII) maps from satellite imagery and OpenStreetMap data. The workflow centres on the `src/R/SUHI_mapping.R` script, which orchestrates preprocessing, spatial analysis, and visualization tasks. Complementary Python utilities (such as `downloader.py`) support data acquisition.

## Prerequisites

### Install R
1. Download the latest stable release of [R](https://cran.r-project.org/) for your operating system.
2. Follow the platform-specific installer prompts (Windows `.exe`, macOS `.pkg`, or Linux package manager instructions).
3. (Optional) Install [RStudio](https://posit.co/download/rstudio-desktop/) for an enhanced development environment.

### Install Required R Packages
The script automatically installs any missing CRAN packages on first run. If you prefer to install them manually, you can execute the following in an R console:

```r
install.packages(c(
  "devtools", "terra", "tidyterra", "osmdata", "sf", "googledrive",
  "dplyr", "ggplot2", "lubridate", "sp", "leaflet", "grDevices",
  "colorRamps", "colorspace", "elevatr", "reticulate", "sfdep",
  "spdep", "tidyr", "jsonlite", "httr", "purrr", "kgc"
))
```

### Python Support (Optional)
Some steps rely on Python scripts for data download. Install Python 3.9+ and the required packages with:

```bash
pip install -r requirements.txt
```

## Using the R Workflow

1. **Clone the repository**
   ```bash
   git clone https://github.com/<your-org>/SUHII_mapping.git
   cd SUHII_mapping
   ```

2. **Prepare configuration**
   Open `src/R/SUHI_mapping.R` and edit the configuration block near the top of the script:
   - `citta`: name of the city or study area.
   - `percorso`: working directory where data are processed and outputs will be stored.
   - `season`: `"warm"` or `"inverno"` to select the analysis season.
   - `LD_script`: path to the folder that contains `downloader.py`.
   - `cct`: cloud cover threshold (%) for selecting imagery. The default and recommended is 30%.

3. **Run the script**
   Launch an R session (R GUI, RStudio, or terminal) and source the script:
   ```r
   source("src/R/SUHI_mapping.R")
   ```
   The script will:
   - Install and load required packages.
   - Query OpenStreetMap features by dividing the area of interest into manageable chunks.
   - Download, preprocess, and mosaic satellite imagery using the configured parameters.
   - Generate maps and intermediate datasets inside the working directory defined by `percorso`.

## Project Status
This work underpins a scientific manuscript that is currently under peer review. Updates to the repository may occur as part of the review process.

## Acknowledgements
The development of this workflow was made possible thanks to the collaboration and support of **SCIFT Officina**.

For questions or contributions, please open an issue or submit a pull request.
