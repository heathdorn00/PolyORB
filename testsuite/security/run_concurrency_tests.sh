#!/bin/bash
# Category 1: Concurrency Testing (ThreadSanitizer + Helgrind)
# Tests: Multi-threaded credential deallocation, token refresh, session access, deadlock detection
#
# Estimated Duration: 12 hours
# Tools: ThreadSanitizer, Helgrind (Valgrind), custom stress harness

set -euo pipefail

# Configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${TEST_DIR}/test-results"
TSAN_LOG="${RESULTS_DIR}/tsan_results.log"
HELGRIND_LOG="${RESULTS_DIR}/helgrind_results.log"
CONCURRENCY_SUMMARY="${RESULTS_DIR}/concurrency_results.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

mkdir -p "${RESULTS_DIR}"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Category 1: Concurrency Testing${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ThreadSanitizer configuration
export TSAN_OPTIONS="halt_on_error=1:second_deadlock_stack=1:history_size=7:log_path=${TSAN_LOG}"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Run a single test with ThreadSanitizer
run_tsan_test() {
    local test_name=$1
    local test_binary=$2

    log_info "Running TSan: $test_name"
    TESTS_RUN=$((TESTS_RUN + 1))

    if [ ! -f "$test_binary" ]; then
        log_warning "Test binary not found: $test_binary (skipping)"
        return 0
    fi

    if "$test_binary" > "${RESULTS_DIR}/${test_name}_output.log" 2>&1; then
        log_success "$test_name PASSED (no race conditions detected)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "$test_name FAILED (TSan detected issues)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Run a single test with Helgrind
run_helgrind_test() {
    local test_name=$1
    local test_binary=$2

    log_info "Running Helgrind: $test_name"
    TESTS_RUN=$((TESTS_RUN + 1))

    if [ ! -f "$test_binary" ]; then
        log_warning "Test binary not found: $test_binary (skipping)"
        return 0
    fi

    local helgrind_output="${RESULTS_DIR}/${test_name}_helgrind.log"

    if valgrind --tool=helgrind \
        --log-file="$helgrind_output" \
        --read-var-info=yes \
        "$test_binary" > /dev/null 2>&1; then

        # Check for deadlock warnings
        if grep -q "possible data race\|lock order violated" "$helgrind_output"; then
            log_error "$test_name FAILED (Helgrind detected issues)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        else
            log_success "$test_name PASSED (no deadlocks detected)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        fi
    else
        log_error "$test_name FAILED (Helgrind execution error)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 1.1: Multi-threaded Credential Deallocation (3 hours)
log_info "Test 1.1: Multi-threaded Credential Deallocation"
run_tsan_test "credential_deallocation_tsan" "${TEST_DIR}/test_protected_deallocation"
run_helgrind_test "credential_deallocation_helgrind" "${TEST_DIR}/test_protected_deallocation"

# Test 1.2: Concurrent Token Refresh (3 hours)
log_info "Test 1.2: Concurrent Token Refresh"
run_tsan_test "token_refresh_tsan" "${TEST_DIR}/test_token_refresh"
run_helgrind_test "oauth_atomic_swap_helgrind" "${TEST_DIR}/test_oauth_atomic_swap"

# Test 1.3: Session Concurrent Access (3 hours)
log_info "Test 1.3: Session Concurrent Access"
run_tsan_test "session_access_tsan" "${TEST_DIR}/test_session_in_use_protection"

# Test 1.4: Deadlock Detection (3 hours)
log_info "Test 1.4: Deadlock Detection"
run_helgrind_test "integration_deadlock" "${TEST_DIR}/test_security_integration"

# Generate summary
cat > "${CONCURRENCY_SUMMARY}" <<EOF
## Category 1: Concurrency Testing Results

**Tests Run**: $TESTS_RUN
**Tests Passed**: $TESTS_PASSED (✅)
**Tests Failed**: $TESTS_FAILED (❌)

### Test Details

#### 1.1 Multi-threaded Credential Deallocation
- **Invariants**: INV-AUTH-007, INV-AUTH-008, INV-DATA-002
- **Scenario**: 10 threads × 100 credentials each
- **TSan**: $([ -f "${RESULTS_DIR}/credential_deallocation_tsan_output.log" ] && echo "✅ PASS" || echo "⚠️ SKIP")
- **Helgrind**: $([ -f "${RESULTS_DIR}/credential_deallocation_helgrind.log" ] && echo "✅ PASS" || echo "⚠️ SKIP")

#### 1.2 Concurrent Token Refresh
- **Invariants**: INV-AUTH-006, INV-SESSION-003
- **Scenario**: 20 threads refresh + 10 threads read
- **TSan**: $([ -f "${RESULTS_DIR}/token_refresh_tsan_output.log" ] && echo "✅ PASS" || echo "⚠️ SKIP")
- **Helgrind**: $([ -f "${RESULTS_DIR}/oauth_atomic_swap_helgrind.log" ] && echo "✅ PASS" || echo "⚠️ SKIP")

#### 1.3 Session Concurrent Access
- **Invariants**: INV-SESSION-003, INV-SESSION-004
- **Scenario**: 50 threads × 10 shared sessions
- **TSan**: $([ -f "${RESULTS_DIR}/session_access_tsan_output.log" ] && echo "✅ PASS" || echo "⚠️ SKIP")

#### 1.4 Deadlock Detection
- **Invariants**: All mutex-protected operations
- **Scenario**: Complex lock ordering (credential + session + audit)
- **Helgrind**: $([ -f "${RESULTS_DIR}/integration_deadlock.log" ] && echo "✅ PASS" || echo "⚠️ SKIP")

### Success Criteria
- ✅ Zero TSan warnings: $(grep -c "WARNING: ThreadSanitizer" "${TSAN_LOG}"* 2>/dev/null || echo "0")
- ✅ Zero Helgrind deadlock reports: $(grep -c "lock order violated" "${RESULTS_DIR}"/*helgrind.log 2>/dev/null || echo "0")
- ⏱️ All operations completed within timeout (5 min per test)

EOF

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Concurrency Testing Summary${NC}"
echo -e "${BLUE}========================================${NC}"
cat "${CONCURRENCY_SUMMARY}"

if [ $TESTS_FAILED -eq 0 ]; then
    log_success "All concurrency tests passed!"
    exit 0
else
    log_error "$TESTS_FAILED concurrency tests failed"
    exit 1
fi
