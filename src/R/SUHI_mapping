########################################
# Isola di calore urbana superficiale #
#######################################

# Script per la mappatura delle isole di calore urbane superficiali

# Riferimenti: 
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
# SCRIVERE QUI LA CITTA DI INTERESSE
citta <- "Bologna"  
# SCRIVERE QUI IL PERCORSO DELLA CARTELLA DI LAVORO (A SCELTA)
percorso <- "/Users/federicobaldo/Repositories/heat_islands/"
# IMPOSTA LA STAGIONE DI INTERESSE
stagione <- "estate" # oppure "inverno"
################################################################################

#### Sezione 1 - OPERAZIONI PRELIMINARI ########################################
#1.1 Carica pacchetti ----
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
  "tidyr"
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


#1.2 Imposta e crea struttura cartelle ----
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

# Carica area di interesse
aoi_bb <- getbb(citta) #, format_out = "polygon", featuretype = "city", limit=1
aoi_bb


#### Sezione 2 - DATI DI INPUT  ################################################
#2.1 Prendi file vettoriali da OpenStreetMap ----
setwd(input)

#2.1.1 Confini comune ----
aoiosm <- aoi_bb %>%
  opq() %>%
  add_osm_feature("admin_level", value = "8") %>% 
  add_osm_feature("name", value = citta,
                  #key_exact = FALSE,
                  #value_exact = FALSE,
                  match_case = FALSE) %>% 
  osmdata_sf() 

if (length(aoiosm$osm_multipolygons)>0){
  aoi <- vect(aoiosm$osm_multipolygons) 
} else {
  aoi <- vect(aoi_bb, crs="EPSG:4326") # Se non trovasse i confini amministrativi, prendi la bbox
}


# Salva il dato
writeVector(aoi, filename="confini.shp", filetype="ESRI Shapefile",overwrite=TRUE, options="ENCODING=UTF-8")

# Visualizza il dato
aoisf <- sf::st_as_sf(aoi)

leaflet(aoisf) %>%
  addPolygons(
    fillOpacity = 0.4, smoothFactor = 0.5) %>%
  addTiles()

rm(aoisf)

#2.1.2 Aree rurali ----

#### Aree semi-naturali
natural <- aoi_bb %>%
  opq() %>%
  add_osm_feature("natural",value=c("fell","grassland","heath","moor","scrub",
                                    "shrubbery","tree","tree_row","tree_stump",
                                    "tundra","wood")) %>%
  osmdata_sf()
