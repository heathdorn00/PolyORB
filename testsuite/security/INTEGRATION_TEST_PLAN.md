# Security Invariants Integration Test Plan
**Task ID**: a9209b
**Created**: 2025-11-17
**Owner**: @test_stabilize
**Estimated Effort**: 32 hours

## Objective

Perform comprehensive integration testing of all 22 security invariants across the entire PolyORB codebase, validating thread-safety, memory security, error handling, and performance characteristics in realistic operational scenarios.

## Executive Summary

PolyORB implements 22 security invariants across 9 security modules. This test plan validates these invariants under:
- Multi-threaded concurrent access (race conditions, deadlocks)
- Complex object lifecycles (creation, use, expiration, destruction)
- Error conditions and edge cases (exception safety, cleanup verification)
- Resource exhaustion scenarios (memory limits, handle exhaustion)
- Real-world interoperability patterns (legacy code integration)

## Security Invariants Inventory

### Authentication & Authorization (INV-AUTH-*)
1. **INV-AUTH-001**: Safe credential handle validation
2. **INV-AUTH-002**: Timing-safe credential comparison
3. **INV-AUTH-003**: Credential lifecycle tracking with audit logging
4. **INV-AUTH-004**: Mutex-protected credential operations
5. **INV-AUTH-005**: Credential expiry enforcement
6. **INV-AUTH-006**: Token refresh atomicity
7. **INV-AUTH-007**: Race-free deallocation (mutex before free)
8. **INV-AUTH-008**: Double-free prevention

### Cryptographic Security (INV-CRYPTO-*)
9. **INV-CRYPTO-001**: Volatile writes for key zeroization
10. **INV-CRYPTO-002**: Memory barriers for completion guarantee
11. **INV-CRYPTO-003**: Comprehensive byte coverage
12. **INV-CRYPTO-004**: Timing-safe comparison operations
13. **INV-CRYPTO-005**: Protected random pool cleanup
14. **INV-CRYPTO-006**: Zeroization before deallocation

### Session Management (INV-SESSION-*)
15. **INV-SESSION-001**: Session token secure cleanup
16. **INV-SESSION-002**: Session expiration enforcement
17. **INV-SESSION-003**: Thread-safe session access
18. **INV-SESSION-004**: In-use session protection

### Data Protection (INV-DATA-*)
19. **INV-DATA-001**: Buffer overflow protection
20. **INV-DATA-002**: Protected deallocation with mutex

### Audit & Logging (INV-AUDIT-*)
21. **INV-AUDIT-001**: Security event audit logging
22. **INV-AUDIT-002**: Audit log integrity protection

## Test Categories

### Category 1: Concurrency Testing (12 hours)

**Objective**: Validate thread-safety of all security invariants under concurrent access.

**Tools**:
- ThreadSanitizer (TSan) - race detection
- Helgrind (Valgrind) - deadlock detection
- Custom stress harness

**Tests**:

#### 1.1 Multi-threaded Credential Deallocation (3 hours)
**Invariants**: INV-AUTH-007, INV-AUTH-008, INV-DATA-002
**Scenario**: 10 threads concurrently deallocating 100 credentials each
**Expected**: Zero race conditions, zero double-frees
**Files**: `test_protected_deallocation.adb`, `test_credential_lifecycle.adb`

#### 1.2 Concurrent Token Refresh (3 hours)
**Invariants**: INV-AUTH-006, INV-SESSION-003
**Scenario**: 20 threads refreshing tokens while 10 threads read them
**Expected**: Atomic token swaps, no torn reads
**Files**: `test_token_refresh.adb`, `test_oauth_atomic_swap.adb`

#### 1.3 Session Concurrent Access (3 hours)
**Invariants**: INV-SESSION-003, INV-SESSION-004
**Scenario**: 50 threads accessing 10 shared sessions
**Expected**: Proper mutex protection, no corruption
**Files**: `test_session_in_use_protection.adb`

#### 1.4 Deadlock Detection (3 hours)
**Invariants**: All mutex-protected operations
**Scenario**: Complex lock ordering in credential + session + audit operations
**Expected**: Zero deadlocks detected by Helgrind
**Files**: `test_security_integration.adb`

