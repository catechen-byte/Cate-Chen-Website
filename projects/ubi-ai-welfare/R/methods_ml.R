#' Machine learning: predict households with largest UBI welfare gains under AI shock
#' @param data Household data after AI shock applied
#' @param ubi_monthly UBI amount
#' @param config Config
#' @return List with decision tree and random forest results
run_ml_welfare_prediction <- function(
    data,
    ubi_monthly = 1000,
    scenario = "misaligned_automation",
    config = load_config()
) {
  if (!requireNamespace("rpart", quietly = TRUE)) {
    install.packages("rpart", repos = "https://cloud.r-project.org")
  }
  if (!requireNamespace("ranger", quietly = TRUE)) {
    install.packages("ranger", repos = "https://cloud.r-project.org")
  }

  shocked <- apply_ai_shock(data, scenario, config = config)
  sim <- simulate_ubi(shocked, ubi_monthly, funding = "deficit_financed", config = config)

  rho <- config$welfare$crra_rho
  base_u <- crra_utility(shocked$ai_shocked_income, rho)
  policy_u <- crra_utility(sim$net_resources, rho)
  welfare_gain <- policy_u - base_u

  ml_data <- shocked |>
    dplyr::mutate(
      welfare_gain = welfare_gain,
      log_income = log(pmax(market_income, 1)),
      high_ai_exposure = as.integer(ai_exposure >= 0.5)
    ) |>
    dplyr::select(
      welfare_gain, adults, children, employed, log_income,
      ai_exposure, automation_prone, augmentation_prone, high_ai_exposure
    )

  set.seed(42)
  n <- nrow(ml_data)
  train_idx <- sample(seq_len(n), size = floor(0.7 * n))

  train <- ml_data[train_idx, ]
  test <- ml_data[-train_idx, ]

  # Decision tree (Economics 50 Lecture 13 style)
  tree_formula <- welfare_gain ~ adults + children + employed + log_income +
    ai_exposure + automation_prone + augmentation_prone + high_ai_exposure

  tree_model <- rpart::rpart(
    tree_formula,
    data = train,
    method = "anova",
    control = rpart::rpart.control(maxdepth = 4, cp = 0.01)
  )

  tree_pred <- predict(tree_model, newdata = test)
  tree_rmse <- sqrt(mean((test$welfare_gain - tree_pred)^2))

  # Random forest
  rf_model <- ranger::ranger(
    welfare_gain ~ adults + children + employed + log_income +
      ai_exposure + automation_prone + augmentation_prone + high_ai_exposure,
    data = train,
    num.trees = 200,
    importance = "impurity"
  )

  rf_pred <- predict(rf_model, data = test)$predictions
  rf_rmse <- sqrt(mean((test$welfare_gain - rf_pred)^2))

  list(
    tree_model = tree_model,
    rf_model = rf_model,
    tree_rmse = tree_rmse,
    rf_rmse = rf_rmse,
    feature_importance = rf_model$variable.importance,
    ml_data = ml_data
  )
}
