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
      string a = "a", b = "b", c = "c",
          d = "d", e = "e";
      Long i0 = Long.valueOf(0);
      Long i1 = Long.valueOf(1);
      Long i2 = Long.valueOf(2);

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
          list.add(match[j] = Long.valueOf(j));
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
      System.Type nt = CompileToType("class Foo { static Type f() { return string[,].type() } }");
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
      verify("Obj f() { return string[,] }", new List(Sys.StrType));

      // adds
      verify("Obj f(string[] x) { x.add(\"a\"); return x }", new object[] {new List(Sys.StrType)}, Make("a"));
      verify("Obj f(string[] x) { x.add(\"a\"); x.add(\"b\"); return x }", new object[] {new List(Sys.StrType)}, Make("a", "b"));

      // literals
      verify("Obj f() { return [,] }", new List(Sys.ObjType));
      verify("Obj f() { return [\"a\"] }", Make("a"));
      verify("Obj f() { return [\"a\", \"b\"]; }", Make("a", "b"));
      verify("Obj f() { return [ \"a\" , \"b\" , \"c\" ] }", Make("a", "b", "c"));
      verify("Obj f() { return [ \"a\" , \"b\" , \"c\", ] }", Make("a", "b", "c"));  // extra comma

      // explicit typing: empty literal
      verify("Obj f() { return string[,] }", new List(Sys.StrType));
      // explicit typing: single item - not figured out until resolve time
      verify("Obj f() { return string[\"a\"] }", Make("a"));
      // explicit typing: single item, trailing comma
      verify("Obj f() { return string[\"a\",] }", Make("a"));
      // explicit typing: multiple items
      verify("Obj f() { return string[\"a\", \"b\"] }", Make("a", "b"));

      // slicing
      object[] args = { Make("0", "1", "2", "3") };
      verify("Obj f(string[] x) { return x[0] }", args, "0");
      verify("string f(string[] x) { return x[1] }", args, "1");
      verify("Obj f(string[] x) { return x[2] }", args, "2");
      verify("string f(string[] x) { return x[3] }", args, "3");
      verify("Obj f(string[] x) { return x[-1] }", args, "3");
      verify("string f(string[] x) { return x[-2] }", args, "2");
      verify("Obj f(string[] x) { return x[-3] }", args, "1");
      verify("string f(string[] x) { return x[-4] }", args, "0");
      verifyThrows("Obj f(string[] x) { return x[4] }",  args, System.Type.GetType("Fan.Sys.IndexErr+Val"));
      verifyThrows("string f(string[] x) { return x[5] }",  args, System.Type.GetType("Fan.Sys.IndexErr+Val"));
      verifyThrows("Obj f(string[] x) { return x[-5] }", args, System.Type.GetType("Fan.Sys.IndexErr+Val"));
      verifyThrows("string f(string[] x) { return x[-6] }", args, System.Type.GetType("Fan.Sys.IndexErr+Val"));

      // parameterized typing
//      verifyErr("Long f(string[] x) { return x[0] }", "Cannot return 'sys::string' as 'sys::Long'");
//      verifyErr("Void f(string[] x) { x.add(3) }", "Invalid args add(sys::Long) for add(sys::string)");
//      verifyErr("Void f(string[] x, Obj a) { x.add(a) }", "Invalid args add(sys::Obj) for add(sys::string)");
      //verifyErr("Long[] f(string[] x) { return x }", "Cannot return 'sys::string[]' as 'sys::Long[]'");

      // TODO - just List; should we allow List/Map to be used or force use of Obj[]?
      // verify("Obj f(List x) { return x[0] }", args, string.make("0"));

      // errors
//      verifyErr("Obj f([] x) {}",             "Expected type identifier, not ']'");
//      verifyErr("Obj f() { return [] }",      "Invalid list literal; use '[,]' for empty Obj[] list");
//      verifyErr("Obj f() { return string[] }",   "Invalid use of type name as expression");
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
      verify("Obj f(List x) { return x[0] }", args, "0");
      verify("Obj f(List x) { return x.get(2) }", args, "2");
    }

  //////////////////////////////////////////////////////////////////////////
  // Convenience
  //////////////////////////////////////////////////////////////////////////

    public List Make(string a) { return new List(Sys.StrType, MakeStrs(a)); }
    public List Make(string a, string b) { return new List(Sys.StrType, MakeStrs(a, b)); }
    public List Make(string a, string b, string c) { return new List(Sys.StrType, MakeStrs(a, b, c)); }
    public List Make(string a, string b, string c, string d) { return new List(Sys.StrType, MakeStrs(a, b, c, d)); }

    public void verify(List list) { verify(list, new object[0]); }
    public void verify(List list, string a) { verify(list, new object[]{a}); }
    public void verify(List list, string a, string b) { verify(list, new object[]{a, b}); }
    public void verify(List list, string a, string b, string c) { verify(list, new object[]{a, b, c}); }
    public void verify(List list, string a, string b, string c, string d) { verify(list, new object[]{a, b, c, d}); }
    public void verify(List list, string a, string b, string c, string d, string e) { verify(list, new object[] {a, b, c, d, e}); }

    public void verify(List list, object[] v)
    {
  //System.Console.WriteLine(list);
      verify(list.isEmpty().booleanValue() == (v.Length == 0));
      verify(list.size().longValue() == v.Length);
      for (int i=0; i<list.size().longValue(); ++i)
        verify(list.get(Long.valueOf(i)) == v[i]);
    }

  }
}