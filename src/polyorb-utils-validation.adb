------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--              P O L Y O R B . U T I L S . V A L I D A T I O N             --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2025, Free Software Foundation, Inc.               --
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

--  RDB-008: Input Validation Utility Module
--  Security: CWE-190, CWE-193, CWE-131, CWE-789 mitigations

pragma Ada_2012;

package body PolyORB.Utils.Validation is

   ----------------------------
   --  Is_Valid_String_Length --
   ----------------------------

   function Is_Valid_String_Length
     (Str        : String;
      Max_Length : Natural) return Boolean
   is
   begin
      --  Simple comparison - Str'Length is always Natural (>= 0)
      --  so no overflow risk here
      return Str'Length <= Max_Length;
   end Is_Valid_String_Length;

   -------------------------
   --  Ensure_Valid_Length --
   -------------------------

   procedure Ensure_Valid_Length
     (Str        : String;
      Max_Length : Natural)
   is
   begin
      if not Is_Valid_String_Length (Str, Max_Length) then
         raise Validation_Error with
           "String length" & Natural'Image (Str'Length) &
           " exceeds maximum" & Natural'Image (Max_Length);
      end if;
   end Ensure_Valid_Length;

   -----------------
   --  Is_In_Range --
   -----------------

   function Is_In_Range
     (Value : Integer;
      Min   : Integer;
      Max   : Integer) return Boolean
   is
   begin
      --  Handle invalid range (Min > Max) by returning False
      --  This prevents logic errors from silently passing
      if Min > Max then
         return False;
      end if;

      --  Standard range check - no overflow possible here
      --  since we're just comparing, not computing
      return Value >= Min and then Value <= Max;
   end Is_In_Range;

   ----------------------------
   --  Validate_Buffer_Bounds --
   ----------------------------

   function Validate_Buffer_Bounds
     (Offset      : Natural;
      Length      : Natural;
      Buffer_Size : Natural) return Boolean
   is
   begin
      --  Zero-length access is always valid if offset is in bounds
      if Length = 0 then
         return Offset <= Buffer_Size;
      end if;

      --  CWE-131/CWE-190: Overflow-safe check for Offset + Length
      --  Instead of: Offset + Length <= Buffer_Size (could overflow)
      --  We use:     Buffer_Size - Offset >= Length (safe subtraction)
      --
      --  First check Offset is within buffer to ensure subtraction is safe
      if Offset > Buffer_Size then
         return False;
      end if;

      --  Now Buffer_Size - Offset is safe (no underflow)
      --  Check if remaining space can hold Length bytes
      return Buffer_Size - Offset >= Length;
   end Validate_Buffer_Bounds;

   -----------------------------
   --  Is_Valid_Sequence_Count --
   -----------------------------

   function Is_Valid_Sequence_Count
     (Count        : Natural;
      Max_Elements : Natural) return Boolean
   is
   begin
      --  Simple comparison - both are Natural, no overflow risk
      return Count <= Max_Elements;
   end Is_Valid_Sequence_Count;

end PolyORB.Utils.Validation;
