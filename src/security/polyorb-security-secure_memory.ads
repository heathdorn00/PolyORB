------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--   P O L Y O R B . S E C U R I T Y . S E C U R E _ M E M O R Y            --
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
------------------------------------------------------------------------------

--  Secure memory zeroization operations
--
--  Provides procedures to securely zeroize sensitive data in memory,
--  preventing information leakage through memory dumps or cold boot attacks.
--  Implementation uses volatile writes to ensure compiler cannot optimize
--  away the zeroization operations.
--
--  Security Properties:
--  - Resistant to dead-store elimination (CWE-14)
--  - FIPS 140-2 compliant memory zeroization
--  - Memory barriers ensure completion before return

pragma Ada_2012;

with Ada.Streams;

package PolyORB.Security.Secure_Memory is

   --  Securely zeroize a stream element array
   --  All bytes are overwritten with zero using volatile writes
   --  INV-MEM-001: Prevents information leakage of sensitive data
   procedure Secure_Zero (Buffer : in out Ada.Streams.Stream_Element_Array);

   --  Securely zeroize a string
   --  All characters are overwritten with ASCII.NUL using volatile writes
   --  INV-MEM-001: Prevents information leakage of sensitive data
   procedure Secure_Zero_String (S : in Out String);

end PolyORB.Security.Secure_Memory;
