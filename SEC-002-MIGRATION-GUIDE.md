# SEC-002 Migration Guide: Exception-Safe Memory Management

## Overview
This guide provides patterns for migrating Unchecked_Deallocation usages to exception-safe patterns across the PolyORB codebase.

## Migration Statistics
- **Total Free procedure instantiations**: 86 across 53 files
- **polyorb-any.adb**: 3 sites migrated (COMPLETED)
- **Remaining**: 83 instances across 52 files

## Pattern 1: Content_Holder for Content Types

**Use when**: Allocating Content-derived objects that need automatic cleanup.

**Before**:
```ada
function Allocate_Foo return Content_Ptr is
   Result : constant Foo_Ptr := new Foo_Content;
begin
   Initialize (Foo_Content (Result.all));  -- May raise
   return Content_Ptr (Result);
end Allocate_Foo;
```

**After**:
```ada
function Allocate_Foo return Content_Ptr is
   use PolyORB.Any.Controlled;
   Guard  : Content_Holder;
   Result : Foo_Ptr;
begin
   Result := new Foo_Content;
   Take_Ownership (Guard, Content_Ptr (Result));

   Initialize (Foo_Content (Result.all));  -- Guard cleans up on exception

   Release_Ownership (Guard);
   return Content_Ptr (Result);
end Allocate_Foo;
```

## Pattern 2: Exception Block for Non-Content Types

**Use when**: Allocating objects like Any_Container that are not Content-derived.

**Before**:
```ada
Container := new Any_Container;
Setup_Container (Container.all);  -- May raise
```

**After**:
```ada
Container := new Any_Container;
begin
   Setup_Container (Container.all);  -- May raise
exception
   when others =>
      declare
         procedure Free_Container is
           new PolyORB.Utils.Unchecked_Deallocation.Free
             (Any_Container'Class, Any_Container_Ptr);
      begin
         Free_Container (Container);
      end;
      raise;
end;
```

## Pattern 3: Transactional Pattern for Loop Allocations

**Use when**: Multiple allocations in a loop where partial completion needs cleanup.

**Before**:
```ada
for J in First .. Last loop
   Table (J) := new Element;
   Initialize (Table (J).all);
end loop;
```

**After**:
```ada
declare
   Allocated_Count : Natural := 0;
begin
   for J in First .. Last loop
      Table (J) := new Element;
      Allocated_Count := Allocated_Count + 1;
      Initialize (Table (J).all);
   end loop;
exception
   when others =>
      --  Cleanup all allocated elements
      for J in First .. First + Allocated_Count - 1 loop
         if Table (J) /= null then
            Free_Element (Table (J));
         end if;
      end loop;
      raise;
end;
```

## Files Requiring Migration

### High Priority (Core Any/TypeCode)
- [x] `src/polyorb-any.adb` - 2 instances (COMPLETED)
- [ ] `src/polyorb-any-typecode.adb` - 1 instance
- [ ] `src/polyorb-typecode.adb` - 1 instance

### GIOP Protocol
- [ ] `src/giop/polyorb-protocols-giop.ads` - 3 instances
- [ ] `src/giop/polyorb-protocols-giop-giop_1_0.adb` - 1 instance
- [ ] `src/giop/polyorb-protocols-giop-giop_1_1.adb` - 1 instance
- [ ] `src/giop/polyorb-protocols-giop-giop_1_2.adb` - 2 instances
- [ ] `src/giop/polyorb-representations-cdr-giop_1_1.adb` - 2 instances
- [ ] `src/giop/polyorb-giop_p-tagged_components.adb` - 2 instances

### Security Module
- [ ] `src/security/polyorb-security-authentication_mechanisms.adb` - 2 instances
- [ ] `src/security/polyorb-security-authorization_elements.adb` - 1 instance
- [ ] `src/security/polyorb-security-identities.adb` - 1 instance
- [ ] `src/security/polyorb-qos-targets_security.adb` - 2 instances
- [ ] `src/security/polyorb-qos-clients_security.adb` - 2 instances

### Core Infrastructure
- [ ] `src/polyorb-buffers.adb` - 2 instances
- [ ] `src/polyorb-poa.adb` - 2 instances
- [ ] `src/polyorb-requests.adb` - 1 instance
- [ ] `src/polyorb-annotations.adb` - 1 instance

### Tasking
- [ ] `src/polyorb-tasking-profiles-full_tasking-mutexes.adb` - 2 instances
- [ ] `src/polyorb-tasking-profiles-full_tasking-threads.adb` - 1 instance
- [ ] `src/polyorb-orb-thread_per_session.adb` - 2 instances

## Implementation Notes

1. **Always use classwide types** for access types:
   - `Any_Container'Class` not `Any_Container`
   - `Content'Class` not `Content`

2. **Import requirements**:
   - Add `with PolyORB.Any.Controlled;` for Content_Holder pattern
   - Already have `with PolyORB.Utils.Unchecked_Deallocation;` for Free procedures

3. **Testing**: After each migration, run:
   ```bash
   gnatmake -c -gnatc <file> -Isrc
   ```

4. **Finalize procedures**: Per Ada RM 7.6.1(20), Finalize must NOT propagate exceptions.
   Always wrap cleanup in exception handlers.

## Verification Checklist

For each migrated file:
- [ ] Compiles with `-gnatc` (syntax check)
- [ ] Compiles with `-gnatwa` (all warnings)
- [ ] No new warnings introduced
- [ ] Exception paths properly protected
- [ ] Memory freed on all error paths
