------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--         P O L Y O R B . S E C U R I T Y . A U D I T _ L O G              --
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

--  INV-AUDIT-001: Security Audit Logging Implementation

pragma Ada_2012;

with Ada.Calendar;
with Ada.Calendar.Formatting;
with PolyORB.Log;

package body PolyORB.Security.Audit_Log is

   use Ada.Calendar;
   use Ada.Calendar.Formatting;

   ----------------
   -- Audit_Log --
   ----------------

   procedure Audit_Log
     (Event     : String;
      Object_ID : String;
      Severity  : Log_Level := INFO)
   is
      Timestamp    : constant String := Image (Clock);
      Severity_Str : constant String := Log_Level'Image (Severity);
   begin
      --  Format: [TIMESTAMP] [SEVERITY] [AUDIT] Event: Object_ID
      --  Example: [2025-11-07 10:30:15] [INFO] [AUDIT] Crypto key deallocated: KEY_12345

      PolyORB.Log.Output
        ("[" & Timestamp & "] " &
         "[" & Severity_Str & "] " &
         "[AUDIT] " & Event & ": " & Object_ID,
         PolyORB.Log.Notice);

      --  INV-AUDIT-002: Ensure no sensitive data in logs
      --  Only log identifiers, never key material, credentials, or token values

   end Audit_Log;

   -------------------------------
   -- Audit_Log_Security_Event --
   -------------------------------

   procedure Audit_Log_Security_Event
     (Event     : String;
      Object_ID : String;
      Context   : String := "")
   is
      Full_Event : constant String :=
        (if Context /= "" then Event & " (" & Context & ")"
         else Event);
   begin
      --  Security events are always CRITICAL severity
      --  Example: [2025-11-07 10:30:15] [CRITICAL] [AUDIT]
      --           Attempted deallocation of active session: SESSION_789 (User: admin)

      Audit_Log (Full_Event, Object_ID, CRITICAL);

      --  TODO: Future enhancement - Send to SIEM/security monitoring system
      --  Send_To_SIEM (Event, Object_ID, Context);

   end Audit_Log_Security_Event;

end PolyORB.Security.Audit_Log;
