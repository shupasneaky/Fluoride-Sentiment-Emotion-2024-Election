library(dplyr)
library(tidyr)
library(igraph)
library(stringr)
library(RColorBrewer)

# Load data (outside function — smart for reuse)
general_posts <- read.csv("general_posts.csv", header = TRUE)[, -1] %>% mutate(Source = "General")
fluoride_posts <- read.csv("fluoride_posts.csv", header = TRUE)[, -1] %>% mutate(Source = "Fluoride")
combined_posts <- bind_rows(general_posts, fluoride_posts)

# === Function ===
build_user_topic_network <- function(sentiment_group = "Negative", topic_vector = NULL, topic_name = NULL, weight_threshold = 0.1) {
  
  fluoride_users <- combined_posts %>%
    filter(Source == "Fluoride", Sentiment == sentiment_group) %>%
    distinct(Author.ID)
  
  n_users <- nrow(fluoride_users)
  
  if (n_users == 0) {
    message("No users found for sentiment group: ", sentiment_group)
    return(NULL)
  }
  
  message("Total users with ", sentiment_group, " fluoride sentiment: ", n_users)
  
  user_topics <- combined_posts %>%
    filter(Author.ID %in% fluoride_users$Author.ID) %>%
    select(Author.ID, Topic) %>%
    separate_rows(Topic, sep = ",\\s*") %>%
    distinct()
  
  if (!is.null(topic_vector)) {
    user_topics <- user_topics %>%
      filter(Topic %in% topic_vector)
  }
  
  if (nrow(user_topics) == 0) {
    message("No topics found for selected sentiment and topic group.")
    return(NULL)
  }
  
  # Step 1: Count total users per topic
  topic_totals <- user_topics %>%
    group_by(Topic) %>%
    summarise(total_users = n_distinct(Author.ID), .groups = "drop")
  
  # Step 2: Build co-occurrence counts
  topic_pairs <- user_topics %>%
    group_by(Author.ID) %>%
    summarise(Topics = list(unique(Topic)), .groups = "drop") %>%
    filter(lengths(Topics) >= 2) %>%
    mutate(Pairs = lapply(Topics, function(x) expand.grid(from = x, to = x, stringsAsFactors = FALSE) %>% filter(from != to))) %>%
    select(Pairs) %>%
    unnest(Pairs)
  
  if (nrow(topic_pairs) == 0) {
    message("No co-occurring topic pairs found after filtering.")
    return(NULL)
  }
  
  # Step 3: Count number of users per topic pair (directed)
  pair_counts <- topic_pairs %>%
    count(from, to, name = "user_count")
  
  # Step 4: Calculate directional weight: users mentioning both topics / total users mentioning 'from' topic
  pair_counts <- pair_counts %>%
    left_join(topic_totals, by = c("from" = "Topic")) %>%
    mutate(proportion = user_count / total_users) %>%
    filter(proportion >= weight_threshold)
  
  if (nrow(pair_counts) == 0) {
    message("No topic pairs above threshold for selected sentiment and topics.")
    return(NULL)
  }
  
  # Step 5: Build directed graph
  g <- graph_from_data_frame(pair_counts, directed = TRUE)
  
  layout <- layout_in_circle(g)
  
  # Custom palette: white → grey → red
  palette_func <- colorRampPalette(c("white", "grey80", "red"))
  gamma <- 1  # higher gamma = more fade
  edge_proportions <- E(g)$proportion
  base_colors <- palette_func(100)[ceiling((edge_proportions ^ gamma) * 99) + 1]
  
  # Opacity range: min 0.2, max 1
  edge_opacity <- 0.2 + (edge_proportions ^ gamma) * 0.8
  
  # Convert to hex (00–FF)
  opacity_hex <- sprintf("%02X", as.integer(edge_opacity * 255))
  edge_colors <- paste0(base_colors, opacity_hex)
  
  # Dynamic filename
  filename <- paste0("user_topic_network_", tolower(sentiment_group))
  if (!is.null(topic_name)) {
    filename <- paste0(filename, "_", tolower(topic_name))
  }
  filename <- paste0(filename, ".png")
  
  png(filename = filename, width = 1800, height = 1300, res = 150)
  
  plot(
    g,
    layout = layout,  # Scaling works now!
    rescale = FALSE, 
    edge.width = edge_proportions * 3,
    edge.color = edge_colors,
    edge.curved = 0.2,
    edge.arrow.size = 0.8,  # ✅ Add arrows to show directionality
    vertex.color = "white",
    vertex.frame.color = "black",
    vertex.label.color = "black",
    vertex.size = 15,
    vertex.label.cex = 0.6
  )
  
  title(
    main = paste("User-Level Topic Directional Network\n(", sentiment_group, " Fluoride Sentiment)", sep = ""),
    sub = "Edge color represents proportion of users from source topic",
    cex.main = 0.8,
    cex.sub = 0.6
  )
  
  # Manual legend
  legend_gradient <- palette_func(20)
  x_left <- 1.3
  y_bottom <- -0.5
  y_top <- 0.5
  x_right <- 1.4
  legend_steps <- length(legend_gradient)
  
  rect(
    xleft = rep(x_left, legend_steps),
    ybottom = seq(y_bottom, y_top - (y_top - y_bottom) / legend_steps, length.out = legend_steps),
    xright = rep(x_right, legend_steps),
    ytop = seq(y_bottom, y_top, length.out = legend_steps),
    col = legend_gradient,
    border = NA
  )
  
  text(x = x_right - 0.1, y = y_bottom - 0.15, labels = "No\nCorrelation (0)", adj = 0, cex = 0.7)
  text(x = x_right - 0.1, y = y_top + 0.15, labels = "Full\nCorrelation (1)", adj = 0, cex = 0.7)
  
  dev.off()
  
  message("✅ Network saved: ", filename)
}




health = c("Fluoride", "Health", "Dental", "Vaccines", "Cancer", "Thyroid", "Autism", "Endocrine", "Neurological Effects", "Mass medication", "Pineal", "IQ")
society = c("Political", "Societal Issues", "Economic", "Education", "Sports", "IQ", "Conspiracy")
sciences = c("Science", "Technology", "Arts", "Other Topics")


noflo = c("Science", "Technology", "Arts", "Other Topics", "Health", "Dental", "Vaccines", "Cancer", "Thyroid", "Autism", "Endocrine","Political", "Societal Issues", "Economic", "Education", "Sports", "IQ", "Conspiracy", "Neurological Effects", "Mass medication", "Pineal", "IQ")
build_user_topic_network(sentiment_group = "Positive", topic_vector = noflo, topic_name = "1noflo", weight_threshold = 0)
build_user_topic_network(sentiment_group = "Negative", topic_vector = noflo, topic_name = "1noflo", weight_threshold = 0)
build_user_topic_network(sentiment_group = "Neutral", topic_vector = noflo, topic_name = "1noflo", weight_threshold = 0)

list.files()
