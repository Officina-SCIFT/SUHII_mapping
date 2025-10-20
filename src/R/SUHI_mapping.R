######################################
# SURFACE URBAN HEAT ISLANDS MAPPING #
######################################

# Script for automating the mapping of surface urban heat islands 

# References: 
# https://www.youtube.com/watch?v=XfaoRxQQYzg 

# Reference keys and values OSM:
# https://wiki.openstreetmap.org/wiki/Key:landuse
# https://wiki.openstreetmap.org/wiki/Category:Key_descriptions
# https://rspatialdata.github.io/osm.html

# USGS API
# https://m2m.cr.usgs.gov/api/docs/json/

# Contacts: 
# chiara.richiardi@gmail.com
# letizia.caroscio2@unibo.it

################################################################################
#####                              SETUP                                    ####
################################################################################
# WRITE HERE, INSIDE THE QUOTATION MARKS, YOUR CITY OF INTEREST
citta <- "Limassol"  
# WRITE HERE, INSIDE THE QUOTATION MARKS, THE PATH OF THE WORK FOLDER (OF YOUR CHOICE)
percorso <- "E:/UHI_test"
# IMPOSTA LA season DI INTERESSE
season <- "warm" # oppure "inverno"
# WRITE HERE, INSIDE THE QUOTATION MARKS, THE FOLDER WHERE THE "downloader.py" FILE IS 
LD_script <- "H:/.shortcut-targets-by-id/1CL6-2-JcQe_EHeMxTKhTwfCNXBRos6cC/Progetto_Climattivismo_Urbano/Script"
# Cloud cover threshold
cct <- 30
################################################################################

#### Section 1 - PRELIMINAR OPERATIONS #########################################
#1.1 Load packages ----
list.of.packages <- c(
  "devtools",
  "terra",
  "tidyterra",
  "osmdata",
  "sf",
  "googledrive",
  "dplyr",
  "ggplot2",
  "lubridate",
  "sp",
  "leaflet",
  "grDevices",
  "colorRamps",
  "colorspace",
  "elevatr",
  "reticulate",
  "sfdep",
  "spdep", 
  "tidyr",
  "jsonlite",
  "httr",
  "purrr",
  "kgc"
)

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

if(length(new.packages) > 0){
  install.packages(new.packages, dep=TRUE)
}

#loading packages
for(package.i in list.of.packages){
  suppressPackageStartupMessages(
    library(package.i,character.only = TRUE))
}


#1.2 Functions ----
# Helper function: splits the AOI bounding box into a grid (default: 3 columns × 3 rows = 9 chunks)
split_aoi_chunks <- function(aoi_bb, nx = 2, ny = 2) {
  # aoi_bb: 2x2 matrix with rownames "x" and "y", colnames "min" and "max"
  x_min <- aoi_bb["x", "min"]
  x_max <- aoi_bb["x", "max"]
  y_min <- aoi_bb["y", "min"]
  y_max <- aoi_bb["y", "max"]
  
  x_breaks <- seq(x_min, x_max, length.out = nx + 1)
  y_breaks <- seq(y_min, y_max, length.out = ny + 1)
  
  subBbs <- list()
  idx <- 1
  for (i in seq_len(nx)) {
    for (j in seq_len(ny)) {
      xmin_ij <- x_breaks[i]
      xmax_ij <- x_breaks[i + 1]
      ymin_ij <- y_breaks[j]
      ymax_ij <- y_breaks[j + 1]
      
      subBbs[[idx]] <- matrix(
        c(xmin_ij, ymin_ij, xmax_ij, ymax_ij),
        nrow = 2, byrow = FALSE,
        dimnames = list(c("x", "y"), c("min", "max"))
      )
      idx <- idx + 1
    }
  }
  return(subBbs)
}

# Function to download an OSM feature in chunks (without a timeout parameter) and merge the results.
download_osm_feature_chunks <- function(aoi_bb, key, value = NULL, out_prefix, output_dir = ".") {
  
  # Split the AOI bounding box into sub–AOIs (default: 2 x 2 = 4 chunks)
  subBbs <- split_aoi_chunks(aoi_bb, nx = 2, ny = 2)
  message("Processing ", length(subBbs), " sub-AOIs for key: ", key)
  
  for (i in seq_along(subBbs)) {
    bbox_i <- subBbs[[i]]
    bb_vec <- c(bbox_i["x", "min"], bbox_i["y", "min"],
                bbox_i["x", "max"], bbox_i["y", "max"])
    
    q <- opq(bb_vec)
    q <- if (!is.null(value)) add_osm_feature(q, key, value = value) else add_osm_feature(q, key)
    
    osm_data <- tryCatch({
      osmdata_sf(q)
    }, error = function(e) {
      message("OSM query failed for sub-AOI ", i, ": ", e$message)
      return(NULL)
    })
    
    if (is.null(osm_data)) next
    
    # Polygons
    if (!is.null(osm_data$osm_polygons) && nrow(osm_data$osm_polygons) > 0) {
      shp_poly <- tryCatch({
        v <- vect(osm_data$osm_polygons)
        if (length(v) > 0) makeValid(v) else NULL
      }, error = function(e) {
        message("Failed to process osm_polygons for sub-AOI ", i, ": ", e$message)
        return(NULL)
      })
      if (!is.null(shp_poly) && length(shp_poly) > 0) {
        out_file_poly <- file.path(output_dir, paste0(out_prefix, "_poly_sub", i, ".shp"))
        writeVector(shp_poly, out_file_poly,
                    filetype = "ESRI Shapefile",
                    overwrite = TRUE,
                    options = "ENCODING=UTF-8")
      }
    }
    
    # Multipolygons
    if (!is.null(osm_data$osm_multipolygons) && nrow(osm_data$osm_multipolygons) > 0) {
      shp_mpoly <- tryCatch({
        v <- vect(osm_data$osm_multipolygons) 
        if (length(v) > 0) makeValid(v) else NULL
      }, error = function(e) {
        message("Failed to process osm_multipolygons for sub-AOI ", i, ": ", e$message)
        return(NULL)
      })
      if (!is.null(shp_mpoly) && length(shp_mpoly) > 0) {
        out_file_mpoly <- file.path(output_dir, paste0(out_prefix, "_multipoly_sub", i, ".shp"))
        writeVector(shp_mpoly, out_file_mpoly,
                    filetype = "ESRI Shapefile",
                    overwrite = TRUE,
                    options = "ENCODING=UTF-8")
      }
    }
    
    rm(osm_data)
    gc()
  }
  
  # Merge shapefiles
  shp_files <- list.files(output_dir, pattern = glob2rx(paste0(out_prefix, "_*.shp")), full.names = TRUE)
  shp_files_all <- list.files(output_dir, pattern = glob2rx(paste0(out_prefix, "_*.*")), full.names = TRUE)
  shp_files_all <- shp_files_all[!grepl("merge", basename(shp_files_all), ignore.case = TRUE)]
  
  if (length(shp_files) > 0) {
    message("Merging ", length(shp_files), " files for key: ", key)
    
    sf_list <- lapply(shp_files, function(f) {
      tryCatch({
        sf_obj <- sf::read_sf(f)
        if (!inherits(sf_obj, "sf") || is.null(sf::st_geometry(sf_obj)) || nrow(sf_obj) == 0) {
          message("File ", f, " is not a valid sf with geometry.")
          return(NULL)
        }
        return(sf_obj)
      }, error = function(e) {
        message("Error reading file ", f, ": ", e$message)
        return(NULL)
      })
    })
    
    sf_list <- Filter(Negate(is.null), sf_list)
    
    if (length(sf_list) == 0) {
      message("No valid shapefiles with geometry found for ", key)
    } else {
      merged_sf <- tryCatch({
        merged <- dplyr::bind_rows(sf_list)  # Armonizza colonne
        if (is.null(sf::st_geometry(merged))) stop("Merged object has no geometry.")
        merged
      }, error = function(e) {
        message("Merging failed: ", e$message)
        return(NULL)
      })
      
      if (!is.null(merged_sf)) {
        out_merged <- file.path(output_dir, paste0(out_prefix, "_merge.shp"))
        writeVector(vect(merged_sf), out_merged,
                    filetype = "ESRI Shapefile",
                    overwrite = TRUE,
                    options = "ENCODING=UTF-8")
      }
    }
    
    file.remove(shp_files_all)
    
  } else {
    message("No files were downloaded for ", key)
  }
} 
# Load the city of interest
aoi_bb <- getbb(citta) #, format_out = "polygon", featuretype = "city", limit=1

