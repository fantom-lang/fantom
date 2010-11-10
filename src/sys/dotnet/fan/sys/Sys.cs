//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Sep 06  Andy Frank  Creation
//

using System;
using System.Collections;
using System.Reflection;
using System.IO;
using Fanx.Fcode;
using Fanx.Util;

namespace Fan.Sys
{
  ///
  /// Sys provides static access to the system's environment.
  ///
  public sealed class Sys
  {

  //////////////////////////////////////////////////////////////////////////
  // Fields (loaded before type constants)
  //////////////////////////////////////////////////////////////////////////

    /** Env.os constant */
    public static readonly string m_os = initOs();

    /** Env.arch constant */
    public static readonly string m_arch = initArch();

    /** Env.platform constant */
    public static readonly string m_platform  = m_os + "-" + m_arch;

    /** BootEnv.homeDir */
    public static readonly string m_homeDir = initHomeDir();

    /** {BootEnv.homeDir}/lib/fan/ */
    public static readonly string m_podsDir = initPodsDir();

    /** {BootEnv.homeDir}/lib/fan/sys.pod */
    public static Pod m_sysPod = initSysPod();

  //////////////////////////////////////////////////////////////////////////
  // Fields (type constants)
  //////////////////////////////////////////////////////////////////////////

    // the Eve of all types
    public static readonly Type ObjType = initType("Obj");

    // basic primitives
    public static readonly Type NumType       = initType("Num");
    public static readonly Type EnumType      = initType("Enum");
    public static readonly Type FacetType     = initType("Facet");
    public static readonly Type BoolType      = initType("Bool");
    public static readonly Type DurationType  = initType("Duration");
    public static readonly Type FuncType      = initType("Func");
    public static readonly Type IntType       = initType("Int");
    public static readonly Type DecimalType   = initType("Decimal");
    public static readonly Type FloatType     = initType("Float");
    public static readonly Type ListType      = initType("List");
    public static readonly Type MapType       = initType("Map");
    public static readonly Type MonthType     = initType("Month");
    public static readonly Type PodType       = initType("Pod");
    public static readonly Type RangeType     = initType("Range");
    public static readonly Type StrType       = initType("Str");
    public static readonly Type StrBufType    = initType("StrBuf");
    public static readonly Type TestType      = initType("Test");
    public static readonly Type DateTimeType  = initType("DateTime");
    public static readonly Type DateType      = initType("Date");
    public static readonly Type TimeType      = initType("Time");
    public static readonly Type TimeZoneType  = initType("TimeZone");
    public static readonly Type TypeType      = initType("Type");
    public static readonly Type WeekdayType   = initType("Weekday");
    public static readonly Type ThisType      = initType("This");
    public static readonly Type VoidType      = initType("Void");
    public static readonly Type EnvType       = initType("Env");
    public static readonly Type BootEnvType   = initType("BootEnv");
    public static readonly Type JarDistEnvType = initType("JarDistEnv");

    // reflection
    public static readonly Type SlotType      = initType("Slot");
    public static readonly Type FieldType     = initType("Field");
    public static readonly Type MethodType    = initType("Method");
    public static readonly Type ParamType     = initType("Param");

    // IO
    public static readonly Type CharsetType      = initType("Charset");
    public static readonly Type EndianType       = initType("Endian");
    public static readonly Type InStreamType     = initType("InStream");
    public static readonly Type SysInStreamType  = initType("SysInStream");
    public static readonly Type OutStreamType    = initType("OutStream");
    public static readonly Type SysOutStreamType = initType("SysOutStream");
    public static readonly Type FileType         = initType("File");
    public static readonly Type LocalFileType    = initType("LocalFile");
    public static readonly Type ZipEntryFileType = initType("ZipEntryFile");
    public static readonly Type BufType          = initType("Buf");
    public static readonly Type MemBufType       = initType("MemBuf");
    public static readonly Type FileBufType      = initType("FileBuf");
    public static readonly Type MmapBufType      = initType("MmapBuf");
    public static readonly Type UriType          = initType("Uri");
    public static readonly Type ZipType          = initType("Zip");

