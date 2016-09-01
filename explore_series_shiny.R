library(dplyr)
library(ggplot2)
library(plotly)
library(shiny)
library(httr)
library(XML)

bigquery_basequery <- read.csv(file = 'Descargas/data_1', header = TRUE, sep = ",", dec = ".", na.strings = "", colClasses = "character")

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
                  textOutput('web')
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
    g <- ggplot(filtered_data(), aes(date, weightedTone, colour = Event, label = maxArticle)) + geom_line()
    ggplotly(g)
  }) 
  output$iarticles <- renderPlotly({ 
    g <- ggplot(filtered_data(), aes(date, importanceArticle, colour = Event, label = maxArticle)) + geom_line()
    ggplotly(g)
  }) 
  output$itone <- renderPlotly({ 
    g <- ggplot(filtered_data(), aes(date, importanceTone, colour = Event, label = maxArticle)) + geom_line()
    ggplotly(g, tooltip = "label")
  }) 
  output$web <- renderText({
    s <- event_data("plotly_click")
    df <- filtered_data()
    article <- df[df$date == s[["x"]] & df$sumNumArticles == s[["y"]],]$maxArticle
    doc_html <- htmlParse(article, useInternalNodes = TRUE)
    doc_text <- unlist(xpathApply(doc_html, '//p', xmlValue))
    doc_header <- unlist(xpathApply(doc_html, '//h1', xmlValue))
    doc_header
  })
} 
shinyApp(ui = ui, server = server)
