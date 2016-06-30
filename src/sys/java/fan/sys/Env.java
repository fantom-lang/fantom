//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jan 10  Brian Frank  Creation
//
package fan.sys;

import java.util.HashMap;
import fanx.util.*;

/**
 * Env
 */
public abstract class Env
  extends FanObj
{

  static { Sys.boot(); }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Env cur() { return Sys.curEnv; }

  public static void make$(Env self) { make$(self, cur()); }
  public static void make$(Env self, Env parent) { self.parent = parent; }

  public Env() {}
  public Env(Env parent) { this.parent = parent; }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.EnvType; }

  public String toStr() { return typeof().toString(); }

//////////////////////////////////////////////////////////////////////////
// Non-Virtuals
//////////////////////////////////////////////////////////////////////////

  public final Env parent() { return parent; }

  public final String os() { return Sys.os; }

  public final String arch() { return Sys.arch; }

  public final String platform() { return Sys.platform; }

  public final String runtime() { return "java"; }

  public final long idHash(Object obj) { return System.identityHashCode(obj); }

//////////////////////////////////////////////////////////////////////////
// Virtuals
//////////////////////////////////////////////////////////////////////////

  public List args() { return parent.args(); }

  public Method mainMethod() { return parent.mainMethod(); }

  public Map vars()  { return parent.vars(); }

  public Map diagnostics() { return parent.diagnostics(); }

  public void gc() { parent.gc(); }

  public String host() { return parent.host(); }

  public String user() { return parent.user(); }

  public InStream in() { return parent.in(); }

  public OutStream out() { return parent.out(); }

  public OutStream err() { return parent.err(); }

  public String prompt() { return this.prompt(""); }
  public String prompt(String msg) { return parent.prompt(msg); }

  public String promptPassword() { return this.promptPassword(""); }
  public String promptPassword(String msg) { return parent.promptPassword(msg); }

  public File homeDir() { return parent.homeDir(); }

  public File workDir() { return parent.workDir(); }

  public File tempDir() { return parent.tempDir(); }

  public void exit() { this.exit(0); }
  public void exit(long status) { parent.exit(status); }

  public void addShutdownHook(Func f) { parent.addShutdownHook(f); }

  public boolean removeShutdownHook(Func f) { return parent.removeShutdownHook(f); }

