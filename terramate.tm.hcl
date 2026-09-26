terramate {
  config {
    run {
      env {
        TF_VAR_env = terramate.stack.name == "auth" ? "prod" : env.TF_VAR_env
      }
    }
  }
}
