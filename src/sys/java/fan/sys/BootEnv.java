//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jan 10  Brian Frank  Creation
//
package fan.sys;

import java.lang.management.*;
import java.net.*;
import java.util.Iterator;
import java.util.HashMap;
import fanx.emit.*;
import fanx.fcode.*;
import fanx.util.*;

/**
 * BootEnv
 */
public class BootEnv
  extends Env
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public BootEnv()
  {
    this.args    = initArgs();
    this.vars    = initVars();
    this.host    = initHost();
    this.user    = initUser();
    this.in      = new SysInStream(System.in);
    this.out     = new SysOutStream(System.out);
    this.err     = new SysOutStream(System.err);
    this.homeDir = new LocalFile(Sys.homeDir, true).normalize();
    this.tempDir = homeDir.plus(Uri.fromStr("temp/"), false);
  }

  private static List initArgs()
  {
    return (List)new List(Sys.StrType).toImmutable();
  }

  private static Map initVars()
  {
    Map vars = new Map(Sys.StrType, Sys.StrType);
    try
    {
      vars.caseInsensitive(true);

      // environment variables
      java.util.Map getenv = System.getenv();
      Iterator it = getenv.keySet().iterator();
      while (it.hasNext())
      {
        String key = (String)it.next();
        String val = (String)getenv.get(key);
        vars.set(key, val);
      }

      // Java system properties
      it = System.getProperties().keySet().iterator();
      while (it.hasNext())
      {
        String key = (String)it.next();
        String val = System.getProperty(key);
        vars.set(key, val);
      }
    }
    catch (Throwable e)
    {
      e.printStackTrace();
    }
    return (Map)vars.toImmutable();
  }

  private static String initHost()
  {
    try
    {
      return java.net.InetAddress.getLocalHost().getHostName();
    }
    catch (Throwable e)
    {
      return "unknown";
    }
  }

  private static String initUser()
  {
    return System.getProperty("user.name", "unknown");
  }

//////////////////////////////////////////////////////////////////////////
// BootEnv
//////////////////////////////////////////////////////////////////////////

  public void setArgs(String[] args)
  {
    this.args = (List)new List(Sys.StrType, args).toImmutable();
  }

  public void setMainMethod(Method m)
  {
    this.mainMethod = m;
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.BootEnvType; }

//////////////////////////////////////////////////////////////////////////
// Virtuals
//////////////////////////////////////////////////////////////////////////

  public List args() { return args; }

  public Method mainMethod() { return mainMethod; }

  public Map vars()  { return vars; }

  public String host() { return host; }

  public String user() { return user; }

  public void gc() { System.gc(); }

  public InStream in() { return in; }

  public OutStream out() { return out; }

  public OutStream err() { return err; }

  public File homeDir() { return homeDir; }

  public File workDir() { return homeDir; }

  public File tempDir() { return tempDir; }

