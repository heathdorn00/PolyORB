------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--              P O L Y O R B . U T I L S . V A L I D A T I O N             --
--                                                                          --
--                                 S p e c                                  --
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

--  Input validation utilities for security hardening.
--  Provides centralized validators for common security checks including
--  string length, numeric range, buffer bounds, and sequence counts.
--
--  RDB-008: Input Validation Utility Module
--  Security: CWE-190, CWE-193, CWE-131, CWE-789 mitigations

pragma Ada_2012;

package PolyORB.Utils.Validation is

   pragma Pure;

   --  Exception raised when validation fails
   Validation_Error : exception;

   --------------------------
   --  String Validation   --
   --------------------------

   function Is_Valid_String_Length
     (Str        : String;
      Max_Length : Natural) return Boolean;
   --  Check if string length is within allowed bounds.
   --  Returns True if Str'Length <= Max_Length.
   --  Handles empty strings correctly.
   --  Security: DoS protection against oversized strings (CWE-789)

   procedure Ensure_Valid_Length
     (Str        : String;
      Max_Length : Natural);
   --  Validate string length, raise Validation_Error if invalid.
   --  Security: Same as Is_Valid_String_Length but with exception semantics

   --------------------------
   --  Numeric Validation  --
   --------------------------

   function Is_In_Range
     (Value : Integer;
      Min   : Integer;
      Max   : Integer) return Boolean;
   --  Check if Value is within [Min, Max] inclusive.
   --  Returns True if Min <= Value <= Max.
   --  Handles case where Min > Max (returns False).
   --  Security: Prevents integer boundary attacks (CWE-190)

   --------------------------
   --  Buffer Validation   --
   --------------------------

   function Validate_Buffer_Bounds
     (Offset      : Natural;
      Length      : Natural;
      Buffer_Size : Natural) return Boolean;
   --  Check if buffer access [Offset .. Offset + Length - 1] is valid.
   --  Returns True if Offset + Length <= Buffer_Size.
   --  Uses overflow-safe arithmetic to prevent wraparound.
   --  Security: Memory safety for buffer operations (CWE-131, CWE-193)

   ----------------------------
   --  Sequence Validation   --
   ----------------------------

   function Is_Valid_Sequence_Count
     (Count        : Natural;
      Max_Elements : Natural) return Boolean;
   --  Check if sequence element count is within limits.
   --  Returns True if Count <= Max_Elements.
   --  Security: DoS protection against excessive allocation (CWE-789)

end PolyORB.Utils.Validation;
