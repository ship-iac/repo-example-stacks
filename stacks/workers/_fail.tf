# Step-8 acceptance fixture: force a plan-time failure in exactly this one stack
# to prove fail-fast:false cell isolation and that shipmate / checkmate blocks
# the merge when a plan cell fails. Remove to restore a clean plan.
resource "terraform_data" "fail_fixture" {
  lifecycle {
    precondition {
      condition     = false
      error_message = "Step-8 fixture: forced plan failure in stacks/workers."
    }
  }
}
