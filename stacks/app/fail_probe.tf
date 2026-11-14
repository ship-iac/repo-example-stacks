# Test-only: fails the apply in dev-eu, never the plan.
resource "terraform_data" "fail_probe" {
  triggers_replace = [var.app_version]
  provisioner "local-exec" {
    command = var.env == "dev-eu" ? "exit 1" : "true"
  }
}
