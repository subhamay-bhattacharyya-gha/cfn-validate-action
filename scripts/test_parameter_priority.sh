#!/bin/bash

# Test script to verify the determine_parameter_source function
set -euo pipefail

echo "🧪 Testing parameter priority logic..."

# Create test directory structure
mkdir -p test-cloudformation
echo '[{"ParameterKey": "TestParam", "ParameterValue": "TestValue"}]' > test-cloudformation/parameters.json

# Mock the parse_parameters_input function for testing
parse_parameters_input() {
  local parameters_input="$1"
  local temp_file="validation-output/parameters/input-parameters.json"
  
  mkdir -p validation-output/parameters
  
  # Simple validation - just check if it's not empty and looks like JSON
  if [[ -z "${parameters_input}" ]]; then
    return 1
  fi
  
  # Basic JSON check
  if echo "${parameters_input}" | jq empty 2>/dev/null; then
    echo "${parameters_input}" > "${temp_file}"
    echo "${temp_file}"
    return 0
  else
    return 1
  fi
}

# Extract the determine_parameter_source function from action.yaml
determine_parameter_source() {
  local parameters_input="$1"
  local parameters_file="$2"
  local parameters_path="$3"
  
  echo "🔍 Determining parameter source..." >&2
  echo "📋 Priority order: input > file > skip" >&2
  echo "🔍 Parameters input length: ${#parameters_input}" >&2
  echo "📄 Parameters file path: ${parameters_path}" >&2
  echo "📁 Parameters file exists: $(if [[ -f "${parameters_path}" ]]; then echo "yes"; else echo "no"; fi)" >&2
  
  # Priority: input > file > skip
  if [[ -n "${parameters_input}" ]]; then
    echo "🔍 Using parameters from input (priority: input > file)" >&2
    echo "💡 Parameters input takes precedence over parameters file" >&2
    
    # Parse and validate parameters input
    local temp_file
    if temp_file=$(parse_parameters_input "${parameters_input}"); then
      echo "✅ Parameters input parsed successfully" >&2
      echo "input|${temp_file}"
      return 0
    else
      echo "❌ Parameters input parsing failed" >&2
      return 1
    fi
    
  elif [[ -f "${parameters_path}" ]]; then
    echo "🔍 Using parameters from file: ${parameters_path}" >&2
    echo "💡 No parameters input provided, falling back to parameters file" >&2
    echo "file|${parameters_path}"
    return 0
    
  else
    echo "⏭️ No parameters provided (neither input nor file). Skipping parameters validation." >&2
    echo "💡 To include parameters validation:" >&2
    echo "  - Use 'parameters' input with JSON array format, or" >&2
    echo "  - Create a parameters file at: ${parameters_path}" >&2
    echo "skip|"
    return 0
  fi
}

# Test Case 1: Input takes precedence over file
echo ""
echo "🧪 Test Case 1: Input takes precedence over file"
echo "================================================"
PARAMETERS_INPUT='[{"ParameterName": "InputParam", "ParameterValue": "InputValue"}]'
PARAMETERS_FILE="parameters.json"
PARAMETERS_PATH="test-cloudformation/parameters.json"

if RESULT=$(determine_parameter_source "${PARAMETERS_INPUT}" "${PARAMETERS_FILE}" "${PARAMETERS_PATH}"); then
  SOURCE=$(echo "${RESULT}" | cut -d'|' -f1)
  DATA_FILE=$(echo "${RESULT}" | cut -d'|' -f2)
  echo "✅ Result: source=${SOURCE}, data_file=${DATA_FILE}"
  if [[ "${SOURCE}" == "input" ]]; then
    echo "✅ PASS: Input correctly takes precedence"
  else
    echo "❌ FAIL: Expected 'input', got '${SOURCE}'"
    exit 1
  fi
else
  echo "❌ FAIL: Function returned error"
  exit 1
fi

# Test Case 2: File fallback when no input
echo ""
echo "🧪 Test Case 2: File fallback when no input"
echo "============================================"
PARAMETERS_INPUT=""
PARAMETERS_FILE="parameters.json"
PARAMETERS_PATH="test-cloudformation/parameters.json"

if RESULT=$(determine_parameter_source "${PARAMETERS_INPUT}" "${PARAMETERS_FILE}" "${PARAMETERS_PATH}"); then
  SOURCE=$(echo "${RESULT}" | cut -d'|' -f1)
  DATA_FILE=$(echo "${RESULT}" | cut -d'|' -f2)
  echo "✅ Result: source=${SOURCE}, data_file=${DATA_FILE}"
  if [[ "${SOURCE}" == "file" ]]; then
    echo "✅ PASS: File correctly used as fallback"
  else
    echo "❌ FAIL: Expected 'file', got '${SOURCE}'"
    exit 1
  fi
else
  echo "❌ FAIL: Function returned error"
  exit 1
fi

# Test Case 3: Skip when neither input nor file
echo ""
echo "🧪 Test Case 3: Skip when neither input nor file"
echo "================================================"
PARAMETERS_INPUT=""
PARAMETERS_FILE="parameters.json"
PARAMETERS_PATH="test-cloudformation/nonexistent.json"

if RESULT=$(determine_parameter_source "${PARAMETERS_INPUT}" "${PARAMETERS_FILE}" "${PARAMETERS_PATH}"); then
  SOURCE=$(echo "${RESULT}" | cut -d'|' -f1)
  DATA_FILE=$(echo "${RESULT}" | cut -d'|' -f2)
  echo "✅ Result: source=${SOURCE}, data_file=${DATA_FILE}"
  if [[ "${SOURCE}" == "skip" ]]; then
    echo "✅ PASS: Correctly skips when no parameters available"
  else
    echo "❌ FAIL: Expected 'skip', got '${SOURCE}'"
    exit 1
  fi
else
  echo "❌ FAIL: Function returned error"
  exit 1
fi

# Test Case 4: Invalid input handling
echo ""
echo "🧪 Test Case 4: Invalid input handling"
echo "======================================"
PARAMETERS_INPUT='invalid json'
PARAMETERS_FILE="parameters.json"
PARAMETERS_PATH="test-cloudformation/parameters.json"

if RESULT=$(determine_parameter_source "${PARAMETERS_INPUT}" "${PARAMETERS_FILE}" "${PARAMETERS_PATH}"); then
  echo "❌ FAIL: Function should have returned error for invalid JSON"
  exit 1
else
  echo "✅ PASS: Function correctly handles invalid input"
fi

# Cleanup
rm -rf test-cloudformation validation-output

echo ""
echo "🎉 All tests passed! Parameter priority logic is working correctly."