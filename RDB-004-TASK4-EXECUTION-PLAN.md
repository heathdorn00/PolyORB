# RDB-004 Task 4: CDR Marshalling Module Extraction
**Task ID**: fb039e
**Created**: 2025-11-17
**Owner**: @refactor_agent
**Estimated Effort**: 7-9 days (56-72 hours)
**Dependencies**: Task 3 (Accessor extraction) must complete first
**Timeline**: Week 5 (Dec 2-10, 2025)

---

## Executive Summary

Extract CDR (Common Data Representation) marshalling and unmarshalling operations from the polyorb-any monolithic module into a dedicated `polyorb-any-cdr.ad[sb]` module. This extraction reduces polyorb-any module size, improves maintainability, and creates a clear separation of concerns between Any container logic and wire format serialization.

**Key Metrics**:
- **Scope**: Extract CDR marshalling operations from polyorb-any.adb
- **Estimated Size**: ~800-1,000 LOC to extract
- **Affected Modules**: 20-30 modules with CDR dependencies
- **Testing**: CORBA interoperability tests (TAO, omniORB, JacORB)
- **Risk Level**: MEDIUM-HIGH (wire format compatibility critical)
- **Timeline**: 7-9 days with daily milestone gates

---

## 1. Context & Motivation

### 1.1 Current State

**Problem**: CDR marshalling logic is embedded within the polyorb-any module, creating tight coupling between:
1. Any container data model (what data is stored)
2. Wire format serialization (how data is transmitted)
3. Type conversion logic (how types are mapped)

**Impact**:
- **Maintainability**: Changes to CDR format require modifying polyorb-any
- **Testability**: Cannot test CDR operations independently from Any logic
- **Reusability**: CDR logic cannot be reused outside Any context
- **Module Size**: Contributes to polyorb-any's "God Class" antipattern

### 1.2 Desired State

**Goal**: Create a dedicated `polyorb-any-cdr` module with:
- Clean interface for marshalling/unmarshalling Any containers
- Zero-overhead delegation from polyorb-any (using `renames` keyword)
- 100% wire format compatibility (no CORBA protocol changes)
- Independent testability with CORBA interoperability suite

**Success Criteria**:
- ✅ All CDR operations extracted to polyorb-any-cdr module
- ✅ polyorb-any.adb reduced by ~800-1,000 LOC
- ✅ All contract tests pass (TAO, omniORB, JacORB interop)
- ✅ Zero performance regression (±2% acceptable)
- ✅ All dependent modules updated and tested

---

## 2. Scope Analysis

### 2.1 Primary Target: polyorb-any.adb

**Estimated CDR Operations to Extract**:

Based on CORBA CDR specification and typical Any implementation patterns:

1. **Marshalling Operations** (estimated ~400 LOC):
   - `Marshall_Any` - Serialize Any container to buffer
   - `Marshall_TypeCode` - Serialize TypeCode to buffer
   - `Marshall_Content` - Serialize content based on type
   - Type-specific marshallers for elementary types
   - Complex type marshallers (struct, union, sequence, array)

2. **Unmarshalling Operations** (estimated ~400 LOC):
   - `Unmarshall_Any` - Deserialize Any container from buffer
   - `Unmarshall_TypeCode` - Deserialize TypeCode from buffer
   - `Unmarshall_Content` - Deserialize content based on type
   - Type-specific unmarshallers for elementary types
   - Complex type unmarshallers (struct, union, sequence, array)

3. **CDR Helper Functions** (estimated ~200 LOC):
   - Alignment calculations
   - Byte order handling (big-endian/little-endian)
   - Encapsulation support
   - String/WString encoding helpers

**Total Estimated Extraction**: ~1,000 LOC

### 2.2 Dependent Modules

**High-Impact Dependencies** (require updates):
```
src/giop/polyorb-protocols-giop*.adb         (GIOP protocol layers use CDR)
src/polyorb-any-nvlist.adb                    (NVList marshalling)
src/polyorb-any-objref.adb                    (Object reference marshalling)
src/corba/corba-orb.adb                       (ORB core CDR operations)
src/corba/corba-context.adb                   (Context marshalling)
src/corba/corba-serverrequest.adb             (Request/response marshalling)
src/dsa/polyorb-dsa_p-*.adb                   (DSA remote call marshalling)
```

**Estimated Impact**: 20-30 modules requiring import updates

### 2.3 Testing Scope

**Critical Test Categories**:

1. **Wire Format Compatibility** (MUST NOT BREAK):
   - Contract tests with TAO (C++ CORBA ORB)
   - Contract tests with omniORB (C++ CORBA ORB)
   - Contract tests with JacORB (Java CORBA ORB)
   - Byte-level wire format validation

