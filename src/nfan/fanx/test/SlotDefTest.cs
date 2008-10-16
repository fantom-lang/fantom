//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Nov 06  Andy Frank  Creation
//

using System.Reflection;
using Fan.Sys;

namespace Fanx.Test
{
  /// <summary>
  /// SlotDefTest.
  /// </summary>
  public class SlotDefTest : CompileTest
  {

  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    public override void Run()
    {
      //Play();
      verifySimple();
      verifyManyArgCtor();
      verifyMultipleCtors();
      verifyProtections();
      // TODO
      //verifyClassInit();
      verifyTypeInference();
    }

  //////////////////////////////////////////////////////////////////////////
  // Play
  //////////////////////////////////////////////////////////////////////////

/*
    string play  =
      "class Foo\n" +
      "{\n" +
      "  static Foo f() { return Make; }\n" +
      "  Int a := 6\n" +
      "}";

    public void Play()
    {
  // TODO: don't handle calling default Make()
  if (true) return;
      Class cls = compileToClass(play);
      Object foo = invoke(cls, "f");
      verify(get(foo, "a"), Int.make(6));
    }
*/

  //////////////////////////////////////////////////////////////////////////
  // Simple
  //////////////////////////////////////////////////////////////////////////

    string simple =
      "class Foo\n" +
      "{\n" +

      "  new make(Int x)\n" +
      "  {\n" +
      "    this.x = x;\n" +
      "  }\n" +

      "  Int x\n" +
      "  Int y := 3\n" +
      "  static const Int z := 4\n" +

      "  static Foo f() { return make(2); }\n" +
      "}";

    public void verifySimple()
    {
      System.Type type = CompileToType(simple);
      object o = type.InvokeMember("F", GetStaticFlags(), null, null, new object[0]);
        verify(Get(o, "x")   == Int.make(2));
        verify(Get(o, "y")   == Int.make(3));
        verify(Get(type, "z") == Int.make(4));
    }

  //////////////////////////////////////////////////////////////////////////
  // verifyManyArgCtor
  //////////////////////////////////////////////////////////////////////////

    string manyArgCtor =
      "class Foo\n" +
      "{\n" +

      "  new make(Int a, Int b, Int c, Int d, Int e, Int f, Int g)\n" +
      "  {\n" +
      "    this.a = a\n" +
      "    this.b = b\n" +
      "    this.c = c\n" +
      "    this.d = d\n" +
      "    this.e = e\n" +
      "    this.f = f\n" +
      "    this.g = g\n" +
      "  }\n" +

      "  Int a\n" +
      "  Int b\n" +
      "  Int c\n" +
      "  Int d\n" +
      "  Int e\n" +
      "  Int f\n" +
      "  Int g\n" +

      "  static Foo what() { return make(1, 2, 3, 4, 5, 6, 7); }\n" +
      "}";

    public void verifyManyArgCtor()
    {
      System.Type type = CompileToType(manyArgCtor);
      object o = type.InvokeMember("What", GetStaticFlags(), null, null, new object[0]);
        verify(Get(o, "a")   == Int.make(1));
        verify(Get(o, "b")   == Int.make(2));
        verify(Get(o, "c")   == Int.make(3));
        verify(Get(o, "d")   == Int.make(4));
        verify(Get(o, "e")   == Int.make(5));
        verify(Get(o, "f")   == Int.make(6));
        verify(Get(o, "g")   == Int.make(7));
    }

  //////////////////////////////////////////////////////////////////////////
  // MultipleCtors
  //////////////////////////////////////////////////////////////////////////

    string multipleCtors =
      "class Foo\n" +
      "{\n" +

      "  new make()\n" +
      "  {\n" +
      "    s2 = s2 + \" overwritten\" \n" +
      "  }\n" +

      "  new makeArgs(Int i0, Str s0)\n" +
      "  {\n" +
      "    this.i0 = i0;\n" +
      "    this.s0 = s0;\n" +
      "    s2 = s2 + \" overwritten\" \n" +
      "  }\n" +

      "  static Int zero() { return 0; }\n" +
      "  static Int one()  { return 1; }\n" +
      "  static Foo make0()                { return make }\n" +
      "  static Foo make1()                { return Foo.make }\n" +
      "  static Foo make2(Int i0, Str s0)  { return makeArgs(i0, s0); }\n" +
      "  static Foo make3(Int i0, Str s0)  { return (Foo.makeArgs(i0, s0)); }\n" +
      "  static Str makeAndGet(Str s0)     { return makeArgs(-1, s0).s0; }\n" +
      "  Int i1PreInc()  { return ++i1; }\n" +
      "  Int i1PostInc() { return i1++; }\n" +
      "  Int fooPreInc()  { return ++foo.i1; }\n" +
      "  Int fooPostInc() { return foo.i1++; }\n" +

