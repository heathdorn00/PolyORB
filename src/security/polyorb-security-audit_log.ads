------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--         P O L Y O R B . S E C U R I T Y . A U D I T _ L O G              --
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

--  INV-AUDIT-001: Security Audit Logging
--  Provides audit logging for CRITICAL security object deallocations
--  Compliance: SOC2 CC6.1, GDPR Art 32, NIST 800-53 AU-2

pragma Ada_2012;

package PolyORB.Security.Audit_Log is

   --  Note: Cannot use Preelaborate due to Ada.Calendar dependency in body

   --  Log severity levels
   type Log_Level is (DEBUG, INFO, WARNING, CRITICAL);

   --  Standard audit logging for security events
   --  INV-AUDIT-001: Logs deallocation of CRITICAL security objects
   procedure Audit_Log
     (Event     : String;
      Object_ID : String;
      Severity  : Log_Level := INFO);
   --  Format: [TIMESTAMP] [SEVERITY] [AUDIT] Event: Object_ID

   --  Security event logging (elevated severity)
   --  INV-SESSION-004: Logs attempted deallocation of active sessions
   procedure Audit_Log_Security_Event
     (Event     : String;
      Object_ID : String;
      Context   : String := "");
   --  Always logs at CRITICAL severity
   --  Format: [TIMESTAMP] [CRITICAL] [AUDIT] Event: Object_ID (Context)

end PolyORB.Security.Audit_Log;
