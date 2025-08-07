# 1.0.0 (2025-08-07)


* feat!: remove built-in checkout and AWS credentials steps ([44338c4](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/44338c43d16908ee3c377b92eb768062b99160d5))


### Bug Fixes

* add aws cloudformation validate-template ([be28a8d](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/be28a8dcc51a4b9cf04698357537c276105ea284))
* cleanup the code ([7a537ef](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/7a537ef578f9273513766a90c38e9204a7811ce9))
* correct bash script syntax ([7a6aaf2](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/7a6aaf25316559921b6ca14a26eca10963515325))
* correct heredoc indentation in action.yaml ([27f16ef](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/27f16ef5d560f37798c7a6e07dae1f77eb44b187))
* correct template path construction and remove empty path field ([6a0e4c2](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/6a0e4c2bcf4134138575f1cd71d5a4392bb28b5c))
* corrected syntax in validation ([03d8a24](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/03d8a24eab1f3e267319399753dbc16ad29a654a))
* fix the template path ([c3c6ad6](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/c3c6ad6cc06182315e72cf0b8a97424253dedc6b))
* syntax correction ([8f85c87](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/8f85c8788255c2ddeb2abf725a262d18a9286c7d))
* typo error in the validate step ([71163f8](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/71163f823e57fd656282232b50c86205819f6d95))
* use github.workspace for template path resolution ([c927534](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/c92753434df5c71188f48dc57c47cb748248817a))


### Features

* add a step to print validation summary ([0ace8e9](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/0ace8e93ac70f58a25af6e1f312876ea964984fb))
* add comprehensive test workflow for CloudFormation validation action ([3acd5c5](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/3acd5c526215a5d838efe3db24546d7643a2d33e))
* add the step to validate the cloudformation template ([cd6bdb2](https://github.com/subhamay-bhattacharyya-gha/cfn-validate-action/commit/cd6bdb27f48998ede555b709a1b8863771a72ae7))


### BREAKING CHANGES

* The action no longer includes repository checkout and AWS credentials configuration steps. Caller workflows must now include these steps before using this action.

- Remove actions/checkout@v4 step from composite action
- Remove aws-actions/configure-aws-credentials@v4 step from composite action
- Update action description to clarify prerequisites
- Add Prerequisites section to README with required setup steps
- Update all usage examples to include required checkout and credentials steps
- Update repository references from placeholder to actual repo name
- Fix YAML indentation issues in heredoc blocks
- Update author field to match package.json
- Add migration guide to CHANGELOG with breaking change documentation
- Update test workflows to include required AWS credentials configuration

This change provides more flexibility for users to configure checkout and AWS credentials according to their specific needs while focusing the action on its core CloudFormation validation functionality.

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