2. **Functional Correctness**:
   - Unit tests for each marshaller/unmarshaller
   - Round-trip tests (marshal → unmarshal → verify)
   - Edge cases (empty Any, null references, large data)
   - Error handling (malformed buffers, alignment errors)

3. **Performance Validation**:
   - Benchmark marshalling throughput (ops/second)
   - Measure latency impact (P95, P99)
   - Memory allocation patterns (no regressions)

**Test Count Estimate**: 40-50 tests (25 unit + 15 contract + 10 performance)

---

## 3. Implementation Strategy

### 3.1 Four-Phase Extraction Approach

**Overview**: Incremental extraction with rollback points every 2 days

#### Phase 1: Module Structure Creation (Day 1)
**Duration**: 8 hours
**Deliverable**: Empty module skeleton with interface design

**Steps**:
1. Create `src/polyorb-any-cdr.ads` (specification)
   ```ada
   package PolyORB.Any.CDR is
      pragma Preelaborate;

      -- Marshalling operations
      procedure Marshall_Any (
         Buffer : access PolyORB.Buffers.Buffer_Type;
         Item   : in Any_Container'Class);

      procedure Marshall_TypeCode (
         Buffer : access PolyORB.Buffers.Buffer_Type;
         TC     : in TypeCode.Local_Ref);

      -- Unmarshalling operations
      function Unmarshall_Any (
         Buffer : access PolyORB.Buffers.Buffer_Type)
         return Any_Container'Class;

      function Unmarshall_TypeCode (
         Buffer : access PolyORB.Buffers.Buffer_Type)
         return TypeCode.Local_Ref;

      -- Helper functions
      function Get_CDR_Alignment (
         TC : TypeCode.Local_Ref) return Natural;

   end PolyORB.Any.CDR;
   ```

2. Create `src/polyorb-any-cdr.adb` (body) - initially empty

3. Update build system:
   - Add to `src/polyorb.gpr`
   - Update Makefile.am dependency lists

**Validation**:
```bash
# Clean build
make clean
./configure --enable-debug=yes
make all

# Verify compilation
ls -lh src/polyorb-any-cdr.ali
ls -lh src/polyorb-any-cdr.o
```

**Rollback Point #1**: Delete files, revert commits (<5 minutes)

---

#### Phase 2: Extract Marshalling Operations (Days 2-3)
**Duration**: 16 hours
**Deliverable**: All marshalling operations moved, polyorb-any delegates via `renames`

**Steps**:

1. **Identify marshalling functions in polyorb-any.adb**:
   ```bash
   grep -n "procedure.*Marshall\|function.*Marshall" src/polyorb-any.adb
   ```

2. **Move implementations to polyorb-any-cdr.adb**:
   - Copy marshalling procedure bodies
   - Update dependencies (`with` clauses)
   - Preserve implementation logic exactly (zero changes)

3. **Add delegation in polyorb-any.adb**:
   ```ada
   -- In polyorb-any.adb
   procedure Marshall_Any (
      Buffer : access PolyORB.Buffers.Buffer_Type;
      Item   : in Any_Container'Class)
      renames PolyORB.Any.CDR.Marshall_Any;
   ```

4. **Compile incrementally**:
   ```bash
   # After each 5-10 procedures moved
   gprbuild -P polyorb.gpr src/polyorb-any-cdr.adb
   gprbuild -P polyorb.gpr src/polyorb-any.adb
   ```

**Validation**:
```bash
# Unit tests (if available)
make test-any

# Basic contract test
cd testsuite/corba/interop
./run_marshal_test.sh
```

**Rollback Point #2**: Revert commits, restore from backup (~10 minutes)

---

#### Phase 3: Extract Unmarshalling Operations (Days 4-5)
**Duration**: 16 hours
**Deliverable**: All unmarshalling operations moved, complete CDR module

**Steps**:

1. **Identify unmarshalling functions in polyorb-any.adb**:
   ```bash
   grep -n "procedure.*Unmarshall\|function.*Unmarshall" src/polyorb-any.adb
   ```

2. **Move implementations to polyorb-any-cdr.adb** (same process as Phase 2)

3. **Extract helper functions**:
   - Alignment calculators
   - Byte order helpers
   - Encapsulation support

4. **Add comprehensive logging**:
   ```ada
   pragma Debug (L.Enabled,
      O ("Marshalling Any with TypeCode: " & TypeCode.Image (Get_Type (Item))));
   ```