citta <- gsub(" ", "_", citta) # Remove empty spaces

#1.3 Set and create folder's structure ----
cartella <- file.path(percorso,citta)
input <- file.path(cartella,"Input")
landsat <- file.path(input,"Landsat")
output <- file.path(cartella,"Output")
processing <- file.path(cartella,"Processing")
dir.create(cartella, showWarnings = FALSE)
dir.create(input, showWarnings = FALSE)
dir.create(landsat, showWarnings = FALSE)
dir.create(output, showWarnings = FALSE)
dir.create(processing, showWarnings = FALSE)

#### Section 2 - INPUT DATA  ###################################################
#2.1 Land Use / Land Cover from OpenStreetMap ----
setwd(input)
#2.1.1 Administrative boundaries ----
# First try the primary query
aoiosm <- tryCatch({
  aoi_bb %>%
    opq() %>%
    add_osm_feature("admin_level", value = c("6", "7", "8")) %>% 
    add_osm_feature("name", value = citta, match_case = FALSE) %>%  
    osmdata_sf()
}, error = function(e) {
  message("Primary OSM query failed: ", e$message)
  message("Trying alternate OSM query...")
  # Now try the alternate query
  tryCatch({
    aoi_bb %>%
      opq() %>%
      add_osm_feature("int_name", value = citta, match_case = FALSE) %>% 
      add_osm_feature("place", value = "city") %>% 
      osmdata_sf()
  }, error = function(e2) {
    message("Alternate OSM query failed: ", e2$message)
    return(NULL)
  })
})

# Check if the query returned empty results in the osm_multipolygons slot.
if (is.null(aoiosm) || length(aoiosm$osm_multipolygons) == 0) {
  message("No administrative boundaries found. Using bounding box as fallback.")
  
  # Create a polygon from aoi_bb manually
  coords <- rbind(
    c(aoi_bb["x", "min"], aoi_bb["y", "min"]),
    c(aoi_bb["x", "min"], aoi_bb["y", "max"]),
    c(aoi_bb["x", "max"], aoi_bb["y", "max"]),
    c(aoi_bb["x", "max"], aoi_bb["y", "min"]),
    c(aoi_bb["x", "min"], aoi_bb["y", "min"])  # repeat first point to close the polygon
  )
  
  aoi <- vect(coords, type = "polygons", crs = "EPSG:4326")
  
} else {
  aoi <- vect(aoiosm$osm_multipolygons)
}

# Visualizza il dato
aoisf <- sf::st_as_sf(aoi)

leaflet(aoisf) %>%
  addPolygons(
    fillOpacity = 0.4, smoothFactor = 0.5) %>%
  addTiles()

rm(aoisf)

# Salva il dato
writeVector(aoi, filename="boundaries.shp", filetype="ESRI Shapefile",overwrite=TRUE, options="ENCODING=UTF-8")


#2.1.2 Rural areas ----
#### Aree naturali
download_osm_feature_chunks(aoi_bb,
                            key = "natural",
                            value = c("fell", "grassland", "heath", "moor", "scrub",
                                      "shrubbery", "tree", "tree_row", "tree_stump",
                                      "tundra", "wood"),
                            out_prefix = "aree_naturali")

#### Aree semi-naturali
download_osm_feature_chunks(aoi_bb,
                            key = "landuse",
                            value = c("farmland", "farmyard", "paddy",
                                      "animal_keeping", "flowerbed", "forest",
                                      "meadow", "orchard", "grass"),
                            out_prefix = "aree_agricole")
#### Aree verdi
download_osm_feature_chunks(aoi_bb,
                            key = "leisure",
                            value = c("garden", "golf_course", "nature_reserve", "park"),
                            out_prefix = "aree_verdi")

# Aree rurali totali
rur_inter_files <- list.files(input, pattern=glob2rx("aree_*"))
aree_riferimento <- list.files(input, pattern=glob2rx("aree_*.shp"))  %>%  
  purrr::map(\(f) sf::read_sf(f)  %>%  
               dplyr::mutate(source = f, .before = 1)) |> 
  purrr::list_rbind()  %>% 
  dplyr::as_tibble()  %>%  
  sf::st_sf() 

aree_rurali <-vect(aree_riferimento)
writeVector(aree_rurali, "rural_areas.shp", filetype="ESRI Shapefile",
            overwrite=TRUE, options="ENCODING=UTF-8")

file.remove(rur_inter_files)