//////////////////////////////////////////////////////////////////////////
// Resolution
//////////////////////////////////////////////////////////////////////////

  public File findFile(Uri uri) { return findFile(uri, true); }
  public File findFile(Uri uri, boolean checked)
  {
    return parent.findFile(uri, checked);
  }

  public List findAllFiles(Uri uri)
  {
    return parent.findAllFiles(uri);
  }

  public File findPodFile(String name)
  {
    findFile(Uri.fromStr("lib/fan/" + name + ".pod"), false);
    fan.sys.File file = findFile(Uri.fromStr("lib/fan/" + name + ".pod"), false);
    if (file == null) return null;

    // verify case since Windoze is case insensitive
    String actualName = file.normalize().name();
    if (!actualName.equals(name + ".pod")) throw UnknownPodErr.make("Case mismatch: expected '" + name + ".pod' but found '" + actualName + "'");
    return file;
  }

  public List findAllPodNames()
  {
    List acc = new List(Sys.StrType);
    List files = findFile(Uri.fromStr("lib/fan/")).list();
    for (int i=0; i<files.sz(); ++i)
    {
      File f = (File)files.get(i);
      if (f.isDir() || !"pod".equals(f.ext())) continue;
      acc.add(f.basename());
    }
    return acc;
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  public Type compileScript(File file) { return compileScript(file, null); }
  public Type compileScript(File file, Map options)
  {
    return scripts.compile(file, options);
  }

  public List index(String key)
  {
    return index.get(key);
  }

  public List indexKeys()
  {
    return index.keys();
  }

  public Map props(Pod pod, Uri uri, Duration maxAge)
  {
    return props.get(pod, uri, maxAge);
  }

  public String config(Pod pod, String key) { return config(pod, key, null); }
  public String config(Pod pod, String key, String def)
  {
    return (String)props.get(pod, configProps, Duration.oneMin).get(key, def);
  }

  public String locale(Pod pod, String key) { return locale(pod, key, noDef, Locale.cur()); }
  public String locale(Pod pod, String key, String def) { return locale(pod, key, def, Locale.cur()); }
  public String locale(Pod pod, String key, String def, Locale locale)
  {
    Object val;
    Duration maxAge = Duration.maxVal;

    // 1. 'props(pod, `locale/{locale}.props`)'
    val = props(pod, locale.strProps, maxAge).get(key, null);
    if (val != null) return (String)val;

    // 2. 'props(pod, `locale/{lang}.props`)'
    val = props(pod, locale.langProps, maxAge).get(key, null);
    if (val != null) return (String)val;

    // 3. 'props(pod, `locale/en.props`)'
    val = props(pod, localeEnProps, maxAge).get(key, null);
    if (val != null) return (String)val;

    // 4. Fallback to 'pod::key' unless 'def' specified
    if (def == noDef) return pod + "::" + key;
    return def;
  }

//////////////////////////////////////////////////////////////////////////
// Java Env
//////////////////////////////////////////////////////////////////////////

  /**
   * Load the Java class representation of Pod constants.
   * Default implementation delegates to parent.
   */
  public Class loadPodClass(Pod pod)
  {
    return parent.loadPodClass(pod);
  }

  /**
   * Load the Java class representations of a Fantom type:
   *   - Fantom class => [class]
   *   - Fantom mixin => [interface, body class]
   *   - Fantom Err class => [class, val class]
   * Default implementation delegates to parent.
   */
  public Class[] loadTypeClasses(ClassType t)
  {
    return parent.loadTypeClasses(t);
  }

  /**
   * Load the Java class of a FFI JavaType.
   * Default implementation delegates to parent.
   */
  public Class loadJavaClass(String className)
    throws Exception
  {
    return parent.loadJavaClass(className);
  }

  /**
   * Given a Java class, get its FFI JavaType mapping.  This
   * method is called by FanUtil.toFanType.  JavaTypes are be
   * cached by classname once loaded.
   */
  public final JavaType loadJavaType(Class cls)
  {
    // at this point we shouldn't have any native fan type
    String clsName = cls.getName();
    if (clsName.startsWith("fan.")) throw new IllegalStateException(clsName);

    // cache all the java types statically
    synchronized (javaTypeCache)
    {
      // if cached use that one
      JavaType t = (JavaType)javaTypeCache.get(clsName);
      if (t != null) return t;

      // create a new one
      t = new JavaType(cls);
      javaTypeCache.put(clsName, t);
      return t;
    }
  }

  /**
   * Given a Java FFI qname (pod and type name), get its FFI JavaType
   * mapping.  JavaTypes are cached once loaded.  This method is
   * kept as light weight as possible since it is used to stub all
   * the FFI references at pod load time (avoid loading classes).
   * The JavaType will delegate to `loadJavaClass` when it is time
   * to load the Java class mapped by the FFI type.
   */
  public final JavaType loadJavaType(Pod loadingPod, String podName, String typeName)
  {
    // we shouldn't be using this method for pure Fantom types
    if (!podName.startsWith("[java]"))
      throw ArgErr.make("Unsupported FFI type: " + podName + "::" + typeName);

    // ensure unnormalized "[java] package::Type" isn't used (since
    // it took me an hour to track down a bug related to this)
    if (podName.length() >= 7 && podName.charAt(6) == ' ')
      throw ArgErr.make("Java FFI qname cannot contain space: " + podName + "::" + typeName);

    // cache all the java types statically
    synchronized (javaTypeCache)
    {
      // if cached use that one
      String clsName =  JavaType.toClassName(podName, typeName);
      JavaType t = (JavaType)javaTypeCache.get(clsName);
      if (t != null) return t;

      // resolve class to create new JavaType for this class name
      try
      {
        Class cls = nameToClass(loadingPod, clsName);
        t = new JavaType(cls);
        javaTypeCache.put(clsName, t);
        return t;
      }
      catch (ClassNotFoundException e)
      {
        throw UnknownTypeErr.make("Load from [" + loadingPod + "] " + clsName, e);
      }
    }
  }

  /**
   * Return the absolute path to the JNI library for given pod.
   */
  public String jniLibPath(String podName)
  {
    String lib = workDir().osPath() + "/lib/java/ext/" + platform() + "/";
    String os  = os();

    if (os == "win32") lib += podName + ".dll";
    else if (os == "macosx") lib += "lib" + podName + ".jnilib";
    else lib += "lib" + podName + ".so";

    // TODO FIXIT: continue to load if library not found?
    if (!new java.io.File(lib).exists())
    {
      System.out.println("ERR: jni library not found: " + lib);
      return null;
    }

    return lib;
  }

  private Class nameToClass(Pod loadingPod, String name)
    throws ClassNotFoundException
  {
    // first try primitives because Class.forName doesn't work for them
    Class cls = (Class)primitiveClasses.get(name);
    if (cls != null) return cls;

    // array class like "[I" or "[Lfoo.Bar;"
    if (name.charAt(0) == '[')
    {
      // if not a array of class, then use Class.forName
      if (!name.endsWith(";")) return Class.forName(name);

      // resolve component class "[Lfoo.Bar;"
      String compName = name.substring(2, name.length()-1);
      Class comp = nameToClass(loadingPod, compName);
      return java.lang.reflect.Array.newInstance(comp, 0).getClass();
    }

    // if we have a pod class loader use it
    if (loadingPod != null) return loadingPod.classLoader.loadClass(name);

    // fallback to Class.forName
    return Class.forName(name);
  }

  // String -> Class
  private static final HashMap primitiveClasses = new HashMap();
  static
  {
    try
    {
      primitiveClasses.put("boolean", boolean.class);
      primitiveClasses.put("char",    char.class);
      primitiveClasses.put("byte",    byte.class);
      primitiveClasses.put("short",   short.class);
      primitiveClasses.put("int",     int.class);
      primitiveClasses.put("long",    long.class);
      primitiveClasses.put("float",   float.class);
      primitiveClasses.put("double",  double.class);
    }
    catch (Throwable e)
    {
      e.printStackTrace();
    }
  }

  // TODO: temp hack to get PathEnv.path
  public String[] toDebugPath()
  {
    Method m = typeof().method("path", false);
    if (m == null) return null;

    List list = (List)m.callOn(this, null);
    String[] result = new String[list.sz()];
    for (int i=0; i<list.sz(); ++i)
    {
      String s = ((File)list.get(i)).osPath();
      if (i == 0) s += " (work)";
      if (i == list.sz()-1) s += " (home)";
      result[i] = s;
    }
    return result;
  }

  /**
   * Called when one or more pods are add, removed, or reloaded
   */
  void onPodReload()
  {
    index.reload();
    props.reload();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final String noDef = "_Env_nodef_";
  static Uri configProps    = Uri.fromStr("config.props");
  static Uri localeEnProps  = Uri.fromStr("locale/en.props");

  private Env parent;
  private EnvScripts scripts = new EnvScripts();
  private EnvProps props = new EnvProps(this);
  private EnvIndex index = new EnvIndex(this);
  private HashMap javaTypeCache = new HashMap();  // String class name => JavaType
}