**Success Criteria**:
- Zero TSan warnings
- Zero Helgrind deadlock reports
- All operations complete within timeout (5 minutes per test)

---

### Category 2: Memory Security Testing (8 hours)

**Objective**: Validate secure memory operations and leak prevention.

**Tools**:
- AddressSanitizer (ASan) - memory errors
- Valgrind Memcheck - leak detection
- Custom zeroization validators

**Tests**:

#### 2.1 Cryptographic Buffer Zeroization (2 hours)
**Invariants**: INV-CRYPTO-001, INV-CRYPTO-002, INV-CRYPTO-003, INV-CRYPTO-006
**Scenario**: Allocate 1000 crypto buffers, fill with known patterns, zeroize, verify
**Expected**: 100% zeroization, no compiler optimization
**Files**: `test_crypto_buffer_zeroization.adb`, `test_crypto_key_zeroization.adb`

**Validation Method**:
```ada
-- Before zeroization: buffer = [0xDE, 0xAD, 0xBE, 0xEF, ...]
Secure_Zero (Buffer);
-- After: buffer = [0x00, 0x00, 0x00, 0x00, ...]
-- Verify via memory dump that ALL bytes = 0
```

#### 2.2 Memory Leak Detection (2 hours)
**Invariants**: INV-AUTH-003, INV-DATA-002
**Scenario**: 10,000 credential create/destroy cycles
**Expected**: Zero leaks detected by Valgrind
**Files**: `test_memory_leak_detection.adb`

#### 2.3 Use-After-Free Detection (2 hours)
**Invariants**: INV-AUTH-008, INV-DATA-002
**Scenario**: Attempt to access freed credentials (should fail gracefully)
**Expected**: ASan detects violations, no crashes
**Files**: `test_credential_zeroization.adb`

#### 2.4 Double-Free Prevention (2 hours)
**Invariants**: INV-AUTH-008
**Scenario**: Attempt double-free on credentials
**Expected**: Runtime error with clear diagnostic
**Files**: `test_protected_deallocation.adb`

**Success Criteria**:
- Zero Valgrind "definitely lost" leaks
- Zero ASan "heap-use-after-free" errors (except intentional test cases)
- 100% zeroization verification (all bytes = 0x00)

---

### Category 3: Error Handling Testing (6 hours)

**Objective**: Validate exception safety and cleanup on error paths.

**Tools**:
- GNATtest - exception testing framework
- Custom fault injection harness

**Tests**:

#### 3.1 Exception Safety During Deallocation (2 hours)
**Invariants**: INV-AUTH-007, INV-DATA-002, INV-AUDIT-001
**Scenario**: Inject exceptions during deallocation paths
**Expected**: Proper cleanup despite exceptions
**Files**: `test_protected_deallocation.adb`

#### 3.2 Resource Cleanup on Error Paths (2 hours)
**Invariants**: INV-AUTH-003, INV-SESSION-002
**Scenario**: Force errors during credential/session creation
**Expected**: No leaked resources
**Files**: `test_credential_lifecycle.adb`

#### 3.3 Audit Logging Under Failure (2 hours)
**Invariants**: INV-AUDIT-001, INV-AUDIT-002
**Scenario**: Full audit log, out-of-disk-space conditions
**Expected**: Graceful degradation, integrity maintained
**Files**: `test_audit_logging.adb`

**Success Criteria**:
- All exception scenarios handled gracefully
- Zero resource leaks on error paths
- Audit log integrity maintained (checksum validation)

---

### Category 4: Performance Impact Testing (6 hours)

**Objective**: Measure performance overhead of security invariants.

**Tools**:
- GNATprof - profiling
- perf - Linux performance counters
- Custom benchmarking harness

**Tests**:

#### 4.1 Mutex Overhead Measurement (2 hours)
**Invariants**: INV-AUTH-004, INV-AUTH-007, INV-SESSION-003
**Scenario**: Compare protected vs unprotected operations (1M iterations)
**Expected**: Overhead <10%
**Baseline**: 5ns per unprotected operation
**Target**: <6ns per protected operation

#### 4.2 Zeroization Performance (2 hours)
**Invariants**: INV-CRYPTO-001, INV-CRYPTO-002, INV-CRYPTO-003
**Scenario**: Zeroize 10,000 buffers of varying sizes (64B - 1MB)
**Expected**: Linear scaling, <5μs per 1KB
**Files**: `test_secure_memory.adb`

