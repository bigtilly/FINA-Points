data <- read.csv("Simulated_Swim_Data_Final.csv")
head(data)

library(dplyr)
library(tidyr)

long_data <- data %>%
  select(X50.Free.Time, X100.Br.Time, X100.Back.Time, Percentile) %>%
  pivot_longer(cols = c(X50.Free.Time, X100.Br.Time, X100.Back.Time),
               names_to = "event",
               values_to = "time")

long_data$time <- as.numeric(long_data$time)

N_counts <- c("X50.Free.Time" = 979, "X100.Br.Time" = 496, "X100.Back.Time" = 572)
N_ref <- N_counts["X50.Free.Time"]

# --- Times ---
# Use fixed ylim = 0 to 50
hist(as.numeric(data$X50.Free.Time),
     main = "50 Free Times", xlab = "Time (s)", col = "red", breaks = 20,
     ylim = c(0, 50))

hist(as.numeric(data$X100.Br.Time),
     main = "100 Breast Times", xlab = "Time (s)", col = "blue", breaks = 20,
     ylim = c(0, 50))

hist(as.numeric(data$X100.Back.Time),
     main = "100 Back Times", xlab = "Time (s)", col = "gold", breaks = 20,
     ylim = c(0, 50))


# --- FINA ---
# Reverse x axis with xlim
hist(data$X50.Free.FINA,
     main = "50 Free FINA", xlab = "FINA Points", col = "red", breaks = 20,
     ylim = c(0, 50),
     xlim = rev(range(data$X50.Free.FINA)))

hist(data$X100.Br.FINA,
     main = "100 Breast FINA", xlab = "FINA Points", col = "blue", breaks = 20,
     ylim = c(0, 50),
     xlim = rev(range(data$X100.Br.FINA)))

hist(data$X100.Bk.FINA,
     main = "100 Back FINA", xlab = "FINA Points", col = "gold", breaks = 20,
     ylim = c(0, 50),
     xlim = rev(range(data$X100.Bk.FINA)))

#Line comparison

plot(data$Percentile, data$X50.Free.FINA,
     type = "l", col = "red", lwd = 2,
     main = "Percentile vs FINA (50 Free vs 100 Breast)",
     xlab = "Percentile", ylab = "FINA Points")
lines(data$Percentile, data$X100.Br.FINA, col = "blue", lwd = 2)
legend("topleft", legend = c("50 Free", "100 Breast"),
       col = c("red", "blue"), lwd = 2)


# Mean difference
mean_diff_50free_br <- mean(data$X100.Br.FINA - data$X50.Free.FINA)
mean_diff_br_back <- mean(data$X100.Br.FINA - data$X100.Bk.FINA)

# Subset rows between 25th and 75th percentile
mid_range <- subset(data, Percentile >= 25 & Percentile <= 100)

# Compute mean differences
mean_diff_50free_br   <- mean(mid_range$X100.Br.FINA - mid_range$X50.Free.FINA)
mean_diff_50free_back <- mean(mid_range$X50.Free.FINA - mid_range$X100.Bk.FINA)
mean_diff_br_back     <- mean(mid_range$X100.Br.FINA - mid_range$X100.Bk.FINA)

# --- Plot ---
plot(data$Percentile, data$X50.Free.FINA,
     type = "l", col = "red", lwd = 2,
     main = "Percentile vs FINA (All Strokes)",
     xlab = "Percentile", ylab = "FINA Points")

lines(data$Percentile, data$X100.Br.FINA, col = "blue", lwd = 2)
lines(data$Percentile, data$X100.Bk.FINA, col = "gold", lwd = 2)

# Highlight 25th–75th percentile region
rect(25, par("usr")[3], 75, par("usr")[4], col = rgb(0,0,0,0.1), border = NA)

# Add legend
legend("topleft", legend = c("50 Free", "100 Breast", "100 Back"),
       col = c("red", "blue", "gold"), lwd = 2)

# --- Add text with mean differences ---
text(55, par("usr")[4] - 50, 
     labels = paste("Mean diff above 25th Percentile (100Br - 50Fr):", round(mean_diff_50free_br, 1)),
     col = "black", cex = 0.9)


text(55, par("usr")[4] - 100, 
     labels = paste("Mean diff above 25th Percentile (100Br - 100Bk):", round(mean_diff_br_back, 1)),
     col = "black", cex = 0.9)

