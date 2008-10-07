//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 06  Andy Frank  Creation
//

using System.Reflection;
using Fan.Sys;

namespace Fanx.Test
{
  /// <summary>
  /// ListTest.
  /// </summary>
  public class ListTest: CompileTest
  {

  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    public override void Run()
    {
      verifyKernel();
      verifyReflect();
      verifyLang();
      verifyUnparameterized();
    }

  //////////////////////////////////////////////////////////////////////////
  // Kernel
  //////////////////////////////////////////////////////////////////////////

    public void verifyKernel()
    {
      Str a = Str.make("a"), b = Str.make("b"), c = Str.make("c"),
          d = Str.make("d"), e = Str.make("e"), f = Str.make("f");
      Int i0 = Int.make(0);
      Int i1 = Int.make(1);
      Int i2 = Int.make(2);

      List x = new List(Sys.StrType);
      verify(x);

      x.add(a); verify(x, a);
      x.add(b); verify(x, a, b);
      x.add(c); verify(x, a, b, c);
      x.insert(i0, d); verify(x, d, a, b, c);
      x.insert(i1, e); verify(x, d, e, a, b, c);
      x.removeAt(i0); verify(x, e, a, b, c);
      x.removeAt(i2); verify(x, e, a, c);
      x.removeAt(i2); verify(x, e, a);
      x.removeAt(i1); verify(x, e);
      x.removeAt(i0); verify(x);

      for (int i=0; i<100; ++i)
      {
        List list = new List(Sys.ObjType);
        object[] match = new object[i];

        for (int j=0; j<i; ++j)
          list.add(match[j] = Int.make(j));
        verify(list, match);

        for (int j=0; j<i; ++j)
          list.removeAt(i0);
        verify(list);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Reflect
  //////////////////////////////////////////////////////////////////////////

    public void verifyReflect()
    {
      System.Type nt = CompileToType("class Foo { static Type f() { return Str[,].type() } }");
      Type t = (Type)InvokeStatic(nt, "F");
      //t.Dump();

      Method get = t.method("get", true);
      verify(get.returns() == Sys.StrType);

      Method add = t.method("add", true);
      verify(((Param)add.@params().get(0)).of() == Sys.StrType);
      verify(add.returns() == t);
    }

  //////////////////////////////////////////////////////////////////////////
  // Lang
  //////////////////////////////////////////////////////////////////////////

    public void verifyLang()
    {
      verify("Obj f() { return [,] }",    new List(Sys.ObjType));
      verify("Obj f() { return Str[,] }", new List(Sys.StrType));

      // adds
      verify("Obj f(Str[] x) { x.add(\"a\"); return x }", new object[] {new List(Sys.StrType)}, Make("a"));
      verify("Obj f(Str[] x) { x.add(\"a\"); x.add(\"b\"); return x }", new object[] {new List(Sys.StrType)}, Make("a", "b"));

      // literals
      verify("Obj f() { return [,] }", new List(Sys.ObjType));
      verify("Obj f() { return [\"a\"] }", Make("a"));
      verify("Obj f() { return [\"a\", \"b\"]; }", Make("a", "b"));
      verify("Obj f() { return [ \"a\" , \"b\" , \"c\" ] }", Make("a", "b", "c"));
      verify("Obj f() { return [ \"a\" , \"b\" , \"c\", ] }", Make("a", "b", "c"));  // extra comma

      // explicit typing: empty literal
      verify("Obj f() { return Str[,] }", new List(Sys.StrType));
      // explicit typing: single item - not figured out until resolve time
      verify("Obj f() { return Str[\"a\"] }", Make("a"));
      // explicit typing: single item, trailing comma
      verify("Obj f() { return Str[\"a\",] }", Make("a"));
      // explicit typing: multiple items
      verify("Obj f() { return Str[\"a\", \"b\"] }", Make("a", "b"));

      // slicing
      object[] args = { Make("0", "1", "2", "3") };
      verify("Obj f(Str[] x) { return x[0] }", args, Str.make("0"));
      verify("Str f(Str[] x) { return x[1] }", args, Str.make("1"));
      verify("Obj f(Str[] x) { return x[2] }", args, Str.make("2"));
      verify("Str f(Str[] x) { return x[3] }", args, Str.make("3"));
      verify("Obj f(Str[] x) { return x[-1] }", args, Str.make("3"));
      verify("Str f(Str[] x) { return x[-2] }", args, Str.make("2"));
      verify("Obj f(Str[] x) { return x[-3] }", args, Str.make("1"));
      verify("Str f(Str[] x) { return x[-4] }", args, Str.make("0"));
      verifyThrows("Obj f(Str[] x) { return x[4] }",  args, System.Type.GetType("Fan.Sys.IndexErr+Val"));
      verifyThrows("Str f(Str[] x) { return x[5] }",  args, System.Type.GetType("Fan.Sys.IndexErr+Val"));
      verifyThrows("Obj f(Str[] x) { return x[-5] }", args, System.Type.GetType("Fan.Sys.IndexErr+Val"));
      verifyThrows("Str f(Str[] x) { return x[-6] }", args, System.Type.GetType("Fan.Sys.IndexErr+Val"));

      // parameterized typing
//      verifyErr("Int f(Str[] x) { return x[0] }", "Cannot return 'sys::Str' as 'sys::Int'");
//      verifyErr("Void f(Str[] x) { x.add(3) }", "Invalid args add(sys::Int) for add(sys::Str)");
//      verifyErr("Void f(Str[] x, Obj a) { x.add(a) }", "Invalid args add(sys::Obj) for add(sys::Str)");
      //verifyErr("Int[] f(Str[] x) { return x }", "Cannot return 'sys::Str[]' as 'sys::Int[]'");

      // TODO - just List; should we allow List/Map to be used or force use of Obj[]?
      // verify("Obj f(List x) { return x[0] }", args, Str.make("0"));

      // errors
//      verifyErr("Obj f([] x) {}",             "Expected type identifier, not ']'");
//      verifyErr("Obj f() { return [] }",      "Invalid list literal; use '[,]' for empty Obj[] list");
//      verifyErr("Obj f() { return Str[] }",   "Invalid use of type name as expression");
//      verifyErr("Obj f() { return this[] }",  "Expected expression, not ']'");
//      verifyErr("Obj f() { return X[] }",     "Unresolved type 'X'");
//      verifyErr("Obj f() { return X[,] }",    "Unresolved type 'X'");
//      verifyErr("Obj f() { return x[3] }",    "Unknown variable 'x'");
//      verifyErr("Obj f() { return [,3] }",    "Expected ']', not '3'");
//      verifyErr("Obj f() { return [,foo] }",  "Expected ']', not 'foo'");
    }

  //////////////////////////////////////////////////////////////////////////
  // Unparameterized
  //////////////////////////////////////////////////////////////////////////

    public void verifyUnparameterized()
    {
      object[] args = { Make("0", "1", "2", "3") };
      verify("Obj f(List x) { return x[0] }", args, Str.make("0"));
      verify("Obj f(List x) { return x.get(2) }", args, Str.make("2"));
    }

  //////////////////////////////////////////////////////////////////////////
  // Convenience
  //////////////////////////////////////////////////////////////////////////

    public List Make(string a) { return new List(Sys.StrType, MakeStrs(a)); }
    public List Make(string a, string b) { return new List(Sys.StrType, MakeStrs(a, b)); }
    public List Make(string a, string b, string c) { return new List(Sys.StrType, MakeStrs(a, b, c)); }
    public List Make(string a, string b, string c, string d) { return new List(Sys.StrType, MakeStrs(a, b, c, d)); }

    public void verify(List list) { verify(list, new object[0]); }
    public void verify(List list, Str a) { verify(list, new object[]{a}); }
    public void verify(List list, Str a, Str b) { verify(list, new object[]{a, b}); }
    public void verify(List list, Str a, Str b, Str c) { verify(list, new object[]{a, b, c}); }
    public void verify(List list, Str a, Str b, Str c, Str d) { verify(list, new object[]{a, b, c, d}); }
    public void verify(List list, Str a, Str b, Str c, Str d, Str e) { verify(list, new object[] {a, b, c, d, e}); }

    public void verify(List list, object[] v)
    {
  //System.Console.WriteLine(list);
      verify(list.isEmpty().val == (v.Length == 0));
      verify(list.size().val == v.Length);
      for (int i=0; i<list.size().val; ++i)
        verify(list.get(Int.make(i)) == v[i]);
    }

  }
}
