resource "random_pet" "new_pet" {
  keepers = {
    app_version = var.app_version
  }
}

output "name_net_pet" {
  value = random_pet.new_pet.id
}
