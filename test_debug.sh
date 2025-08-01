#!/bin/bash
set -euo pipefail

echo "Debug test starting..."

# Create test directory
TEST_DIR="test-validation-comprehensive"
mkdir -p "${TEST_DIR}/validation-output/parameters"

# Test the parse function
parse_parameters_input() {
  local parameters_input="$1"
  local temp_file="${TEST_DIR}/validation-output/parameters/input-parameters.json"
  
  echo "Parsing input: $parameters_input"
  
  if [[ -z "${parameters_input}" ]]; then
    echo "Input is empty"
    return 1
  fi
  
  if ! echo "${parameters_input}" | jq empty 2> "${TEST_DIR}/validation-output/parameters/input-json-errors.log"; then
    echo "JSON validation failed"
    return 1
  fi
  
  echo "JSON is valid"
  echo "${parameters_input}" > "${temp_file}"
  echo "Saved to temp file"
  
  if ! jq -e 'type == "array"' "${temp_file}" > /dev/null 2>&1; then
    echo "Not an array"
    return 1
  fi
  
  echo "Is array"
  echo "${temp_file}"
  return 0
}

echo "Testing basic input..."
VALID_INPUT='[{"ParameterName": "Environment", "ParameterValue": "production"}]'

if parse_parameters_input "${VALID_INPUT}"; then
  echo "SUCCESS: Parse function worked"
else
  echo "FAILED: Parse function failed"
fi

echo "Testing multiple parameters..."
MULTI_INPUT='[{"ParameterName": "Environment", "ParameterValue": "production"}, {"ParameterName": "InstanceType", "ParameterValue": "t3.micro"}]'

if parse_parameters_input "${MULTI_INPUT}"; then
  echo "SUCCESS: Multi-parameter test worked"
else
  echo "FAILED: Multi-parameter test failed"
fi

# Cleanup
rm -rf "${TEST_DIR}"

echo "Debug test completed successfully"