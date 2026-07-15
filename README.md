# repo-example-stacks

A minimal Terramate + OpenTofu monorepo used to exercise a multi-stack,
multi-environment dependency graph end to end — code generation, stack
discovery by tag, dependency-graph ordering, and three common CI failure
modes — **without touching any real cloud**.

- **Every stack manages only `random_pet` / `terraform_data` null resources.**
- **State is local** (`.state/<env>/<region>/terraform.tfstate` per stack).
- **Zero cloud credentials are required or used**, anywhere.

This README is the whole onboarding doc. Following it top to bottom — including
all three failure fixtures — takes under 15 minutes.

## Prerequisites

- [Terramate](https://terramate.io/) 0.17.1
- [OpenTofu](https://opentofu.org/) 1.12.4
- Windows PowerShell. On this machine (and likely yours) both tools are
  installed but **not on the default PATH** — every session below starts by
  refreshing PATH from the machine + user environment so `terramate`/`tofu`
  resolve.

Verify your toolchain first:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
terramate version   # expect 0.17.1
tofu version        # expect OpenTofu v1.12.4
```

## Quickstart

Copy-paste block for a fresh clone. This regenerates code, lists the dev-eu
stacks, prints the full dependency graph, then inits/plans one stack (`dns`):

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

git clone <this-repo-url> repo-example-stacks
cd repo-example-stacks

# Regenerate the per-stack backend/provider/variables/main files from
# stacks/root.tm.hcl. Committed generated files are already up to date, so
# this should print "Nothing to do, generated code is up to date".
terramate generate

# List every stack tagged for the dev-eu environment.
terramate list --tags env/dev-eu

# Print the full cross-stack dependency graph (Graphviz DOT).
terramate experimental run-graph

# Drive one stack: dns is dev-us / us-east-1.
cd stacks/dns
$env:TF_VAR_env = "dev-us"
$env:TF_VAR_region = "us-east-1"
tofu init -input=false
tofu plan -input=false
```

Expect `tofu plan` to show 2 resources to add (`random_pet.this`,
`terraform_data.this`) on a stack that has never been applied.

## Repository layout

```
repo-example-stacks/
├── terramate.tm.hcl          # enables the "scripts" experiment
├── .gitattributes            # forces LF checkout (see "Windows gotchas")
├── tools/
│   └── mutate-state.ps1      # drift fixture helper
└── stacks/
    ├── root.tm.hcl           # shared globals + generate_hcl blocks + scripts,
    │                         # inherited by every stack below it
    ├── dns/                  # env/dev-us
    ├── platform/              # env/dev-eu, after dns
    ├── auth/                  # env/dev-eu, after platform
    ├── workers/                # env/dev-eu, after platform
    ├── app/                   # env/dev-eu + env/dev-us, after auth & workers
    ├── tenant-a/               # env/dev-eu + env/dev-us, after app
    ├── tenant-b/               # env/dev-eu + env/dev-us, after app
    └── sandbox/box/            # env/sbx, standalone (no dependents/dependencies)
```

Each stack directory holds a `stack.tm.hcl` (name, tags, `after` dependencies,
stable UUID) plus four Terramate-generated files that you should never
hand-edit: `_backend.tf`, `_providers.tf`, `_variables.tf`, `_main.tf`. They
all begin with `// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT` and are
produced from the single set of `generate_hcl` blocks in `stacks/root.tm.hcl`.
If you need to change what a stack contains, edit `root.tm.hcl` and rerun
`terramate generate` — do not edit the generated `.tf` files directly, or
`terramate generate` will refuse to touch them (see below).

## Tag convention: `env/<name>`

Stacks are tagged with a slash-separated `env/<name>` tag, never a colon
(`env/dev-eu`, not `env:dev-eu`). A stack can carry more than one `env/*` tag
if it's meant to be instantiated in more than one environment (`app`,
`tenant-a`, `tenant-b` all carry both `env/dev-eu` and `env/dev-us`). Use
`terramate list --tags env/<name>` to select the stacks for one environment,
and `terramate list --tags env/dev-eu --tags env/dev-us` semantics are OR'd if
you ever need the union — see `terramate list --help`.

`sandbox/box` is tagged `env/sbx` — a standalone scratch stack, excluded from
both `env/dev-eu` and `env/dev-us`, with no `after` and nothing depending on
it. Use it to try things without touching the real DAG.

## The dependency graph

`after = [...]` in each `stack.tm.hcl` wires up a single, environment-agnostic
5-level DAG:

```
dns (dev-us)
 └─▶ platform (dev-eu)
      ├─▶ auth (dev-eu)
      │    └─▶ app (dev-eu, dev-us)
      │         ├─▶ tenant-a (dev-eu, dev-us)
      │         └─▶ tenant-b (dev-eu, dev-us)
      └─▶ workers (dev-eu)
           └─▶ app  (same node as above)

sandbox/box (sbx)   — disconnected, no edges
```

Note that the graph is **not** duplicated per environment: `dns` only ever
runs under `dev-us`/`us-east-1`, while `platform`/`auth`/`workers` only run
under `dev-eu`. `app`, `tenant-a`, and `tenant-b` are the stacks that
straddle both environments — the *same* stack directory is applied twice,
once per environment, distinguished purely by which `TF_VAR_env`/
`TF_VAR_region` you export before running `tofu` (see next section). Ordering
(`after`) is about stack-to-stack dependency, not about environment.

Confirm this yourself:

```powershell
terramate experimental run-graph
```

which prints Graphviz DOT with edges `dns->platform`, `platform->auth`,
`platform->workers`, `auth->app`, `workers->app`, `app->tenant-a`,
`app->tenant-b`, and `box` with no edges at all.

## Environment / region model

Nothing in a stack's generated code hardcodes an environment or region.
Instead, `stacks/root.tm.hcl` generates:

- `_variables.tf` declaring `var.env` and `var.region` (both required,
  no default) plus `var.app_version` and `var.fail_precondition`.
- `_backend.tf` pointing the local backend at
  `.state/${var.env}/${var.region}/terraform.tfstate` — so state never
  collides across environments even though it's the same stack directory.

You supply `env`/`region` via `TF_VAR_env` / `TF_VAR_region` before running
`tofu init`/`plan`/`apply`. For example:

| Stack       | Example env / region invocation                                   |
|-------------|---------------------------------------------------------------------|
| dns         | `TF_VAR_env=dev-us`, `TF_VAR_region=us-east-1`                      |
| platform    | `TF_VAR_env=dev-eu`, `TF_VAR_region=eu-west-1`                      |
| auth/workers| `TF_VAR_env=dev-eu`, `TF_VAR_region=eu-west-1`                      |
| app/tenant-* | `TF_VAR_env=dev-eu`/`TF_VAR_region=eu-west-1` **or** `TF_VAR_env=dev-us`/`TF_VAR_region=us-east-1` (run once per env) |

## Driving a stack by hand

Per stack: `cd` into it, set the two required vars, `tofu init`, `tofu plan`
(and `tofu apply -auto-approve` if you actually want the null resources
created). Verified example, `platform` (dev-eu / eu-west-1):

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
cd stacks/platform
$env:TF_VAR_env = "dev-eu"
$env:TF_VAR_region = "eu-west-1"
tofu init -input=false
tofu plan -input=false
```

Terramate also ships two convenience scripts (`stacks/root.tm.hcl`, requires
the `scripts` experiment already enabled in `terramate.tm.hcl`):

```powershell
terramate script run plan    # tofu init && tofu plan -out=stack.otplan
terramate script run apply   # tofu init && tofu apply -auto-approve stack.otplan
```

run from inside a stack directory, with `TF_VAR_env`/`TF_VAR_region` still
exported.

## Failure fixtures

Three fixtures simulate the CI failures this repo exists to exercise. Each is
independent — run them in any order, against any stack (examples below use
`dns`, `TF_VAR_env=dev-us`, `TF_VAR_region=us-east-1`).

### 1. Precondition failure

Toggle it on and plan:

```powershell
$env:TF_VAR_fail_precondition = "true"
tofu plan -input=false
```

Expected: plan fails with

```
Error: Resource precondition failed
...
fail_precondition fixture is enabled
```

exit code 1. Unset it to go back to normal (`Remove-Item Env:\TF_VAR_fail_precondition`).

### 2. Drift

Requires the stack to have been applied at least once (`tofu apply -input=false -auto-approve`).
`tools/mutate-state.ps1` deletes the `random_pet` resource straight out of
local state, bypassing OpenTofu, so the next plan reports real drift. Run it
with an explicit path qualifier (PowerShell won't run a bare relative script
path) — from inside `stacks/dns` that's two levels up to the repo root:

```powershell
..\..\tools\mutate-state.ps1 -StateFile ".state/dev-us/us-east-1/terraform.tfstate"
tofu plan -input=false -detailed-exitcode
```

Expected: exit code **2** (changes present) — `tofu plan` shows
`random_pet.this` being re-created and `terraform_data.this` updated in
place. (`-detailed-exitcode`: 0 = no changes, 1 = error, 2 = changes present.)

### 3. Stale plan

Save a plan, let something else advance the state, then try to apply the
now-outdated plan file:

```powershell
tofu plan -input=false -out plan.otplan
$env:TF_VAR_app_version = "99"       # simulate a concurrent apply with a new input
tofu apply -input=false -auto-approve
Remove-Item Env:\TF_VAR_app_version
tofu apply plan.otplan
```

Expected: the final `tofu apply plan.otplan` fails with

```
Error: Saved plan is stale
The given plan file can no longer be applied because the state was changed
by another operation after the plan was created.
```

exit code 1.

## Windows gotchas found while verifying this walkthrough

- **`terramate/tofu` are not on PATH by default** — every command block above
  starts with the `$env:Path = ...Machine...+...User...` line for this
  reason; without it you'll get "not recognized as the name of a cmdlet".
- **Line endings**: this repo ships a `.gitattributes` (`* text=auto eol=lf`)
  so the committed, Terramate-generated `.tf` files always check out with LF.
  Without it, Windows checkouts with `core.autocrlf=true` (the Git-for-Windows
  default) silently rewrite those files to CRLF, and `terramate generate`
  then refuses to regenerate them ("manually defined code found") because the
  content no longer matches what it expects to have written. If you ever see
  that error on a clone that predates the `.gitattributes` fix, delete the
  generated `_*.tf` files and rerun `terramate generate`.
- **`tofu plan -out=<path>` (equals form)**: on this machine, typing
  `tofu plan -input=false -out=plan.otplan` directly at a PowerShell prompt
  reliably fails with `Error: Too many command line arguments`, even though
  `-input=false` alone works fine. The space form,
  `tofu plan -input=false -out plan.otplan`, works every time (as does
  passing all args via an array/splat). All commands in this README use the
  space form for `-out` — copy them as written.
- **`tools/mutate-state.ps1`**: originally resolved `-StateFile` through
  `[System.IO.File]::WriteAllText`, which reads .NET's
  `[Environment]::CurrentDirectory` rather than PowerShell's `$PWD`. Those two
  can silently diverge after `Set-Location`/`cd`, which made the script write
  to (or fail against) the wrong path while still printing a "mutated: ..."
  success message. Fixed to resolve the path via `Resolve-Path` first — the
  drift fixture above reflects the fixed behavior.