    // utils
    public static readonly Type DependType       = initType("Depend");
    public static readonly Type LogType          = initType("Log");
    public static readonly Type LogLevelType     = initType("LogLevel");
    public static readonly Type LogRecType       = initType("LogRec");
    public static readonly Type LocaleType       = initType("Locale");
    public static readonly Type MimeTypeType     = initType("MimeType");
    public static readonly Type ProcessType      = initType("Process");
    public static readonly Type RegexType        = initType("Regex");
    public static readonly Type RegexMatcherType = initType("RegexMatcher");
    public static readonly Type ServiceType      = initType("Service");
    public static readonly Type VersionType      = initType("Version");
    public static readonly Type UnitType         = initType("Unit");
    public static readonly Type UnsafeType       = initType("Unsafe");
    public static readonly Type UuidType         = initType("Uuid");

    // uri schemes
    public static readonly Type UriSchemeType    = initType("UriScheme");
    public static readonly Type FanSchemeType    = initType("FanScheme");
    public static readonly Type FileSchemeType   = initType("FileScheme");

    // facets
    public static readonly Type TransientType      = initType("Transient");
    public static readonly Type SerializableType   = initType("Serializable");
    public static readonly Type JsType             = initType("Js");
    public static readonly Type NoDocType          = initType("NoDoc");
    public static readonly Type DeprecatedType     = initType("Deprecated");
    public static readonly Type OperatorType       = initType("Operator");
    public static readonly Type FacetMetaType      = initType("FacetMeta");

    // exceptions
    public static readonly Type ErrType               = initType("Err");
    public static readonly Type ArgErrType            = initType("ArgErr");
    public static readonly Type CancelledErrType      = initType("CancelledErr");
    public static readonly Type CastErrType           = initType("CastErr");
    public static readonly Type ConstErrType          = initType("ConstErr");
    public static readonly Type FieldNotSetErrType    = initType("FieldNotSetErr");
    public static readonly Type IOErrType             = initType("IOErr");
    public static readonly Type IndexErrType          = initType("IndexErr");
    public static readonly Type InterruptedErrType    = initType("InterruptedErr");
    public static readonly Type NameErrType           = initType("NameErr");
    public static readonly Type NotImmutableErrType   = initType("NotImmutableErr");
    public static readonly Type NullErrType           = initType("NullErr");
    public static readonly Type ParseErrType          = initType("ParseErr");
    public static readonly Type ReadonlyErrType       = initType("ReadonlyErr");
    public static readonly Type TestErrType           = initType("TestErr");
    public static readonly Type TimeoutErrType        = initType("TimeoutErr");
    public static readonly Type UnknownPodErrType     = initType("UnknownPodErr");
    public static readonly Type UnknownServiceErrType = initType("UnknownServiceErr");
    public static readonly Type UnknownSlotErrType    = initType("UnknownSlotErr");
    public static readonly Type UnknownFacetErrType   = initType("UnknownFacetErr");
    public static readonly Type UnknownTypeErrType    = initType("UnknownTypeErr");
    public static readonly Type UnresolvedErrType     = initType("UnresolvedErr");
    public static readonly Type UnsupportedErrType    = initType("UnsupportedErr");

    // generic parameter types used with generic types List, Map, and Method
    static  ClassType[] m_genericParamTypes = new ClassType[256];
    public static readonly ClassType AType = initGeneric('A');
    public static readonly ClassType BType = initGeneric('B');
    public static readonly ClassType CType = initGeneric('C');
    public static readonly ClassType DType = initGeneric('D');
    public static readonly ClassType EType = initGeneric('E');
    public static readonly ClassType FType = initGeneric('F');
    public static readonly ClassType GType = initGeneric('G');
    public static readonly ClassType HType = initGeneric('H');
    public static readonly ClassType KType = initGeneric('K');
    public static readonly ClassType LType = initGeneric('L');
    public static readonly ClassType MType = initGeneric('M');
    public static readonly ClassType RType = initGeneric('R');
    public static readonly ClassType VType = initGeneric('V');
    private static bool dummy1 = initGenericParamTypes();

