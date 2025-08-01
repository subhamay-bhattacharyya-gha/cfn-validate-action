
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- **parameters**: New `parameters` input field for passing CloudFormation parameters directly as JSON array
  - Accepts parameters in the format: `[{"ParameterName": "string", "ParameterValue": "string"}]`
  - Takes precedence over `parameters-file` when both are provided
  - Maintains full backward compatibility with existing `parameters-file` input
  - Enables dynamic parameter handling without creating intermediate files

### BREAKING CHANGES

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

### New Parameters Input Feature

The action now supports passing CloudFormation parameters directly as input, providing more flexibility for dynamic parameter handling.

#### Usage Examples

**Using the new `parameters` input:**

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

**Traditional file-based approach (still supported):**

```yaml
- name: Validate CloudFormation Templates
  uses: subhamay-bhattacharyya-gha/cfn-validate-action@v1
  with:
    template-path: 'cloudformation/template.yaml'
    parameters-file: 'cloudformation/parameters.json'
```

#### Migration Path

You can migrate from file-based to input-based parameters gradually:

1. **Current file-based approach** - No changes needed, continues to work as before
2. **Mixed approach** - Use `parameters` input for dynamic values, `parameters-file` for static ones (parameters input takes precedence)
3. **Full migration** - Convert all parameters to the new input format

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

#### Backward Compatibility

- Existing workflows using `parameters-file` continue to work unchanged
- When both `parameters` and `parameters-file` are provided, `parameters` takes precedence
- When neither is provided, parameter validation is skipped (same as before)
- All existing outputs and error handling remain the same
