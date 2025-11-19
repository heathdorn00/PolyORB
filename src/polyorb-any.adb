------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                          P O L Y O R B . A N Y                           --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2001-2022, Free Software Foundation, Inc.          --
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

pragma Ada_2012;

with Ada.Exceptions;
with Ada.Strings.Fixed;
with Ada.Tags;
with PolyORB.Utils.Unchecked_Deallocation;

with PolyORB.Log;
with PolyORB.Utils.Dynamic_Tables;

with System.Address_Image;

package body PolyORB.Any is

   use PolyORB.Log;
   use PolyORB.Types;
   use type System.Address;

   package L is new PolyORB.Log.Facility_Log ("polyorb.any");
   procedure O (Message : Standard.String; Level : Log_Level := Debug)
     renames L.Output;
   function C (Level : Log_Level := Debug) return Boolean
     renames L.Enabled;

   -----------------------
   --  Local subprograms --
   -----------------------

   procedure Free is new PolyORB.Utils.Unchecked_Deallocation.Free
     (Object => Content'Class,
      Name => Content_Ptr);

   procedure Move_Any_Value (Dst_C, Src_C : in out Any_Container'Class);
   --  Transfer the value of Src_C to Dst_C; Src_C is empty upon return.
   --  Foreign status is transferred from Src_C to Dst_C. The previous
   --  contents of Dst_C are deallocated if appropriate.

   function Any_Container_Eq
     (TC           : TypeCode.Object_Ptr;
      Left, Right  : Any_Container'Class) return Boolean;
   --   Test equality between Left and Right, Any containers with type TC.
   --   Note: the actual typecode set on Left and Right is ignored.

   function Agg_Container_Eq
     (TCK          : TCKind;
      TC           : TypeCode.Object_Ptr;
      Left, Right  : Any_Container'Class) return Boolean;
   --   Helper for Any_Container_Eq, handles the case of aggregates

   type Aggregate_Content_Ptr is access all Aggregate_Content'Class;


   -------------------
   --  Accessor_Impl --
   -------------------

   --   Nested package containing all accessor implementations
   --   RDB-004 Task 3: Accessor Extraction Pattern (ADR-005)
   --
   --   This package encapsulates all accessor function implementations for
   --   the PolyORB.Any module. All public accessors in the parent package
   --   delegate to this implementation package.
   --
   --   Total public accessors: 109 declarations
   --     - From_Any functions: 39
   --         (17 for Any_Container'Class, 19 for Any, 3 for Standard)
   --     - To_Any functions: 20
   --     - Set_Any_Value procedures: 20
   --     - Get_Aggregate functions: 8 (1 count + 7 element accessors)
   --     - Set_Aggregate procedures: 2 (non-overriding variants)
   --     - Wrap functions: 19

   package Accessor_Impl is

      ----------------------------------------
      --  From_Any Functions (39 declarations)
      ----------------------------------------

      --   From_Any (Any_Container'Class) overloads - 17 declarations

      function From_Any (C : Any_Container'Class) return Types.Octet;

      function From_Any (C : Any_Container'Class) return Types.Short;

      function From_Any (C : Any_Container'Class) return Types.Long;

      function From_Any (C : Any_Container'Class) return Types.Long_Long;

      function From_Any (C : Any_Container'Class) return Types.Unsigned_Short;

      function From_Any (C : Any_Container'Class) return Types.Unsigned_Long;

      function From_Any
        (C : Any_Container'Class) return Types.Unsigned_Long_Long;

      function From_Any (C : Any_Container'Class) return Types.Boolean;

      function From_Any (C : Any_Container'Class) return Types.Char;

      function From_Any (C : Any_Container'Class) return Types.Wchar;

      function From_Any (C : Any_Container'Class) return Types.Float;

      function From_Any (C : Any_Container'Class) return Types.Double;

      function From_Any (C : Any_Container'Class) return Types.Long_Double;

      function From_Any (C : Any_Container'Class) return Types.String;

      function From_Any (C : Any_Container'Class) return Types.Wide_String;

      function From_Any (C : Any_Container'Class) return Any;

      function From_Any (C : Any_Container'Class) return TypeCode.Local_Ref;

      --   From_Any (Any) overloads - 19 declarations

      function From_Any (A : Any) return Types.Octet;

      function From_Any (A : Any) return Types.Short;

      function From_Any (A : Any) return Types.Long;

      function From_Any (A : Any) return Types.Long_Long;

      function From_Any (A : Any) return Types.Unsigned_Short;

      function From_Any (A : Any) return Types.Unsigned_Long;

      function From_Any (A : Any) return Types.Unsigned_Long_Long;

      function From_Any (A : Any) return Types.Boolean;

      function From_Any (A : Any) return Types.Char;

      function From_Any (A : Any) return Types.Wchar;

      function From_Any (A : Any) return Types.Float;

      function From_Any (A : Any) return Types.Double;

      function From_Any (A : Any) return Types.Long_Double;

      function From_Any (A : Any) return Types.String;

      function From_Any (A : Any) return Types.Wide_String;

      function From_Any (A : Any) return Any;

      function From_Any (A : Any) return TypeCode.Local_Ref;

      function From_Any (A : Any) return Ada.Strings.Superbounded.Super_String;

      function From_Any
        (A : Any) return Ada.Strings.Wide_Superbounded.Super_String;

      --   From_Any (Standard types) - 3 declarations

      function From_Any (C : Any_Container'Class) return Standard.String;

      function From_Any (C : Any_Container'Class) return Standard.Wide_String;

      function From_Any (A : Any) return Standard.String;

      function From_Any (A : Any) return Standard.Wide_String;

      --------------------------------------
      --  To_Any Functions (20 declarations)
      --------------------------------------

      function To_Any (X : Types.Octet) return Any;

      function To_Any (X : Types.Short) return Any;

      function To_Any (X : Types.Long) return Any;

      function To_Any (X : Types.Long_Long) return Any;

      function To_Any (X : Types.Unsigned_Short) return Any;

      function To_Any (X : Types.Unsigned_Long) return Any;

      function To_Any (X : Types.Unsigned_Long_Long) return Any;

      function To_Any (X : Types.Boolean) return Any;

      function To_Any (X : Types.Char) return Any;

      function To_Any (X : Types.Wchar) return Any;

      function To_Any (X : Types.Float) return Any;

      function To_Any (X : Types.Double) return Any;

      function To_Any (X : Types.Long_Double) return Any;

      function To_Any (X : Types.String) return Any;

      function To_Any (X : Types.Wide_String) return Any;

      function To_Any (X : Any) return Any;

      function To_Any (X : TypeCode.Local_Ref) return Any;

      function To_Any
        (X  : Ada.Strings.Superbounded.Super_String;
         TC : access function return TypeCode.Local_Ref)
         return Any;

      function To_Any
        (X  : Ada.Strings.Wide_Superbounded.Super_String;
         TC : access function return TypeCode.Local_Ref)
         return Any;

      function To_Any (X : Standard.String) return Any;

      ------------------------------------------------
      --  Set_Any_Value Procedures (20 declarations)
      ------------------------------------------------

      procedure Set_Any_Value
        (X : Types.Short;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.Long;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.Long_Long;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.Unsigned_Short;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.Unsigned_Long;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.Unsigned_Long_Long;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.Float;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.Double;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.Long_Double;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.Boolean;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.Char;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.Wchar;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.Octet;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Any;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : TypeCode.Local_Ref;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.String;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Types.Wide_String;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X : Standard.String;
         C : in out Any_Container'Class);

      procedure Set_Any_Value
        (X     : String;
         Bound : Positive;
         C     : in out Any_Container'Class);

      procedure Set_Any_Value
        (X     : Wide_String;
         Bound : Positive;
         C     : in out Any_Container'Class);

      ----------------------------------------------
      --  Get_Aggregate Functions (8 declarations)
      ----------------------------------------------

      --   Get_Aggregate_Count - 1 declaration

      function Get_Aggregate_Count (Value : Any) return Unsigned_Long;

      --   Get_Aggregate_Element - 7 declarations

      function Get_Aggregate_Element
        (ACC   : not null access Aggregate_Content'Class;
         TC    : TypeCode.Local_Ref;
         Index : Unsigned_Long;
         Mech  : not null access Mechanism)
         return Content'Class;

      function Get_Aggregate_Element
        (Value : Any;
         TC    : TypeCode.Local_Ref;
         Index : Unsigned_Long)
         return Any;

      function Get_Aggregate_Element
        (Value : Any;
         TC    : TypeCode.Object_Ptr;
         Index : Unsigned_Long)
         return Any;

      function Get_Aggregate_Element
        (Value : Any;
         Index : Unsigned_Long)
         return Types.Unsigned_Long;

      function Get_Aggregate_Element
        (Value : Any_Container'Class;
         Index : Unsigned_Long)
         return Types.Unsigned_Long;

      function Get_Aggregate_Element
        (Value : Any;
         Index : Unsigned_Long)
         return Types.Octet;

      function Get_Aggregate_Element
        (Value : Any_Container'Class;
         Index : Unsigned_Long)
         return Types.Octet;

      ------------------------------------------------
      --  Set_Aggregate Procedures (2 declarations)
      ------------------------------------------------

      procedure Set_Aggregate_Element
        (ACC    : in out Aggregate_Content'Class;
         TC     : TypeCode.Local_Ref;
         Index  : Unsigned_Long;
         From_C : in out Any_Container'Class);

      --  NOTE: Set_Aggregate_Element (Aggregate_Content, Object_Ptr)
      --  base implementation is NOT in Accessor_Impl - it remains in
      --  main body as utility function

      -------------------------------------
      --  Wrap Functions (19 declarations)
      -------------------------------------

      function Wrap (X : not null access Types.Octet) return Content'Class;

      function Wrap (X : not null access Types.Short) return Content'Class;

      function Wrap (X : not null access Types.Long) return Content'Class;

      function Wrap (X : not null access Types.Long_Long) return Content'Class;

      function Wrap
        (X : not null access Types.Unsigned_Short) return Content'Class;

      function Wrap
        (X : not null access Types.Unsigned_Long) return Content'Class;

      function Wrap
        (X : not null access Types.Unsigned_Long_Long)
         return Content'Class;

      function Wrap (X : not null access Types.Boolean) return Content'Class;

      function Wrap (X : not null access Types.Char) return Content'Class;

      function Wrap (X : not null access Types.Wchar) return Content'Class;

      function Wrap (X : not null access Types.Float) return Content'Class;

      function Wrap (X : not null access Types.Double) return Content'Class;

      function Wrap
        (X : not null access Types.Long_Double) return Content'Class;

      function Wrap
        (X : not null access Types.String) return Content'Class;

      function Wrap
        (X : not null access Types.Wide_String) return Content'Class;

      function Wrap (X : not null access Any) return Content'Class;

      function Wrap
        (X : not null access TypeCode.Local_Ref) return Content'Class;

      function Wrap
        (X : not null access Ada.Strings.Superbounded.Super_String)
         return Content'Class;

      function Wrap
        (X : not null access Ada.Strings.Wide_Superbounded.Super_String)
         return Content'Class;

   end Accessor_Impl;


   --------------------
   --  Elementary_Any --
   --------------------

   package body Elementary_Any is

      Kind : TCKind renames PTC.Kind;

      type T_Content_Ptr is access all T_Content;

      procedure Free is new PolyORB.Utils.Unchecked_Deallocation.Free
        (Object => T,
         Name => T_Ptr);

      procedure Kind_Check (C : Any_Container'Class);
      pragma Inline (Kind_Check);

      -----------
      --  Clone --
      -----------

      overriding function Clone
        (CC   : T_Content;
         Into : Content_Ptr := null) return Content_Ptr
      is
      begin
         if Into /= null then
            T_Content (Into.all).V.all := CC.V.all;
            return Into;
         end if;
         return new T_Content'(Content with V => new T'(CC.V.all));
      end Clone;

      --------------------
      --  Finalize_Value --
      --------------------

      overriding procedure Finalize_Value (CC : in out T_Content) is
      begin
         Free (CC.V);
      end Finalize_Value;

      --------------
      --  From_Any --
      --------------

      function From_Any (C : Any_Container'Class) return T is
         use Ada.Tags;
      begin
         Kind_Check (C);
         return T_Content_Ptr (C.The_Value).V.all;
      exception
         when E : Constraint_Error =>
            pragma Debug (L.Enabled,
              O ("C_E (" & Ada.Exceptions.Exception_Message (E)
                 & ") raised in generic elementary From_Any, expected content "
                 & External_Tag (T_Content'Tag)
                 & ", found " & External_Tag (C.The_Value'Tag)));
            raise;
      end From_Any;

      ---------------------------
      --  Get_Aggregate_Element --
      ---------------------------

      function Get_Aggregate_Element
        (Value : Any_Container'Class;
         Index : Unsigned_Long) return T
      is
         CA_Ptr : constant Aggregate_Content_Ptr :=
           Aggregate_Content_Ptr (Value.The_Value);
         M : aliased Mechanism := By_Value;

         CC  : constant Content'Class :=
                 Get_Aggregate_Element (CA_Ptr, PTC, Index, M'Access);
      begin
         return T_Content (CC).V.all;
      end Get_Aggregate_Element;

      ---------------------------
      --  Get_Aggregate_Element --
      ---------------------------

      function Get_Aggregate_Element
        (Value : Any;
         Index : Unsigned_Long) return T
      is
      begin
         return Get_Aggregate_Element (Get_Container (Value).all, Index);
      end Get_Aggregate_Element;

      ----------------
      --  Kind_Check --
      ----------------

      procedure Kind_Check (C : Any_Container'Class) is
      begin
         if TypeCode.Kind (Unwind_Typedefs (Get_Type_Obj (C))) /= Kind then
            raise Constraint_Error;
         end if;
      end Kind_Check;

      -------------------
      --  Set_Any_Value --
      -------------------

      procedure Set_Any_Value (X : T; C : in out Any_Container'Class) is
      begin
         Kind_Check (C);

         if C.The_Value = null then
            C.The_Value := new T_Content'(V => new T'(X));
            C.Foreign   := False;

         else
            T_Content_Ptr (C.The_Value).V.all := X;
         end if;

         C.Is_Finalized := False;
      end Set_Any_Value;

      ------------------------
      --  Unchecked_From_Any --
      ------------------------

      function Unchecked_From_Any (C : Any_Container'Class) return T is
      begin
         return T_Content_Ptr (C.The_Value).V.all;
      end Unchecked_From_Any;

      ---------------------
      --  Unchecked_Get_V --
      ---------------------

      function Unchecked_Get_V (X : not null access T_Content) return T_Ptr is
      begin
         return X.V;
      end Unchecked_Get_V;

      ---------------------
      --  Unchecked_Get_V --
      ---------------------

      overriding function Unchecked_Get_V
        (X : not null access T_Content) return System.Address
      is
      begin
         return X.V.all'Address;
      end Unchecked_Get_V;

      ----------
      --  Wrap --
      ----------

      function Wrap (X : not null access T) return Content'Class is
      begin
         return T_Content'(V => X.all'Unchecked_Access);
      end Wrap;

   end Elementary_Any;

   ------------------------------
   --  Elementary_Any instances --
   ------------------------------

   --   The following two bodies are needed early for elaboration of
   --   Elementary_Any instances

   ----------------
   --  From_Any_G --
   ----------------

   function From_Any_G (A : Any) return T is
   begin
      return From_Any (Get_Container (A).all);
   end From_Any_G;

   --------------
   --  To_Any_G --
   --------------

   function To_Any_G (X : T) return Any is
   begin
      return A : Any do
         Set_Type (A, TC);
         Set_Any_Value (X, Get_Container (A).all);
      end return;
   end To_Any_G;

   package Elementary_Any_Octet is
     new Elementary_Any (Types.Octet, TypeCode.PTC_Octet'Access);
   package Elementary_Any_Short is
     new Elementary_Any (Types.Short, TypeCode.PTC_Short'Access);
   package Elementary_Any_Long is
     new Elementary_Any (Types.Long, TypeCode.PTC_Long'Access);
   package Elementary_Any_Long_Long is
     new Elementary_Any (Types.Long_Long, TypeCode.PTC_Long_Long'Access);
   package Elementary_Any_UShort is
     new Elementary_Any (Types.Unsigned_Short,
                         TypeCode.PTC_Unsigned_Short'Access);
   package Elementary_Any_ULong is
     new Elementary_Any (Types.Unsigned_Long,
                         TypeCode.PTC_Unsigned_Long'Access);
   package Elementary_Any_ULong_Long is
     new Elementary_Any (Types.Unsigned_Long_Long,
                         TypeCode.PTC_Unsigned_Long_Long'Access);
   package Elementary_Any_Boolean is
     new Elementary_Any (Types.Boolean, TypeCode.PTC_Boolean'Access);
   package Elementary_Any_Char is
     new Elementary_Any (Types.Char, TypeCode.PTC_Char'Access);
   package Elementary_Any_Wchar is
     new Elementary_Any (Types.Wchar, TypeCode.PTC_Wchar'Access);
   package Elementary_Any_Float is
     new Elementary_Any (Types.Float, TypeCode.PTC_Float'Access);
   package Elementary_Any_Double is
     new Elementary_Any (Types.Double, TypeCode.PTC_Double'Access);
   package Elementary_Any_Long_Double is
     new Elementary_Any (Types.Long_Double, TypeCode.PTC_Long_Double'Access);
   package Elementary_Any_String is
     new Elementary_Any (Types.String, TypeCode.PTC_String'Access);
   package Elementary_Any_Wide_String is
     new Elementary_Any (Types.Wide_String, TypeCode.PTC_Wide_String'Access);

   --   Wrong typecodes used below, should use bounded typecodes???

   package Elementary_Any_Bounded_String is
     new Elementary_Any (Ada.Strings.Superbounded.Super_String,
                         TypeCode.PTC_String'Access);
   package Elementary_Any_Bounded_Wide_String is
     new Elementary_Any (Ada.Strings.Wide_Superbounded.Super_String,
                         TypeCode.PTC_Wide_String'Access);

   package Elementary_Any_Any is
     new Elementary_Any (Any, TypeCode.PTC_Any'Access);
   package Elementary_Any_TypeCode is
     new Elementary_Any (TypeCode.Local_Ref, TypeCode.PTC_TypeCode'Access);


   package body Accessor_Impl is separate;

   ---------------------------------
   --  'Aggregate' content wrapper --
   ---------------------------------

   --   While an aggregate is constructed, its contents are stored as a
   --   chained list.
   --   Once the construction is completed (i.e. the length of the list won't
   --   grow anymore), the list is converted to an array (to speed up access
   --   to random elements) and the aggegate is frozen (i.e. no elements can
   --   be added to it). Actually the freeze occurs the first time an element
   --   is retrieved through Get_Aggregate_Element.

   --   A list of Any contents (for construction of aggregates)

   package Content_Tables is new PolyORB.Utils.Dynamic_Tables
     (Table_Component_Type => Any_Container_Ptr,
      Table_Index_Type     => Integer,
      Table_Low_Bound      => 0,
      Table_Initial        => 8,
      Table_Increment      => 100);
   subtype Content_Table is Content_Tables.Instance;

   --   For complex types that could be defined in IDL, a Aggregate_Content
   --   will be used.
   --
   --   Complex types include Struct, Union, Enum, Sequence, Array, Except,
   --   Fixed, Value, Valuebox, Abstract_Interface. Here is the way the
   --   content_list is used in each case (See CORBA V2.3 - 15.3)

   --      - for Struct, Except: the elements are the values of each
   --        field in the order of the declaration
   --
   --      - for Union : the value of the switch element comes
   --        first. Then come all the values of the corresponding fields
   --
   --      - for Enum : an unsigned_long corresponding to the position
   --        of the value in the declaration is the only element
   --
   --      - for Array : all the elements of the array, one by one.
   --
   --      - for Sequence : the length first and then all the elements
   --        of the sequence, one by one. XXX Can't we get rid of the length?
   --        it is implicit already in the length of the aggregate
   --
   --      - for Fixed : XXX
   --      - for Value : XXX
   --      - for Valuebox : XXX
   --      - for Abstract_Interface : XXX

   -------------------------------
   --  Default_Aggregate_Content --
   -------------------------------

   --   Default generic implementation of aggregate content wrapper, based on
   --   a table of Any_Container accesses.

   type Default_Aggregate_Content (Kind : TCKind) is
     new Aggregate_Content with
   record
      V : Content_Table;
   end record;

   --   Content primitives

   overriding function Clone
     (CC   : Default_Aggregate_Content;
      Into : Content_Ptr := null) return Content_Ptr;
   overriding procedure Finalize_Value (CC : in out Default_Aggregate_Content);

   --   Aggregate_Content primitives

   overriding function Get_Aggregate_Count
     (ACC : Default_Aggregate_Content) return Types.Unsigned_Long;

   overriding procedure Set_Aggregate_Count
     (ACC   : in out Default_Aggregate_Content;
      Count : Types.Unsigned_Long);

   overriding function Get_Aggregate_Element
     (ACC   : not null access Default_Aggregate_Content;
      TC    : TypeCode.Object_Ptr;
      Index : Types.Unsigned_Long;
      Mech  : not null access Mechanism) return Content'Class;

   overriding procedure Set_Aggregate_Element
     (ACC    : in out Default_Aggregate_Content;
      TC     : TypeCode.Object_Ptr;
      Index  : Types.Unsigned_Long;
      From_C : in out Any_Container'Class);

   overriding procedure Add_Aggregate_Element
     (ACC : in out Default_Aggregate_Content;
      El  : Any_Container_Ptr);

   function Allocate_Default_Aggregate_Content
     (Kind : TCKind) return Content_Ptr;
   --   Allocate and initialize a Aggregate_Content. The TCKind is that of the
   --   aggregate.

   procedure Deep_Deallocate (Table : in out Content_Table);
   --   Deallocate each content element of a content table

   ---------
   --  "=" --
   ---------

   overriding function "=" (Left, Right : Any) return Boolean is
      Res : Boolean;
   begin
      pragma Debug (C, O ("Equal (Any): enter, "
                       & Image (Left) & " =? " & Image (Right)));
      Res := "=" (Get_Container (Left).all, Get_Container (Right).all);
      pragma Debug (C, O ("Equal (Any): returning " & Res'Img));
      return Res;
   end "=";

   ---------------------------
   --  Add_Aggregate_Element --
   ---------------------------

   procedure Add_Aggregate_Element
     (ACC : in out Aggregate_Content;
      El  : Any_Container_Ptr)
   is
   begin

      --   This is not supported by default

      raise Program_Error;
   end Add_Aggregate_Element;

   ---------------------------
   --  Add_Aggregate_Element --
   ---------------------------

   overriding procedure Add_Aggregate_Element
     (ACC : in out Default_Aggregate_Content;
      El  : Any_Container_Ptr)
   is
      use Content_Tables;
   begin
      pragma Assert (Initialized (ACC.V));

      Smart_Pointers.Inc_Usage (Smart_Pointers.Entity_Ptr (El));
      Increment_Last (ACC.V);
      ACC.V.Table (Last (ACC.V)) := El;
   end Add_Aggregate_Element;

   ---------------------------
   --  Add_Aggregate_Element --
   ---------------------------

   procedure Add_Aggregate_Element (Value : in out Any; Element : Any) is
      CA_Ptr : constant Aggregate_Content_Ptr :=
        Aggregate_Content_Ptr (Get_Container (Value).The_Value);
   begin
      pragma Debug (C, O ("Add_Aggregate_Element: enter"));
      Add_Aggregate_Element (CA_Ptr.all, Get_Container (Element));
      pragma Debug (C, O ("Add_Aggregate_Element: end"));
   end Add_Aggregate_Element;

   ----------------------------------------
   --  Allocate_Default_Aggregate_Content --
   ----------------------------------------

   function Allocate_Default_Aggregate_Content
     (Kind : TCKind) return Content_Ptr
   is
      Result : constant Aggregate_Content_Ptr :=
        new Default_Aggregate_Content (Kind => Kind);
   begin
      Content_Tables.Initialize (Default_Aggregate_Content (Result.all).V);
      return Content_Ptr (Result);
   end Allocate_Default_Aggregate_Content;

   ----------------------
   --  Agg_Container_Eq --
   ----------------------

   function Agg_Container_Eq
     (TCK          : TCKind;
      TC           : TypeCode.Object_Ptr;
      Left, Right  : Any_Container'Class) return Boolean
   is
      L_C : Any_Container;
      R_C : Any_Container;
      --   Scratch containers for aggregate elements

      function Agg_Elements_Equal
        (TC           : TypeCode.Object_Ptr;
         L_ACC, R_ACC : access Aggregate_Content'Class;
         Index        : Types.Unsigned_Long) return Boolean;
      --   Compare the Index'th element of Left and Right, which are assumed
      --   to be aggregates. The expected type for both elements is TC.

      ------------------------
      --  Agg_Elements_Equal --
      ------------------------

      function Agg_Elements_Equal
        (TC           : TypeCode.Object_Ptr;
         L_ACC, R_ACC : access Aggregate_Content'Class;
         Index        : Types.Unsigned_Long) return Boolean
      is
         L_M  : aliased Mechanism := By_Value;
         L_CC : aliased Content'Class :=
                  Get_Aggregate_Element (L_ACC, TC, Index, L_M'Access);
         R_M  : aliased Mechanism := By_Value;
         R_CC : aliased Content'Class :=
                  Get_Aggregate_Element (R_ACC, TC, Index, R_M'Access);
      begin
         Set_Value (L_C, L_CC'Unchecked_Access, Foreign => True);
         Set_Value (R_C, R_CC'Unchecked_Access, Foreign => True);
         return Any_Container_Eq (TC, L_C, R_C);
      end Agg_Elements_Equal;

   --   Start of processing for Agg_Container_Eq

   begin
      case TCK is
         when Tk_Struct | Tk_Except =>

            --  1. Retrieve aggregate contents wrapper for Left and Right
            --  2. For each member in the aggregate, compare both values:
            --     2.1. Retrieve member type
            --     2.2. Retrieve contents wrapper on the stack
            --     2.3. Conjure up temporary Any's pointing to these wrappers,
            --          marked as foreign (no contents deallocation upon
            --          finalization)
            --     2.4. Recurse in Equal on temporary Anys

            declare
               List_Type : constant TypeCode.Object_Ptr :=
                             Unwind_Typedefs (TC);
               Count     : constant Types.Unsigned_Long :=
                             TypeCode.Member_Count (List_Type);
               M_Type    : TypeCode.Object_Ptr;

               L_ACC : Aggregate_Content'Class
                 renames Aggregate_Content'Class (Left.The_Value.all);
               R_ACC : Aggregate_Content'Class
                 renames Aggregate_Content'Class (Right.The_Value.all);
            begin
               --  Note: Count is unsigned, guard against Count - 1 overflow

               if Count > 0 then
                  for J in 0 .. Count - 1 loop
                     M_Type := TypeCode.Member_Type (List_Type, J);
                     if not Agg_Elements_Equal
                              (M_Type, L_ACC'Access, R_ACC'Access, J)
                     then
                        pragma Debug
                          (C, O ("Equal (Any, struct/except): end"));
                        return False;
                     end if;
                  end loop;
               end if;
               pragma Debug (C, O ("Equal (Any, struct/except): end"));
               return True;
            end;

         when Tk_Union =>
            declare
               L_ACC : Aggregate_Content'Class renames
                 Aggregate_Content'Class (Left.The_Value.all);
               R_ACC : Aggregate_Content'Class renames
                 Aggregate_Content'Class (Right.The_Value.all);
               List_Type   : constant TypeCode.Object_Ptr :=
                 Unwind_Typedefs (TC);
               Switch_Type : constant TypeCode.Object_Ptr :=
                 TypeCode.Discriminator_Type (List_Type);
               Member_Type : TypeCode.Object_Ptr;
            begin
               pragma Assert (Get_Aggregate_Count (L_ACC) = 2);
               pragma Assert (Get_Aggregate_Count (R_ACC) = 2);

               --  First compares the switch value

               if not Agg_Elements_Equal
                        (Switch_Type, L_ACC'Access, R_ACC'Access, 0)
               then
                  pragma Debug (C, O ("Equal (Any, Union): "
                    & "switch differs, end"));
                  return False;
               end if;

               declare
                  Label_Mech : aliased Mechanism := By_Value;
                  Label_CC : aliased Content'Class :=
                    Get_Aggregate_Element
                      (L_ACC'Access, Switch_Type, 0, Label_Mech'Access);
                  Res : Boolean;
               begin
                  Set_Type (L_C, Switch_Type);
                  Set_Value
                    (L_C, Label_CC'Unchecked_Access, Foreign => True);
                  Member_Type :=
                    TypeCode.Member_Type_With_Label (List_Type, L_C);

                  Res := Agg_Elements_Equal
                           (Member_Type, L_ACC'Access, R_ACC'Access, 1);
                  pragma Debug (C, O ("Equal (Any, Union): end, " & Res'Img));
                  return Res;
               end;
            end;

         when Tk_Sequence
           | Tk_Array =>
            declare
               List_Type : constant TypeCode.Object_Ptr :=
                 Unwind_Typedefs (TC);

               Member_Type : constant TypeCode.Object_Ptr :=
                 TypeCode.Content_Type (List_Type);

               L_ACC : Aggregate_Content'Class renames
                 Aggregate_Content'Class (Left.The_Value.all);
               R_ACC : Aggregate_Content'Class renames
                 Aggregate_Content'Class (Right.The_Value.all);
            begin
               --  Compare values for each member in both aggregates

               for J in 0 .. TypeCode.Length (List_Type) - 1 loop
                  if not Agg_Elements_Equal
                           (Member_Type, L_ACC'Access, R_ACC'Access, J)
                  then
                     pragma Debug (C, O ("Equal (Any, sequence/array): end"));
                     return False;
                  end if;
               end loop;

               pragma Debug (C, O ("Equal (Any, sequence/array): end"));
               return True;
            end;

         when others =>
            raise Program_Error;
      end case;
   end Agg_Container_Eq;

   ----------------------
   --  Any_Container_Eq --
   ----------------------

   function Any_Container_Eq
     (TC           : TypeCode.Object_Ptr;
      Left, Right  : Any_Container'Class) return Boolean
   is
      TCK : constant TCKind := TypeCode.Kind (Unwind_Typedefs (TC));
   begin
      case TCK is
         when Tk_Struct   |
              Tk_Except   |
              Tk_Union    |
              Tk_Array    |
              Tk_Sequence =>
            return Agg_Container_Eq (TCK, TC, Left, Right);

         when Tk_Enum =>
            pragma Debug (C, O ("Equal (Any, Enum): end"));
            --  Compare the only element of both aggregate: an unsigned long

            declare
               use Elementary_Any_ULong;

               L_M  : aliased Mechanism := By_Value;
               L_CC : aliased Content'Class :=
                        Get_Aggregate_Element
                          (Aggregate_Content'Class
                             (Left.The_Value.all)'Access, TC, 0, L_M'Access);
               R_M  : aliased Mechanism := By_Value;
               R_CC : aliased Content'Class :=
                        Get_Aggregate_Element
                          (Aggregate_Content'Class
                             (Right.The_Value.all)'Access, TC, 0, R_M'Access);

            begin
               return Unchecked_Get_V (T_Content (L_CC)'Access).all
                    = Unchecked_Get_V (T_Content (R_CC)'Access).all;
            end;

         when Tk_Null | Tk_Void =>
            pragma Debug (C, O ("Equal (Any, Null or Void): end"));
            return True;

         when Tk_Short =>
            declare
               use Elementary_Any_Short;
               L : constant Short := Unchecked_From_Any (Left);
               R : constant Short := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Short): end"));
               return L = R;
            end;

         when Tk_Long =>
            declare
               use Elementary_Any_Long;
               L : constant Long := Unchecked_From_Any (Left);
               R : constant Long := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Long): end"));
               return L = R;
            end;

         when Tk_Ushort =>
            declare
               use Elementary_Any_UShort;
               L : constant Unsigned_Short := Unchecked_From_Any (Left);
               R : constant Unsigned_Short := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Ushort): end"));
               return L = R;
            end;

         when Tk_Ulong =>
            declare
               use Elementary_Any_ULong;
               L : constant Unsigned_Long := Unchecked_From_Any (Left);
               R : constant Unsigned_Long := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Ulong): end"));
               return L = R;
            end;

         when Tk_Float =>
            declare
               use Elementary_Any_Float;
               L : constant Types.Float := Unchecked_From_Any (Left);
               R : constant Types.Float := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Float): end"));
               return L = R;
            end;

         when Tk_Double =>
            declare
               use Elementary_Any_Double;
               L : constant Double := Unchecked_From_Any (Left);
               R : constant Double := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Double): end"));
               return L = R;
            end;

         when Tk_Boolean =>
            declare
               use Elementary_Any_Boolean;
               L : constant Boolean := Unchecked_From_Any (Left);
               R : constant Boolean := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Boolean): end"));
               return L = R;
            end;

         when Tk_Char =>
            declare
               use Elementary_Any_Char;
               L : constant Char := Unchecked_From_Any (Left);
               R : constant Char := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Char): end"));
               return L = R;
            end;

         when Tk_Octet =>
            declare
               use Elementary_Any_Octet;
               L : constant Octet := Unchecked_From_Any (Left);
               R : constant Octet := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Octet): end"));
               return L = R;
            end;

         when Tk_Any =>
            declare
               use Elementary_Any_Any;
               L : constant Any := Unchecked_From_Any (Left);
               R : constant Any := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Any): end"));
               return "=" (L, R);
            end;

         when Tk_TypeCode =>
            declare
               use Elementary_Any_TypeCode;
               L : constant TypeCode.Local_Ref := Unchecked_From_Any (Left);
               R : constant TypeCode.Local_Ref := Unchecked_From_Any (Right);
            begin
               if TypeCode.Kind (R) = Tk_Value then
                  pragma Debug (C, O ("Equal (Any, TypeCode) :" &
                                   " Skipping Tk_Value" &
                                   " typecode comparison"));
                  --  TODO/XXX Call a different equality procedure
                  --  to accomodate eventual circular references in
                  --  typecodes
                  pragma Debug (C, O ("Equal (Any, TypeCode) :" &
                                   " Tk_Value NOT IMPLEMENTED"));
                  raise Program_Error;
                  return True;
               else
                  pragma Debug (C, O ("Equal (Any, TypeCode): end"));
                  return TypeCode.Equal (R, L);
               end if;
            end;

         when Tk_Principal =>
            --  XXX : to be done
            pragma Debug (C, O ("Equal (Any, Principal): end"
                             & " NOT IMPLEMENTED -> TRUE"));
            return True;

         when Tk_Objref =>
            declare
--               L : CORBA.Object.Ref := CORBA.Object.Helper.From_Any (Left);
--               R : CORBA.Object.Ref := CORBA.Object.Helper.From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, ObjRef): end"
                                & " NOT IMPLEMENTED -> TRUE"));
               --  XXX : is_equivalent has to be implemented
               return True;
               --  return CORBA.Object.Is_Equivalent (L, R);
            end;

         when Tk_Fixed
           | Tk_Value
           | Tk_Valuebox
           | Tk_Abstract_Interface
           | Tk_Local_Interface
           | Tk_Component
           | Tk_Home
           | Tk_Event =>
            --  XXX : to be done
            pragma Debug (C, O ("Equal (Any, Fixed, Value, ValueBox, "
                             & "Abstract_Interface, Local_Interface, "
                             & "Component, Home or Event): end"
                             & " NON IMPLEMENTED -> TRUE"));
            return True;

         when Tk_String =>
            declare
               L : constant Standard.String := From_Any (Left);
               R : constant Standard.String := From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, String): end"));
               return L = R;
            end;

         when Tk_Alias =>

            --  We should never be here, since the case statement uses the
            --  precise type of the anys, that is an unaliased type.

            pragma Debug (C, O ("Equal (Any, Alias): end with exception"));
            raise Program_Error;

         when Tk_Longlong =>
            declare
               use Elementary_Any_Long_Long;
               L : constant Long_Long := Unchecked_From_Any (Left);
               R : constant Long_Long := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Long_Long): end"));
               return L = R;
            end;

         when Tk_Ulonglong =>
            declare
               use Elementary_Any_ULong_Long;
               L : constant Unsigned_Long_Long := Unchecked_From_Any (Left);
               R : constant Unsigned_Long_Long := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Unsigned_Long_Long): end"));
               return L = R;
            end;

         when Tk_Longdouble =>
            declare
               use Elementary_Any_Long_Double;
               L : constant Long_Double := Unchecked_From_Any (Left);
               R : constant Long_Double := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Long_Double): end"));
               return L = R;
            end;

         when Tk_Widechar =>
            declare
               use Elementary_Any_Wchar;
               L : constant Wchar := Unchecked_From_Any (Left);
               R : constant Wchar := Unchecked_From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Wchar): end"));
               return L = R;
            end;

         when Tk_Wstring =>
            declare
               L : constant Types.Wide_String := From_Any (Left);
               R : constant Types.Wide_String := From_Any (Right);
            begin
               pragma Debug (C, O ("Equal (Any, Wide_String): end"));
               return L = R;
            end;

         when Tk_Native =>
            --  XXX  to be done
            pragma Debug (C, O ("Equal (Any, Native): end"
                             & " NON IMPLEMENTED -> TRUE"));
            return True;
      end case;
   end Any_Container_Eq;

   ---------
   --  "=" --
   ---------

   function "=" (Left, Right : Any_Container'Class) return Boolean is
      L_Type : constant TypeCode.Object_Ptr := Get_Type_Obj (Left);
      R_Type : constant TypeCode.Object_Ptr := Get_Type_Obj (Right);

   begin
      return TypeCode.Equal (L_Type, R_Type)
               and then
             Any_Container_Eq (L_Type, Left, Right);
   end "=";

   -----------
   --  Clone --
   -----------

   overriding function Clone
     (CC   : No_Content;
      Into : Content_Ptr := null) return Content_Ptr is
   begin
      raise Program_Error;
      return null;
   end Clone;

   --   Clone function for Default_Aggregate_Content
   --   Caveat emptor: this function allocates a new container for each
   --   element of the aggregate, and sets its value by recursively cloning
   --   the contents of the original element. It is *extremely* costly! Also,
   --   it never supports direct in-place assignment.

   overriding function Clone
     (CC   : Default_Aggregate_Content;
      Into : Content_Ptr := null) return Content_Ptr
   is
      use PolyORB.Smart_Pointers;
      use Content_Tables;
   begin
      if Into /= null then
         return null;
      end if;

      declare
         New_CC_P : constant Content_Ptr :=
           Allocate_Default_Aggregate_Content (CC.Kind);
         New_CC   : Default_Aggregate_Content
           renames Default_Aggregate_Content (New_CC_P.all);
      begin
         Set_Last (New_CC.V, Last (CC.V));
         for J in First (New_CC.V) .. Last (New_CC.V) loop

            --  Create a new any container, referenced by this aggregate

            New_CC.V.Table (J) := new Any_Container;
            Inc_Usage (Entity_Ptr (New_CC.V.Table (J)));

            --  Set its type and copy the value from the original element

            New_CC.V.Table (J).The_Type := CC.V.Table (J).The_Type;
            Set_Value (New_CC.V.Table (J).all,
                       Clone (CC.V.Table (J).The_Value.all), Foreign => False);
         end loop;
         return New_CC_P;
      end;
   end Clone;

   --------------
   --  Copy_Any --
   --------------

   function Copy_Any (Src : Any) return Any is
      Dst : Any;
   begin
      Set_Type (Dst, Get_Type_Obj (Src));
      Copy_Any_Value (Dst => Dst, Src => Src);
      return Dst;
   end Copy_Any;

   --------------------
   --  Copy_Any_Value --
   --------------------

   procedure Copy_Any_Value
     (Dst_C : in out Any_Container'Class;
      Src_C : Any_Container'Class);

   procedure Copy_Any_Value (Dst : Any; Src : Any) is
   begin
      Copy_Any_Value (Get_Container (Dst).all, Get_Container (Src).all);
   end Copy_Any_Value;

   procedure Copy_Any_Value
     (Dst_C : in out Any_Container'Class;
      Src_C : Any_Container'Class)
   is
      TC  : constant TypeCode.Object_Ptr :=
        Unwind_Typedefs (Get_Type_Obj (Src_C));

      TCK : constant TCKind := TypeCode.Kind (TC);

      Dst_TCK : constant TCKind :=
        TypeCode.Kind (Unwind_Typedefs (Get_Type_Obj (Dst_C)));
   begin
      if Src_C'Address = Dst_C'Address then
         return;
      end if;

      if Dst_TCK /= TCK then
         raise TypeCode.Bad_TypeCode;
      end if;

      if Dst_C.The_Value = null then
         Set_Value (Dst_C, Clone (Src_C.The_Value.all), Foreign => False);
      else
         case TCK is
            when Tk_Null | Tk_Void =>
               null;

            when Tk_Short =>
               Set_Any_Value (Short'(From_Any (Src_C)), Dst_C);

            when Tk_Long =>
               Set_Any_Value (Long'(From_Any (Src_C)), Dst_C);

            when Tk_Ushort =>
               Set_Any_Value (Unsigned_Short'(From_Any (Src_C)), Dst_C);

            when Tk_Ulong =>
               Set_Any_Value (Unsigned_Long'(From_Any (Src_C)), Dst_C);

            when Tk_Float =>
               Set_Any_Value (Types.Float'(From_Any (Src_C)), Dst_C);

            when Tk_Double =>
               Set_Any_Value (Double'(From_Any (Src_C)), Dst_C);

            when Tk_Boolean =>
               Set_Any_Value (Boolean'(From_Any (Src_C)), Dst_C);

            when Tk_Char =>
               Set_Any_Value (Char'(From_Any (Src_C)), Dst_C);

            when Tk_Octet =>
               Set_Any_Value (Octet'(From_Any (Src_C)), Dst_C);

            when Tk_Longlong =>
               Set_Any_Value (Long_Long'(From_Any (Src_C)), Dst_C);

            when Tk_Ulonglong =>
               Set_Any_Value (Unsigned_Long_Long'(From_Any (Src_C)), Dst_C);

            when Tk_Longdouble =>
               Set_Any_Value (Long_Double'(From_Any (Src_C)), Dst_C);

            when Tk_Widechar =>
               Set_Any_Value (Wchar'(From_Any (Src_C)), Dst_C);

            when Tk_String =>
               declare
                  Bound : constant Types.Unsigned_Long := TypeCode.Length (TC);
               begin
                  if Bound = 0 then
                     Set_Any_Value (Types.String'(From_Any (Src_C)), Dst_C);
                  else
                     Elementary_Any_Bounded_String.Set_Any_Value
                       (Elementary_Any_Bounded_String.From_Any (Src_C), Dst_C);
                  end if;
               end;

            when Tk_Wstring =>
               declare
                  Bound : constant Types.Unsigned_Long := TypeCode.Length (TC);
               begin
                  if Bound = 0 then
                     Set_Any_Value (Types.Wide_String'(From_Any (Src_C)),
                                    Dst_C);
                  else
                     Elementary_Any_Bounded_Wide_String.Set_Any_Value
                       (Elementary_Any_Bounded_Wide_String.From_Any (Src_C),
                        Dst_C);
                  end if;
               end;

            when Tk_Any =>
               Set_Any_Value (Any'(From_Any (Src_C)), Dst_C);

            when Tk_TypeCode =>
               Set_Any_Value (TypeCode.Local_Ref'(From_Any (Src_C)), Dst_C);

            when Tk_Objref =>
               declare
                  New_CC : constant Content_Ptr :=
                    Clone (CC   => Src_C.The_Value.all,
                           Into => Dst_C.The_Value);
               begin
                  if Dst_C.The_Value = null then
                     Set_Value (Dst_C, New_CC, Foreign => False);
                  else
                     pragma Assert (New_CC = Dst_C.The_Value);
                     null;
                  end if;
               end;

            when
              Tk_Struct   |
              Tk_Except   |
              Tk_Union    |
              Tk_Enum     |
              Tk_Sequence |
              Tk_Array    |
              Tk_Fixed    =>

               declare
                  El_TC : TypeCode.Object_Ptr;
                  Dst_ACC : Aggregate_Content'Class
                    renames Aggregate_Content'Class (Dst_C.The_Value.all);
                  Src_ACC : Aggregate_Content'Class
                    renames Aggregate_Content'Class (Src_C.The_Value.all);
                  Src_Count : constant Types.Unsigned_Long :=
                    Get_Aggregate_Count (Src_ACC);
               begin
                  Set_Aggregate_Count (Dst_ACC, Src_Count);

                  --  Set up El_TC for first element

                  case TCK is
                     when Tk_Enum | Tk_Sequence =>
                        El_TC := TypeCode.PTC_Unsigned_Long'Access;

                     when Tk_Union =>
                        El_TC := TypeCode.Discriminator_Type (TC);

                     when Tk_Array =>
                        El_TC := TypeCode.Content_Type (TC);

                     when Tk_Fixed =>
                        El_TC := TypeCode.PTC_Octet'Access;

                     when others =>
                        null;
                  end case;

                  for J in 0 .. Src_Count - 1 loop
                     if TCK = Tk_Struct or else TCK = Tk_Except then
                        El_TC := TypeCode.Member_Type (TC, J);
                     end if;

                     declare
                        Dst_El_C  : Any_Container;
                        Src_El_C  : Any_Container;

                        Dst_El_M  : aliased Mechanism := By_Reference;
                        Dst_El_CC : aliased Content'Class :=
                          Get_Aggregate_Element
                            (Dst_ACC'Access, El_TC, J, Dst_El_M'Access);

                        Src_El_M  : aliased Mechanism := By_Value;
                        Src_El_CC : aliased Content'Class :=
                          Get_Aggregate_Element
                            (Src_ACC'Access, El_TC, J, Src_El_M'Access);

                     begin
                        Set_Type (Src_El_C, El_TC);
                        Set_Value (Src_El_C,
                          Src_El_CC'Unchecked_Access, Foreign => True);

                        --  Case of an aggregate element that needs to be set
                        --  explicitly.

                        if Dst_El_M = By_Value then
                           Set_Aggregate_Element (Dst_ACC, El_TC, J, Src_El_C);

                           --  This would be incorrect if Dst_ACC is a default
                           --  aggregate content, since in this case the call
                           --  will incorrectly steal the value from Src_El_C.

                           --  At least try to detect this fault case:

                           pragma Assert (not Is_Empty (Src_El_C));

                        --  Attempt in-place assignment

                        elsif Clone
                            (CC   => Src_El_CC,
                             Into => Dst_El_CC'Unchecked_Access) = null

                        --  Fall back to recursive element copy

                        then
                           Set_Type (Dst_El_C, El_TC);
                           Set_Value (Dst_El_C,
                             Dst_El_CC'Unchecked_Access, Foreign => True);

                           Copy_Any_Value (Dst_El_C, Src_El_C);
                        end if;

                        if J = 0 then
                           case TCK is
                              when Tk_Union =>
                                 El_TC :=
                                   TypeCode.Member_Type_With_Label
                                     (TC, Src_El_C);

                              when Tk_Sequence =>
                                 El_TC := TypeCode.Content_Type (TC);

                              when others =>
                                 null;
                           end case;
                        end if;
                     end;
                  end loop;
               end;

            when
              Tk_Value              |
              Tk_Valuebox           |
              Tk_Abstract_Interface |
              Tk_Local_Interface    |
              Tk_Component          |
              Tk_Home               |
              Tk_Event              |
              Tk_Principal          |
              Tk_Native             =>
               --  XXX : to be done
               pragma Debug (C, O ("Copy (" & Dst_TCK'Img & ": end"
                                & " NON IMPLEMENTED"));
               return;

            when Tk_Alias =>
               --  we should never be here, since the case statement uses the
               --  precise type of the anys, that is an unaliased type
               pragma Debug (C, O ("Equal (Any, Alias): end with exception"));
               raise Program_Error;

         end case;
      end if;
   end Copy_Any_Value;

   ---------------------
   --  Deep_Deallocate --
   ---------------------

   procedure Deep_Deallocate (Table : in out Content_Table) is
      use Content_Tables;
   begin
      pragma Debug (C, O ("Deep_Deallocate: enter"));

      if Initialized (Table) then
         for J in First (Table) .. Last (Table) loop

            --  If we are aborting during initialisation of the aggregate,
            --  not all elements might have been initialized at this point,
            --  so we need to test explicitly against null.

            if Table.Table (J) /= null then
               Smart_Pointers.Dec_Usage
                 (Smart_Pointers.Entity_Ptr (Table.Table (J)));
            end if;
         end loop;
      end if;

      Deallocate (Table);

      pragma Debug (C, O ("Deep_Deallocate: end"));
   end Deep_Deallocate;

   --------------
   --  Finalize --
   --------------

   overriding procedure Finalize (Self : in out Any_Container) is
   begin
      pragma Debug (C, O ("Finalizing Any_Container: enter"));

      if Self.Is_Finalized then
         return;
      end if;

      Self.Is_Finalized := True;
      Finalize_Value (Self);

      pragma Debug (C, O ("Finalizing Any_Container: leave"));
   end Finalize;

   --------------------
   --  Finalize_Value --
   --------------------

   procedure Finalize_Value (C : in out Any_Container'Class) is
   begin
      Set_Value (C, null, Foreign => False);
   end Finalize_Value;

   --------------------
   --  Finalize_Value --
   --------------------

   overriding procedure Finalize_Value (CC : in out No_Content) is
   begin
      raise Program_Error;
   end Finalize_Value;

   --------------------
   --  Finalize_Value --
   --------------------

   overriding procedure Finalize_Value
     (CC : in out Default_Aggregate_Content)
   is
   begin
      Deep_Deallocate (CC.V);
   end Finalize_Value;

   overriding function Get_Aggregate_Count
     (ACC : Default_Aggregate_Content) return Unsigned_Long
   is
   begin
      return Unsigned_Long
        (Content_Tables.Last (ACC.V) - Content_Tables.First (ACC.V) + 1);
   end Get_Aggregate_Count;
   overriding function Get_Aggregate_Element
     (ACC   : not null access Default_Aggregate_Content;
      TC    : TypeCode.Object_Ptr;
      Index : Unsigned_Long;
      Mech  : not null access Mechanism) return Content'Class
   is
      use PolyORB.Smart_Pointers;
      use Content_Tables;

      El_C_Ptr : Any_Container_Ptr renames
        ACC.V.Table (First (ACC.V) + Natural (Index));
   begin
      pragma Debug (C, O ("Get_Aggregate_Element: enter"));

      pragma Debug (C, O ("Get_Aggregate_Element: Index = "
                       & Unsigned_Long'Image (Index)
                       & ", aggregate_count = "
                       & Unsigned_Long'Image (Get_Aggregate_Count (ACC.all))));

      if El_C_Ptr = null then

         --  Allocate new container and count one reference (the aggregate)

         El_C_Ptr := new Any_Container;
         Inc_Usage (Entity_Ptr (El_C_Ptr));

         El_C_Ptr.The_Type := TypeCode.To_Ref (TC);
      end if;

      if (El_C_Ptr.The_Value = null)
        or else (ACC.Kind = Tk_Union
                   and then
                 Index = 0
                   and then
                 Mech.all = By_Reference)
      then
         pragma Assert (Mech.all = By_Reference);

         --  When there is no current value for this aggregate element, or when
         --  getting the discriminant of an Union for update, set Mech to
         --  By_Value to force the caller to call Set_Aggregate_Element.

         Mech.all := By_Value;
         return No_Content'(null record);

      else
         Mech.all := By_Reference;
         return El_C_Ptr.The_Value.all;
      end if;
   end Get_Aggregate_Element;
   function Get_Container (A : Any) return Any_Container_Ptr is
   begin
      return Any_Container_Ptr (Entity_Of (A));
   end Get_Container;
   function Get_Empty_Any (Tc : TypeCode.Local_Ref) return Any is
      Result : Any;
   begin

      pragma Debug (C, O ("Get_Empty_Any: enter"));
      Set_Type (Result, Tc);
      pragma Debug (C, O ("Get_Empty_Any: type set"));

      return Result;
   end Get_Empty_Any;
   function Get_Empty_Any_Aggregate (TC : TypeCode.Local_Ref) return Any
   is
      A    : Any;
      Kind : constant TCKind := TypeCode.Kind (Unwind_Typedefs (TC));
   begin
      pragma Debug (C, O ("Get_Empty_Any_Aggregate: begin"));
      Set_Type (A, TC);

      if Kind in Aggregate_TCKind then
         Set_Value
           (Get_Container (A).all,
            Allocate_Default_Aggregate_Content (Kind),
            Foreign => False);
      end if;

      pragma Debug (C, O ("Get_Empty_Any_Aggregate: end"));
      return A;
   end Get_Empty_Any_Aggregate;
   function Get_Type (A : Any) return TypeCode.Local_Ref is
   begin
      return TypeCode.To_Ref (Get_Type_Obj (A));
   end Get_Type;

   function Get_Type_Obj (A : Any) return TypeCode.Object_Ptr is
   begin
      return Get_Type_Obj (Get_Container (A).all);
   end Get_Type_Obj;

   function Get_Type (C : Any_Container'Class) return TypeCode.Local_Ref is
   begin
      return TypeCode.To_Ref (Get_Type_Obj (C));
   end Get_Type;

   function Get_Type_Obj
     (C : Any_Container'Class) return TypeCode.Object_Ptr
   is
   begin
      return TypeCode.Object_Of (C.The_Type);
   end Get_Type_Obj;
   function Get_Unwound_Type (The_Any : Any) return TypeCode.Object_Ptr is
   begin
      return Unwind_Typedefs (Get_Type_Obj (The_Any));
   end Get_Unwound_Type;
   function Get_Value (C : Any_Container'Class) return Content_Ptr is
   begin
      return C.The_Value;
   end Get_Value;
   function Image (NV : NamedValue) return Standard.String is
      function Flag_Name (F : Flags) return Standard.String;
      pragma Inline (Flag_Name);
      --   Return string representation for F, which denotes an argument mode

      ---------------
      --  Flag_Name --
      ---------------

      function Flag_Name (F : Flags) return Standard.String is
      begin
         case F is
            when ARG_IN =>
               return "in";
            when ARG_OUT =>
               return "out";
            when ARG_INOUT =>
               return "in out";
            when IN_COPY_VALUE =>
               return "in-copy";
            when others =>
               return "(invalid flag" & Flags'Image (F) & ")";
         end case;
      end Flag_Name;

   begin
      return Flag_Name (NV.Arg_Modes) & " "
        & To_Standard_String (NV.Name) & " = " & Image (NV.Argument);
   end Image;

   ----------------------
   --  Image (typecode) --
   ----------------------

   function Image (TC : TypeCode.Local_Ref) return Standard.String is
   begin
      return Image (TypeCode.Object_Of (TC));
   end Image;

   function Image (TC : TypeCode.Object_Ptr) return Standard.String is
      use TypeCode;

      Kind   : constant TCKind := TypeCode.Kind (TC);
      Count  : Unsigned_Long;
      Result : Types.String;
   begin
      case Kind is
         when
           Tk_Objref             |
           Tk_Struct             |
           Tk_Union              |
           Tk_Enum               |
           Tk_Alias              |
           Tk_Value              |
           Tk_Valuebox           |
           Tk_Native             |
           Tk_Abstract_Interface |
           Tk_Except             =>
            Result := To_PolyORB_String (TCKind'Image (Kind) & " ")
              & Types.String (Name (TC)) & " (" & Types.String (Id (TC)) & ")";

            --  Add a few information

            case Kind is
               when
                 Tk_Objref             |
                 Tk_Native             |
                 Tk_Abstract_Interface =>
                  return To_Standard_String (Result);

               when Tk_Alias =>
                  return To_Standard_String (Result)
                    & " <" & TCKind'Image (Kind) & ":"
                    & Image (Content_Type (TC)) & ">";

               when
                 Tk_Struct             |
                 Tk_Except             =>

                  Result := Result & " {";

                  --  Note: Count is unsigned, guard against overflow
                  --  of Count - 1.

                  Count := Member_Count (TC);
                  if Count > 0 then
                     for J in 0 .. Count - 1 loop
                        Result := Result
                          & " "
                          & Image (Member_Type (TC, J))
                          & " "
                          & Types.String (Member_Name (TC, J))
                          & ";";
                     end loop;
                  end if;
                  Result := Result & " }";

                  return To_Standard_String (Result);

               when Tk_Union =>
                  Result := Result
                    & " ("
                    & Image (Discriminator_Type (TC))
                    & " :="
                    & Types.Long'Image (Default_Index (TC))
                    & ") {";

                  Count := Member_Count (TC);
                  if Count > 0 then
                     for J in 0 .. Count - 1 loop
                        Result := Result &
                          " case " & Ada.Strings.Fixed.Trim
                                       (Image (Member_Label (TC, J)),
                                        Ada.Strings.Left)
                          & ": "
                          & Image (Member_Type (TC, J))
                          & " "
                          & Types.String (Member_Name (TC, J)) & ";";
                     end loop;
                  end if;
                  Result := Result & " }";

                  return To_Standard_String (Result);

               when others =>
                  return "<aggregate:" & TCKind'Image (Kind) & ">";
            end case;

         when Tk_Array | Tk_Sequence =>
            return TCKind'Image (Kind) & "<"
              & Image (Content_Type (TC)) & ","
              & Unsigned_Long'Image (Length (TC)) & " >";

         when Tk_String | Tk_Wstring =>
            declare
               function Tmpl return String;
               --  Return template type name, from typecode kind

               function Tmpl return String is
               begin
                  if Kind = Tk_Wstring then
                     return "wide_string";
                  else
                     return "string";
                  end if;
               end Tmpl;

               Bound : constant Types.Unsigned_Long := Length (TC);
               Bound_Img : constant String := Bound'Img;
            begin
               if Bound = 0 then
                  return Tmpl;
               else
                  return Tmpl & "<"
                    & Bound_Img (Bound_Img'First + 1 .. Bound_Img'Last) & ">";
               end if;
            end;

         when others =>
            return TCKind'Image (Kind);
      end case;
   end Image;

   -----------------
   --  Image (Any) --
   -----------------

   function Image (A : Any) return Standard.String is
   begin
      return Image (Get_Container (A).all);
   end Image;

   ---------------------------------
   --  Image (Any_Container'Class) --
   ---------------------------------

   function Image (C : Any_Container'Class) return Standard.String is
      TC   : constant TypeCode.Local_Ref := Unwind_Typedefs (Get_Type (C));
      Kind : constant TCKind := TypeCode.Kind (TC);
   begin
      if Is_Empty (C) then
         return "<empty>";
      end if;

      case Kind is
         when Tk_Short =>
            return Short'Image (From_Any (C));

         when Tk_Long =>
            return Long'Image (From_Any (C));

         when Tk_Ushort =>
            return Unsigned_Short'Image (From_Any (C));

         when Tk_Ulong =>
            return Unsigned_Long'Image (From_Any (C));

         when Tk_Float =>
            return Types.Float'Image (From_Any (C));

         when Tk_Double =>
            return Double'Image (From_Any (C));

         when Tk_Boolean =>
            return Boolean'Image (From_Any (C));

         when Tk_Char =>
            return Char'Image (From_Any (C));

         when Tk_Octet =>
            return Octet'Image (From_Any (C));

         when Tk_String =>
            return Standard.String'(From_Any (C));

         when Tk_Longlong =>
            return Long_Long'Image (From_Any (C));

         when Tk_Ulonglong =>
            return Unsigned_Long_Long'Image (From_Any (C));

         when Tk_Enum =>
            declare
               Index_C : Any_Container;
               Val_M   : aliased Mechanism := By_Value;
               CA_Ptr  : constant Aggregate_Content_Ptr :=
                 Aggregate_Content_Ptr (C.The_Value);

               Val_CC  : aliased Content'Class :=
                 Get_Aggregate_Element (CA_Ptr,
                   TypeCode.PTC_Unsigned_Long'Access, 0,
                   Val_M'Access);

            begin
               Set_Type  (Index_C, TC_Unsigned_Long);
               Set_Value (Index_C, Val_CC'Unchecked_Access, Foreign => True);
               return Types.To_Standard_String
                 (TypeCode.Enumerator_Name (TC, From_Any (Index_C)));
            end;

         when Tk_Value =>
            return "<Value:"
              & Image (Get_Type_Obj (C)) & ":"
              & System.Address_Image (Get_Value (C)'Address) & ">";

         when Tk_Any =>
            return "<Any:"
              & Image (Elementary_Any_Any.Unchecked_Get_V
                       (Elementary_Any_Any.T_Content
                        (Get_Value (C).all)'Access).all)
              & ">";

         when others =>
            return "<Any:" & Image (Get_Type_Obj (C)) & ">";
      end case;

   exception
      when others =>
         return "<Image raised an exception>";
   end Image;
   overriding procedure Initialize (Self : in out Any) is
      use type PolyORB.Smart_Pointers.Entity_Ptr;

      Container : constant Any_Container_Ptr := new Any_Container;
   begin
      pragma Debug (C, O ("Initializing Any: enter"));
      pragma Assert (Entity_Of (Self) = null);

      Use_Entity (Self, PolyORB.Smart_Pointers.Entity_Ptr (Container));
      pragma Debug (C, O ("Initializing Any: leave"));
   end Initialize;
   function Is_Empty (A : Any) return Boolean is
   begin
      return Is_Empty (Get_Container (A).all);
   end Is_Empty;

   --------------
   --  Is_Empty --
   --------------

   function Is_Empty (C : Any_Container'Class) return Boolean is
   begin
      return C.The_Value = null;
   end Is_Empty;
   procedure Move_Any_Value (Dst_C, Src_C : in out Any_Container'Class) is
   begin
      if Src_C'Address = Dst_C'Address then
         return;
      end if;

      Set_Value (Dst_C, Src_C.The_Value, Src_C.Foreign);
      Src_C.The_Value := null;
      Src_C.Foreign   := False;
   end Move_Any_Value;

   --------------------
   --  Move_Any_Value --
   --------------------

   procedure Move_Any_Value (Dst : Any; Src : Any)
   is
      Src_C : constant Any_Container_Ptr := Get_Container (Src);
      Dst_C : constant Any_Container_Ptr := Get_Container (Dst);
   begin
      if TypeCode.Kind (Get_Unwound_Type (Dst))
         /= TypeCode.Kind (Get_Unwound_Type (Src))
      then
         pragma Debug (C, O ("Move_Any_Value from: "
                          & Image (Get_Unwound_Type (Src))));
         pragma Debug (C, O ("  to: " & Image (Get_Unwound_Type (Dst))));
         raise TypeCode.Bad_TypeCode;
      end if;
      Move_Any_Value (Dst_C.all, Src_C.all);
   end Move_Any_Value;
   function No_Wrap (X : access T) return Content'Class is
      pragma Unreferenced (X);
   begin
      raise Program_Error;
      return No_Content'(null record);
   end No_Wrap;
   function Pos_From_Any
     (C : Any_Container'Class) return Types.Unsigned_Long
   is
      subtype UL is Types.Unsigned_Long;
   begin
      case TypeCode.Kind (C.The_Type) is
         when Tk_Enum =>
            return Get_Aggregate_Element (C, 0);
         when Tk_Boolean =>
            return Boolean'Pos (From_Any (C));
         when Tk_Short =>
            return UL (From_Any (C) - Short'First);
         when Tk_Ushort =>
            return UL (From_Any (C) - Unsigned_Short'First);
         when Tk_Long =>
            return UL (From_Any (C) - Long'First);
         when Tk_Ulong =>
            return UL (From_Any (C) - Unsigned_Long'First);

         --  Mapping of scalar value to Unsigned_Long position is unsupported
         --  for other typecode kinds, in particular [unsigned] long longs.

         when others =>
            raise TypeCode.BadKind;
      end case;
   end Pos_From_Any;
   overriding procedure Set_Aggregate_Count
     (ACC   : in out Default_Aggregate_Content;
      Count : Types.Unsigned_Long)
   is
      Prev_Last : constant Integer := Content_Tables.Last (ACC.V);
   begin
      Content_Tables.Set_Last (ACC.V,
        Content_Tables.First (ACC.V) + Natural (Count) - 1);

      --   Note: there is no default initialization for table elements, so
      --   make sure here that they are properly initialized to null.

      for J in Prev_Last + 1 .. Content_Tables.Last (ACC.V) loop
         ACC.V.Table (J) := null;
      end loop;
   end Set_Aggregate_Count;
   procedure Set_Aggregate_Element
     (ACC    : in out Aggregate_Content;
      TC     : TypeCode.Object_Ptr;
      Index  : Unsigned_Long;
      From_C : in out Any_Container'Class) is
   begin

      --  By default this is not implemented. This operation must be
      --  overridden for derived types of Aggregate_Content that may
      --  return No_Content in Get_Aggregate_Element.

      raise Program_Error;

   end Set_Aggregate_Element;
   overriding procedure Set_Aggregate_Element
     (ACC    : in out Default_Aggregate_Content;
      TC     : TypeCode.Object_Ptr;
      Index  : Unsigned_Long;
      From_C : in out Any_Container'Class)
   is
      use Content_Tables;
      V_First : constant Natural := First (ACC.V);
      El_C : Any_Container'Class
        renames ACC.V.Table (V_First + Natural (Index)).all;
   begin
      if ACC.Kind = Tk_Union
        and then Index = 0
        and then not Is_Empty (El_C)
        and then ACC.V.Table (V_First + 1) /= null
        and then not Is_Empty (ACC.V.Table (V_First + 1).all)
        and then El_C /= From_C
      then
         --  Changing the discriminant of a union: finalize previous member,
         --  if present.

         Finalize_Value (ACC.V.Table (V_First + 1).all);
      end if;
      Set_Type (El_C, TC);

      if From_C.Foreign then

         --  If From_C is foreign, we are not allowed to steal its contents
         --  pointer (it may become invalid at any point).

         Copy_Any_Value (Dst_C => El_C, Src_C => From_C);

      else
         Move_Any_Value (Dst_C => El_C, Src_C => From_C);
      end if;
   end Set_Aggregate_Element;
   procedure Set_Any_Aggregate_Value (Agg_C : in out Any_Container'Class) is
      use TypeCode;
      Kind : constant TCKind :=
        TypeCode.Kind (Unwind_Typedefs (Get_Type_Obj (Agg_C)));
   begin
      pragma Debug (C, O ("Set_Any_Aggregate_Value: enter"));
      if Kind not in Aggregate_TCKind then
         raise TypeCode.Bad_TypeCode;
      end if;

      pragma Debug (C, O ("Set_Any_Aggregate_Value: typecode is correct"));

      if Agg_C.The_Value = null then
         Set_Value
           (Agg_C,
            Allocate_Default_Aggregate_Content (Kind), Foreign => False);
      end if;
   end Set_Any_Aggregate_Value;
   procedure Set_Container (A : in out Any; ACP : Any_Container_Ptr) is
   begin
      Set (A, Smart_Pointers.Entity_Ptr (ACP));
   end Set_Container;
   procedure Set_Type (A : in out Any; TC : TypeCode.Local_Ref) is
   begin
      Set_Type (A, TypeCode.Object_Of (TC));
   end Set_Type;

   procedure Set_Type (A : in out Any; TC : TypeCode.Object_Ptr) is
   begin
      Set_Type (Get_Container (A).all, TC);
   end Set_Type;

   procedure Set_Type
     (C  : in out Any_Container'Class;
      TC : TypeCode.Local_Ref)
   is
   begin
      Set_Type (C, TypeCode.Object_Of (TC));
   end Set_Type;

   procedure Set_Type
     (C  : in out Any_Container'Class;
      TC : TypeCode.Object_Ptr)
   is
   begin
      C.The_Type := TypeCode.To_Ref (TC);
   end Set_Type;
   procedure Set_Value
     (C       : in out Any_Container'Class;
      CC      : Content_Ptr;
      Foreign : Boolean := True)
   is
   begin
      if C.The_Value /= null and then not C.Foreign then
         Finalize_Value (C.The_Value.all);
         Free (C.The_Value);
      end if;

      C.The_Value := CC;
      C.Foreign   := Foreign;
   end Set_Value;
   function Unchecked_Get_V
     (X : not null access Content) return System.Address
   is
      pragma Unreferenced (X);
   begin
      --   By default, content wrappers do not provide direct access to the
      --   underlying data.

      return System.Null_Address;
   end Unchecked_Get_V;
   function Unwind_Typedefs
     (TC : TypeCode.Local_Ref) return TypeCode.Local_Ref
   is
   begin
      return TypeCode.To_Ref (Unwind_Typedefs (TypeCode.Object_Of (TC)));
   end Unwind_Typedefs;

   function Unwind_Typedefs
     (TC : TypeCode.Object_Ptr) return TypeCode.Object_Ptr
   is
      Result : TypeCode.Object_Ptr := TC;
   begin
      while TypeCode.Kind (Result) = Tk_Alias loop
         Result := TypeCode.Content_Type (Result);
      end loop;

      return Result;
   end Unwind_Typedefs;

   ----------------------------------------------------------------------------
   --  Accessor Wrapper Stubs - Delegate to Accessor_Impl
   ----------------------------------------------------------------------------
   --   RDB-004 Task 3: Accessor Extraction Pattern (ADR-005)
   --
   --   These wrapper stubs maintain the existing public API while delegating
   --   all implementation to the nested Accessor_Impl package.
   --
   --   Total wrapper stubs: 109 (matching Accessor_Impl package spec 1:1)

   ----------------------------------------
   --  From_Any Wrapper Stubs (39 functions)
   ----------------------------------------

   --   From_Any (Any_Container'Class) overloads - 17 wrappers

   function From_Any (C : Any_Container'Class) return Types.Octet is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Types.Short is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Types.Long is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Types.Long_Long is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Types.Unsigned_Short is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Types.Unsigned_Long is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any
     (C : Any_Container'Class) return Types.Unsigned_Long_Long is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Types.Boolean is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Types.Char is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Types.Wchar is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Types.Float is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Types.Double is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Types.Long_Double is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Types.String is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Types.Wide_String is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Any is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return TypeCode.Local_Ref is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   --   From_Any (Any) overloads - 19 wrappers

   function From_Any (A : Any) return Types.Octet is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.Short is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.Long is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.Long_Long is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.Unsigned_Short is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.Unsigned_Long is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.Unsigned_Long_Long is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.Boolean is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.Char is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.Wchar is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.Float is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.Double is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.Long_Double is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.String is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Types.Wide_String is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Any is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return TypeCode.Local_Ref is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Ada.Strings.Superbounded.Super_String is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any
     (A : Any) return Ada.Strings.Wide_Superbounded.Super_String is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   --   From_Any (Standard types) - 3 wrappers

   function From_Any (C : Any_Container'Class) return Standard.String is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (C : Any_Container'Class) return Standard.Wide_String is
   begin
      return Accessor_Impl.From_Any (C);
   end From_Any;

   function From_Any (A : Any) return Standard.String is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   function From_Any (A : Any) return Standard.Wide_String is
   begin
      return Accessor_Impl.From_Any (A);
   end From_Any;

   --------------------------------------
   --  To_Any Wrapper Stubs (20 functions)
   --------------------------------------

   function To_Any (X : Types.Octet) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.Short) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.Long) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.Long_Long) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.Unsigned_Short) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.Unsigned_Long) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.Unsigned_Long_Long) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.Boolean) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.Char) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.Wchar) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.Float) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.Double) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.Long_Double) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.String) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Types.Wide_String) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : Any) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any (X : TypeCode.Local_Ref) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   function To_Any
     (X  : Ada.Strings.Superbounded.Super_String;
      TC : access function return TypeCode.Local_Ref)
      return Any
   is
   begin
      return Accessor_Impl.To_Any (X, TC);
   end To_Any;

   function To_Any
     (X  : Ada.Strings.Wide_Superbounded.Super_String;
      TC : access function return TypeCode.Local_Ref)
      return Any
   is
   begin
      return Accessor_Impl.To_Any (X, TC);
   end To_Any;

   function To_Any (X : Standard.String) return Any is
   begin
      return Accessor_Impl.To_Any (X);
   end To_Any;

   ------------------------------------------------
   --  Set_Any_Value Wrapper Stubs (20 procedures)
   ------------------------------------------------

   procedure Set_Any_Value
     (X : Types.Short;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.Long;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.Long_Long;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.Unsigned_Short;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.Unsigned_Long;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.Unsigned_Long_Long;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.Float;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.Double;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.Long_Double;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.Boolean;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.Char;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.Wchar;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.Octet;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Any;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : TypeCode.Local_Ref;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.String;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Types.Wide_String;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X : Standard.String;
      C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X     : String;
      Bound : Positive;
      C     : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, Bound, C);
   end Set_Any_Value;

   procedure Set_Any_Value
     (X     : Wide_String;
      Bound : Positive;
      C     : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Any_Value (X, Bound, C);
   end Set_Any_Value;

   ----------------------------------------------
   --  Get_Aggregate Wrapper Stubs (8 functions)
   ----------------------------------------------

   --   Get_Aggregate_Count - 1 wrapper

   function Get_Aggregate_Count (Value : Any) return Unsigned_Long is
   begin
      return Accessor_Impl.Get_Aggregate_Count (Value);
   end Get_Aggregate_Count;

   --   Get_Aggregate_Element - 7 wrappers

   function Get_Aggregate_Element
     (ACC   : not null access Aggregate_Content'Class;
      TC    : TypeCode.Local_Ref;
      Index : Unsigned_Long;
      Mech  : not null access Mechanism)
      return Content'Class
   is
   begin
      return Accessor_Impl.Get_Aggregate_Element (ACC, TC, Index, Mech);
   end Get_Aggregate_Element;

   function Get_Aggregate_Element
     (Value : Any;
      TC    : TypeCode.Local_Ref;
      Index : Unsigned_Long)
      return Any
   is
   begin
      return Accessor_Impl.Get_Aggregate_Element (Value, TC, Index);
   end Get_Aggregate_Element;

   function Get_Aggregate_Element
     (Value : Any;
      TC    : TypeCode.Object_Ptr;
      Index : Unsigned_Long)
      return Any
   is
   begin
      return Accessor_Impl.Get_Aggregate_Element (Value, TC, Index);
   end Get_Aggregate_Element;

   function Get_Aggregate_Element
     (Value : Any;
      Index : Unsigned_Long)
      return Types.Unsigned_Long
   is
   begin
      return Accessor_Impl.Get_Aggregate_Element (Value, Index);
   end Get_Aggregate_Element;

   function Get_Aggregate_Element
     (Value : Any_Container'Class;
      Index : Unsigned_Long)
      return Types.Unsigned_Long
   is
   begin
      return Accessor_Impl.Get_Aggregate_Element (Value, Index);
   end Get_Aggregate_Element;

   function Get_Aggregate_Element
     (Value : Any;
      Index : Unsigned_Long)
      return Types.Octet
   is
   begin
      return Accessor_Impl.Get_Aggregate_Element (Value, Index);
   end Get_Aggregate_Element;

   function Get_Aggregate_Element
     (Value : Any_Container'Class;
      Index : Unsigned_Long)
      return Types.Octet
   is
   begin
      return Accessor_Impl.Get_Aggregate_Element (Value, Index);
   end Get_Aggregate_Element;

   ------------------------------------------------
   --  Set_Aggregate Wrapper Stubs (2 procedures)
   ------------------------------------------------

   procedure Set_Aggregate_Element
     (ACC    : in out Aggregate_Content'Class;
      TC     : TypeCode.Local_Ref;
      Index  : Unsigned_Long;
      From_C : in out Any_Container'Class)
   is
   begin
      Accessor_Impl.Set_Aggregate_Element (ACC, TC, Index, From_C);
   end Set_Aggregate_Element;

   -------------------------------------
   --  Wrap Wrapper Stubs (19 functions)
   -------------------------------------

   function Wrap (X : not null access Types.Octet) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap (X : not null access Types.Short) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap (X : not null access Types.Long) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap (X : not null access Types.Long_Long) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap
     (X : not null access Types.Unsigned_Short) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap
     (X : not null access Types.Unsigned_Long) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap
     (X : not null access Types.Unsigned_Long_Long)
      return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap (X : not null access Types.Boolean) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap (X : not null access Types.Char) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap (X : not null access Types.Wchar) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap (X : not null access Types.Float) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap (X : not null access Types.Double) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap
     (X : not null access Types.Long_Double) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap
     (X : not null access Types.String) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap
     (X : not null access Types.Wide_String) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap (X : not null access Any) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap
     (X : not null access TypeCode.Local_Ref) return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap
     (X : not null access Ada.Strings.Superbounded.Super_String)
      return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;

   function Wrap
     (X : not null access Ada.Strings.Wide_Superbounded.Super_String)
      return Content'Class is
   begin
      return Accessor_Impl.Wrap (X);
   end Wrap;


   --------------
   --  TypeCode --
   --------------

   --  TypeCode package body extracted to separate compilation unit
   --  See: src/polyorb-any-typecode.adb
   --  Extraction: RDB-004 Decompose polyorb-any God Class

   package body TypeCode is separate;

end PolyORB.Any;
