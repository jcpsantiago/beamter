feature_registry <- c(
  step_mutate_feat("hour", "created_at", lubridate::hour(created_at)),
  step_mutate_feat("email_name", "email", tolower(stringr::str_replace(email, "@.*", ""))),
  step_mutate_feat("n_digits_in_email", "email_name", stringr::str_count(email_name, "[0-9]"))
)
