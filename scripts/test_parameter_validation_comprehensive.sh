#!/bin/bash

# Comprehensive test script for parameter validation functionality
# Tests the new parameter input feature with backward compatibility
set -euo pipefail

echo "🧪 Running comprehensive parameter validation tests..."
echo "======================================================"

# Create test directory structure
TEST_DIR="test-validation-comprehensive"
mkdir -p "${TEST_DIR}/cloudformation"
mkdir -p "${TEST_DIR}/validation-output/parameters"

# Create test parameter files
cat > "${TEST_DIR}/cloudformation/valid-parameters.json" << 'EOF'
[
  {
    "ParameterKey": "BucketName",
    "ParameterValue": "test-bucket-12345"
  },
  {
    "ParameterKey": "Environment", 
    "ParameterValue": "test"
  }
]
EOF

cat > "${TEST_DIR}/cloudformation/invalid-parameters.json" << 'EOF'
{
  "InvalidStructure": "This should be an array"
}
EOF

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test result tracking
test_result() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
  
  ((TOTAL_TESTS++))
  
  if [[ "${expected}" == "${actual}" ]]; then
    echo "✅ PASS: ${test_name}"
    ((PASSED_TESTS++))
  else
    echo "❌ FAIL: ${test_name}"
    echo "   Expected: ${expected}"
    echo "   Actual: ${actual}"
    ((FAILED_TESTS++))
  fi
}

# Mock functions extracted from action.yaml for testing
parse_parameters_input() {
  local parameters_input="$1"
  local temp_file="${TEST_DIR}/validation-output/parameters/input-parameters.json"
  
  # Check if input is empty
  if [[ -z "${parameters_input}" ]]; then
    return 1
  fi
  
  # Validate JSON syntax
  if ! echo "${parameters_input}" | jq empty 2> "${TEST_DIR}/validation-output/parameters/input-json-errors.log"; then
    return 1
  fi
  
  # Save input to temporary file
  echo "${parameters_input}" > "${temp_file}"
  
  # Validate structure - ensure it's an array
  if ! jq -e 'type == "array"' "${temp_file}" > /dev/null 2>&1; then
    return 1
  fi
  
  # Check array length
  local param_count=$(jq 'length' "${temp_file}")
  if [[ "${param_count}" -eq 0 ]]; then
    echo "${temp_file}"
    return 0
  fi
  
  # Validate each parameter object structure
  for i in $(seq 0 $((param_count - 1))); do
    local param=$(jq -r ".[$i]" "${temp_file}")
    
    # Check if it's an object
    if ! echo "${param}" | jq -e 'type == "object"' > /dev/null 2>&1; then
      return 1
    fi
    
    # Check required fields
    if ! echo "${param}" | jq -e 'has("ParameterName") and has("ParameterValue")' > /dev/null 2>&1; then
      return 1
    fi
    
    # Check field types and values
    local param_name=$(echo "${param}" | jq -r '.ParameterName // ""')
    local param_value=$(echo "${param}" | jq -r '.ParameterValue // ""')
    
    if [[ -z "${param_name}" ]] || ! echo "${param}" | jq -e '.ParameterName | type == "string"' > /dev/null 2>&1; then
      return 1
    fi
    
    if ! echo "${param}" | jq -e '.ParameterValue | type == "string"' > /dev/null 2>&1; then
      return 1
    fi
  done
  
  echo "${temp_file}"
  return 0
}

determine_parameter_source() {
  local parameters_input="$1"
  local parameters_file="$2"
  local parameters_path="$3"
  
  # Priority: input > file > skip
  if [[ -n "${parameters_input}" ]]; then
    local temp_file
    if temp_file=$(parse_parameters_input "${parameters_input}"); then
      echo "input|${temp_file}"
      return 0
    else
      return 1
    fi
  elif [[ -f "${parameters_path}" ]]; then
    echo "file|${parameters_path}"
    return 0
  else
    echo "skip|"
    return 0
  fi
}

echo ""
echo "🧪 Test Suite 1: Valid Parameter Input Formats"
echo "=============================================="