**Validation**:
```bash
# Full test suite
make test

# Contract tests with all ORBs
cd testsuite/corba/interop
./run_tao_interop.sh
./run_omni_interop.sh
./run_jacorb_interop.sh
```

**Rollback Point #3**: Revert commits, restore from backup (~15 minutes)

---

#### Phase 4: Update Dependents & Performance Validation (Days 6-9)
**Duration**: 24-32 hours
**Deliverable**: All dependent modules updated, all tests pass, performance validated

**Steps**:

1. **Update dependent modules** (Days 6-7):
   ```bash
   # Find all modules importing polyorb-any marshalling
   grep -r "with PolyORB.Any" src/**/*.ad[sb] | \
      grep -v polyorb-any-cdr | \
      cut -d: -f1 | sort -u

   # For each dependent module:
   # 1. Add: with PolyORB.Any.CDR;
   # 2. Update calls if needed (most should be transparent)
   # 3. Compile and test
   ```

2. **Run full test suite** (Day 8):
   ```bash
   # All unit tests
   make test-unit

   # All integration tests
   make test-integration

   # Contract tests (CORBA interoperability)
   make test-contract
   ```

3. **Performance benchmarking** (Day 9):
   ```bash
   # Baseline (before extraction)
   testsuite/performance/benchmark_marshal.sh --baseline

   # After extraction
   testsuite/performance/benchmark_marshal.sh --compare

   # Expected: ±2% variation (zero-cost abstraction)
   ```

4. **Code review checklist**:
   - [ ] All marshalling operations extracted
   - [ ] Zero duplicated code
   - [ ] All `with` clauses correct
   - [ ] No circular dependencies
   - [ ] Logging preserved
   - [ ] Error handling preserved
   - [ ] Comments updated

**Validation**:
```bash
# Final comprehensive check
make clean && make all test
cd testsuite && ./run_all_tests.sh

# Verify polyorb-any size reduction
wc -l src/polyorb-any.adb
# Expected: ~1,600-1,700 LOC (reduced from ~2,600)
```

**Rollback Point #4**: Revert all commits, restore to Task 3 completion state (~20 minutes)

---

## 4. Testing Strategy

### 4.1 Five-Layer Testing Approach

**Layer 1: Compilation Verification**
```bash
# Clean build ensures no missing dependencies
make clean
./configure --enable-debug=yes
make all

# Check for warnings
grep -i "warning\|error" build.log
```

**Layer 2: Unit Tests** (Target: 25 tests)

Example test structure:
```ada
-- testsuite/core/test_any_cdr_marshalling.adb
with PolyORB.Any.CDR;
with PolyORB.Buffers;
with CORBA.Impl;

procedure Test_Marshall_Elementary_Types is
   Buffer : aliased PolyORB.Buffers.Buffer_Type;
   Item   : PolyORB.Any.Any_Container;
begin
   -- Test TC_Long marshalling
   Set_Type (Item, TC_Long);
   Set_Value (Item, CORBA.Long (42));

   PolyORB.Any.CDR.Marshall_Any (Buffer'Access, Item);

   declare
      Result : constant PolyORB.Any.Any_Container :=
         PolyORB.Any.CDR.Unmarshall_Any (Buffer'Access);
   begin
      Assert (Get_Type (Result) = TC_Long);
      Assert (From_Any (Result) = CORBA.Long (42));
   end;
end Test_Marshall_Elementary_Types;
```

**Layer 3: Integration Tests** (Target: 15 tests)

Test categories:
1. Complex type marshalling (struct, union, sequence, array)
2. Nested Any containers
3. Large data sets (1MB+ payloads)
4. Error paths (malformed buffers, alignment errors)

**Layer 4: Contract Tests** (Target: 10 tests)

CORBA interoperability validation:
```bash
# TAO (C++ ORB) interop
testsuite/corba/interop/tao/test_any_marshal.sh

# omniORB (C++ ORB) interop
testsuite/corba/interop/omni/test_any_marshal.sh

# JacORB (Java ORB) interop
testsuite/corba/interop/jacorb/test_any_marshal.sh
```

**Layer 5: Performance Tests** (Target: 5 benchmarks)

Metrics to measure:
- Marshalling throughput (Anys/second)
- Unmarshalling throughput (Anys/second)
- Round-trip latency (P50, P95, P99)
- Memory allocations per operation
- CPU cache efficiency

**Success Threshold**: ±2% variation from baseline

---

## 5. Risk Analysis & Mitigation

