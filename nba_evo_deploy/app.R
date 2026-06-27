#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(shinythemes)
library(ggplot2)
library(plotly)
library(leaflet)
library(dplyr)
library(readr)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)

# --- Custom ggplot Theme for Dark background to match "Superhero" shiny theme
theme_dark_custom <- function(base_size = 13) {
  theme_minimal(base_size = 13) + 
    theme(
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA),
    legend.background = element_rect(fill = "transparent", color = NA),
    legend.key = element_rect(fill = "transparent", color = NA),
    panel.grid.major = element_line(color = "gray30"),
    panel.grid.minor = element_blank(),
    text = element_text(color = "white"),
    axis.text = element_text(color = "white"),
    axis.title = element_text(color = "white"),
    legend.text = element_text(color = "white"),
    legend.title = element_text(color = "white"),
    plot.title = element_text(color = "white")
    )
}

# --- UI ---

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
    /* Slider font + tick label fixes */
    .plotly .slider-container .slider-label,
    .plotly .slider-container .slider-value,
    .plotly .slider-container .slider-current-value,
    .plotly .slider-container .slider .tick text,
    .plotly .slider-container .slider .handle text,
    .plotly .slider-container .slider text,
    .plotly .updatemenu-button text {
      fill: white !important;
      color: white !important;
    }
    
    /* Make active tab selected NBA orange */
    .nav-tabs > li.active > a,
    .nav-tabs > li.active > a:focus,
    .nav-tabs > li.active > a:hover {
      background-color: #f77f6e;
      color = white;
      border: none;
    }
    
    .plotly .updatement-button{
    boder-color: white !important;
    }
    
    .plotly .updatemenu-button:hover {
    background-color: #444 !important;
    }
  "  
    ))
  ),
  theme = shinytheme("superhero"), 
  div(
    style = "font-family: 'Georgia', serif; font-size: 34px; font-weight: bold; color: #f77f6e; margin-bottom: 20px;",
    "The Evolution of NBA Basketball"),
  
  fluidRow(
    column(3,
           div(id = "stickyFilters",
               # ---Shot Evolution Sidebar---
               conditionalPanel(
                 condition = "input.tabs === 'Shot Evolution'",
                 wellPanel(
                   style = "min-height: 1600px;", # Unique to tab height
                   sliderInput("seasonRange", "Select Season Range:",
                               min = 2004, max = 2022, value = c(2012,  2022), sep = "", step = 1),
                   
                   tags$div(
                     style = "margin-top: 90px",
                     tags$div(
                       style = "background-color: #f77f6e22; padding: 10px; border-radius: 10px; font-family: Tahoma, sans-serif; font-size: 13px; font-weight: bold; color: white;",
                       "In 2022, guards took shots from an average distance of over 13 feet - nearly double that of Centres." # Sidebar key facts to utilise unused space
                     )
                   ),
                   tags$div(
                     style = "margin-top: 470px",
                     tags$div(
                       style = "background-color: #f77f6e22; padding: 10px; border-radius: 10px; font-family: Tahoma, sans-serif; font-size: 13px; font-weight: bold; color: white;",
                       "By 2023, 3-point shots made up 39% of all field goal attempts - up from just 22% in 2004." # Sidebar key facts to utilise unused space
                     )
                   ),
                   tags$div(
                     style = "margin-top: 460px",
                     tags$div(
                       style = "background-color: #f77f6e22; padding: 10px; border-radius: 10px; font-family: Tahoma, sans-serif; font-size: 13px; font-weight: bold; color: white;",
                       "International players posted a league-high TS% of 57.4% in 2023." # Sidebar key facts to utilise unused space
                     )
                   )
                 )
               ),
               
               # ---Player Archetypes Sidebar--- 
               conditionalPanel(
                 condition = "input.tabs === 'Player Archetypes'",
                 wellPanel(
                   style = "min-height: 1930px;", # Unique to tab height
                   sliderInput("seasonRange", "Select Season Range:",
                               min = 2004, max = 2022, value = c(2012,  2022), sep = "", step = 1),
                   
                   radioButtons("measureType", "Select Physical Trait for Box Plots:",
                                choices = c("Height" = "player_height", "Weight" = "player_weight"),
                                selected = "player_height"),
                   
                   tags$div(
                     style = "margin-top: 90px",
                     tags$div(
                       style = "background-color: #f77f6e22; padding: 10px; border-radius: 10px; font-family: Tahoma, sans-serif; font-size: 13px; font-weight: bold; color: white;",
                       "Guards consistently use over 20% of team possessions - the highest among all positions." # Sidebar key facts to utilise unused space
                     )
                   ),
                   tags$div(
                     style = "margin-top: 470px",
                     tags$div(
                       style = "background-color: #f77f6e22; padding: 10px; border-radius: 10px; font-family: Tahoma, sans-serif; font-size: 13px; font-weight: bold; color: white;",
                       "The average hiegh of Centres declined by 2cm between 2004 and 2022." # Sidebar key facts to utilise unused space
                     )
                   ),
                   tags$div(
                     style = "margin-top: 50px",
                     tags$div(
                       style = "background-color: #f77f6e22; padding: 10px; border-radius: 10px; font-family: Tahoma, sans-serif; font-size: 13px; font-weight: bold; color: white;",
                       "The average player weight has dropped by 4kg since 2004, reflecting a shift toward leaner, more mobile athletes." # Sidebar key facts to utilise unused space
                     )
                   ),
                   tags$div(
                     style = "margin-top: 600px",
                     tags$div(
                       style = "background-color: #f77f6e22; padding: 10px; border-radius: 10px; font-family: Tahoma, sans-serif; font-size: 13px; font-weight: bold; color: white;",
                       "The average NBA player age dropped from 28.1 in 2000 to 26.1 in 2021." # Sidebar key facts to utilise unused space
                     )
                   )
                 )
               ),
               
               # ---Globalisation of NBA Sidebar---
               conditionalPanel(
                 condition = "input.tabs === 'Globalisation of NBA'",
                 wellPanel(
                   style = "min-height: 1590px;", # Unique to tab height
                   selectInput("mapSeason", "Map Season:", 
                               choices = c("All", 1997:2023), selected = "All"),
                   
                   tags$div(
                     style = "margin-top: 130px",
                     tags$div(
                       style = "background-color: #f77f6e22; padding: 10px; border-radius: 10px; font-family: Tahoma, sans-serif; font-size: 13px; font-weight: bold; color: white;",
                       "Canada has produced over 200 players - more than any other country outside the U.S." # Sidebar key facts to utilise unused space
                     )
                   ),
                   tags$div(
                     style = "margin-top: 470px",
                     tags$div(
                       style = "background-color: #f77f6e22; padding: 10px; border-radius: 10px; font-family: Tahoma, sans-serif; font-size: 13px; font-weight: bold; color: white;",
                       "The number of international NBA players has tripled since 1997" # Sidebar key facts to utilise unused space
                     )
                   ),
                   tags$div(
                     style = "margin-top: 460px",
                     tags$div(
                       style = "background-color: #f77f6e22; padding: 10px; border-radius: 10px; font-family: Tahoma, sans-serif; font-size: 13px; font-weight: bold; color: white;",
                       "Over 55% of NBA players have careers lasting fewer than 5 seasons." # Sidebar key facts to utilise unused space
                     )
                   )
                 )
               )
           )
  ),
  
  column(9,
         tabsetPanel(id = "tabs",
                     tabPanel("Shot Evolution",
                              
                              h3("Average Shot Distance by Height"),
                               fluidRow(
                                 column(8, plotlyOutput("shotDistanceScatter")),
                                 column(4, tags$div(
                                   style = "background-color: rgba(255,255,255,0.05); padding: 10px; border-radius: 10px; color: white; font-family: Tahoma, sans-serif; font-size: 13px;",
                                   tags$strong("Key Insight:"), # Make bold
                                   p("Over the past two decades, there has been a clear evolution in player shot tendencies and physical profiles. Average shot distance has steadily increased across all positions, particularly among guards and forwards, highlighting the league's shift toward perimeter-oriented play. There's a noticeable decline in averagge player height, reflecting the rise of more agile, skill-based roles over traditional size dominated play. This trend demonstrates how modern NBA strategies favour spacing, shooting, and speed over sheer physicality.")))
                                ),
                               p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", "Press Play or use the season slider to observe how shot distance and average height evolve across player positions over time."),
                               p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", tags$strong("Note: This chart updates based on the selected Season Range above.")),
                              
                              h3("Shot Type Composition (2PT vs 3PT)"),
                              fluidRow(
                                column(8, plotlyOutput("shotTypeArea")),
                                column(4, tags$div(
                                  style = "background-color: rgba(255,255,255,0.05); padding: 10px; border-radius: 10px; color: white; font-family: Tahoma, sans-serif; font-size: 13px;",
                                  tags$strong("Key Insight:"), # Make bold
                                  p("Since the mid-2010s, there's been a significant rise in 3PT field goalds, now making up nearly half of all shots taken. While 2PT attempts still lead overall volume, the growth of the three-point shot reflects the league's anayltical shift prioritising efficiency and floor spacing.")))
                              ),
                              p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", "Displays the total number of 2PT and 3PT field goals attempted each season from 2004 to 2022."),
                              p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", tags$strong("Note: This chart displays all seasons and is not affected by the slider above.")),
                              
                              h3("True Shooting % Over Time"),
                              fluidRow(
                                column(8, plotlyOutput("tsPctLine"),
                                       p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", "Shows the average True Shooting Percentage (TS%) per seaons by player origin. TS% accounts for field goals, three-point shots, and free throws to measure overall scoring efficiency."),
                                       p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", tags$strong("Note: This chart displays all seasons and is not affected by the slider above.")),),
                                column(4, tags$div(
                                  style = "background-color: rgba(255,255,255,0.05); padding: 10px; border-radius: 10px; color: white; font-family: Tahoma, sans-serif; font-size: 13px;",
                                  tags$strong("Key Insight:"), # Make bold
                                  p("True Shooting Percentage (TS%) has shown a consistent upward trajectory since the early 2000s, reflecting a league-wide improvement in scoring efficiency. Notable, international players have often recorded highter TS% compared to their U.S. counterparts, suggesting superior shot selection, perimeter accuracy and offensive role specialisation. However, it is important to acknowledge that international playeres comprise a smaller subset of the dataset, which may introduce volatility and potential skew in year-to-year comparisons. Despite this, the convergence of the 'All' group with international trends in recent seasons highlights the growing impact of global talent on NBA scoring efficiency and playstyle evolution.")))
                              )
                              
                              
                     ),
                                 
                      tabPanel("Player Archetypes",
                               
                               h3("Usage % Over Time by Position"),
                               fluidRow(
                                 column(8, plotlyOutput("usgHeatMap"),
                                        p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", "Displays average Usage Percentage (USG%) by player position across seasons. Usage % reflects the share of team possessions a player uses while on the floor"),
                                        p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", tags$strong("Note: This chart updates based on the selected Season Range above.")),),
                                 column(4, tags$div(
                                   style = "background-color: rgba(255,255,255,0.05); padding: 10px; border-radius: 10px; color: white; font-family: Tahoma, sans-serif; font-size: 13px;",
                                   tags$strong("Key Insight:"), # Make bold
                                   p("Over time, guards have consistently maintained the highest usage rates, reflecting their central role in ball handling and offensive creation. In contrast, usage among Centres and forwards has been lower and more stable, with Centres experiencing the lowest share of possessions. These trends highlight the evolving structure of offensive schemes, where perimeter players (particularly guards), are increasingly responsible for initiating and finishing plays.")))
                               ),
                               
                               h3("Physical Profile by Position"),
                               fluidRow(
                                 column(8, plotlyOutput("physProfileBoxplots", height = "700px"),
                                        p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", "Displays the distribution of player height or weight by position group across seasons using box plots."),
                                        p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", tags$strong("Note: Use the toggle feature to change between Height and Weight. This chart updates based on the selected Season Range above.")),),
                                 column(4, tags$div(
                                   style = "background-color: rgba(255,255,255,0.05); padding: 10px; border-radius: 10px; color: white; font-family: Tahoma, sans-serif; font-size: 13px;",
                                   tags$strong("Key Insight:"), # Make bold
                                   p("Across all seasons, Centres consistently exhibit the greatest height and weight, followed by forwards and then guards. While median values have remained realtively stable, there is a subtle compression in height and weight distribution over time (especially among guards), reflecting the NBA's shift toward more versatile and agile player builds. This trend underscores evolving athletic demands across positions in the modern game.")))
                               ),
                               
                               h3("Average Age Across Seasons"),
                               fluidRow(
                                 column(8, plotlyOutput("avgAgeLine"),
                                        p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", "Shows the average age of NBA players across seasons, calculated using all players who logged game time each year."),
                                        p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", tags$strong("Note: This chart displays all seasons and is not affected by the slider above.")),),
                                 column(4, tags$div(
                                   style = "background-color: rgba(255,255,255,0.05); padding: 10px; border-radius: 10px; color: white; font-family: Tahoma, sans-serif; font-size: 13px;",
                                   tags$strong("Key Insight:"), # Make bold
                                   p("The average age of NBA players has gradually declined since the early 2000s, indicating a noticeable shift toward younger rosters. This trend suggests reduced veteran presence across the league, potentially driven by earlier player entry via one-and-done college rules, greater reliance on player development, and a faster-paced game that favours youth and athleticism. The decrease in age reflects evolving team-building strategies that prioritise upside and long-term potential over experience and tenure.")))
                               ),
                               
                      ),
                     
                       tabPanel("Globalisation of NBA",
                               
                                h3("Player Origin Map"),
                                fluidRow(
                                  column(8, leafletOutput("originMap"),
                                         p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", "Displays the number of NBA players by country of origin. Countries are shaded according to total player count."),
                                         p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", tags$strong("Note: This chart updates based on the chosen Map Filter option above.")),),
                                  column(4, tableOutput("topCountriesSummary"))
                                ),
                                
                                h3("International Representation Over Time"),
                                fluidRow(
                                  column(8, plotlyOutput("intlLine"),
                                         p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", "Displays the number of international and U.S. players in the NBA by seaso, based on player birthplace data."),
                                         p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", tags$strong("Note: This chart displays all seasons and is not affected by the map filter above.")),),
                                  column(4, tags$div(
                                    style = "background-color: rgba(255,255,255,0.05); padding: 10px; border-radius: 10px; color: white; font-family: Tahoma, sans-serif; font-size: 13px;",
                                    tags$strong("Key Insight:"), # Make bold
                                    p("International representation in the NAB has steadily increased since the 1990s, with international player counts rising year-over-year while U.S. representation remains relatively stable. This growth highlights the NBA's expanding global reach and the increasing contribution of international talent to the league's overall player pool. The trend reflects the success of global scouting, development leagues, and international scout systems in producing NBA-ready talent.")))
                                ),
                                
                                h3("Career Length by Country"),
                                fluidRow(
                                  column(8, plotlyOutput("careerLength"),
                                         p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", "Displays the proportion of NBA players in each career length band (0-4, 5-9, 10+ years) by country group."),
                                         p(style = "color:white, font-size: 11px, font-family: 'Tahoma', sans-serif;", tags$strong("Note: This chart displays all seasons and is not affected by the slider above. Hover over the chart to see additional stats!")),),
                                  column(4, tags$div(
                                    style = "background-color: rgba(255,255,255,0.05); padding: 10px; border-radius: 10px; color: white; font-family: Tahoma, sans-serif; font-size: 13px;",
                                    tags$strong("Key Insight:"), # Make bold
                                    p("Across both country groups, the majority of players fall within the 0-4 year career band, though the overall distribution is similar between international and U.S. players. This suggests that while international players may face intiial adaptation challenges, their career longevity aligns closely with U.S. counterparts once they enter the league. The data highlights the competitive nature of NBA roster retention regardless of origin.")))
                                ),
                         )
           )
    )
  )
)
      

# --- SERVER ---

server <- function(input, output) {
  
  output$shotDistanceScatter <- renderPlotly({
    df <- read_csv("Processed/player_archetypes_scatter.csv") %>%
      rename(Season = season_1) %>%
      filter(Season >= input$seasonRange[1], Season <= input$seasonRange[2]) %>%
      mutate(
        Season = as.character(Season),
        position_label = recode(position_group, 
                                "C" = "Centre", 
                                "F" = "Forward",
                                "G" = "Guard")
      )
    if (nrow(df) == 0) {
      return(plot_ly() %>%
             layout(title = list(text = "No data", font = list(color = "white"))))
    }
    
    plot_ly(
      data = df,
      x = ~avg_height, 
      y = ~avg_shot_dist,
      color = ~position_label,
      frame = ~Season,
      type = 'scatter',
      mode = 'markers',
      marker = list(size = 10, opacity = 1),
      colors = c("Centre" = "#FF6F31", "Forward" = "#4AB1F1", "Guard" = "#7BDCB5")
    ) %>%
      layout(
        xaxis = list(title = "Avg Height (cm)", titlefont = list(color = "white"), tickfont = list(color = "white")),
        yaxis = list(title = "Avg Shot Distance (feet)", titlefont = list(color = "white"), tickfont = list(color = "white")),
        legend = list(font = list(color = "white")),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  output$shotTypeArea <- renderPlotly({
    df <- read_csv("Processed/shot_type_composition.csv") %>%
      arrange(season_1, shot_type)
    
    plot <- ggplot(df, aes(
      x = season_1, 
      y = shot_count, 
      fill = shot_type, 
      group = shot_type # ensure proper stacking
    )) +
      geom_area(position = "stack", alpha = 0.9) + # changed from fill to stack
      scale_y_continuous(labels = scales::comma) + 
      scale_fill_manual(
        values = c(
          "2PT Field Goal" = "#f77f6e", 
          "3PT Field Goal" = "#6096ba"
        ),
        name = "Shot Type"
      ) + 
      labs(
        x = "Season",
        y = "Total Shots"
      ) + 
      theme_dark_custom(base_size = 13) + 
      theme(
        legend.text = element_text(color = "white"),
        legend.title = element_text(color = "white"),
        axis.text = element_text(color = "white"),
        axis.title = element_text(color = "white")
      )
    
    ggplotly(plot) %>% config(displayModeBar = FALSE)
  })
  
  
  output$tsPctLine <- renderPlotly({
    df <- read_csv("Processed/ts_percentages.csv") %>%
      filter(season_start >= 2004, season_start <= 2022)
    
    plot <- ggplot(df, aes(x = season_start, y = ts_pct, color = country_group)) + 
      geom_line(size = 1.2) + 
      scale_color_manual(values = c("All" = "#81b29a",
                                     "USA" = "#e76f51",
                                     "International" = "#6096ba")) +
      labs(x = "Season", y = "TS%") + 
      theme_dark_custom()
    ggplotly(plot) %>% config(displayModeBar = FALSE)
  })
  
  output$usgHeatMap <- renderPlotly({
    df <- read_csv("Processed/usage_percentages.csv") %>%
      filter(season_start >= input$seasonRange[1], 
             season_start <= input$seasonRange[2],
             !is.na(position_group)
             ) %>%
      mutate(
        position_label = recode(position_group, 
                                "C" = "Centre", 
                                "F" = "Forward",
                                "G" = "Guard",
                                "All" = "All")
      )
    
    df$position_label <- factor(df$position_label, levels = c("Centre", "Forward", "Guard", "All")) # reorganise position group
    
    plot <- ggplot(df, aes(
      x = season_start, 
      y = position_label, 
      fill = usg_pct, 
      text = paste0(
        "Position: ", position_label, "\n",
        "Season: ", season_start, "\n",
        "Usage %: ", round(usg_pct * 100, 1), "%"
      )
    )) +
      geom_tile(color = NA) + 
      scale_fill_gradientn(
        colors = c("#2c7bb6", "#abd9e9", "#ffffbf", "#fdae61", "#d7191c"),
        name = "Usage %",
        labels = scales::percent_format(accuracy = 1)
      ) + 
      labs(
        x = "Season", 
        y = "Position Group"
      ) +
      theme_dark_custom(base_size = 13) +
      theme(
        legend.text = element_text(color = "white"),
        legend.title = element_text(color = "white"),
        axis.text = element_text(color = "white"),
        axis.title = element_text(color = "white")
      )
    ggplotly(plot, tooltip = "text") %>%
      config(displayModeBar = FALSE)
    
  })
  
  output$physProfileBoxplots <- renderPlotly({
    req(input$seasonRange, length(input$seasonRange) == 2)
    
    # Select correct summary CSV based on input
    summary_file <- if(input$measureType == "player_height") {
      'Processed/height_summary_stats.csv'
    } else {
      'Processed/weight_summary_stats.csv'
    }
    
    # Load summary data
    df <- read_csv(summary_file) %>%
      filter(season_1 >= input$seasonRange[1],
             season_1 <= input$seasonRange[2]) %>%
      mutate(position_group = recode(position_group, 
                                     "C" = "Centre",
                                     "F" = "Forward",
                                     "G" = "Guard"))
    
    # Handle empty dataset
    if (nrow(df) == 0) {
      plot <- ggplot(data.frame(x = 1, y = 1), aes(x,y)) + 
        geom_blank() + 
        labs(title = "No data available for selected season range.") +
        theme_dark_custom()
      return(ggplotly(plot))
    }
    
    # Label y-axis
    y_label <- if(input$measureType == "player_height") "Player Height (cm)" else "Player Weight (kg)"
    
    # Create manual boxplots
    plot <- ggplot(df) +
      # whiskers
      geom_linerange(
        aes(x = factor(season_1), ymin = Min, ymax = Max),
        color = "white", linewidth = 0.6
      ) +
      # Box with median line
      geom_crossbar(
        aes(
          x = factor(season_1), 
          y = Median,
          ymin = Q1, 
          ymax = Q3, 
          fill = as.numeric(season_1),
          text = paste0(
            "Season: ", season_1, "<br>",
            "Position: ", position_group, "<br>",
            "Min: ", round(Min, 1), "<br>",
            "Q1: ", round(Q1, 1), "<br>",
            "Median: ", round(Median, 1), "<br>",
            "Q3: ", round(Q3, 1), "<br>",
            "Max: ", round(Max, 1)
          )
        ),
        width = 0.4, 
        fatten = 0.8,
        color = "white"
      ) +
      scale_fill_gradientn(
        colors = c("#6096ba", "#B0B0B0", "#e76f51"), # blue to gray to orange
        name = "Season"
      ) +
      facet_wrap(~position_group, ncol = 1) + 
      labs(
        x = "Season", 
        y = y_label
      ) +
      theme_dark_custom(base_size = 13) +
      theme(
        legend.position = "none",
        strip.text = element_text(size = 14, color = "white"),
        axis.text.x = element_text(angle = 45, hjust = 1),
        axis.title.x = element_text(margin = margin(t = 10), color = "white"),
        panel.spacing = unit(1.5, "lines")
      )
    
    ggplotly(plot, tooltip = "text") %>% config(displayModeBar = FALSE)
  })
  
  output$avgAgeLine <- renderPlotly({
    df <- read_csv("Processed/avg_age_per_season.csv")
    
    plot <- ggplot(df, aes(x = season_start, y = avg_age)) +
      geom_line(color = "#e76f51", size = 1.2) + 
      labs(x = "Season", y = "Average Age") + 
      theme_dark_custom()
    
    ggplotly(plot) %>% config(displayModeBar = FALSE)
  })
  
  output$originMap <- renderLeaflet({
    df <- read_csv("Processed/player_origins_map.csv")
    df_filtered <- if (input$mapSeason != "All") {
      df %>% filter(season_start == input$mapSeason)
    } else {
      df %>% filter(view == "Overall")
    }
    df_filtered <- df_filtered %>% select(country, player_count)
    world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
    world_data <- left_join(world, df_filtered, by = c("name" = "country"))
    pal <- colorNumeric("YlOrRd", domain = c(0, 250), na.color = "transparent")
    leaflet(world_data) %>%
      addProviderTiles("CartoDB.Positron") %>%
      addPolygons(
        fillColor = ~pal(pmin(player_count, 250)),
        weight = 1,
        color = "white", 
        fillOpacity = 0.8,
        label = ~paste0(name, ": ", player_count, " players"),
        highlightOptions = highlightOptions(
          weight = 2, 
          color = "#666", 
          fillOpacity = 0.9, 
          bringToFront = TRUE
        )
      ) %>%
      addLegend(pal = pal, values = ~pmin(player_count, 250), title = "NBA Players", position = "bottomright")
  })
  
  output$topCountriesSummary <- renderTable({
    df <- read_csv("Processed/player_origins_map.csv")
    df_filtered <- if (input$mapSeason != "All") {
      df %>% filter(season_start == input$mapSeason)
    } else {
      df %>% filter(view == "Overall")
    }
    df_filtered %>%
      group_by(country) %>%
      summarise(player_count = sum(player_count, na.rm = TRUE)) %>%
      arrange(desc(player_count)) %>%
      slice_head(n = 10) %>%
      rename(
        "Country" = country,
        "Player Count" = player_count
      )
  })
  
  output$intlLine <- renderPlotly({
    df <- read_csv("Processed/intl_representation.csv") %>%
      mutate(country_group = factor(country_group, levels = c("USA", "International")))
    
    plot <- ggplot(df, aes(x = season_start, y = player_count, color = country_group)) + 
      geom_line(size = 1.2) +
      scale_color_manual(values = c("USA" = "#e76f51", "International" = "#6096ba")) +
      labs(x = "Season", y = "Player Count", color = NULL) + 
      theme_dark_custom()
    
    ggplotly(plot) %>% config(displayModeBar = FALSE)
  })
  
  
  output$careerLength <- renderPlotly({
    df <- read_csv("Processed/career_length_country_draft.csv")
    
    # Ensure correct ordering for legend
    df$career_band <- factor(df$career_band, levels = c("10+ years", "5-9 years", "0-4 years"))
    
    # Create plot
    plot <- ggplot(df, aes(
      x = country_group, 
      y = country_pct, 
      fill = career_band, 
      text = paste0(
        career_band, "\n",
        "Share: ", round(country_pct * 100, 1), "\n", 
        "Total Players: ", total_in_band, "\n",
        "Drafted: ", drafted, "\n",
        "Undrafted: ", undrafted
      )
    )) +
      geom_bar(stat = "identity", position = "stack", color = NA) +
      scale_fill_manual(
        values = c(
          "0-4 years" = "#e76f51",
          "5-9 years" = "#6096ba",
          "10+ years" = "#81b29a"
        ),
        name = "Career Length"
      ) +
      scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
      labs(
        x = "Country Group", 
        y = "Proportion"
      ) + 
      theme_dark_custom(base_size = 13) + 
      theme(
        axis.text = element_text(color = "white"),
        axis.title = element_text(color = "white"),
        legend.text = element_text(color = "white"),
        legend.title = element_text(color = "white")
      )
    
    ggplotly(plot, tooltip = "text") %>%
      config(displayModeBar = FALSE)
  })

}

# --- RUN APP ---
shinyApp(ui = ui, server = server)

