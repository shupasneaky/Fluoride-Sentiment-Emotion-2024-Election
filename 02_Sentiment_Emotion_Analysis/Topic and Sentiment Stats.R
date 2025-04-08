# Load required libraries
library(lessR)
library(dplyr)
library(tm)
library(tidyr)
library(tidytext)
library(wordcloud)
library(stringr)
library(ggplot2)

# User Level sentiment towards Fluoride.
### 1. Sentiment
# Null Hypothesis: There is no difference in the sentiment of users about fluoride compared to topic2

# Load Data
general_posts <- read.csv("general_posts.csv", header = TRUE)[,-1] %>% mutate(Source = "General")
fluoride_posts <- read.csv("fluoride_posts.csv", header = TRUE)[,-1] %>% mutate(Source = "Fluoride")
combined_posts <- bind_rows(general_posts, fluoride_posts) 



user_that_spoke_about_fluoride <- combined_posts %>%
  mutate(Includes_Fluoride = grepl(paste0("\\bFluoride\\b"), combined_posts$Topic)) %>%
  filter(Includes_Fluoride == TRUE) %>%
  select(Author.ID) %>%
  distinct()

topics_from_users_that_posted_about_fluoride <- combined_posts %>%
  filter(Author.ID %in% user_that_spoke_about_fluoride$Author.ID) %>%
  separate_longer_delim(Topic, ",") %>%
  filter(Topic != "Fluoride") %>%
  select(Author.ID, Topic) %>%
  distinct() 

pie_table <- as.data.frame(table(topics_from_users_that_posted_about_fluoride$Topic)) %>%
  mutate(Topic = Var1) %>%
  select(Freq, Topic) %>%
  arrange(desc(Freq)) %>%
  mutate(
    Percent = Freq / sum(Freq) * 100,
    Label = paste0(Topic, " (", round(Percent, 1), "%)")
  )

pie_table$Label <- factor(pie_table$Label, levels = pie_table$Label)

pie_plot <- ggplot(pie_table, aes(x = 2, y = Freq, fill = Label)) +
  geom_bar(stat = "identity", width = 1, color = "black", size = 0.5) +
  coord_polar(theta = "y") +
  xlim(0.5, 2.5) + 
  theme_void() +
  ggtitle("Topics Discussed by Users that Posted About Fluoride") +
  guides(fill = guide_legend(ncol = 1))

pie_plot
ggsave("User That Poster About Fluoride Other Topics Pie_Chart.jpg", pie_plot, width = 8, height = 8, dpi = 300)

############################################################
############        User Level Statistics         ##########
############################################################
user_avg_sentiment <- combined_posts %>%
  mutate(Sentiment = case_when(
    Sentiment == "Positive" ~ 1, 
    Sentiment == "Neutral" ~ 0, 
    TRUE ~ -1
  )) %>%
  separate_longer_delim(Topic, ",") %>%
  group_by(Author.ID, Topic) %>%
  summarise(Avg_Sentiment = mean(Sentiment), .groups = "drop") %>%
  mutate(Sentiment = case_when(
    Avg_Sentiment < - 0.5 ~ "Negative",
    Avg_Sentiment > 0.5 ~ "Positive", 
    TRUE ~ "Neutral"
  )) %>% select(Author.ID, Topic, Sentiment)


# Get all topics in data
topic_vec <- combined_posts %>%
  separate_longer_delim(Topic, ",") %>%
  mutate(Topic = trimws(Topic)) %>%
  filter(Topic != "N/A") %>%
  select(Topic) %>%
  unique() %>%
  unlist()

compare_topics <- setdiff(topic_vec, "Fluoride")

test_results <- vector("list", length(compare_topics))
names(test_results) <- compare_topics

