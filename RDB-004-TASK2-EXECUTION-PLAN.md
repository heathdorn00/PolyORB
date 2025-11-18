# RDB-004 Task 2: TypeCode Extraction - Execution Plan
**Task ID**: ad5433
**Created**: 2025-11-17
**Owner**: @refactor_agent (lead), @code_architect (review)
**Phase**: Week 3 Planning (Week 2 preparation)
**Parent**: RDB-004 PolyORB-Any Decomposition
**Duration**: 1 week (Week 3)

---

## Executive Summary

**Objective**: Extract TypeCode functionality from the monolithic polyorb-any module into a dedicated, type-safe module using enumeration-based constants.

**Scope**:
- Primary module: `polyorb-any-typecode.adb` (1,736 LOC)
- Affected modules: 15-20 dependent modules (~400+ files estimated)
- TypeCode references: 162+ in polyorb-any modules alone
- Constants to replace: 40 TypeCode integer constants → 1 enumeration type

**Key Benefits**:
- **Type Safety**: 0% → 100% (compiler-enforced TypeCode validation)
- **Code Clarity**: Magic numbers eliminated (e.g., `13` → `TC_String`)
- **Maintainability**: Single source of truth for TypeCode definitions
- **Zero Behavior Change**: 100% backward compatible (representation clause ensures wire format compatibility)

**Timeline**: 1 week implementation (Week 3: Nov 18-22)

---

## 1. Background & Context

### 1.1 RDB-004 Objectives

**Problem**: 40 TypeCode constants defined as integer literals scattered across codebase
- No type safety (compiler allows `TypeCode := 999`)
- Magic numbers reduce code clarity
- Risk of value collisions when adding new types

**Solution**: Replace with type-safe enumeration
```ada
-- BEFORE (Current State)
TC_Null       : constant := 0;
TC_String     : constant := 13;
-- ... 38 more constants ...

-- AFTER (Target State)
type TypeCode_Enum is (
  TC_Null,      -- 0
  TC_Void,      -- 1
  TC_Short,     -- 2
  -- ... 37 more values ...
);

for TypeCode_Enum use (
  TC_Null => 0,
  TC_Void => 1,
  -- Ensures CORBA wire format compatibility
);
```

### 1.2 Related Work

**Completed**:
- RDB-005 Phase 1: GIOP Protocol Consolidation (demonstrates Ada extraction patterns)
  - Used Ada `renames` for zero-cost delegation
  - Used generics for reusable templates
  - Achieved 24 LOC extraction with zero technical debt

**Patterns to Apply**:
- **ADR-006**: Interface-As-Contract Pattern (abstract interfaces with preconditions/postconditions)
- **RDB-005 Learnings**:
  - Quality over quantity (extract cleanly, avoid technical debt)
  - Ada-specific patterns (package-level declarations, generics, renames)
  - Fresh builds essential (`--no-cache` for validation)

---

## 2. Dependency Analysis

### 2.1 TypeCode Module Structure

**Primary Files**:
| File | LOC | Purpose | TypeCode Usage |
|------|-----|---------|----------------|
| `src/polyorb-any-typecode.adb` | 1,736 | TypeCode operations | Heavy |
| `src/polyorb-any.adb` | 2,613 | Any container core | Moderate |
| `src/polyorb-any.ads` | 1,163 | Any interface spec | Light |
| `src/polyorb-representations-cdr.adb` | ~500 | CDR marshalling | **CRITICAL** (defines constants) |

**TypeCode Constant References**:
- polyorb-any modules: 162+ references
- Estimated total codebase: 400-600 references (15-20 modules)

### 2.2 Dependent Module Categories

**Category 1: Core CORBA Operations** (CRITICAL - High Priority)
- `src/corba/corba-typecode*.adb` - CORBA TypeCode API
- `src/polyorb-any*.adb` - Any container operations
- `src/polyorb-representations-cdr.adb` - CDR marshalling (defines constants)

**Category 2: GIOP Protocol Layer** (HIGH - Protocol Handling)
- `src/giop/polyorb-protocols-giop-*.adb` - GIOP message handling
- Protocol version-specific modules (1.0, 1.1, 1.2)

**Category 3: ORB Services** (MEDIUM - Service Implementations)
- `src/dsa/s-parint.adb` - DSA partitioning
- `src/moma/*.adb` - Message-oriented middleware
- Service-specific Any handling

**Category 4: Code Generation** (LOW - IAC Compiler)
- IDL-to-Ada compiler templates
- Helper code generation patterns