//////////////////////////////////////////////////////////////////////////
// Prompt JLine
//////////////////////////////////////////////////////////////////////////

  public String prompt(String msg)
  {
    // attempt to initilize JLine and if we can't fallback to Java API
    if (!jlineInit())
    {
      java.io.Console console = System.console();
      if (console == null) return promptStdIn(msg);
      return console.readLine(msg);
    }

    // use reflection to call JLine ConsoleReader.readLine
    try
    {
      return (String)jline.getClass()
        .getMethod("readLine", new Class[] { String.class })
        .invoke(jline, new Object[] { msg });
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }

  public String promptPassword(String msg)
  {
    // attempt to initilize JLine and if we can't fallback to Java API
    if (!jlineInit())
    {
      java.io.Console console = System.console();
      if (console == null) return promptStdIn(msg);
      char[] pass = console.readPassword(msg);
      if (pass == null) return null;
      return new String(pass);
    }

    // use reflection to call JLine ConsoleReader.readLine
    try
    {
      return (String)jline.getClass()
        .getMethod("readLine", new Class[] { String.class, Character.class })
        .invoke(jline, new Object[] { msg, Character.valueOf('#') });
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }

  private boolean jlineInit()
  {
    if (jline == null)
    {
      // use reflection to see if jline.console.ConsoleReader
      // is available in classpath
      try
      {
        // jline = new ConsoleReader()
        Class cls  = Class.forName("jline.console.ConsoleReader");
        jline = cls.getConstructor(new Class[] {}).newInstance();
      }
      catch (Throwable e)
      {
        jline = e;
      }
    }
    return !(jline instanceof Throwable);
  }

  private String promptStdIn(String msg)
  {
    try
    {
      out().print(msg).flush();
      return new java.io.BufferedReader(new java.io.InputStreamReader(System.in)).readLine();
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Exit and Shutdown Hooks
//////////////////////////////////////////////////////////////////////////

  public void exit(long status) { System.exit((int)status); }

  public void addShutdownHook(Func f)
  {
    if (!f.isImmutable()) throw NotImmutableErr.make();
    Thread thread = new ShutdownHookThread(f);
    shutdownHooks.put(f, thread);
    Runtime.getRuntime().addShutdownHook(thread);
  }

  public boolean removeShutdownHook(Func f)
  {
    Thread thread = (Thread)shutdownHooks.get(f);
    if (thread == null) return false;
    return Runtime.getRuntime().removeShutdownHook(thread);
  }

  static class ShutdownHookThread extends Thread
  {
    ShutdownHookThread(Func func) { this.func = func; }
    public void run()
    {
      try
      {
        func.call();
      }
      catch (Throwable e)
      {
        e.printStackTrace();
      }
    }
    private final Func func;
  }

//////////////////////////////////////////////////////////////////////////
// Diagnostics
//////////////////////////////////////////////////////////////////////////

  public Map diagnostics()
  {
    Map d = new Map(Sys.StrType, Sys.ObjType);

    // memory
    MemoryMXBean mem = ManagementFactory.getMemoryMXBean();
    d.add("mem.heap",    Long.valueOf(mem.getHeapMemoryUsage().getUsed()));
    d.add("mem.nonHeap", Long.valueOf(mem.getNonHeapMemoryUsage().getUsed()));

    // threads
    ThreadMXBean thread = ManagementFactory.getThreadMXBean();
    long[] threadIds = thread.getAllThreadIds();
    d.add("thread.size", Long.valueOf(threadIds.length));
    for (int i=0; i<threadIds.length; ++i)
    {
      ThreadInfo ti = thread.getThreadInfo(threadIds[i]);
      if (ti == null) continue;
      d.add("thread." + i + ".name",    ti.getThreadName());
      d.add("thread." + i + ".state",   ti.getThreadState().toString());
      d.add("thread." + i + ".cpuTime", Duration.make(thread.getThreadCpuTime(threadIds[i])));
    }

    // class loading
    ClassLoadingMXBean cls = ManagementFactory.getClassLoadingMXBean();
    d.add("classes.loaded",   Long.valueOf(cls.getLoadedClassCount()));
    d.add("classes.total",    Long.valueOf(cls.getTotalLoadedClassCount()));
    d.add("classes.unloaded", Long.valueOf(cls.getUnloadedClassCount()));

    return d;
  }

//////////////////////////////////////////////////////////////////////////
// Find Files
//////////////////////////////////////////////////////////////////////////

  public File findFile(Uri uri, boolean checked)
  {
    if (uri.isPathAbs()) throw ArgErr.make("Uri must be relative: " + uri);
    File f = homeDir.plus(uri, false);
    if (f.exists()) return f;
    if (!checked) return null;
    throw UnresolvedErr.make("File not found in Env: " + uri);
  }

  public List findAllFiles(Uri uri)
  {
    File f = findFile(uri, false);
    if (f == null) return Sys.FileType.emptyList();
    return new List(Sys.FileType, new File[] { f });
  }

//////////////////////////////////////////////////////////////////////////
// Java Env
//////////////////////////////////////////////////////////////////////////

  public Class loadPodClass(Pod pod)
  {
    try
    {
      FPodEmit emit = FPodEmit.emit(pod.fpod);
      return pod.classLoader.loadFan(emit.className.replace('/', '.'), emit.classFile);
    }
    catch (Exception e)
    {
      e.printStackTrace();
      throw new RuntimeException(e.toString());
    }
  }

  public Class[] loadTypeClasses(ClassType t)
  {
    try
    {
      FTypeEmit[] emitted = FTypeEmit.emit(t, t.ftype);
      Class[] classes = new Class[emitted.length];
      for (int i=0; i<emitted.length; ++i)
      {
        FTypeEmit e = emitted[i];
        classes[i] = t.pod().classLoader.loadFan(e.className.replace('/', '.'), e.classFile);
      }
      return classes;
    }
    catch (Exception e)
    {
      e.printStackTrace();
      throw new RuntimeException(e.toString());
    }
  }

  public Class loadJavaClass(String className)
    throws Exception
  {
    // handle primitives, these don't get handled by URLClassLoader
    if (className.charAt(0) == '[' && className.length() == 2)
    {
      switch (className.charAt(1))
      {
        case 'Z': return boolean[].class;
        case 'B': return byte[].class;
        case 'S': return short[].class;
        case 'I': return int[].class;
        case 'J': return long[].class;
        case 'F': return float[].class;
        case 'D': return double[].class;
      }
    }

    // route to extention classloader
    return FanClassLoader.extClassLoader.loadClass(className);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private List args;
  private Method mainMethod;
  private final Map vars;
  private final String host;
  private final String user;
  private final InStream  in;
  private final OutStream out;
  private final OutStream err;
  private final File homeDir;
  private final File tempDir;
  private final HashMap shutdownHooks = new HashMap();  // Func => Thread
  private Object jline;  // null, Throwable, ConsoleReader

}