### 5.1 Critical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Wire format compatibility broken** | LOW | CRITICAL | Run TAO/omniORB/JacORB contract tests after every phase |
| **Performance regression** | MEDIUM | HIGH | Benchmark after Phase 2, Phase 3, Phase 4; abort if >5% regression |
| **Circular dependency created** | LOW | HIGH | Verify dependency graph after every `with` clause addition |
| **Missed marshaller** | MEDIUM | MEDIUM | Automated grep scan for "Marshall\|Unmarshall" patterns before Phase 4 |
| **Complex type edge cases** | MEDIUM | MEDIUM | Expand contract test coverage for struct/union/sequence edge cases |

### 5.2 Rollback Strategy

**Four Rollback Points** (aligned with phases):

1. **After Phase 1** (<5 min): Delete empty module files, revert commits
2. **After Phase 2** (~10 min): Revert marshalling extraction, restore from Git tag
3. **After Phase 3** (~15 min): Revert unmarshalling extraction, restore from Git tag
4. **After Phase 4** (~20 min): Full rollback to Task 3 completion state

**Rollback Trigger**: Any of:
- Contract test failure (CORBA interop broken)
- Performance regression >5%
- Circular dependency detected
- Critical bug found in extraction

---

## 6. Definition of Done (DoD)

### 6.1 Code Quality

- [ ] All CDR marshalling/unmarshalling operations extracted to polyorb-any-cdr
- [ ] polyorb-any.adb reduced by ~800-1,000 LOC
- [ ] Zero code duplication (DRY principle maintained)
- [ ] All `with` clauses correct and minimal
- [ ] No circular dependencies (verified with gnatcheck)
- [ ] Code follows PolyORB style guidelines

### 6.2 Testing

- [ ] All unit tests pass (25 tests minimum)
- [ ] All integration tests pass (15 tests minimum)
- [ ] All contract tests pass (TAO, omniORB, JacORB)
- [ ] Performance within ±2% baseline (5 benchmarks)
- [ ] Test coverage ≥95% of polyorb-any-cdr module

### 6.3 Documentation

- [ ] Module interface documented (polyorb-any-cdr.ads comments)
- [ ] Migration guide created (for future CDR changes)
- [ ] ADR updated (ADR-004 or new ADR if needed)
- [ ] CHANGELOG.md entry added
- [ ] Commit messages follow conventional commits

### 6.4 Deployment Readiness

- [ ] Clean build from scratch (no warnings)
- [ ] All PolyORB examples compile and run
- [ ] Backward compatibility verified (existing code unaffected)
- [ ] No new SAST findings
- [ ] CI/CD pipeline green (all jobs passing)

---

## 7. Timeline & Milestones

### 7.1 Daily Breakdown

**Week 5: Dec 2-10, 2025** (7-9 working days)

| Day | Phase | Milestone | Hours | Cumulative |
|-----|-------|-----------|-------|------------|
| Mon Dec 2 | Phase 1 | Module skeleton created, builds clean | 8h | 8h |
| Tue Dec 3 | Phase 2 Day 1 | 50% marshalling ops extracted | 8h | 16h |
| Wed Dec 4 | Phase 2 Day 2 | 100% marshalling ops extracted, tests pass | 8h | 24h |
| Thu Dec 5 | Phase 3 Day 1 | 50% unmarshalling ops extracted | 8h | 32h |
| Fri Dec 6 | Phase 3 Day 2 | 100% unmarshalling ops extracted, tests pass | 8h | 40h |
| Mon Dec 9 | Phase 4 Day 1 | 50% dependents updated | 8h | 48h |
| Tue Dec 10 | Phase 4 Day 2 | 100% dependents updated, full test pass | 8h | 56h |
| Wed Dec 11 | Phase 4 Day 3 (buffer) | Performance validated, DoD complete | 8h | 64h |
| Thu Dec 12 | Phase 4 Day 4 (contingency) | Code review, final cleanup | 8h | 72h |

**Total Effort**: 56-72 hours (7-9 days)

### 7.2 Milestone Gates

**Gate 1 (End of Day 1)**:
- ✅ Module skeleton compiles
- ✅ No build system errors
- ⏭️ Proceed to Phase 2

**Gate 2 (End of Day 4)**:
- ✅ All marshalling operations extracted
- ✅ Basic contract tests pass (TAO interop)
- ⏭️ Proceed to Phase 3

**Gate 3 (End of Day 6)**:
- ✅ All unmarshalling operations extracted
- ✅ Full contract tests pass (TAO, omniORB, JacORB)
- ⏭️ Proceed to Phase 4

**Gate 4 (End of Day 10)**:
- ✅ All DoD items checked
- ✅ Performance within ±2% baseline
- ✅ CI/CD pipeline green
- 🎉 **Task 4 Complete**

