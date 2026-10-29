variable "v" {
  type    = string
  default = "1"
}

output "o" {
  value = var.v
}

resource "terraform_data" "m" {
  input = var.v
}
