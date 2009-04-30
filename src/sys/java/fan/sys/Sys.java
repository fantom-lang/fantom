//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Dec 05  Brian Frank  Creation
//
package fan.sys;

import java.lang.ref.*;
import java.io.File;
import java.util.Iterator;
import java.lang.management.*;
import fanx.fcode.*;
import fanx.util.*;

/**
 * Sys provides static access to the system's environment.
 */
public final class Sys
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  private Sys() {}

//////////////////////////////////////////////////////////////////////////
// Namespace
//////////////////////////////////////////////////////////////////////////

  public static Namespace ns() { return ns; }
  public static Namespace ns(Uri uri) { return ns.ns(uri); }

  public static void mount(Uri uri, Namespace m) { ns.mount(uri, m); }

  public static void unmount(Uri uri) { ns.unmount(uri); }

//////////////////////////////////////////////////////////////////////////
// Environment
//////////////////////////////////////////////////////////////////////////

  public static List args() { return args.ro(); }

  public static Map env() { return env; }

  public static fan.sys.File homeDir() { return homeDir; }

  public static fan.sys.File appDir() { return appDir; }

  public static String hostName() { return hostName; }

  public static String userName() { return userName; }

  public static void exit() { exit(0L); }
  public static void exit(long status) { System.exit((int)status); }

  public static InStream  in()  { return StdIn; }
  public static OutStream out() { return StdOut; }
  public static OutStream err() { return StdErr; }

  public static void gc() { System.gc(); }

  public static long idHash(Object obj)
  {
    return System.identityHashCode(obj);
  }