# New get_score function based on percentile by rank
get_score <- function(event, time) {
  # Add a guard clause to handle missing time values
  if (is.na(time)) {
    return(NA)
  }
  
  # --- Get all times for the event ---
  event_times <- as.numeric(data[[event]])
  event_times <- event_times[!is.na(event_times)]
  
  fastest_time <- min(event_times)
  print(fastest_time)
  if (time < fastest_time || time == fastest_time) {
    # --- Handle Record-Breaking Swim ---
    
    # 1. Calculate the score for the PREVIOUS fastest time
    # Percentile for the fastest time in the database
    slower_swims_record <- sum(event_times > fastest_time)
    total_swims <- length(event_times)
    percentile_record <- (slower_swims_record / total_swims) * 100
    
    base_score_record <- percentile_record * 10
    
    k_record <- -2 * percentile_record + 200
    
    participation_bonus_record <- 0
    N_event <- N_counts[event]
    if (!is.na(N_event) && N_event > 0 && N_ref > 0) {
      participation_ratio <- N_ref / N_event
      if (participation_ratio > 1) {
        participation_bonus_record <- k_record * log(participation_ratio)
      }
    }
    score_record <- base_score_record + participation_bonus_record
    
    # 2. Calculate and add the user-specified bonus for the new record
    record_bonus <- ((time / fastest_time) - 1) * 100
    final_score <- score_record + record_bonus
    
  } else {
    # --- Handle Standard Swim ---
    slower_swims <- sum(event_times > time)
    total_swims <- length(event_times)
    percentile <- (slower_swims / total_swims) * 100
    
    base_score <- percentile * 10
    
    k <- -2 * percentile + 200
    
    participation_bonus <- 0
    N_event <- N_counts[event]
    if (!is.na(N_event) && N_event > 0 && N_ref > 0) {
      participation_ratio <- N_ref / N_event
      if (participation_ratio > 1) {
        participation_bonus <- k * log(participation_ratio)
      }
    }
    final_score <- base_score + participation_bonus
  }
  
  return(((final_score/1000)^3) * 1000 )
}

# placements go from 1 (best) to 1000 (worst)
placements <- 1:1000
percentiles <- 100 - (placements / 1000 * 100)

# build a data frame with scores for each event
score_df <- data.frame(
  Percentile = percentiles,
  Free50 = sapply(placements, function(p) {
    time <- as.numeric(data$X50.Free.Time[p])
    get_score("X50.Free.Time", time)
  }),
  Br100 = sapply(placements, function(p) {
    time <- as.numeric(data$X100.Br.Time[p])
    get_score("X100.Br.Time", time)
  }),
  Back100 = sapply(placements, function(p) {
    time <- as.numeric(data$X100.Back.Time[p])
    get_score("X100.Back.Time", time)
  })
)

# plot the curves
plot(score_df$Percentile, score_df$Free50,
     type = "l", col = "red", lwd = 2,
     main = "Percentile vs New Score",
     xlab = "Percentile", ylab = "Score",
     ylim = range(score_df[, -1], na.rm = TRUE))

lines(score_df$Percentile, score_df$Br100, col = "blue", lwd = 2)
lines(score_df$Percentile, score_df$Back100, col = "gold", lwd = 2)

legend("topleft", legend = c("50 Free", "100 Breast", "100 Back"),
       col = c("red", "blue", "gold"), lwd = 2)

# --- Compute mean diffs in 25th–100th percentile range ---
mid_range <- subset(score_df, Percentile >= 25 & Percentile <= 100)

mean_diff_50free_br   <- mean(mid_range$Br100 - mid_range$Free50, na.rm = TRUE)
mean_diff_50free_back <- mean(mid_range$Back100 - mid_range$Free50, na.rm = TRUE)
mean_diff_br_back     <- mean(mid_range$Br100 - mid_range$Back100, na.rm = TRUE)

# --- Plot ---
plot(score_df$Percentile, score_df$Free50,
     type = "l", col = "red", lwd = 2,
     main = "Percentile vs New Score (All Strokes)",
     xlab = "Percentile", ylab = "Score",
     ylim = range(score_df[, -1], na.rm = TRUE))

lines(score_df$Percentile, score_df$Br100, col = "blue", lwd = 2)
lines(score_df$Percentile, score_df$Back100, col = "gold", lwd = 2)

# Highlight 25th–75th percentile region for context
rect(25, par("usr")[3], 75, par("usr")[4], col = rgb(0,0,0,0.1), border = NA)

# Legend
legend("topleft", legend = c("50 Free", "100 Breast", "100 Back"),
       col = c("red", "blue", "gold"), lwd = 2)

# --- Add mean difference annotations ---
text(55, par("usr")[4] - 50,
     labels = paste("Mean diff 100Br - 50Fr:", round(mean_diff_50free_br, 1)),
     col = "black", cex = 0.9)

text(55, par("usr")[4] - 100,
     labels = paste("Mean diff 100Br - 100Bk:", round(mean_diff_br_back, 1)),
     col = "black", cex = 0.9)