      "  Int i0;\n" +
      "  Int i1 := 7;\n" +
      "  Double r0 := 7.0;\n" +  // auto-casts
      "  Double r1 := 7.0;\n" +
      "  Str s0;\n" +
      "  Str s1 := \"hello\";\n" +
      "  Str s2 := \"s2\";\n" +
      "  Foo foo;\n" +
      "  \n" +
      "  static const Int  si := 3\n" +
      "  static const Double sr := 7.0\n" +  // auto-cast
      "  static const Str  ss\n" +      // default to null
      "  static const Int  sx\n" +      // compute in static {}
      "  \n" +
      "  static\n" +
      "  {\n" +
      "    sx = si + 6\n" +
      "  }\n" +
      "}\n";

    public void verifyMultipleCtors()
    {
      System.Type type = CompileToType(multipleCtors);
      object o;

      // static fields
      verify(Get(type, "si").Equals(Int.make(3)));
      verify(Get(type, "sr").Equals(Double.valueOf(7)));
      verify(Get(type, "ss") == null);
      verify(Get(type, "sx").Equals(Int.make(9)));

      // static methods
      o = type.InvokeMember("Zero", GetStaticFlags(), null, null, new object[0]);
        verify(o.Equals(Int.make(0)));
      o = type.InvokeMember("One", GetStaticFlags(), null, null, new object[0]);
        verify(o.Equals(Int.make(1)));

      object x = type.InvokeMember("Make", GetStaticFlags(), null, null, new object[0]);
      object y = type.InvokeMember("Make", GetStaticFlags(), null, null, new object[0]);
      verifyDefInit(x);
      o = type.InvokeMember("I1PreInc", GetInstanceFlags(), null, x, new object[0]);
        verify(o.Equals(Int.make(8)));
        verify(Get(x, "i1").Equals(Int.make(8)));
      o = type.InvokeMember("I1PostInc", GetInstanceFlags(), null, x, new object[0]);
        verify(o.Equals(Int.make(8)));
        verify(Get(x, "i1").Equals(Int.make(9)));

      type.GetField("foo", GetInstanceFlags()).SetValue(x, y);
      o = type.InvokeMember("FooPreInc", GetInstanceFlags(), null, x, new object[0]);
        verify(o.Equals(Int.make(8)));
        verify(Get(x, "i1").Equals(Int.make(9)));
        verify(Get(y, "i1").Equals(Int.make(8)));
      o = type.InvokeMember("FooPostInc", GetInstanceFlags(), null, x, new object[0]);
        verify(o.Equals(Int.make(8)));
        verify(Get(x, "i1").Equals(Int.make(9)));
        verify(Get(y, "i1").Equals(Int.make(9)));

      // instance fields
      x = type.InvokeMember("MakeArgs", GetStaticFlags(), null, null, new object[] { Int.make(88), Str.make("lombardy") });
      verifyInit(x, 88, "lombardy");

      // factory method
      x = type.InvokeMember("Make0", GetStaticFlags(), null, null, new object[0]);
      verifyDefInit(x);
      x = type.InvokeMember("Make1", GetStaticFlags(), null, null, new object[0]);
      verifyDefInit(x);
      x = type.InvokeMember("Make2", GetStaticFlags(), null, null, new object[] { Int.make(62), Str.make("fan rocks") });
      verifyInit(x, 62, "fan rocks");
      x = type.InvokeMember("Make3", GetStaticFlags(), null, null, new object[] { Int.make(63), Str.make("fan really rocks") });
      verifyInit(x, 63, "fan really rocks");
      x = type.InvokeMember("MakeAndGet", GetStaticFlags(), null, null, new object[] { Str.make("Haley dog!") });
      verify(x.Equals(Str.make("Haley dog!")));
    }

    void verifyDefInit(object x)
    {
      verify(Get(x, "i0") == null);
      verify(Get(x, "i1").Equals(Int.make(7)));
      verify(Get(x, "s0") == null);
      verify(Get(x, "s1").Equals(Str.make("hello")));
      verify(Get(x, "s2"), Str.make("s2 overwritten"));
    }

    void verifyInit(object x, int i0, string s0)
    {
      verify(Get(x, "i0").Equals(Int.make(i0)));
      verify(Get(x, "i1").Equals(Int.make(7)));
      verify(Get(x, "s0").Equals(Str.make(s0)));
      verify(Get(x, "s1").Equals(Str.make("hello")));
      verify(Get(x, "s2").Equals(Str.make("s2 overwritten")));
    }

    void verifyMethodFlags(System.Type type, string name, MethodAttributes attrs)
    {
      verifyMethodFlags(type, name, attrs, false);
    }

    void verifyMethodFlags(System.Type type, string name, MethodAttributes attrs, bool not)
    {
      MethodInfo m = type.GetMethod(name,
        BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.DeclaredOnly| BindingFlags.Instance);
      MethodAttributes actual = m.Attributes;
//System.Console.WriteLine("actual/attrs " + actual + " :: " + attrs + " --> " + (actual == attrs));
      if (not)
        verify(actual != attrs);
      else
        verify(actual == attrs);
    }

  //////////////////////////////////////////////////////////////////////////
  // Protection Scope
  //////////////////////////////////////////////////////////////////////////

    string protections =
      "class Foo\n" +
      "{\n" +
      "            Void mDefault()   {}\n" +
      "  public    Void mPublic()    {}\n" +
      "  protected Void mProtected() {}\n" +
      "  internal  Void mInternal()  {}\n" +
      "  private   Void mPrivate()   {}\n" +
      "}\n";

