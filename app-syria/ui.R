library(shiny) 

ui <- fluidPage( 
  titlePanel(wellPanel(h1(strong("Aid Syria")), style = "background-color: #ce1126; font-family: 'Courier'; color: #ffffff; 
                       border-color: #000000")),
  sidebarLayout(position = "left", 
                sidebarPanel(wellPanel(
                  dateRangeInput(inputId = "selectdate", label = "Select date", min = "2011-01-01", max = "2016-08-31", 
                                 start = "2011-01-01", end = '2016-08-31'),
                  selectInput(inputId = "selectevent", label = "Select event", 
                              choices = sort(unique(as.character(data_processed$Event))), selected = '07. Provide aid*'),
                  selectInput(inputId = "selectvariable", label = "Select graph", choices = c("Articles","Tone vs Articles")),
                  style = "background-color: #bdbdbd; font-family: 'Courier'; color: #000000; border-color: #000000"), 
                  style = "background-color: #007a3d; border-color: #000000", width = 3, img(src="logo_master_sidebar.png")),
                mainPanel(
                  conditionalPanel(condition = 'input.selectvariable == "Articles"', plotlyOutput("articles")),
                  conditionalPanel(condition = 'input.selectvariable == "Tone vs Articles"', plotlyOutput("weightedtone")),
                  htmlOutput('info'),
                  htmlOutput('article'),
                  htmlOutput('web'),
                  width = 9
                )
  )
)

ui