  //////////////////////////////////////////////////////////////////////////
  // Fields (loaded after type constants)
  //////////////////////////////////////////////////////////////////////////

    /** Empty Str:Obj? map */
    public static readonly Map m_emptyStrObjMap = initEmptyStrMap(ObjType.toNullable());

    /** Empty Str:Str map */
    public static readonly Map m_emptyStrStrMap = initEmptyStrMap(StrType);

    /** Empty Str:Type map */
    public static readonly Map m_emptyStrTypeMap = initEmptyStrMap(TypeType);

    /** Bootstrap environment */
    public static readonly BootEnv m_bootEnv = new BootEnv();
    internal static Env m_curEnv = m_bootEnv;

    /** {BootEnv.homeDir}/etc/sys/config.props */
    public static readonly Map m_sysConfig = initSysConfig();

    /** "fan.debug" env var used to generating debug attributes in bytecode */
    public static readonly bool m_debug = sysConfigBool("debug", false);

    /** Absolute boot time */
    public static readonly DateTime m_bootDateTime = initBootDateTime();

    /** Relative boot time */
    public static readonly Duration m_bootDuration = initBootDuration();

    /** Current environment - do this after sys fully booted */
    private static bool dummy2 = initEnv();

  //////////////////////////////////////////////////////////////////////////
  // Platform Init
  //////////////////////////////////////////////////////////////////////////

    // TODO: need to query 32-bit versus 64-bit, looks like you need WMI for this
    private static string initOs() { return "win32"; }
    private static string initArch() { return "x86"; }

  //////////////////////////////////////////////////////////////////////////
  // Dir Init
  //////////////////////////////////////////////////////////////////////////

    private static string initHomeDir()
    {
      try
      {
        return sysPropToDir("fan.home", "FAN_HOME", null);
      }
      catch (Exception e)
      {
        throw initFail("homeDir", e);
      }
    }

    private static string initPodsDir()
    {
      try
      {
        return FileUtil.combine(m_homeDir, "lib", "fan");
      }
      catch (Exception e)
      {
        throw initFail("podsDir", e);
      }
    }

    private static string sysPropToDir(string propKey, string envKey, string def)
    {
      // lookup system property
      string val = SysProps.getProperty(propKey);

      // fallback to environment variable
      if (val == null)
        val = Environment.GetEnvironmentVariable(envKey);

      // fallback to def if provides
      if (val == null && def != null)
        val = def;

      // if still not found then we're toast
      if (val == null)
        throw new Exception("Missing " + propKey + " system property or " + envKey + " env var");

      // check if relative to home directory (fand, fant)
      bool checkExists = true;
      if (val.StartsWith("$home"))
      {
        val = FileUtil.combine(m_homeDir, val.Substring(6));
        checkExists = false;
      }

      // check that it is a valid directory
      if (checkExists && !Directory.Exists(val))
        throw new Exception("Invalid " + propKey + " dir: " + val);

      // make sure path gets normalized
      return new DirectoryInfo(val).FullName;
    }

  //////////////////////////////////////////////////////////////////////////
  // Init Sys Pod
  //////////////////////////////////////////////////////////////////////////

