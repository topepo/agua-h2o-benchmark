library(tidymodels)
library(agua)
library(h2o)

# ------------------------------------------------------------------------------

# monitor using
# /usr/local/opt/python@3.9/Frameworks/Python.framework/Versions/3.9/bin/syrupy.py -c '(R\.framework)|(java)' -t ~/tmp/multithread_grid --separator=, --no-align

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE)

h2o.init(nthreads = -1)
h2o_thread_spec <- agua_backend_options(parallelism = 5)

# ------------------------------------------------------------------------------

set.seed(1)
dat <- sim_classification(10000)
rs <- vfold_cv(dat, v = 10)

# ------------------------------------------------------------------------------

nnet_spec <-
  mlp(hidden_units = tune(), penalty = tune(), epochs = tune(), activation = tune()) %>%
  set_engine("h2o") %>%
  set_mode("classification")

# ------------------------------------------------------------------------------

set.seed(2)
nnet_grid <-
  nnet_spec %>%
  extract_parameter_set_dials() %>%
  grid_max_entropy(size = 5)

# ------------------------------------------------------------------------------

grid_ctrl <- control_grid(backend_options = h2o_thread_spec)

system.time({
  set.seed(3)
  nnet_res <-
    nnet_spec %>%
    tune_grid(class ~ ., resamples = rs, grid = nnet_grid, control = grid_ctrl)
})

collect_metrics(nnet_res)

# ------------------------------------------------------------------------------

q("no")
