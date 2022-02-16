#' Get registry features needed
#'
#' @param feature_registry A vector of all the `step_feature_*`s available.
#' @param features A character vector of the features needed for your model.
#'
#' @return A character vector.
#' @export
get_registry_features_needed <- function(feature_registry, features) {
  features[features %in% names(feature_registry)]
}

#' Get base faetures needed
#'
#' @param feature_registry A vector of all the `step_feature_*`s available.
#' @param feature The name of the feature you are interested in collecting base features from.
#'
#' @return A character vector.
get_base_features_needed <- function(feature_registry, feature) {
  deps <- feature_registry[feature][[1]]$deps
  deps_in_registry <- deps %in% names(feature_registry)

  # we are not interested in "primitive features" e.g. email, because those come
  # from the data and are not the result of a transformation.
  # thus making it our base case here
  if (!any(deps_in_registry)) {
    return(feature)
  }

  deps_to_explore <- deps[deps_in_registry]

  deps_to_explore |>
    purrr::map(~ get_base_features_needed(feature_registry, .x)) |>
    purrr::flatten_chr() |>
    # order is important! keep base features always first in the vector
    # this is a naive attempt at a DAG
    `c`(deps_to_explore)
}

#' Get all base features needed
#'
#' @param feature_registry A vector of all the `step_feature_*`s available.
#' @param features A character vector of the features needed for your model.
#'
#' @return A character vector.
#' @export
get_all_base_features_needed <- function(feature_registry, features) {
  get_registry_features_needed(feature_registry, features) |>
    purrr::map(~ get_base_features_needed(feature_registry, .x)) |>
    purrr::reduce(`c`) |>
    unique()
}

#' Get unneeded recipe vars
#'
#' @param unprepped_recipe_full Unprepped recipe, still with all steps included.
#' @param feature_and_deps_names_used Character vector of features and dependencies needed.
#' @param features A character vector of the features needed for your model.
#'
#' @return A character vector.
#' @export
get_unneeded_recipe_vars <- function(unprepped_recipe_full, feature_and_deps_names_used, features) {
  recipe_var_info <- unprepped_recipe_full$var_info

  c(
    recipe_var_info$variable[
      recipe_var_info$role == "predictor" &
        !(recipe_var_info$variable %in% features)
    ],
    # we want to discard unnecessary base features and only keep the final features
    unique(
      setdiff(
        feature_and_deps_names_used,
        intersect(features, feature_and_deps_names_used)
      )
    )
  )
}

#' Collect features and dependencies
#'
#' @param feature_registry A vector of all the `step_feature_*`s available.
#' @param features A character vector of the features needed for your model.
#'
#' @return A character vector.
#' @export
collect_features_and_deps <- function(feature_registry, features) {
  registry_features_needed <- get_registry_features_needed(feature_registry, features)
  base_features_needed <- get_all_base_features_needed(feature_registry, features)

  feature_and_deps_names_used <- c(
    base_features_needed, registry_features_needed
  ) |>
    unique()
}