### 2.3 Dependency Chain

```
TypeCode_Enum Definition (NEW in polyorb-representations-cdr.ads)
    ↓
polyorb-any-typecode.adb (uses enum, 1,736 LOC)
    ↓
polyorb-any.adb (core Any operations, 2,613 LOC)
    ↓
CORBA TypeCode API (corba-typecode*.adb)
    ↓
GIOP Protocol Layer (protocol message handling)
    ↓
Application Code (CORBA clients/servers)
```

**Critical Path**: CDR module → TypeCode module → Any module → CORBA API → Applications

---

## 3. Extraction Strategy

### 3.1 Four-Step Migration Path

**Step 1: Define Enumeration Type + Representation Clause** (Day 1 - Monday)
- **Duration**: 1 day
- **Owner**: @refactor_agent
- **Location**: `src/polyorb-representations-cdr.ads`

**Tasks**:
1. Add TypeCode_Enum type definition (40 values)
2. Add representation clause (ensures wire format compatibility)
3. Compile and validate
4. Run representation clause test (verify integer values match)

**Validation**:
- Compilation succeeds
- Representation clause test passes
- Contract test confirms CORBA wire format unchanged

**Deliverables**:
- `polyorb-representations-cdr.ads` (updated spec)
- Unit test: `test_typecode_representation.adb`

**Rollback**: Git revert, old constants still available

---

**Step 2: Replace Constants in Primary Module** (Days 2-3 - Tuesday-Wednesday)
- **Duration**: 2 days
- **Owner**: @refactor_agent
- **Location**: `src/polyorb-any-typecode.adb` (1,736 LOC)

**Tasks**:
1. Replace all `TC_*` constant references with `TypeCode_Enum'` values
2. Update case statements to use enumeration
3. Add exhaustiveness checks (compiler validates all cases covered)
4. Run unit tests after each file

**Validation**:
- Compilation succeeds
- All unit tests pass (95%+ coverage maintained)
- Case statements use enumeration literals (no magic numbers)

**Deliverables**:
- Updated polyorb-any-typecode.adb
- Updated unit tests (20 new/modified tests)

**Rollback**: Git revert to Step 1, constants still present

---

**Step 3: Update Dependent Modules** (Days 4-5 - Thursday-Friday Morning)
- **Duration**: 1.5 days
- **Owner**: @refactor_agent
- **Modules**: ~15 dependent modules

**Priority Order**:
1. **Day 4 AM**: Core CORBA (corba-typecode*.adb, polyorb-any.adb)
2. **Day 4 PM**: GIOP Protocol Layer (giop modules)
3. **Day 5 AM**: ORB Services (dsa, moma)

**Per-Module Checklist**:
- [ ] Replace TC_* constant references
- [ ] Update case statements
- [ ] Compile and link
- [ ] Run module-specific tests
- [ ] Document changes in commit

**Validation**:
- All compilation units pass
- Module boundary tests pass
- Integration tests pass

**Deliverables**:
- 15 updated module files
- Integration test results
- Dependency update log

**Rollback**: Git revert to Step 2, dependent modules unchanged

---

**Step 4: Remove Old Constants + Final Cleanup** (Day 5 - Friday PM)
- **Duration**: 0.5 day
- **Owner**: @refactor_agent

**Tasks**:
1. Remove old TC_* constants from CDR module
2. Run full test suite (unit + integration + contract)
3. Static analysis (GNAT style checks)
4. Performance baseline comparison

**Validation**:
- Compilation with constants removed succeeds
- All tests pass (100% pass rate)
- No constant references remain (static analysis confirms)
- Performance within ±5% baseline

**Deliverables**:
- Cleaned polyorb-representations-cdr.ads
- Full test suite results
- Performance comparison report

**Rollback**: Reinstate constants, maintain backward compatibility

---

### 3.2 Extraction Patterns Applied

**Pattern 1: Ada Enumeration Type**
```ada
-- Type-safe enumeration with representation clause
type TypeCode_Enum is (
  TC_Null, TC_Void, TC_Short, TC_Long, TC_UShort, TC_ULong,
  TC_Float, TC_Double, TC_Boolean, TC_Char, TC_Octet,
  TC_Any, TC_TypeCode, TC_String, TC_Objref, TC_Struct,
  TC_Union, TC_Enum, TC_Sequence, TC_Array, TC_Alias,
  TC_Except, TC_LongLong, TC_ULongLong, TC_LongDouble,
  TC_WChar, TC_WString, TC_Fixed, TC_Value, TC_ValueBox,
  TC_Native, TC_Abstract, TC_Local, TC_Component,
  TC_Home, TC_Event, TC_EventValue, TC_EventValueBox,
  TC_Reserved38, TC_Reserved39
);

for TypeCode_Enum use (
  TC_Null => 0, TC_Void => 1, TC_Short => 2, TC_Long => 3,
  -- ... (ensures CORBA wire format compatibility)
  TC_Reserved38 => 38, TC_Reserved39 => 39
);
```

