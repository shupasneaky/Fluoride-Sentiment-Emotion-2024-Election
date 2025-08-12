# Sentiment counts for posts from each pull
pull1_posts <- c(Negative = 4217, Neutral = 2172, Positive = 608)
pull2_posts <- c(Negative = 3690, Neutral = 2432, Positive = 1241)
post_matrix <- rbind(Pull1 = pull1_posts, Pull2 = pull2_posts)

# Test 1: Chi-square test of independence
test1_result <- chisq.test(post_matrix)
cat("Test 1: Post sentiment distribution across Pull 1 and Pull 2\n")
print(test1_result)

# Post sentiment counts in Pull 2 by user group from Pull 1
pull2_posts_by_user <- data.frame(
  Negative = c(2412, 1049, 229),
  Neutral  = c(1370,  884, 178),
  Positive = c( 695,  407, 139),
  row.names = c("NegUser", "NeuUser", "PosUser")
)

# Conditional post sentiment distributions (D_neg, D_neu, D_pos)
post_distributions <- sweep(pull2_posts_by_user, 1, rowSums(pull2_posts_by_user), FUN = "/")

# Pull 1 and Pull 2 user sentiment proportions
pull1_users <- c(Negative = 3721, Neutral = 2002, Positive = 530)
pull2_users <- c(Negative = 1281, Neutral = 722, Positive = 168)

cat("Test 2: Equality of user sentiment distribution across pulls\n")
chisq.test(rbind(Pull1 = pull1_users, Pull2 = pull2_users))

weights <- (pull1_users / sum(pull1_users)) / (pull2_users / sum(pull2_users))

# Adjust post sentiment distributions for user prevalence distortion
adjusted_distributions <- sweep(post_distributions, 1, weights, FUN = "*")

# Convert to pseudo-counts and test for equality across adjusted distributions
simulated_counts <- round(adjusted_distributions * 10000)
test3_result <- chisq.test(simulated_counts)

cat("Test 3: Equality of adjusted post sentiment distributions (weighted)\n")
print(test3_result)



