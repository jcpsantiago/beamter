> You need form B-42 for that.

# beamter
Programmatically create a tidymodels [recipe](https://github.com/tidymodels/recipes/) from a registry of steps.

## What is this?
I needed to build recipes programmatically, because the model training pipeline I built with [DVC](https://dvc.org) was used for multiple models at the same time (think different mdodel _variants_ trained on different populations, such as countries or industry sectors). 
This meant a preprocessing recipe would need to be different for each of the models, because it would be possible each would use slightly different features. 
Creating an über-recipe with all the features/steps was not possible, because some data populations lacked some data fields, which would lead to errors.

I reached out to the [RStudio community](https://community.rstudio.com/t/programmatically-disable-recipe-steps-for-deployment/111194), but it seems I had a very niche use-case. It happens 😅. 
In any case, here is my solution in all its open-source glory.

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
  step_mutate_feat("hour", "created_at", lubridate::hour(created_at)),
  step_mutate_feat("is_free_mail", "email", as.integer(isfreemail::is_free_email(email))),
  step_mutate_feat("email_name", "email", tolower(stringr::str_replace(email, "@.*", ""))),
  # features can depend on other features in the registry, dependencies are resolved when creating the recipe
  step_mutate_feat("n_digits_in_email", "email_name", stringr::str_count(email_name, "[0-9]"))
)
```

Currently, only `recipes::step_mutate` is wrapped as `step_mutate_feat` in beamter, but the `beamter::step_feature` can potentially wrap any `step_*`. 
Let me know if you need others.

Once you have your feature registry, you need to know which features you want:
```r
features_needed <- c("hour", "n_digits_in_email")
```