#2.1.3 Urban areas ----
#### Artificial
download_osm_feature_chunks(aoi_bb,
                            key = "landuse",
                            value = c("commercial", "construction", "education",
                                      "fairground", "industrial","residential",
                                      "retail","institutional","railway","aerodrome",
                                      "landfill","port","depot","quarry","military"),
                            out_prefix = "urbanizzato_gen")

#### Amenity
download_osm_feature_chunks(aoi_bb,
                            key = "amenity",
                            out_prefix = "urbanizzato_am")

#### Tourism
download_osm_feature_chunks(aoi_bb,
                            key = "tourism",
                            out_prefix = "urbanizzato_build")

#### Leisure
download_osm_feature_chunks(aoi_bb,
                            key = "leisure",
                            value = c("adult_gaming_centre","amusement_arcade","bandstand",
                                      "beach_resort", "bleachers","bowling_alley", "common",
                                      "dance","disc_golf_course","fitness_centre","fitness_station",
                                      "hackerspace","ice_rink","marina","miniature_golf",
                                      "outdoor_seating","playground","resort","sauna","slipway",
                                      "sports_centre","sport_hall","stadium","summer_camp",
                                      "swimming_pool","tanning_salon", "track","trampoline_park",
                                      "water_park"),
                            out_prefix = "urbanizzato_leis")
#### aeroway
download_osm_feature_chunks(aoi_bb,
                            key = "aeroway",
                            value = c("aerodrome", "apron", "gate","hangar", "spaceport",
                                      "helipad","runway","taxiway","terminal"),
                            out_prefix = "urbanizzato_aero")

#### Highway
download_osm_feature_chunks(aoi_bb,
                            key = "highway",
                            out_prefix = "urbanizzato_high")

### Unisci tutte le aree impermeabilizzate
urb_inter_files <- list.files(input, pattern=glob2rx("urbanizzato*"))
aree_urbanizzate <- list.files(input, pattern=glob2rx("urbanizzato*.shp"))  %>%  
  purrr::map(\(f) sf::read_sf(f)  %>%  
               dplyr::mutate(source = f, .before = 1)) |> 
  purrr::list_rbind()  %>% 
  dplyr::as_tibble()  %>%  
  sf::st_sf() 
aree_urb <- vect(aree_urbanizzate) %>% aggregate() %>% makeValid()


writeVector(aree_urb, "urban_areas.shp", filetype="ESRI Shapefile",
            overwrite=TRUE, options="ENCODING=UTF-8")
rm(aree_urb)

file.remove(urb_inter_files)

#2.2 Download Landsat Collection 2 Level 2 ----
# Set time window based on Koppen-Geiger climate classification 
data <- data.frame(Site = citta, 
                   Longitude = base::mean(c(aoi_bb[1,1],aoi_bb[1,2])), 
                   Latitude = mean(c(aoi_bb[2,1],aoi_bb[2,2]))) 

# Function to round coordinates at 0.05°
data <- data.frame(data, rndCoord.lon = RoundCoordinates(data$Longitude), 
                   rndCoord.lat = RoundCoordinates(data$Latitude)) 

# Function to assign Koppen-Geiger climate zone
data <- data.frame(data, ClimateZ = LookupCZ(data)) 
koppen_class <- data$ClimateZ
KG <- substr(koppen_class, 1, 2)

oggi <- Sys.Date()
y <- as.integer(format(Sys.Date(), "%Y"))

# Compute centroid latitude
lat <- ymin(centroids(aoi)) # returns [x, y]

# Check hemisphere based on y-coordinate
if (lat < 0) {
  message("The AOI is in the Southern Hemisphere.")
  emisfero <- "sud"
} else {
  message("The AOI is in the Northern Hemisphere.")
  emisfero <- "nord"
}

# Function to get default warm months based on KG and latitude
get_default_warm_months <- function(koppen_class, lat){
  NH <- lat >= 0
  
  if (startsWith(koppen_class, "A")){  # Tropical
    if (koppen_class %in% c("Af")){    # Rainforest
      return(1:12)
    } else {                            # Aw/Am - dry season preferred
      if(NH) return(c(11:12,1:4)) else return(c(5:10))
    }
  } else if (startsWith(koppen_class, "B")){  # Arid
    if(NH) return(4:9) else return(c(10:12,1:3))  # fixed crossing-year for SH
  } else if (startsWith(koppen_class, "C")){  # Temperate
    if(koppen_class %in% c("Csa","Csb")){     # Mediterranean
      return(4:9)
    } else {                                  # Oceanic
      if(NH) return(6:8) else return(c(12,1,2))
    }
  } else if (startsWith(koppen_class, "D")){  # Continental
    if(NH) return(6:8) else return(c(12,1,2))
  } else {  # Polar or undefined
    if(NH) return(6:8) else return(c(12,1,2))
  }
}

warm_months <- get_default_warm_months(KG, data$Latitude)


# Function to compute a *full* warm-season window ---
get_warm_season_window <- function(warm_months, today = Sys.Date()) {
  
  y <- as.integer(format(today, "%Y"))
  
  # Case A: warm months are continuous (e.g. 6:8)
  if (max(warm_months) > min(warm_months)) {
    start_date <- as.Date(sprintf("%d-%02d-01", y, min(warm_months)))
    end_date   <- as.Date(format(seq(as.Date(sprintf("%d-%02d-01", y, max(warm_months))), 
                                     by="1 month", length.out=2)[2] - 1, "%Y-%m-%d"))
    
    # If today is before or within current warm season → take previous year
    if (today <= end_date) {
      y <- y - 1
      start_date <- as.Date(sprintf("%d-%02d-01", y, min(warm_months)))
      end_date   <- as.Date(format(seq(as.Date(sprintf("%d-%02d-01", y, max(warm_months))), 
                                       by="1 month", length.out=2)[2] - 1, "%Y-%m-%d"))
    }
    
  } else {
    # Case B: crossing-year season (e.g. 11:3)
    start_month <- min(warm_months) # e.g. 11
    end_month   <- max(warm_months) # e.g. 3
    
    # Season spans Nov (y-1) → Mar (y)
    start_date <- as.Date(sprintf("%d-%02d-01", y-1, start_month))
    end_date   <- as.Date(format(seq(as.Date(sprintf("%d-%02d-01", y, end_month)), 
                                     by="1 month", length.out=2)[2] - 1, "%Y-%m-%d"))
    
    # If today is before end_date (season not finished) → shift one year earlier
    if (today <= end_date) {
      start_date <- as.Date(sprintf("%d-%02d-01", y-2, start_month))
      end_date   <- as.Date(format(seq(as.Date(sprintf("%d-%02d-01", y-1, end_month)), 
                                       by="1 month", length.out=2)[2] - 1, "%Y-%m-%d"))
    }
  }
  
  return(list(start_date = start_date, end_date = end_date))
}