for (i in seq_along(compare_topics)) {
  topic <- compare_topics[i]
  
  # Filter to users with both Fluoride and the comparison topic
  filtered_users <- user_avg_sentiment %>%
    filter(Topic %in% c("Fluoride", topic))
  
  users_with_both <- filtered_users %>%
    group_by(Author.ID) %>%
    filter(n_distinct(Topic) == 2) %>%
    ungroup()
  
  if (nrow(users_with_both) == 0) {
    test_results[[i]] <- NULL
    next
  }
  
  # Define rows and columns
  topics <- c("Fluoride", topic)
  sentiments <- c("Negative", "Neutral", "Positive")
  
  # Build 2x3 matrix manually
  sentiment_table <- matrix(0, nrow = 2, ncol = 3,
                            dimnames = list(topics, sentiments))
  
  for (t in topics) {
    for (s in sentiments) {
      sentiment_table[t, s] <- sum(users_with_both$Topic == t & users_with_both$Sentiment == s)
    }
  }
  
  # Skip malformed tables
  if (any(rowSums(sentiment_table) == 0)) {
    test_results[[i]] <- NULL
    next
  }
  
  # Fisher's Exact Test (simulated p-value)
  fisher_result <- fisher.test(sentiment_table, simulate.p.value = TRUE, B = 10000)
  
  test_results[[i]] <- list(
    Topic = topic,
    Table = sentiment_table,
    P_Value = fisher_result$p.value
  )
}

# Compile results
final_results <- do.call(rbind, lapply(test_results, function(res) {
  if (is.null(res)) return(NULL)
  counts <- as.vector(res$Table)
  data.frame(
    Topic = res$Topic,
    Δ_Prop_Neg = res$Table[2, "Negative"] / sum(res$Table[2,]) - res$Table[1, "Negative"] / sum(res$Table[1,]),
    Δ_Prop_Neu = res$Table[2, "Neutral"] / sum(res$Table[2,]) - res$Table[1, "Neutral"] / sum(res$Table[1,]),
    Δ_Prop_Pos = res$Table[2, "Positive"] / sum(res$Table[2,]) - res$Table[1, "Positive"] / sum(res$Table[1,]),
    P_Value = res$P_Value
  )
}))


final_results_count_table <- do.call(rbind, lapply(test_results, function(res) {
  if (is.null(res)) return(NULL)
  counts <- as.vector(res$Table)
  data.frame(
    Topic = res$Topic,
    Other_Neg = res$Table[2, "Negative"] ,
    Other_Neu = res$Table[2, "Neutral"]   ,
    Other_Pos = res$Table[2, "Positive"]   ,
    Fluoride_Neg =  res$Table[1, "Negative"] ,
    Fluoride_Neu =  res$Table[1, "Neutral"] ,
    Fluoride_Pos =  res$Table[1, "Positive"] ,
    P_Value = res$P_Value
  )
}))


final_results <- final_results[order(final_results$P_Value), ]

write.csv(final_results, file = "Topic Comparison By User.csv")

final_results_count_table <- final_results_count_table[order(final_results_count_table$P_Value), ]

write.csv(final_results_count_table, file = "Topic Count By User.csv")



library(ggplot2)
library(cowplot)

##################################################################
#################         Plot style 1           #################
##################################################################
# Ensure Topic is a character
final_results$Topic <- as.character(final_results$Topic)

# Remove any rows with missing values
final_results <- na.omit(final_results)

# Create factor versions of Topic ordered by each Δ_Prop
final_results$Topic_Neg <- factor(final_results$Topic, levels = final_results$Topic[order(final_results$Δ_Prop_Neg)])
final_results$Topic_Neu <- factor(final_results$Topic, levels = final_results$Topic[order(final_results$Δ_Prop_Neu)])
final_results$Topic_Pos <- factor(final_results$Topic, levels = final_results$Topic[order(final_results$Δ_Prop_Pos)])

# Negative Sentiment Plot
p1 <- ggplot(final_results, aes(x = Topic_Neg, y = Δ_Prop_Neg)) +
  geom_col(fill = "tomato3") +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0.15, 0.15))) +
  labs(
    y = "Δ Proportion of Negative Sentiment",
    x = "Topic",
    title = "Negative Sentiment"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    axis.title.x = element_text(size = 14, face = "bold"),
    axis.title.y = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(size = 12, face = "bold"),
    axis.text.y = element_text(size = 12, face = "bold")
  )

