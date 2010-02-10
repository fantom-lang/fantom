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
  /// Fantom runtime for .NET.
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
      Sys.m_bootEnv.setArgs(args);

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

      // use Fantom reflection to run compiler::Main.compileScript(File)
      Pod pod = null;
      try
      {
        pod = Env.cur().compileScript(f).pod();
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
      else if (((Param)pars.get(0)).type().@is(Sys.StrType.toListOf()) &&
               (pars.sz() == 1 || ((Param)pars.get(1)).hasDefault()))
      {
        args = new List(Sys.ObjType, new object[] { Env.cur().args() });
      }
      else
      {
        System.Console.WriteLine("ERROR: Invalid parameters for main: " + m.signature());
        return -1;
      }

      // invoke
      try
      {
        if (m.isStatic())
          return toResult(m.callList(args));
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
      if (obj is long) return (int)obj;
      return 0;
    }

  //////////////////////////////////////////////////////////////////////////
  // Version
  //////////////////////////////////////////////////////////////////////////

    internal static void version(string progName)
    {
      writeLine(progName);
      writeLine("Copyright (c) 2006-2010, Brian Frank and Andy Frank");
      writeLine("Licensed under the Academic Free License version 3.0");
      writeLine("");
      writeLine(".NET Runtime:");
      writeLine("  clr.version:  " + Environment.Version);
      writeLine("  sys.platform: " + Sys.m_platform);
      writeLine("  sys.version:  " + Sys.m_sysPod.version());
      writeLine("");
    }

    static void pods(String progName)
    {
      version(progName);

      long t1 = Duration.nowTicks();
      List pods = Pod.list();
      long t2 = Duration.nowTicks();

      writeLine("");
      writeLine("Fantom Pods [" + (t2-t1)/1000000L + "ms]:");

      writeLine("  Pod                 Version");
      writeLine("  ---                 -------");
      for (int i=0; i<pods.sz(); ++i)
      {
        Pod pod = (Pod)pods.get(i);
        writeLine("  " +
          FanStr.justl(pod.name(), 18L) + "  " +
          FanStr.justl(pod.version().toStr(), 8));
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Run
  //////////////////////////////////////////////////////////////////////////

    public static int run(string reserved)
    {
      try
      {
        sysInit(reserved);

        // process args
        string[] args = Tool.getArgv();
        for (int i=0; i<args.Length; i++)
        {
          string a = args[i];
          if (a.Length == 0) continue;
          if (a == "-help" || a == "-h" || a == "-?")
          {
            help();
            return 2;
          }
          else if (a == "-version")
          {
            version("Fantom Launcher");
            return 3;
          }
          else if (a == "-pods")
          {
            pods("Fantom Launcher");
            return 4;
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
        return 2;
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
        return 1;
      }
    }

    static void help()
    {
      writeLine("Fantom Launcher");
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