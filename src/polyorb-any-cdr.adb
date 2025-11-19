------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                    P O L Y O R B . A N Y . C D R                         --
--                                                                          --
--                                 B o d y                                  --
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

--  RDB-004 Task 4: CDR Marshalling Module Implementation
--  Security: SEC-001/SEC-002 validation patterns

pragma Ada_2012;

with PolyORB.Log;
with PolyORB.Representations.CDR.Common;
with PolyORB.Utils.Buffers;

package body PolyORB.Any.CDR is

   use PolyORB.Log;
   use PolyORB.Types;

   package L is new PolyORB.Log.Facility_Log ("polyorb.any.cdr");
   procedure O (Message : Standard.String; Level : Log_Level := Debug)
     renames L.Output;
   function C (Level : Log_Level := Debug) return Boolean
     renames L.Enabled;

   ------------------------------------------
   --  Security Validation Utilities       --
   ------------------------------------------

   --------------------------------
   --  Validate_Buffer_Remaining --
   --------------------------------

   procedure Validate_Buffer_Remaining
     (Buffer   : access Buffer_Type;
      Required : Stream_Element_Count;
      Error    : in Out Error_Container)
   is
      Remaining : constant Stream_Element_Count := Remaining_Length (Buffer);
   begin
      if Remaining < Required then
         pragma Debug (C, O ("Validate_Buffer_Remaining: need" &
           Required'Img & " bytes, have" & Remaining'Img));

         Throw
           (Error,
            Marshal_E,
            System_Exception_Members'
              (Minor     => 1,  --  Buffer underflow
               Completed => Completed_No));
      end if;
   end Validate_Buffer_Remaining;

   ----------------------
   --  Remaining_Length --
   ----------------------

   function Remaining_Length
     (Buffer : access Buffer_Type) return Stream_Element_Count
   is
   begin
      return PolyORB.Buffers.Remaining (Buffer);
   end Remaining_Length;

   --------------------------
   --  Check_Type_Alignment --
   --------------------------

   procedure Check_Type_Alignment
     (Buffer    : access Buffer_Type;
      Type_Size : Alignment_Type;
      Error     : in Out Error_Container)
   is
      use PolyORB.Utils.Buffers;
      Current_Pos : constant Stream_Element_Count :=
        Stream_Element_Count (CDR_Position (Buffer));

      --  Convert alignment type to numeric value
      Align_Size : Stream_Element_Count;
   begin
      case Type_Size is
         when Align_1 => Align_Size := 1;
         when Align_2 => Align_Size := 2;
         when Align_4 => Align_Size := 4;
         when Align_8 => Align_Size := 8;
      end case;

      if Current_Pos mod Align_Size /= 0 then
         pragma Debug (C, O ("Check_Type_Alignment: position" &
           Current_Pos'Img & " not aligned to" & Align_Size'Img));

         Throw
           (Error,
            Marshal_E,
            System_Exception_Members'
              (Minor     => 2,  --  Alignment violation
               Completed => Completed_No));
      end if;
   end Check_Type_Alignment;

   ------------------------------------------
   --  Length Validation Utilities         --
   ------------------------------------------

   ----------------------------
   --  Validate_String_Length --
   ----------------------------

   procedure Validate_String_Length
     (Length : Types.Unsigned_Long;
      Error  : in Out Error_Container)
   is
   begin
      if Length > Max_String_Length then
         pragma Debug (C, O ("Validate_String_Length: length" &
           Length'Img & " exceeds max" & Max_String_Length'Img));

         Throw
           (Error,
            Marshal_E,
            System_Exception_Members'
              (Minor     => 3,  --  Invalid string length
               Completed => Completed_No));
      end if;
   end Validate_String_Length;

   ------------------------------
   --  Validate_Sequence_Length --
   ------------------------------

   procedure Validate_Sequence_Length
     (Length : Types.Unsigned_Long;
      Error  : in Out Error_Container)
   is
   begin
      if Length > Max_Sequence_Length then
         pragma Debug (C, O ("Validate_Sequence_Length: length" &
           Length'Img & " exceeds max" & Max_Sequence_Length'Img));

         Throw
           (Error,
            Marshal_E,
            System_Exception_Members'
              (Minor     => 4,  --  Invalid sequence length
               Completed => Completed_No));
      end if;
   end Validate_Sequence_Length;

   ------------------------------------------
   --  Fast Path Marshalling Helpers       --
   ------------------------------------------

   ----------------------------
   --  Fast_Path_Element_Size --
   ----------------------------

   function Fast_Path_Element_Size
     (El_TCK : TCKind) return Types.Unsigned_Long
   is
   begin
      case El_TCK is
         when Tk_Char | Tk_Octet =>
            return 1;

         when Tk_Short | Tk_Ushort =>
            return 2;

         when Tk_Long | Tk_Ulong =>
            return 4;

         when others =>
            return 0;
      end case;
   end Fast_Path_Element_Size;

   ------------------------
   --  Get_Fast_Path_Info --
   ------------------------

   function Get_Fast_Path_Info
     (ACC    : access Aggregate_Content'Class;
      TC     : TypeCode.Object_Ptr;
      Buffer : access Buffer_Type) return Fast_Path_Info
   is
      pragma Unreferenced (ACC, TC, Buffer);

      Result : Fast_Path_Info;
   begin
      --  Fast path marshalling requires direct access to aggregate
      --  underlying data storage. This is a placeholder implementation
      --  that returns null address (no fast path available).
      --
      --  Future enhancement: Implement actual fast path when aggregate
      --  content types provide Get_Data_Address primitive operation.
      --
      --  The security-hardened approach in this module prioritizes
      --  correctness over performance, so per-element marshalling
      --  with bounds checking is the default.

      return Result;
   end Get_Fast_Path_Info;

   ------------------------------------------
   --  Safe Read Wrappers                  --
   ------------------------------------------

   ---------------------------
   --  Safe_Unmarshall_Octet --
   ---------------------------

   function Safe_Unmarshall_Octet
     (Buffer : access Buffer_Type;
      Error  : access Error_Container) return Types.Octet
   is
      use PolyORB.Representations.CDR.Common;
   begin
      Validate_Buffer_Remaining (Buffer, 1, Error.all);
      if Found (Error.all) then
         return 0;
      end if;

      return Unmarshall (Buffer);
   end Safe_Unmarshall_Octet;

   ----------------------------------
   --  Safe_Unmarshall_Unsigned_Long --
   ----------------------------------

   function Safe_Unmarshall_Unsigned_Long
     (Buffer : access Buffer_Type;
      Error  : access Error_Container) return Types.Unsigned_Long
   is
      use PolyORB.Representations.CDR.Common;
   begin
      --  Check alignment first
      Check_Type_Alignment (Buffer, Long_Alignment, Error.all);
      if Found (Error.all) then
         return 0;
      end if;

      --  Then check bounds
      Validate_Buffer_Remaining (Buffer, 4, Error.all);
      if Found (Error.all) then
         return 0;
      end if;

      return Unmarshall (Buffer);
   end Safe_Unmarshall_Unsigned_Long;

   ----------------------------------
   --  Safe_Unmarshall_String_Length --
   ----------------------------------

   function Safe_Unmarshall_String_Length
     (Buffer : access Buffer_Type;
      Error  : access Error_Container) return Types.Unsigned_Long
   is
      Length : Types.Unsigned_Long;
   begin
      --  Unmarshall the length with bounds/alignment check
      Length := Safe_Unmarshall_Unsigned_Long (Buffer, Error);
      if Found (Error.all) then
         return 0;
      end if;

      --  Validate the length is within safe limits
      Validate_String_Length (Length, Error.all);
      if Found (Error.all) then
         return 0;
      end if;

      return Length;
   end Safe_Unmarshall_String_Length;

end PolyORB.Any.CDR;