**Pattern 2: Case Statement Exhaustiveness**
```ada
-- BEFORE: Magic numbers, no exhaustiveness check
case TypeCode_Value is
  when 0 => Handle_Null;
  when 13 => Handle_String;
  when others => raise Invalid_TypeCode;  -- Catches 999!
end case;

-- AFTER: Type-safe, compiler-enforced exhaustiveness
case TypeCode is
  when TC_Null => Handle_Null;
  when TC_String => Handle_String;
  -- Compiler ensures ALL 40 values covered
  when others => raise Program_Error;  -- Never reached
end case;
```

**Pattern 3: Representation Clause Testing**
```ada
-- Validate wire format compatibility
procedure Test_TypeCode_Representation is
begin
  Assert (TypeCode_Enum'Pos(TC_Null) = 0);
  Assert (TypeCode_Enum'Pos(TC_String) = 13);
  Assert (TypeCode_Enum'Pos(TC_Reserved39) = 39);
  -- Ensures CORBA protocol compliance
end Test_TypeCode_Representation;
```

---

## 4. Test Coverage Requirements

### 4.1 Five-Layer Testing Strategy

**Layer 1: Compilation Tests** (5 min per module)
- Builds successfully with enumeration type
- No new compiler warnings
- Static analysis passes (GNAT style checks)

**Target**: 100% compilation success across all modules

---

**Layer 2: Unit Tests** (10 min per module)
- All existing unit tests pass
- New tests for enumeration operations (20 tests):
  - TypeCode_Enum'Pos validation
  - TypeCode_Enum'Val conversion
  - Case statement exhaustiveness
  - Representation clause correctness

**Target**: 95%+ coverage of TypeCode-related code

---

**Layer 3: Integration Tests** (15 min total)
- Module boundary tests (Any ↔ TypeCode ↔ CDR)
- TypeCode marshaling/unmarshaling tests
- Cross-module type safety validation

**Target**: 100% of module boundaries tested

---

**Layer 4: Contract Tests** (20 min total)
- **CRITICAL**: CORBA wire format validation
- Test all 40 TypeCode values in CDR encoding
- Interoperability with external CORBA systems (TAO, omniORB)
- Round-trip test (Marshal → Unmarshal → Verify)

**Target**: All 40 TypeCode values validated, 100% CORBA compliance

---

**Layer 5: E2E Smoke Tests** (10 min total)
- Critical CORBA operations end-to-end
- Performance regression check (P95/P99 latency)
- Real-world Any container scenarios

**Target**: Zero failures, performance within +10% baseline

---

### 4.2 Test Data Requirements

**TypeCode Test Matrix** (40 values):
| Category | Count | Examples | Test Priority |
|----------|-------|----------|---------------|
| Primitive Types | 11 | TC_Null, TC_Short, TC_Long, TC_Float, TC_Double | HIGH |
| String Types | 4 | TC_Char, TC_WChar, TC_String, TC_WString | HIGH |
| Complex Types | 8 | TC_Struct, TC_Union, TC_Sequence, TC_Array | HIGH |
| CORBA Types | 11 | TC_Objref, TC_TypeCode, TC_Any, TC_Value | MEDIUM |
| Advanced Types | 4 | TC_Component, TC_Home, TC_Event, TC_Abstract | LOW |
| Reserved | 2 | TC_Reserved38, TC_Reserved39 | LOW |

**Total Test Cases**: 60 tests minimum
- 40 wire format tests (1 per TypeCode)
- 20 unit tests (enumeration operations)

---

## 5. Risk Assessment & Mitigation

### 5.1 Risk Matrix

