###########
## this version add clear btn
############



## loading packages

library(shiny)
library(mapboxer)
library(shinythemes)
library(haven)
library(sf)
library(dplyr)
library(readr)
source("mapboxtoken_setup.R") # setting up the mapbox token

## loading data

hdallyears <- read_rds("hdallyears.rds") # demand side data
ipeds_green_summed <- read_rds("ipeds_green_summed.rds") # supply-side data
counties_sf <- read_rds("counties_sf_processed.rds") # county shapes

## data preparation
hdallyears_joined <- hdallyears %>% 
  left_join(ipeds_green_summed, by = "unitid")

## app
ui <- fluidPage(
  theme = shinytheme("flatly"),
  titlePanel("CCRC Mapping Sandbox"),
  
  # Search input and clear button
  fluidRow(
    column(
      width = 10, 
      div(
        style = "display: flex; align-items: center;",
        textInput("search_term", "Search by Institution, County, or State:", placeholder = "Type institution, county, or state here...", width = "100%"),
        actionButton("search_btn", "Search", style = "margin-left: 15px;"),
        actionButton("clear_btn", "Clear", style = "margin-left: 15px;") # Clear button
      )
    )
  ),
  
  # Selectors for supply and demand categories
  fluidRow(
    column(6, align = "center",
           selectInput("selected_green_category",
                       "Select Supply Category:",
                       choices = c("Green New & Emerging", "Green Enhanced Skills", "Green Increased Demand"))
    ),
    column(6, align = "center",
           selectInput("selected_demand_variable",
                       "Select Demand Variable:",
                       choices = c("unique_postings"),
                       selected = "unique_postings")
    )
  ),
  
  # Map output
  fluidRow(
    column(12, mapboxerOutput("map", height = "700px"))
  )
)

server <- function(input, output, session) {
  
  # Reactive values to manage map state and marker
  map_state <- reactiveValues(
    lng = -95,
    lat = 40,
    zoom = 2.5,
    marker_lng = NULL,
    marker_lat = NULL
  )
  
  # Render the initial map
  output$map <- renderMapboxer({
    hdallyears_joined %>% 
      select(instnm, countynm, stabbr, longitud, latitude, greencat, size) %>% 
      filter(greencat == input$selected_green_category) %>%
      as_mapbox_source(lng = "longitud", lat = "latitude") %>%
      mapboxer(
        style = "mapbox://styles/mapbox/streets-v11",
        center = c(map_state$lng, map_state$lat),
        zoom = map_state$zoom,
        token = mapbox_token
      ) %>%
      add_navigation_control() %>%
      add_circle_layer(
        circle_color = "green",
        circle_radius = list(
          "interpolate", list("linear"), list("get", "size"), 
          0, 1, 
          500, 2, 
          1000, 4, 
          5000, 8
        ),
        popup = "Institution: {{instnm}}, Graduates: {{size}}"
      ) %>%
      add_fill_layer(
        source = counties_sf,
        fill_color = list(
          "property" = "unique_postings",
          "stops" = list(
            list(0, "#fff5f0"),
            list(10000, "#fcbba1"),
            list(30000, "#fb6a4a"),
            list(50000, "#cb181d")
          )
        ),
        fill_opacity = 0.8,
        fill_outline_color = "gray"
      )
  })
  
  # Search functionality
  observeEvent(input$search_btn, {
    search_term <- input$search_term
    if (search_term != "") {
      coords <- hdallyears_joined %>%
        filter(grepl(search_term, instnm, ignore.case = TRUE)) %>%
        select(instnm, longitud, latitude, size) %>%
        slice(1)
      
      if (nrow(coords) == 0 || is.na(coords$longitud) || is.na(coords$latitude)) {
        showNotification("No matching results or invalid coordinates.", type = "error")
        return()
      }
      
      lng <- as.numeric(coords$longitud)
      lat <- as.numeric(coords$latitude)
      instnm <- coords$instnm
      size <- coords$size
      
      # Update map state
      map_state$lng <- lng
      map_state$lat <- lat
      map_state$zoom <- 8
      map_state$marker_lng <- lng
      map_state$marker_lat <- lat
      
      # Re-render the map with a marker and popup
      output$map <- renderMapboxer({
        hdallyears_joined %>% 
          select(instnm, countynm, stabbr, longitud, latitude, greencat, size) %>% 
          filter(greencat == input$selected_green_category) %>%
          as_mapbox_source(lng = "longitud", lat = "latitude") %>%
          mapboxer(
            style = "mapbox://styles/mapbox/streets-v11",
            center = c(map_state$lng, map_state$lat),
            zoom = map_state$zoom,
            token = mapbox_token
          ) %>%
          add_navigation_control() %>%
          add_circle_layer(
            circle_color = "green",
            circle_radius = list(
              "interpolate", list("linear"), list("get", "size"), 
              0, 1, 
              500, 2, 
              1000, 4, 
              5000, 8
            ),
            popup = "Institution: {{instnm}}, No: {{size}}"
          ) %>%
          add_marker(
            lng = map_state$marker_lng, 
            lat = map_state$marker_lat, 
            popup = paste("Institution:", instnm, "<br>No:", size)
          ) %>%
          add_fill_layer(
            source = counties_sf,
            fill_color = list(
              "property" = "unique_postings",
              "stops" = list(
                list(0, "#fff5f0"),
                list(10000, "#fcbba1"),
                list(30000, "#fb6a4a"),
                list(50000, "#cb181d")
              )
            ),
            fill_opacity = 0.8,
            fill_outline_color = "gray"
          )
      })
    } else {
      showNotification("Search term is empty.", type = "error")
    }
  })
  
  # Clear functionality
  observeEvent(input$clear_btn, {
    map_state$marker_lng <- NULL
    map_state$marker_lat <- NULL
    map_state$lng <- -95
    map_state$lat <- 40
    map_state$zoom <- 2.5
    
    output$map <- renderMapboxer({
      hdallyears_joined %>% 
        select(instnm, countynm, stabbr, longitud, latitude, greencat, size) %>% 
        filter(greencat == input$selected_green_category) %>%
        as_mapbox_source(lng = "longitud", lat = "latitude") %>%
        mapboxer(
          style = "mapbox://styles/mapbox/streets-v11",
          center = c(map_state$lng, map_state$lat),
          zoom = map_state$zoom,
          token = mapbox_token
        ) %>%
        add_navigation_control() %>%
        add_circle_layer(
          circle_color = "green",
          circle_radius = list(
            "interpolate", list("linear"), list("get", "size"), 
            0, 1, 
            500, 2, 
            1000, 4, 
            5000, 8
          ),
          popup = "Institution: {{instnm}}, Graduates: {{size}}"
        ) %>%
        add_fill_layer(
          source = counties_sf,
          fill_color = list(
            "property" = "unique_postings",
            "stops" = list(
              list(0, "#fff5f0"),
              list(10000, "#fcbba1"),
              list(30000, "#fb6a4a"),
              list(50000, "#cb181d")
            )
          ),
          fill_opacity = 0.8,
          fill_outline_color = "gray"
        )
    })
  })
}

# Run the application
shinyApp(ui = ui, server = server)