---

## 8. Dependencies & Blockers

### 8.1 Prerequisites

**MUST BE COMPLETE BEFORE START**:
- ✅ Task 3 (Accessor extraction) fully complete and merged
- ✅ polyorb-any.adb compiles successfully after Task 3
- ✅ All Task 3 tests passing
- ✅ Performance baseline established

### 8.2 External Dependencies

**Tools Required**:
- GCC/GNAT 13+ with Ada 2012 support
- TAO CORBA ORB (for contract tests)
- omniORB (for contract tests)
- JacORB (for contract tests)
- Valgrind (for memory profiling)
- `perf` (for performance analysis)

**Infrastructure Required**:
- CI/CD pipeline with contract test support
- Performance benchmarking environment (dedicated machine)
- CORBA interop test harness

### 8.3 Parallel Work Opportunities

**Can be done in parallel with Task 4**:
- Task 5 planning (Utilities extraction design)
- Security validation (separate test infrastructure)
- Documentation updates (user guides, tutorials)

**CANNOT be done in parallel**:
- Task 5 implementation (depends on Task 4 completion)

---

## 9. Appendix

### 9.1 Example Extraction: Marshall_Any

**Before** (in polyorb-any.adb):
```ada
procedure Marshall_Any (
   Buffer : access PolyORB.Buffers.Buffer_Type;
   Item   : in Any_Container'Class)
is
   TC : constant TypeCode.Local_Ref := Get_Type (Item);
begin
   pragma Debug (L.Enabled,
      O ("Marshalling Any with TC: " & TypeCode.Image (TC)));

   -- Marshal TypeCode first
   Marshall_TypeCode (Buffer, TC);

   -- Then marshal content
   Marshall_Content (Buffer, Item);
end Marshall_Any;
```

**After** (in polyorb-any.adb - delegation):
```ada
procedure Marshall_Any (
   Buffer : access PolyORB.Buffers.Buffer_Type;
   Item   : in Any_Container'Class)
   renames PolyORB.Any.CDR.Marshall_Any;
```

**New location** (in polyorb-any-cdr.adb):
```ada
procedure Marshall_Any (
   Buffer : access PolyORB.Buffers.Buffer_Type;
   Item   : in Any_Container'Class)
is
   TC : constant TypeCode.Local_Ref := Get_Type (Item);
begin
   pragma Debug (L.Enabled,
      O ("Marshalling Any with TC: " & TypeCode.Image (TC)));

   -- Marshal TypeCode first
   Marshall_TypeCode (Buffer, TC);

   -- Then marshal content
   Marshall_Content (Buffer, Item);
end Marshall_Any;
```

**Impact**: Zero runtime overhead (Ada `renames` is compile-time only)

### 9.2 Expected File Sizes

**Before Task 4**:
- `src/polyorb-any.adb`: ~2,600 LOC (after Task 3)
- `src/polyorb-any.ads`: ~1,163 LOC

**After Task 4**:
- `src/polyorb-any.adb`: ~1,600-1,700 LOC (reduced by ~900-1,000)
- `src/polyorb-any.ads`: ~1,100 LOC (minor spec updates)
- `src/polyorb-any-cdr.adb`: ~800-900 LOC (NEW)
- `src/polyorb-any-cdr.ads`: ~100-150 LOC (NEW)

**Total Reduction**: ~900-1,000 LOC extracted

---

## 10. Success Metrics

| Metric | Baseline (Before) | Target (After) | Actual | Status |
|--------|-------------------|----------------|--------|--------|
| polyorb-any.adb LOC | 2,600 | ≤1,700 | TBD | ⏳ |
| Compilation time (polyorb-any) | 45s | ≤48s (+6%) | TBD | ⏳ |
| Contract tests passed | 100% | 100% | TBD | ⏳ |
| Marshall throughput | 10K ops/s | ≥9.8K ops/s (±2%) | TBD | ⏳ |
| Unmarshall throughput | 9.5K ops/s | ≥9.3K ops/s (±2%) | TBD | ⏳ |
| Test coverage (new module) | N/A | ≥95% | TBD | ⏳ |
| SAST findings (new) | 0 | 0 | TBD | ⏳ |

---

**Execution Status**: 🚧 BLOCKED (waiting for Task 3 completion)
**Next Action**: Monitor Task 3 progress, prepare test infrastructure
**Estimated Start Date**: Dec 2, 2025 (assuming Task 3 completes Nov 29)

---

**Document Version**: 1.0
**Last Updated**: 2025-11-17
**Prepared By**: @refactor_agent