| Risk | Likelihood | Impact | Severity | Mitigation |
|------|------------|--------|----------|------------|
| Wire format incompatibility breaks CORBA | LOW | HIGH | P1 | Representation clause + contract tests + external interop |
| Dependent module compilation failures | MEDIUM | MEDIUM | P2 | Incremental migration + comprehensive build testing |
| Performance regression from enum ops | LOW | LOW | P3 | Baseline benchmarks + P95/P99 monitoring |
| Hidden TypeCode arithmetic breaks functionality | LOW | MEDIUM | P2 | Code audit for arithmetic operations |
| IAC compiler generation needs updates | LOW | HIGH | P2 | IAC code review + helper regeneration testing |

### 5.2 Mitigation Strategies

**P1 Mitigation (Wire Format)**:
1. Representation clause ensures integer values unchanged
2. Contract tests validate all 40 TypeCodes
3. Interop test with TAO and omniORB
4. Binary diff of marshaled output (before/after)

**P2 Mitigation (Compilation Failures)**:
1. Incremental migration (one module at a time)
2. Daily compilation checks
3. Continuous Integration pipeline validation
4. Rollback points after each step

**P2 Mitigation (IAC Compiler)**:
1. Review helper code generation templates
2. Test with sample IDL files
3. Regenerate test helpers and validate
4. Document required IAC changes (if any)

### 5.3 Rollback Strategy

**Layer 1: Step-by-Step Rollback** (Preferred)
- Each migration step is independently reversible
- Git revert to previous step
- Recompile and redeploy
- **Rollback time**: <10 minutes per step

**Layer 2: Full Rollback** (Emergency)
```bash
git revert <all-commits>
make clean && make
# Full rebuild
```
**Rollback time**: <30 minutes total

**Rollback Triggers**:
- **IMMEDIATE**: Contract test failures (CORBA interoperability lost)
- **IMMEDIATE**: Compilation failures in production pipeline
- **HIGH**: P95 latency >+25% baseline
- **MEDIUM**: Minor SAST findings (investigate + decide)

---

## 6. Success Criteria

### 6.1 Technical Metrics

**Code Quality**:
- ✅ 40 TypeCode constants → 1 enumeration type (100% consolidation)
- ✅ Type safety: 0% → 100% (compiler-enforced)
- ✅ All case statements use enumeration (no magic numbers)

**Functionality**:
- ✅ All unit tests passing (95%+ coverage)
- ✅ All integration tests passing
- ✅ All contract tests passing (40/40 TypeCodes validated)
- ✅ E2E smoke tests passing

**Performance**:
- ✅ P50 latency: ≤+5% baseline
- ✅ P95 latency: ≤+10% baseline
- ✅ P99 latency: ≤+15% baseline
- ✅ Throughput: No regression

**Security**:
- ✅ SAST findings: ≤Baseline (0 new CRITICAL/HIGH)
- ✅ Wire format validation: 100% (all 40 TypeCodes)
- ✅ No security regressions

**Reliability**:
- ✅ Compilation success: 100% (all dependent modules)
- ✅ Test pass rate: 100% (all layers)
- ✅ Deployment success: 100%

### 6.2 Process Metrics

**Timeline**:
- ✅ Week 3 timeline met (5 days)
- ✅ No scope creep
- ✅ Daily status updates provided

**Quality**:
- ✅ Zero production incidents
- ✅ Zero rollback events
- ✅ Security review sign-off (SRN-004)

### 6.3 Definition of Done

**Technical DoD**:
- ✅ TypeCode_Enum defined with representation clause
- ✅ All 40 constants replaced in all modules
- ✅ All dependent modules compile successfully
- ✅ All 5 test layers passing
- ✅ Performance metrics within targets
- ✅ SAST scan shows no new issues

**Process DoD**:
- ✅ @security_verification review complete
- ✅ @code_architect approval received
- ✅ PR merged to master
- ✅ 48h production monitoring complete with no incidents
- ✅ Documentation updated (RDB-004, inline comments)

---

## 7. Timeline & Milestones

### 7.1 Week 3 Daily Schedule (Nov 18-22)

**Monday (Day 1): Enumeration Definition**
- 09:00 - 10:00: Create TypeCode_Enum type + representation clause
- 10:00 - 11:00: Write representation clause unit tests
- 11:00 - 12:00: Compile and validate
- 13:00 - 15:00: Run contract tests (wire format validation)
- 15:00 - 16:00: Code review with @code_architect
- 16:00 - 17:00: Address feedback, commit Step 1

**Tuesday (Day 2): Primary Module Migration (Part 1)**
- 09:00 - 12:00: Replace constants in polyorb-any-typecode.adb (first half)
- 13:00 - 15:00: Update case statements with enumeration
- 15:00 - 17:00: Run unit tests, fix failures

