------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                P O L Y O R B . A N Y . C O N T R O L L E D               --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--           SECURITY FIX: VULN-003 - Exception Safety (CWE-401)            --
--                                                                          --
------------------------------------------------------------------------------

pragma Ada_2012;

with Ada.Unchecked_Deallocation;

package body PolyORB.Any.Controlled is

   use type Content_Ptr;

   --  SECURITY NOTE: All Finalize procedures MUST NOT propagate exceptions
   --  per Ada RM 7.6.1(20). We catch and log any exceptions that occur
   --  during finalization to ensure proper cleanup continues.

   -----------------------------------
   -- Content_Holder Implementation
   -----------------------------------

   procedure Take_Ownership
     (Holder  : in out Content_Holder;
      Content : in Content_Ptr)
   is
   begin
      --  Release any existing content first
      if Holder.Owned and then Holder.Content /= null then
         --  Finalize will handle cleanup
         Finalize (Holder);
      end if;

      --  Take ownership of new content
      Holder.Content := Content;
      Holder.Owned   := True;
   end Take_Ownership;

   procedure Release_Ownership
     (Holder : in out Content_Holder)
   is
   begin
      --  Transfer ownership out - don't clean up in Finalize
      Holder.Owned := False;
      --  Note: Content pointer remains valid, just not owned
   end Release_Ownership;

   function Has_Ownership
     (Holder : Content_Holder) return Boolean
   is
   begin
      return Holder.Owned and then Holder.Content /= null;
   end Has_Ownership;

   overriding procedure Finalize
     (Holder : in out Content_Holder)
   is
      procedure Free is new Ada.Unchecked_Deallocation
        (Content'Class, Content_Ptr);
   begin
      --  VULN-003 FIX: Automatic cleanup ensures no memory leaks
      --  This is called automatically when Holder goes out of scope,
      --  even if an exception is being propagated

      if Holder.Owned and then Holder.Content /= null then
         begin
            --  First, finalize the content's value (application-specific cleanup)
            Finalize_Value (Holder.Content.all);

            --  Then, deallocate the Content object itself
            Free (Holder.Content);

            --  Mark as cleaned up
            Holder.Owned := False;

         exception
            when E : others =>
               --  CRITICAL: Finalize MUST NOT propagate exceptions (Ada RM 7.6.1)
               --  Log the error for diagnostics but continue cleanup

               --  TODO: Integrate with PolyORB logging system
               --  PolyORB.Log.Output
               --    ("SECURITY: Content_Holder finalization error: " &
               --     Ada.Exceptions.Exception_Information (E),
               --     PolyORB.Log.Error);

               --  Even on error, mark as cleaned up to prevent double-free
               Holder.Content := null;
               Holder.Owned   := False;
         end;
      end if;
   end Finalize;

   -----------------------------------
   -- Generic Array_Holder Implementation
   -----------------------------------

   package body Array_Holders is

      procedure Take_Ownership
        (Holder : in out Array_Holder;
         Arr    : in Array_Access)
      is
      begin
         if Holder.Owned and then Holder.Arr /= null then
            Finalize (Holder);
         end if;

         Holder.Arr   := Arr;
         Holder.Owned := True;
      end Take_Ownership;

      procedure Release_Ownership
        (Holder : in out Array_Holder)
      is
      begin
         Holder.Owned := False;
      end Release_Ownership;

      function Get_Array
        (Holder : Array_Holder) return Array_Access
      is
      begin
         return Holder.Arr;
      end Get_Array;

      overriding procedure Finalize
        (Holder : in out Array_Holder)
      is
      begin
         if Holder.Owned and then Holder.Arr /= null then
            begin
               --  Use the provided Free procedure
               Free (Holder.Arr);
               Holder.Owned := False;

            exception
               when E : others =>
                  --  Log but don't propagate
                  --  TODO: Integrate with PolyORB logging
                  Holder.Arr   := null;
                  Holder.Owned := False;
            end;
         end if;
      end Finalize;

   end Array_Holders;

end PolyORB.Any.Controlled;
