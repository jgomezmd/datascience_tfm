library(dplyr)
library(ggplot2)
library(RColorBrewer)
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
data_timeseries[data_timeseries$EventRootCode == '01',]$Event <- "01. Public statement"
data_timeseries[data_timeseries$EventRootCode == '02',]$Event <- "02. Appeal"
data_timeseries[data_timeseries$EventRootCode == '03',]$Event <- "03. Express intent to cooperate"
data_timeseries[data_timeseries$EventRootCode == '04',]$Event <- "04. Consult"
data_timeseries[data_timeseries$EventRootCode == '05',]$Event <- "05. Diplomatic Cooperation"
data_timeseries[data_timeseries$EventRootCode == '06',]$Event <- "06. Material Cooperation"
data_timeseries[data_timeseries$EventRootCode == '07',]$Event <- "07. Provide aid"
data_timeseries[data_timeseries$EventRootCode == '08',]$Event <- "08. Yield"
data_timeseries[data_timeseries$EventRootCode == '09',]$Event <- "09. Investigate"
data_timeseries[data_timeseries$EventRootCode == '10',]$Event <- "10. Demand"
data_timeseries[data_timeseries$EventRootCode == '11',]$Event <- "11. Disapprove"
data_timeseries[data_timeseries$EventRootCode == '12',]$Event <- "12. Reject"
data_timeseries[data_timeseries$EventRootCode == '13',]$Event <- "13. Threaten"
data_timeseries[data_timeseries$EventRootCode == '14',]$Event <- "14. Protest"
data_timeseries[data_timeseries$EventRootCode == '15',]$Event <- "15. Exhibit military posture"
data_timeseries[data_timeseries$EventRootCode == '16',]$Event <- "16. Reduce relations"
data_timeseries[data_timeseries$EventRootCode == '17',]$Event <- "17. Coerce"
data_timeseries[data_timeseries$EventRootCode == '18',]$Event <- "18. Assault"
data_timeseries[data_timeseries$EventRootCode == '19',]$Event <- "19. Fight"
data_timeseries[data_timeseries$EventRootCode == '20',]$Event <- "20. Mass violence"

data_timeseries$date <- as.Date(data_timeseries$date, "%Y%m%d")

data_timeseries <- arrange(data_timeseries, Event)

display.brewer.all(colorblindFriendly = TRUE)
pal <- brewer.pal(nlevels(as.factor(sort(data_timeseries$Event))), "Dark2")

ui <- fluidPage( 
  titlePanel(h2("Aid Syria")),
  sidebarLayout(position = "left",
                sidebarPanel(
                  dateRangeInput(inputId = "selectdate", label = "date", min = "2011-01-01", max = "2016-08-15", start = "2011-01-01", end = '2016-08-15'),
                  selectInput(inputId = "selectevent", label = "event", 
                              choices = sort(unique(as.character(data_timeseries$Event))),multiple = TRUE, selected = '07. Provide aid'),
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
    p <- plot_ly(filtered_data(), x = date, y = sumNumArticles, name = Event, color = Event, colors = "Dark2", xaxis = "x1", yaxis = "y1")
    p <- add_trace(p, x = date, y = weightedTone, name = Event, color = Event, colors = "Paired", xaxis = "x1", yaxis = "y2")
    p %>% layout(showLegend = TRUE, yaxis = list(anchor = 'x', domain = c(0.55, 1)),
                 yaxis2 = list(anchor = 'x', domain = c(0, 0.45), title = 'weightedTone'))
  }) 
  output$weightedtone <- renderPlotly({ 
    #g <- ggplot(filtered_data(), aes(date, weightedTone, colour = Event, label = maxArticle)) + geom_line()
    #ggplotly(g)
    p <- plot_ly(filtered_data(), x = date, y = weightedTone, name = Event, color = Event, colors = pal)
    p %>% layout(showLegend = TRUE)    
  }) 
  output$iarticles <- renderPlotly({ 
    p <- plot_ly(filtered_data(), x = date, y = importanceArticle, name = Event, color = Event, colors = pal)
    p %>% layout(showLegend = TRUE)   
  }) 
  output$itone <- renderPlotly({ 
    p <- plot_ly(filtered_data(), x = date, y = importanceTone, name = Event, color = Event, colors = pal)
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
