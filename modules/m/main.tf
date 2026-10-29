variable "v" {
  type    = string
  default = "1"
}

output "o" {
  value = var.v
}
