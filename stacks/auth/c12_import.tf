resource "terraform_data" "imported" {}

import {
  to = terraform_data.imported
  id = "c12-acceptance"
}
