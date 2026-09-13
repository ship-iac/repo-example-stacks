globals "shipmate" {
  env_order = {
    "dev-us" = ["dev-eu"]
  }

  # Dynamic backend: the layout derives `TF_VAR_env` from each environment's own
  # name and `TF_VAR_region` from its `region`, which is what the per-environment
  # variables carry today. Under `dry` every environment in the matrix needs an
  # entry with a non-empty region, or the run refuses at detect.
  layout = "dry"

  environments = {
    "dev-eu" = {
      region = "eu-west-1"
    }
    "dev-us" = {
      region = "us-east-1"
    }
    "sbx" = {
      region = "eu-west-1"
    }
  }
}