f <- function(x, A = 152.09, s = 392) {
  500 + A * tan((x - 500) / s)
}
get_score_from_data <- function(event, time) {
  if (is.na(time)) {
    return(NA)
  }
  
  event_times <- as.numeric(data[[event]])
  event_times <- event_times[!is.na(event_times)]
  
  fastest_time <- min(event_times)
  
  if (time < fastest_time || time == fastest_time) {
    # --- Handle Record-Breaking Swim ---
    # Get the score of the fastest time
    slower_swims <- sum(event_times > fastest_time)
    total_swims <- length(event_times)
    percentile <- 100
    base_score <- percentile * 10
    k <- -2 * percentile + 200
    participation_bonus <- 0
    N_event <- N_counts[event]
    if (!is.na(N_event) && N_event > 0 && N_ref > 0) {
      participation_ratio <- N_ref / N_event
      if (participation_ratio > 1) {
        participation_bonus <- k * log(participation_ratio)
      }
    }
    score_at_fastest_time <- base_score + participation_bonus
    
    record_bonus <- ((fastest_time / time ) - 1) * 1000
    final_score <- score_at_fastest_time + record_bonus
    
  } else {
    slower_swims <- sum(event_times > time)
    total_swims <- length(event_times)
    percentile <- (slower_swims / total_swims) * 100
    
    # The user wants to cap the percentile at 99.999...
    percentile <- pmin(99.9999999, percentile)
    
    base_score <- percentile * 10
    
    k <- -2 * percentile + 200
    
    participation_bonus <- 0
    N_event <- N_counts[event]
    if (!is.na(N_event) && N_event > 0 && N_ref > 0) {
      participation_ratio <- N_ref / N_event
      if (participation_ratio > 1) {
        participation_bonus <- k * log(participation_ratio)
      }
    }
    final_score <- base_score + participation_bonus
  }
  
  final_score <- f(pmax(0, final_score))
  
  return(final_score)
}

score_df_from_data <- data.frame(
  Free50 = sapply(data$X50.Free.Time, function(time) {
    get_score_from_data("X50.Free.Time", time)
  }),
  Br100 = sapply(data$X100.Br.Time, function(time) {
    get_score_from_data("X100.Br.Time", time)
  }),
  Back100 = sapply(data$X100.Back.Time, function(time) {
    get_score_from_data("X100.Back.Time", time)
  })
)

# Scatter plot for 50 Free
clean_data_free <- na.omit(data.frame(time = data$X50.Free.Time, score = score_df_from_data$Free50))
plot(clean_data_free$time, clean_data_free$score,
     main = "50 Free: Time vs. Score from Data",
     xlab = "Time (s)",
     ylab = "Score",
     col = "red")

# Scatter plot for 100 Breast
clean_data_br <- na.omit(data.frame(time = data$X100.Br.Time, score = score_df_from_data$Br100))
plot(clean_data_br$time, clean_data_br$score,
     main = "100 Breast: Time vs. Score from Data",
     xlab = "Time (s)",
     ylab = "Score",
     col = "blue")

# Scatter plot for 100 Back
clean_data_back <- na.omit(data.frame(time = data$X100.Back.Time, score = score_df_from_data$Back100))
plot(clean_data_back$time, clean_data_back$score,
     main = "100 Back: Time vs. Score from Data",
     xlab = "Time (s)",
     ylab = "Score",
     col = "gold")

percentiles_for_plot <- seq(0, 100, by = 1)

score_df_from_data_percentile <- data.frame(
  Percentile = percentiles_for_plot,
  Free50 = sapply(percentiles_for_plot, function(p) {
    time <- quantile(data$X50.Free.Time, probs = (100-p)/100, na.rm = TRUE)
    get_score_from_data("X50.Free.Time", time)
  }),
  Br100 = sapply(percentiles_for_plot, function(p) {
    time <- quantile(data$X100.Br.Time, probs = (100-p)/100, na.rm = TRUE)
    get_score_from_data("X100.Br.Time", time)
  }),
  Back100 = sapply(percentiles_for_plot, function(p) {
    time <- quantile(data$X100.Back.Time, probs = (100-p)/100, na.rm = TRUE)
    get_score_from_data("X100.Back.Time", time)
  })
)

# plot the curves
plot(score_df_from_data_percentile$Percentile, score_df_from_data_percentile$Free50,
     type = "l", col = "red", lwd = 2,
     main = "Percentile vs Score from Data",
     xlab = "Percentile", ylab = "Score",
     ylim = range(score_df_from_data_percentile[, -1], na.rm = TRUE))

lines(score_df_from_data_percentile$Percentile, score_df_from_data_percentile$Br100, col = "blue", lwd = 2)
lines(score_df_from_data_percentile$Percentile, score_df_from_data_percentile$Back100, col = "gold", lwd = 2)

legend("topleft", legend = c("50 Free", "100 Breast", "100 Back"),
       col = c("red", "blue", "gold"), lwd = 2)

mid_range_from_data <- subset(score_df_from_data_percentile, Percentile >= 25 & Percentile <= 100)

mean_diff_from_data_50free_br   <- mean(mid_range_from_data$Br100 - mid_range_from_data$Free50, na.rm = TRUE)
mean_diff_from_data_br_back     <- mean(mid_range_from_data$Br100 - mid_range_from_data$Back100, na.rm = TRUE)

text(55, par("usr")[4] - 50,
     labels = paste("Mean diff 100Br - 50Fr:", round(mean_diff_from_data_50free_br, 1)),
     col = "black", cex = 0.9)

text(55, par("usr")[4] - 100,
     labels = paste("Mean diff 100Br - 100Bk:", round(mean_diff_from_data_br_back, 1)),
     col = "black", cex = 0.9)

get_score_from_data("X50.Free.Time", 21.02)
get_score_from_data("X50.Free.Time", 23)
