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
  public sealed class Sys : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    private Sys() {}

  //////////////////////////////////////////////////////////////////////////
  // Environment
  //////////////////////////////////////////////////////////////////////////

    public static List args() { return m_args.ro(); }

    public static Map env() { return m_env; }

    public static Fan.Sys.File homeDir() { return m_homeDir; }

    public static Fan.Sys.File appDir()
    {
      if (m_appDir == null)
        m_appDir = new LocalFile(new DirectoryInfo(AppDir));
      return m_appDir;
    }

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
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static string m_HomeDir;
    private static string m_AppDir;
    private static string m_PodsDir;

    public static string HomeDir { get { return m_HomeDir; } }
    public static string PodsDir { get { return m_PodsDir; } }

    // TODO - this is sort of a big hack, need to really
    // go back and clean all this code up
    public static string AppDir
    {
      get
      {
        if (m_AppDir == null)
          m_AppDir = sysPropToDir("fan.appDir", "fan_appDir", Directory.GetCurrentDirectory());
        return m_AppDir;
      }
    }

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
// set in prop getter
//m_AppDir  = sysPropToDir("fan.appDir", "fan_appDir", Directory.GetCurrentDirectory());
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
        RepoType     = builtin("Repo",     ObjType);
        RangeType    = builtin("Range",    ObjType);
        StrType      = builtin("Str",      ObjType);
        StrBufType   = builtin("StrBuf",   ObjType);
        SysType      = builtin("Sys",      ObjType);
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

        // reflection
        SlotType        = builtin("Slot",   ObjType);
        FieldType       = builtin("Field",  SlotType);
        MethodType      = builtin("Method", SlotType);
        ParamType       = builtin("Param",  ObjType);
        SymbolType      = builtin("Symbol",  ObjType);

        // resources
        UriSpaceType     = builtin("UriSpace",     ObjType);
        RootUriSpaceType = builtin("RootUriSpace", UriSpaceType);
        SysUriSpaceType  = builtin("SysUriSpace",  UriSpaceType);
        DirUriSpaceType  = builtin("DirUriSpace",  UriSpaceType);

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

        // actos
        ActorType        = builtin("Actor",        ObjType);
        ActorPoolType    = builtin("ActorPool",    ObjType);
        ContextType      = builtin("Context",      ObjType);
        FutureType       = builtin("Future",       ObjType);

        // utils
        DependType       = builtin("Depend",       ObjType);
        LogType          = builtin("Log",          ObjType);
        LogLevelType     = builtin("LogLevel",     EnumType);
        LogRecordType    = builtin("LogRecord",    ObjType);
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
        UnknownSymbolErrType  = builtin("UnknownSymbolErr",  ErrType);
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
// set is accesor method
//m_appDir  = new LocalFile(new DirectoryInfo(AppDir));
        m_hostName = Environment.MachineName;
        m_userName = Environment.UserName;

        m_env = new Map(StrType, StrType);
        m_env.caseInsensitive(true);
        try
        {
          // predefined
          m_env.set("os.name", Environment.OSVersion.Platform.ToString());
          m_env.set("os.version", Environment.OSVersion.Version.ToString());

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
          /*
          // Java system properties
          it = System.getProperties().keySet().iterator();
          while (it.hasNext())
          {
            string key = (string)it.next();
            string val = System.getProperty(key);
            env.set(string.make(key), string.make(val));
          }
          */

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
    public static readonly Type RepoType;
    public static readonly Type RangeType;
    public static readonly Type StrType;
    public static readonly Type StrBufType;
    public static readonly Type SysType;
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

    // reflection
    public static readonly Type SlotType;
    public static readonly Type FieldType;
    public static readonly Type MethodType;
    public static readonly Type ParamType;
    public static readonly Type SymbolType;

    // resources
    public static readonly Type UriSpaceType;
    public static readonly Type RootUriSpaceType;
    public static readonly Type SysUriSpaceType;
    public static readonly Type DirUriSpaceType;

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

    // actos
    public static readonly Type ActorType;
    public static readonly Type ActorPoolType;
    public static readonly Type ContextType;
    public static readonly Type FutureType;

    // utils
    public static readonly Type DependType;
    public static readonly Type LogType;
    public static readonly Type LogLevelType;
    public static readonly Type LogRecordType;
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
    public static readonly Type UnknownSymbolErrType;
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
    public static LocalFile m_appDir;
    public static readonly string m_hostName;
    public static readonly string m_userName;
    private static Map m_env;

    // Compiler Utils
    public static Type compile(Fan.Sys.File file) { return ScriptUtil.compile(file, null); }
    public static Type compile(Fan.Sys.File file, Map options) { return ScriptUtil.compile(file, options); }

  }
}