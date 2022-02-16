test_that("creating a step works", {
  step_mutate_test <- step_feature(
    recipes::step_mutate,
    "hour",
    "created_at",
    format(strptime(created_at,"%H:%M:%S"),'%H')
  )

  expect_named(
    step_mutate_test,
    "hour"
  )
  expect_equal(
    step_mutate_test$hour$deps,
    "created_at"
  )
  expect_equal(
    step_mutate_test$hour$step_fn,
    quote(recipes::step_mutate)
  )
  expect_equal(
    step_mutate_test$hour$args$hour,
    quote(format(strptime(created_at,"%H:%M:%S"),'%H'))
  )
})