//////////////////////////////////////////////////////////////////////////
// Diagnostics
//////////////////////////////////////////////////////////////////////////

  public static Map diagnostics()
  {
    Map d = new Map(StrType, ObjType);

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
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final File HomeDir;
  public static final File AppDir;
  public static final File PodsDir;
  public static final Pod  SysPod;
  public static final InStream  StdIn  = new SysInStream(System.in);
  public static final OutStream StdOut = new SysOutStream(System.out);
  public static final OutStream StdErr = new SysOutStream(System.err);

  // if true then we disable FanClassLoader and all classes
  // must be available precompiled into bytecode from the
  // system's classloader (or webapp, etc); default is false
  public static boolean usePrecompiledOnly;

//////////////////////////////////////////////////////////////////////////
// Boot
//////////////////////////////////////////////////////////////////////////

  static
  {
    try
    {
      // map key directories
      HomeDir = sysPropToDir("fan.home",   "FAN_HOME", null);
      AppDir  = sysPropToDir("fan.appDir", "FAN_APPDIR", new File(".").getCanonicalPath().toString());
      PodsDir = new File(HomeDir, "lib" + File.separator + "fan");

      // check fan.usePrecompiledOnly
      usePrecompiledOnly = System.getProperty("fan.usePrecompiledOnly", "false").equals("true");

      // add shutdown hook - this is the only way to
      // cleanup pod files marked deleteOnExit
      /*
      Runtime.getRuntime().addShutdownHook(new Thread("fan.Sys Shutdown Hook") {
        public void run()
        {
          Iterator it = podsByName.values().iterator();
          while (it.hasNext()) ((Pod)it.next()).shutdown();
        }
      });
      */

      // load sys pod
      SysPod = Pod.doFind("sys", true, null, null);
    }
    catch (Throwable e)
    {
      System.out.println("ERROR: Sys.static");
      e.printStackTrace();
      throw new RuntimeException("Cannot boot fan::Sys - " + e.toString());
    }
  }

  /**
   * Map a system property or environment variable to a local directory.
   */
  private static File sysPropToDir(String propKey, String envKey, String def)
  {
    // lookup system property
    String val = System.getProperty(propKey);

    // fallback to environment variable
    if (val == null)
      val = System.getenv(envKey);
    if (val == null)
      val = System.getenv(FanStr.lower(envKey));

    // fallback to def if provides
    if (val == null && def != null)
      val = def;

    // if still not found then we're toast
    if (val == null)
      throw new RuntimeException("Missing " + propKey + " system property or " + envKey + " env var");

    // check that val ends in trailing newline
    if (!val.endsWith("/")) val += "/";

    // check if relative to home directory (fand, fant)
    boolean checkExists = true;
    if (val.startsWith("$home"))
    {
      val = new File(HomeDir, val.substring(5)).toString();
      checkExists = false;
    }

    // map to java.io.File and check that it is a valid directory
    File f = new File(val);
    if (checkExists && (!f.exists() || !f.isDirectory()))
      throw new RuntimeException("Invalid " + propKey + " dir: " + f);
    return f;
  }

//////////////////////////////////////////////////////////////////////////
// Built-in Types
//////////////////////////////////////////////////////////////////////////

  // the Eve of all types
  public static final Type ObjType       = builtin("Obj",      null);

  // basic primitives
  public static final Type NumType       = builtin("Num",      ObjType);
  public static final Type EnumType      = builtin("Enum",     ObjType);
  public static final Type BoolType      = builtin("Bool",     ObjType);
  public static final Type DurationType  = builtin("Duration", ObjType);
  public static final Type FuncType      = builtin("Func",     ObjType);
  public static final Type IntType       = builtin("Int",      NumType);
  public static final Type DecimalType   = builtin("Decimal",  NumType);
  public static final Type FloatType     = builtin("Float",    NumType);
  public static final Type ListType      = builtin("List",     ObjType);
  public static final Type MapType       = builtin("Map",      ObjType);
  public static final Type MonthType     = builtin("Month",    EnumType);
  public static final Type PodType       = builtin("Pod",      ObjType);
  public static final Type RangeType     = builtin("Range",    ObjType);
  public static final Type StrType       = builtin("Str",      ObjType);
  public static final Type StrBufType    = builtin("StrBuf",   ObjType);
  public static final Type SysType       = builtin("Sys",      ObjType);
  public static final Type TestType      = builtin("Test",     ObjType);
  public static final Type DateTimeType  = builtin("DateTime", ObjType);
  public static final Type DateType      = builtin("Date",     ObjType);
  public static final Type TimeType      = builtin("Time",     ObjType);
  public static final Type TimeZoneType  = builtin("TimeZone", ObjType);
  public static final Type TypeType      = builtin("Type",     ObjType);
  public static final Type WeekdayType   = builtin("Weekday",  EnumType);
  public static final Type ThisType      = builtin("This",     ObjType);
  public static final Type VoidType      = builtin("Void",     ObjType);

  // reflection
  public static final Type SlotType      = builtin("Slot",     ObjType);
  public static final Type FieldType     = builtin("Field",    SlotType);
  public static final Type MethodType    = builtin("Method",   SlotType);
  public static final Type ParamType     = builtin("Param",    ObjType);

  // resources
  public static final Type NamespaceType     = builtin("Namespace",     ObjType);
  public static final Type RootNamespaceType = builtin("RootNamespace", NamespaceType);
  public static final Type SysNamespaceType  = builtin("SysNamespace",  NamespaceType);
  public static final Type DirNamespaceType  = builtin("DirNamespace",  NamespaceType);

  // IO
  public static final Type CharsetType      = builtin("Charset",      ObjType);
  public static final Type InStreamType     = builtin("InStream",     ObjType);
  public static final Type SysInStreamType  = builtin("SysInStream",  ObjType);
  public static final Type OutStreamType    = builtin("OutStream",    ObjType);
  public static final Type SysOutStreamType = builtin("SysOutStream", ObjType);
  public static final Type FileType         = builtin("File",         ObjType);
  public static final Type LocalFileType    = builtin("LocalFile",    FileType);
  public static final Type ZipEntryFileType = builtin("ZipEntryFile", FileType);
  public static final Type BufType          = builtin("Buf",          ObjType);
  public static final Type MemBufType       = builtin("MemBuf",       BufType);
  public static final Type FileBufType      = builtin("FileBuf",      BufType);
  public static final Type MmapBufType      = builtin("MmapBuf",      BufType);
  public static final Type UriType          = builtin("Uri",          ObjType);
  public static final Type ZipType          = builtin("Zip",          ObjType);

  // actos
  public static final Type ActorType        = builtin("Actor",        ObjType);
  public static final Type ActorPoolType    = builtin("ActorPool",   ObjType);
  public static final Type ContextType      = builtin("Context",      ObjType);
  public static final Type FutureType       = builtin("Future",       ObjType);

  // utils
  public static final Type DependType       = builtin("Depend",       ObjType);
  public static final Type LogType          = builtin("Log",          ObjType);
  public static final Type LogLevelType     = builtin("LogLevel",     EnumType);
  public static final Type LogRecordType    = builtin("LogRecord",    ObjType);
  public static final Type LocaleType       = builtin("Locale",       ObjType);
  public static final Type MimeTypeType     = builtin("MimeType",     ObjType);
  public static final Type ProcessType      = builtin("Process",      ObjType);
  public static final Type RegexType        = builtin("Regex",        ObjType);
  public static final Type RegexMatcherType = builtin("RegexMatcher", ObjType);
  public static final Type ServiceType      = builtin("Service",      ObjType);
  public static final Type VersionType      = builtin("Version",      ObjType);
  public static final Type UnitType         = builtin("Unit",         ObjType);
  public static final Type UnsafeType       = builtin("Unsafe",       ObjType);
  public static final Type UuidType         = builtin("Uuid",         ObjType);

  // uri schemes
  public static final Type UriSchemeType    = builtin("UriScheme",    ObjType);
  public static final Type FanSchemeType    = builtin("FanScheme",    UriSchemeType);
  public static final Type FileSchemeType   = builtin("FileScheme",   UriSchemeType);

  // exceptions
  public static final Type ErrType               = builtin("Err",               ObjType);
  public static final Type ArgErrType            = builtin("ArgErr",            ErrType);
  public static final Type CancelledErrType      = builtin("CancelledErr",      ErrType);
  public static final Type CastErrType           = builtin("CastErr",           ErrType);
  public static final Type ConstErrType          = builtin("ConstErr",          ErrType);
  public static final Type IOErrType             = builtin("IOErr",             ErrType);
  public static final Type IndexErrType          = builtin("IndexErr",          ErrType);
  public static final Type InterruptedErrType    = builtin("InterruptedErr",    ErrType);
  public static final Type NameErrType           = builtin("NameErr",           ErrType);
  public static final Type NotImmutableErrType   = builtin("NotImmutableErr",   ErrType);
  public static final Type NullErrType           = builtin("NullErr",           ErrType);
  public static final Type ParseErrType          = builtin("ParseErr",          ErrType);
  public static final Type ReadonlyErrType       = builtin("ReadonlyErr",       ErrType);
  public static final Type TestErrType           = builtin("TestErr",           ErrType);
  public static final Type TimeoutErrType        = builtin("TimeoutErr",        ErrType);
  public static final Type UnknownPodErrType     = builtin("UnknownPodErr",     ErrType);
  public static final Type UnknownServiceErrType = builtin("UnknownServiceErr", ErrType);
  public static final Type UnknownSlotErrType    = builtin("UnknownSlotErr",    ErrType);
  public static final Type UnknownTypeErrType    = builtin("UnknownTypeErr",    ErrType);
  public static final Type UnresolvedErrType     = builtin("UnresolvedErr",     ErrType);
  public static final Type UnsupportedErrType    = builtin("UnsupportedErr",    ErrType);

  // generic parameter types used with generic types List, Map, and Method
  public static final ClassType[] GenericParameterTypes = new ClassType[256];
  public static final ClassType AType, BType, CType, DType, EType, FType, GType,
                                HType, KType, LType, MType, RType, VType;
  static
  {
    GenericParameterTypes['A'] = AType = new ClassType(SysPod, "A", 0, null);  // A-H Params
    GenericParameterTypes['B'] = BType = new ClassType(SysPod, "B", 0, null);
    GenericParameterTypes['C'] = CType = new ClassType(SysPod, "C", 0, null);
    GenericParameterTypes['D'] = DType = new ClassType(SysPod, "D", 0, null);
    GenericParameterTypes['E'] = EType = new ClassType(SysPod, "E", 0, null);
    GenericParameterTypes['F'] = FType = new ClassType(SysPod, "F", 0, null);
    GenericParameterTypes['G'] = GType = new ClassType(SysPod, "G", 0, null);
    GenericParameterTypes['H'] = HType = new ClassType(SysPod, "H", 0, null);
    GenericParameterTypes['K'] = KType = new ClassType(SysPod, "K", 0, null);  // Key
    GenericParameterTypes['L'] = LType = new ClassType(SysPod, "L", 0, null);  // Parameterized List
    GenericParameterTypes['M'] = MType = new ClassType(SysPod, "M", 0, null);  // Parameterized Map
    GenericParameterTypes['R'] = RType = new ClassType(SysPod, "R", 0, null);  // Return
    GenericParameterTypes['V'] = VType = new ClassType(SysPod, "V", 0, null);  // Value

    List noMixins = new List(TypeType, 0).ro();
    for (int i=0; i<GenericParameterTypes.length; ++i)
    {
      ClassType gp = GenericParameterTypes[i];
      if (gp == null) continue;
      gp.base = ObjType;
      gp.mixins = noMixins;
    }
  }

  public static Type genericParameterType(String name)
  {
    if (name.length() == 1 && name.charAt(0) < GenericParameterTypes.length)
      return GenericParameterTypes[name.charAt(0)];
    else
      return null;
  }

  static Type builtin(String name, Type base)
  {
    try
    {
      return SysPod.findType(name, true);
    }
    catch (Throwable e)
    {
      System.out.println("FATAL: Cannot init Sys builtin " + name);
      e.printStackTrace();
      return null;
    }
  }

  public static final List args = new List(StrType);
  public static final LocalFile homeDir = toLocalFile("homeDir", HomeDir);
  public static final LocalFile appDir  = toLocalFile("appDir",  AppDir);

  private static LocalFile toLocalFile(String fieldName, File f)
  {
    try
    {
      return new LocalFile(f, true);
    }
    catch (Throwable e)
    {
      System.out.println("FATAL: Cannot init Sys." + fieldName);
      e.printStackTrace();
      return null;
    }
  }

  public static final String hostName;
  static
  {
    String name;
    try
    {
      name = java.net.InetAddress.getLocalHost().getHostName();
    }
    catch (Throwable e)
    {
      name = "unknown";
    }
    hostName = name;
  }

  public static final String userName = System.getProperty("user.name", "unknown");

//////////////////////////////////////////////////////////////////////////
// Env
//////////////////////////////////////////////////////////////////////////

  private static Map env = new Map(StrType, StrType);
  static
  {
    try
    {
      env.caseInsensitive(true);

      // environment variables
      java.util.Map getenv = System.getenv();
      Iterator it = getenv.keySet().iterator();
      while (it.hasNext())
      {
        String key = (String)it.next();
        String val = (String)getenv.get(key);
        env.set(key, val);
      }

      // Java system properties
      it = System.getProperties().keySet().iterator();
      while (it.hasNext())
      {
        String key = (String)it.next();
        String val = System.getProperty(key);
        env.set(key, val);
      }

      // sys.properties
      LocalFile f = new LocalFile(new File(HomeDir, "lib" + File.separator + "sys.props"));
      if (f.exists())
      {
        try
        {
          Map props = f.readProps();
          env.setAll(props);
        }
        catch (Exception e)
        {
          System.out.println("ERROR: Invalid props file: " + f);
          System.out.println("  " + e);
        }
      }
    }
    catch (Throwable e)
    {
      e.printStackTrace();
    }
    env = env.ro();
  }

//////////////////////////////////////////////////////////////////////////
// Java Versions
//////////////////////////////////////////////////////////////////////////

  /** Are we running 1.6 or greater */
  public static boolean isJava1_6() { return javaVersion.compare(v1_6) >= 0; }

  public static final Version javaVersion;
  public static final Version v1_6 = Version.fromStr("1.6");
  static
  {
    String verStr = System.getProperty("java.version");
    Version ver = null;
    try
    {
      for (int i=0; i<verStr.length(); ++i)
      {
        int c = verStr.charAt(i);
        if (c == '.' || ('0' <= c && c <= '9')) continue;
        verStr = verStr.substring(0, i);
        break;
      }
      ver = Version.fromStr(verStr);
    }
    catch (Throwable e)
    {
      System.out.println("ERROR: Cannot parse java version: " + verStr);
      System.out.println("  " + e);
      ver = Version.fromStr("1.0");
    }
    javaVersion = ver;
  }

//////////////////////////////////////////////////////////////////////////
// Namespace
//////////////////////////////////////////////////////////////////////////

  static final RootNamespace ns;

  static
  {
    RootNamespace x = null;
    try
    {
      x = new RootNamespace();
    }
    catch (Throwable e)
    {
      e.printStackTrace();
    }
    ns = x;
  }

//////////////////////////////////////////////////////////////////////////
// Touch
//////////////////////////////////////////////////////////////////////////

  static
  {
    try
    {
      DateTime.boot();
      Duration.boot();
    }
    catch (Throwable e)
    {
      e.printStackTrace();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Compiler Utils
//////////////////////////////////////////////////////////////////////////

  public static Type compile(fan.sys.File file) { return ScriptUtil.compile(file, null); }
  public static Type compile(fan.sys.File file, Map options) { return ScriptUtil.compile(file, options); }

}