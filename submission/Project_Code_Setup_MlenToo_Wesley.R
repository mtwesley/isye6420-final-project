# install.packages("devtools")
# install.packages("reticulate")
# install.packages("bayesplot")
# install.packages("bayestestR")
# install.packages("posterior")
# install.packages("readr")
# install.packages("dplyr")

library(devtools)
library(reticulate)

# Optional for Greta plotting capabilities
# install.packages("igraph")
# install.packages("DiagrammeR")

# Recommended install (will not work on Apple Silicon)
# install.packages("greta")
# install_greta_deps()

# My personal machine setup - pyenv and miniforge3
# use_python("~/.pyenv/versions/miniforge3/bin/python")

# Mac with Apple Silicon - supports TensorFlow 2
# install.packages("greta", repos = c("https://greta-dev.r-universe.dev",
#                  "https://cloud.r-project.org"))
# install_greta_deps()