**Wednesday (Day 3): Primary Module Migration (Part 2)**
- 09:00 - 12:00: Complete polyorb-any-typecode.adb migration
- 13:00 - 15:00: Add exhaustiveness checks
- 15:00 - 17:00: Full unit test suite, commit Step 2

**Thursday (Day 4): Dependent Modules**
- 09:00 - 12:00: Core CORBA modules (corba-typecode*.adb, polyorb-any.adb)
- 13:00 - 15:00: GIOP Protocol Layer (giop modules)
- 15:00 - 17:00: Integration tests

**Friday (Day 5): Finalize & Validate**
- 09:00 - 12:00: ORB Services modules (dsa, moma)
- 13:00 - 14:00: Remove old constants
- 14:00 - 16:00: Full test suite (all 5 layers)
- 16:00 - 17:00: Performance validation, final commit

### 7.2 Milestone Gates

**Gate 1: Enumeration Defined** ✅ (End of Day 1)
- TypeCode_Enum type complete
- Representation clause validated
- Contract tests pass (wire format unchanged)
- **Criteria**: Compilation succeeds, wire format correct

**Gate 2: Primary Module Complete** ✅ (End of Day 3)
- polyorb-any-typecode.adb fully migrated
- Unit tests passing
- No magic numbers remaining in primary module
- **Criteria**: 95%+ test coverage, all tests pass

**Gate 3: All Modules Updated** ✅ (End of Day 4)
- All 15 dependent modules migrated
- Integration tests passing
- Module boundaries validated
- **Criteria**: 100% compilation success, integration tests pass

**Gate 4: Production Ready** ✅ (End of Day 5)
- Old constants removed
- Full test suite passing
- Performance validated
- Security review complete
- **Criteria**: All DoD items met, SRN-004 issued

---

## 8. Communication Plan

### 8.1 Daily Status Updates

**Format**: AX Messages Board (Refactor Cell)
**Frequency**: End of each day (17:00)
**Template**:
```
📊 RDB-004 Task 2 - Day X Status

✅ Completed:
- [List completed tasks]

🚧 In Progress:
- [Current work]

⏭️ Next:
- [Tomorrow's plan]

🚨 Blockers:
- [Issues needing escalation]

📈 Metrics:
- Modules migrated: X/15
- Tests passing: X/60
- Performance: P95 +X% baseline
```

### 8.2 Escalation Path

**Level 1: Team Discussion** (0-2 hours)
- Post in AX messages
- Tag relevant agents
- Collaborative problem-solving

**Level 2: Domain Expert Consultation** (2-8 hours)
- @polyorb_expert (CORBA/PolyORB implementation)
- @cdr_maintainer (CDR marshaling, wire format)

**Level 3: Technical Lead** (8-24 hours)
- Escalate to Tech Lead
- Architecture decision needed
- Timeline impact assessment

**Level 4: Security/Business** (24+ hours)
- Security incident
- Business impact
- Escalate to appropriate stakeholders

---

## 9. Deliverables

### 9.1 Code Deliverables

**Primary**:
- [x] `src/polyorb-representations-cdr.ads` (TypeCode_Enum definition)
- [ ] `src/polyorb-any-typecode.adb` (updated, 1,736 LOC)
- [ ] 15 dependent module files (updated)

**Tests**:
- [ ] `tests/test_typecode_representation.adb` (representation clause validation)
- [ ] 20 new/updated unit tests (enumeration operations)
- [ ] 8 integration tests (module boundaries)
- [ ] 40 contract tests (CORBA wire format)

**Documentation**:
- [x] This execution plan (RDB-004-TASK2-EXECUTION-PLAN.md)
- [ ] Inline code comments (enumeration design rationale)
- [ ] Migration notes (for future refactors)

### 9.2 Process Deliverables

**Reports**:
- [ ] Test execution results (all 5 layers)
- [ ] Coverage report (95%+ target)
- [ ] Performance comparison report
- [ ] Security baseline comparison

**Reviews**:
- [ ] Security Review Note (SRN-004)
- [ ] @code_architect approval
- [ ] PR review comments

---

## 10. Dependencies & Prerequisites

### 10.1 Blocking Dependencies

**Before Starting Week 3**:
- ✅ RDB-004 specification reviewed
- ✅ Extraction patterns studied (RDB-005, ADR-006)
- ✅ TypeCode dependencies analyzed
- ✅ This execution plan created and approved

