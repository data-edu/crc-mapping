library(shiny)
library(mapboxer)
library(dplyr)
library(shinythemes)
library(haven)
library(urbnmapr)
library(tidyverse)
library(tidycensus)

# counties_sf <- get_urbn_map("counties", sf = TRUE)
# write_rds(counties_sf, "counties_sf.rds")

counties_sf <- read_rds("counties_sf.rds")

# Sys.setenv(PATH = paste("/opt/homebrew/bin", Sys.getenv("PATH"), sep = ":"))
# Sys.setenv(PROJ_LIB = "/opt/homebrew/Cellar/proj/9.4.1/share/proj")
# Sys.setenv(GDAL_CONFIG = "/opt/homebrew/bin/gdal-config")

counties_sf <- sf::st_transform(counties_sf, crs = 4326)

counties_sf <- counties_sf %>% 
  as_mapbox_source()

source("token.R")

# ipeds_green <- read_dta("ipeds&green.dta")
# 
# ipeds_green_summed <- ipeds_green %>% 
#   group_by(unitid, greencat) %>% 
#   summarize(sum_cmplt_green = sum(cmplt_tot)) %>% 
#   filter(greencat != "") %>% 
#   spread(greencat, sum_cmplt_green)
# 
# write_rds(ipeds_green_summed, "ipeds_green_summed.rds")

ipeds_green_summed <- read_rds("ipeds_green_summed.rds")

# hdallyears <- read_dta("hdallyears.dta")
# 
# hdallyears <- hdallyears %>%
#   filter(year == 2020)
# 
# write_rds(hdallyears, "hdallyears.rds")
hdallyears <- read_rds("hdallyears.rds")

hdallyears_joined <- hdallyears %>% 
  left_join(ipeds_green_summed, by = "unitid")

ui <- fluidPage(theme = shinytheme("flatly"),
                
                # Application title
                titlePanel("CRC Mapping Sandbox"),
                
                # Sidebar with a slider input for number of bins 
                sidebarLayout(
                  sidebarPanel(width = 3,
                               selectInput("selected_green_category",
                                           "Select category:",
                                           choices = c("Green New & Emerging", "Green Enhanced Skills", "Green Increased Demand")),
                  ),
                  
                  # Show a plot of the generated distribution
                  mainPanel(
                    mapboxerOutput("map")
                  )
                )
)

server <- function(input, output) {
  
  output$map <- renderMapboxer({

    hdallyears_joined %>% 
      select(instnm, longitud, latitude, input$selected_green_category) %>% 
      rename(greencat = 4) %>%
      as_mapbox_source(lng = "longitud", lat = "latitude") %>%
      
      # Setup a map with the default source above
      mapboxer(
        style = "mapbox://styles/mapbox/light-v10",
        center = c(-95, 40),
        zoom = 2.5,
        token = mapbox_token
      ) %>%
      
      # Add a navigation control
      add_navigation_control() %>%
      
      # Add a layer styling the data of the default source
      add_circle_layer(
        circle_color = "black",
        circle_radius = list(
          "greencat" = "size"
        ),
        popup = "Institution: {{instnm}}"
      ) %>% 
      
      add_fill_layer(
        source = counties_sf,
        fill_color = "gray",  # Set the fill color
        fill_opacity = 0.1,  # Adjust transparency
        fill_outline_color = "gray"  # Optional: add an outline
      )
    
  })
}

# Run the application 
shinyApp(ui = ui, server = server)