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
 * Sys provides static access to the system's environment and initializes
 * key data structures in a specific order in its static initializer.
 */
public final class Sys
{

//////////////////////////////////////////////////////////////////////////
// Fields (loaded before type constants)
//////////////////////////////////////////////////////////////////////////

  /** Env.os constant */
  public static final String os = initOs();

  /** Env.arch constant */
  public static final String arch = initArch();

  /** Env.platform constant */
  public static final String platform  = os + "-" + arch;

  /** Booting from only a JAR distribution? */
  public static final boolean isJarDist = initIsJarDist();

  /** BootEnv.homeDir */
  public static final File homeDir = initHomeDir();

  /** {BootEnv.homeDir}/lib/fan/ */
  public static final File podsDir = initPodsDir();

  /** {BootEnv.homeDir}/lib/fan/sys.pod */
  public static final Pod sysPod = initSysPod();

//////////////////////////////////////////////////////////////////////////
// Java Version
//////////////////////////////////////////////////////////////////////////

  public static int JAVA_1_5 = 15;
  public static int JAVA_1_6 = 16;
  public static int JAVA_1_7 = 17;
  public static int JAVA_1_8 = 18;
  public static int JAVA_1_9 = 19;

  /** Java version 1.5, 1.6, 1.7, etc */
  public static int javaVersion = initJavaVersion();

//////////////////////////////////////////////////////////////////////////
// Fields (type constants)
//////////////////////////////////////////////////////////////////////////

  // the Eve of all types
  public static final Type ObjType       = initType("Obj");

  // basic primitives
  public static final Type NumType       = initType("Num");
  public static final Type EnumType      = initType("Enum");
  public static final Type FacetType     = initType("Facet");
  public static final Type BoolType      = initType("Bool");
  public static final Type DurationType  = initType("Duration");
  public static final Type FuncType      = initType("Func");
  public static final Type IntType       = initType("Int");
  public static final Type DecimalType   = initType("Decimal");
  public static final Type FloatType     = initType("Float");
  public static final Type ListType      = initType("List");
  public static final Type MapType       = initType("Map");
  public static final Type MonthType     = initType("Month");
  public static final Type PodType       = initType("Pod");
  public static final Type RangeType     = initType("Range");
  public static final Type StrType       = initType("Str");
  public static final Type StrBufType    = initType("StrBuf");
  public static final Type TestType      = initType("Test");
  public static final Type DateTimeType  = initType("DateTime");
  public static final Type DateType      = initType("Date");
  public static final Type TimeType      = initType("Time");
  public static final Type TimeZoneType  = initType("TimeZone");
  public static final Type TypeType      = initType("Type");
  public static final Type WeekdayType   = initType("Weekday");
  public static final Type ThisType      = initType("This");
  public static final Type VoidType      = initType("Void");
  public static final Type EnvType       = initType("Env");
  public static final Type BootEnvType   = initType("BootEnv");
  public static final Type JarDistEnvType = initType("JarDistEnv");

  // reflection
  public static final Type SlotType      = initType("Slot");
  public static final Type FieldType     = initType("Field");
  public static final Type MethodType    = initType("Method");
  public static final Type ParamType     = initType("Param");

  // IO
  public static final Type CharsetType      = initType("Charset");
  public static final Type EndianType       = initType("Endian");
  public static final Type InStreamType     = initType("InStream");
  public static final Type SysInStreamType  = initType("SysInStream");
  public static final Type OutStreamType    = initType("OutStream");
  public static final Type SysOutStreamType = initType("SysOutStream");
  public static final Type FileType         = initType("File");
  public static final Type LocalFileType    = initType("LocalFile");
  public static final Type ZipEntryFileType = initType("ZipEntryFile");
  public static final Type MemFileType      = initType("MemFile");
  public static final Type BufType          = initType("Buf");
  public static final Type MemBufType       = initType("MemBuf");
  public static final Type ConstBufType     = initType("ConstBuf");
  public static final Type FileBufType      = initType("FileBuf");
  public static final Type NioBufType       = initType("NioBuf");
  public static final Type UriType          = initType("Uri");
  public static final Type ZipType          = initType("Zip");
  public static final Type ClassLoaderFileType = initType("ClassLoaderFile");
  public static final Type FileStoreType       = initType("FileStore");
  public static final Type LocalFileStoreType  = initType("LocalFileStore");

