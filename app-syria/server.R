library(shiny) 
library(leaflet)

raw <- read.csv(file = "data.csv/part-r-00000-ea35dfb0-5f31-4e62-9de4-98052da3dc0d.csv", header = TRUE)
#raw$EventRootCode <- as.factor(raw$EventRootCode)
#raw$NumArticles <- as.numeric(raw$NumArticles)
raw$SQLDATE <- as.character(raw$SQLDATE)
raw$SQLDATE <- as.Date(raw$SQLDATE, "%Y%m%d")

#str(raw)

clean <- raw[complete.cases(raw),]
clean$WeigthedTone <- clean$sum.ImportanceTone./clean$sum.NumArticles.

shinyServer(function(input, output) { 
  output$map <- renderLeaflet({ 
    if (input$selectevent == 1) {
      data <- subset(clean, SQLDATE == input$selectdate & QuadClass == 2)
    }
    else if (input$selectevent == 2) {
      data <- subset(clean, SQLDATE == input$selectdate & QuadClass == 4)
    }
    else {
      data <- subset(clean, SQLDATE == input$selectdate)
    }
    #data <- subset(clean, SQLDATE == input$selectdate & QuadClass == 2)
    leaf <- leaflet(data = data) %>% addTiles() %>% addCircleMarkers( lng = ~Actor1Geo_Long, 
                                                                      lat = ~Actor1Geo_Lat,
                                                                      radius = ~abs(WeigthedTone),
                                                                      color = ~ifelse(QuadClass == 2, 'blue','red'),
                                                                      stroke = FALSE, 
                                                                      fillOpacity = 0.2,
                                                                      popup = ~as.character(Actor1CountryCode))
    
    
  }) 
}) 