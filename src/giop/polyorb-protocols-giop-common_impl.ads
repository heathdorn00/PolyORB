------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--   P O L Y O R B . P R O T O C O L S . G I O P . C O M M O N _ I M P L    --
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

--  Common implementation routines shared across GIOP versions
--  RDB-005 Phase 1: GIOP Protocol Consolidation

pragma Ada_2012;

with PolyORB.Buffers;
with PolyORB.Objects;
with PolyORB.Types;

package PolyORB.Protocols.GIOP.Common_Impl is

   use PolyORB.Buffers;
   use PolyORB.Objects;
   use PolyORB.Types;

   -----------------------------
   -- Marshall_Locate_Request --
   -----------------------------

   --  Common implementation for GIOP 1.0 and 1.1
   --  Marshalls a LocateRequest message with Request_Id and Object_Key
   --
   --  Extracted from:
   --    - polyorb-protocols-giop-giop_1_0.adb (lines 776-783)
   --    - polyorb-protocols-giop-giop_1_1.adb (lines 836-844)
   --
   --  Note: GIOP 1.2 uses a different signature (Target_Address)
   --        and is NOT extracted

   procedure Marshall_Locate_Request_Common
     (Buffer     : Buffer_Access;
      Request_Id : Types.Unsigned_Long;
      Object_Key : PolyORB.Objects.Object_Id_Access);
   --  Marshall a LocateRequest message
   --
   --  @param Buffer: Output buffer for marshalled data
   --  @param Request_Id: GIOP request identifier
   --  @param Object_Key: Target object key to locate

   ----------------
   -- Initialize --
   ----------------

   --  Generic Initialize procedure template for GIOP version registration
   --
   --  Extracted from:
   --    - polyorb-protocols-giop-giop_1_0.adb (lines 804-807)
   --    - polyorb-protocols-giop-giop_1_1.adb (lines 864-867)
   --    - polyorb-protocols-giop-giop_1_2.adb (lines 1744-1747)
   --
   --  All three implementations are 99% identical, differing only in
   --  the GIOP version constant passed to Global_Register_GIOP_Version

   generic
      Version : GIOP_Version;
      --  GIOP version to register (V1_0, V1_1, or V1_2)

      with function New_Implem return GIOP_Implem_Access;
      --  Factory function that creates the version-specific implementation
   procedure Initialize_Version_Generic;
   --  Register a GIOP version implementation with the PolyORB runtime
   --
   --  @param Version: GIOP version constant (GIOP_V1_0, GIOP_V1_1, or GIOP_V1_2)
   --  @param New_Implem: Factory function for creating the implementation

end PolyORB.Protocols.GIOP.Common_Impl;
