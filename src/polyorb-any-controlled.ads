------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                P O L Y O R B . A N Y . C O N T R O L L E D               --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--           SECURITY FIX: VULN-003 - Exception Safety (CWE-401)            --
--                                                                          --
------------------------------------------------------------------------------

--  Exception-safe resource management using Ada controlled types (RAII pattern)
--  Automatically cleans up allocations on scope exit, even when exceptions occur
--
--  SECURITY IMPACT: Prevents memory leaks from exception paths (CWE-401)
--  COMPLIANCE: CERT ADA MEM52-ADA, OWASP ASVS 14.2.2

pragma Ada_2012;

with Ada.Finalization;
with System;

package PolyORB.Any.Controlled is

   pragma Preelaborate;

   --  NOTE: This is a REFERENCE IMPLEMENTATION for security fix VULN-003
   --  Integration into PolyORB requires adapting to actual Content types

   -----------------------------------
   -- Controlled Content Holder
   -----------------------------------
   --
   --  Wraps a Content_Ptr with automatic cleanup via Finalize
   --  Prevents memory leaks when exceptions occur during Any construction
   --
   --  Usage Pattern:
   --    declare
   --       Guard : Content_Holder;
   --       Ptr : Content_Ptr;
   --    begin
   --       Ptr := new Aggregate_Content;           -- May raise Storage_Error
   --       Take_Ownership (Guard, Ptr);            -- Guard now owns Ptr
   --
   --       -- Perform operations that may raise exceptions
   --       Initialize_Content (Ptr.all);           -- May raise exceptions
   --
   --       -- Success: transfer ownership to result
   --       Result.Content := Ptr;
   --       Release_Ownership (Guard);              -- Don't cleanup on return
   --
   --       return Result;
   --       -- If exception: Guard.Finalize automatically frees Ptr
   --    end;

   type Content_Holder is new Ada.Finalization.Limited_Controlled with private;

   --  Take ownership of dynamically allocated Content
   --  After this call, Finalize will free the Content if still owned
   procedure Take_Ownership
     (Holder  : in out Content_Holder;
      Content : in Content_Ptr);

   --  Release ownership (transfer to another owner)
   --  After this call, Finalize will NOT free the Content
   procedure Release_Ownership
     (Holder : in out Content_Holder);

   --  Check if holder currently owns content
   function Has_Ownership
     (Holder : Content_Holder) return Boolean;

   -----------------------------------
   -- Generic Array Holder
   -----------------------------------
   --
   --  Generic controlled holder for array allocations
   --  Can be instantiated for Member_Array, Element_Vector, etc.

   generic
      type Element_Type is private;
      type Array_Type is array (Positive range <>) of Element_Type;
      type Array_Access is access Array_Type;
      with procedure Free (X : in out Array_Access);
   package Array_Holders is

      type Array_Holder is new Ada.Finalization.Limited_Controlled with private;

      procedure Take_Ownership
        (Holder : in out Array_Holder;
         Arr    : in Array_Access);

      procedure Release_Ownership
        (Holder : in out Array_Holder);

      function Get_Array
        (Holder : Array_Holder) return Array_Access;

   private

      type Array_Holder is new Ada.Finalization.Limited_Controlled with record
         Arr   : Array_Access := null;
         Owned : Boolean := False;
      end record;

      overriding procedure Finalize (Holder : in out Array_Holder);

   end Array_Holders;

private

   type Content_Holder is new Ada.Finalization.Limited_Controlled with record
      Content : Content_Ptr := null;
      Owned   : Boolean := False;
   end record;

   --  Automatic cleanup on scope exit
   --  CRITICAL: This is called automatically by the Ada runtime when the
   --  holder goes out of scope, EVEN if an exception is being propagated
   overriding procedure Finalize (Holder : in out Content_Holder);

end PolyORB.Any.Controlled;
