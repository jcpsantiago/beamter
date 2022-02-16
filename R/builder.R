get_registry_features_needed <- function(feature_registry, features) {
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

get_all_base_features_needed <- function(feature_registry, features) {
  get_registry_features_needed(feature_registry, features) %>%
    purrr::map(., ~ get_base_features_needed(feature_registry, .x)) %>%
    purrr::reduce(`c`) %>%
    unique(.)
}

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

collect_features_and_deps <- function(feature_registry, features) {
  registry_features_needed <- get_registry_features_needed(feature_registry, features)
  base_features_needed <- get_all_base_features_needed(feature_registry, features)

  feature_and_deps_names_used <- c(
    base_features_needed, registry_features_needed
  ) %>%
    unique(.)
}

init_recipe <- function(df_for_recipe, recipe_roles) {
  recipes::recipe(
    df_for_recipe,
    vars = names(df_for_recipe),
    roles = recipe_roles
  )
}

build_recipe_call_factory <- function(feature_registry) {
  function(recipe, feature) {
    rlang::call2(
      feature_registry[[feature]]$step_fn,
      recipe,
      !!!feature_registry[[feature]]$args
    )
  }
}

assemble_recipe <- function(feature_registry, features, df_for_recipe, recipe_roles) {
  unprepped_recipe_init <- init_recipe(df_for_recipe, recipe_roles)
  features_and_deps_used <- collect_features_and_deps(feature_registry, features)
  build_recipe <- build_recipe_call_factory(feature_registry)


  unprepped_recipe_full <- features_and_deps_used %>%
    purrr::reduce(
      build_recipe,
      .init = unprepped_recipe_init
    ) %>%
    eval(.)

  unneeded_recipe_vars <- get_unneeded_recipe_vars(
    unprepped_recipe_full, features_and_deps_used, features
  )

  unprepped_recipe_full %>%
    recipes::step_rm(
      dplyr::all_of(unneeded_recipe_vars)
    )
}
