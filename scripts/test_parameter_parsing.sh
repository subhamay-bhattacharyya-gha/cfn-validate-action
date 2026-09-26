#!/bin/bash

# Test script for parameter input parsing function
set -euo pipefail

echo "🧪 Testing parameter input parsing function..."

# Create test directory
mkdir -p test-validation-output/parameters

# Test function (extracted from action.yaml)
parse_parameters_input() {
  local parameters_input="$1"
  local temp_file="test-validation-output/parameters/input-parameters.json"
  
  echo "::group::🔍 Parsing Parameters Input"
  echo "📝 Processing parameters from input..."
  
  # Create output directory
  mkdir -p test-validation-output/parameters
  
  # Check if input is empty
  if [[ -z "${parameters_input}" ]]; then
    echo "⚠️ Parameters input is empty"
    echo "::endgroup::"
    return 1
  fi
  
  # Validate JSON syntax
  echo "🔄 Validating JSON syntax..."
  if ! echo "${parameters_input}" | jq empty 2> test-validation-output/parameters/input-json-errors.log; then
    echo "❌ Invalid JSON format in parameters input!"
    
    if [[ -f test-validation-output/parameters/input-json-errors.log ]]; then
      local error_content=$(cat test-validation-output/parameters/input-json-errors.log)
      echo "🔍 JSON Error Details:"
      echo "${error_content}"
      
      # Extract main error message
      local error_message=$(echo "${error_content}" | head -1)
      echo "::error title=Parameters Input JSON Error::${error_message}"
    fi
    
    echo ""
    echo "📖 Expected JSON format:"
    echo '[{"ParameterName": "string", "ParameterValue": "string"}]'
    echo ""
    echo "📄 Example:"
    echo '[{"ParameterName": "Environment", "ParameterValue": "production"}]'
    
    echo "::endgroup::"
    return 1
  fi
  
  echo "✅ JSON syntax is valid"
  
  # Save input to temporary file for further processing
  echo "${parameters_input}" > "${temp_file}"
  
  # Validate structure - ensure it's an array
  echo "📋 Checking if root element is an array..."
  if ! jq -e 'type == "array"' "${temp_file}" > /dev/null 2>&1; then
    echo "❌ Parameters input structure validation failed!"
    echo "🔍 Structure Error: Parameters input must be a JSON array"
    
    local current_type=$(jq -r 'type' "${temp_file}" 2>/dev/null || echo "unknown")
    echo "📄 Current root type: ${current_type}"
    echo ""
    echo "📖 Expected format:"
    echo '[{"ParameterName": "string", "ParameterValue": "string"}]'
    
    echo "::error title=Parameters Input Structure Error::Parameters input must be a JSON array of parameter objects"
    echo "::endgroup::"
    return 1
  fi
  
  echo "✅ Root element is an array"
  
  # Check array length
  local param_count=$(jq 'length' "${temp_file}")
  echo "📊 Array length: ${param_count}"
  
  if [[ "${param_count}" -eq 0 ]]; then
    echo "⚠️ Parameters input is an empty array"
    echo "✅ Structure is valid but no parameters defined"
    echo "::endgroup::"
    return 0
  fi
  
  # Validate each parameter object structure
  echo "🔄 Validating individual parameter objects..."
  
  local structure_errors=""
  if structure_errors=$(jq -r '
    to_entries[] | 
    select(
      (.value | type != "object") or 
      (.value | has("ParameterName") | not) or 
      (.value | has("ParameterValue") | not) or
      (.value.ParameterName | type != "string") or
      (.value.ParameterValue | type != "string") or
      (.value.ParameterName == "")
    ) | 
    "Parameter at index \(.key): \(
      if (.value | type != "object") then "must be an object (currently: \(.value | type))"
      elif (.value | has("ParameterName") | not) then "missing required ParameterName field"
      elif (.value | has("ParameterValue") | not) then "missing required ParameterValue field"
      elif (.value.ParameterName | type != "string") then "ParameterName must be a string (currently: \(.value.ParameterName | type))"
      elif (.value.ParameterValue | type != "string") then "ParameterValue must be a string (currently: \(.value.ParameterValue | type))"
      elif (.value.ParameterName == "") then "ParameterName cannot be empty"
      else "unknown structural error"
      end
    )"
  ' "${temp_file}" 2>/dev/null); then
    
    if [[ -n "${structure_errors}" ]]; then
      echo "❌ Parameters input structure validation failed!"
      echo "🔍 Structure Validation Errors:"
      echo "${structure_errors}"
      echo ""
      echo "📖 Expected format for each parameter:"
      echo '{"ParameterName": "string", "ParameterValue": "string"}'
      echo ""
      echo "📄 Example of valid parameters input:"
      cat << 'EOF'
[
  {"ParameterName": "Environment", "ParameterValue": "production"},
  {"ParameterName": "InstanceType", "ParameterValue": "t3.micro"}
]
EOF
      
      # Create GitHub error annotations for each structure error
      local error_count=0
      while IFS= read -r error_line; do
        [[ -z "${error_line}" ]] && continue
        echo "::error title=Parameter Input Structure Error::${error_line}"
        ((error_count++))
      done <<< "${structure_errors}"
      
      echo "📊 Total structure errors: ${error_count}"
      echo "::endgroup::"
      return 1
    fi
  fi
  
  echo "✅ Parameters input structure validation successful!"
  echo "📊 Successfully parsed ${param_count} parameters from input"
  echo "::endgroup::"
  
  # Set the temp file path for use by calling function
  echo "${temp_file}"
  return 0
}

