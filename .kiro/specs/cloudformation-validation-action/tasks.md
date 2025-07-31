# Implementation Plan

- [x] 1. Update action.yaml with CloudFormation validation inputs and metadata
  - Replace template action.yaml with CloudFormation-specific inputs (cloudformation-dir, template-file, parameters-file, aws-region, aws-role-arn)
  - Define action name, description, and branding for CloudFormation validation
  - Set up composite action structure with proper input definitions and defaults
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 2. Implement repository checkout and AWS credentials configuration steps
  - Add checkout step using actions/checkout@v4 for repository access
  - Add AWS credentials configuration step using aws-actions/configure-aws-credentials@v4
  - Configure role assumption with session naming and region setup
  - _Requirements: 6.1, 6.2, 6.3_

- [x] 3. Implement main CloudFormation template validation step
  - Create validation step that checks template file existence and provides directory listing on failure
  - Implement AWS CLI template validation with proper error handling and output capture
  - Add success path logic to display template capabilities and parameters using jq
  - Add failure path logic to capture and display detailed validation errors
  - Set GitHub output variables for validation results
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 4. Implement nested templates validation step
  - Create conditional step that runs only after main template validation succeeds
  - Add logic to check for nested-templates directory existence
  - Implement find command to locate all YAML and JSON files in nested directory
  - Create validation loop for each nested template with individual error handling
  - Add logic to track overall nested validation status and set appropriate outputs
  - Handle case where no nested templates directory exists (skip and report)
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 5. Implement parameters file validation step
  - Create conditional step that runs only after main template validation succeeds
  - Add logic to check parameters file existence and skip if not found
  - Implement JSON syntax validation using jq with error capture
  - Add structure validation to ensure array format with ParameterKey/ParameterValue objects
  - Display parameter keys and values on successful validation
  - Set appropriate GitHub output variables for parameters validation results
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 6. Implement validation artifacts upload step
  - Add step using actions/upload-artifact@v4 that runs always (regardless of success/failure)
  - Configure artifact upload to include all validation output files (JSON and log files)
  - Set artifact retention period to 30 days as specified in requirements
  - Ensure artifact naming follows consistent pattern for easy identification
  - _Requirements: 4.1, 4.3_

- [x] 7. Implement validation summary generation step
  - Create step that runs always to generate GitHub step summary
  - Add logic to read validation results from previous steps' outputs
  - Generate markdown summary with status indicators (✅, ❌, ⏭️) for each validation type
  - Include template and parameters file paths in summary
  - Format summary with proper markdown structure for GitHub display
  - _Requirements: 4.2, 4.4_

- [x] 8. Add comprehensive error handling and logging throughout all steps
  - Implement proper error message formatting using GitHub Actions error annotations
  - Add detailed logging for debugging purposes in each validation step
  - Ensure all AWS API errors are properly captured and displayed
  - Add timeout handling and retry logic where appropriate for AWS API calls
  - _Requirements: 6.4, 4.4_

- [x] 9. Update README.md with action usage documentation
  - Create comprehensive documentation explaining action purpose and features
  - Add usage examples showing how to integrate the action in workflows
  - Document all input parameters with descriptions, requirements, and default values
  - Document all output parameters and their possible values
  - Include troubleshooting section for common validation errors
  - Add examples for different CloudFormation project structures
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 10. Create test workflow for action validation
  - Create .github/workflows/test.yml to test the action functionality
  - Add test cases for valid CloudFormation templates with successful validation
  - Add test cases for invalid templates to verify error handling
  - Include tests for nested templates and parameters file validation scenarios
  - Set up test fixtures with sample CloudFormation templates and parameters
  - Configure test workflow to run on pull requests and pushes
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 3.1, 3.2_