<!-- badges: start -->
[![R-CMD-check](https://github.com/jcpsantiago/beamter/workflows/R-CMD-check/badge.svg)](https://github.com/jcpsantiago/beamter/actions)
<!-- badges: end -->

> Der Nächste, bitte!

# beamter [bəˈʔamtɐ]
Programmatically create tidymodels [recipes](https://github.com/tidymodels/recipes/) from a registry of steps.


## What is this?
`beamter` let's you create a registry of `{recipes}` preprocessing steps. 

At work, I built a model training pipeline with DVC many models at once. For this flexibility, I had to build `recipes` step-by-step from a list of features. Models can have different features, or use different data. This means each model has its own preprocessing `recipe`.

I reached out to the [RStudio community](https://community.rstudio.com/t/programmatically-disable-recipe-steps-for-deployment/111194), but it seems I had a very niche use-case. It happens 😅. In any case, here is my solution in all its open-source glory.

`beamter` is also a great base to build your own "feature store as a package". You could then share it among team-members, or use across different ML projects. Keep your ML work DRY 🧐

## How to use beamter?
Get it from this repo
```r
remotes::install_github("jcpsantiago/beamter")
```

The first step is to create a _feature registry_, This is just an R vector which contains all the recipe steps ("features" from now on) you want to make available for any model.
I define _every_ feature that needs any transformation in this manner. 
You don't need to define features that are used as-is from the raw data e.g. some numeric value like a price.

```r
feature_registry <- c(
  # "base features" don't depend on anything else in the feature registry
  step_mutate_feat("hour", "created_at", format(strptime(created_at,"%H:%M:%S"),'%H')),
  # args are: `feature name`, `dependencies` i.e. the cols in the data needed for the calculations and
  # the actual code passed to `step_mutate`
  step_mutate_feat("email_name", "email", tolower(gsub("@.*", "", email))),
  # features can depend on other features in the registry,
  # dependencies are resolved when creating the recipe
  step_mutate_feat("n_chars_in_email", "email_name", nchar(email_name))
)
```

Currently, only `recipes::step_mutate` is wrapped as `step_mutate_feat` in beamter, but the `beamter::step_feature` can potentially wrap any `step_*`. 
Let me know if you need others.

Once you have your feature registry, you need to know which features you want:
```r
features_needed <- c("hour", "n_chars_in_email")
```
this can come from some YAML configuration where you define which features the
different models use, or just straight in a script if you're using beamter as a
feature store for a single model.

Then just assemble the recipe:
```r
unprepped_recipe <- assemble_recipe(
  feature_registry, features, df_for_recipe, recipe_roles
)
```

Use it as you would any other output from `recipes::recipe()`.

To use it in a production context, you probably want to cut down the fat:
```r
recipes::prep(unprepped_recipe) |>
  butcher::butcher()
  
# aggressive size savings
prepped_recipe$orig_lvls <- NULL
prepped_recipe$template <- NULL
prepped_recipe$term_info <- NULL
prepped_recipe$retained <- NULL

# these two elements are needed for baking and should never be removed!
# prepped_recipe$last_term_info
# prepped_recipe$var_info
```
