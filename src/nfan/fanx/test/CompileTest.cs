//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   02 Oct 06  Andy Frank  Creation
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
  /// CompileTest.
  /// </summary>
  public abstract class CompileTest : Test
  {

  //////////////////////////////////////////////////////////////////////////
  // Test
  //////////////////////////////////////////////////////////////////////////

    public override bool Skip()
    {
      // can't run compiler tests if dynamic class loading not supported
      return Sys.usePrecompiledOnly;
    }

  //////////////////////////////////////////////////////////////////////////
  // Harness
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// verify no arg method "f" returns the specified result.
    /// </summary>
    public Object verify(string func, Object result)
    {
      return verify(func, new Object[0], result);
    }

    /// <summary>
    /// verify the source code for method "f" returns the specified result.
    /// If the function is static return the generated class, otherwise return
    /// the actual instance used (to test for side effects).
    /// </summary>
    public Object verify(string func, Object[] args, Object result)
    {
      string pod = "nsystest" + count++;
      string src =
      imports + "\n" +
      "class Bar\n" +
      "{\n" +
      members + "\n" +
      "  " + func + "\n" +
      "}\n";

      Stub(pod, src);
      Compile(pod);

      System.Type type = Fan.Sys.Type.find(pod, "Bar", true).emit();
      MethodInfo m = type.GetMethod("F");

      Object target = (m.IsStatic) ? null : Activator.CreateInstance(type);
      BindingFlags flags = BindingFlags.Public | BindingFlags.InvokeMethod;
      flags |= (m.IsStatic) ? BindingFlags.Static : BindingFlags.Instance;

      Object ret = type.InvokeMember("F", flags, null, target, args);
      verify(ret, result);

      return (target == null) ? type : target;
    }

    public void verifyErr(string func, string msg)
    {
      Exception ex = null;
      try
      {
        verify(func, null, null);
      }
      catch (Exception e)
      {
        ex = e;
      }
      verify(ex != null);
      if (ex is TargetInvocationException) ex = ex.InnerException;
      if (!ex.Message.Equals(msg)) System.Console.WriteLine(ex + " != " + msg);
      verify(ex.Message.Equals(msg));
    }

    public void verifyThrows(string func, object[] args, System.Type type)
    {
      Exception ex = null;
      try
      {
        verify(func, args, null);
      }
      catch (Exception e)
      {
        ex = e;
      }

      verify(ex != null);
      if (ex is TargetInvocationException) ex = ex.InnerException;
  //System.Console.WriteLine(ex.GetType() + " ?= " + type);
      verify(ex.GetType() == type);
    }

    /*
    public void verifyFooBar()
    {
      string code = "class Foo {\n" +
        "  Bool b\n" +
        "  Int i\n" +
        "  Str s\n" +
        "}";
      stub(code);
      compile();

      Pod pod = Pod.find("nsystest", true, null);
      Fan.Sys.Type type = pod.FindType("Foo", true);
    }
    */

//////////////////////////////////////////////////////////////////////////
// Compiling
//////////////////////////////////////////////////////////////////////////

    public System.Type[] CompileToTypes(string src)
    {
      string pod = "nsystest" + count++;

      Stub(pod, src);
      Compile(pod);

      List list = Pod.find(pod, true, null).types();
      System.Type[] types = new System.Type[list.sz()];
      for (int i=0; i<list.sz(); i++)
        types[i] = (list.get(i) as Fan.Sys.Type).emit();

      return types;
    }

    public System.Type CompileToType(string src)
    {
      return CompileToTypes(src)[0];
    }

    //public Fan.Sys.Type[] CompileToFanTypes(string src)
    //{
    //  string pod = "nsystest" + count;
    //  System.Type t = CompileToTypes(src)[0];
    //  return Sys.FindType(pod + "::" + t.Name);
    //}

    public Fan.Sys.Type CompileToFanType(string src)
    {
      string pod = "nsystest" + count;
      System.Type t = CompileToTypes(src)[0];
      return Fan.Sys.Type.find(pod + "::" + t.Name);
    }

    private void Stub(string pod, string code)
    {
      string path = "c:\\dev\\fan\\src\\tmp\\" + pod + "\\fan";
      Directory.CreateDirectory(path);
      StreamWriter w = new StreamWriter(
        new FileInfo(path + @"\Foo.fan").Open(FileMode.Create, FileAccess.Write));
      w.WriteLine(code);
      w.Flush();
      w.Close();
    }

    private void Compile(string pod)
    {
      System.Diagnostics.Process proc = new System.Diagnostics.Process();
      proc.StartInfo.WorkingDirectory = @"c:\dev\fan\bin";
      proc.StartInfo.FileName = @"c:\dev\fan\bin\ntestc.bat";
      proc.StartInfo.Arguments = pod;
      proc.StartInfo.UseShellExecute = false;
      proc.StartInfo.CreateNoWindow = false;
      proc.Start();
      proc.WaitForExit();
    }

    internal static void Cleanup()
    {
      // delete all the test pods we created
      string[] paths = Directory.GetFiles(@"c:\dev\fan\lib\fan");
      for (int i=0; i<paths.Length; i++)
      {
        string name = paths[i].Substring(paths[i].LastIndexOf("\\")+1);
        name = name.Substring(0, name.Length-4);

        if (!name.StartsWith("nsystest")) continue;

        Pod.find(name, true, null).close();
        System.IO.File.Delete(paths[i]);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static int count = 0;

    internal string imports = "";  // imports to add to next class tested
    internal string members = "";  // other stuff to insert inside class definition
  }
}