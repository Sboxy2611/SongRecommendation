# plumber.R
library(plumber)
library(dplyr)
library(proxy)
library(lubridate)

# 1. DATA PREPARATION (Runs once when the server starts)
df <- read.csv("spotify_songs.csv", stringsAsFactors = FALSE)

# Extract release year for age prediction
df <- df %>%
  mutate(release_year = as.numeric(substr(track_album_release_date, 1, 4))) %>%
  filter(!is.na(release_year))

# Select numerical audio features for ML similarity
features <- c("danceability", "energy", "loudness", "speechiness", 
              "acousticness", "instrumentalness", "liveness", "valence", "tempo")

# Remove rows with NA in features, then scale (Z-score normalization)
df_clean <- df[complete.cases(df[, features]), ]
feature_matrix <- scale(df_clean[, features])
rownames(feature_matrix) <- df_clean$track_id

#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
    res$setHeader("Access-Control-Allow-Headers", "Content-Type")
    res$status <- 200
    return(list())
  }
  plumber::forward()
}

#* Predict user age based on playlist era
#* @get /predict_age
function() {
  # Heuristic: People typically lock in their musical tastes around age 15
  median_year <- median(df_clean$release_year, na.rm = TRUE)
  
  birth_year <- median_year - 15
  current_year <- as.numeric(format(Sys.Date(), "%Y"))
  estimated_age <- current_year - birth_year
  
  return(list(
    median_release_year = median_year,
    estimated_age = estimated_age,
    message = paste("Based on a median track release year of", median_year, ", the user's estimated age is", estimated_age)
  ))
}

#* Get song recommendations using Cosine Similarity
#* @param track_name The name of the seed song
#* @post /recommend
function(track_name) {
  # Find the track ID in the dataset
  seed_song <- df_clean %>% 
    filter(tolower(track_name) == tolower(track_name)) %>% 
    head(1)
  
  if (nrow(seed_song) == 0) {
    return(list(error = "Song not found in the 30k dataset."))
  }
  
  seed_id <- seed_song$track_id
  seed_features <- feature_matrix[rownames(feature_matrix) == seed_id, , drop = FALSE]
  
  # Calculate Cosine Similarity against all 30k songs
  sim_scores <- proxy::simil(feature_matrix, seed_features, method = "cosine")
  
  # Get top 5 highest similarity indices (excluding the seed itself)
  top_indices <- order(sim_scores, decreasing = TRUE)[2:6]
  
  # Return the metadata of the recommended tracks
  recommendations <- df_clean[top_indices, c("track_name", "track_artist", "track_album_name")]
  return(recommendations)
}