#### 4.3 Memory Footprint Analysis (2 hours)
**Invariants**: All
**Scenario**: Measure memory overhead of security features
**Expected**: <5% increase vs baseline
**Baseline**: Track current memory usage
**Measurement**: RSS, heap, stack size

**Success Criteria**:
- Mutex overhead <10%
- Zeroization overhead <5% of total deallocation time
- Memory footprint increase <5%

---

## Testing Infrastructure

### Build Configurations

#### 1. ThreadSanitizer Build
```bash
gprbuild -XBUILD_MODE=tsan -cargs -fsanitize=thread -g -O1
```

#### 2. AddressSanitizer Build
```bash
gprbuild -XBUILD_MODE=asan -cargs -fsanitize=address -g -O1
```

#### 3. Production Build (Baseline)
```bash
gprbuild -XBUILD_MODE=release -cargs -O2
```

### Test Execution Framework

**Master Test Runner**: `testsuite/security/run_integration_tests.sh`

```bash
#!/bin/bash
# Runs all 4 test categories with appropriate sanitizers

echo "=== Security Invariants Integration Tests ==="

# Category 1: Concurrency (ThreadSanitizer)
export TSAN_OPTIONS="halt_on_error=1:second_deadlock_stack=1"
./run_concurrency_tests.sh

# Category 2: Memory (AddressSanitizer + Valgrind)
export ASAN_OPTIONS="halt_on_error=0:detect_leaks=1"
./run_memory_tests.sh

# Category 3: Error Handling (GNATtest)
./run_error_handling_tests.sh

# Category 4: Performance (Benchmarks)
./run_performance_tests.sh

# Generate unified report
./generate_test_report.sh
```

### Continuous Integration Integration

Add to `.github/workflows/security-tests.yml`:

```yaml
jobs:
  security-invariants-tests:
    name: Security Invariants Integration Tests
    runs-on: ubuntu-latest
    timeout-minutes: 120

    steps:
      - name: Install sanitizer support
        run: |
          sudo apt-get install -y \
            valgrind \
            gnat-13

      - name: Run concurrency tests
        run: |
          cd testsuite/security
          ./run_concurrency_tests.sh

      - name: Run memory tests
        run: ./run_memory_tests.sh

      - name: Upload test results
        uses: actions/upload-artifact@v4
        with:
          name: security-test-results
          path: testsuite/security/test-results/
          retention-days: 30
```

---

## Deliverables

### 1. Test Suite (Code)
- [ ] `run_integration_tests.sh` - Master test runner
- [ ] `run_concurrency_tests.sh` - TSan/Helgrind tests
- [ ] `run_memory_tests.sh` - ASan/Valgrind tests
- [ ] `run_error_handling_tests.sh` - Exception safety tests
- [ ] `run_performance_tests.sh` - Benchmarks

### 2. Test Coverage Report
- [ ] Coverage by module (>90% of security code)
- [ ] Coverage by invariant (all 22 covered)
- [ ] Uncovered paths (with justification)

### 3. Performance Impact Analysis
- [ ] Benchmark results (CSV + charts)
- [ ] Overhead breakdown by invariant
- [ ] Recommendations for optimization

### 4. Bug Reports
- [ ] Critical issues (JIRA tickets created)
- [ ] Medium issues (documented in backlog)
- [ ] Enhancement suggestions

---

## Acceptance Criteria

✅ **Functional**:
- All 22 security invariants tested in integration scenarios
- All tests passing (zero failures)
- Test coverage >90% of security modules

✅ **Concurrency**:
- Zero TSan race conditions
- Zero Helgrind deadlocks
- All concurrent scenarios complete successfully

✅ **Memory**:
- Zero Valgrind memory leaks
- 100% zeroization verification
- Zero ASan use-after-free errors

✅ **Performance**:
- Mutex overhead <10%
- Zeroization overhead <5%
- Memory footprint increase <5%

✅ **Documentation**:
- Test coverage report generated
- Performance analysis documented
- All findings tracked in issue system

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Tests flaky under CI | Medium | High | Run 3 times, require 3/3 pass |
| Performance variance | High | Medium | Run 10 iterations, report median |
| Sanitizer false positives | Low | High | Manually review all warnings |
| Test environment differences | Medium | Medium | Use Docker for consistency |