window <- get_warm_season_window(warm_months, oggi)
start_date <- window$start_date
end_date <- window$end_date

# Get central date ---
#central_date <- start_date + as.integer((end_date - start_date) / 2)

# Define 90-day window around central date ---
#half_window <- 90 %/% 2   # half of 90 days = 45
#window_start <- central_date - half_window
#window_end   <- central_date + half_window

print(paste0("Analysis over ", citta, " from ", start_date," to ",end_date,", cloud cover threshold ", cct,"%"))

# Ensure Python 3 is available for system() calls
setup_python <- function() {
  # --- helpers ---
  find_python_bin <- function() {
    # Try env var first, then common names
    candidates <- unique(c(Sys.getenv("PYTHON"), "python3", "python", "py"))
    candidates <- candidates[nzchar(candidates)]
    for (bin in candidates) {
      path <- Sys.which(bin)
      if (nzchar(path)) return(list(bin = bin, path = path))
    }
    NULL
  }
  python_version <- function(bin) {
    # Capture stdout+stderr without throwing if it fails
    out <- tryCatch(system2(bin, "--version", stdout = TRUE, stderr = TRUE),
                    error = function(e) character(0))
    if (length(out)) trimws(paste(out, collapse = " ")) else NA_character_
  }
  
  # --- 1. Check if any python is available ---
  hit <- find_python_bin()
  if (!is.null(hit)) {
    v <- python_version(hit$bin)
    msg <- if (!is.na(v)) v else sprintf("Found: %s", hit$path)
    message("Python detected (", hit$bin, "): ", msg)
    return(invisible(TRUE))
  }
  
  message("Python not found. Attempting to install...")
  
  # --- 2. Try installation depending on OS ---
  os <- Sys.info()[["sysname"]]
  
  if (os == "Linux") {
    # Try apt; fall back to dnf/yum/pacman if apt isn't present
    has <- function(x) nzchar(Sys.which(x))
    if (has("apt-get")) {
      system("sudo apt-get update -y", ignore.stdout = TRUE, ignore.stderr = TRUE)
      system("sudo apt-get install -y python3", ignore.stdout = TRUE, ignore.stderr = TRUE)
    } else if (has("dnf")) {
      system("sudo dnf install -y python3", ignore.stdout = TRUE, ignore.stderr = TRUE)
    } else if (has("yum")) {
      system("sudo yum install -y python3", ignore.stdout = TRUE, ignore.stderr = TRUE)
    } else if (has("pacman")) {
      system("sudo pacman -S --noconfirm python", ignore.stdout = TRUE, ignore.stderr = TRUE)
    } else {
      stop("No known package manager found. Please install Python manually.")
    }
    
  } else if (os == "Darwin") {
    # macOS (requires Homebrew)
    if (!nzchar(Sys.which("brew"))) {
      stop("Homebrew not found. Please install it first: https://brew.sh/")
    }
    system("brew install python", ignore.stdout = TRUE, ignore.stderr = TRUE)
    
  } else if (os == "Windows") {
    # Windows: try winget; otherwise suggest the official installer
    if (nzchar(Sys.which("winget"))) {
      system("winget install -e --id Python.Python.3", ignore.stdout = TRUE, ignore.stderr = TRUE)
    } else {
      stop("Winget not found. Please install Python from https://www.python.org/downloads/windows/")
    }
    
  } else {
    stop("Unsupported OS: ", os)
  }
  
  # --- 3. Re-check (try both python3 and python) ---
  hit <- find_python_bin()
  if (!is.null(hit)) {
    v <- python_version(hit$bin)
    message("Python successfully installed (", hit$bin, "): ", v)
    return(invisible(TRUE))
  } else {
    stop("Python installation did not succeed. Please install it manually.")
  }
}
# Run setup
setup_python()

# Download thermal band (B6 if L <= 7, B10 if L8 or 9), MTL and QA_PIXEL 
setwd(LD_script)
token = 'IhL7fWN!6B_LEXNBl6G6O0tHjbbRQaKJgMukbcEmkjndacC0O39f7@pG0hfLlE2f'
username = 'chiara.richiardi'
system('pip install requests pandas')

command = paste0(
  "python downloader_all_sat_cc.py",
  " --token ", token,
  " --username ", username,
  " --bbox ", aoi_bb['x', 'min'], " ", aoi_bb['y', 'min'], 
  " ", aoi_bb['x', 'max'], " ", aoi_bb['y', 'max'],
  " --start_date ", start_date,
  " --end_date ", end_date,
  " --city ", citta,
  " --out_dir ", landsat,
  " --max_cloud ", cct
)
system(command)


#2.3 Get the DEM ----
# Source: Mapzen (elevatr package)
# https://cran.r-project.org/web/packages/elevatr/vignettes/introduction_to_elevatr.html#Get_Raster_Elevation_Data

data(lake)
aoisf <- aoi %>% project(lake) %>% tidyterra::as_sf()

# Per ottenere un dato a circa 30 m si parte dalla seguente formula:
# ground_resolution = (cos(latitude * pi/180) * 2 * pi * 6378137) / (256 * 2^zoom_level)
#latitude <- mean(st_coordinates(aoisf)[,2])
#zoom_level = 11 #round(log2((cos(latitude * pi/180) * 2 * pi * 6378137) / (30 * 256)),0) -1 

elevatr::set_opentopo_key("e86536257246d55c5683c82f441bfc71")
dem <- get_elev_raster(locations = aoisf, #z = zoom_level, 
                       src = "gl1",
                       #src = c("aws", "gl3", "gl1", "alos", "srtm15plus"), 
                       expand = 5000)
setwd(input)
writeRaster(dem,paste0(citta,"_DEM.tif"),overwrite = TRUE, 
            wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                      gdal=c("COMPRESS=LZW")))
print(paste("DEM per",citta,"ok, risoluzione",round(xres(dem),2)))
rm(dem)

#### Section 3 - LAND SURFACE TEMPERATURE PROCESSING ###########################
#3.1 Pre-processing Collection 2 level 2 ----
setwd(landsat)
lst.list <- list.files(path = ".", pattern = "*ST_B*")