# Test 1.1: Basic valid input
echo ""
echo "Test 1.1: Basic valid parameter input"
VALID_INPUT='[{"ParameterName": "Environment", "ParameterValue": "production"}]'
if parse_parameters_input "${VALID_INPUT}" > /dev/null 2>&1; then
  test_result "Basic valid input" "success" "success"
else
  test_result "Basic valid input" "success" "failure"
fi

# Test 1.2: Multiple parameters
echo ""
echo "Test 1.2: Multiple parameters input"
MULTI_INPUT='[{"ParameterName": "Environment", "ParameterValue": "production"}, {"ParameterName": "InstanceType", "ParameterValue": "t3.micro"}]'
if parse_parameters_input "${MULTI_INPUT}" > /dev/null 2>&1; then
  test_result "Multiple parameters" "success" "success"
else
  test_result "Multiple parameters" "success" "failure"
fi

# Test 1.3: Empty array (should be valid)
echo ""
echo "Test 1.3: Empty array input"
EMPTY_INPUT='[]'
if parse_parameters_input "${EMPTY_INPUT}" > /dev/null 2>&1; then
  test_result "Empty array input" "success" "success"
else
  test_result "Empty array input" "success" "failure"
fi

# Test 1.4: Parameters with special characters
echo ""
echo "Test 1.4: Parameters with special characters"
SPECIAL_INPUT='[{"ParameterName": "DatabaseURL", "ParameterValue": "mysql://user:pass@host:3306/db?ssl=true"}]'
if parse_parameters_input "${SPECIAL_INPUT}" > /dev/null 2>&1; then
  test_result "Special characters in values" "success" "success"
else
  test_result "Special characters in values" "success" "failure"
fi

echo ""
echo "🧪 Test Suite 2: Invalid Parameter Input Scenarios"
echo "================================================="

# Test 2.1: Invalid JSON syntax
echo ""
echo "Test 2.1: Invalid JSON syntax"
INVALID_JSON='[{"ParameterName": "Environment", "ParameterValue": "production"'
if parse_parameters_input "${INVALID_JSON}" > /dev/null 2>&1; then
  test_result "Invalid JSON syntax" "failure" "success"
else
  test_result "Invalid JSON syntax" "failure" "failure"
fi

# Test 2.2: Wrong structure (not array)
echo ""
echo "Test 2.2: Non-array structure"
NON_ARRAY='{"ParameterName": "Environment", "ParameterValue": "production"}'
if parse_parameters_input "${NON_ARRAY}" > /dev/null 2>&1; then
  test_result "Non-array structure" "failure" "success"
else
  test_result "Non-array structure" "failure" "failure"
fi

# Test 2.3: Missing ParameterName
echo ""
echo "Test 2.3: Missing ParameterName field"
MISSING_NAME='[{"ParameterValue": "production"}]'
if parse_parameters_input "${MISSING_NAME}" > /dev/null 2>&1; then
  test_result "Missing ParameterName" "failure" "success"
else
  test_result "Missing ParameterName" "failure" "failure"
fi

# Test 2.4: Missing ParameterValue
echo ""
echo "Test 2.4: Missing ParameterValue field"
MISSING_VALUE='[{"ParameterName": "Environment"}]'
if parse_parameters_input "${MISSING_VALUE}" > /dev/null 2>&1; then
  test_result "Missing ParameterValue" "failure" "success"
else
  test_result "Missing ParameterValue" "failure" "failure"
fi

# Test 2.5: Empty ParameterName
echo ""
echo "Test 2.5: Empty ParameterName"
EMPTY_NAME='[{"ParameterName": "", "ParameterValue": "production"}]'
if parse_parameters_input "${EMPTY_NAME}" > /dev/null 2>&1; then
  test_result "Empty ParameterName" "failure" "success"
else
  test_result "Empty ParameterName" "failure" "failure"
fi

# Test 2.6: Wrong field types
echo ""
echo "Test 2.6: Non-string field types"
WRONG_TYPES='[{"ParameterName": 123, "ParameterValue": true}]'
if parse_parameters_input "${WRONG_TYPES}" > /dev/null 2>&1; then
  test_result "Non-string field types" "failure" "success"
else
  test_result "Non-string field types" "failure" "failure"
fi

