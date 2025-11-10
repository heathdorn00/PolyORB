------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--   P O L Y O R B . P R O T O C O L S . G I O P . C O M M O N _ I M P L    --
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

--  Common implementation routines shared across GIOP versions
--  RDB-005 Phase 1: GIOP Protocol Consolidation

pragma Ada_2012;

with Ada.Streams;

with PolyORB.Representations.CDR.Common;

package body PolyORB.Protocols.GIOP.Common_Impl is

   use Ada.Streams;
   use PolyORB.Representations.CDR.Common;

   -----------------------------
   -- Marshall_Locate_Request --
   -----------------------------

   procedure Marshall_Locate_Request_Common
     (Buffer     : Buffer_Access;
      Request_Id : Types.Unsigned_Long;
      Object_Key : PolyORB.Objects.Object_Id_Access)
   is
   begin
      --  Marshall request ID
      Marshall (Buffer, Request_Id);

      --  Marshall object key as stream element array
      Marshall (Buffer, Stream_Element_Array (Object_Key.all));
   end Marshall_Locate_Request_Common;

end PolyORB.Protocols.GIOP.Common_Impl;
