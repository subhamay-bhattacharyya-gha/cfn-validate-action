
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