  // utils
  public static final Type DependType       = initType("Depend");
  public static final Type LogType          = initType("Log");
  public static final Type LogLevelType     = initType("LogLevel");
  public static final Type LogRecType       = initType("LogRec");
  public static final Type LocaleType       = initType("Locale");
  public static final Type MimeTypeType     = initType("MimeType");
  public static final Type ProcessType      = initType("Process");
  public static final Type RegexType        = initType("Regex");
  public static final Type RegexMatcherType = initType("RegexMatcher");
  public static final Type ServiceType      = initType("Service");
  public static final Type VersionType      = initType("Version");
  public static final Type UnitType         = initType("Unit");
  public static final Type UnsafeType       = initType("Unsafe");
  public static final Type UuidType         = initType("Uuid");

  // uri schemes
  public static final Type UriSchemeType    = initType("UriScheme");
  public static final Type FanSchemeType    = initType("FanScheme");
  public static final Type FileSchemeType   = initType("FileScheme");

  // facets
  public static final Type TransientType      = initType("Transient");
  public static final Type SerializableType   = initType("Serializable");
  public static final Type JsType             = initType("Js");
  public static final Type NoDocType          = initType("NoDoc");
  public static final Type DeprecatedType     = initType("Deprecated");
  public static final Type OperatorType       = initType("Operator");
  public static final Type FacetMetaType      = initType("FacetMeta");

  // exceptions
  public static final Type ErrType               = initType("Err");
  public static final Type ArgErrType            = initType("ArgErr");
  public static final Type CancelledErrType      = initType("CancelledErr");
  public static final Type CastErrType           = initType("CastErr");
  public static final Type ConstErrType          = initType("ConstErr");
  public static final Type FieldNotSetErrType    = initType("FieldNotSetErr");
  public static final Type IOErrType             = initType("IOErr");
  public static final Type IndexErrType          = initType("IndexErr");
  public static final Type InterruptedErrType    = initType("InterruptedErr");
  public static final Type NameErrType           = initType("NameErr");
  public static final Type NotImmutableErrType   = initType("NotImmutableErr");
  public static final Type NullErrType           = initType("NullErr");
  public static final Type ParseErrType          = initType("ParseErr");
  public static final Type ReadonlyErrType       = initType("ReadonlyErr");
  public static final Type TestErrType           = initType("TestErr");
  public static final Type TimeoutErrType        = initType("TimeoutErr");
  public static final Type UnknownKeyErrType     = initType("UnknownKeyErr");
  public static final Type UnknownPodErrType     = initType("UnknownPodErr");
  public static final Type UnknownServiceErrType = initType("UnknownServiceErr");
  public static final Type UnknownSlotErrType    = initType("UnknownSlotErr");
  public static final Type UnknownFacetErrType   = initType("UnknownFacetErr");
  public static final Type UnknownTypeErrType    = initType("UnknownTypeErr");
  public static final Type UnresolvedErrType     = initType("UnresolvedErr");
  public static final Type UnsupportedErrType    = initType("UnsupportedErr");

  // generic parameter types used with generic types List, Map, and Method
  static final ClassType[] genericParamTypes = new ClassType[256];
  public static final ClassType AType = initGeneric('A');
  public static final ClassType BType = initGeneric('B');
  public static final ClassType CType = initGeneric('C');
  public static final ClassType DType = initGeneric('D');
  public static final ClassType EType = initGeneric('E');
  public static final ClassType FType = initGeneric('F');
  public static final ClassType GType = initGeneric('G');
  public static final ClassType HType = initGeneric('H');
  public static final ClassType KType = initGeneric('K');
  public static final ClassType LType = initGeneric('L');
  public static final ClassType MType = initGeneric('M');
  public static final ClassType RType = initGeneric('R');
  public static final ClassType VType = initGeneric('V');
  static { initGenericParamTypes(); }

//////////////////////////////////////////////////////////////////////////
// Fields (loaded after type constants)
//////////////////////////////////////////////////////////////////////////

