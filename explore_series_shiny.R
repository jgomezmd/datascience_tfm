library(dplyr)
library(ggplot2)
library(RColorBrewer)
library(plotly)
library(shiny)
library(httr)
library(XML)
#library(RCurl)

data_processed <- read.csv(file = 'masterdatascience/TFM/data_bigquery_processed/data_processed.csv', 
                               header = TRUE, sep = ",", dec = ".", na.strings = "", colClasses = "character")

data_processed$sumNumArticles <- as.numeric(data_processed$sumNumArticles)
data_processed$importanceArticle <- as.numeric(data_processed$importanceArticle)
data_processed$importanceTone <- as.numeric(data_processed$importanceTone)
data_processed$sumImportanceTone <- as.numeric(data_processed$sumImportanceTone)

data_processed$Event <- NA
data_processed[data_processed$EventRootCode == '01',]$Event <- "01. Public statement"
data_processed[data_processed$EventRootCode == '02',]$Event <- "02. Appeal*"
data_processed[data_processed$EventRootCode == '03',]$Event <- "03. Express intent to cooperate*"
data_processed[data_processed$EventRootCode == '04',]$Event <- "04. Consult"
data_processed[data_processed$EventRootCode == '05',]$Event <- "05. Diplomatic Cooperation"
data_processed[data_processed$EventRootCode == '06',]$Event <- "06. Material Cooperation"
data_processed[data_processed$EventRootCode == '07',]$Event <- "07. Provide aid*"
data_processed[data_processed$EventRootCode == '08',]$Event <- "08. Yield*"
data_processed[data_processed$EventRootCode == '09',]$Event <- "09. Investigate"
data_processed[data_processed$EventRootCode == '10',]$Event <- "10. Demand*"
data_processed[data_processed$EventRootCode == '11',]$Event <- "11. Disapprove"
data_processed[data_processed$EventRootCode == '12',]$Event <- "12. Reject"
data_processed[data_processed$EventRootCode == '13',]$Event <- "13. Threaten"
data_processed[data_processed$EventRootCode == '14',]$Event <- "14. Protest"
data_processed[data_processed$EventRootCode == '15',]$Event <- "15. Exhibit military posture"
data_processed[data_processed$EventRootCode == '16',]$Event <- "16. Reduce relations"
data_processed[data_processed$EventRootCode == '17',]$Event <- "17. Coerce"
data_processed[data_processed$EventRootCode == '18',]$Event <- "18. Assault"
data_processed[data_processed$EventRootCode == '19',]$Event <- "19. Fight"
data_processed[data_processed$EventRootCode == '20',]$Event <- "20. Mass violence"

data_processed$Humanitarian <- "No humanitarian"
data_processed[data_processed$EventCode == '0233' | #appeal humanitarian aid
                 data_processed$EventCode == '0234' | #appeal protection and peacekeeping
                 data_processed$EventCode == '0243' | #appeal for rights
                 data_processed$EventCode == '0256' | #appeal de-escalation of military engagement
                 data_processed$EventCode == '0333' | #express intent humanitarian aid
                 data_processed$EventCode == '0334' | #express intent protection and peacekeeping
                 data_processed$EventCode == '0343' | #express intent for rights
                 data_processed$EventCode == '0356' | #express intent de-escalation of military engagement
                 data_processed$EventCode == '073' | #provide humanitarian aid
                 data_processed$EventCode == '074' | #provide protection and peacekeeping
                 data_processed$EventCode == '0833' | #accede demands rigths
                 data_processed$EventCode == '0861' | #recive peacekeepers
                 data_processed$EventCode == '0863' | #allow humanitarian access
                 data_processed$EventCode == '087' | #de-escalate military engagement
                 data_processed$EventCode == '0871' | #declare ceasefire
                 data_processed$EventCode == '0872' | #ease military blockade
                 data_processed$EventCode == '0873' | #demobilize armed forces
                 data_processed$EventCode == '0874' | #retreat military
                 data_processed$EventCode == '1033' | #demand humanitarian aid
                 data_processed$EventCode == '1034' | #demand protection and peacekeeping
                 data_processed$EventCode == '1043' | #demand rights
                 data_processed$EventCode == '1056'  #demand de-escalation of military engagement
                 ,]$Humanitarian <- "Humanitarian"

data_event <- data_processed %>%
  arrange(date, Event, sumNumArticles) %>%
  group_by(date, Event) %>%
  summarise(sumNumArticles = sum(sumNumArticles), sumImportanceTone = sum(sumImportanceTone), maxArticle = last(maxArticle),
            importanceTone = last(importanceTone), importanceArticle = last(sumNumArticles)) %>%
  mutate(weightedTone = sumImportanceTone / sumNumArticles)

data_humanitarian <- data_processed %>%
  arrange(date, Event, Humanitarian, sumNumArticles) %>%
  group_by(date, Event, Humanitarian) %>%
  summarise(sumNumArticles = sum(sumNumArticles), sumImportanceTone = sum(sumImportanceTone), maxArticle = last(maxArticle),
            importanceTone = last(importanceTone), importanceArticle = last(sumNumArticles)) %>%
  mutate(weightedTone = sumImportanceTone / sumNumArticles)

