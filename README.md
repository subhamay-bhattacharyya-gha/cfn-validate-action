# CloudFormation Template Validator

![Built with Kiro](https://img.shields.io/badge/Built%20with-Kiro-blue?style=flat&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTEyIDJMMTMuMDkgOC4yNkwyMCA5TDEzLjA5IDE1Ljc0TDEyIDIyTDEwLjkxIDE1Ljc0TDQgOUwxMC45MSA4LjI2TDEyIDJaIiBmaWxsPSJ3aGl0ZSIvPgo8L3N2Zz4K)&nbsp;![GitHub Action](https://img.shields.io/badge/GitHub-Action-blue?logo=github)&nbsp;![Release](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/actions/workflows/release.yaml/badge.svg)&nbsp;![Commit Activity](https://img.shields.io/github/commit-activity/t/subhamay-bhattacharyya-gha/cfn-validate-action)&nbsp;![Bash](https://img.shields.io/badge/Language-Bash-green?logo=gnubash)&nbsp;![CloudFormation](https://img.shields.io/badge/AWS-CloudFormation-orange?logo=amazonaws)&nbsp;![Last Commit](https://img.shields.io/github/last-commit/subhamay-bhattacharyya-gha/cfn-validate-action)&nbsp;![Release Date](https://img.shields.io/github/release-date/subhamay-bhattacharyya-gha/cfn-validate-action)&nbsp;![Repo Size](https://img.shields.io/github/repo-size/subhamay-bhattacharyya-gha/cfn-validate-action)&nbsp;![File Count](https://img.shields.io/github/directory-file-count/subhamay-bhattacharyya-gha/cfn-validate-action)&nbsp;![Issues](https://img.shields.io/github/issues/subhamay-bhattacharyya-gha/cfn-validate-action)&nbsp;![Top Language](https://img.shields.io/github/languages/top/subhamay-bhattacharyya-gha/cfn-validate-action)&nbsp;![Custom Endpoint](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bsubhamay/0bcfd7d53cb4036029aa32cb81aac635/raw/cfn-validate-action.json?)

A comprehensive GitHub Action that validates CloudFormation templates, nested templates, and parameters files with comprehensive error reporting and artifact generation. Requires repository checkout and AWS credentials to be configured by caller workflow.

> **Note**: This action requires the caller workflow to handle repository checkout and AWS credentials configuration. See [Prerequisites](#prerequisites) for details.

## Features

- **Main Template Validation**: Validates CloudFormation template syntax using AWS CloudFormation API
- **Nested Templates Support**: Automatically discovers and validates templates in `nested-templates` directory
- **Parameters File Validation**: Validates JSON structure and syntax of CloudFormation parameters files
- **Comprehensive Error Reporting**: Detailed error messages with categorization and troubleshooting suggestions
- **Validation Artifacts**: Uploads validation results and logs as GitHub artifacts for debugging
- **Step Summary**: Generates markdown summary with validation status for each component
- **Retry Logic**: Built-in retry mechanism for transient AWS API failures
- **Multiple File Formats**: Supports YAML (.yaml, .yml) and JSON (.json) template formats

---

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `cloudformation-dir` | Directory containing CloudFormation templates | No | `.` |
| `template-file` | Main CloudFormation template filename | No | `template.yaml` |
| `parameters-file` | Parameters file name | No | `parameters.json` |
| `aws-region` | AWS region for validation | No | `us-east-1` |
| `aws-role-arn` | AWS IAM role ARN for authentication | **Yes** | — |
| `github-token` | GitHub token for artifact upload | No | `${{ github.token }}` |

## Outputs

| Name | Description | Possible Values |
|------|-------------|-----------------|
| `validation-result` | Overall validation result | `success`, `failure` |
| `main-template-result` | Main template validation result | `success`, `failure` |
| `nested-templates-result` | Nested templates validation result | `success`, `failure`, `skipped` |
| `parameters-result` | Parameters file validation result | `success`, `failure`, `skipped` |

---

## Prerequisites

Before using this action, ensure your workflow includes:

1. **Repository Checkout**: Use `actions/checkout@v4` to checkout your repository
2. **AWS Credentials Configuration**: Use `aws-actions/configure-aws-credentials@v4` to configure AWS credentials

This action focuses solely on CloudFormation validation and expects the repository to be checked out and AWS credentials to be configured by the caller workflow.

## Usage Examples

### Basic Usage

```yaml
name: CloudFormation Validation

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
          role-session-name: cloudformation-validation-${{ github.run_id }}
          aws-region: us-west-2

      - name: Validate CloudFormation Templates
        uses: subhamay-bhattacharyya-gha/cfn-validate-action@main
        with:
          aws-role-arn: ${{ secrets.AWS_ROLE_ARN }}
          cloudformation-dir: 'cloudformation'
          template-file: 'main-template.yaml'
          parameters-file: 'parameters.json'
          aws-region: 'us-west-2'
```

### Advanced Usage with Multiple Environments

```yaml
name: Multi-Environment CloudFormation Validation

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
          role-session-name: cloudformation-validation-${{ matrix.environment }}-${{ github.run_id }}
          aws-region: ${{ matrix.aws-region }}

      - name: Validate ${{ matrix.environment }} Templates
        uses: subhamay-bhattacharyya-gha/cfn-validate-action@main
        with:
          aws-role-arn: ${{ secrets.AWS_ROLE_ARN }}
          cloudformation-dir: ${{ matrix.template-dir }}
          template-file: 'template.yaml'
          parameters-file: '${{ matrix.environment }}-parameters.json'
          aws-region: ${{ matrix.aws-region }}
```

### Usage with Custom File Names

```yaml
name: Custom CloudFormation Validation

on:
  workflow_dispatch:
    inputs:
      template-name:
        description: 'Template file name'
        required: true
        default: 'infrastructure.yaml'

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
          role-session-name: cloudformation-validation-${{ github.run_id }}
          aws-region: ap-southeast-2

      - name: Validate Custom Template
        uses: subhamay-bhattacharyya-gha/cfn-validate-action@main
        with:
          aws-role-arn: ${{ secrets.AWS_ROLE_ARN }}
          cloudformation-dir: 'templates'
          template-file: ${{ github.event.inputs.template-name }}
          parameters-file: 'custom-params.json'
          aws-region: 'ap-southeast-2'
```

---

## Project Structure Examples

### Simple Project Structure

```
repository/
├── template.yaml          # Main CloudFormation template
├── parameters.json        # Parameters file
└── .github/
    └── workflows/
        └── validate.yml   # Validation workflow
```

### Complex Project Structure

```
repository/
├── infrastructure/
│   ├── template.yaml              # Main template
│   ├── parameters.json            # Parameters
│   ├── nested-templates/          # Nested templates directory
│   │   ├── vpc.yaml              # VPC nested template
│   │   ├── security-groups.yaml  # Security groups template
│   │   └── database.yaml         # Database template
│   └── environments/
│       ├── dev-parameters.json
│       ├── staging-parameters.json
│       └── prod-parameters.json
└── .github/
    └── workflows/
        └── validate-infrastructure.yml
```

### Multi-Environment Project Structure

```
repository/
├── environments/
│   ├── dev/
│   │   ├── template.yaml
│   │   ├── parameters.json
│   │   └── nested-templates/
│   │       └── dev-specific.yaml
│   ├── staging/
│   │   ├── template.yaml
│   │   ├── parameters.json
│   │   └── nested-templates/
│   │       └── staging-specific.yaml
│   └── prod/
│       ├── template.yaml
│       ├── parameters.json
│       └── nested-templates/
│           └── prod-specific.yaml
└── .github/
    └── workflows/
        └── validate-all-environments.yml
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

#### Parameters File Errors
**Error**: `Invalid JSON syntax` or `Invalid structure`

**Solutions**:
- Validate JSON syntax using a JSON validator
- Ensure parameters file follows the correct structure:
  ```json
  [
    {
      "ParameterKey": "string",
      "ParameterValue": "string"
    }
  ]
  ```
- Check that all parameter keys match those defined in the template

#### Nested Templates Issues
**Error**: Individual nested template validation failures

**Solutions**:
- Ensure all files in `nested-templates/` directory are valid CloudFormation templates
- Check that nested templates don't reference resources that don't exist
- Verify nested templates use supported CloudFormation features
- Remove any non-template files from the `nested-templates/` directory

### Rate Limiting
If you encounter AWS API rate limiting:
- The action includes automatic retry logic with exponential backoff
- Consider spacing out validation runs if running frequently
- Check AWS CloudFormation service limits for your account

### Large Template Files
For large templates or many nested templates:
- The action has a 5-minute timeout per template validation
- Consider breaking down very large templates into smaller components
- Use the artifacts feature to debug validation issues with large templates

### Debugging Tips

1. **Check Artifacts**: Download validation artifacts from the GitHub Actions run for detailed logs
2. **Review Step Summary**: The action generates a comprehensive markdown summary
3. **Enable Debug Logging**: Set `ACTIONS_STEP_DEBUG=true` in repository secrets for verbose logging
4. **Test Locally**: Use AWS CLI locally to test template validation before committing

---

## Artifacts

The action automatically uploads the following artifacts for debugging:

- **Validation Results**: JSON files containing AWS CloudFormation validation responses
- **Error Logs**: Detailed error messages and stack traces
- **Template Analysis**: Information about template capabilities, parameters, and metadata

Artifacts are retained for 30 days and can be downloaded from the GitHub Actions run page.

---

## License

MIT