  /** Empty Str:Obj? map */
  public static final Map emptyStrObjMap = initEmptyStrMap(ObjType.toNullable());

  /** Empty Str:Str map */
  public static final Map emptyStrStrMap = initEmptyStrMap(StrType);

  /** Empty Str:Type map */
  public static final Map emptyStrTypeMap = initEmptyStrMap(TypeType);

  /** Bootstrap environment */
  public static final BootEnv bootEnv = new BootEnv();
  static Env curEnv = bootEnv;

  /** {BootEnv.homeDir}/etc/sys/config.props */
  public static final Map sysConfig = initSysConfig();

  /** Config prop used to generating debug attributes in bytecode */
  public static final boolean debug = sysConfigBool("debug", false);

  /** Config prop used to determine max stack trace  */
  public static final int errTraceMaxDepth = sysConfigInt("errTraceMaxDepth", 25);

  /** Absolute boot time */
  public static final DateTime bootDateTime = initBootDateTime();

  /** Relative boot time */
  public static final Duration bootDuration = initBootDuration();

  /** Current environment - do this after sys fully booted */
  static
  {
    initEnv();
    initEnvClassPath();
  }

//////////////////////////////////////////////////////////////////////////
// Platform Init
//////////////////////////////////////////////////////////////////////////

  private static String initOs()
  {
    try
    {
      String os = System.getProperty("os.name", "unknown");
      os = sanitize(os);
      if (os.contains("win"))   return "win32";
      if (os.contains("mac"))   return "macosx";
      if (os.contains("sunos")) return "solaris";
      return os;
    }
    catch (Throwable e)
    {
      throw initFail("os", e);
    }
  }

  private static String initArch()
  {
    try
    {
      String arch = System.getProperty("os.arch", "unknown");
      arch = sanitize(arch);
      if (arch.contains("i386"))  return "x86";
      if (arch.contains("amd64")) return "x86_64";
      return arch;
    }
    catch (Throwable e)
    {
      throw initFail("arch", e);
    }
  }

  private static String sanitize(String s)
  {
    StringBuilder buf = new StringBuilder();
    for (int i=0; i<s.length(); ++i)
    {
      int c = s.charAt(i);
      if (c == '_') { buf.append((char)c); continue; }
      if ('a' <= c && c <= 'z') { buf.append((char)c); continue; }
      if ('0' <= c && c <= '9') { buf.append((char)c); continue; }
      if ('A' <= c && c <= 'Z') { buf.append((char)(c | 0x20)); continue; }
      // skip it
    }
    return buf.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Init isJarDist
//////////////////////////////////////////////////////////////////////////

  private static boolean initIsJarDist()
  {
    return System.getProperty("fan.jardist", "false").equals("true");
  }

//////////////////////////////////////////////////////////////////////////
// Dir Init
//////////////////////////////////////////////////////////////////////////

  private static File initHomeDir()
  {
    try
    {
      return sysPropToDir("fan.home", "FAN_HOME", null);
    }
    catch (Throwable e)
    {
      throw initFail("homeDir", e);
    }
  }

  private static File initPodsDir()
  {
    try
    {
      return new File(homeDir, "lib" + File.separator + "fan");
    }
    catch (Throwable e)
    {
      throw initFail("podsDir", e);
    }
  }

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

    // map to java.io.File and check that it is a valid directory
    File f = new File(val);
    if (!f.exists() || !f.isDirectory())
      throw new RuntimeException("Invalid " + propKey + " dir: " + f);
    return f;
  }

//////////////////////////////////////////////////////////////////////////
// Init Sys Pod
//////////////////////////////////////////////////////////////////////////