---

## Timeline

| Phase | Duration | Owner | Deliverables |
|-------|----------|-------|--------------|
| Test infrastructure setup | 4h | @refactor_agent | Master runners, CI config |
| Concurrency testing | 12h | @test_stabilize | TSan/Helgrind results |
| Memory testing | 8h | @test_stabilize | ASan/Valgrind reports |
| Error handling testing | 6h | @test_stabilize | Exception safety validation |
| Performance testing | 6h | @test_stabilize | Benchmark analysis |
| Report generation | 2h | @security_verification | Final test report |

**Total**: 32 hours (4 days @ 8h/day)

---

## Appendix A: Existing Test Files

| Test File | Invariants Tested | Status |
|-----------|-------------------|--------|
| test_crypto_buffer_zeroization | INV-CRYPTO-001/002/003/006 | ✅ Compiled |
| test_crypto_key_zeroization | INV-CRYPTO-001/002/003 | ✅ Compiled |
| test_memory_leak_detection | INV-AUTH-003, INV-DATA-002 | ✅ Compiled |
| test_secure_memory | INV-CRYPTO-001/002/003 | ✅ Compiled |
| test_session_in_use_protection | INV-SESSION-003/004 | ✅ Compiled |
| test_session_token_zeroization | INV-SESSION-001 | ✅ Compiled |
| test_acl_reference_counting | ACL lifecycle | ⚠️ Source only |
| test_audit_logging | INV-AUDIT-001/002 | ⚠️ Source only |
| test_buffer_protection | INV-DATA-001 | ⚠️ Source only |
| test_credential_lifecycle | INV-AUTH-003/004 | ⚠️ Source only |
| test_credential_zeroization | INV-CRYPTO-006, INV-AUTH-007 | ⚠️ Source only |
| test_naming_security | Naming validation | ⚠️ Source only |
| test_oauth_atomic_swap | INV-AUTH-006 | ⚠️ Source only |
| test_protected_deallocation | INV-AUTH-007/008, INV-DATA-002 | ⚠️ Source only |
| test_qos_validation_security | QoS validation | ⚠️ Source only |
| test_random_pool_state_cleanup | INV-CRYPTO-005 | ⚠️ Source only |
| test_security_integration | All invariants | ⚠️ Source only |
| test_timing_safe | INV-AUTH-002, INV-CRYPTO-004 | ⚠️ Source only |
| test_token_refresh | INV-AUTH-006 | ⚠️ Source only |
| test_transport_validation_security | Transport validation | ⚠️ Source only |
| test_trust_evaluator_security | Trust evaluation | ⚠️ Source only |

**Status**: 6/21 tests compiled and executable, 15/21 source only

---

## Appendix B: Security Module Inventory

| Module | File | Invariants | LOC |
|--------|------|------------|-----|
| Protected Deallocation | polyorb-security-protected_deallocation.ad[sb] | INV-DATA-002, INV-CRYPTO-006, INV-AUDIT-001 | ~200 |
| Secure Memory | polyorb-security-secure_memory.ad[sb] | INV-CRYPTO-001/002/003 | ~150 |
| Credential Lifecycle | polyorb-security-credential_lifecycle.ad[sb] | INV-AUTH-003/004 | ~300 |
| OAuth Token Manager | polyorb-security-oauth_token_manager.ad[sb] | INV-AUTH-006 | ~250 |
| Audit Log | polyorb-security-audit_log.ad[sb] | INV-AUDIT-001/002 | ~200 |
| Timing Safe | polyorb-security-timing_safe.ad[sb] | INV-AUTH-002, INV-CRYPTO-004 | ~100 |
| Buffer Protection | polyorb-security-buffer_protection.ad[sb] | INV-DATA-001 | ~150 |
| Transport Validation | polyorb-security-transport_validation.ad[sb] | Transport security | ~200 |
| QoS Validation | polyorb-security-qos_validation.ad[sb] | QoS security | ~200 |

**Total Security Code**: ~1,750 LOC
**Target Test Coverage**: >90% (>1,575 LOC covered)
