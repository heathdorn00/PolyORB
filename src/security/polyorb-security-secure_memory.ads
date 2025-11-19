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

--  Specification of secure memory zeroization operations
--
--  This package provides procedures to securely zeroize memory buffers
--  and strings, ensuring that sensitive data is overwritten and cannot
--  be recovered after deallocation. The zeroization operations are
--  designed to be resistant to compiler optimizations.

pragma Ada_2012;

with Ada.Streams;

package PolyORB.Security.Secure_Memory is

   pragma Preelaborate;

   -----------------
   -- Secure_Zero --
   -----------------

   procedure Secure_Zero (Buffer : in out Ada.Streams.Stream_Element_Array);
   --  Securely zeroizes the given byte array.
   --  Ensures that the memory is overwritten with zeros and that
   --  compiler optimizations do not remove this operation.

   ------------------------
   -- Secure_Zero_String --
   ------------------------

   procedure Secure_Zero_String (S : in out String);
   --  Securely zeroizes the given string.
   --  Ensures that the string's memory is overwritten with null characters
   --  and that compiler optimizations do not remove this operation.

end PolyORB.Security.Secure_Memory;
