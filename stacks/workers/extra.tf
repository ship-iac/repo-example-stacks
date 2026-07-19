# preview-comment E2E: oversized-plan cell fixture — the rendered plan for this
# resource exceeds the preview comment's size budget, so its details section
# must truncate with a link to the check run.
resource "terraform_data" "big" {
  input = [for i in range(3000) : "padding-line-${i}-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"]
}
