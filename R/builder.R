#' Initialize a recipe
#'
#' @param df_for_recipe The data.frame used to build the recipe.
#' @param recipe_roles The roles used to build the recipe.
#'
#' @return An unprepped recipe.
init_recipe <- function(df_for_recipe, recipe_roles) {
  recipes::recipe(
    df_for_recipe,
    vars = names(df_for_recipe),
    roles = recipe_roles
  )
}

#' Build a recipe call
#'
#' @param feature_registry A vector of all the `step_feature_*`s available.
#' @param recipe A recipe object.
#' @param feature The name of the feature needed.
#'
#' @return An R call.
build_recipe_call <- function(feature_registry, recipe, feature) {
  rlang::call2(
    feature_registry[[feature]]$step_fn,
    recipe,
    !!!feature_registry[[feature]]$args
  )
}

#' Assemble a recipe
#'
#' @param feature_registry A vector of all the `step_feature_*`s available.
#' @param features A character vector of the features needed for your model.
#' @param df_for_recipe The data.frame used to build the recipe.
#' @param recipe_roles The roles used to build the recipe.
#'
#' @return An unprepped recipe.
#' @export
assemble_recipe <- function(feature_registry, features, df_for_recipe, recipe_roles) {
  unprepped_recipe_init <- init_recipe(df_for_recipe, recipe_roles)
  features_and_deps_used <- collect_features_and_deps(feature_registry, features)
  build_recipe <- purrr::partial(build_recipe_call, feature_registry = feature_registry)


  unprepped_recipe_full <- features_and_deps_used |>
    purrr::reduce(
      build_recipe,
      .init = unprepped_recipe_init
    ) |>
    eval()

  unneeded_recipe_vars <- get_unneeded_recipe_vars(
    unprepped_recipe_full, features_and_deps_used, features
  )

  unprepped_recipe_full |>
    recipes::step_rm(
      dplyr::all_of(unneeded_recipe_vars)
    )
}
