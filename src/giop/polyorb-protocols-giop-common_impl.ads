------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--  P O L Y O R B . P R O T O C O L S . G I O P . C O M M O N _ I M P L   --
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

--  Common implementation utilities for GIOP 1.0, 1.1, and 1.2
--  Extracts duplicate code to reduce maintenance burden and improve consistency

--  RDB-005: GIOP Protocol Consolidation
--  Phase: Week 11 - Foundation (Extract 100% duplicates)
--  Created: 2025-11-09

pragma Ada_2012;

with PolyORB.Buffers;
with PolyORB.Log;
with PolyORB.Objects;
with PolyORB.Types;

package PolyORB.Protocols.GIOP.Common_Impl is

   pragma Elaborate_Body;

   --  Common procedures extracted from GIOP version-specific implementations
   --  to reduce duplication and improve maintainability.

   --  RDB-005 Extraction Phase 1: 100% Duplicate Procedures
   --  Target: Marshall_Locate_Request (GIOP 1.0 & 1.1 only)

   procedure Marshall_Locate_Request
     (Buffer     : Buffers.Buffer_Access;
      Request_Id : Types.Unsigned_Long;
      Object_Key : Objects.Object_Id_Access);
   --  Marshall a LocateRequest message for GIOP 1.0 and 1.1
   --  Note: GIOP 1.2 uses Target_Address instead of Object_Key,
   --  so it requires a different implementation.
   --
   --  Extracted from:
   --  - polyorb-protocols-giop-giop_1_0.adb (lines 771-778)
   --  - polyorb-protocols-giop-giop_1_1.adb (lines 831+)

   --  RDB-005 Extraction Phase 2: Template Methods (99% similar)
   --  Target: Initialize procedure (GIOP 1.0, 1.1, and 1.2)

   generic
      GIOP_Version : PolyORB.Types.Octet;
      with function New_Implem return GIOP_Implem_Access;
   procedure Generic_Initialize;
   --  Template method for GIOP version initialization
   --  Only difference across versions is the GIOP_Version constant
   --
   --  Extracted from:
   --  - polyorb-protocols-giop-giop_1_0.adb (lines 802-804)
   --  - polyorb-protocols-giop-giop_1_1.adb (lines 861-863)
   --  - polyorb-protocols-giop-giop_1_2.adb (lines 1743-1745)

   --  RDB-005 Extraction Phase 2: New_Implem Factory (99% similar)
   --  Target: New_Implem function (GIOP 1.0, 1.1, and 1.2)

   generic
      type Implem_Type is new GIOP_Implem with private;
   function Generic_New_Implem return GIOP_Implem_Access;
   --  Template method for GIOP implementation factory
   --  Only difference across versions is the concrete type instantiated
   --
   --  Extracted from:
   --  - polyorb-protocols-giop-giop_1_0.adb (lines 790-793)
   --  - polyorb-protocols-giop-giop_1_1.adb (lines 850-853)
   --  - polyorb-protocols-giop-giop_1_2.adb (lines 1732-1735)

   --  RDB-005 Extraction Phase 2: Logging Setup (99% similar)
   --  Target: Logging facility setup (GIOP 1.0, 1.1, and 1.2)

   generic
      Version_Suffix : String;
   package Generic_Logging_Setup is
      pragma Elaborate_Body;
      --  Generic logging setup for GIOP versions
      --  Provides O (output) and C (check) procedures/functions
      --
      --  Usage: package Logging is new Common_Impl.Generic_Logging_Setup
      --           (Version_Suffix => "1_0");
      --         use Logging;
      --
      --  Extracted from:
      --  - polyorb-protocols-giop-giop_1_0.adb (lines 69-74)
      --  - polyorb-protocols-giop-giop_1_1.adb (lines 72-77)
      --  - polyorb-protocols-giop-giop_1_2.adb (lines 84-89)

      procedure O (Message : String; Level : PolyORB.Log.Log_Level := PolyORB.Log.Debug);
      function C (Level : PolyORB.Log.Log_Level := PolyORB.Log.Debug) return Boolean;

   end Generic_Logging_Setup;

end PolyORB.Protocols.GIOP.Common_Impl;
