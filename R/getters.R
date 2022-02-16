#' Title
#'
#' @param feature_registry
#' @param features
#'
#' @return
#' @export
#'
#' @examples
get_registry_features_needed <- function(feature_registry, features) {
  features[features %in% names(feature_registry)]
}

#' Title
#'
#' @param feature_registry
#' @param feature
#'
#' @return
#' @export
#'
#' @examples
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

  deps_to_explore %>%
    purrr::map(~ get_base_features_needed(feature_registry, .x)) %>%
    purrr::flatten_chr(.) %>%
    # order is important! keep base features always first in the vector
    # this is a naive attempt at a DAG
    `c`(., deps_to_explore)
}

#' Title
#'
#' @param feature_registry
#' @param features
#'
#' @return
#' @export
#'
#' @examples
get_all_base_features_needed <- function(feature_registry, features) {
  get_registry_features_needed(feature_registry, features) %>%
    purrr::map(., ~ get_base_features_needed(feature_registry, .x)) %>%
    purrr::reduce(`c`) %>%
    unique(.)
}

#' Title
#'
#' @param unprepped_recipe_full
#' @param feature_and_deps_names_used
#' @param features
#'
#' @return
#' @export
#'
#' @examples
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

#' Title
#'
#' @param feature_registry
#' @param features
#'
#' @return
#' @export
#'
#' @examples
collect_features_and_deps <- function(feature_registry, features) {
  registry_features_needed <- get_registry_features_needed(feature_registry, features)
  base_features_needed <- get_all_base_features_needed(feature_registry, features)

  feature_and_deps_names_used <- c(
    base_features_needed, registry_features_needed
  ) %>%
    unique(.)
}
