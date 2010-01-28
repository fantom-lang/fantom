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

  /** BootEnv.homeDir */
  public static final File homeDir = initHomeDir();

  /** {BootEnv.homeDir}/lib/fan/ */
  public static final File podsDir = initPodsDir();

  /** {BootEnv.homeDir}/lib/fan/sys.pod */
  public static final Pod  sysPod  = initSysPod();

//////////////////////////////////////////////////////////////////////////
// Fields (type constants)
//////////////////////////////////////////////////////////////////////////

  // the Eve of all types
  public static final Type ObjType       = initType("Obj",      null);

  // basic primitives
  public static final Type NumType       = initType("Num",      ObjType);
  public static final Type EnumType      = initType("Enum",     ObjType);
  public static final Type BoolType      = initType("Bool",     ObjType);
  public static final Type DurationType  = initType("Duration", ObjType);
  public static final Type FuncType      = initType("Func",     ObjType);
  public static final Type IntType       = initType("Int",      NumType);
  public static final Type DecimalType   = initType("Decimal",  NumType);
  public static final Type FloatType     = initType("Float",    NumType);
  public static final Type ListType      = initType("List",     ObjType);
  public static final Type MapType       = initType("Map",      ObjType);
  public static final Type MonthType     = initType("Month",    EnumType);
  public static final Type PodType       = initType("Pod",      ObjType);
  public static final Type RepoType      = initType("Repo",     ObjType);
  public static final Type RangeType     = initType("Range",    ObjType);
  public static final Type StrType       = initType("Str",      ObjType);
  public static final Type StrBufType    = initType("StrBuf",   ObjType);
  public static final Type TestType      = initType("Test",     ObjType);
  public static final Type DateTimeType  = initType("DateTime", ObjType);
  public static final Type DateType      = initType("Date",     ObjType);
  public static final Type TimeType      = initType("Time",     ObjType);
  public static final Type TimeZoneType  = initType("TimeZone", ObjType);
  public static final Type TypeType      = initType("Type",     ObjType);
  public static final Type WeekdayType   = initType("Weekday",  EnumType);
  public static final Type ThisType      = initType("This",     ObjType);
  public static final Type VoidType      = initType("Void",     ObjType);
  public static final Type EnvType       = initType("Env",      ObjType);
  public static final Type BootEnvType   = initType("BootEnv",  EnvType);

  // reflection
  public static final Type SlotType      = initType("Slot",     ObjType);
  public static final Type FieldType     = initType("Field",    SlotType);
  public static final Type MethodType    = initType("Method",   SlotType);
  public static final Type ParamType     = initType("Param",    ObjType);
  public static final Type SymbolType    = initType("Symbol",   ObjType);

  // resources
  public static final Type UriSpaceType     = initType("UriSpace",     ObjType);
  public static final Type RootUriSpaceType = initType("RootUriSpace", UriSpaceType);
  public static final Type SysUriSpaceType  = initType("SysUriSpace",  UriSpaceType);
  public static final Type DirUriSpaceType  = initType("DirUriSpace",  UriSpaceType);

  // IO
  public static final Type CharsetType      = initType("Charset",      ObjType);
  public static final Type EndianType       = initType("Endian",       EnumType);
  public static final Type InStreamType     = initType("InStream",     ObjType);
  public static final Type SysInStreamType  = initType("SysInStream",  ObjType);
  public static final Type OutStreamType    = initType("OutStream",    ObjType);
  public static final Type SysOutStreamType = initType("SysOutStream", ObjType);
  public static final Type FileType         = initType("File",         ObjType);
  public static final Type LocalFileType    = initType("LocalFile",    FileType);
  public static final Type ZipEntryFileType = initType("ZipEntryFile", FileType);
  public static final Type BufType          = initType("Buf",          ObjType);
  public static final Type MemBufType       = initType("MemBuf",       BufType);
  public static final Type FileBufType      = initType("FileBuf",      BufType);
  public static final Type MmapBufType      = initType("MmapBuf",      BufType);
  public static final Type UriType          = initType("Uri",          ObjType);
  public static final Type ZipType          = initType("Zip",          ObjType);

  // actos
  public static final Type ActorType        = initType("Actor",        ObjType);
  public static final Type ActorPoolType    = initType("ActorPool",    ObjType);
  public static final Type FutureType       = initType("Future",       ObjType);

  // utils
  public static final Type DependType       = initType("Depend",       ObjType);
  public static final Type LogType          = initType("Log",          ObjType);
  public static final Type LogLevelType     = initType("LogLevel",     EnumType);
  public static final Type LogRecType       = initType("LogRec",       ObjType);
  public static final Type LocaleType       = initType("Locale",       ObjType);
  public static final Type MimeTypeType     = initType("MimeType",     ObjType);
  public static final Type ProcessType      = initType("Process",      ObjType);
  public static final Type RegexType        = initType("Regex",        ObjType);
  public static final Type RegexMatcherType = initType("RegexMatcher", ObjType);
  public static final Type ServiceType      = initType("Service",      ObjType);
  public static final Type VersionType      = initType("Version",      ObjType);
  public static final Type UnitType         = initType("Unit",         ObjType);
  public static final Type UnsafeType       = initType("Unsafe",       ObjType);
  public static final Type UuidType         = initType("Uuid",         ObjType);

  // uri schemes
  public static final Type UriSchemeType    = initType("UriScheme",    ObjType);
  public static final Type FanSchemeType    = initType("FanScheme",    UriSchemeType);
  public static final Type FileSchemeType   = initType("FileScheme",   UriSchemeType);

  // exceptions
  public static final Type ErrType               = initType("Err",               ObjType);
  public static final Type ArgErrType            = initType("ArgErr",            ErrType);
  public static final Type CancelledErrType      = initType("CancelledErr",      ErrType);
  public static final Type CastErrType           = initType("CastErr",           ErrType);
  public static final Type ConstErrType          = initType("ConstErr",          ErrType);
  public static final Type IOErrType             = initType("IOErr",             ErrType);
  public static final Type IndexErrType          = initType("IndexErr",          ErrType);
  public static final Type InterruptedErrType    = initType("InterruptedErr",    ErrType);
  public static final Type NameErrType           = initType("NameErr",           ErrType);
  public static final Type NotImmutableErrType   = initType("NotImmutableErr",   ErrType);
  public static final Type NullErrType           = initType("NullErr",           ErrType);
  public static final Type ParseErrType          = initType("ParseErr",          ErrType);
  public static final Type ReadonlyErrType       = initType("ReadonlyErr",       ErrType);
  public static final Type TestErrType           = initType("TestErr",           ErrType);
  public static final Type TimeoutErrType        = initType("TimeoutErr",        ErrType);
  public static final Type UnknownPodErrType     = initType("UnknownPodErr",     ErrType);
  public static final Type UnknownServiceErrType = initType("UnknownServiceErr", ErrType);
  public static final Type UnknownSlotErrType    = initType("UnknownSlotErr",    ErrType);
  public static final Type UnknownSymbolErrType  = initType("UnknownSymbolErr",  ErrType);
  public static final Type UnknownTypeErrType    = initType("UnknownTypeErr",    ErrType);
  public static final Type UnresolvedErrType     = initType("UnresolvedErr",     ErrType);
  public static final Type UnsupportedErrType    = initType("UnsupportedErr",    ErrType);

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

  /** Bootstrap environment */
  public static BootEnv bootEnv = new BootEnv();

  /** Current environment */
  static Env curEnv = bootEnv;

  /** "fan.usePrecompiledOnly" env var - loads bytecode straight from java */
  public static final boolean usePrecompiledOnly = initEnvVar("fan.usePrecompiledOnly");

  /** "fan.debug" env var used to generating debug attributes in bytecode */
  public static final boolean debug = initEnvVar("fan.debug");

  /** Absolute boot time */
  public static final DateTime bootDateTime = initBootDateTime();

  /** Relative boot time */
  public static final Duration bootDuration = initBootDuration();

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
// Init Types
//////////////////////////////////////////////////////////////////////////

  static Type initType(String name, Type base)
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
// Environment Variables
//////////////////////////////////////////////////////////////////////////

  private static boolean initEnvVar(String name)
  {
    try
    {
      return "true".equals(Env.cur().vars().get(name));
    }
    catch (Exception e)
    {
      initWarn(name, e);
      return false;
    }
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

}