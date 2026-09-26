# GitHub Composite Action: CloudFormation Template Validator

<!-- Row 1: Status - Most Important -->
[![Release](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/actions/workflows/release.yaml/badge.svg)](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action)&nbsp;[![GitHub Action](https://img.shields.io/badge/GitHub-Action-blue?logo=github)](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action)&nbsp;[![Issues](https://img.shields.io/github/issues/subhamay-bhattacharyya-gha/cfn-validate-action)](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/issues)&nbsp;[![Last Commit](https://img.shields.io/github/last-commit/subhamay-bhattacharyya-gha/cfn-validate-action)](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commits)

<!-- Row 2: Code Quality -->
[![Top Language](https://img.shields.io/github/languages/top/subhamay-bhattacharyya-gha/cfn-validate-action)](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action)&nbsp;[![Commits](https://img.shields.io/github/commit-activity/t/subhamay-bhattacharyya-gha/cfn-validate-action)](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commits)

<!-- Row 3: Tech Stack -->
[![CloudFormation](https://img.shields.io/badge/CloudFormation-IaC-FF9900?logo=amazon&logoColor=white)](https://aws.amazon.com/cloudformation/)&nbsp;[![Built with Claude Code](https://img.shields.io/badge/Built_with-Claude_Code-D97757?logo=anthropic&logoColor=white)](https://claude.ai/)

<!-- Row 4: Repository Info -->
[![Files](https://img.shields.io/github/directory-file-count/subhamay-bhattacharyya-gha/cfn-validate-action)](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action)&nbsp;[![Repo Size](https://img.shields.io/github/repo-size/subhamay-bhattacharyya-gha/cfn-validate-action)](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action)&nbsp;[![Release Date](https://img.shields.io/github/release-date/subhamay-bhattacharyya-gha/cfn-validate-action)](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/releases)

<!-- Row 5: Custom Metrics -->
[![Custom Endpoint](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bsubhamay/9fb36e8446e7b5bb95f5e539e1d2fd2e/raw/cfn-validate-action.json)](https://gist.github.com/bsubhamay/9fb36e8446e7b5bb95f5e539e1d2fd2e)

A GitHub Composite Action that validates CloudFormation templates using the AWS CloudFormation API with comprehensive validation output and error reporting. This action is designed to be lightweight and modular—it expects the caller workflow to handle repository checkout and AWS credentials configuration.

> **Important**: This is a composite action that validates templates against AWS CloudFormation API. It requires the caller workflow to checkout the repository and configure AWS credentials. See [Prerequisites](#prerequisites) for details.

## Features

- **CloudFormation Template Validation**: Validates template syntax and structure using AWS CloudFormation's `validate-template` API
- **Comprehensive Validation Output**: Generates JSON validation results with capabilities, parameters, and metadata
- **Error Reporting**: Captures and displays detailed validation error messages
- **GitHub Step Summary**: Displays validation results directly in the GitHub Actions workflow summary
- **Multiple Template Formats**: Supports YAML (.yaml, .yml) and JSON (.json) CloudFormation templates
- **Template Size Validation**: Enforces AWS CloudFormation's 51.2 KB limit for template body size
- **Debug Information**: Logs template path, file size, and preview for troubleshooting

---

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `cloudformation-dir` | Directory containing CloudFormation templates | No | `.` |
| `template-file` | CloudFormation template filename | No | `template.yaml` |
| `aws-region` | AWS region for validation | No | `us-east-1` |
| `aws-role-arn` | AWS IAM role ARN for authentication | **Yes** | — |

## Outputs

| Name | Description | Possible Values |
|------|-------------|-----------------|
| `validation-result` | CloudFormation template validation result | `success`, `failure` |

---

## Prerequisites

Before using this action, ensure your workflow includes:

1. **Repository Checkout**: Use `actions/checkout@v4` to checkout your repository
2. **AWS Credentials Configuration**: Use `aws-actions/configure-aws-credentials@v4` to configure AWS credentials

This action focuses solely on CloudFormation validation and expects the repository to be checked out and AWS credentials to be configured by the caller workflow.

## Usage Examples

### Basic Usage

```yaml
name: Validate CloudFormation Template

on:
  push:
    paths:
      - 'cloudformation/**'
  pull_request:
    paths:
      - 'cloudformation/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: cfn-validation-${{ github.run_id }}
          aws-region: us-west-2

      - name: Validate CloudFormation template
        uses: subhamay-bhattacharyya-gha/cfn-validate-action@v1
        with:
          aws-role-arn: ${{ secrets.AWS_ROLE_ARN }}
          cloudformation-dir: cloudformation
          template-file: template.yaml
          aws-region: us-west-2
```

### Multi-Environment Validation

```yaml
name: Validate CloudFormation Templates Across Environments

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    strategy:
      matrix:
        environment: [dev, staging, prod]
        include:
          - environment: dev
            aws-region: us-east-1
            template-dir: infrastructure/dev
          - environment: staging
            aws-region: us-west-2
            template-dir: infrastructure/staging
          - environment: prod
            aws-region: eu-west-1
            template-dir: infrastructure/prod
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: cfn-validation-${{ matrix.environment }}-${{ github.run_id }}
          aws-region: ${{ matrix.aws-region }}

      - name: Validate ${{ matrix.environment }} template
        uses: subhamay-bhattacharyya-gha/cfn-validate-action@v1
        with:
          aws-role-arn: ${{ secrets.AWS_ROLE_ARN }}
          cloudformation-dir: ${{ matrix.template-dir }}
          template-file: template.yaml
          aws-region: ${{ matrix.aws-region }}
```

### Workflow Dispatch with Custom Template

```yaml
name: Validate CloudFormation Template (Manual)

on:
  workflow_dispatch:
    inputs:
      template-name:
        description: Template filename
        required: true
        default: template.yaml
      region:
        description: AWS region
        required: true
        default: us-east-1

jobs:
  validate:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: cfn-validation-${{ github.run_id }}
          aws-region: ${{ github.event.inputs.region }}

      - name: Validate template
        uses: subhamay-bhattacharyya-gha/cfn-validate-action@v1
        with:
          aws-role-arn: ${{ secrets.AWS_ROLE_ARN }}
          cloudformation-dir: templates
          template-file: ${{ github.event.inputs.template-name }}
          aws-region: ${{ github.event.inputs.region }}
```

---

## Project Structure Examples

### Simple Project Structure

```
repository/
├── template.yaml          # Main CloudFormation template
└── .github/
    └── workflows/
        └── validate.yaml  # Validation workflow
```

### Multi-Template Project Structure

```
repository/
├── infrastructure/
│   ├── template.yaml              # Main template
│   └── nested-templates/          # Nested templates directory
│       ├── vpc.yaml              # VPC nested template
│       ├── security-groups.yaml  # Security groups template
│       └── database.yaml         # Database template
└── .github/
    └── workflows/
        └── validate-infrastructure.yaml
```

### Multi-Environment Project Structure

```
repository/
├── environments/
│   ├── dev/
│   │   ├── template.yaml
│   │   └── nested-templates/
│   │       └── dev-specific.yaml
│   ├── staging/
│   │   ├── template.yaml
│   │   └── nested-templates/
│   │       └── staging-specific.yaml
│   └── prod/
│       ├── template.yaml
│       └── nested-templates/
│           └── prod-specific.yaml
└── .github/
    └── workflows/
        └── validate.yaml  # Validates each environment's template
```

---

## AWS IAM Permissions

The AWS IAM role specified in `aws-role-arn` must have the following minimum permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:ValidateTemplate"
      ],
      "Resource": "*"
    }
  ]
}
```

For GitHub Actions OIDC integration, ensure your IAM role has a trust policy similar to:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:subhamay-bhattacharyya-gha/cfn-validate-action:*"
        }
      }
    }
  ]
}
```

---

## Troubleshooting

### Common Validation Errors

#### Template File Not Found
**Error**: `Template file not found: ./template.yaml`

**Solutions**:
- Verify the `cloudformation-dir` and `template-file` inputs are correct
- Check that the template file exists in the specified directory
- Ensure the file has the correct extension (.yaml, .yml, or .json)

#### AWS Authentication Errors
**Error**: `AccessDenied` or `UnauthorizedOperation`

**Solutions**:
- Verify the `aws-role-arn` is correct and exists
- Check that the IAM role has `cloudformation:ValidateTemplate` permission
- Ensure the GitHub Actions OIDC trust policy is properly configured
- Verify the AWS region is correct

#### Template Syntax Errors
**Error**: `ValidationError: Template format error`

**Solutions**:
- Check YAML/JSON syntax using a validator
- Verify all required CloudFormation sections are present
- Ensure resource types and properties are valid
- Check for proper indentation in YAML files

#### Invalid Resource Types
**Error**: `ValidationError: [...] is not a valid CloudFormation resource type`

**Solutions**:
- Verify resource types match the CloudFormation documentation
- Check AWS service availability in your region
- Ensure you're not using deprecated resource types
- Validate against the correct CloudFormation specification version



#### Nested Templates
**Note**: This action validates the main template syntax only. It does not independently validate nested templates referenced within the main template.

**For nested templates**:
- Nested templates must be properly referenced in the main template (e.g., via `AWS::CloudFormation::Stack`)
- Ensure nested template files are accessible and syntactically valid
- Use the action on each nested template separately to validate them individually
- Check that nested template references use correct paths and URLs

### Debugging Tips

1. **Review Step Summary**: Check the GitHub Actions step summary for validation results and error details
2. **Check Validation Output**: Review the `{cloudformation-dir}/validation-output/` directory files:
   - `template-validation.json` for successful validation results
   - `template-errors.log` for validation errors
3. **Enable Debug Logging**: Set `ACTIONS_STEP_DEBUG=true` in repository secrets for verbose debugging output
4. **Test Locally**: Use AWS CLI to test template validation locally before committing:
   ```bash
   aws cloudformation validate-template \
     --template-body file://path/to/template.yaml \
     --region us-east-1 \
     --output json
   ```

### Template Size Limits
CloudFormation enforces a 51.2 KB limit for template body size. If your template approaches this limit:
- Use [CloudFormation module registry](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/modules.html) to modularize templates
- Consider breaking large templates into smaller components with nested stacks
- Use S3 URLs for very large templates (not supported by this action)

---

## Outputs

The action generates validation results and error logs in the `{cloudformation-dir}/validation-output/` directory:

- **template-validation.json**: JSON response from AWS CloudFormation validate-template API containing:
  - Template description and capabilities
  - Parameters and their configurations
  - Template metadata and version information
  
- **template-errors.log**: Detailed error messages if validation fails (only created if validation fails)

These files are available in the GitHub Actions workspace and can be uploaded as artifacts by your workflow if needed.

## GitHub Step Summary

The action automatically generates a markdown summary in the GitHub Actions step summary that displays:
- Validation status (✅ passed or ❌ failed)
- Validation output or error details
- Collapsible sections for detailed inspection

---

## License

MIT