data_event$date <- as.Date(data_event$date, "%Y%m%d")
data_event <- data_event[with(data_event, order(Event)),]

data_humanitarian$date <- as.Date(data_humanitarian$date, "%Y%m%d")

pal <- brewer.pal(8, "Dark2") #colorblindFriendly Palette

ui <- fluidPage( 
  titlePanel(h2("Aid Syria")),
  sidebarLayout(position = "left",
                sidebarPanel(
                  dateRangeInput(inputId = "selectdate", label = "Select date", min = "2011-01-01", max = "2016-08-31", 
                                 start = "2011-01-01", end = '2016-08-31'),
                  selectInput(inputId = "selectevent", label = "Select event", 
                              choices = sort(unique(as.character(data_processed$Event))), selected = '07. Provide aid*'),
                  selectInput(inputId = "selectvariable", label = "Select graph", choices = c("Articles","Tone vs Articles")),
                width = 3),
                mainPanel(
                  conditionalPanel(condition = 'input.selectvariable == "Articles"', plotlyOutput("articles")),
                  conditionalPanel(condition = 'input.selectvariable == "Tone vs Articles"', plotlyOutput("weightedtone")),
                  #conditionalPanel(condition = 'input.selectvariable == "importanceArticle"', plotlyOutput("iarticles")),
                  #conditionalPanel(condition = 'input.selectvariable == "importanceTone"', plotlyOutput("itone")),
                  htmlOutput('info'),
                  htmlOutput('article'),
                  htmlOutput('web'),
                  width = 9
                  )
  )
)