  static Pod initSysPod()
  {
    try
    {
      return Pod.doFind("sys", true, null, null);
    }
    catch (Throwable e)
    {
      throw initFail("sysPod", e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Init Java Version
//////////////////////////////////////////////////////////////////////////

  static int initJavaVersion()
  {
    try
    {
      String s = System.getProperty("java.version", "1.5.0");
      if (s.startsWith("1.9.")) return JAVA_1_9;
      if (s.startsWith("1.8.")) return JAVA_1_8;
      if (s.startsWith("1.7.")) return JAVA_1_7;
      if (s.startsWith("1.6.")) return JAVA_1_6;
      return JAVA_1_5;
    }
    catch (Throwable e)
    {
      throw initFail("javaVersion", e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Init Types
//////////////////////////////////////////////////////////////////////////

  static Type initType(String name)
  {
    try
    {
      return sysPod.type(name, true);
    }
    catch (Throwable e)
    {
      throw initFail("type " + name, e);
    }
  }

  private static ClassType initGeneric(int ch)
  {
    String name = String.valueOf((char)ch);
    try
    {
      return genericParamTypes[ch] = new ClassType(sysPod, name, 0, null);
    }
    catch (Throwable e)
    {
      throw initFail("generic " + name, e);
    }
  }

  private static void initGenericParamTypes()
  {
    List noMixins = new List(TypeType, 0).ro();
    for (int i=0; i<genericParamTypes.length; ++i)
    {
      ClassType gp = genericParamTypes[i];
      if (gp == null) continue;
      gp.base = ObjType;
      gp.mixins = noMixins;
    }
  }

  public static Type genericParamType(String name)
  {
    if (name.length() == 1 && name.charAt(0) < genericParamTypes.length)
      return genericParamTypes[name.charAt(0)];
    else
      return null;
  }

//////////////////////////////////////////////////////////////////////////
// Init Env
//////////////////////////////////////////////////////////////////////////

  private static void initEnv()
  {
    try
    {
      // if running from JAR, we have to use special JarDistEnv
      if (isJarDist)
      {
        curEnv = JarDistEnv.make();
        return;
      }

      // check FAN_ENV environment variable
      String var = (String)Env.cur().vars().get("FAN_ENV");
      if (var != null)
      {
        curEnv = (Env)Type.find(var).make();
        return;
      }

      // lookup up from current directory to find "fan.props" file
      File dir = new File(".").getCanonicalFile();
      while (dir != null)
      {
        File fanFile = new File(dir, "fan.props");
        if (fanFile.exists())
        {
          curEnv = (Env)Type.find("util::PathEnv").method("makeProps").call(new LocalFile(fanFile));
          return;
        }
        dir = dir.getParentFile();
      }
    }
    catch (Exception e)
    {
      initWarn("curEnv", e);
    }
  }

  private static void initEnvClassPath()
  {
    try
    {
      // add environment's work dir to classpath
      LocalFile homeDir = (LocalFile)curEnv.homeDir();
      LocalFile workDir = (LocalFile)curEnv.workDir();
      if (!homeDir.equals(workDir))
        FanClassLoader.extClassLoader.addFanDir(workDir.file);
    }
    catch (Exception e)
    {
      initWarn("envClassPath", e);
    }
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
      String sep = java.io.File.separator;
      LocalFile f = new LocalFile(new java.io.File(homeDir, "etc" + sep + "sys" + sep + "config.props"));
      if (f.exists())
      {
        try
        {
          return f.readProps();
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
      throw initFail("sysConfig", e);
    }
    return emptyStrStrMap;
  }

  static String sysConfig(String name)
  {
    return (String)sysConfig.get(name);
  }

  static boolean sysConfigBool(String name, boolean def)
  {
    String val = sysConfig(name);
    if (val != null) return val.equals("true");
    return def;
  }

  static int sysConfigInt(String name, int def)
  {
    try
    {
      String val = sysConfig(name);
      if (val != null) return Integer.parseInt(val);
    }
    catch (Exception e) {}
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
    catch (Throwable e)
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
    catch (Throwable e)
    {
      throw initFail("bootDuration", e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private static void initWarn(String field, Throwable e)
  {
    System.out.println("WARN: cannot init Sys." + field);
    e.printStackTrace();
  }

  private static RuntimeException initFail(String field, Throwable e)
  {
    System.out.println("ERROR: cannot init Sys." + field);
    e.printStackTrace();
    throw new RuntimeException("Cannot boot fan: " + e.toString());
  }

  /** Force sys class to load */
  public static void boot() {}

}