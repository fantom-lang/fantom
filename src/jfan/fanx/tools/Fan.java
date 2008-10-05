//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Dec 05  Brian Frank  Creation
//
package fanx.tools;

import java.io.File;
import fan.sys.*;
import fan.sys.Thread;
import fanx.util.*;

/**
 * Fan runtime command line tool.
 */
public class Fan
{

//////////////////////////////////////////////////////////////////////////
// Execute
//////////////////////////////////////////////////////////////////////////

  public int execute(String target, String[] args)
    throws Exception
  {
    // args
    for (int i=0; i<args.length; ++i)
      Sys.args.add(Str.make(args[i]));

    // first try as file name
    File file = new File(target);
    if (file.exists() && !file.isDirectory())
    {
      return executeFile(file);
    }
    else
    {
      return executeType(target);
    }
  }

  public int executeFile(File file)
    throws Exception
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
      System.out.println("ERROR: cannot compile script");
      if (!e.getClass().getName().startsWith("fan.compiler"))
        e.err().trace();
      return -1;
    }
    catch (Exception e)
    {
      System.out.println("ERROR: cannot compile script");
      e.printStackTrace();
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
      System.out.println("ERROR: missing main method: " + ((Type)types.get(0)).name() + ".main()");
      return -1;
    }

    return callMain(type, main);
  }

  public int executeType(String target)
    throws Exception
  {
    if (target.indexOf("::") < 0) target += "::Main.main";
    else if (target.indexOf('.') < 0) target += ".main";

    try
    {
      int dot = target.indexOf('.');
      Type type   = Type.find(target.substring(0, dot), true);
      Method main = type.method(target.substring(dot+1), true);
      return callMain(type, main);
    }
    catch (Throwable e)
    {
      System.out.println("ERROR: " + e);
      return -1;
    }
  }

  static int callMain(Type t, Method m)
  {
    // check parameter type and build main arguments
    List args;
    List params = m.params();
    if (params.sz() == 0)
    {
      args = null;
    }
    else if (((Param)params.get(0)).of().is(Sys.StrType.toListOf()) &&
             (params.sz() == 1 || ((Param)params.get(1)).hasDefault()))
    {
      args = new List(Sys.ObjType, new Object[] { Sys.args() });
    }
    else
    {
      System.out.println("ERROR: Invalid parameters for main: " + m.signature());
      return -1;
    }

    // invoke
    try
    {
      if (m.isStatic())
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

  static int toResult(Object obj)
  {
    if (obj instanceof Long) return ((Long)obj).intValue();
    return 0;
  }

//////////////////////////////////////////////////////////////////////////
// Version
//////////////////////////////////////////////////////////////////////////

  static void version(String progName)
  {
    println(progName);
    println("Copyright (c) 2006-2008, Brian Frank and Andy Frank");
    println("Licensed under the Academic Free License version 3.0");
    println("");
    println("Java Runtime:");
    println("  java.vm.name:    " + System.getProperty("java.vm.name"));
    println("  java.vm.vendor:  " + System.getProperty("java.vm.vendor"));
    println("  java.vm.version: " + System.getProperty("java.vm.version"));
    println("  java.home:       " + System.getProperty("java.home"));
    println("  fan.home:        " + Sys.HomeDir);
    println("  sys.version:     " + Sys.SysPod.version());
  }

  static void pods(String progName)
  {
    version(progName);

    long t1 = System.nanoTime();
    List pods = Pod.list();
    long t2 = System.nanoTime();

    println("");
    println("Fan Pods [" + (t2-t1)/1000000L + "ms]:");

    for (int i=0; i<pods.sz(); ++i)
    {
      Pod pod = (Pod)pods.get(i);
      System.out.println("  " + pod.name().justl(Long.valueOf(14)) + "  " + pod.version());
    }
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  public int run(String[] args)
  {
    try
    {
      if (args.length == 0) { help(); return -1; }

      // process args
      for (int i=0; i<args.length; ++i)
      {
        String a = args[i].intern();
        if (a.length() == 0) continue;
        if (a == "-help" || a == "-h" || a == "-?")
        {
          help();
          return 2;
        }
        else if (a == "-version")
        {
          version("Fan Launcher");
          return 3;
        }
        else if (a == "-pods")
        {
          pods("Fan Launcher");
          return 4;
        }
        else if (a.charAt(0) == '-')
        {
          System.out.println("WARNING: Unknown option " + a);
        }
        else
        {
          String target = a;
          String[] targetArgs = new String[args.length-i-1];
          System.arraycopy(args, i+1, targetArgs, 0, targetArgs.length);
          return execute(target, targetArgs);
        }
      }

      help();
      return 2;
    }
    catch (Throwable e)
    {
      e.printStackTrace();
      return 1;
    }
  }

  void help()
  {
    println("Fan Launcher");
    println("Usage:");
    println("  fan [options] <pod>::<type>.<method> [args]*");
    println("  fan [options] <filename> [args]*");
    println("Options:");
    println("  -help, -h, -?  print usage help");
    println("  -version       print version information");
    println("  -pods          list installed pods");
  }

  public static void println(String s)
  {
    System.out.println(s);
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  public static void main(final String[] args)
    throws Exception
  {
    new Thread(Str.make("main"))
    {
      public Object run()
      {
        System.exit(new Fan().run(args));
        return null;
      }
    }.start().join();
  }

}
