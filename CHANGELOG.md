
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### BREAKING CHANGES

- **parameters**: Removed `parameters-file` input in favor of direct JSON parameter input
  - The `parameters-file` input has been completely removed
  - Parameters must now be passed directly via the `parameters` input as JSON array
  - Format: `[{"ParameterName": "string", "ParameterValue": "string"}]`
  - Enables dynamic parameter handling without creating intermediate files

- **action**: Removed built-in repository checkout and AWS credentials configuration steps
  - The action no longer includes `actions/checkout@v4` step
  - The action no longer includes `aws-actions/configure-aws-credentials@v4` step
  - Caller workflows must now include these steps before calling this action
  - This change provides more flexibility for users to configure checkout and AWS credentials according to their specific needs

### Migration Guide

If you're upgrading from a previous version, you need to add these steps to your workflow before calling this action:

```yaml
steps:
  - name: Checkout repository
    uses: actions/checkout@v4

  - name: Configure AWS credentials
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
      role-session-name: cloudformation-validation-${{ github.run_id }}
      aws-region: your-aws-region

  - name: Validate CloudFormation Templates
    uses: subhamay-bhattacharyya-gha/cfn-validate-action@v1
    with:
      # your existing configuration
```

### Parameters Input Migration

The action now requires CloudFormation parameters to be passed directly as JSON input instead of using parameter files.

#### New Usage

```yaml
- name: Validate CloudFormation Templates
  uses: subhamay-bhattacharyya-gha/cfn-validate-action@v1
  with:
    template-path: 'cloudformation/template.yaml'
    parameters: |
      [
        {
          "ParameterName": "Environment",
          "ParameterValue": "production"
        },
        {
          "ParameterName": "BucketName", 
          "ParameterValue": "my-app-bucket-${{ github.run_id }}"
        }
      ]
```

#### Migration from File-Based Parameters

If you were previously using `parameters-file`, you need to convert your parameter file content to the `parameters` input:

**Before (no longer supported):**
```yaml
- name: Validate CloudFormation Templates
  uses: subhamay-bhattacharyya-gha/cfn-validate-action@v1
  with:
    template-path: 'cloudformation/template.yaml'
    parameters-file: 'cloudformation/parameters.json'
```

**After (required):**
```yaml
- name: Validate CloudFormation Templates
  uses: subhamay-bhattacharyya-gha/cfn-validate-action@v1
  with:
    template-path: 'cloudformation/template.yaml'
    parameters: |
      [
        {
          "ParameterName": "Environment",
          "ParameterValue": "production"
        },
        {
          "ParameterName": "InstanceType",
          "ParameterValue": "t3.micro"
        }
      ]
```

#### Parameter Format

The `parameters` input expects a JSON array of objects with the following structure:

```json
[
  {
    "ParameterName": "YourParameterName",
    "ParameterValue": "YourParameterValue"
  }
]
```

#### Breaking Changes Impact

- The `parameters-file` input has been completely removed
- Workflows using `parameters-file` will fail until migrated to use `parameters` input
- Parameter file references in documentation and examples are no longer valid
- All parameter validation now occurs on the JSON input format only
