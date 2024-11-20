library(shiny)
library(mapboxer)
library(shinythemes)
library(haven)
library(urbnmapr)
library(tidycensus)
library(sf)


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
      select(instnm, longitud, latitude, greencat, size) %>% 
      filter(greencat == input$selected_green_category) %>%
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
        # circle_radius = 1,
        circle_radius = list(
          "step", c("get", "size"),
          .5, 10,
          1, 100,
          1.5, 1000,
          2, 10000,
          2.5
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