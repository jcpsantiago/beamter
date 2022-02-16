feature_registry <- c(
  step_mutate_feat("hour", "created_at", lubridate::hour(created_at)),
  step_mutate_feat("email_name", "email", tolower(stringr::str_replace(email, "@.*", ""))),
  step_mutate_feat("n_digits_in_email", "email_name", stringr::str_count(email_name, "[0-9]"))
)

get_base_features_needed(feature_registry, "n_digits_in_email")

test_that("getting base features works", {
  expect_equal()
})
