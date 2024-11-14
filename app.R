#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(mapboxer)
library(dplyr)
library(shinythemes)

# # Create a source
# motor_vehicle_collisions_nyc %>%
#   dplyr::mutate(color = ifelse(injured > 0, "red", "yellow")) %>%
#   as_mapbox_source(lng = "lng", lat = "lat") %>%
#   # Setup a map with the default source above
#   mapboxer(
#     center = c(-73.9165, 40.7114),
#     zoom = 10
#   ) %>%
#   # Add a navigation control
#   add_navigation_control() %>%
#   # Add a layer styling the data of the default source
#   add_circle_layer(
#     circle_color = c("get", "color"),
#     circle_radius = 3,
#     # Use a mustache template to add popups to the layer
#     popup = "Number of persons injured: {{injured}}"
#   )

# Define UI for application that draws a histogram
ui <- fluidPage(theme = shinytheme("flatly"),

    # Application title
    titlePanel("CRC Mapping Sandbox"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            selectInput("bins",
                        "Select variable:",
                        choices = c("a", "b"))
        ),

        # Show a plot of the generated distribution
        mainPanel(
          mapboxerOutput("map")
        )
    )
)

backend <- function(input, output) {

}

# if (interactive()) shinyApp(view, backend)

# Define server logic required to draw a histogram
server <- function(input, output) {

  output$map <- renderMapboxer({
    mapboxer(center = c(9.5, 51.3), zoom = 10) %>%
      add_navigation_control() %>%
      add_marker(lng = 9.5, lat = 51.3, popup = "mapboxer")
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