    void verifyProtections()
    {
      System.Type type = CompileToType(protections);

      // protection scope methods
      verifyMethodFlags(type, "MDefault",   MethodAttributes.Public);
      verifyMethodFlags(type, "MDefault",   MethodAttributes.Static, true);
      verifyMethodFlags(type, "MPublic",    MethodAttributes.Public);
      verifyMethodFlags(type, "MPublic",    MethodAttributes.Static, true);
      verifyMethodFlags(type, "MProtected", MethodAttributes.Public); // protected+internal closures
      verifyMethodFlags(type, "MInternal",  MethodAttributes.Public | MethodAttributes.Family | MethodAttributes.Private, true);
      verifyMethodFlags(type, "MPrivate",   MethodAttributes.Public | MethodAttributes.Family | MethodAttributes.Private, true); // internal closures
    }

  //////////////////////////////////////////////////////////////////////////
  // Static Class Initialization
  //////////////////////////////////////////////////////////////////////////

/*
    string classInit =
      "class Foo\n" +
      "{\n" +

      "  static Int a := 1 \n" +
      "  static Int b := 2 \n" +
      "  static Int c := a + b \n" +
      "  static Int d := a + b \n" +
      "  static { d = -1 }\n" +
      "  static Int e := d\n" +
      "  static Int f\n" +
      "  static { f = e + 9 }\n" +

      "}\n";

    static int a = 1;
    static int b = 2;
    static int c = a + b;
    static int d = a + b;
    static int e = d;
    static int f;
    static SlotDefTest()
    {
      d = -1;
      e = d;
      f = e  + 9;
    }

    public void verifyClassInit()
    {
      System.Type type = CompileToType(classInit);

      verify(Get(type, "a").Equals(Int.make(a)));
      verify(Get(type, "b").Equals(Int.make(b)));
      verify(Get(type, "c").Equals(Int.make(c)));
      verify(Get(type, "d").Equals(Int.make(d)));
      verify(Get(type, "e").Equals(Int.make(e)));
      verify(Get(type, "f").Equals(Int.make(f)));
    }
*/

  //////////////////////////////////////////////////////////////////////////
  // TypeInference
  //////////////////////////////////////////////////////////////////////////

    string typeInference =
      "class Foo \n" +
      "{\n" +

      // some static methods
      " static Bool b() { return true }\n" +
      " static Int  i() { return 5 }\n" +

      // basic literals
      "  static const Bool lb := true \n" +
      "  static const Int li := 3 \n" +
      "  static const Double lr := 6.9 \n" +
      "  static const Str ls := \"inference rules!\" \n" +
      "  static const Duration lt := 5ns \n" +
      "  //static lsa := [ \"a\", \"b\" ] \n" +
      "  //static lta := Duration[] \n" +

      // math expressions
// Andy - TODO
//      "  static m1 := 3 * 4 \n" +
//      "  static m2 := 3.7 + 4.0 \n" +

      // call expression chains
// Andy - TODO
//      "  static call0 := 0xab.toHex() \n" +
//      "  static call1 := 0xab.toHex().size() \n" +

      // my methods, my fields (doesn't work yet, type inference before bind)
      //"  static methodb := b() \n" +
      //"  static methodi := i() \n" +


      // local var type inference
      "static Obj local0() { x := \"inferred\"; return x }\n" +
      "static Obj local1() { x := \"foo\"; y := x; return y }\n" +
      "static Obj local2() { x := ls; return x }\n" +

      "}\n";

    public void verifyTypeInference()
    {
      System.Type type = CompileToType(typeInference);

      // literals
      verify(Get(type, "lb"),  Bool.True);
      verify(Get(type, "li"),  Int.make(3));
      verify(Get(type, "lr"),  Double.valueOf(6.9));
      verify(Get(type, "ls"),  Str.make("inference rules!"));
      verify(Get(type, "lt"),  Duration.make(5));
  // TODO
  //    verify(Get(type, "lsa"), new List(String.class).add(Str.make("a")).add(Str.make("b")));
  //    verify(Get(type, "lta"), new List(Duration.class));

      // math
// Andy - TODO
//      verify(Get(type, "m1"), Int.make(12));
//      verify(Get(type, "m2"), Double.make(7.7));

      // call chains
// Andy - TODO
//      verify(Get(type, "call0"), Str.make("ab"));
//      verify(Get(type, "call1"), Int.make(2));

      // my methods (doesn't work, type inference before bind)
      //verify(Get(type, "methodb"), new Boolean(true));
      //verify(Get(type, "methodi"), Int.make(5));

      // local type inference
// Andy - TODO
//      verify(Invoke(type, "local0"), Str.make("inferred"));
//      verify(Invoke(type, "local1"), Str.make("foo"));
//      verify(Invoke(type, "local2"), Str.make("inference rules!"));
    }

  //////////////////////////////////////////////////////////////////////////
  // TODO
  //////////////////////////////////////////////////////////////////////////

    // TODO: Default constructor 'Make' conflicts with another slot
  }
}