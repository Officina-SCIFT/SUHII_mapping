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
   - `season`: up to now only `"warm"` season implemented.  
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


## Disclaimer
All data products and derived outputs provided in this repository are based on the associated peer‐reviewed publication. Any use of these data - whether for further analysis, modeling, visualization, or incorporation into other projects - must include a citation to the original paper.
Please cite the following reference when using any portion of these data:

Richiardi, C., Caroscio, L., Crescini, E., De Marchi, M., De Pieri, G. M., Ceresi, C., Baldo, F., Francobaldi, M., & Pappalardo, S. E. (2025). A global downstream approach to mapping surface urban heat islands using open data and collaborative technology. *Sustainable Geosciences: People, Planet and Prosperity*, 100006. [https://doi.org/10.1016/j.susgeo.2025.100006](https://doi.org/10.1016/j.susgeo.2025.100006).

Failure to cite the original publication may constitute a breach of academic and professional standards.

## Project 
The project aligns with SDG 17 (Partnerships for the Goals) by fostering open, cross-sectoral collaboration through open science principles. By releasing the workflow under the GNU General Public License v3.0 (GPL 3.0) and providing implementations in both R and Python, the project promotes inclusivity in technical development and downstream use.

In line with the values of transparency, reproducibility, and accessibility, all code, data processing steps, and documentation are openly shared to facilitate collaboration across research institutions, policy sectors, and geographic regions. The repository is intended as a living resource that encourages community contributions, interoperability between tools, and the co-creation of robust environmental analyses supporting evidence-based decision-making.
  
## Acknowledgements
The development of this workflow was made possible thanks to the collaboration and support of **SCIFT Officina**.

For questions or contributions, please open an issue or submit a pull request.

# 💬 Share Your Feedback
We’d love to hear how you’re using the workflow. Your input helps improve the workflow and highlight real-world applications.
👉 Take a few minutes to fill out our [user feedback form](https://docs.google.com/forms/d/e/1FAIpQLScPsFdDerNaYa_WPHlRN-0qV5SfJcZ4uILIQK0cef_2M6jNOg/viewform?usp=dialog)

If you’d like, you can also share your story about how you used the workflow and the impact of your results.
Thank you for helping make this project more open, useful, and collaborative! 🌍
