# prep-data.R

library(tidyverse)
library(sf)
library(urbnmapr)

tn_test <- read_dta("raw-data/TN_test.dta") # lightcast/jobs posting data

tn_test

counties_sf <- get_urbn_map("counties", sf = TRUE)
write_rds(counties_sf, "counties_sf.rds")

counties_sf <- read_rds("counties_sf.rds")

tn_test <- tn_test %>%
  rename(county_fips = countyfips) %>% 
  select(county_fips, unique_postings = uniquepostingsfromjan2010)

counties_sf <- counties_sf %>% 
  left_join(tn_test)

# can probably ignore these
# Sys.setenv(PATH = paste("/opt/homebrew/bin", Sys.getenv("PATH"), sep = ":"))
# Sys.setenv(PROJ_LIB = "/opt/homebrew/Cellar/proj/9.4.1/share/proj")
# Sys.setenv(GDAL_CONFIG = "/opt/homebrew/bin/gdal-config")

counties_sf <- st_transform(counties_sf, crs = 4326)

counties_sf <- counties_sf %>% 
  as_mapbox_source()

counties_sf %>% write_rds("counties_sf_processed.rds")

source("token.R")

ipeds_green <- read_dta("raw-data/ipeds&green.dta")

ipeds_green_summed <- ipeds_green %>%
  group_by(unitid, greencat) %>%
  summarize(sum_cmplt_green = sum(cmplt_tot)) %>%
  filter(greencat != "") %>%
  spread(greencat, sum_cmplt_green)

ipeds_green_summed <- ipeds_green_summed %>% 
  pivot_longer(-unitid, names_to = "greencat", values_to = "size")

write_rds(ipeds_green_summed, "ipeds_green_summed.rds")



hdallyears <- read_dta("raw-data/hdallyears.dta")

hdallyears <- hdallyears %>%
  filter(year == 2020)

write_rds(hdallyears, "hdallyears.rds")



