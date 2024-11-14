#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/

library(shiny)
library(mapboxer)
library(dplyr)
library(shinythemes)


# # Create a source

library(haven)

hdallyears <- read_dta("hdallyears.dta")

hdallyears <- hdallyears %>%
  filter(year == 2020)

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

    hdallyears %>%
      as_mapbox_source(lng = "longitud", lat = "latitude") %>%
      # Setup a map with the default source above
      mapboxer(
        center = c(-95, 40),
        zoom = 2.5
      ) %>%
      # Add a navigation control
      add_navigation_control() %>%
      # Add a layer styling the data of the default source
      add_circle_layer(
        circle_color = "white",
        circle_radius = 3,
        # Use a mustache template to add popups to the layer
        popup = "Institution: {{instnm}}"
      )
    
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
