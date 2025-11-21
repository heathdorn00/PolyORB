------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                    P O L Y O R B . A N Y . C D R                         --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--         Copyright (C) 2001-2025, Free Software Foundation, Inc.          --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.                                               --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
--                  PolyORB is maintained by AdaCore                        --
--                     (email: sales@adacore.com)                           --
--                                                                          --
------------------------------------------------------------------------------

--  CDR marshalling/unmarshalling utilities for Any types.
--  This package provides security-hardened helpers for CDR serialization
--  of Any containers, including buffer validation and bounds checking.
--
--  RDB-004 Task 4: CDR Marshalling Module Extraction
--  Security: SEC-001/SEC-002 validation patterns

pragma Ada_2012;

with Ada.Streams;

with PolyORB.Buffers;
with PolyORB.Errors;
with PolyORB.Types;

package PolyORB.Any.CDR is

   use Ada.Streams;
   use PolyORB.Buffers;
   use PolyORB.Errors;

   ----------------------------------
   --  Security Validation Errors  --
   ----------------------------------

   --  SEC-001: Buffer bounds validation
   --  SEC-002: Memory safety checks

   Buffer_Underflow_Error : exception;
   --  Raised when attempting to read beyond buffer bounds

   Alignment_Error : exception;
   --  Raised when buffer position violates type alignment requirements

   Invalid_Length_Error : exception;
   --  Raised when a length field exceeds safe limits

   ------------------------------------------
   --  Security Validation Utilities       --
   ------------------------------------------

   procedure Validate_Buffer_Remaining
     (Buffer   : access Buffer_Type;
      Required : Stream_Element_Count;
      Error    : in out Error_Container);
   --  Validate that Buffer has at least Required bytes remaining.
   --  Sets Marshal_E error if validation fails.
   --  SEC-001: Core bounds check before any read operation.

   function Remaining_Length
     (Buffer : access Buffer_Type) return Stream_Element_Count;
   --  Return the number of bytes remaining in Buffer.
   --  SEC-001: Helper for bounds checking calculations.

   procedure Check_Type_Alignment
     (Buffer    : access Buffer_Type;
      Type_Size : Alignment_Type;
      Error     : in Out Error_Container);
   --  Validate that current buffer position is properly aligned for Type_Size.
   --  Sets Marshal_E error if alignment is violated.
   --  SEC-002: Prevents misaligned memory access.

   ------------------------------------------
   --  Length Validation Utilities         --
   ------------------------------------------

   Max_String_Length : constant := 2 ** 24;
   --  Maximum allowed string length (16 MB) - prevents memory exhaustion

   Max_Sequence_Length : constant := 2 ** 20;
   --  Maximum allowed sequence length (1M elements)

   procedure Validate_String_Length
     (Length : Types.Unsigned_Long;
      Error  : in out Error_Container);
   --  Validate string length is within safe bounds.
   --  SEC-001: Prevents memory exhaustion from malformed data.

   procedure Validate_Sequence_Length
     (Length : Types.Unsigned_Long;
      Error  : in Out Error_Container);
   --  Validate sequence length is within safe bounds.
   --  SEC-001: Prevents memory exhaustion from malformed data.

   ------------------------------------------
   --  Fast Path Marshalling Helpers       --
   ------------------------------------------

   function Fast_Path_Element_Size
     (El_TCK : TCKind) return Types.Unsigned_Long;
   --  Return the element size in bytes for types suitable for fast path
   --  marshalling (Char, Octet, Short, Long, etc.). Returns 0 if the type
   --  is not suitable for fast path.
   --  Note: Extracted from polyorb-representations-cdr.adb

   type Fast_Path_Info is record
      Data_Address : System.Address := System.Null_Address;
      Data_Size    : Stream_Element_Count := 0;
      Alignment    : Alignment_Type := Align_1;
   end record;
   --  Information for fast path (un)marshalling of aggregates

   function Get_Fast_Path_Info
     (ACC    : access Aggregate_Content'Class;
      TC     : TypeCode.Object_Ptr;
      Buffer : access Buffer_Type) return Fast_Path_Info;
   --  Obtain data address, length and CDR alignment for fast path
   --  marshalling of aggregate ACC of type TC from/to Buffer.
   --  Returns null address if fast path is not possible.
   --  Note: Extracted from polyorb-representations-cdr.adb

   ------------------------------------------
   --  Safe Read Wrappers                  --
   ------------------------------------------

   --  These wrappers combine bounds checking with unmarshalling.
   --  Use these instead of direct Unmarshall calls for security.

   function Safe_Unmarshall_Octet
     (Buffer : access Buffer_Type;
      Error  : access Error_Container) return Types.Octet;
   --  Unmarshall Octet with bounds check.
   --  SEC-001: Safe wrapper for single byte read.

   function Safe_Unmarshall_Unsigned_Long
     (Buffer : access Buffer_Type;
      Error  : access Error_Container) return Types.Unsigned_Long;
   --  Unmarshall Unsigned_Long with bounds and alignment check.
   --  SEC-001/SEC-002: Safe wrapper for 4-byte read.

   function Safe_Unmarshall_String_Length
     (Buffer : access Buffer_Type;
      Error  : access Error_Container) return Types.Unsigned_Long;
   --  Unmarshall string length with bounds check and length validation.
   --  SEC-001: Combined bounds check + max length validation.

private

   --  Implementation constants for alignment checks
   Octet_Alignment     : constant Alignment_Type := Align_1;
   Short_Alignment     : constant Alignment_Type := Align_2;
   Long_Alignment      : constant Alignment_Type := Align_4;
   Long_Long_Alignment : constant Alignment_Type := Align_8;

end PolyORB.Any.CDR;
