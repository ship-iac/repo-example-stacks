resource "null_resource" "smoke_fail" {
  triggers = {
    v = var.smoke_undefined
  }
}
