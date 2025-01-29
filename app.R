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

hdallyears <- read_rds("hdallyears.rds") # supply side data
ipeds_green_summed <- read_rds("ipeds_green_summed.rds") # supply-side data
counties_sf <- read_rds("counties_sf_processed.rds") # county shapes and demand data(county population)

## data preparation
hdallyears_joined <- hdallyears %>% 
  left_join(ipeds_green_summed, by = "unitid")

## app
ui <- fluidPage(
  theme = shinytheme("flatly"),
  titlePanel("CCRC Mapping"),
  
  # Category selectors
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
  
  # Search and control panel (centered below selectors)
  fluidRow(
    column(
      width = 12, align = "center",
      div(
        style = "display: flex; justify-content: center; align-items: center;",
        textInput("search_term", "Search by Institution:", placeholder = "Type here...", width = "50%"),
        actionButton("search_btn", "Search", style = "margin-left: 10px;"),
        actionButton("clear_btn", "Clear", style = "margin-left: 10px;")
      )
    )
  ),
  
  # Map output
  fluidRow(
    column(12, mapboxerOutput("map", height = "700px"))
  ),
  # Footer for credits
  fluidRow(
    column(
      width = 12, align = "center",
      tags$footer(
        style = "margin-top: 20px; padding: 10px; font-size: 12px; background-color: #f8f9fa; border-top: 1px solid #e9ecef;",
        HTML("Created by Wei Wang, Joshua Rosenberg, and Cameron Sublet at the University of Tennessee, Knoxville with the Community College Research Center at Teachers College, Columbia. 
              Source code at: <a href='link_to_github' target='_blank'>GitHub</a>. 
              Thanks to funding from JC Morgan Chase.")
      )
    )
  )
  
  
  
)

server <- function(input, output, session) {
  
  # Reactive values for map state and marker
  map_state <- reactiveValues(
    lng = -95,
    lat = 40,
    zoom = 2.5,
    marker = NULL
  )
  
  # Function to render the map
  render_map <- function(lng, lat, zoom, marker = NULL) {
    map <- hdallyears_joined %>% 
      select(instnm, countynm, stabbr, longitud, latitude, greencat, size) %>% 
      filter(greencat == input$selected_green_category) %>%
      as_mapbox_source(lng = "longitud", lat = "latitude") %>%
      mapboxer(
        style = "mapbox://styles/mapbox/streets-v11",
        center = c(lng, lat),
        zoom = 3.5,
        token = mapbox_token
      ) %>%
      add_navigation_control() %>%
      add_circle_layer(
        circle_color = "green",
        circle_radius = list(
          "interpolate", list("linear"), list("get", "size"), 
          0, 0.5, 
          500, 1, 
          1000, 2, 
          5000, 4
        ),
        popup = "Institution: {{instnm}}, No: {{size}}"
      ) %>%
      add_fill_layer(
        source = counties_sf,
        fill_color = list(
          "property" = "population",
          "stops" = list(
            list(0, "#fff5f0"),
            list(10000, "#fcbba1"),
            list(30000, "#fb6a4a"),
            list(50000, "#cb181d")
          )
        ),
        fill_opacity = 0.8,
        fill_outline_color = "gray",
        popup = "County: {{county_name}}<br>Demand: {{population}}" # Hover popup showing population
      )
    
    if (!is.null(marker)) {
      map <- map %>%
        add_marker(lng = marker$lng, lat = marker$lat, popup = marker$popup)
    }
    
    return(map)
  }
  
  # Initial render
  output$map <- renderMapboxer(
    render_map(map_state$lng, map_state$lat, map_state$zoom)
  )
  
  # Search functionality
  observeEvent(input$search_btn, {
    # Preprocess the search term: remove spaces, special characters, and convert to lowercase
    search_term <- gsub("[^a-z0-9]", "", tolower(trimws(input$search_term)))
    
    if (search_term != "") {
      # Preprocess the institution names in the dataset similarly
      hdallyears_joined_processed <- hdallyears_joined %>%
        mutate(processed_instnm = gsub("[^a-z0-9]", "", tolower(instnm)))
      
      # Perform the search using the processed search term
      coords <- hdallyears_joined_processed %>%
        filter(grepl(search_term, processed_instnm), greencat == input$selected_green_category) %>%
        select(instnm, longitud, latitude, size) %>%
        slice(1)
      
      if (nrow(coords) == 0 || is.na(coords$longitud) || is.na(coords$latitude)) {
        showNotification("No matching results or invalid coordinates for the selected category.", type = "error")
        return()
      }
      
      # Update map state and marker
      map_state$lng <- as.numeric(coords$longitud)
      map_state$lat <- as.numeric(coords$latitude)
      map_state$zoom <- 8
      map_state$marker <- list(
        lng = map_state$lng,
        lat = map_state$lat,
        popup = paste(
          "Institution:", coords$instnm, 
          "<br>No (", input$selected_green_category, "):", coords$size
        )
      )
      
      # Update the map
      output$map <- renderMapboxer(
        render_map(map_state$lng, map_state$lat, map_state$zoom, map_state$marker)
      )
    } else {
      showNotification("Search term is empty.", type = "error")
    }
  })
  
  
  
  # Clear functionality
  observeEvent(input$clear_btn, {
    map_state$lng <- -95
    map_state$lat <- 40
    map_state$zoom <- 2.5
    map_state$marker <- NULL
    
    output$map <- renderMapboxer(
      render_map(map_state$lng, map_state$lat, map_state$zoom)
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)
