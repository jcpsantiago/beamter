feature_registry <- c(
  step_mutate_feat("hour", "created_at", format(strptime(created_at,"%H:%M:%S"),'%H')),
  step_mutate_feat("email_name", "email", tolower(gsub("@.*", "", email))),
  step_mutate_feat("n_chars_in_email", "email_name", nchar(email_name))
)

assemble_recipe(
  feature_registry,
  c("hour", "n_chars_email"),
  mtcars,
  c(
    c("numeric_id", "outcome"),
    rep("predictor", length(names(mtcars)) - 2)
  ))