echo ""
echo "🧪 Test Suite 3: Priority Logic Tests"
echo "===================================="

# Test 3.1: Input takes precedence over file
echo ""
echo "Test 3.1: Input takes precedence over file"
PARAMETERS_INPUT='[{"ParameterName": "InputParam", "ParameterValue": "InputValue"}]'
PARAMETERS_FILE="valid-parameters.json"
PARAMETERS_PATH="${TEST_DIR}/cloudformation/valid-parameters.json"

if RESULT=$(determine_parameter_source "${PARAMETERS_INPUT}" "${PARAMETERS_FILE}" "${PARAMETERS_PATH}"); then
  SOURCE=$(echo "${RESULT}" | cut -d'|' -f1)
  test_result "Input precedence over file" "input" "${SOURCE}"
else
  test_result "Input precedence over file" "input" "error"
fi

# Test 3.2: File fallback when no input
echo ""
echo "Test 3.2: File fallback when no input"
PARAMETERS_INPUT=""
PARAMETERS_FILE="valid-parameters.json"
PARAMETERS_PATH="${TEST_DIR}/cloudformation/valid-parameters.json"

if RESULT=$(determine_parameter_source "${PARAMETERS_INPUT}" "${PARAMETERS_FILE}" "${PARAMETERS_PATH}"); then
  SOURCE=$(echo "${RESULT}" | cut -d'|' -f1)
  test_result "File fallback" "file" "${SOURCE}"
else
  test_result "File fallback" "file" "error"
fi

# Test 3.3: Skip when neither available
echo ""
echo "Test 3.3: Skip when neither input nor file available"
PARAMETERS_INPUT=""
PARAMETERS_FILE="nonexistent.json"
PARAMETERS_PATH="${TEST_DIR}/cloudformation/nonexistent.json"

if RESULT=$(determine_parameter_source "${PARAMETERS_INPUT}" "${PARAMETERS_FILE}" "${PARAMETERS_PATH}"); then
  SOURCE=$(echo "${RESULT}" | cut -d'|' -f1)
  test_result "Skip when no parameters" "skip" "${SOURCE}"
else
  test_result "Skip when no parameters" "skip" "error"
fi

# Test 3.4: Invalid input falls back to file
echo ""
echo "Test 3.4: Invalid input with valid file available"
PARAMETERS_INPUT='invalid json'
PARAMETERS_FILE="valid-parameters.json"
PARAMETERS_PATH="${TEST_DIR}/cloudformation/valid-parameters.json"

if RESULT=$(determine_parameter_source "${PARAMETERS_INPUT}" "${PARAMETERS_FILE}" "${PARAMETERS_PATH}"); then
  test_result "Invalid input with file" "input" "unexpected_success"
else
  test_result "Invalid input handling" "failure" "failure"
fi

echo ""
echo "🧪 Test Suite 4: Backward Compatibility Tests"
echo "============================================="

# Test 4.1: Existing file-based workflow (no input provided)
echo ""
echo "Test 4.1: Traditional file-based parameters"
PARAMETERS_INPUT=""
PARAMETERS_FILE="valid-parameters.json"
PARAMETERS_PATH="${TEST_DIR}/cloudformation/valid-parameters.json"

if RESULT=$(determine_parameter_source "${PARAMETERS_INPUT}" "${PARAMETERS_FILE}" "${PARAMETERS_PATH}"); then
  SOURCE=$(echo "${RESULT}" | cut -d'|' -f1)
  DATA_FILE=$(echo "${RESULT}" | cut -d'|' -f2)
  if [[ "${SOURCE}" == "file" ]] && [[ "${DATA_FILE}" == "${PARAMETERS_PATH}" ]]; then
    test_result "Traditional file-based workflow" "success" "success"
  else
    test_result "Traditional file-based workflow" "success" "failure"
  fi
else
  test_result "Traditional file-based workflow" "success" "failure"
fi

# Test 4.2: No parameters scenario (existing behavior)
echo ""
echo "Test 4.2: No parameters provided (skip validation)"
PARAMETERS_INPUT=""
PARAMETERS_FILE="parameters.json"
PARAMETERS_PATH="${TEST_DIR}/cloudformation/nonexistent.json"

