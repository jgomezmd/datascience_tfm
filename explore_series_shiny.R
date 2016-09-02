library(dplyr)
library(ggplot2)
library(plotly)
library(shiny)
library(httr)
library(XML)
library(RCurl)

bigquery_basequery <- read.csv(file = 'Descargas/data_1', header = TRUE, sep = ",", dec = ".", 
                               na.strings = "", colClasses = "character")

length(na.exclude(bigquery_basequery$Actor1Geo_Lat))

bigquery_basequery$AvgTone <- as.numeric(bigquery_basequery$AvgTone)
bigquery_basequery$NumArticles <- as.numeric(bigquery_basequery$NumArticles)

data_timeseries <- bigquery_basequery %>%
  arrange(SQLDATE, Actor1CountryCode, EventCode, NumArticles) %>%
  mutate(importanceTone = NumArticles * AvgTone) %>%
  #filter(Actor1CountryCode == 'ESP') %>%
  #filter(EventRootCode %in% c('07', '20', '19', '18')) %>%
  #group_by(Actor1CountryCode, SQLDATE, EventRootCode, EventCode) %>%
  group_by(SQLDATE, EventRootCode) %>%
  summarise(sumNumArticles = sum(NumArticles), sumimportanceTone = sum(importanceTone), maxArticle = last(SOURCEURL),
            importanceTone = last(AvgTone), importanceArticle = last(NumArticles), countRecords = n()) %>%
  rename(date = SQLDATE) %>%
  mutate(weightedTone = sumimportanceTone / sumNumArticles)

data_timeseries$Event <- NA
data_timeseries[data_timeseries$EventRootCode == '02',]$Event <- "1. Appeal for aid"
data_timeseries[data_timeseries$EventRootCode == '03',]$Event <- "2. Express intent to cooperate"
data_timeseries[data_timeseries$EventRootCode == '07',]$Event <- "3. Provide aid"
data_timeseries[data_timeseries$EventRootCode == '10',]$Event <- "4. Demand aid"
data_timeseries[data_timeseries$EventRootCode == '18',]$Event <- "5. Assault"
data_timeseries[data_timeseries$EventRootCode == '19',]$Event <- "6. Fight"
data_timeseries[data_timeseries$EventRootCode == '20',]$Event <- "7. Mass violence"

data_timeseries$date <- as.Date(data_timeseries$date, "%Y%m%d")

ui <- fluidPage( 
  titlePanel(h2("Aid Syria")),
  sidebarLayout(position = "left",
                sidebarPanel(
                  dateRangeInput(inputId = "selectdate", label = "date", min = "2011-01-01", max = "2016-08-15", start = "2011-01-01", end = '2016-08-15'),
                  selectInput(inputId = "selectevent", label = "event", 
                              choices = sort(unique(as.character(data_timeseries$Event))),multiple = TRUE, selected = '3. Provide aid'),
                  selectInput(inputId = "selectvariable", label = "variable", choices = c("sumNumArticles","weightedTone", "importanceArticle","importanceTone"))
                ),
                mainPanel(
                  conditionalPanel(condition = 'input.selectvariable == "sumNumArticles"', plotlyOutput("articles")),
                  conditionalPanel(condition = 'input.selectvariable == "weightedTone"', plotlyOutput("weightedtone")),
                  conditionalPanel(condition = 'input.selectvariable == "importanceArticle"', plotlyOutput("iarticles")),
                  conditionalPanel(condition = 'input.selectvariable == "importanceTone"', plotlyOutput("itone")),
                  htmlOutput('web')
                  )
  )
) 

server <- function(input, output) { 
  filtered_data <- reactive({
    data_timeseries %>%
      filter(Event %in% input$selectevent) %>%
      filter(date >= input$selectdate[1] && date <= input$selectdate[2])
  })
  output$articles <- renderPlotly({ 
    p <- plot_ly(filtered_data(), x = date, y = sumNumArticles, name = Event, color = Event)
    p %>% layout(showLegend = TRUE)
  }) 
  output$weightedtone <- renderPlotly({ 
    #g <- ggplot(filtered_data(), aes(date, weightedTone, colour = Event, label = maxArticle)) + geom_line()
    #ggplotly(g)
    p <- plot_ly(filtered_data(), x = date, y = weightedTone, name = Event, color = Event)
    p %>% layout(showLegend = TRUE)    
  }) 
  output$iarticles <- renderPlotly({ 
    p <- plot_ly(filtered_data(), x = date, y = importanceArticle, name = Event, color = Event)
    p %>% layout(showLegend = TRUE)   
  }) 
  output$itone <- renderPlotly({ 
    p <- plot_ly(filtered_data(), x = date, y = importanceTone, name = Event, color = Event)
    p %>% layout(showLegend = TRUE)   
  }) 
  output$web <- renderUI({
    event_reactive <- reactive({event_data("plotly_click")})
    s <- event_reactive()
    if (length(s[["x"]]) == 1) {
      df <- filtered_data()
      article <- df[df$date == s[["x"]] & df$sumNumArticles == s[["y"]],]$maxArticle
      #article <- getURL(df[df$date == s[["x"]] & df[, input$selectvariable] == s[["y"]],]$maxArticle)
      #HTML(readLines(article))}
      #doc_html <- htmlTreeParse(article, asText = TRUE)
      doc_html <- htmlParse(article, isURL = TRUE, useInternalNodes = TRUE)
      doc_text <- unlist(xpathApply(doc_html, '//p', xmlValue))
      doc_header <- unlist(xpathApply(doc_html, '//h1', xmlValue))
      list(h3(doc_header),h5(doc_text[1]),a(article))}
    else if (length(s[["x"]]) > 1) {h4("Select one point")}
    else {h4("Click in the graph to select the most important article")}
  })
}
shinyApp(ui = ui, server = server)