# Neutral Sentiment Plot
p2 <- ggplot(final_results, aes(x = Topic_Neu, y = Δ_Prop_Neu)) +
  geom_col(fill = "gray60") +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0.15, 0.15))) +
  labs(
    y = "Δ Proportion of Neutral Sentiment",
    x = "Topic",
    title = "Neutral Sentiment"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    axis.title.x = element_text(size = 14, face = "bold"),
    axis.title.y = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(size = 12, face = "bold"),
    axis.text.y = element_text(size = 12, face = "bold")
  )

# Positive Sentiment Plot
p3 <- ggplot(final_results, aes(x = Topic_Pos, y = Δ_Prop_Pos)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0.15, 0.15))) +
  labs(
    y = "Δ Proportion of Positive Sentiment",
    x = "Topic",
    title = "Positive Sentiment"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    axis.title.x = element_text(size = 14, face = "bold"),
    axis.title.y = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(size = 12, face = "bold"),
    axis.text.y = element_text(size = 12, face = "bold")
  )



# Combine plots into one frame using cowplot
combined_plot <- plot_grid(p1, p2, p3, ncol = 3, align = "h", axis = "tb")

# Add a title to the full plot
# 
final_plot <- plot_grid(
  ggdraw() + 
    draw_label("Difference in Proportion of Sentiment of Topics Compared to Fluoride", 
               fontface = "bold", size = 20, hjust = 0.5),
  combined_plot,
  ncol = 1,
  rel_heights = c(0.1, 1)  # adjust title vs. plot height
)

# Display the full plot
print(final_plot)

# Save it
ggsave("sentiment_comparison_style1.jpg", final_plot, width = 18, height = 7, dpi = 300)


##################################################################
#################         Plot style 2           #################
##################################################################

# Define a shared topic order (based on Δ_Prop_Pos)
shared_order <- final_results$Topic[order(final_results$P_Value, decreasing = TRUE)]

# Apply the same factor level to all
final_results$Topic <- factor(final_results$Topic, levels = shared_order)

# Plot 1: Negative Sentiment
p1 <- ggplot(final_results, aes(x = Topic, y = Δ_Prop_Neg)) +
  geom_col(fill = "tomato3") +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0.15, 0.15))) +
  labs(y = "Δ Proportion of Negative", x = "Topic", title = "Negative Sentiment") +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12, face = "bold")
  )

# Plot 2: Neutral Sentiment
p2 <- ggplot(final_results, aes(x = Topic, y = Δ_Prop_Neu)) +
  geom_col(fill = "gray60") +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0.15, 0.15))) +
  labs(y = "Δ Proportion of Neutral", x = "Topic", title = "Neutral Sentiment") +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12, face = "bold")
  )

# Plot 3: Positive Sentiment
p3 <- ggplot(final_results, aes(x = Topic, y = Δ_Prop_Pos)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0.15, 0.15))) +
  labs(y = "Δ Proportion of Positive", x = "Topic", title = "Positive Sentiment") +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12, face = "bold")
  )

# Combine plots into one frame using cowplot
combined_plot <- plot_grid(p1, p2, p3, ncol = 3, align = "h", axis = "tb")

# Add a title to the full plot
# 
final_plot <- plot_grid(
  ggdraw() + 
    draw_label("Difference in Proportion of Sentiment of Topics Compared to Fluoride", 
               fontface = "bold", size = 20, hjust = 0.5),
  combined_plot,
  ncol = 1,
  rel_heights = c(0.1, 1)  # adjust title vs. plot height
)

# Display the full plot
print(final_plot)

# Save it
ggsave("sentiment_comparison_style2.jpg", final_plot, width = 18, height = 7, dpi = 300)
