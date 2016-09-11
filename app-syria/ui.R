library(shiny) 

data_processed <- read.csv(file = '/home/javi/masterdatascience/TFM/data_bigquery_processed/data_processed.csv', 
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