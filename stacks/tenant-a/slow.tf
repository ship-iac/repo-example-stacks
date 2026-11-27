resource "terraform_data" "slow" {
  input = "m35-acceptance-1"
  provisioner "local-exec" {
    command = "sleep 150"
  }
}
