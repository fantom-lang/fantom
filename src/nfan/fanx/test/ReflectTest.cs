//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Dec 06  Andy Frank  Creation
//

using Fan.Sys;

namespace Fanx.Test
{
  /// <summary>
  /// ReflectTest.
  /// </summary>
  public class ReflectTest : CompileTest
  {

  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    public override void Run()
    {
      verifyTypeParser();
      verifyBasic();
    }

  //////////////////////////////////////////////////////////////////////////
  // TypeParser
  //////////////////////////////////////////////////////////////////////////

    void verifyTypeParser()
    {
      verify(Type.find("sys::Boolean", true)     == Sys.BoolType);
      verify(Type.find("sys::Duration", true) == Sys.DurationType);
      //verify(Sys.findType("sys::Int[]", true)    == Sys.IntType.ToListOf());
      verifyTypeParserErr("");
      verifyTypeParserErr("x");
      verifyTypeParserErr("xy");
      verifyTypeParserErr("xyz");
      verifyTypeParserErr("x:z");
      verifyTypeParserErr("xz[");
      verifyTypeParserErr("xz[]");
      verifyTypeParserErr("[]");
    }

    void verifyTypeParserErr(string sig)
    {
      try
      {
        Type.find(sig, false);
        System.Console.WriteLine("didn't fail: " + sig);
        Fail();
      }
      catch(Err.Val err)
      {
        //System.out.println(" -- " + err);
        verify(err.err().message().val.StartsWith("Invalid type signature '" + sig + "'"));
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Basic
  //////////////////////////////////////////////////////////////////////////

    public void verifyBasic()
    {
      Type t = CompileToFanType("class Foo { Str f() { return type.name } }");
      object obj = t.make();
      Str name = (Str)t.method("f", true).call1(obj);
      verify(name.val == "Foo");
    }

  }
}
