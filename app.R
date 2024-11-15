library(shiny)
library(mapboxer)
library(dplyr)
library(shinythemes)
library(haven)

# docs: https://cran.r-project.org/web/packages/mapboxer/vignettes/mapboxer.html

hdallyears <- read_dta("hdallyears.dta")

ui <- fluidPage(theme = shinytheme("flatly"),
                
                # Application title
                titlePanel("CRC Mapping Sandbox"),
                
                # Sidebar with a slider input for number of bins 
                sidebarLayout(
                  sidebarPanel(
                    selectInput("selected_size",
                                "Select institutional size:",
                                choices = c("Under 1,000" = 1,
                                            "1,000 - 4,999" = 2,
                                            "5,000 - 9,999" = 3,
                                            "10,000 - 19,999" = 4,
                                            "20,000 and above" = 5)),
                    selectInput("selected_year",
                                "Select year:",
                                choices = c(2010, 2015, 2020))
                  ),
                
                # Show a plot of the generated distribution
                mainPanel(
                  mapboxerOutput("map")
                )
)
)

server <- function(input, output) {
  
  output$map <- renderMapboxer({
    
    print(input$selected_size)
    
    hdallyears %>%
      filter(year == input$selected_year) %>%
      filter(instsize == as.integer(input$selected_size)) %>%
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
        popup = "Institution: {{instnm}}"
      )
    
  })
}

# Run the application 
shinyApp(ui = ui, server = server)