    static Pod initSysPod()
    {
      try
      {
        return Pod.doFind("sys", true, null);
      }
      catch (Exception e)
      {
        throw initFail("sysPod", e);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Init Types
  //////////////////////////////////////////////////////////////////////////

    static Type initType(string name)
    {
      try
      {
        return m_sysPod.type(name, true);
      }
      catch (Exception e)
      {
        throw initFail("type " + name, e);
      }
    }

    private static ClassType initGeneric(int ch)
    {
      string name = ""+(char)ch;
      try
      {
        return m_genericParamTypes[ch] = new ClassType(m_sysPod, name, 0, null);
      }
      catch (Exception e)
      {
        throw initFail("generic " + name, e);
      }
    }

    private static bool initGenericParamTypes()
    {
      List noMixins = new List(TypeType, 0).ro();
      for (int i=0; i<m_genericParamTypes.Length; ++i)
      {
        ClassType gp = m_genericParamTypes[i];
        if (gp == null) continue;
        gp.m_base = ObjType;
        gp.m_mixins = noMixins;
      }
      return true;
    }

    public static Type genericParamType(string name)
    {
      if (name.Length == 1 && name[0] < m_genericParamTypes.Length)
        return m_genericParamTypes[name[0]];
      else
        return null;
    }

  //////////////////////////////////////////////////////////////////////////
  // Init Env
  //////////////////////////////////////////////////////////////////////////

    private static bool initEnv()
    {
      try
      {
        string var = (string)Env.cur().vars().get("FAN_ENV");
        if (var == null) return true;
        m_curEnv = (Env)Type.find(var).make();
      }
      catch (Exception e)
      {
        initWarn("curEnv", e);
      }
      return true;
    }

  //////////////////////////////////////////////////////////////////////////
  // Empty Maps
  //////////////////////////////////////////////////////////////////////////

    private static Map initEmptyStrMap(Type v)
    {
      try
      {
        return (Map)new Map(StrType, v).toImmutable();
      }
      catch (Exception e)
      {
        throw initFail("emptyStrMap", e);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Sys Config
  //////////////////////////////////////////////////////////////////////////

    private static Map initSysConfig()
    {
      try
      {
        string path = FileUtil.combine(m_homeDir, "etc", "sys", "config.props");
        LocalFile f = new LocalFile(new FileInfo(path));

        if (f.exists())
        {
          try
          {
            return f.readProps();
          }
          catch (Exception e)
          {
            Console.WriteLine("ERROR: Invalid props file: " + f);
            Console.WriteLine("  " + e);
          }
        }
      }
      catch (Exception e)
      {
        throw initFail("sysConfig", e);
      }
      return m_emptyStrStrMap;
    }

    static string sysConfig(string name)
    {
      return (string)m_sysConfig.get(name);
    }

    static bool sysConfigBool(string name, bool def)
    {
      string val = sysConfig(name);
      if (val != null) return val == "true";
      return def;
    }

  //////////////////////////////////////////////////////////////////////////
  // Boot Times
  //////////////////////////////////////////////////////////////////////////

    private static Duration initBootDuration()
    {
      try
      {
        return Duration.now();
      }
      catch (Exception e)
      {
        throw initFail("bootDuration", e);
      }
    }

    private static DateTime initBootDateTime()
    {
      try
      {
        return DateTime.now();
      }
      catch (Exception e)
      {
        throw initFail("bootDuration", e);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    private static void initWarn(string field, Exception e)
    {
      Console.WriteLine("WARN: cannot init Sys." + field);
      Err.dumpStack(e);
    }

    private static Exception initFail(string field, Exception e)
    {
      Console.WriteLine("ERROR: cannot init Sys." + field);
      Err.dumpStack(e);
      throw new Exception("Cannot boot fan: " + e.ToString());
    }

    /**
     * Make a thread-safe copy of the specified object.
     * If it is immutable, then just return it; otherwise
     * we make a serialized copy.
     */
    public static object safe(object obj)
    {
      if (obj == null) return null;
      if (FanObj.isImmutable(obj)) return obj;
      Buf buf = new MemBuf(512);
      buf.writeObj(obj);
      buf.flip();
      return buf.readObj();
    }

    public static long nanoTime()
    {
      return System.DateTime.Now.Ticks * DateTime.nsPerTick;
    }

    public static void dumpStack()
    {
      System.Console.WriteLine(new System.Diagnostics.StackTrace(true));
    }

    /** Force sys class to load */
    public static void boot() {}
  }
}



/*

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    private Sys() {}

  //////////////////////////////////////////////////////////////////////////
  // Environment
  //////////////////////////////////////////////////////////////////////////

    public static List args() { return m_args.ro(); }

    public static Map env() { return m_env; }

internal static Env m_curEnv;

    public static Fan.Sys.File homeDir() { return m_homeDir; }

    public static string hostName() { return m_hostName; }

    public static string userName() { return m_userName; }

    public static void exit() { exit(0); }
    public static void exit(long status) { System.Environment.Exit((int)status); }

    public static InStream  @in()  { return StdIn; }
    public static OutStream @out() { return StdOut; }
    public static OutStream err()  { return StdErr; }

    public static void gc()
    {
      GC.Collect();
    }

    public static long idHash(object obj)
    {
      return System.Runtime.CompilerServices.RuntimeHelpers.GetHashCode(obj);
    }

    public static long nanoTime()
    {
      return System.DateTime.Now.Ticks * DateTime.nsPerTick;
    }

    public static Map diagnostics()
    {
      Map d = new Map(StrType, ObjType);
      // TODO - return empty map for now
      return d;
    }

    public static void dumpStack()
    {
      System.Console.WriteLine(new System.Diagnostics.StackTrace(true));
    }

  //////////////////////////////////////////////////////////////////////////
  // Platform
  //////////////////////////////////////////////////////////////////////////

    // TODO: need to query 32-bit versus 64-bit, looks like you need WMI for this
    public static string os() { return "win32"; }
    public static string arch() { return "x86"; }
    public static string platform() { return "win32-x86"; }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static string m_HomeDir;
    private static string m_PodsDir;

    public static string HomeDir { get { return m_HomeDir; } }
    public static string PodsDir { get { return m_PodsDir; } }

    public static readonly Pod SysPod;
    public static readonly InStream  StdIn;
    public static readonly OutStream StdOut;
    public static readonly OutStream StdErr;


    // are we using the bootstrap stub versions of sys types
    public static bool isStub;

    // if true then we disable FanClassLoader and all classes
    // must be available precompiled into bytecode from the
    // system's classloader (or webapp, etc); default is false
    public static bool usePrecompiledOnly = false;  // TODO

  //////////////////////////////////////////////////////////////////////////
  // Boot
  //////////////////////////////////////////////////////////////////////////

    static Sys()
    {
      try
      {
        // get fan home directory
//        HomeDir = Environment.GetEnvironmentVariable("fan_home");
//        if (HomeDir == null)
//          throw new Exception("Missing fan_home environment variable.");
//        if (!Directory.Exists(HomeDir))
//          throw new Exception("Invalid fan_home dir: " + HomeDir);

        // map key directories
        m_HomeDir = sysPropToDir("fan.home", "fan_home", null);
        m_PodsDir = FileUtil.combine(HomeDir, "lib", "fan");

        // load sys pod
        SysPod = new Pod("sys");
        Pod.m_podsByName["sys"] = SysPod;
        try
        {
          SysPod.load(Pod.readFPod("sys"));
          isStub = false;
        }
        catch (Exception e)
        {
          Console.WriteLine("WARNING: Using stub for 'sys' pod");
          Err.dumpStack(e);
          Sys.isStub = true;
        }

        // types
        ObjType = builtin("Obj", null);

        // basic primitives
        NumType      = builtin("Num",      ObjType);
        BoolType     = builtin("Bool",     ObjType);
        CharsetType  = builtin("Charset",  ObjType);
        DurationType = builtin("Duration", ObjType);
        FuncType     = builtin("Func",     ObjType);
        IntType      = builtin("Int",      NumType);
        EnumType     = builtin("Enum",     ObjType);
        DecimalType  = builtin("Decimal",  NumType);
        FloatType    = builtin("Float",    NumType);
        ListType     = builtin("List",     ObjType);
        MapType      = builtin("Map",      ObjType);
        MonthType    = builtin("Month",    EnumType);
        PodType      = builtin("Pod",      ObjType);
        RangeType    = builtin("Range",    ObjType);
        StrType      = builtin("Str",      ObjType);
        StrBufType   = builtin("StrBuf",   ObjType);
        TestType     = builtin("Test",     ObjType);
        DateTimeType = builtin("DateTime", ObjType);
        DateType     = builtin("Date",     ObjType);
        TimeType     = builtin("Time",     ObjType);
        TimeZoneType = builtin("TimeZone", ObjType);
        TypeType     = builtin("Type",     ObjType);
        UriType      = builtin("Uri",      ObjType);
        ThisType     = builtin("This",     ObjType);
        VoidType     = builtin("Void",     ObjType);
        WeekdayType  = builtin("Weekday",  EnumType);
        EnvType      = builtin("Env",      ObjType);
        BootEnvType  = builtin("BootEnv",  ObjType);

        // reflection
        SlotType        = builtin("Slot",   ObjType);
        FieldType       = builtin("Field",  SlotType);
        MethodType      = builtin("Method", SlotType);
        ParamType       = builtin("Param",  ObjType);
        SymbolType      = builtin("Symbol",  ObjType);

        // IO
        InStreamType     = builtin("InStream",     ObjType);
        SysInStreamType  = builtin("SysInStream",  ObjType);
        OutStreamType    = builtin("OutStream",    ObjType);
        SysOutStreamType = builtin("SysOutStream", ObjType);
        BufType          = builtin("Buf",          ObjType);
        MemBufType       = builtin("MemBuf",       BufType);
        MmapBufType      = builtin("MmapBuf",      BufType);
        FileBufType      = builtin("FileBuf",      BufType);
        FileType         = builtin("File",         ObjType);
        LocalFileType    = builtin("LocalFile",    FileType);
        ZipEntryFileType = builtin("ZipEntryFile", FileType);
        ZipType          = builtin("Zip",          ObjType);
        EndianType       = builtin("Endian",       EnumType);

        // utils
        DependType       = builtin("Depend",       ObjType);
        LogType          = builtin("Log",          ObjType);
        LogLevelType     = builtin("LogLevel",     EnumType);
        LogRecType       = builtin("LogRec",       ObjType);
        LocaleType       = builtin("Locale",       ObjType);
        MimeTypeType     = builtin("MimeType",     ObjType);
        ProcessType      = builtin("Process",      ObjType);
        RegexType        = builtin("Regex",        ObjType);
        RegexMatcherType = builtin("RegexMatcher", ObjType);
        ServiceType      = builtin("Service",      ObjType);
        VersionType      = builtin("Version",      ObjType);
        UnitType         = builtin("Unit",         ObjType);
        UnsafeType       = builtin("Unsafe",       ObjType);
        UuidType         = builtin("Uuid",         ObjType);

        // scheme
        UriSchemeType    = builtin("UriScheme",    ObjType);
        FanSchemeType    = builtin("FanScheme",    UriSchemeType);
        FileSchemeType   = builtin("FileScheme",   UriSchemeType);

        // exceptions
        ErrType               = builtin("Err",               ObjType);
        ArgErrType            = builtin("ArgErr",            ErrType);
        CancelledErrType      = builtin("CancelledErr",      ErrType);
        CastErrType           = builtin("CastErr",           ErrType);
        ConstErrType          = builtin("ConstErr",          ErrType);
        IndexErrType          = builtin("IndexErr",          ErrType);
        InterruptedErrType    = builtin("InterruptedErr",    ErrType);
        IOErrType             = builtin("IOErr",             ErrType);
        NameErrType           = builtin("NameErr",           ErrType);
        NotImmutableErrType   = builtin("NotImmutableErr",   ErrType);
        NullErrType           = builtin("NullErr",           ErrType);
        ParseErrType          = builtin("ParseErr",          ErrType);
        ReadonlyErrType       = builtin("ReadonlyErr",       ErrType);
        TestErrType           = builtin("TestErr",           ErrType);
        TimeoutErrType        = builtin("TimeoutErr",        ErrType);
        UnknownPodErrType     = builtin("UnknownPodErr",     ErrType);
        UnknownSlotErrType    = builtin("UnknownSlotErr",    ErrType);
        UnknownTypeErrType    = builtin("UnknownTypeErr",    ErrType);
        UnknownServiceErrType = builtin("UnknownServiceErr", ErrType);
        UnknownFacetErrType   = builtin("UnknownFacetErr",   ErrType);
        UnresolvedErrType     = builtin("UnresolvedErr",     ErrType);
        UnsupportedErrType    = builtin("UnsupportedErr",    ErrType);

        // generic types
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
        for (int i=0; i<GenericParameterTypes.Length; i++)
        {
          ClassType gp = GenericParameterTypes[i];
          if (gp == null) continue;
          gp.m_base   = ObjType;
          gp.m_mixins = noMixins;
        }

        m_args = new List(StrType);
        m_homeDir = new LocalFile(new DirectoryInfo(HomeDir));
        m_hostName = Environment.MachineName;
        m_userName = Environment.UserName;

        m_env = new Map(StrType, StrType);
        m_env.caseInsensitive(true);
        try
        {
          // predefined
          m_env.set("os.name", Environment.OSVersion.Platform.Tostring());
          m_env.set("os.version", Environment.OSVersion.Version.Tostring());

          // environment variables
          IDictionary getenv = Environment.GetEnvironmentVariables();
          foreach (DictionaryEntry de in getenv)
          {
            string key = (string)de.Key;
            string val = (string)de.Value;
            m_env.set(key, val);
          }

          // TODO - is there an equiv in C# for Java sys props?
          // TODO - is it System.Configuration.ConfigurationSettings?
          // Java system properties
          it = System.getProperties().keySet().iterator();
          while (it.hasNext())
          {
            string key = (string)it.next();
            string val = System.getProperty(key);
            env.set(string.make(key), string.make(val));
          }

          // sys.properties
          LocalFile f = new LocalFile(new FileInfo(FileUtil.combine(HomeDir, "lib", "sys.props")));
          if (f.exists())
          {
            try
            {
              Map props = f.readProps();
              m_env.setAll(props);
            }
            catch (Exception e)
            {
              System.Console.WriteLine("ERROR: Invalid props file: " + f);
              System.Console.WriteLine("  " + e);
            }
          }
        }
        catch (Exception e)
        {
          Err.dumpStack(e);
        }
        m_env = m_env.ro();

        //
        // Standard streams
        //

        StdIn  = new SysInStream(Console.OpenStandardInput());
        StdOut = new SysOutStream(Console.OpenStandardOutput());
        StdErr = new SysOutStream(Console.OpenStandardError());

        //
        // Touch
        //
        DateTime.boot();
        Duration.boot();
      }
      catch(Exception e)
      {
        Console.WriteLine("ERROR: Sys.static");
        Err.dumpStack(e);
        throw e;
      }
    }

    /// <summary>
    /// Map a system property or environment variable to a local directory.
    /// </summary>
    static string sysPropToDir(string propKey, string envKey, string def)
    {
      // lookup system property
      string val = SysProps.getProperty(propKey);

      // fallback to environment variable
      if (val == null)
        val = Environment.GetEnvironmentVariable(envKey);

      // fallback to def if provides
      if (val == null && def != null)
        val = def;

      // if still not found then we're toast
      if (val == null)
        throw new Exception("Missing " + propKey + " system property or " + envKey + " env var");

      // check that val ends in trailing newline
      //if (!val.EndsWith("/")) val += "/";

      // check if relative to home directory (fand, fant)
      bool checkExists = true;
      if (val.StartsWith("$home"))
      {
        val = FileUtil.combine(HomeDir, val.Substring(6));
        checkExists = false;
      }

      // check that it is a valid directory
      if (checkExists && !Directory.Exists(val))
        throw new Exception("Invalid " + propKey + " dir: " + val);

      // make sure path gets normalized
      return new DirectoryInfo(val).FullName;
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Make a thread-safe copy of the specified object.
    /// If it is immutable, then just return it; otherwise
    /// we make a serialized copy.
    /// </summary>
    public static object safe(object obj)
    {
      if (obj == null) return null;
      if (FanObj.isImmutable(obj)) return obj;
      Buf buf = new MemBuf(512);
      buf.m_out.writeObj(obj);
      buf.flip();
      return buf.m_in.readObj();
    }

  //////////////////////////////////////////////////////////////////////////
  // Built-in Types
  //////////////////////////////////////////////////////////////////////////

    // the Eve of all types
    public static readonly Type ObjType;

    // basic primitives
    public static readonly Type NumType;
    public static readonly Type BoolType;
    public static readonly Type CharsetType;
    public static readonly Type DurationType;
    public static readonly Type FuncType;
    public static readonly Type IntType;
    public static readonly Type EnumType;
    public static readonly Type DecimalType;
    public static readonly Type FloatType;
    public static readonly Type ListType;
    public static readonly Type MapType;
    public static readonly Type MonthType;
    public static readonly Type PodType;
    public static readonly Type RangeType;
    public static readonly Type StrType;
    public static readonly Type StrBufType;
    public static readonly Type TestType;
    public static readonly Type DateTimeType;
    public static readonly Type TimeZoneType;
    public static readonly Type DateType;
    public static readonly Type TimeType;
    public static readonly Type TypeType;
    public static readonly Type UriType;
    public static readonly Type ThisType;
    public static readonly Type VoidType;
    public static readonly Type WeekdayType;
    public static readonly Type EnvType;
    public static readonly Type BootEnvType;

    // reflection
    public static readonly Type SlotType;
    public static readonly Type FieldType;
    public static readonly Type MethodType;
    public static readonly Type ParamType;
    public static readonly Type SymbolType;

    // IO
    public static readonly Type InStreamType;
    public static readonly Type SysInStreamType;
    public static readonly Type OutStreamType;
    public static readonly Type SysOutStreamType;
    public static readonly Type BufType;
    public static readonly Type MemBufType;
    public static readonly Type MmapBufType;
    public static readonly Type FileBufType;
    public static readonly Type FileType;
    public static readonly Type LocalFileType;
    public static readonly Type ZipEntryFileType;
    public static readonly Type ZipType;
    public static readonly Type EndianType;

    // actos
    public static readonly Type ActorType;
    public static readonly Type ActorPoolType;
    public static readonly Type FutureType;

    // utils
    public static readonly Type DependType;
    public static readonly Type LogType;
    public static readonly Type LogLevelType;
    public static readonly Type LogRecType;
    public static readonly Type LocaleType;
    public static readonly Type MimeTypeType;
    public static readonly Type ProcessType;
    public static readonly Type RegexType;
    public static readonly Type RegexMatcherType;
    public static readonly Type ServiceType;
    public static readonly Type VersionType;
    public static readonly Type UnitType;
    public static readonly Type UnsafeType;
    public static readonly Type UuidType;

    // uri schemes
    public static readonly Type UriSchemeType;
    public static readonly Type FanSchemeType;
    public static readonly Type FileSchemeType;

    // exceptions
    public static readonly Type ErrType;
    public static readonly Type ArgErrType;
    public static readonly Type CancelledErrType;
    public static readonly Type CastErrType;
    public static readonly Type ConstErrType;
    public static readonly Type IndexErrType;
    public static readonly Type InterruptedErrType;
    public static readonly Type IOErrType;
    public static readonly Type NameErrType;
    public static readonly Type NotImmutableErrType;
    public static readonly Type NullErrType;
    public static readonly Type ParseErrType;
    public static readonly Type ReadonlyErrType;
    public static readonly Type TestErrType;
    public static readonly Type TimeoutErrType;
    public static readonly Type UnknownPodErrType;
    public static readonly Type UnknownSlotErrType;
    public static readonly Type UnknownTypeErrType;
    public static readonly Type UnknownServiceErrType;
    public static readonly Type UnknownFacetErrType;
    public static readonly Type UnresolvedErrType;
    public static readonly Type UnsupportedErrType;

    // generic parameter types used with generic types List, Map, and Method
    public static readonly ClassType[] GenericParameterTypes = new ClassType[256];
    public static readonly ClassType AType, BType, CType, DType, EType, FType, GType,
                             HType, KType, LType, MType, RType, VType;

    public static Type genericParameterType(string name)
    {
      if (name.Length == 1 && name[0] < GenericParameterTypes.Length)
        return GenericParameterTypes[name[0]];
      else
        return null;
    }

    static Type builtin(string name, Type baseType)
    {
      return SysPod.findType(name, true);
    }

    public static readonly List m_args;
    public static readonly LocalFile m_homeDir;
    public static readonly string m_hostName;
    public static readonly string m_userName;
    private static Map m_env;

  }
*/