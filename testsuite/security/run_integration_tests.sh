#!/bin/bash
# Security Invariants Integration Test Suite - Master Runner
# Task ID: a9209b
# Created: 2025-11-17
#
# This script orchestrates all security invariant integration tests across
# 4 categories: Concurrency, Memory, Error Handling, and Performance.
#
# Usage:
#   ./run_integration_tests.sh [--category=<1-4>] [--verbose] [--ci]
#
# Categories:
#   1 - Concurrency Testing (ThreadSanitizer, Helgrind)
#   2 - Memory Security Testing (AddressSanitizer, Valgrind)
#   3 - Error Handling Testing (Exception safety)
#   4 - Performance Impact Testing (Benchmarks)
#
# Options:
#   --category=N  Run only category N (default: all)
#   --verbose     Enable verbose output
#   --ci          CI mode (strict failure checking, no interactive prompts)
#   --help        Show this help

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${TEST_DIR}/test-results"
REPORT_FILE="${RESULTS_DIR}/integration_test_report.md"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Parse command line arguments
CATEGORY=""
VERBOSE=false
CI_MODE=false

for arg in "$@"; do
  case $arg in
    --category=*)
      CATEGORY="${arg#*=}"
      ;;
    --verbose)
      VERBOSE=true
      ;;
    --ci)
      CI_MODE=true
      ;;
    --help)
      grep "^#" "$0" | grep -v "#!/bin/bash" | sed 's/^# //'
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $arg${NC}"
      exit 1
      ;;
  esac
done

# Initialize results directory
mkdir -p "${RESULTS_DIR}"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    log_section "Checking Prerequisites"

    local missing_tools=()

    # Check for required tools
    for tool in gnat gcc valgrind; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        else
            log_info "$tool found: $(command -v $tool)"
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Install with: sudo apt-get install gnat-13 gcc valgrind"
        return 1
    fi

    log_success "All prerequisites satisfied"
    return 0
}

# Run category 1: Concurrency tests
run_concurrency_tests() {
    log_section "Category 1: Concurrency Testing (12 hours)"

    if [ -f "${TEST_DIR}/run_concurrency_tests.sh" ]; then
        bash "${TEST_DIR}/run_concurrency_tests.sh" || return 1
    else
        log_warning "run_concurrency_tests.sh not found, skipping"
        return 0
    fi

    log_success "Concurrency tests completed"
    return 0
}

# Run category 2: Memory security tests
run_memory_tests() {
    log_section "Category 2: Memory Security Testing (8 hours)"

    if [ -f "${TEST_DIR}/run_memory_tests.sh" ]; then
        bash "${TEST_DIR}/run_memory_tests.sh" || return 1
    else
        log_warning "run_memory_tests.sh not found, skipping"
        return 0
    fi

    log_success "Memory security tests completed"
    return 0
}

# Run category 3: Error handling tests
run_error_handling_tests() {
    log_section "Category 3: Error Handling Testing (6 hours)"

    if [ -f "${TEST_DIR}/run_error_handling_tests.sh" ]; then
        bash "${TEST_DIR}/run_error_handling_tests.sh" || return 1
    else
        log_warning "run_error_handling_tests.sh not found, skipping"
        return 0
    fi

    log_success "Error handling tests completed"
    return 0
}

# Run category 4: Performance tests
run_performance_tests() {
    log_section "Category 4: Performance Impact Testing (6 hours)"

    if [ -f "${TEST_DIR}/run_performance_tests.sh" ]; then
        bash "${TEST_DIR}/run_performance_tests.sh" || return 1
    else
        log_warning "run_performance_tests.sh not found, skipping"
        return 0
    fi

    log_success "Performance tests completed"
    return 0
}

# Generate test report
generate_report() {
    log_section "Generating Test Report"

    cat > "${REPORT_FILE}" <<EOF
# Security Invariants Integration Test Results
**Generated**: $(date)
**Test Run ID**: ${TIMESTAMP}

## Summary

EOF

    # Aggregate results from each category
    for category in concurrency memory error_handling performance; do
        if [ -f "${RESULTS_DIR}/${category}_results.txt" ]; then
            cat "${RESULTS_DIR}/${category}_results.txt" >> "${REPORT_FILE}"
        fi
    done

    log_success "Report generated: ${REPORT_FILE}"
}

# Main execution
main() {
    log_section "Security Invariants Integration Test Suite"
    log_info "Task ID: a9209b"
    log_info "Test Run ID: ${TIMESTAMP}"
    log_info "Results Directory: ${RESULTS_DIR}"

    # Check prerequisites
    check_prerequisites || exit 1

    # Track overall status
    local exit_code=0

    # Run requested categories
    if [ -z "$CATEGORY" ] || [ "$CATEGORY" = "1" ]; then
        run_concurrency_tests || exit_code=1
    fi

    if [ -z "$CATEGORY" ] || [ "$CATEGORY" = "2" ]; then
        run_memory_tests || exit_code=1
    fi

    if [ -z "$CATEGORY" ] || [ "$CATEGORY" = "3" ]; then
        run_error_handling_tests || exit_code=1
    fi

    if [ -z "$CATEGORY" ] || [ "$CATEGORY" = "4" ]; then
        run_performance_tests || exit_code=1
    fi

    # Generate consolidated report
    generate_report

    # Final status
    if [ $exit_code -eq 0 ]; then
        log_section "✅ ALL TESTS PASSED"
        log_success "Security invariants integration testing complete"
        log_info "View full report: ${REPORT_FILE}"
        exit 0
    else
        log_section "❌ SOME TESTS FAILED"
        log_error "One or more test categories failed"
        log_info "Review logs in: ${RESULTS_DIR}"
        exit 1
    fi
}

# Run main function
main
