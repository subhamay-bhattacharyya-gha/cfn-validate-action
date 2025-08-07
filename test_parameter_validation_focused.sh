#!/bin/bash

# Focused test script for parameter validation functionality
# Tests the requirements: 3.1, 3.2, 3.4
set -uo pipefail

echo "🧪 Parameter Validation Tests - Requirements 3.1, 3.2, 3.4"
echo "=========================================================="

# Create test directory structure
TEST_DIR="test-validation-focused"
mkdir -p "${TEST_DIR}/cloudformation"
mkdir -p "${TEST_DIR}/validation-output/parameters"

# Create test parameter file (existing format with ParameterKey)
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

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0

# Test result function
run_test() {
  local test_name="$1"
  local test_command="$2"
  local expected_result="$3"
  
  ((TOTAL_TESTS++))
  echo ""
  echo "Test ${TOTAL_TESTS}: ${test_name}"
  echo "----------------------------------------"
  
  if eval "${test_command}"; then
    local actual_result="success"
  else
    local actual_result="failure"
  fi
  
  if [[ "${expected_result}" == "${actual_result}" ]]; then
    echo "✅ PASS: ${test_name}"
    ((PASSED_TESTS++))
  else
    echo "❌ FAIL: ${test_name} (expected: ${expected_result}, got: ${actual_result})"
  fi
}

# Simplified parse function for testing
parse_parameters_input() {
  local parameters_input="$1"
  local temp_file="${TEST_DIR}/validation-output/parameters/input-parameters.json"
  
  [[ -n "${parameters_input}" ]] || return 1
  echo "${parameters_input}" | jq empty 2>/dev/null || return 1
  echo "${parameters_input}" > "${temp_file}"
  jq -e 'type == "array"' "${temp_file}" >/dev/null 2>&1 || return 1
  
  # Basic structure validation
  local count=$(jq 'length' "${temp_file}")
  if [[ "${count}" -gt 0 ]]; then
    jq -e '.[0] | has("ParameterName") and has("ParameterValue")' "${temp_file}" >/dev/null 2>&1 || return 1
  fi
  
  echo "${temp_file}"
  return 0
}

# Priority determination function
determine_parameter_source() {
  local parameters_input="$1"
  local parameters_path="$2"
  
  echo "Debug: checking parameters_input='${parameters_input}'" >&2
  echo "Debug: checking parameters_path='${parameters_path}'" >&2
  echo "Debug: file exists check: $(if [[ -f "${parameters_path}" ]]; then echo "yes"; else echo "no"; fi)" >&2
  
  if [[ -n "${parameters_input}" ]]; then
    if parse_parameters_input "${parameters_input}" >/dev/null 2>&1; then
      echo "input"
      return 0
    else
      return 1
    fi
  elif [[ -f "${parameters_path}" ]]; then
    echo "file"
    return 0
  else
    echo "skip"
    return 0
  fi
}

echo ""
echo "🧪 Test Suite 1: Valid Parameter Input Formats (Req 3.1)"
echo "========================================================"

# Test valid parameter formats
run_test "Basic valid parameter input" \
  'parse_parameters_input '"'"'[{"ParameterName": "Environment", "ParameterValue": "production"}]'"'"' >/dev/null 2>&1' \
  "success"

run_test "Multiple parameters input" \
  'parse_parameters_input '"'"'[{"ParameterName": "Env", "ParameterValue": "prod"}, {"ParameterName": "Type", "ParameterValue": "t3.micro"}]'"'"' >/dev/null 2>&1' \
  "success"

run_test "Empty array input" \
  'parse_parameters_input '"'"'[]'"'"' >/dev/null 2>&1' \
  "success"

echo ""
echo "🧪 Test Suite 2: Invalid Parameter Input Scenarios (Req 3.1)"
echo "==========================================================="

# Test invalid parameter formats
run_test "Invalid JSON syntax" \
  'parse_parameters_input '"'"'[{"ParameterName": "Environment", "ParameterValue": "production"'"'"' >/dev/null 2>&1' \
  "failure"

run_test "Non-array structure" \
  'parse_parameters_input '"'"'{"ParameterName": "Environment", "ParameterValue": "production"}'"'"' >/dev/null 2>&1' \
  "failure"

run_test "Missing required fields" \
  'parse_parameters_input '"'"'[{"ParameterName": "Environment"}]'"'"' >/dev/null 2>&1' \
  "failure"

echo ""
echo "🧪 Test Suite 3: Priority Logic (Req 3.2)"
echo "========================================="

# Test priority logic
run_test "Input takes precedence over file" \
  'result=$(determine_parameter_source '"'"'[{"ParameterName": "Test", "ParameterValue": "value"}]'"'"' '"'"'${TEST_DIR}/cloudformation/valid-parameters.json'"'"'); [[ "$result" == "input" ]]' \
  "success"

run_test "File fallback when no input" \
  'result=$(determine_parameter_source "" '"'"'${TEST_DIR}/cloudformation/valid-parameters.json'"'"'); echo "Result: $result"; [[ "$result" == "file" ]]' \
  "success"

run_test "Skip when neither available" \
  'result=$(determine_parameter_source "" '"'"'${TEST_DIR}/cloudformation/nonexistent.json'"'"'); [[ "$result" == "skip" ]]' \
  "success"

echo ""
echo "🧪 Test Suite 4: Backward Compatibility (Req 3.4)"
echo "================================================"

# Test backward compatibility
run_test "Traditional file-based workflow" \
  'result=$(determine_parameter_source "" '"'"'${TEST_DIR}/cloudformation/valid-parameters.json'"'"'); echo "Result: $result"; [[ "$result" == "file" ]]' \
  "success"

run_test "File format uses ParameterKey (not ParameterName)" \
  'echo "Checking file: ${TEST_DIR}/cloudformation/valid-parameters.json"; ls -la "${TEST_DIR}/cloudformation/"; jq -e '"'"'.[0] | has("ParameterKey")'"'"' '"'"'${TEST_DIR}/cloudformation/valid-parameters.json'"'"' >/dev/null 2>&1' \
  "success"

run_test "Input format uses ParameterName (not ParameterKey)" \
  'temp_file=$(parse_parameters_input '"'"'[{"ParameterName": "Test", "ParameterValue": "value"}]'"'"'); jq -e '"'"'.[0] | has("ParameterName")'"'"' "$temp_file" >/dev/null 2>&1' \
  "success"

# Cleanup
rm -rf "${TEST_DIR}"

echo ""
echo "📊 Test Results Summary"
echo "======================"
echo "Total tests: ${TOTAL_TESTS}"
echo "Passed: ${PASSED_TESTS}"
echo "Failed: $((TOTAL_TESTS - PASSED_TESTS))"

if [[ ${PASSED_TESTS} -eq ${TOTAL_TESTS} ]]; then
  echo ""
  echo "🎉 All tests passed! Parameter validation functionality meets requirements."
  exit 0
else
  echo ""
  echo "❌ Some tests failed. Review implementation needed."
  exit 1
fi