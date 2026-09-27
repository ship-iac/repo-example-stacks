resource "terraform_data" "big" {
  count = 600
  input = "c12-acceptance-${count.index}-${join("", [for i in range(80) : "x"])}"
}
