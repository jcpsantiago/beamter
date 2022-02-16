#' Create step
#'
#' @param step_fn The step function to be used, e.g. recipes::step_mutate
#' @param step_name The name of the step/feature.
#' @param deps A vector of strings with names of dependencies e.g. c("email").
#' @param args Arguments passed to `step_fn`.
#'
#' @return A list.
#' @export
step_feature <- function(step_fn, step_name, deps, args) {
  if (step_name %in% deps) {
    stop(
      sprintf(
        "Step name %s conflicts with one of the dependency names!", step_name
      )
    )
  }

  l <- list(
    list(
      step_fn = rlang::enexpr(step_fn),
      deps = deps,
      args = list(rlang::enexpr(args))
    )
  )

  names(l) <- step_name
  names(l[[1]]$args) <- step_name

  l
}

#' Create mutate step
#'
#' @param ... step_name, deps and args
#'
#' @return A list.
#' @export
step_mutate_feat <- purrr::partial(step_feature, step_fn = recipes::step_mutate)
