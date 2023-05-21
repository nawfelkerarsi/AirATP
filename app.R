library(shiny)
library(dplyr)
library(ggplot2)
# Chemin vers le dataset format json.
data <- jsonlite::fromJSON("dataset.json")

data$Dateheure <- as.POSIXct(
    data$dateheure,
    format = "%Y-%m-%dT%H:%M:%S",
    tz = "UTC"
  )

# Polluants dans la station souterraine.
data$NO <- as.numeric(data$nocha4) # Monoxyde d'azote.
data$NO2 <- as.numeric(data$n2cha4) # Dioxyde d'azote.
data$PM10 <- as.numeric(data$`10cha4`) # Particules fines.

# Pollutants à l'extérieur de la station.
data$EXT_PM10 <- as.numeric(data$`ext_10cha4`) # Particules fines à la surface.

# Définition de l'ui.
ui <- fluidPage(
  titlePanel("Qualité de l'air à la station de Châtelet en 2022."),
  sidebarLayout(
    sidebarPanel(
      # Réglage de l'intervalle de date.
      dateRangeInput(
        "date_range",
        label = "Intervalle de date",
        start = "2022-01-01",
        end = "2022-12-31",
        min = "2021-01-01",
        max = "2023-12-31",
        separator = "-"
      ),
      # Réglage des checkbox.
      checkboxGroupInput("pollutants",
        label = "Sélectionner un ou plusieurs polluants",
        choices = c("NO", "NO2", "PM10", "EXT_PM10"),
        selected = c("NO", "NO2", "PM10"),
      )
    ),
    # Affichage des concentrations moyennes.
    mainPanel(
      plotOutput("air_quality_plot"),
      verbatimTextOutput("avg_output_NO"),
      verbatimTextOutput("avg_output_NO2"),
      verbatimTextOutput("avg_output_PM10"),
      verbatimTextOutput("avg_output_EXT_PM10")
    ),
  )
)
# Définition du serveur.
server <- function(input, output) {
  # Configuration de l'intervalle de date.
  filtered_data <- reactive({
    data %>% filter(
      Dateheure >= as.POSIXct(input$date_range[1]),
      Dateheure <= as.POSIXct(input$date_range[2]))
  })
  # Quelques couleurs pour chaque polluant.
  color_values <- reactive({
    colors <- c(NO = "blue", NO2 = "red", PM10 = "green", EXT_PM10 = "purple")
    colors[input$pollutants]
  })
  # Rendu des courbes du graphique.
  output$air_quality_plot <- renderPlot({
    gg <- ggplot(filtered_data(), aes(x = Dateheure))
    if ("NO" %in% input$pollutants) {
      gg <- gg + geom_line(
        aes(y = NO, color = "NO"),
        linetype = "solid"
      )
    }
    if ("NO2" %in% input$pollutants) {
      gg <- gg + geom_line(
        aes(y = NO2, color = "NO2"),
        linetype = "solid"
      )
    }
    if ("PM10" %in% input$pollutants) {
      gg <- gg + geom_line(
        aes(y = PM10, color = "PM10"),
        linetype = "solid"
      )
    }
    if ("EXT_PM10" %in% input$pollutants) {
      gg <- gg + geom_line(
        aes(y = EXT_PM10, color = "EXT_PM10"),
        linetype = "solid"
      )
    }
    # Définition des légendes et des noms des axes.
    gg <- gg +
      labs(
        x = "Date", y = "Valeur du polluant en µg/m³",
        title = "Qualité de l'air",
        color = "Légende"
      ) +
      scale_color_manual(values = color_values()) +
      theme_minimal() +
      theme(
        legend.text = element_text(size = 12),
        legend.title = element_text(size = 14),
        legend.margin = margin(10, 10, 10, 10)
      )
    gg
  })

  # Configuration des concentrations moyennes.
  output$avg_output_NO <- renderText({
    if ("NO" %in% input$pollutants) {
      paste("Concentration moyenne de NO :",
      round(mean(filtered_data()$NO, na.rm = TRUE), 2), "µg/m³")
    }
  })
  output$avg_output_NO2 <- renderText({
    if ("NO2" %in% input$pollutants) {
      paste("Concentration moyenne de NO2 :",
      round(mean(filtered_data()$NO2, na.rm = TRUE), 2), "µg/m³")
    }
  })
  output$avg_output_PM10 <- renderText({
    if ("PM10" %in% input$pollutants) {
      paste("Concentration moyenne de PM10 :",
      round(mean(filtered_data()$PM10, na.rm = TRUE), 2), "µg/m³")
    }
  })
  output$avg_output_EXT_PM10 <- renderText({
    if ("EXT_PM10" %in% input$pollutants) {
      paste("Concentration moyenne de PM10 à l'extérieur :",
      round(mean(filtered_data()$EXT_PM10, na.rm = TRUE), 2), "µg/m³")
    }
  })
}

# Appelle de la fonction shinyApp().
shinyApp(ui = ui, server = server)
