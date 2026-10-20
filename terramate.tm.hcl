terramate {
  config {
    run {
      env {
        TF_DATA_DIR = tm_try(".terraform/${env.TF_VAR_env}", ".terraform/local")
      }
    }
  }
}
