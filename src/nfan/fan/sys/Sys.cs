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
  public class Sys : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    private Sys() {}

  //////////////////////////////////////////////////////////////////////////
  // Namespace
  //////////////////////////////////////////////////////////////////////////

    public static Namespace ns() { return m_ns; }
    public static Namespace ns(Uri uri) { return m_ns.ns(uri); }

    public static void mount(Uri uri, Namespace m) { m_ns.mount(uri, m); }

    public static void unmount(Uri uri) { m_ns.unmount(uri); }

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

    public static Str hostName() { return m_hostName; }

    public static Str userName() { return m_userName; }

    public static void exit() { exit(Int.Zero); }
    public static void exit(Int status) { System.Environment.Exit((int)status.val); }

    public static InStream  @in()  { return StdIn; }
    public static OutStream @out() { return StdOut; }
    public static OutStream err()  { return StdErr; }

    public static void gc()
    {
      GC.Collect();
    }

    public static Int idHash(Obj obj)
    {
      //return Int.make(System.identityHashCode(obj));
      return obj.hash();
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

    public static long ticks()
    {
      return System.DateTime.Now.Ticks * DateTime.nsPerTick;
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
        RangeType    = builtin("Range",    ObjType);
        StrType      = builtin("Str",      ObjType);
        StrBufType   = builtin("StrBuf",   ObjType);
        SysType      = builtin("Sys",      ObjType);
        TestType     = builtin("Test",     ObjType);
        DateTimeType = builtin("DateTime", ObjType);
        TimeZoneType = builtin("TimeZone", ObjType);
        ThreadType   = builtin("Thread",   ObjType);
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

        // resources
        NamespaceType     = builtin("Namespace",     ObjType);
        RootNamespaceType = builtin("RootNamespace", NamespaceType);
        SysNamespaceType  = builtin("SysNamespace",  NamespaceType);
        DirNamespaceType  = builtin("DirNamespace",  NamespaceType);

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

        // utils
        LogType          = builtin("Log",          ObjType);
        LogLevelType     = builtin("LogLevel",     EnumType);
        LogRecordType    = builtin("LogRecord",    ObjType);
        LocaleType       = builtin("Locale",       ObjType);
        MimeTypeType     = builtin("MimeType",     ObjType);
        ProcessType      = builtin("Process",      ObjType);
        RegexType        = builtin("Regex",        ObjType);
        RegexMatcherType = builtin("RegexMatcher", ObjType);
        DependType       = builtin("Depend",       ObjType);
        VersionType      = builtin("Version",      ObjType);

        // scheme
        UriSchemeType    = builtin("UriScheme",    ObjType);
        FanSchemeType    = builtin("FanScheme",    UriSchemeType);
        FileSchemeType   = builtin("FileScheme",   UriSchemeType);

        // exceptions
        ErrType              = builtin("Err",              ObjType);
        ArgErrType           = builtin("ArgErr",           ErrType);
        CastErrType          = builtin("CastErr",          ErrType);
        IndexErrType         = builtin("IndexErr",         ErrType);
        InterruptedErrType   = builtin("InterruptedErr",   ErrType);
        IOErrType            = builtin("IOErr",            ErrType);
        NameErrType          = builtin("NameErr",          ErrType);
        NotImmutableErrType  = builtin("NotImmutableErr",  ErrType);
        NullErrType          = builtin("NullErr",          ErrType);
        ParseErrType         = builtin("ParseErr",         ErrType);
        ReadonlyErrType      = builtin("ReadonlyErr",      ErrType);
        TestErrType          = builtin("TestErr",          ErrType);
        UnknownPodErrType    = builtin("UnknownPodErr",    ErrType);
        UnknownSlotErrType   = builtin("UnknownSlotErr",   ErrType);
        UnknownTypeErrType   = builtin("UnknownTypeErr",   ErrType);
        UnknownThreadErrType = builtin("UnknownThreadErr", ErrType);
        UnresolvedErrType    = builtin("UnresolvedErr",    ErrType);
        UnsupportedErrType   = builtin("UnsupportedErr",   ErrType);

        // generic types
        GenericParameterTypes['A'] = AType = new Type(SysPod, "A", 0, null);  // A-H Params
        GenericParameterTypes['B'] = BType = new Type(SysPod, "B", 0, null);
        GenericParameterTypes['C'] = CType = new Type(SysPod, "C", 0, null);
        GenericParameterTypes['D'] = DType = new Type(SysPod, "D", 0, null);
        GenericParameterTypes['E'] = EType = new Type(SysPod, "E", 0, null);
        GenericParameterTypes['F'] = FType = new Type(SysPod, "F", 0, null);
        GenericParameterTypes['G'] = GType = new Type(SysPod, "G", 0, null);
        GenericParameterTypes['H'] = HType = new Type(SysPod, "H", 0, null);
        GenericParameterTypes['K'] = KType = new Type(SysPod, "K", 0, null);  // Key
        GenericParameterTypes['L'] = LType = new Type(SysPod, "L", 0, null);  // Parameterized List
        GenericParameterTypes['M'] = MType = new Type(SysPod, "M", 0, null);  // Parameterized Map
        GenericParameterTypes['R'] = RType = new Type(SysPod, "R", 0, null);  // Return
        GenericParameterTypes['V'] = VType = new Type(SysPod, "V", 0, null);  // Value

        List noMixins = new List(TypeType, 0).ro();
        for (int i=0; i<GenericParameterTypes.Length; i++)
        {
          Type gp = GenericParameterTypes[i];
          if (gp == null) continue;
          gp.m_base   = ObjType;
          gp.m_mixins = noMixins;
        }

        m_args = new List(StrType);
        m_homeDir = new LocalFile(new DirectoryInfo(HomeDir));
// set is accesor method
//m_appDir  = new LocalFile(new DirectoryInfo(AppDir));
        m_hostName = Str.make(Environment.MachineName);
        m_userName = Str.make(Environment.UserName);

        m_env = new Map(StrType, StrType);
        m_env.caseInsensitive(Bool.True);
        try
        {
          // predefined
          m_env.set(Str.make("os.name"), Str.make(Environment.OSVersion.Platform.ToString()));
          m_env.set(Str.make("os.version"), Str.make(Environment.OSVersion.Version.ToString()));

          // environment variables
          IDictionary getenv = Environment.GetEnvironmentVariables();
          foreach (DictionaryEntry de in getenv)
          {
            string key = (string)de.Key;
            string val = (string)de.Value;
            m_env.set(Str.make(key), Str.make(val));
          }

          // TODO - is there an equiv in C# for Java sys props?
          // TODO - is it System.Configuration.ConfigurationSettings?
          /*
          // Java system properties
          it = System.getProperties().keySet().iterator();
          while (it.hasNext())
          {
            String key = (String)it.next();
            String val = System.getProperty(key);
            env.set(Str.make(key), Str.make(val));
          }
          */

          // sys.properties
          LocalFile f = new LocalFile(new FileInfo(FileUtil.combine(HomeDir, "lib", "sys.props")));
          if (f.exists().val)
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
        // Namespace
        //

        RootNamespace x = null;
        try { x = new RootNamespace(); }
        catch (Exception e) { Err.dumpStack(e); }
        m_ns = x;

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
    public static readonly Type RangeType;
    public static readonly Type StrType;
    public static readonly Type StrBufType;
    public static readonly Type SysType;
    public static readonly Type TestType;
    public static readonly Type DateTimeType;
    public static readonly Type TimeZoneType;
    public static readonly Type ThreadType;
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

    // resources
    public static readonly Type NamespaceType;
    public static readonly Type RootNamespaceType;
    public static readonly Type SysNamespaceType;
    public static readonly Type DirNamespaceType;

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

    // utils
    public static readonly Type LogType;
    public static readonly Type LogLevelType;
    public static readonly Type LogRecordType;
    public static readonly Type LocaleType;
    public static readonly Type MimeTypeType;
    public static readonly Type ProcessType;
    public static readonly Type RegexType;
    public static readonly Type RegexMatcherType;
    public static readonly Type DependType;
    public static readonly Type VersionType;

    // uri schemes
    public static readonly Type UriSchemeType;
    public static readonly Type FanSchemeType;
    public static readonly Type FileSchemeType;

    // exceptions
    public static readonly Type ErrType;
    public static readonly Type ArgErrType;
    public static readonly Type CastErrType;
    public static readonly Type IndexErrType;
    public static readonly Type InterruptedErrType;
    public static readonly Type IOErrType;
    public static readonly Type NameErrType;
    public static readonly Type NotImmutableErrType;
    public static readonly Type NullErrType;
    public static readonly Type ParseErrType;
    public static readonly Type ReadonlyErrType;
    public static readonly Type TestErrType;
    public static readonly Type UnknownPodErrType;
    public static readonly Type UnknownSlotErrType;
    public static readonly Type UnknownTypeErrType;
    public static readonly Type UnknownThreadErrType;
    public static readonly Type UnresolvedErrType;
    public static readonly Type UnsupportedErrType;

    // generic parameter types used with generic types List, Map, and Method
    public static readonly Type[] GenericParameterTypes = new Type[256];
    public static readonly Type AType, BType, CType, DType, EType, FType, GType,
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
      //if (SysPod.fpod != null) return SysPod.findType(name, true);
      //return SysPod.Stub(Type.Stub(SysPod, name, baseType));
    }

    public static readonly List m_args;
    public static readonly LocalFile m_homeDir;
    public static LocalFile m_appDir;
    public static readonly Str m_hostName;
    public static readonly Str m_userName;
    private static Map m_env;

    // Namespace
    internal static readonly RootNamespace m_ns;

    // Compiler Utils
    public static Type compile(Fan.Sys.File file) { return ScriptUtil.compile(file, null); }
    public static Type compile(Fan.Sys.File file, Map options) { return ScriptUtil.compile(file, options); }

  }
}
