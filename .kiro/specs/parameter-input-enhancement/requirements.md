# Requirements Document

## Introduction

This feature enhances the CloudFormation Template Validator action to accept CloudFormation parameters directly as input instead of requiring a separate parameters.json file. This provides more flexibility for users who want to pass parameters dynamically from their workflow without creating intermediate files.

## Requirements

### Requirement 1

**User Story:** As a workflow author, I want to pass CloudFormation parameters directly as action input, so that I can avoid creating separate parameter files and have more dynamic parameter handling.

#### Acceptance Criteria

1. WHEN a user provides parameters via the new `parameters` input THEN the action SHALL validate the parameter format
2. WHEN parameters are provided via input THEN the action SHALL use these parameters instead of reading from a file
3. WHEN both `parameters` input and `parameters-file` are provided THEN the action SHALL prioritize the `parameters` input and ignore the file
4. WHEN neither `parameters` input nor `parameters-file` are provided THEN the action SHALL skip parameter validation as before

### Requirement 2

**User Story:** As a workflow author, I want the parameter input to follow CloudFormation's standard format, so that I can easily convert existing parameter files to input format.

#### Acceptance Criteria

1. WHEN parameters are provided THEN they SHALL be in the format: `[{ParameterName:string,ParameterValue:string}]`
2. WHEN parameter format is invalid THEN the action SHALL provide clear error messages with examples
3. WHEN parameters contain special characters THEN the action SHALL handle them correctly
4. WHEN parameters are empty array THEN the action SHALL skip parameter validation

### Requirement 3

**User Story:** As a workflow author, I want backward compatibility with existing parameter files, so that I can migrate gradually without breaking existing workflows.

#### Acceptance Criteria

1. WHEN only `parameters-file` is provided THEN the action SHALL work exactly as before
2. WHEN `parameters-file` doesn't exist and no `parameters` input is provided THEN the action SHALL skip parameter validation
3. WHEN migrating from file to input THEN existing validation logic SHALL remain the same
4. WHEN using the new parameter input THEN all existing outputs SHALL remain unchanged

### Requirement 4

**User Story:** As a workflow author, I want clear documentation and examples, so that I can understand how to use the new parameter input feature.

#### Acceptance Criteria

1. WHEN reading documentation THEN examples SHALL show both old and new parameter methods
2. WHEN using the new feature THEN error messages SHALL be clear and actionable
3. WHEN parameters are invalid THEN the action SHALL show the expected format with examples
4. WHEN debugging THEN the action SHALL log which parameter method is being used