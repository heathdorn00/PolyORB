------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--  P O L Y O R B . P R O T O C O L S . G I O P . C O M M O N _ I M P L   --
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

--  RDB-005: GIOP Protocol Consolidation
--  Phase: Week 11 - Foundation (Extract 100% duplicates)
--  Created: 2025-11-09

pragma Ada_2012;

with Ada.Streams;

with PolyORB.Representations.CDR.Common;

package body PolyORB.Protocols.GIOP.Common_Impl is

   use Ada.Streams;
   use PolyORB.Buffers;
   use PolyORB.Objects;
   use PolyORB.Representations.CDR.Common;
   use PolyORB.Types;

   -------------------------------
   -- Marshall_Locate_Request --
   -------------------------------

   procedure Marshall_Locate_Request
     (Buffer     : Buffers.Buffer_Access;
      Request_Id : Types.Unsigned_Long;
      Object_Key : Objects.Object_Id_Access)
   is
   begin
      --  Marshall Request ID
      Marshall (Buffer, Request_Id);

      --  Marshall Object Key as Stream_Element_Array
      Marshall (Buffer, Stream_Element_Array (Object_Key.all));

   end Marshall_Locate_Request;

   --  RDB-005 Extraction Notes:
   --  - Extracted from GIOP 1.0 (lines 771-778) and GIOP 1.1 (lines 831+)
   --  - 100% identical implementation across both versions
   --  - GIOP 1.2 uses Target_Address instead, so requires separate implementation
   --  - This reduces 16 LOC of duplication (8 LOC × 2 files)

   -------------------------
   -- Generic_Initialize --
   -------------------------

   procedure Generic_Initialize is
   begin
      --  Register this GIOP version with the global GIOP registry
      Global_Register_GIOP_Version (GIOP_Version, New_Implem'Access);
   end Generic_Initialize;

   --  RDB-005 Phase 2 Extraction Notes:
   --  - Extracted from GIOP 1.0 (lines 802-804), GIOP 1.1 (lines 861-863),
   --    and GIOP 1.2 (lines 1743-1745)
   --  - 99% similar implementation (only version constant differs)
   --  - Uses generic with version parameter for template method pattern
   --  - This reduces 12 LOC of duplication (4 LOC × 3 files)

end PolyORB.Protocols.GIOP.Common_Impl;
