get_registry_features_needed <- function(feature_registry, features){
  features[features %in% names(feature_registry)]
}

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

get_all_features_needed <- function(feature_registry, features){
  get_registry_features_needed(feature_registry, features) %>%
    purrr::map(., ~ get_base_features_needed(feature_registry, .x)) %>%
    purrr::reduce(`c`) %>%
    unique(.)
}

build_recipe_call_factory <- function(features) {
  function(recipe, feature) {
    rlang::call2(
      features[[feature]]$step_fn,
      recipe,
      !!!features[[feature]]$args
    )
  }
}