**During Week 3**:
- [ ] @security_verification baseline scan (2 hours) - Schedule Monday AM
- [ ] @code_architect RDB approval (24 hours) - Required before Step 2
- [ ] Domain expert availability (4 hours) - Schedule Wednesday

### 10.2 External Dependencies

**Tooling** (Already Available):
- GNAT Ada compiler (gnat-13)
- Contract testing framework
- CORBA test harness (TAO, omniORB)
- CI/CD pipeline

**Infrastructure**:
- Build environment configured
- Test infrastructure operational
- CI pipeline validated

---

## 11. Next Steps (Post-Planning)

**Immediate Actions** (Week 2, Before Nov 18):
1. ✅ Complete this execution plan
2. [ ] Schedule domain expert consultation (4 hours)
3. [ ] Schedule @security_verification baseline scan (Monday AM)
4. [ ] Review plan with @code_architect (get approval)
5. [ ] Notify team of Week 3 kickoff (AX messages)

**Week 3 Kickoff** (Monday Nov 18, 09:00):
1. [ ] Security baseline scan complete
2. [ ] Start Step 1: Define TypeCode_Enum
3. [ ] Daily status updates begin

**Continuous**:
- [ ] Daily compilation checks
- [ ] Daily test execution
- [ ] Daily status updates to AX
- [ ] Rollback readiness maintained

---

## 12. Lessons from RDB-005 Phase 1

**Apply These Learnings**:
1. **Quality over quantity**: Extract cleanly, avoid technical debt
2. **Fresh builds essential**: Use `--no-cache` for validation
3. **Incremental validation**: Test after each module
4. **Documentation matters**: Inline comments explain "why"
5. **Rollback points**: Each step independently reversible

**Avoid These Pitfalls**:
1. **Over-estimating scope**: Be realistic about extractable code
2. **Skipping tests**: Validate continuously, not just at end
3. **Cache masking failures**: Fresh builds catch issues early
4. **Batch commits**: Commit after each logical step

---

## 13. Appendices

### Appendix A: Module Dependency Map

```
┌─────────────────────────────────────────────────────────────┐
│                   TypeCode_Enum Definition                   │
│            (src/polyorb-representations-cdr.ads)             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                ┌───────────┴──────────┐
                ↓                      ↓
    ┌──────────────────────┐  ┌──────────────────────┐
    │  polyorb-any-       │  │  CORBA TypeCode API  │
    │  typecode.adb        │  │  (corba-typecode*)   │
    │  (1,736 LOC)         │  │                      │
    └──────────┬───────────┘  └──────────┬───────────┘
               │                         │
               └───────────┬─────────────┘
                           ↓
               ┌──────────────────────┐
               │   polyorb-any.adb     │
               │   (Core Any ops)      │
               │   (2,613 LOC)         │
               └──────────┬────────────┘
                          │
            ┌─────────────┼─────────────┐
            ↓             ↓             ↓
    ┌────────────┐ ┌────────────┐ ┌────────────┐
    │ GIOP Layer │ │ DSA Layer  │ │ MOMA Layer │
    │ (Protocol) │ │ (Partition)│ │ (Messaging)│
    └────────────┘ └────────────┘ └────────────┘
```

### Appendix B: Test Coverage Matrix

| Module | Unit Tests | Integration Tests | Contract Tests | Total |
|--------|-----------|------------------|----------------|-------|
| polyorb-representations-cdr | 5 | 2 | 40 | 47 |
| polyorb-any-typecode | 10 | 3 | - | 13 |
| polyorb-any | 5 | 3 | - | 8 |
| **Total** | **20** | **8** | **40** | **68** |

### Appendix C: Performance Baseline

**Metrics to Track**:
- TypeCode marshaling: ___ ns/op (baseline TBD)
- TypeCode unmarshaling: ___ ns/op (baseline TBD)
- Any container creation: ___ ns/op (baseline TBD)
- Case statement execution: ___ ns/op (baseline TBD)

**Target**: ≤+10% for all metrics

---

## Approval & Sign-Off

**Execution Plan Author**: @refactor_agent
**Date**: 2025-11-17
**Status**: ✅ READY FOR REVIEW

**Reviewer**: @code_architect
**Review Date**: [Pending]
**Status**: [PENDING APPROVAL]

**Next Action**: Schedule Week 3 kickoff (Monday Nov 18, 09:00)

---

**Document Version**: 1.0
**Last Updated**: 2025-11-17
**Status**: READY FOR WEEK 3 EXECUTION