server <- function(input, output) { 
  selected_event <- reactive({
    data_event %>%
      filter(Event == input$selectevent) %>%
      filter(date >= input$selectdate[1] && date <= input$selectdate[2])
  })
  nonselected_event <- reactive({
    data_event %>%
      filter(Event != input$selectevent) %>%
      filter(date >= input$selectdate[1] && date <= input$selectdate[2]) %>%
      arrange(date, sumNumArticles) %>%
      group_by(date) %>%
      summarise(sumNumArticles = sum(sumNumArticles), sumImportanceTone = sum(sumImportanceTone), maxArticle = last(maxArticle),
                importanceTone = last(importanceTone), importanceArticle = last(sumNumArticles)) %>%
      mutate(weightedTone = sumImportanceTone / sumNumArticles)
  })
  humanitarian_event <- reactive({
    data_humanitarian %>%
      filter(Event == input$selectevent) %>%
      filter(Humanitarian == "Humanitarian") %>%
      filter(date >= input$selectdate[1] && date <= input$selectdate[2])
  })
  output$articles <- renderPlotly({ 
    p <- plot_ly(selected_event(), x = date, y = sumNumArticles, name = paste(input$selectevent, " Total"), 
                 marker = list(color = pal[2]), xaxis = "x1", yaxis = "y2", opacity = 0.8)
    p <- add_trace(nonselected_event(), x = date, y = sumNumArticles, name = '00. Other events Total', 
                   marker = list(color = pal[1]), xaxis = "x1", yaxis = "y2", opacity = 0.8)
    p <- add_trace(selected_event(), x = date, y = sumNumArticles, name = paste(input$selectevent, " Total"), 
                   marker = list(color = pal[2]), xaxis = "x1", yaxis = "y1", opacity = 0.8)
    if (nrow(humanitarian_event()) > 0) {
      p <- add_trace(humanitarian_event(), x = date, y = sumNumArticles, name = paste(input$selectevent, "Humanitarian"), 
                     marker = list(color = pal[3]), xaxis = "x1", yaxis = "y1", opacity = 0.8)
    }
    p %>% layout(title = 'Articles', overlaying = "y", yaxis = list(anchor = 'x', domain = c(0, 0.45), 
                                                                    title = 'Number of articles'),
                 yaxis2 = list(anchor = 'x', domain = c(0.55, 1), title = 'Number of articles'))
    #
    #p %>% layout(showLegend = TRUE, yaxis = list(anchor = 'x', domain = c(0.55, 1)),
    #             yaxis2 = list(anchor = 'x', domain = c(0, 0.45), title = 'weightedTone'))
  }) 
  output$weightedtone <- renderPlotly({ 
    #g <- ggplot(filtered_data(), aes(date, weightedTone, colour = Event, label = maxArticle)) + geom_line()
    #ggplotly(g)
    p <- plot_ly(selected_event(), x = date, y = weightedTone, name = paste(input$selectevent, " Tone"), 
                 marker = list(color = pal[4]), xaxis = "x1", yaxis = "y2", opacity = 0.8)
    p <- add_trace(selected_event(), x = date, y = sumNumArticles, name = paste(input$selectevent," Total"), 
                   marker = list(color = pal[2]), xaxis = "x1", yaxis = "y1", opacity = 0.8)
    #p <- add_trace(nonselected_event(), x = date, y = weightedTone, name = 'Other articles', colors = pal[2], xaxis = "x1", yaxis = "y2", opacity = 0.8)
    if (nrow(humanitarian_event()) > 0) {
      p <- add_trace(humanitarian_event(), x = date, y = sumNumArticles, name = paste(input$selectevent,' Humanitarian'), 
                     marker = list(color = pal[3]), xaxis = "x1", yaxis = "y1", opacity = 0.8)
    }
    p %>% layout(title = 'Tone vs Articles', overlaying = "y", yaxis = list(anchor = 'x', domain = c(0, 0.45), 
                                                                            title = 'Number of articles'),
                 yaxis2 = list(anchor = 'x', domain = c(0.55, 1), title = 'Weighted tone'))
  }) 
#   output$iarticles <- renderPlotly({ 
#     p <- plot_ly(selected_event(), x = date, y = importanceArticle, name = Event, color = Event, colors = pal[1], xaxis = "x1", yaxis = "y2")
#     p <- add_trace(nonselected_event(), x = date, y = importanceArticle, name = 'Others events', colors = pal[2], xaxis = "x1", yaxis = "y2")
#     p <- add_trace(humanitarian_event(), x = date, y = importanceArticle, name = Humanitarian, color = Humanitarian, colors = c(pal[3],pal[4]), xaxis = "x1", yaxis = "y1")
#     p %>% layout(title = 'Important Article', overlaying = "y", yaxis = list(anchor = 'x', domain = c(0, 0.45), title = 'Humanitarian'),
#                  yaxis2 = list(anchor = 'x', domain = c(0.55, 1), title = 'Events'))
#   }) 
#   output$itone <- renderPlotly({ 
#     p <- plot_ly(selected_event(), x = date, y = importanceTone, name = Event, color = Event, colors = pal[1], xaxis = "x1", yaxis = "y2")
#     p <- add_trace(nonselected_event(), x = date, y = importanceTone, name = 'Others events', colors = pal[2], xaxis = "x1", yaxis = "y2")
#     p <- add_trace(selected_event(), x = date, y = importanceTone, color = Event, colors = pal[1], xaxis = "x1", yaxis = "y1")
#     p <- add_trace(humanitarian_event(), x = date, y = importanceTone, name = Humanitarian, color = Humanitarian, colors = c(pal[3],pal[4]), xaxis = "x1", yaxis = "y1")
#     p %>% layout(title = 'Important Tone', overlaying = "y", yaxis = list(anchor = 'x', domain = c(0, 0.45), title = 'Humanitarian'),
#                  yaxis2 = list(anchor = 'x', domain = c(0.55, 1), title = 'Events'))
#   }) 
  output$article <- renderUI({
    event_reactive <- reactive({event_data("plotly_click")})
    s <- event_reactive()
    if (length(s[["x"]]) == 1) {
      if (input$selectvariable == "Articles"){
        if (s[["curveNumber"]] %in% c(0,2)){df <- selected_event()}
        else if (s[["curveNumber"]] ==1){df <- nonselected_event()}
        else if (s[["curveNumber"]] ==3){df <- humanitarian_event()}
      }
      else {
        if (s[["curveNumber"]] %in% c(0,1)){df <- selected_event()}
        else if (s[["curveNumber"]] == 2){df <- humanitarian_event()}
      }
      article <- df[df$date == s[["x"]],]$maxArticle
      #article <- df[df$date == s[["x"]] & df$sumNumArticles == s[["y"]],]$maxArticle
      #article <- getURL(df[df$date == s[["x"]] & df[, input$selectvariable] == s[["y"]],]$maxArticle)
      #HTML(readLines(article))}
      #doc_html <- htmlTreeParse(article, asText = TRUE)
      doc_html <- htmlParse(GET(article), isURL = TRUE, useInternalNodes = TRUE)
      #doc_text <- unlist(xpathApply(doc_html, '//body//p/*[1]', xmlValue))
      doc_header <- unlist(xpathApply(doc_html, '//body//h1', xmlValue))
      list(h3(doc_header[1]))}
    else if (length(s[["x"]]) > 1) {h4("Select one point")}
    else {h4("Click in the graph to select the most important article")}
  })
  output$web <- renderUI({
    event_reactive <- reactive({event_data("plotly_click")})
    s <- event_reactive()
    if (length(s[["x"]]) == 1) {
      if (input$selectvariable == "Articles"){
        if (s[["curveNumber"]] %in% c(0,2)){df <- selected_event()}
        else if (s[["curveNumber"]] ==1){df <- nonselected_event()}
        else if (s[["curveNumber"]] ==3){df <- humanitarian_event()}
      }
      else {
        if (s[["curveNumber"]] %in% c(0,2)){df <- selected_event()}
        else if (s[["curveNumber"]] == 1){df <- humanitarian_event()}
      }
      article <- df[df$date == s[["x"]],]$maxArticle
      list("link to the article: ", a(article))}
  })
  output$info <- renderUI({
    list(h6("The events with * contains humanitarian articles"), 
         h6("The 'on click' articles are available for dates greaters than 31-march-2013"))
  })
}
shinyApp(ui = ui, server = server)
