------------------------------------------------------------------------------
--                           POLYORB COMPONENTS                             --
--                                                                          --
--         P O L Y O R B . A N Y . A C C E S S O R _ I M P L                --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2001-2025, Free Software Foundation, Inc.          --
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

separate (PolyORB.Any)

package body Accessor_Impl is

   -- From_Any (Container) renames (lines 1355-1388)

   function From_Any (C : Any_Container'Class) return Types.Octet
                      renames Elementary_Any_Octet.From_Any;
   function From_Any (C : Any_Container'Class) return Types.Short
                      renames Elementary_Any_Short.From_Any;
   function From_Any (C : Any_Container'Class) return Types.Long
                      renames Elementary_Any_Long.From_Any;
   function From_Any (C : Any_Container'Class) return Types.Long_Long
                      renames Elementary_Any_Long_Long.From_Any;
   function From_Any (C : Any_Container'Class) return Types.Unsigned_Short
                      renames Elementary_Any_UShort.From_Any;
   function From_Any (C : Any_Container'Class) return Types.Unsigned_Long
                      renames Elementary_Any_ULong.From_Any;
   function From_Any (C : Any_Container'Class) return Types.Unsigned_Long_Long
                      renames Elementary_Any_ULong_Long.From_Any;
   function From_Any (C : Any_Container'Class) return Types.Boolean
                      renames Elementary_Any_Boolean.From_Any;
   function From_Any (C : Any_Container'Class) return Types.Char
                      renames Elementary_Any_Char.From_Any;
   function From_Any (C : Any_Container'Class) return Types.Wchar
                      renames Elementary_Any_Wchar.From_Any;
   function From_Any (C : Any_Container'Class) return Types.Float
                      renames Elementary_Any_Float.From_Any;
   function From_Any (C : Any_Container'Class) return Types.Double
                      renames Elementary_Any_Double.From_Any;
   function From_Any (C : Any_Container'Class) return Types.Long_Double
                      renames Elementary_Any_Long_Double.From_Any;
   function From_Any (C : Any_Container'Class) return Types.String
                      renames Elementary_Any_String.From_Any;
   function From_Any (C : Any_Container'Class) return Types.Wide_String
                      renames Elementary_Any_Wide_String.From_Any;
   function From_Any (C : Any_Container'Class) return Any
                      renames Elementary_Any_Any.From_Any;
   function From_Any (C : Any_Container'Class) return TypeCode.Local_Ref
                      renames Elementary_Any_TypeCode.From_Any;

   -- From_Any (Any) renames (lines 1390-1429)

   function From_Any (A : Any) return Types.Octet
                      renames Elementary_Any_Octet.From_Any;
   function From_Any (A : Any) return Types.Short
                      renames Elementary_Any_Short.From_Any;
   function From_Any (A : Any) return Types.Long
                      renames Elementary_Any_Long.From_Any;
   function From_Any (A : Any) return Types.Long_Long
                      renames Elementary_Any_Long_Long.From_Any;
   function From_Any (A : Any) return Types.Unsigned_Short
                      renames Elementary_Any_UShort.From_Any;
   function From_Any (A : Any) return Types.Unsigned_Long
                      renames Elementary_Any_ULong.From_Any;
   function From_Any (A : Any) return Types.Unsigned_Long_Long
                      renames Elementary_Any_ULong_Long.From_Any;
   function From_Any (A : Any) return Types.Boolean
                      renames Elementary_Any_Boolean.From_Any;
   function From_Any (A : Any) return Types.Char
                      renames Elementary_Any_Char.From_Any;
   function From_Any (A : Any) return Types.Wchar
                      renames Elementary_Any_Wchar.From_Any;
   function From_Any (A : Any) return Types.Float
                      renames Elementary_Any_Float.From_Any;
   function From_Any (A : Any) return Types.Double
                      renames Elementary_Any_Double.From_Any;
   function From_Any (A : Any) return Types.Long_Double
                      renames Elementary_Any_Long_Double.From_Any;
   function From_Any (A : Any) return Types.String
                      renames Elementary_Any_String.From_Any;
   function From_Any (A : Any) return Types.Wide_String
                      renames Elementary_Any_Wide_String.From_Any;
   function From_Any (A : Any) return Any
                      renames Elementary_Any_Any.From_Any;
   function From_Any (A : Any) return TypeCode.Local_Ref
                      renames Elementary_Any_TypeCode.From_Any;
   function From_Any
     (A : Any) return Ada.Strings.Superbounded.Super_String
     renames Elementary_Any_Bounded_String.From_Any;
   function From_Any
     (A : Any) return Ada.Strings.Wide_Superbounded.Super_String
     renames Elementary_Any_Bounded_Wide_String.From_Any;

   -- From_Any (Standard.String) full body (lines 1435-1456)

   function From_Any (C : Any_Container'Class) return Standard.String is
      Bound : constant Types.Unsigned_Long :=
        TypeCode.Length (Unwind_Typedefs (Get_Type_Obj (C)));
   begin
      if Bound = 0 then

         --  Unbounded case
         --  Use unchecked access to underlying Types.String to avoid
         --  a costly Adjust.

         return To_Standard_String
           (Elementary_Any_String.Unchecked_Get_V
            (Elementary_Any_String.T_Content (C.The_Value.all)'Access).all);

      else

         --  Bounded case

         return Ada.Strings.Superbounded.Super_To_String
           (Elementary_Any_Bounded_String.From_Any (C));
      end if;
   end From_Any;

   -- From_Any (Standard.Wide_String) full body (lines 1458-1480)

   function From_Any (C : Any_Container'Class) return Standard.Wide_String is
      Bound : constant Types.Unsigned_Long :=
        TypeCode.Length (Unwind_Typedefs (Get_Type_Obj (C)));
   begin
      if Bound = 0 then

         --  Unbounded case
         --  Use unchecked access to underlying Types.String to avoid
         --  a costly Adjust.

         return To_Wide_String
           (Elementary_Any_Wide_String.Unchecked_Get_V
            (Elementary_Any_Wide_String.T_Content
             (C.The_Value.all)'Access).all);

      else

         --  Bounded case

         return Ada.Strings.Wide_Superbounded.Super_To_String
           (Elementary_Any_Bounded_Wide_String.From_Any (C));
      end if;
   end From_Any;

   -- From_Any generic instantiations + renames (lines 1482-1489)

   function String_From_Any is new From_Any_G (Standard.String, From_Any);
   function From_Any (A : Any) return Standard.String
                      renames String_From_Any;

   function Wide_String_From_Any is
     new From_Any_G (Standard.Wide_String, From_Any);
   function From_Any (A : Any) return Standard.Wide_String
                      renames Wide_String_From_Any;

   -- Get_Aggregate_Count (non-overriding) (lines 1495-1501)

   function Get_Aggregate_Count (Value : Any) return Unsigned_Long
   is
      CA_Ptr : constant Aggregate_Content_Ptr :=
        Aggregate_Content_Ptr (Get_Value (Get_Container (Value).all));
   begin
      return Get_Aggregate_Count (CA_Ptr.all);
   end Get_Aggregate_Count;

   -- Get_Aggregate_Element (overload 1) (lines 1515-1524)

   function Get_Aggregate_Element
     (ACC   : not null access Aggregate_Content'Class;
      TC    : TypeCode.Local_Ref;
      Index : Unsigned_Long;
      Mech  : not null access Mechanism) return Content'Class
   is
   begin
      return Get_Aggregate_Element (ACC, TypeCode.Object_Of (TC), Index, Mech);
   end Get_Aggregate_Element;


   -- Get_Aggregate_Element (overload 2) (lines 1580-1588)

   function Get_Aggregate_Element
     (Value : Any;
      TC    : TypeCode.Local_Ref;
      Index : Unsigned_Long) return Any
   is
   begin
      return Get_Aggregate_Element (Value, TypeCode.Object_Of (TC), Index);
   end Get_Aggregate_Element;


   -- Get_Aggregate_Element (overload 3) (lines 1589-1614)

   function Get_Aggregate_Element
     (Value : Any;
      TC    : TypeCode.Object_Ptr;
      Index : Unsigned_Long) return Any
   is
      --  Enforce tag check on Value's container to defend against improper
      --  access for an Any that is not an aggregate.

      pragma Unsuppress (Tag_Check);
      CA_Ptr : constant Aggregate_Content_Ptr :=
        Aggregate_Content_Ptr (Get_Container (Value).The_Value);

      A : Any;
      M : aliased Mechanism := By_Value;
      CC : constant Content'Class :=
        Get_Aggregate_Element (CA_Ptr, TC, Index, M'Access);

      New_CC : Content_Ptr;
   begin
      Set_Type (A, TC);

      New_CC := Clone (CC);

      Set_Value (Get_Container (A).all,  New_CC, Foreign => False);
      return A;
   end Get_Aggregate_Element;

   -- Get_Aggregate_Element renames - Unsigned_Long (lines 1616-1624)

   function Get_Aggregate_Element
     (Value : Any;
      Index : Unsigned_Long) return Types.Unsigned_Long
     renames Elementary_Any_ULong.Get_Aggregate_Element;

   function Get_Aggregate_Element
     (Value : Any_Container'Class;
      Index : Unsigned_Long) return Types.Unsigned_Long
     renames Elementary_Any_ULong.Get_Aggregate_Element;

   -- Get_Aggregate_Element renames - Octet (lines 1626-1634)

   function Get_Aggregate_Element
     (Value : Any;
      Index : Unsigned_Long) return Types.Octet
     renames Elementary_Any_Octet.Get_Aggregate_Element;

   function Get_Aggregate_Element
     (Value : Any_Container'Class;
      Index : Unsigned_Long) return Types.Octet
     renames Elementary_Any_Octet.Get_Aggregate_Element;

   -- Set_Aggregate_Element (non-overriding wrapper)
   -- For Aggregate_Content'Class (lines 2128-2136)

   procedure Set_Aggregate_Element
     (ACC    : in out Aggregate_Content'Class;
      TC     : TypeCode.Local_Ref;
      Index  : Unsigned_Long;
      From_C : in out Any_Container'Class)
   is
   begin
      Set_Aggregate_Element (ACC, TypeCode.Object_Of (TC), Index, From_C);
   end Set_Aggregate_Element;

   -- Set_Any_Value (all 20 procedures) (lines 2221-2294)

   procedure Set_Any_Value (X : Types.Short;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_Short.Set_Any_Value;
   procedure Set_Any_Value (X : Types.Long;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_Long.Set_Any_Value;
   procedure Set_Any_Value (X : Types.Long_Long;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_Long_Long.Set_Any_Value;
   procedure Set_Any_Value (X : Types.Unsigned_Short;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_UShort.Set_Any_Value;
   procedure Set_Any_Value (X : Types.Unsigned_Long;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_ULong.Set_Any_Value;
   procedure Set_Any_Value (X : Types.Unsigned_Long_Long;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_ULong_Long.Set_Any_Value;
   procedure Set_Any_Value (X : Types.Float;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_Float.Set_Any_Value;
   procedure Set_Any_Value (X : Types.Double;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_Double.Set_Any_Value;
   procedure Set_Any_Value (X : Types.Long_Double;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_Long_Double.Set_Any_Value;
   procedure Set_Any_Value (X : Types.Boolean;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_Boolean.Set_Any_Value;
   procedure Set_Any_Value (X : Types.Char;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_Char.Set_Any_Value;
   procedure Set_Any_Value (X : Types.Wchar;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_Wchar.Set_Any_Value;
   procedure Set_Any_Value (X : Types.Octet;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_Octet.Set_Any_Value;
   procedure Set_Any_Value (X : Any;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_Any.Set_Any_Value;
   procedure Set_Any_Value (X : TypeCode.Local_Ref;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_TypeCode.Set_Any_Value;
   procedure Set_Any_Value (X : Types.String;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_String.Set_Any_Value;
   procedure Set_Any_Value (X : Types.Wide_String;
                            C : in out Any_Container'Class)
                            renames Elementary_Any_Wide_String.Set_Any_Value;

   procedure Set_Any_Value
     (X : Standard.String; C : in out Any_Container'Class)
   is
   begin
      Set_Any_Value (To_PolyORB_String (X), C);
   end Set_Any_Value;

   procedure Set_Any_Value (X : String; Bound : Positive;
                            C : in out Any_Container'Class) is
   begin
      Elementary_Any_Bounded_String.Set_Any_Value
        (Ada.Strings.Superbounded.To_Super_String
           (X, Max_Length => Bound), C);
   end Set_Any_Value;

   procedure Set_Any_Value (X : Wide_String; Bound : Positive;
                            C : in out Any_Container'Class) is
   begin
      Elementary_Any_Bounded_Wide_String.Set_Any_Value
        (Ada.Strings.Wide_Superbounded.To_Super_String
           (X, Max_Length => Bound), C);
   end Set_Any_Value;

   -- To_Any (package, instantiations, implementations) (lines 2358-2498)

   package To_Any_Instances is
      function To_Any is
        new To_Any_G
          (Types.Octet, TC_Octet, Elementary_Any_Octet.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.Short, TC_Short, Elementary_Any_Short.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.Long, TC_Long, Elementary_Any_Long.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.Long_Long, TC_Long_Long,
           Elementary_Any_Long_Long.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.Unsigned_Short, TC_Unsigned_Short,
           Elementary_Any_UShort.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.Unsigned_Long, TC_Unsigned_Long,
           Elementary_Any_ULong.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.Unsigned_Long_Long, TC_Unsigned_Long_Long,
           Elementary_Any_ULong_Long.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.Boolean, TC_Boolean, Elementary_Any_Boolean.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.Char, TC_Char, Elementary_Any_Char.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.Wchar, TC_Wchar, Elementary_Any_Wchar.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.Float, TC_Float, Elementary_Any_Float.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.Double, TC_Double, Elementary_Any_Double.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.Long_Double, TC_Long_Double,
           Elementary_Any_Long_Double.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.String, TC_String, Elementary_Any_String.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Types.Wide_String, TC_Wide_String,
           Elementary_Any_Wide_String.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (Any, TC_Any, Elementary_Any_Any.Set_Any_Value);

      function To_Any is
        new To_Any_G
          (TypeCode.Local_Ref, TC_TypeCode,
           Elementary_Any_TypeCode.Set_Any_Value);

   end To_Any_Instances;

   function To_Any (X : Types.Octet) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.Short) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.Long) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.Long_Long) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.Unsigned_Short) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.Unsigned_Long) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.Unsigned_Long_Long) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.Boolean) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.Char) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.Wchar) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.Float) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.Double) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.Long_Double) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.String) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Types.Wide_String) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : Any) return Any
                    renames To_Any_Instances.To_Any;
   function To_Any (X : TypeCode.Local_Ref) return Any
                    renames To_Any_Instances.To_Any;

   function To_Any
     (X  : Ada.Strings.Superbounded.Super_String;
      TC : access function return TypeCode.Local_Ref) return Any
   is
      function To_Any is
        new To_Any_G
          (Ada.Strings.Superbounded.Super_String, TC.all,
           Elementary_Any_Bounded_String.Set_Any_Value);
   begin
      return To_Any (X);
   end To_Any;

   function To_Any
     (X  : Ada.Strings.Wide_Superbounded.Super_String;
      TC : access function return TypeCode.Local_Ref) return Any
   is
      function To_Any is
        new To_Any_G
          (Ada.Strings.Wide_Superbounded.Super_String, TC.all,
           Elementary_Any_Bounded_Wide_String.Set_Any_Value);
   begin
      return To_Any (X);
   end To_Any;

   function To_Any (X : Standard.String) return Any is
   begin
      return To_Any (To_PolyORB_String (X));
   end To_Any;

   -- Wrap renames (19 functions) (lines 2542-2601)

   function Wrap
     (X : not null access Types.Octet) return Content'Class
     renames Elementary_Any_Octet.Wrap;
   function Wrap
     (X : not null access Types.Short) return Content'Class
     renames Elementary_Any_Short.Wrap;
   function Wrap
     (X : not null access Types.Long) return Content'Class
     renames Elementary_Any_Long.Wrap;
   function Wrap
     (X : not null access Types.Long_Long) return Content'Class
     renames Elementary_Any_Long_Long.Wrap;
   function Wrap
     (X : not null access Types.Unsigned_Short) return Content'Class
     renames Elementary_Any_UShort.Wrap;
   function Wrap
     (X : not null access Types.Unsigned_Long) return Content'Class
     renames Elementary_Any_ULong.Wrap;
   function Wrap
     (X : not null access Types.Unsigned_Long_Long) return Content'Class
     renames Elementary_Any_ULong_Long.Wrap;
   function Wrap
     (X : not null access Types.Boolean) return Content'Class
     renames Elementary_Any_Boolean.Wrap;
   function Wrap
     (X : not null access Types.Char) return Content'Class
     renames Elementary_Any_Char.Wrap;
   function Wrap
     (X : not null access Types.Wchar) return Content'Class
     renames Elementary_Any_Wchar.Wrap;
   function Wrap
     (X : not null access Types.Float) return Content'Class
     renames Elementary_Any_Float.Wrap;
   function Wrap
     (X : not null access Types.Double) return Content'Class
     renames Elementary_Any_Double.Wrap;
   function Wrap
     (X : not null access Types.Long_Double) return Content'Class
     renames Elementary_Any_Long_Double.Wrap;
   function Wrap
     (X : not null access Types.String) return Content'Class
     renames Elementary_Any_String.Wrap;
   function Wrap
     (X : not null access Types.Wide_String) return Content'Class
     renames Elementary_Any_Wide_String.Wrap;

   function Wrap (X : not null access Any) return Content'Class
     renames Elementary_Any_Any.Wrap;

   function Wrap (X : not null access TypeCode.Local_Ref) return Content'Class
     renames Elementary_Any_TypeCode.Wrap;

   function Wrap
     (X : not null access Ada.Strings.Superbounded.Super_String)
      return Content'Class
     renames Elementary_Any_Bounded_String.Wrap;
   function Wrap
     (X : not null access Ada.Strings.Wide_Superbounded.Super_String)
      return Content'Class
     renames Elementary_Any_Bounded_Wide_String.Wrap;

end Accessor_Impl;