if RESULT=$(determine_parameter_source "${PARAMETERS_INPUT}" "${PARAMETERS_FILE}" "${PARAMETERS_PATH}"); then
  SOURCE=$(echo "${RESULT}" | cut -d'|' -f1)
  if [[ "${SOURCE}" == "skip" ]]; then
    test_result "No parameters skip behavior" "success" "success"
  else
    test_result "No parameters skip behavior" "success" "failure"
  fi
else
  test_result "No parameters skip behavior" "success" "failure"
fi

# Test 4.3: File format compatibility (ParameterKey vs ParameterName)
echo ""
echo "Test 4.3: File format uses ParameterKey, input uses ParameterName"
# This test verifies that the existing file format (ParameterKey) is different from input format (ParameterName)
if [[ -f "${TEST_DIR}/cloudformation/valid-parameters.json" ]]; then
  FILE_FORMAT=$(jq -r '.[0] | keys[]' "${TEST_DIR}/cloudformation/valid-parameters.json" | grep "Parameter" | head -1)
  if [[ "${FILE_FORMAT}" == "ParameterKey" ]]; then
    test_result "File format uses ParameterKey" "success" "success"
  else
    test_result "File format uses ParameterKey" "success" "failure"
  fi
else
  test_result "File format uses ParameterKey" "success" "failure"
fi

echo ""
echo "🧪 Test Suite 5: Edge Cases and Error Handling"
echo "=============================================="

# Test 5.1: Very large parameter values
echo ""
echo "Test 5.1: Large parameter values"
LARGE_VALUE=$(printf 'A%.0s' {1..1000})  # 1000 character string
LARGE_INPUT="[{\"ParameterName\": \"LargeParam\", \"ParameterValue\": \"${LARGE_VALUE}\"}]"
if parse_parameters_input "${LARGE_INPUT}" > /dev/null 2>&1; then
  test_result "Large parameter values" "success" "success"
else
  test_result "Large parameter values" "success" "failure"
fi

# Test 5.2: Unicode characters in parameters
echo ""
echo "Test 5.2: Unicode characters in parameters"
UNICODE_INPUT='[{"ParameterName": "UnicodeParam", "ParameterValue": "测试值-🚀-émojis"}]'
if parse_parameters_input "${UNICODE_INPUT}" > /dev/null 2>&1; then
  test_result "Unicode characters" "success" "success"
else
  test_result "Unicode characters" "success" "failure"
fi

# Test 5.3: Whitespace handling
echo ""
echo "Test 5.3: Whitespace in parameter names and values"
WHITESPACE_INPUT='[{"ParameterName": "  SpacedParam  ", "ParameterValue": "  spaced value  "}]'
if parse_parameters_input "${WHITESPACE_INPUT}" > /dev/null 2>&1; then
  test_result "Whitespace handling" "success" "success"
else
  test_result "Whitespace handling" "success" "failure"
fi

# Test 5.4: Duplicate parameter names
echo ""
echo "Test 5.4: Duplicate parameter names (should be valid but noted)"
DUPLICATE_INPUT='[{"ParameterName": "DuplicateParam", "ParameterValue": "value1"}, {"ParameterName": "DuplicateParam", "ParameterValue": "value2"}]'
if parse_parameters_input "${DUPLICATE_INPUT}" > /dev/null 2>&1; then
  test_result "Duplicate parameter names" "success" "success"
else
  test_result "Duplicate parameter names" "success" "failure"
fi

# Cleanup
rm -rf "${TEST_DIR}"

echo ""
echo "📊 Test Results Summary"
echo "======================"
echo "Total tests: ${TOTAL_TESTS}"
echo "Passed: ${PASSED_TESTS}"
echo "Failed: ${FAILED_TESTS}"
echo "Success rate: $(( (PASSED_TESTS * 100) / TOTAL_TESTS ))%"

if [[ ${FAILED_TESTS} -eq 0 ]]; then
  echo ""
  echo "🎉 All tests passed! Parameter validation functionality is working correctly."
  exit 0
else
  echo ""
  echo "❌ Some tests failed. Please review the implementation."
  exit 1
fi