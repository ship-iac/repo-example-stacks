stack {
  name        = "workers"
  description = "workers; G1 replan check"
  tags        = ["env/dev-eu"]
  after       = ["/stacks/platform"]
  id          = "6b3ea960-b44c-486b-a6fc-33af70ced4eb"
}
