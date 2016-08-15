library(shiny) 

shinyUI(fluidPage( 
  titlePanel(h2("Aid Syria")),
  sidebarLayout(position = "left",
                sidebarPanel(
                  dateInput(inputId = "selectdate", label = "date", min = "2016-01-01", max = "2016-07-24", value = "2016-06-18"),
                  selectInput(inputId = "selectevent", 
                              label = "event", 
                              choices = list("Aid" = 1, 
                                             "Fight" = 2,
                                             "All" = 3),
                              selected = 3),
                  img(src="logo_master_sidebar.png")
                ),
                mainPanel(
                  leafletOutput(outputId = "map")
                )
  )
))