coords <- rbind(
  c(aoi_bb["x","min"], aoi_bb["y","min"]),
  c(aoi_bb["x","min"], aoi_bb["y","max"]),
  c(aoi_bb["x","max"], aoi_bb["y","max"]),
  c(aoi_bb["x","max"], aoi_bb["y","min"]),
  c(aoi_bb["x","min"], aoi_bb["y","min"]) # repeat first point to close
)
aoi_poly <- vect(coords, type="polygons", crs="EPSG:4326") # prendi la bbox

n.scenes <- length(lst.list)

for (l in lst.list) {
  
  setwd(landsat)
  data <- as.Date(substr(l,18,25),format="%Y%m%d")
  
  if (data %within% interval(start_date,end_date)){
    scena <- substr(l,1,40)
    sensore <- substr(l,3,4)
    
    # Prendere le bande 6 o 10 e QA
    QA <- rast(list.files(path = getwd(), pattern = glob2rx(pattern = paste0(scena,"_QA_PIXEL*")), 
                          recursive = TRUE, full.names = TRUE))
    
    aoi_utm <- project(aoi_poly,QA)
    
    
    QA <- crop(QA,aoi_utm)
    
    # Maschera valori non validi e prendi banda termica
    if (sensore=="08"| sensore =="09") {
      
      QA[QA!=21824] <- NA 
      
      ST <- rast(list.files(path = getwd(), pattern = glob2rx(pattern = paste0(scena,"*B10*")), 
                            recursive = TRUE, full.names = TRUE)) %>% crop(aoi_utm)
    } else {
      
      ST <- rast(list.files(path = getwd(), pattern = glob2rx(pattern = paste0(scena,"*B6*")), 
                            recursive = TRUE, full.names = TRUE)) %>% crop(aoi_utm)
      
      QA[QA!=5440] <- NA
    }
    
    # Apply mask: set only masked pixels to NA
    ST <- mask(ST, clouds, maskvalues = 1, updatevalue = NA)
    
    
    # SE LA SCENA E' PER LA MAGGIOR PARTE NON VALIDA (>CCT%) SALTALA
    #if ((ncell(QA[is.na(QA)])*100/ncell(QA))>cct) {
      #print(paste(l,"skipped -",round(ncell(QA[is.na(QA)])*100/ncell(QA),0),"% cloudy"))
      #next
    #} else {
      #print(paste(l,"ok"))
    #}
    
    
    LST <- ((ST * 0.00341802) + 149.0)-273.15
    
    # Se il sensore è Landsat 7 applica destriping
    if (sensore=="07"& y>2003) {
      LST <- focal(LST, w=11, fun=mean, na.policy="only", na.rm=T)
    }
    
    LST <- mask(LST,QA) %>% 
      extend(ext(aoi_utm))
    
    if ((ncell(LST[is.na(LST)])*100/ncell(LST))>70) {
      print(paste(l,"skipped -",round(ncell(LST[is.na(LST)])*100/ncell(LST),0),"% cloudy/NA"))
      next
    } else {
      print(paste(l,"ok"))
    }
    
    dir.create(paste0(processing,"/",y,"_",season), showWarnings = FALSE)
    setwd(paste0(processing,"/",y,"_",season))
    writeRaster(LST,paste0(scena,"_LST.tif"),overwrite = TRUE, 
                wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                          gdal=c("COMPRESS=LZW")))
    rm(ST,QA,LST)
  }
}

#3.2 Calculate the seasonal mean LST ----
if (file.exists(paste0(processing,"/",y,"_",season))!=TRUE) {
  paste("No suitable scenes available - SUHI mapping not possible") # If there is no LST available stop
  stop()
} 
setwd(paste0(processing,"/",y,"_",season))
raster_files <- list.files(path = ".", pattern = glob2rx("*.tif$"), full.names = TRUE)
raster_list <- raster_files %>% lapply(rast)
reference <- raster_list[[1]]
resampled_list <- lapply(raster_list, function(r) {
  r_proj <- project(r, crs(reference))
  resample(r_proj, reference, method = "bilinear")
})

r <- rast(resampled_list)
aoi_utm_city <- project(aoi,r[[1]])
lst.mean <- app(r, fun = mean, na.rm = TRUE) %>% crop(aoi_utm_city)    # Mean

if ((ncell(lst.mean[is.na(lst.mean)])*100/ncell(lst.mean))==100) {
  print("No valid LST image for the season over the area. The process ends.")
  next
} else {
  
  setwd(output)
  writeRaster(lst.mean, filename=paste0(output,"/",season,"_",y,"_LST_MEAN.tif"), 
              overwrite=TRUE,datatype='FLT4S')
  
  if (nlyr(r)>2) {
    
    lst.sd <- app(r, fun = sd, na.rm = TRUE) %>% crop(aoi_utm_city)         # Standard deviation
    lst.iqr <- app(r, fun = IQR, na.rm = TRUE) %>% crop(aoi_utm_city)       # Interquantile range
    #lst.cv <- lst.sd/lst.mean %>% crop(aoi_utm_city)                       # Coefficient of variation
    lst.n_obs <- app(r, function(x) sum(!is.na(x))) %>% crop(aoi_utm_city)  # N. of valid observations
    
    # SD
    writeRaster(lst.sd, filename=paste0(output,"/",season,"_",y,"_LST_SD.tif"), 
                overwrite=TRUE,datatype='FLT4S')
    # IQR
    writeRaster(lst.iqr, filename=paste0(output,"/",season,"_",y,"_LST_IQR.tif"), 
                overwrite=TRUE,datatype='FLT4S')
    # N.OBS
    writeRaster(lst.n_obs, filename=paste0(output,"/",season,"_",y,"_LST_N_OBS.tif"), 
                overwrite=TRUE,datatype='FLT4S')
    rm(lst.sd, lst.iqr, lst.n_obs)
  }
  
}

# Genera metadato
rs <- crs(lst.mean, proj=T, describe=T, parse=T)

# 1) Estrazione delle informazioni di base
info_raster <- list(
  # Informazioni di identificazione
  title           = paste("LST media",season,y,citta),
  description     = paste0("Mappa della Land Surface Temperature media stagionale (°C) generata da dati Landsat per l'",season," dell'anno ", y),
  keywords        = c("LST", "raster", "satellite"),
  
  # Informazioni tecniche / spaziali
  #filename        = lst.mean,
  format          = "GeoTIFF",                      # o il formato effettivo
  crs             = paste0(rs$name,", ",rs$authority,":",rs$code),     # restituisce il sistema di riferimento
  extent          = as.list(ext(lst.mean)),         # bounding box (xmin, xmax, ymin, ymax)
  resolution      = res(lst.mean),                  # risoluzione in x e y
  ncol            = ncol(lst.mean),
  nrow            = nrow(lst.mean),
  nbands          = nlyr(lst.mean),                 # numero di layer/bande
  values_range    = minmax(lst.mean),  # min e max
  
  # Informazioni di autore e data
  creation_date   = as.character(Sys.Date()),
  author          = "SCIFT",
  license         = "GNU General Public License v3.0 ",
  url             = "https://municipiozero.it/scift/",
  DOI             = "fake_DOI"
)

