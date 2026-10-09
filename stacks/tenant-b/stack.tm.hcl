stack {
  name        = "tenant-b"
  description = "tenant-b"
  tags        = ["envs/dev-eu"]
  after       = ["/stacks/app"]
  id          = "28ea9711-e125-4c92-b92c-79d1e0124272"
}
