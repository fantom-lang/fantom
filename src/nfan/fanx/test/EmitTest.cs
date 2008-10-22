//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Sep 06  Andy Frank  Creation
//

using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using Fan.Sys;
using Fanx.Emit;
using Fanx.Fcode;
using Fanx.Util;

namespace Fanx.Test
{
  /// <summary>
  /// EmitTest.
  /// </summary>
  public class EmitTest : Test
  {
    public override void Run()
    {
      verifyBasic();
      verifySysFindType();
      verifyTypeParser();
      verifySysReflect();
    }

    public void verifyBasic()
    {
      Emitter e = new Emitter("foo");
      e.emitClass("System.Object", "Foo.Bar", new string[0], PERWAPI.TypeAttr.Public);

      e.emitField("FieldA", "System.Boolean", PERWAPI.FieldAttr.Public);
      e.emitField("FieldB", "System.UInt32",  PERWAPI.FieldAttr.Public);
      e.emitField("FieldC", "System.String",  PERWAPI.FieldAttr.Public);

      // TODO - methods require 'ret' - should auto handle that in API
      e.emitMethod("MethodA", "System.Void", s(), s(),
        PERWAPI.MethAttr.PublicStatic, new string[0], new string[0]).Inst(PERWAPI.Op.ret);
      e.emitMethod("MethodB", "System.Void", s("pa"), s("System.UInt32"),
        PERWAPI.MethAttr.PublicStatic, new string[0], new string[0]).Inst(PERWAPI.Op.ret);
      e.emitMethod("MethodC", "System.Void", s("pa", "pb"), s("System.UInt32", "System.Double"),
        PERWAPI.MethAttr.PublicStatic, new string[0], new string[0]).Inst(PERWAPI.Op.ret);

      byte[] buf = e.commit();

      // dump to file
      //BinaryWriter writer = new BinaryWriter(
      //  new FileInfo(@"c:\dev\fan\test.dll").OpenWrite());
      //writer.Write(buf, 0, buf.Length);
      //writer.Flush();
      //writer.Close();

      Assembly assembly = Assembly.Load(buf);
      System.Type type = assembly.GetType("Foo.Bar");
      verify(type.ToString(), "Foo.Bar");

      verify(type.GetField("FieldA").ToString(), "Boolean FieldA");
      verify(type.GetField("FieldB").ToString(), "UInt32 FieldB");
      verify(type.GetField("FieldC").ToString(), "System.String FieldC");

      verify(type.GetMethod("MethodA").ToString(), "Void MethodA()");
      verify(type.GetMethod("MethodB").ToString(), "Void MethodB(UInt32)");
      verify(type.GetMethod("MethodC").ToString(), "Void MethodC(UInt32, Double)");
    }

    public void verifySysFindType()
    {
      Pod pod = Pod.find("sys", true, null);
      verify(pod.findType("Boolean", true) == Sys.BoolType);
      verify(pod.findType("Long", true)  == Sys.IntType);
      verify(pod.findType("string", true)  == Sys.StrType);

      verify(Fan.Sys.Type.find("sys::Boolean") == Sys.BoolType);
      verify(Fan.Sys.Type.find("sys::Boolean", Fan.Sys.Boolean.True) == Sys.BoolType);
      verify(Fan.Sys.Type.find("sys::Boolean") == Sys.BoolType);
      verify(Fan.Sys.Type.find("sys::Boolean", true) == Sys.BoolType);
      verify(Fan.Sys.Type.find("sys", "Boolean", true) == Sys.BoolType);
    }

    public void verifyTypeParser()
    {
      verifyTypeParserErr("");
      verifyTypeParserErr("x");
      verifyTypeParserErr("xy");
      verifyTypeParserErr("xyz");
      verifyTypeParserErr("x:z");
      verifyTypeParserErr("xz[");
      verifyTypeParserErr("xz[]");
      verifyTypeParserErr("[]");
    }

    public void verifyTypeParserErr(string sig)
    {
      try
      {
        Fan.Sys.Type.find(sig, false);
        Console.WriteLine("didn't fail: " + sig);
        Fail();
      }
      catch(Err.Val err)
      {
        //Console.WriteLine(" -- " + err);
        verify(err.err().message().StartsWith("Invalid type signature '" + sig + "'"));
      }
    }

    public void verifySysReflect()
    {
      verifySysImpl("sys::Boolean", "Fan.Sys.Boolean");
      verifySysImpl("sys::Long",    "Fan.Sys.Long");
      verifySysImpl("sys::Str",     "Fan.Sys.Str");
    }

    public void verifySysImpl(string fname, string nname)
    {
      Fan.Sys.Type ftype = Fan.Sys.Type.find(fname, true);
      System.Type ntype  = System.Type.GetType(nname);

      verify(ftype.emit(), ntype);

      /*
      for (int i=0; i<ftype.Fields().Sz(); i++)
      {
        Field ffield = (Field)ftype.Fields().Get(i);
        string name = FanUtil.Upper(ffield.Name().val);
        FieldInfo nfield = ntype.GetField(name);
        verify(name, nfield.Name);
      }
      */

      /*
      for (int i=0; i<ftype.Methods().Sz(); i++)
      {
        Method fmeth = (Method)ftype.Methods().Get(i);
        string name = FanUtil.Upper(fmeth.Name().val);
        MethodInfo nmeth = ntype.GetMethod(name);
        verify(name, nmeth.Name);
      }
      */
    }

    /*
    public void verifyFooBar()
    {
      string code = "class Foo {\n" +
        "  Boolean b\n" +
        "  Long i\n" +
        "  string s\n" +
        "}";
      stub(code);
      compile();

      Pod pod = Pod.find("nsystest", true, null);
      Fan.Sys.Type type = pod.FindType("Foo", true);
    }

    private void stub(String code)
    {
      string path = @"c:\dev\fan\src\nsystest\fan";
      Directory.CreateDirectory(path);
      StreamWriter w = new StreamWriter(new FileInfo(path + @"\Foo.fan").OpenWrite());
      w.WriteLine(code);
      w.Flush();
      w.Close();
    }

    private void compile()
    {
      Process proc = new Process();
      proc.StartInfo.WorkingDirectory = @"c:\dev\fan\bin";
      proc.StartInfo.FileName = @"c:\dev\fan\bin\ntestc.bat";
      proc.StartInfo.CreateNoWindow = true;
      proc.Start();
      proc.WaitForExit();
    }
    */

    private string[] s() { return new string[0]; }
    private string[] s(string a) { return new string[] { a }; }
    private string[] s(string a, string b) { return new string[] { a, b }; }
  }
}