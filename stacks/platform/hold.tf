# G1 live check: holds the platform apply for 600 s on every version change.
resource "terraform_data" "hold" {
  triggers_replace = [var.app_version]

  provisioner "local-exec" {
    command = "sleep 600"
  }
}
