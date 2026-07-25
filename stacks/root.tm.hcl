globals {
  version = "5"
  # Acceptance fixture: when true, this stack PLANS clean but FAILS at apply.
  # An HCL global (not a TF_VAR) so it cannot perturb the TF_VAR fingerprint —
  # a fingerprint change would abort the apply as blocked instead of letting it
  # run and fail, which is a different path.
  fail_apply = false
}

generate_hcl "_backend.tf" {
  content {
    terraform {
      backend "local" {
        path = ".state/${var.env}/${var.region}/terraform.tfstate"
      }
    }
  }
}

generate_hcl "_providers.tf" {
  content {
    terraform {
      required_providers {
        random = {
          source  = "hashicorp/random"
          version = "~> 3.0"
        }
      }
    }
  }
}

generate_hcl "_variables.tf" {
  content {
    variable "env" { type = string }
    variable "region" { type = string }
    variable "app_version" {
      type    = string
      default = global.version
    }
    variable "fail_precondition" {
      type    = bool
      default = false
    }
    variable "fail_apply" {
      type    = bool
      default = global.fail_apply
    }
  }
}

generate_hcl "_main.tf" {
  content {
    resource "random_pet" "this" {
      keepers = {
        app_version = var.app_version
      }
    }
    resource "terraform_data" "this" {
      triggers_replace = [var.app_version]
      input            = random_pet.this.id
      lifecycle {
        precondition {
          condition     = !var.fail_precondition
          error_message = "fail_precondition fixture is enabled"
        }
        # Deliberately references a value unknown until apply, so the
        # precondition is deferred: the plan stays clean and the failure lands
        # during apply. A condition built only from plan-time-known values would
        # fail the PLAN instead, which never yields a failed apply cell.
        precondition {
          condition     = !var.fail_apply || startswith(random_pet.this.id, "zzz-never-matches")
          error_message = "fail_apply fixture is enabled - this stack fails during apply by design"
        }
      }
    }
    output "name" {
      value = random_pet.this.id
    }
  }
}

script "plan" {
  description = "plan this stack"
  job {
    commands = [
      ["tofu", "init", "-input=false"],
      ["tofu", "plan", "-input=false", "-lock=false", "-out=stack.otplan"],
    ]
  }
}

script "apply" {
  description = "apply this stack"
  job {
    commands = [
      ["tofu", "init", "-input=false"],
      ["tofu", "apply", "-input=false", "-lock=false", "-auto-approve", "stack.otplan"],
    ]
  }
}