# 3) Conversione in JSON e scrittura su file
#    Usando l'opzione pretty=TRUE si ottiene un file più leggibile
metadata_json <- toJSON(info_raster, pretty = TRUE)
write(metadata_json, file = paste0(output,"/",season,"_",y,"_LST_MEAN_metadata.json"))

#3.3 Visualize the seasonal mean LST ----
pal <- colorNumeric("Spectral", domain = c(minmax(lst.mean)[1],  minmax(lst.mean)[2]),reverse = TRUE)

leaflet() %>% 
  addTiles() %>% 
  addRasterImage(lst.mean, colors = pal, opacity = 0.8) %>% 
  addLegend(pal = pal, values = c(round(minmax(lst.mean)[1],2), round(minmax(lst.mean)[2],2)),
            title = paste("LST MEDIA (°C)"))

#### Section 4 – TEMPERATURE ANOMALIES COMPARED TO NON-URBAN AREAS #########
#4.1 Create mask from DEM ----
setwd(input)
dem <- rast(paste0(citta,"_DEM.tif")) %>% 
  project(lst.mean) %>% 
  resample(lst.mean)

# Imposto le aree urbanizzate
aree_urb <- vect("urban_areas.shp") %>% 
  project(lst.mean) %>%
  rasterize(lst.mean)

# Imposto aree naturali e semi-naturali lontane 300 m dall'urbano (T ref)
setwd(input)
aree_riferimento <- list.files(input, pattern=glob2rx("rural_areas.shp"))  

aree_ref <- vect(aree_riferimento) %>% 
  aggregate() %>% 
  project(lst.mean) %>%
  rasterize(lst.mean)

# Pulisco eventuali sovrapposizioni tra aree verdi e urbanizzate
aree_urb <- mask(aree_urb,aree_ref,inverse=TRUE)

# Elimina i poligoni nel raggio di 100 m dall'urbanizzato
aree_urb_buffer <- buffer(aree_urb,100,background=NA) 
aree_urb_buffer[aree_urb_buffer==0]<-NA
aree_ref <- mask(aree_ref,aree_urb_buffer,inverse=TRUE)

# Estrai il DEM sull'urbanizzato
dem_urb <- mask(dem, aree_urb)

# Trova le statistiche altitudinali delle aree urbane di interesse
media_altitudine <- as.integer(global(dem_urb, "mean", na.rm=TRUE))
max_altitudine <- as.integer(global(dem_urb, "max", na.rm=TRUE))
min_altitudine <- as.integer(global(dem_urb, "min", na.rm=TRUE))

cat(paste("Altitudine dell'urbanizzato:\nmedia",round(media_altitudine,0),"m s.l.m.\nmassima",round(max_altitudine,0),"m s.l.m.\nminima",round(min_altitudine,0),"m s.l.m."))

#4.2 Calculate altitudinal-wise SUHII ----
altezza_fascia <- 100  # Altezza fascia altitudinale 

fasce_altitudinali <- round((max_altitudine - min_altitudine)/altezza_fascia,0)

# Definisci fascia altitudinale di lavoro
min <- round(min_altitudine,-1)
max <- min + altezza_fascia

