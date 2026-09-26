# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**cfn-validate-action** is a GitHub Action that validates CloudFormation templates with comprehensive error reporting and artifact generation. It's built as a composite action using Bash and is distributed via GitHub Marketplace.

- **Main entry point**: `action.yaml` — defines the action interface (inputs, outputs, steps)
- **Core logic**: Steps within `action.yaml` — validation, output formatting, summary generation
- **Test fixtures**: `tests/fixtures/` — sample templates for testing various scenarios
- **Release management**: Semantic-release with custom plugins in `scripts/plugins/`

## Key Architecture

### Action Structure

The action is a **composite action** (defined in `action.yaml`). Each workflow step is a self-contained Bash script that runs in sequence:

1. **Print Inputs for Debugging** — logs configuration for troubleshooting
2. **Validate CloudFormation directory and template** — checks file existence, readability, and size (51.2 KB limit)
3. **Validate the CloudFormation template** — calls AWS CloudFormation API (`validate-template`)
4. **Validation summary** — generates markdown summary and output artifacts

### Test Strategy

Test fixtures in `tests/fixtures/` represent different scenarios:

- `valid-templates/` — templates that pass validation
- `invalid-templates/` — templates with syntax errors
- `nested-templates/` — templates with nested stacks
- `valid-parameters/`, `invalid-parameters/` — parameter handling
- `no-parameters/`, `mixed-nested-templates/`, `edge-cases/` — edge cases

Tests run via `.github/workflows/test.yml` using GitHub Actions against test fixtures.

### Release Process

Semantic-release automates versioning and publishing:

- Custom plugins in `scripts/plugins/` extend standard semantic-release behavior
- Configured in `.releaserc.json` and `package.json`
- Runs on pushes to `main` branch
- Creates tags, updates CHANGELOG, pushes to GitHub

### Dependency Management

- Uses npm for JavaScript dependencies (semantic-release, commitizen)
- `package.json` defines all devDependencies
- No application runtime dependencies — this is a pure Bash action

## Common Development Tasks

### Validate Changes Locally

Before committing, test the action against fixtures:

```bash
# Check syntax of action.yaml
cat action.yaml | grep -E "^[a-z]" | head -20

# Run a single test fixture manually (if you have AWS credentials configured):
# The action expects the repository to be checked out and AWS credentials to be configured
# You can test by running the action steps defined in action.yaml
```

### Run Tests

Tests are defined in `.github/workflows/test.yml`. They run automatically on push to `main` or `develop`, and on pull requests. To run tests locally:

```bash
# Test fixtures are in tests/fixtures/ with various template scenarios
# Each fixture directory contains templates to test different validation paths
```

### Make a Commit

This project uses **Conventional Commits** and Commitizen:

```bash
npm run cz  # Interactive commit tool (if available)
# OR manually follow the format: type(scope): description
#   type: feat, fix, chore, docs, style, refactor, perf, test
#   scope: (optional) area affected
#   example: fix(validation): handle empty template files
```

### Prepare a Release

Semantic-release handles this automatically on `main`, but if you need to manually run it:

```bash
npm run release
```

### Update Dependencies

```bash
npm update          # Update to latest versions within package.json constraints
npm audit           # Check for security vulnerabilities
npm audit fix       # Auto-fix vulnerabilities (if available)
```

## Important Files

- **action.yaml** — Action definition; inputs, outputs, step-by-step logic
- **scripts/plugins/** — Semantic-release plugins (custom commit analysis, versioning, publishing)
- **.github/workflows/test.yml** — Test automation; validates against fixtures on every push/PR
- **.github/workflows/release.yaml** — Releases to GitHub (runs on main branch)
- **.github/workflows/create-branch.yaml** — Auto-creates feature branches from GitHub Issues
- **README.md** — User-facing documentation with usage examples and troubleshooting
- **CONTRIBUTING.md** — Contribution guidelines
- **tests/fixtures/** — Test data; run through validation in test workflow

## CloudFormation Validation Details

The action calls AWS CloudFormation's `validate-template` API (step: "Validate the CloudFormation template"):

```bash
aws cloudformation validate-template \
  --template-body "file://$FULL_TEMPLATE_PATH" \
  --region "${{ inputs.aws-region }}" \
  --output json
```

**Constraints**:

- Template body max size: 51.2 KB (enforced in step: "Validate CloudFormation directory and template")
- Requires AWS credentials configured (from caller workflow, not action's responsibility)
- Outputs validation result JSON or errors to `{cloudformation-dir}/validation-output/`

## Inputs & Outputs

**Inputs** (defined in `action.yaml`):

- `cloudformation-dir` — directory containing templates (default: `.`)
- `template-file` — template filename (default: `template.yaml`)
- `aws-region` — AWS region (default: `us-east-1`)
- `aws-role-arn` — required; IAM role for AWS credential assumption

**Outputs**:

- `validation-result` — `success` or `failure`

## Debugging

### Check GitHub Action Logs

- Workflow runs in `.github/workflows/`
- Each step logs details (directory, file path, AWS region, etc.)
- Validation errors are captured in `{cloudformation-dir}/validation-output/template-errors.log`

### Enable Verbose Logging

Set `ACTIONS_STEP_DEBUG=true` in repository secrets for step-by-step debugging.

### Test Template Locally

```bash
# If AWS credentials are configured locally:
aws cloudformation validate-template \
  --template-body file://path/to/template.yaml \
  --region us-east-1 \
  --output json
```

### Nested Templates

If testing nested templates, ensure all nested template files are in a `nested-templates/` subdirectory alongside the main template. The action does **not** automatically validate nested templates — it only validates the main template syntax.

## Repository Conventions

- **Branch naming**: `feature/GHA-<issue-number>-<description>` (auto-created from issues)
- **Commit style**: Conventional Commits (analyzed by semantic-release)
- **Version bumping**: Automatic via semantic-release based on commit types
- **Node version**: 20.10.0 (used in release workflow)

## Common Pitfalls

1. **Missing AWS credentials** — The caller workflow must configure AWS credentials; this action assumes they're already set up.
2. **Template size > 51.2 KB** — Use `file://` for larger templates (AWS CloudFormation limitation).
3. **Nested template validation** — Only the main template is validated; nested templates are not independently validated by this action.
4. **Parameter format** — Parameters should be provided as JSON array with `ParameterName` and `ParameterValue` keys (see README for migration from older format).
