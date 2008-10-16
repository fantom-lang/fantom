//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Andy Frank  Creation
//

using System;
using System.IO;
using Fan.Sys;
using Type = Fan.Sys.Type;

namespace Fanx.Tools
{
  /// <summary>
  /// Fan runtime for .NET.
  /// </summary>
  ///
  public class Fan : Tool
  {

  //////////////////////////////////////////////////////////////////////////
  // Execute
  //////////////////////////////////////////////////////////////////////////

    internal int execute(string target, string[] args)
    {
      // args
      for (int i=0; i<args.Length; ++i)
        Sys.m_args.add(Str.make(args[i]));

      // first try as file name
      if (System.IO.File.Exists(target) && !Directory.Exists(target))
      {
        return executeFile(new FileInfo(target));
      }
      else
      {
        return executeType(target);
      }
    }

    public int executeFile(FileInfo file)
    {
      LocalFile f = (LocalFile)(new LocalFile(file).normalize());

      // use Fan reflection to run compiler::Main.compileScript(File)
      Pod pod = null;
      try
      {
        pod = Sys.compile(f).pod();
      }
      catch (Err.Val e)
      {
        System.Console.WriteLine("ERROR: cannot compile script");
        e.err().trace();
        return -1;
      }
      catch (Exception e)
      {
        System.Console.WriteLine("ERROR: cannot compile script");
        System.Console.WriteLine(e);
        return -1;
      }

      List types = pod.types();
      Type type = null;
      Method main = null;
      for (int i=0; i<types.sz(); ++i)
      {
        type = (Type)types.get(i);
        main = type.method("main", false);
        if (main != null) break;
      }

      if (main == null)
      {
        System.Console.WriteLine("ERROR: missing main method: " + ((Type)types.get(0)).name() + ".main()");
        return -1;
      }

      return callMain(type, main);
    }

    int executeType(string target)
    {
      if (target.IndexOf("::") < 0) target += "::Main.main";
      else if (target.IndexOf('.') < 0) target += ".main";

      try
      {
        int dot = target.IndexOf('.');
        Type type   = Type.find(target.Substring(0, dot), true);
        Method main = type.method(target.Substring(dot+1), true);
        return callMain(type, main);
      }
      catch (Exception e)
      {
        if (e is Err.Val)
          ((Err.Val)e).err().trace();
        else
          Err.dumpStack(e);
        return -1;
      }
    }

    static int callMain(Type t, Method m)
    {
      // check parameter type and build main arguments
      List args;
      List pars = m.@params();
      if (pars.sz() == 0)
      {
        args = null;
      }
      else if (((Param)pars.get(0)).of().@is(Sys.StrType.toListOf()) &&
               (pars.sz() == 1 || ((Param)pars.get(1)).hasDefault().booleanValue()))
      {
        args = new List(Sys.ObjType, new object[] { Sys.args() });
      }
      else
      {
        System.Console.WriteLine("ERROR: Invalid parameters for main: " + m.signature());
        return -1;
      }

      // invoke
      try
      {
        if (m.isStatic().booleanValue())
          return toResult(m.call(args));
        else
          return toResult(m.callOn(t.make(), args));
      }
      catch (Err.Val ex)
      {
        ex.err().trace();
        return -1;
      }
    }

    static int toResult(object obj)
    {
      if (obj is Int) return (int)((Int)obj).val;
      return 0;
    }

  //////////////////////////////////////////////////////////////////////////
  // Version
  //////////////////////////////////////////////////////////////////////////

    internal static void version(string progName)
    {
      writeLine(progName);
      writeLine("Copyright (c) 2006-2008, Brian Frank and Andy Frank");
      writeLine("Licensed under the Academic Free License version 3.0");
      writeLine("");
      writeLine(".NET Runtime:");
      writeLine("  clr.version: " + Environment.Version);
      writeLine("  fan.home:    " + Sys.HomeDir);
      writeLine("  sys.version: " + Sys.SysPod.version());
    }

    internal static void pods(string progName)
    {
      version(progName);

      long t1 = System.Environment.TickCount;
      List pods = Pod.list();
      long t2 = System.Environment.TickCount;

      writeLine("");
      writeLine("Fan Pods [" + (t2-t1) + "ms]:");

      for (int i=0; i<pods.sz(); i++)
      {
        Pod pod = (Pod)pods.get(i);
        writeLine("  " + pod.name().justl(Int.make(14)) + "  " + pod.version());
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Run
  //////////////////////////////////////////////////////////////////////////

    public static int run(string reserved)
    {
      sysInit(reserved);
      MainThread t = new MainThread();
      t.start().join();
      return t.ret;
    }

    class MainThread : Thread
    {
      public MainThread() : base(Str.make("main")) {}
      public override object run()
      {
        ret = doRun();
        return null;
      }
      public int ret;
    }

    static int doRun()
    {
      // process args
      string[] args = Tool.getArgv();
      for (int i=0; i<args.Length; i++)
      {
        string a = args[i];
        if (a.Length == 0) continue;
        if (a == "-help" || a == "-h" || a == "-?")
        {
          help();
          return -1;
        }
        else if (a == "-version")
        {
          version("Fan Launcher");
          return -1;
        }
        else if (a == "-pods")
        {
          pods("Fan Launcher");
          return -1;
        }
        else if (a[0] == '-')
        {
          writeLine("WARNING: Unknown option " + a);
        }
        else
        {
          string target = a;
          string[] targetArgs = new string[args.Length-i-1];
          Array.Copy(args, i+1, targetArgs, 0, targetArgs.Length);
          return new Fan().execute(target, targetArgs);
        }
      }

      help();
      return -1;
    }

    static void help()
    {
      writeLine("Fan Launcher");
      writeLine("Usage:");
      writeLine("  fan [options] <pod>::<type>.<method> [args]*");
      writeLine("  fan [options] <filename> [args]*");
      writeLine("Options:");
      writeLine("  -help, -h, -?  print usage help");
      writeLine("  -version       print version information");
      writeLine("  -pods          list installed pods");
    }

    public static void writeLine(string s)
    {
      Console.WriteLine(s);
    }

  }
}