if (fasce_altitudinali>1) {
  
  for (f in 1:fasce_altitudinali) {
    # Imposta DEM
    dem_f <- dem
    
    # Prendi fascia altitudinale di 100 m
    dem_f[dem_f > max] <- NA   
    dem_f[dem_f <= min] <- NA
    
    # Maschero la LST al di fuori della fascia altitudinale
    lst.mean.masked <- mask(lst.mean,dem_f) 
    
    # Calcola la temperatura media dell'urbanizzato
    lst.aree.urb <- lst.mean.masked %>% 
      crop(aree_urb) %>% 
      mask(aree_urb)
    
    media_temp_URB <- as.numeric(global(lst.aree.urb, "mean", na.rm=TRUE))
    print(paste("LST media dell'urbanizzato",citta,round(media_temp_URB,2),"°C"))
    
    # Prendi la T°C media delle aree rurali di riferimento
    lst.aree.nat <- lst.mean.masked %>% 
      crop(aree_ref) %>% 
      mask(aree_ref) %>% 
      mask(aree_urb,inverse=TRUE)
    
    media_temp_REF <- as.numeric(global(lst.aree.nat, "mean", na.rm=TRUE))
    print(paste("LST media delle aree rurali",citta,round(media_temp_REF,2),"°C"))
    
    # Calcola anomalia termica
    anomalia_termica <- lst.mean.masked - media_temp_REF 
    aoi_utm <- project(aoi, anomalia_termica)
    anomalia_termica <- crop(anomalia_termica, aoi_utm) %>% 
      mask(aoi_utm)
    writeRaster(anomalia_termica,paste0(processing,"/",season,"_",y,"_thermal_anomaly_F",f,".tif"),overwrite = TRUE, 
                wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                          gdal=c("COMPRESS=LZW")))
    
    # Calcola SUHI index
    LSTmax <- as.integer(global(lst.mean.masked, "max", na.rm=TRUE))
    LSTmin <- as.integer(global(lst.mean.masked, "min", na.rm=TRUE))
    SUHI <- (lst.mean.masked - LSTmin)/(LSTmax - LSTmin)
    SUHI <- crop(SUHI, aoi_utm) %>% 
      mask(aoi_utm)
    writeRaster(SUHI,paste0(processing,"/",season,"_",y,"_SUHI_F",f,".tif"),overwrite = TRUE, 
                wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                          gdal=c("COMPRESS=LZW")))
    
    # Fascia successiva
    print(paste("Fascia da",min,"a",max,"m analizzata"))
    min <- min + altezza_fascia
    max <- max + altezza_fascia
  }
  
  #4.3 Riassembla mappa di anomalia termica ----
  setwd(processing)
  anomalia.list <- sprc(list.files(pattern=glob2rx(paste0(season,"_",y,"_thermal_anomaly_F*.tif"))))
  anomalia <- merge(anomalia.list)
  
  writeRaster(anomalia,paste0(output,"/",season,"_",y,"_thermal_anomaly.tif"),overwrite = TRUE, 
              wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                        gdal=c("COMPRESS=LZW")))
  
  # Genera metadato
  rs <- crs(anomalia, proj=T, describe=T, parse=T)
  
  # 1) Estrazione delle informazioni di base
  info_raster <- list(
    # Informazioni di identificazione
    title           = paste("Anomalia termica",season,y,citta),
    description     = paste0("Mappa dell'anomalia termica stagionale (°C) generata da dati Landsat per l'",season," dell'anno ", y),
    keywords        = c("UHI", "raster", "satellite"),
    
    # Informazioni tecniche / spaziali
    #filename        = lst.mean,
    format          = "GeoTIFF",                      # o il formato effettivo
    crs             = paste0(rs$name,", ",rs$authority,":",rs$code),     # restituisce il sistema di riferimento
    extent          = as.list(ext(anomalia)),         # bounding box (xmin, xmax, ymin, ymax)
    resolution      = res(anomalia),                  # risoluzione in x e y
    ncol            = ncol(anomalia),
    nrow            = nrow(anomalia),
    nbands          = nlyr(anomalia),                 # numero di layer/bande
    values_range    = minmax(anomalia),  # min e max
    
    # Informazioni di autore e data
    creation_date   = as.character(Sys.Date()),
    author          = "SCIFT",
    license         = "GNU General Public License v3.0 ",
    url             = "https://municipiozero.it/scift/",
    DOI             = "fake_DOI"
  )
  
  # 3) Conversione in JSON e scrittura su file
  #    Usando l'opzione pretty=TRUE si ottiene un file più leggibile
  metadata_json <- toJSON(info_raster, pretty = TRUE)
  write(metadata_json, file = paste0(output,"/",season,"_",y,"_thermal_anomaly_metadata.json"))
  
  ### Visualizza le anomalie termiche
  pal3 <- colorNumeric("Spectral", domain = c(minmax(anomalia)[1], minmax(anomalia)[2]),reverse = TRUE)
  
  leaflet() %>% 
    addTiles() %>% 
    addRasterImage(anomalia, colors = pal3, opacity = 0.8) %>% 
    addLegend(pal = pal3, values =c(minmax(anomalia)[1], minmax(anomalia)[2]),
              title = paste("ANOMALIA TERMICA (°C)"))
  
  #4.4 Riassembla mappa di SUHI index ----
  setwd(processing)
  SUHI.list <- sprc(list.files(pattern=glob2rx(paste0(season,"_",y,"_SUHI_F*.tif"))))
  SUHI <- merge(SUHI.list)
  SUHI[SUHI<0]<-0
  SUHI[SUHI>1]<-1
  
  writeRaster(SUHI,paste0(output,"/",season,"_",y,"_SUHI.tif"),overwrite = TRUE, 
              wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                        gdal=c("COMPRESS=LZW")))
  
  ### Genera metadato
  rs <- crs(SUHI, proj=T, describe=T, parse=T)
  
  # Estrazione delle informazioni di base
  info_raster <- list(
    # Informazioni di identificazione
    title           = paste("SUHI",season,y,citta),
    description     = paste0("Mappa della Surface Urban Heat Island (SUHI) stagionale (°C) generata da dati Landsat per l'",season," dell'anno ", y),
    keywords        = c("UHI", "raster", "satellite"),
    
    # Informazioni tecniche / spaziali
    format          = "GeoTIFF",                  # o il formato effettivo
    crs             = paste0(rs$name,", ",rs$authority,":",rs$code),     # restituisce il sistema di riferimento
    extent          = as.list(ext(SUHI)),         # bounding box (xmin, xmax, ymin, ymax)
    resolution      = res(SUHI),                  # risoluzione in x e y
    ncol            = ncol(SUHI),
    nrow            = nrow(SUHI),
    nbands          = nlyr(SUHI),                 # numero di layer/bande
    values_range    = minmax(SUHI),               # min e max
    
    # Informazioni di autore e data
    creation_date   = as.character(Sys.Date()),
    author          = "SCIFT",
    license         = "GNU General Public License v3.0 ",
    url             = "https://municipiozero.it/scift/",
    DOI             = "fake_DOI"
  )
  
  # Conversione in JSON e scrittura su file
  metadata_json <- toJSON(info_raster, pretty = TRUE)
  write(metadata_json, file = paste0(output,"/",season,"_",y,"_SUHI_metadata.json"))
  
  # Visualize SUHII index
  pal3 <- colorNumeric("Spectral", domain = c(0,1),reverse = TRUE)
  
  leaflet() %>% 
    addTiles() %>% 
    addRasterImage(SUHI, colors = pal3, opacity = 0.8) %>% 
    addLegend(pal = pal3, values = c(0,1),
              title = paste("SUHI"))
  
} else {
  
  # Prendi fascia altitudinale di 100 m
  dem[dem > (media_altitudine)+50] <- NA   
  dem[dem < (media_altitudine)-50] <- NA
  
  lst.mean.masked <- mask(lst.mean,dem) # Maschero dalla LST le aree troppo elevate
  
  writeRaster(lst.mean.masked,paste0(processing,"/LST_",season,"_",y,"_MEAN_MASKED.tif"),overwrite = TRUE, 
              wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999,
                        gdal=c("COMPRESS=LZW")))
  
  # Calcola la temperatura media dell'urbanizzato
  #aree_urb <- urbanizzato %>% 
  #aggregate() %>% 
  #project(lst.mean) 
  
  lst.aree.urb <- lst.mean.masked %>% 
    crop(aree_urb) %>% 
    mask(aree_urb)
  
  #writeRaster(lst.aree.urb,paste0(processing,"/LST_",season,"_",y,"_MEAN_MASKED_URBANIZZATO.tif"),overwrite = TRUE, 
  #wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999,
  #gdal=c("COMPRESS=LZW")))
  
  
  media_temp_URB <- as.numeric(global(lst.aree.urb, "mean", na.rm=TRUE))
  
  # Prendi la T°C media delle aree rurali di riferimento
  lst.aree.nat <- lst.mean.masked %>% 
    crop(aree_ref) %>% 
    mask(aree_ref) 
  
  media_temp_REF <- as.numeric(global(lst.aree.nat, "mean", na.rm=TRUE))
  
  # Calcola anomalia termica
  anomalia_termica <- lst.mean.masked - media_temp_REF 
  aoi_utm <- project(aoi, anomalia_termica)
  anomalia <- crop(anomalia_termica, aoi_utm) %>% 
    mask(aoi_utm)
  writeRaster(anomalia_termica,paste0(output,"/",season,"_",y,"_thermal_anomaly.tif"),overwrite = TRUE, 
              wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                        gdal=c("COMPRESS=LZW")))
  
  # Genera metadato
  rs <- crs(anomalia_termica, proj=T, describe=T, parse=T)
  
  # 1) Estrazione delle informazioni di base
  info_raster <- list(
    # Informazioni di identificazione
    title           = paste("Anomalia termica",season,y,citta),
    description     = paste0("Mappa dell'anomalia termica stagionale (°C) generata da dati Landsat per l'",season," dell'anno ", y),
    keywords        = c("UHI", "raster", "satellite"),
    
    # Informazioni tecniche / spaziali
    #filename        = lst.mean,
    format          = "GeoTIFF",                      # o il formato effettivo
    crs             = paste0(rs$name,", ",rs$authority,":",rs$code),     # restituisce il sistema di riferimento
    extent          = as.list(ext(anomalia_termica)),         # bounding box (xmin, xmax, ymin, ymax)
    resolution      = res(anomalia_termica),                  # risoluzione in x e y
    ncol            = ncol(anomalia_termica),
    nrow            = nrow(anomalia_termica),
    nbands          = nlyr(anomalia_termica),                 # numero di layer/bande
    values_range    = minmax(anomalia_termica),  # min e max
    
    # Informazioni di autore e data
    creation_date   = as.character(Sys.Date()),
    author          = "SCIFT",
    license         = "GNU General Public License v3.0 ",
    url             = "https://municipiozero.it/scift/",
    DOI             = "fake_DOI"
  )
  
  # 3) Conversione in JSON e scrittura su file
  #    Usando l'opzione pretty=TRUE si ottiene un file più leggibile
  metadata_json <- toJSON(info_raster, pretty = TRUE)
  write(metadata_json, file = paste0(output,"/",season,"_",y,"_thermal_anomaly_metadata.json"))
  
  ### Visualizza le anomalie termiche
  pal3 <- colorNumeric("Spectral", domain = c(minmax(anomalia_termica)[1], minmax(anomalia_termica)[2]),reverse = TRUE)
  
  leaflet() %>% 
    addTiles() %>% 
    addRasterImage(anomalia_termica, colors = pal3, opacity = 0.8) %>% 
    addLegend(pal = pal3, values =c(minmax(anomalia_termica)[1], minmax(anomalia_termica)[2]),
              title = paste("ANOMALIA TERMICA (°C)"))
  
  # Calcola SUHI index
  LSTmax <- as.integer(global(lst.mean.masked, "max", na.rm=TRUE))
  LSTmin <- as.integer(global(lst.mean.masked, "min", na.rm=TRUE))
  SUHI <- (lst.mean.masked - LSTmin)/(LSTmax - LSTmin)
  SUHI <- crop(SUHI, aoi_utm) %>% 
    mask(aoi_utm)
  SUHI[SUHI<0]<-0
  SUHI[SUHI>1]<-1
  
  writeRaster(SUHI,paste0(output,"/",season,"_",y,"_SUHI.tif"),overwrite = TRUE, 
              wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                        gdal=c("COMPRESS=LZW")))
  
  ### Genera metadato
  rs <- crs(SUHI, proj=T, describe=T, parse=T)
  
  # Estrazione delle informazioni di base
  info_raster <- list(
    # Informazioni di identificazione
    title           = paste("SUHI",season,y,citta),
    description     = paste0("Mappa della Surface Urban Heat Island (SUHI) stagionale (°C) generata da dati Landsat per l'",season," dell'anno ", y),
    keywords        = c("UHI", "raster", "satellite"),
    
    # Informazioni tecniche / spaziali
    format          = "GeoTIFF",                  # o il formato effettivo
    crs             = paste0(rs$name,", ",rs$authority,":",rs$code),     # restituisce il sistema di riferimento
    extent          = as.list(ext(SUHI)),         # bounding box (xmin, xmax, ymin, ymax)
    resolution      = res(SUHI),                  # risoluzione in x e y
    ncol            = ncol(SUHI),
    nrow            = nrow(SUHI),
    nbands          = nlyr(SUHI),                 # numero di layer/bande
    values_range    = minmax(SUHI),               # min e max
    
    # Informazioni di autore e data
    creation_date   = as.character(Sys.Date()),
    author          = "SCIFT",
    license         = "GNU General Public License v3.0 ",
    url             = "https://municipiozero.it/scift/",
    DOI             = "fake_DOI"
  )
  
  # Conversione in JSON e scrittura su file
  metadata_json <- toJSON(info_raster, pretty = TRUE)
  write(metadata_json, file = paste0(output,"/",season,"_",y,"_SUHI_metadata.json"))
  
  # Visualize SUHII index
  pal3 <- colorNumeric("Spectral", domain = c(0,1),reverse = TRUE)
  
  leaflet() %>% 
    addTiles() %>% 
    addRasterImage(SUHI, colors = pal3, opacity = 0.8) %>% 
    addLegend(pal = pal3, values = c(0,1),
              title = paste("SUHI"))
}
#### Section 5 - DISTANCE FROM GREEN AREAS #####################################
# Formula 3-30-300
# L'OMS ha proposto una formula, supportata da numerosi studi scientifici, per 
# garantire una “adeguata dose di natura” alle persone: la regola del 3-30-300: 
# 3 alberi tra ogni casa, 
# 30% di copertura arborea in ogni quartiere, 
# 300 metri di distanza massima da un parco o da uno spazio verde per ogni cittadino

# Calcola distanza da aree verdi (in m)
distance_raster <- distance(aree_ref) %>% 
  mask(aoi_utm)

distance_raster[distance_raster<300] <- NA

# Salva il risultato
setwd(output)
writeRaster(distance_raster, paste0(output,"/",season,"_",y,"_distance_green_areas.tif"),overwrite = TRUE, 
            wopt=list(filetype='GTiff', datatype='INT2S', NAflag = -9999, 
                      gdal=c("COMPRESS=LZW")))

# Visualizza il risultato
pal3 <- colorNumeric("Spectral", domain = c(-8, 8),reverse = TRUE)

leaflet() %>% 
  addTiles() %>% 
  addRasterImage(distance_raster, colors = pal3, opacity = 0.8) %>% 
  addLegend(pal = pal3, values = c(-5,5),
            title = paste("Distanza dalle aree verdi (m)"))