# Test cases
echo ""
echo "=== Test 1: Valid parameters input ==="
VALID_INPUT='[{"ParameterName": "Environment", "ParameterValue": "production"}, {"ParameterName": "InstanceType", "ParameterValue": "t3.micro"}]'
if parse_parameters_input "${VALID_INPUT}" > /dev/null 2>&1; then
  echo "✅ Test 1 PASSED: Valid input parsed successfully"
  if [[ -f "test-validation-output/parameters/input-parameters.json" ]]; then
    echo "📋 Content:"
    cat "test-validation-output/parameters/input-parameters.json" | jq .
  fi
else
  echo "❌ Test 1 FAILED: Valid input should have been parsed successfully"
fi

echo ""
echo "=== Test 2: Invalid JSON syntax ==="
INVALID_JSON='[{"ParameterName": "Environment", "ParameterValue": "production"'
if parse_parameters_input "${INVALID_JSON}" > /dev/null 2>&1; then
  echo "❌ Test 2 FAILED: Invalid JSON should have been rejected"
else
  echo "✅ Test 2 PASSED: Invalid JSON was correctly rejected"
fi

echo ""
echo "=== Test 3: Wrong structure (not array) ==="
WRONG_STRUCTURE='{"ParameterName": "Environment", "ParameterValue": "production"}'
if parse_parameters_input "${WRONG_STRUCTURE}" > /dev/null 2>&1; then
  echo "❌ Test 3 FAILED: Non-array structure should have been rejected"
else
  echo "✅ Test 3 PASSED: Non-array structure was correctly rejected"
fi

echo ""
echo "=== Test 4: Missing required fields ==="
MISSING_FIELDS='[{"ParameterName": "Environment"}]'
if parse_parameters_input "${MISSING_FIELDS}" > /dev/null 2>&1; then
  echo "❌ Test 4 FAILED: Missing fields should have been rejected"
else
  echo "✅ Test 4 PASSED: Missing fields were correctly rejected"
fi

echo ""
echo "=== Test 5: Empty array ==="
EMPTY_ARRAY='[]'
if parse_parameters_input "${EMPTY_ARRAY}" > /dev/null 2>&1; then
  echo "✅ Test 5 PASSED: Empty array was accepted"
  if [[ -f "test-validation-output/parameters/input-parameters.json" ]]; then
    echo "📋 Content:"
    cat "test-validation-output/parameters/input-parameters.json" | jq .
  fi
else
  echo "❌ Test 5 FAILED: Empty array should have been accepted"
fi

echo ""
echo "=== Test 6: Empty parameter name ==="
EMPTY_NAME='[{"ParameterName": "", "ParameterValue": "production"}]'
if parse_parameters_input "${EMPTY_NAME}" > /dev/null 2>&1; then
  echo "❌ Test 6 FAILED: Empty parameter name should have been rejected"
else
  echo "✅ Test 6 PASSED: Empty parameter name was correctly rejected"
fi

# Cleanup
rm -rf test-validation-output

echo ""
echo "🎉 Parameter parsing function tests completed!"