if (length(natural$osm_polygons)>0){
  aree_naturali.p <- vect(natural$osm_polygons) %>% makeValid()
  writeVector(aree_naturali.p, "aree_naturali_poly.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
}
if (length(natural$osm_multipolygons)>0){
  aree_naturali.m <- vect(natural$osm_multipolygons) %>% makeValid()
  writeVector(aree_naturali.m, "aree_naturali_multipoly.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
  
}
rm(natural,aree_naturali.m,aree_naturali.p)

#### Aree semi-naturali
agriculture <- aoi_bb %>%
  opq() %>%
  add_osm_feature("landuse", value = c("farmland", "farmyard", "paddy",
                                       "animal_keeping", "flowerbed","forest",
                                       "meadow","orchard","grass","meadow")) %>%
  osmdata_sf()
if (length(agriculture$osm_polygons)>0){
  aree_agricole.p <- vect(agriculture$osm_polygons) %>% makeValid()
  writeVector(aree_agricole.p, "aree_agricole_poly.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
}
if (length(agriculture$osm_multipolygons)>0){
  aree_agricole.m <- vect(agriculture$osm_multipolygons) %>% makeValid()
  writeVector(aree_agricole.m, "aree_agricole_multipoly.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
}
rm(agriculture,aree_agricole.m,aree_agricole.p)

#### Aree verdi
leisure <- aoi_bb %>%
  opq() %>%
  add_osm_feature("leisure", value=c("garden","golf_course","nature_reserve","park")) %>%
  osmdata_sf()
if (length(leisure$osm_multipolygons)>0){
  leisure.p <- vect(leisure$osm_multipolygons) %>% makeValid()
  writeVector(leisure.p, "aree_verdi_poly.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
}
if (length(leisure$osm_polygons)>0){
  leisure.m <- vect(leisure$osm_polygons) %>% makeValid()
  writeVector(leisure.m, "aree_verdi_multipoly.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
}
rm(leisure.p,leisure.m,leisure)

# Aree rurali totali
aree_riferimento <- list.files(input, pattern=glob2rx("aree_*.shp"))  %>%  
  purrr::map(\(f) sf::read_sf(f)  %>%  
               dplyr::mutate(source = f, .before = 1)) |> 
  purrr::list_rbind()  %>% 
  dplyr::as_tibble()  %>%  
  sf::st_sf() 

aree_rurali <-vect(aree_riferimento)
writeVector(aree_rurali, "zone_rurali.shp", filetype="ESRI Shapefile",
            overwrite=TRUE, options="ENCODING=UTF-8")

# Visualizza il dato
leaflet(aree_riferimento) %>%
  addPolygons(
    fillOpacity = 0.4, smoothFactor = 0.5) %>%
  addTiles()

#2.1.3 Aree urbanizzate ----
artificial <- aoi_bb %>%
  opq() %>%
  add_osm_feature("landuse", value = c("commercial", "construction", "education",
                                       "fairground", "industrial","residential",
                                       "retail","institutional","railway","aerodrome",
                                       "landfill","port","depot","quarry","military")) %>%
  osmdata_sf()
if (length(artificial$osm_multipolygons)>0){
  urbanizzato.p <- vect(artificial$osm_multipolygons) %>% makeValid()
  writeVector(urbanizzato.p, "urbanizzato_poly1.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
}

if (length(artificial$osm_polygons)>0){
  urbanizzato.m <- vect(artificial$osm_polygons) %>% makeValid()
  writeVector(urbanizzato.m, "urbanizzato_multipoly1.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
}
rm(urbanizzato.p, urbanizzato.m,artificial)

###
amenity <- aoi_bb %>%
  opq() %>%
  add_osm_feature("amenity") %>%
  osmdata_sf()
if (length(amenity$osm_multipolygons)>0){
  amenity.p <- vect(amenity$osm_multipolygons) %>% makeValid()
  writeVector(amenity.p, "urbanizzato_poly2.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
  rm(amenity.p)
}
if (length(amenity$osm_polygons)>0){
  
  amenity.m <- vect(amenity$osm_polygons) %>% makeValid()
  writeVector(amenity.m, "urbanizzato_multipoly2.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
  rm(amenity.m)
}
rm(amenity)

###
building <- aoi_bb %>%
  opq() %>%
  add_osm_feature("building") %>%
  osmdata_sf()
if (length(building$osm_multipolygons)>0){
  building.p <- vect(building$osm_multipolygons) %>% makeValid()
  writeVector(building.p, "urbanizzato_poly7.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
  rm(building.p)
}
if (length(building$osm_polygons)>0){
  
  building.m <- vect(building$osm_polygons) %>% makeValid()
  writeVector(building.m, "urbanizzato_multipoly7.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
  rm(building.m)
}
rm(building)

### 
tourism <- aoi_bb %>%
  opq() %>%
  add_osm_feature("tourism") %>%
  osmdata_sf()
if (length(tourism$osm_multipolygons)>0){
  tourism.p <- vect(tourism$osm_multipolygons) %>% makeValid()
  writeVector(tourism.p, "urbanizzato_poly3.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
}

if (length(tourism$osm_polygons)>0){
  tourism.m <- vect(tourism$osm_polygons) %>% makeValid()
  writeVector(tourism.m, "urbanizzato_multipoly3.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
}

rm(tourism.p,tourism.m,tourism)

### 
leisure <- aoi_bb %>%
  opq() %>%
  add_osm_feature("leisure", value=c("adult_gaming_centre","amusement_arcade","bandstand",
                                     "beach_resort", "bleachers","bowling_alley", "common",
                                     "dance","disc_golf_course","fitness_centre","fitness_station",
                                     "hackerspace","ice_rink","marina","miniature_golf",
                                     "outdoor_seating","playground","resort","sauna","slipway",
                                     "sports_centre","sport_hall","stadium","summer_camp",
                                     "swimming_pool","tanning_salon", "track","trampoline_park",
                                     "water_park")) %>%
  osmdata_sf()
if (length(leisure$osm_multipolygons)>0){
  leisure.p <- vect(leisure$osm_multipolygons) %>% makeValid()
  writeVector(leisure.p, "urbanizzato_poly4.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
}
if (length(leisure$osm_polygons)>0) {
  leisure.m <- vect(leisure$osm_polygons) %>% makeValid()
  writeVector(leisure.m, "urbanizzato_multipoly4.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
}
rm(leisure.p,leisure.m,leisure)

###
aereoporto <- aoi_bb %>%
  opq() %>%
  add_osm_feature("aeroway", value = c("aerodrome", "apron", "gate","hangar", "spaceport",
                                       "helipad","runway","taxiway","terminal"))  %>%
  osmdata_sf()

if (length(aereoporto$osm_multipolygons)>0){
  urbanizzato.p <- vect(aereoporto$osm_multipolygons) %>% makeValid()
  writeVector(urbanizzato.p, "urbanizzato_poly5.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
  rm(urbanizzato.p)
}
if (length(aereoporto$osm_polygons)>0){
  urbanizzato.m <- vect(aereoporto$osm_polygons) %>% makeValid()
  writeVector(urbanizzato.m, "urbanizzato_multipoly5.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
  rm(urbanizzato.m)
}

rm(aereoporto)

### 
highway <- aoi_bb %>%
  opq() %>%
  add_osm_feature("highway") %>%
  osmdata_sf()

if (length(highway$osm_multipolygons)>0){
  highway.p <- vect(highway$osm_multipolygons) %>% makeValid()
  writeVector(highway.p, "urbanizzato_poly6.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
}
if (length(highway$osm_polygons)>0){
  highway.m <- vect(highway$osm_polygons) %>% makeValid()
  writeVector(highway.m, "urbanizzato_multipoly6.shp", filetype="ESRI Shapefile",
              overwrite=TRUE, options="ENCODING=UTF-8")
}
rm(highway.p,highway.m,highway)


### Unisci tutte le aree impermeabilizzate
aree_urbanizzate <- list.files(input, pattern=glob2rx("urbanizzato_*.shp"))  %>%  
  purrr::map(\(f) sf::read_sf(f)  %>%  
               dplyr::mutate(source = f, .before = 1)) |> 
  purrr::list_rbind()  %>% 
  dplyr::as_tibble()  %>%  
  sf::st_sf() 
aree_urb <- vect(aree_urbanizzate)

# Rimuovi eventuali sovrapposizioni con aree rurali
#st_aree_urb <- as_sf(aree_urb)
#st_aree_rurali <- as_sf(aree_rurali)
#cropped <-st_crop(st_aree_urb$geometry, st_aree_rurali$geometry)

writeVector(aree_urb, "urbanizzato_merge.shp", filetype="ESRI Shapefile",
            overwrite=TRUE, options="ENCODING=UTF-8")
rm(aree_urb)

# visualizza il dato
leaflet(aree_urbanizzate) %>%
  addPolygons(
    fillOpacity = 0.4, smoothFactor = 0.5) %>%
  addTiles()


#2.2 Download Landsat Collection 2 Level 2 ----
# Imposta la finestra temporale di download, selezionando 
# l'anno dell'ultima stagione completa disponibile
oggi <- Sys.Date()
y <- format(Sys.Date(), "%Y")
if (stagione == "estate") {
  start_date <- paste0(y,"-06-21")
  end_date <- paste0(y,"-09-21")
} else if (stagione == "inverno") {
  start_date <- paste0(y,"-12-21")
  end_date <- paste0(y+1,"-03-21")
}

# Se oggi cade prima dell'ultimo giorno della stagione imposta l'anno precedente
if (oggi < end_date) {
  y <- as.integer(y)-1
  if (stagione == "estate") {
    start_date <- paste0(y,"-06-21")
    end_date <- paste0(y,"-09-21")
  } else if (stagione == "inverno") {
    start_date <- paste0(y,"-12-21")
    end_date <- paste0(y+1,"-03-21")
  }
} 

print(paste0("Analisi per ", citta, " sull'", stagione," dell'anno ",y,
             " (dal ",start_date," al ",end_date,")"))

#use_virtualenv(paste0(percorso, "/env"))
#dir.create(paste0(input,"/Landsat/",y), showWarnings = FALSE)
##
#path_to_python <- "C:/Users/chiar/AppData/Local/Programs/Python/Python312"
#use_python("C:/Users/chiar/AppData/Local/Programs/Python/Python312/python.exe")
##

# Download della banda termica (B6 se L <= 7, B10 se L8 o 9), del MTL e della QA_PIXEL
setwd(percorso)
token = 'test'
username = 'Matteo22'
system('pip3 install requests pandas')
command = paste0('python3 downloader.py --token ',token,
                 ' --username ', username,
                 ' --bbox ', aoi_bb['x', 'min'], ' ' , aoi_bb['y', 'min'], ' ' ,aoi_bb['x', 'max'], ' ', aoi_bb['y', 'max'],
                 ' --start_date ', start_date,  
                 ' --end_date ', end_date,
                 ' --city ', citta)

system(command)
setwd(landsat)


#2.3 Prendi il DEM ----
# Fonte: Mapzen ha combinato diverse di queste fonti per creare un prodotto altimetrico 
# di sintesi che utilizza i migliori dati altimetrici disponibili per una determinata 
# regione a un determinato livello di zoom.
# https://cran.r-project.org/web/packages/elevatr/vignettes/introduction_to_elevatr.html#Get_Raster_Elevation_Data

data(lake)
aoisf <- aoi %>% project(lake) %>% tidyterra::as_sf()
# Per ottenere un dato a circa 30 m si parte dalla seguente formula:
# ground_resolution = (cos(latitude * pi/180) * 2 * pi * 6378137) / (256 * 2^zoom_level)
latitude <- mean(st_coordinates(aoisf)[,2])
zoom_level = 11 #round(log2((cos(latitude * pi/180) * 2 * pi * 6378137) / (30 * 256)),0) -1 
dem <- get_elev_raster(locations = aoisf, z = zoom_level, 
                       src = c("aws", "gl3", "gl1", "alos", "srtm15plus"), expand = 5000)
setwd(input)
writeRaster(dem,paste0(citta,"_DEM.tif"),overwrite = TRUE, 
            wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                      gdal=c("COMPRESS=LZW")))
print(paste("DEM per",citta,"ok, risoluzione",round(xres(dem),2)))
rm(dem)

#### Sezione 3 - ELABORAZIONE DELLA LAND SURFACE TEMPERATURE ###################
#3.1 Processing Collection 2 level 2 ----
setwd(landsat)
lst.list <- list.files(path = ".", pattern = "*ST_B*")

for (l in lst.list) {
  
  setwd(landsat)
  data <- as.Date(substr(l,18,25),format="%Y%m%d")
  
  if (data %within% interval(start_date,end_date)){
    scena <- substr(l,1,40)
    sensore <- substr(l,3,4)
    
    # Prendere le bande 6 o 10 e QA
    QA <- rast(list.files(path = getwd(), pattern = glob2rx(pattern = paste0(scena,"_QA_PIXEL*")), 
                          recursive = TRUE, full.names = TRUE))
    aoi_utm <- project(aoi,QA)
    QA <- crop(QA,aoi_utm)
    
    # Maschera valori non validi e prendi banda termica
    if (sensore=="08"| sensore =="09") {
      
      QA[QA!=21824] <- NA 
      
      ST <- rast(list.files(path = getwd(), pattern = glob2rx(pattern = paste0(scena,"*ST_B10*")), 
                            recursive = TRUE, full.names = TRUE)) %>% crop(aoi_utm)
    } else {
      
      ST <- rast(list.files(path = getwd(), pattern = glob2rx(pattern = paste0(scena,"*ST_B6*")), 
                            recursive = TRUE, full.names = TRUE)) %>% crop(aoi_utm)
      
      QA[QA!=5440] <- NA
    }
    
    # SE LA SCENA E' PER LA MAGGIOR PARTE NON VALIDA (>70%) SALTALA
    if ((ncell(QA[is.na(QA)])*100/ncell(QA))>70) {
      print(paste(l,"skipped -",round(ncell(QA[is.na(QA)])*100/ncell(QA),0),"% cloudy"))
      next
    } else {
      print(paste(l,"ok"))
    }
    
    
    LST <- ((ST * 0.00341802) + 149.0)-273.15
    
    # Se il sensore è Landsat 7 applica destriping
    if (sensore=="07"& y>2003) {
      LST <- focal(LST, w=11, fun=mean, na.policy="only", na.rm=T)
    }
    
    LST <- mask(LST,QA)
    
    dir.create(paste0(processing,"/",y,"_",stagione), showWarnings = FALSE)
    setwd(paste0(processing,"/",y,"_",stagione))
    writeRaster(LST,paste0(scena,"_LST.tif"),overwrite = TRUE, 
                wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                          gdal=c("COMPRESS=LZW")))
    rm(ST,QA,LST)
  }
}

#3.2 Calcola LST media stagionale ----
setwd(paste0(processing,"/",start_date))
list.files(path = ".", pattern = glob2rx("*L2SP*.tif"))
r <- rast(list.files(path = ".", pattern = glob2rx("*L2SP*.tif")))
output
lst.mean <- app(r, fun = mean, na.rm = TRUE,cores=8, 
                filename=paste0(output,"/",start_date,"_LST_MEAN.tif"), 
                overwrite=TRUE,datatype='FLT4S') 

#3.3 Visualizza la LST media stagionale ----
pal <- colorNumeric("Spectral", domain = c(minmax(lst.mean)[1],  minmax(lst.mean)[2]),reverse = TRUE)

leaflet() %>% 
  addTiles() %>% 
  addRasterImage(lst.mean, colors = pal, opacity = 0.8) %>% 
  addLegend(pal = pal, values = c(round(minmax(lst.mean)[1],2), round(minmax(lst.mean)[2],2)),
            title = paste("LST MEDIA (°C)"))

#### Sezione 4 – ANOMALIE DI TEMPERATURA RISPETTO ALLE AREE NON URBANE #########
#4.1 Crea maschera da DEM ----
setwd(input)
dem <- rast(paste0(citta,"_DEM.tif")) %>% 
  project(lst.mean) %>% 
  resample(lst.mean)

# Imposto le aree urbanizzate
aree_urb <- vect("urbanizzato_merge.shp") %>% 
  project(lst.mean) %>%
  rasterize(lst.mean)

# Imposto aree naturali e semi-naturali lontane 300 m dall'urbano (T ref)
setwd(input)
aree_riferimento <- list.files(input, pattern=glob2rx("zone_rurali.shp"))  

aree_ref <- vect(aree_riferimento) %>% 
  aggregate() %>% 
  project(lst.mean) %>%
  rasterize(lst.mean)

# Pulisco eventuali sovrapposizioni tra aree verdi e urbanizzate
aree_urb <- mask(aree_urb,aree_ref,inverse=TRUE)

# Elimina i poligoni più nel raggio di 100 m dall'urbanizzato
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

#4.2 Calcola fasce altitudinali ----
altezza_fascia <- 100  # Altezza fascia altitudinale 

fasce_altitudinali <- round(max_altitudine - min_altitudine,-1)/altezza_fascia

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
    print(paste("LST media dell'urbanizzato",round(media_temp_URB,2),"°C"))
    
    # Prendi la T°C media delle aree rurali di riferimento
    lst.aree.nat <- lst.mean.masked %>% 
      crop(aree_ref) %>% 
      mask(aree_ref) %>% 
      mask(aree_urb,inverse=TRUE)
    
    media_temp_REF <- as.numeric(global(lst.aree.nat, "mean", na.rm=TRUE))
    print(paste("LST media delle aree rurali",round(media_temp_REF,2),"°C"))
    
    # Calcola anomalia termica
    anomalia_termica <- lst.mean.masked - media_temp_REF 
    aoi_utm <- project(aoi, anomalia_termica)
    anomalia_termica <- crop(anomalia_termica, aoi_utm) %>% 
      mask(aoi_utm)
    writeRaster(anomalia_termica,paste0(processing,"/",stagione,"_",y,"_ANOMALIA_TERMICA_F",f,".tif"),overwrite = TRUE, 
                wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                          gdal=c("COMPRESS=LZW")))
    
    # Calcola SUHI index
    LSTmax <- as.integer(global(lst.mean.masked, "max", na.rm=TRUE))
    LSTmin <- as.integer(global(lst.mean.masked, "min", na.rm=TRUE))
    SUHI <- (lst.mean.masked - LSTmin)/(LSTmax - LSTmin)
    SUHI <- crop(SUHI, aoi_utm) %>% 
      mask(aoi_utm)
    writeRaster(SUHI,paste0(processing,"/",stagione,"_",y,"_SUHI_F",f,".TIF"),overwrite = TRUE, 
                wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                          gdal=c("COMPRESS=LZW")))
    
    # Fascia successiva
    print(paste("Fascia da",min,"a",max,"m analizzata"))
    min <- min + altezza_fascia
    max <- max + altezza_fascia
  }
  
  #4.3 Riassembla mappa di anomalia termica ----
  setwd(processing)
  anomalia.list <- sprc(list.files(pattern=glob2rx(paste0(stagione,"_",y,"_ANOMALIA_TERMICA_F*.tif"))))
  anomalia <- merge(anomalia.list)
  
  writeRaster(anomalia,paste0(output,"/",stagione,"_",y,"_ANOMALIA_TERMICA.tif"),overwrite = TRUE, 
              wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                        gdal=c("COMPRESS=LZW")))
  
  # Visualizza le anomalie termiche
  pal3 <- colorNumeric("Spectral", domain = c(-8, 8),reverse = TRUE)
  
  leaflet() %>% 
    addTiles() %>% 
    addRasterImage(anomalia, colors = pal3, opacity = 0.8) %>% 
    addLegend(pal = pal3, values = c(-5,5),
              title = paste("ANOMALIA TERMICA (°C)"))
  
  #4.4 Riassembla mappa di SUHI index ----
  setwd(processing)
  SUHI.list <- sprc(list.files(pattern=glob2rx(paste0(stagione,"_",y,"_SUHI_F*.tif"))))
  SUHI <- merge(SUHI.list)
  SUHI[SUHI<0]<-0
  SUHI[SUHI>1]<-1
  
  writeRaster(SUHI,paste0(output,"/",stagione,"_",y,"_SUHI.tif"),overwrite = TRUE, 
              wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                        gdal=c("COMPRESS=LZW")))
  
  # Visualizza il SUHI index
  pal3 <- colorNumeric("Spectral", domain = c(-8, 8),reverse = TRUE)
  
  leaflet() %>% 
    addTiles() %>% 
    addRasterImage(SUHI, colors = pal3, opacity = 0.8) %>% 
    addLegend(pal = pal3, values = c(-5,5),
              title = paste("SUHI"))
  
} else {
  
  # Prendi fascia altitudinale di 100 m
  dem[dem > (media_altitudine)+50] <- NA   
  dem[dem < (media_altitudine)-50] <- NA
  
  lst.mean.masked <- mask(lst.mean,dem) # Maschero dalla LST le aree troppo elevate
  
  writeRaster(lst.mean.masked,paste0(processing,"/LST_",stagione,"_",y,"_MEAN_MASKED.tif"),overwrite = TRUE, 
              wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999,
                        gdal=c("COMPRESS=LZW")))
  
  # Calcola la temperatura media dell'urbanizzato
  aree_urb <- urbanizzato %>% 
    aggregate() %>% 
    project(lst.mean) 
  
  lst.aree.urb <- lst.mean.masked %>% 
    crop(aree_urb) %>% 
    mask(aree_urb)
  
  writeRaster(lst.aree.urb,paste0(processing,"/LST_",stagione,"_",y,"_MEAN_MASKED_URBANIZZATO.tif"),overwrite = TRUE, 
              wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999,
                        gdal=c("COMPRESS=LZW")))
  
  
  media_temp_URB <- as.numeric(global(lst.aree.urb, "mean", na.rm=TRUE))
  
  # Prendi la T°C media delle aree rurali di riferimento
  lst.aree.nat <- lst.mean.masked %>% 
    crop(aree_ref) %>% 
    mask(aree_ref) 
  
  media_temp_REF <- as.numeric(global(lst.aree.nat, "mean", na.rm=TRUE))
  
  # Calcola anomalia termica
  anomalia <- lst.mean.masked - media_temp_REF 
  aoi_utm <- project(aoi, anomalia)
  anomalia <- crop(anomalia, aoi_utm) %>% 
    mask(aoi_utm)
  writeRaster(anomalia,paste0(output,"/",stagione,"_",y,"_ANOMALIA_TERMICA.tif"),overwrite = TRUE, 
              wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                        gdal=c("COMPRESS=LZW")))
  
  # Calcola SUHI index
  LSTmax <- as.integer(global(lst.mean.masked, "max", na.rm=TRUE))
  LSTmin <- as.integer(global(lst.mean.masked, "min", na.rm=TRUE))
  SUHI <- (lst.mean.masked - LSTmin)/(LSTmax - LSTmin)
  SUHI <- crop(SUHI, aoi_utm) %>% 
    mask(aoi_utm)
  SUHI[SUHI<0]<-0
  SUHI[SUHI>1]<-1
  
  writeRaster(SUHI,paste0(output,"/",stagione,"_",y,"_SUHI.tif"),overwrite = TRUE, 
              wopt=list(filetype='GTiff', datatype='FLT4S', NAflag = -9999, 
                        gdal=c("COMPRESS=LZW")))
  
}


#### Sezione 5 - DISTANZA DALLE AREE VERDI #####################################
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
writeRaster(distance_raster, paste0(output,"/",stagione,"_",y,"_distanza_aree_verdi.tif"),overwrite = TRUE, 
            wopt=list(filetype='GTiff', datatype='INT2S', NAflag = -9999, 
                      gdal=c("COMPRESS=LZW")))

# Visualizza il risultato
pal3 <- colorNumeric("Spectral", domain = c(-8, 8),reverse = TRUE)

leaflet() %>% 
  addTiles() %>% 
  addRasterImage(distance_raster, colors = pal3, opacity = 0.8) %>% 
  addLegend(pal = pal3, values = c(-5,5),
            title = paste("Distanza dalle aree verdi (m)"))

#### Sezione 6 - STATISTICHE ###################################################
# Remove NA values (to ensure the lengths match for correlation)
df <- c(SUHI,distance_raster) %>% 
  as.data.frame() %>% 
  na.omit()

# Compute Correlation
correlation <- round(cor(df$layer, df$mean, method = "pearson"),3)

# Print the correlation result
print(paste("Correlazione tra distanza da aree verdi e SUHI:", correlation))

# Plot the relationship
plot(df$layer, df$mean, main="Correlazione distanza da aree verdi e SUHI",
     xlab="Distanza dalle aree verdi", ylab="SUHI",
     pch=19, col=adjustcolor("blue", alpha.f = 0.5))
abline(lm(df$mean ~ df$layer), col="red")  # Add a regression line
