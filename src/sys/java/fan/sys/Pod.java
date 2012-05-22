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
import java.util.HashMap;
import java.util.Iterator;
import java.util.zip.*;
import fanx.fcode.*;
import fanx.emit.*;
import fanx.util.*;

/**
 * Pod is a module containing Types.  A Pod is always backed by a FPod
 * instance which defines all the definition tables.  Usually the FPod
 * is in turn backed by a FStore for the pod's zip file.  However in the
 * case of memory-only pods defined by the compiler, the fpod.store field
 * will be null.
 *
 * Pods is loaded as soon as it is constructed:
 *  1) All the types defined by the fpod are mapped into hollow Types.
 *  2) It is emitted as a Java class called "fan.{podName}.$Pod".  The
 *     emitted class is basically a manifestation of the literal tables,
 *     after which we can clear the fpod data structures.
 */
public class Pod
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

  public static Pod of(Object obj)
  {
    return Type.of(obj).pod();
  }

  public static Pod find(String name) { return doFind(name, true, null, null); }
  public static Pod find(String name, boolean checked) { return doFind(name, checked, null, null); }
  public static Pod doFind(String name, boolean checked, FPod fpod, HashMap resolving)
  {
    try
    {
      synchronized(podsByName)
      {
        SoftReference ref = (SoftReference)podsByName.get(name);
        if (ref == null || ref.get() == null)
        {
          // if resolving is non-null, check that our pod name it
          // isn't in the resolving map, because then we have a cyclic
          // dependency which is bad, bad, bad
          if (resolving == null) resolving = new HashMap();
          if (resolving != null && resolving.containsKey(name))
            throw new Exception("Cyclic dependency on '" + name + "'");
          resolving.put(name, name);

          // if fpod is non-null, then we are "creating" this pod in
          // memory direct from the compiler, otherwise we need to
          // find the pod zip file and load it's meta-data
          if (fpod == null) fpod = readFPod(name);

          // sanity check
          if (!fpod.podName.equals(name))
            throw new Exception("Mismatched pod name b/w pod.def and pod zip filename: " + fpod.podName + " != " + name);

          // dependency check, keep track of what we are loading
          // via depends checking to prevent a cyclic dependency
          // from putting us into an infinite loop
          Pod[] dependPods = new Pod[fpod.depends.length];
          for (int i=0; i<fpod.depends.length; ++i)
          {
            Depend d = fpod.depends[i];
            Pod dpod = doFind(d.name(), false, null, resolving);
            if (dpod == null)
              throw new Exception("Missing dependency for '" + name + "': " + d);
            if (!d.match(dpod.version()))
              throw new Exception("Missing dependency for '" + name + "': " + dpod.name() + " " + dpod.version() + " != " + d);
            dependPods[i] = dpod;
          }

          // create the pod and register it
          ref = new SoftReference(new Pod(fpod, dependPods));
          podsByName.put(name, ref);
        }
        return (Pod)ref.get();
      }
    }
    catch (UnknownPodErr e)
    {
      if (!checked) return null;
      throw e;
    }
    catch (Exception e)
    {
      e.printStackTrace();
      if (!checked) return null;
      throw UnknownPodErr.make(name, Err.make(e));
    }
  }

  public static Pod load(InStream in)
  {
    FPod fpod = null;
    try
    {
      fpod = new FPod(null, null);
      fpod.readFully(new ZipInputStream(SysInStream.java(in)));
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }

    String name = fpod.podName;
    synchronized(podsByName)
    {
      // check for duplicate pod name
      SoftReference ref = (SoftReference)podsByName.get(name);
      if (ref != null && ref.get() != null)
        throw Err.make("Duplicate pod name: " + name);

      // create Pod and add to master table
      Pod pod = new Pod(fpod, new Pod[]{});
      podsByName.put(name, new SoftReference(pod));
      return pod;
    }
  }

  public static FPod readFPod(String name)
    throws Exception
  {
    FStore store = null;

    // otherwise if we are running with JarDistEnv use my own classloader
    if (Sys.isJarDist)
    {
      store = FStore.makeJarDist(Pod.class.getClassLoader(), name);
    }

    // handle sys specially for bootstrapping the VM
    else if (name.equals("sys"))
    {
      store = FStore.makeZip(new File(Sys.podsDir, name + ".pod"));
    }

    // otherwise delete to Env.cur to find the pod file
    else
    {
      File file = null;
      fan.sys.File f = Env.cur().findPodFile(name);
      if (f != null) file = ((LocalFile)f).file;

      // if null or doesn't exist then its a no go
      if (file == null || !file.exists()) throw UnknownPodErr.make(name);

      // verify case since Windoze is case insensitive
      String actualName = file.getCanonicalFile().getName();
      actualName = actualName.substring(0, actualName.length()-4);
      if (!actualName.equals(name)) throw UnknownPodErr.make("Mismatch case: " + name + " != " + actualName);

      store = FStore.makeZip(file);
    }

    // read in the FPod tables
    FPod fpod = new FPod(name, store);
    fpod.read();

    return fpod;
  }

  public static List list()
  {
    synchronized(podsByName)
    {
      //  eventually we need a faster way to load
      //  pod meta-data into memory without actually loading
      //  every pod into memory
      if (allPodsList == null)
      {
        List names = Env.cur().findAllPodNames();
        List pods = new List(Sys.PodType, names.sz());
        for (int i=0; i<names.sz(); ++i)
        {
          String name = (String)names.get(i);
          try
          {
            pods.add(doFind(name, true, null, null));
          }
          catch (Throwable e)
          {
            System.out.println("ERROR: Invalid pod file: " + name);
            e.printStackTrace();
          }
        }
        allPodsList = (List)pods.sort().toImmutable();
      }
      return allPodsList;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  Pod(FPod fpod, Pod[] dependPods)
  {
    this.name = fpod.podName;
    this.classLoader = new FanClassLoader(this);
    this.dependPods = dependPods;
    load(fpod);
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.PodType; }

  public final String name()  { return name; }

  public final Version version()
  {
    if (version == null)
      version = Version.fromStr(fpod.podVersion);
    return version;
  }

  public final List depends()
  {
    if (depends == null)
      depends = (List)new List(Sys.DependType, fpod.depends).toImmutable();
    return depends;
  }

  public final Uri uri()
  {
    if (uri == null) uri = Uri.fromStr("fan://" + name);
    return uri;
  }

  public final String toStr() { return name; }

  public final Map meta()
  {
    if (meta == null)
    {
      try
      {
        if (fpod.meta != null) meta = (Map)fpod.meta;
        else
        {
          InStream in = new SysInStream(fpod.store.read("meta.props"));
          meta = (Map)in.readProps().toImmutable();
          in.close();
        }
      }
      catch (Exception e)
      {
        e.printStackTrace();
        meta = Sys.emptyStrStrMap;
      }
    }
    return meta;
  }

//////////////////////////////////////////////////////////////////////////
// Types
//////////////////////////////////////////////////////////////////////////

  public List types() { return new List(Sys.TypeType, types); }

  public Type type(String name) { return type(name, true); }
  public Type type(String name, boolean checked)
  {
    Type type = (Type)typesByName.get(name);
    if (type != null) return type;
    if (checked) throw UnknownTypeErr.make(this.name + "::" + name);
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Documentation
//////////////////////////////////////////////////////////////////////////

  public String doc()
  {
    if (!docLoaded)
    {
      try
      {
        java.io.InputStream in = fpod.store.read("doc/pod.fandoc");
        if (in != null) doc = SysInStream.make(in, Long.valueOf(1024L)).readAllStr();
      }
      catch (Exception e) { e.printStackTrace(); }
      docLoaded = true;
    }
    return doc;
  }

//////////////////////////////////////////////////////////////////////////
// Files
//////////////////////////////////////////////////////////////////////////

  public final List files()
  {
    loadFiles();
    return filesList;
  }

  public final fan.sys.File file(Uri uri) { return file(uri, true); }
  public final fan.sys.File file(Uri uri, boolean checked)
  {
    loadFiles();
    if (!uri.isPathAbs())
      throw ArgErr.make("Pod.files Uri must be path abs: " + uri);
    if (uri.auth() != null && !uri.toStr().startsWith(uri().toStr()))
      throw ArgErr.make("Invalid base uri `" + uri + "` for `" + uri() + "`");
    else
      uri = this.uri().plus(uri);
    fan.sys.File f = (fan.sys.File)filesMap.get(uri);
    if (f != null || !checked) return f;
    throw UnresolvedErr.make(uri.toStr());
  }

  private void loadFiles()
  {
    synchronized (filesMap)
    {
      if (filesList != null) return;
      if (fpod.store == null) throw Err.make("Not backed by pod file: " + name);
      List list;
      try
      {
        this.filesList = (List)fpod.store.podFiles(uri()).toImmutable();
      }
      catch (java.io.IOException e)
      {
        e.printStackTrace();
        throw Err.make(e);
      }
      for (int i=0; i<filesList.sz(); ++i)
      {
        fan.sys.File f = (fan.sys.File)filesList.get(i);
        filesMap.put(f.uri(), f);
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public final Log log()
  {
    if (log == null) log = Log.get(name);
    return log;
  }

  public final Map props(Uri uri, Duration maxAge)
  {
    return Env.cur().props(this, uri, maxAge);
  }

  public final String config(String key)
  {
    return Env.cur().config(this, key);
  }

  public final String config(String key, String def)
  {
    return Env.cur().config(this, key, def);
  }

  public final String locale(String key)
  {
    return Env.cur().locale(this, key);
  }

  public final String locale(String key, String def)
  {
    return Env.cur().locale(this, key, def);
  }

//////////////////////////////////////////////////////////////////////////
// Load
//////////////////////////////////////////////////////////////////////////

  void load(FPod fpod)
  {
    this.fpod = fpod;
    this.typesByName = new HashMap();

    // create a hollow Type for each FType (this requires two steps,
    // because we don't necessary have all the Types created for
    // superclasses until this loop completes)
    types = new ClassType[fpod.types.length];
    for (int i=0; i<fpod.types.length; ++i)
    {
      // create type instance
      ClassType type = new ClassType(this, fpod.types[i]);

      // add to my data structures
      types[i] = type;
      if (typesByName.put(type.name, type) != null)
        throw Err.make("Invalid pod: " + name + " type already defined: " + type.name);
    }

    // get TypeType to use for mixin List (we need to handle case
    // when loading sys itself - and lookup within my own pod)
    Type typeType = Sys.TypeType;
    if (typeType == null)
      typeType = (Type)typesByName.get("Type");

    // now that everthing is mapped, we can fill in the super
    // class fields (unless something is wacked, this will only
    // use Types in my pod or in pods already loaded)
    for (int i=0; i<fpod.types.length; ++i)
    {
      FType ftype = fpod.types[i];
      ClassType type = types[i];
      type.base = type(ftype.base);

      Object[] mixins = new Object[ftype.mixins.length];
      for (int j=0; j<mixins.length; ++j)
        mixins[j] = type(ftype.mixins[j]);
      type.mixins = new List(typeType, mixins).ro();
    }
  }

  synchronized Class emit()
  {
    if (cls == null)
    {
      try
      {
        cls = Env.cur().loadPodClass(this);
        FPodEmit.initFields(this, fpod, cls);
      }
      catch (Exception e)
      {
        e.printStackTrace();
        throw new RuntimeException(e.toString());
      }
    }
    return cls;
  }

  synchronized void precompiled(Class cls)
    throws Exception
  {
    this.cls = cls;
    FPodEmit.initFields(this, fpod, cls);
  }

  Type type(int qname)
  {
    if (qname == 0xFFFF || qname == -1) return null;

    // lookup type with typeRef index
    FTypeRef ref = fpod.typeRef(qname);

    // if generic instance, then this type must be used in a method
    // signature, not type meta-data (b/c I can't subclass generic types),
    // so it's safe that my pod has been loaded and is now registered (in
    // case the generic type is parameterized via types in my pod)
    if (ref.isGenericInstance())
      return TypeParser.load(ref.signature, true, this);

    // if the pod name starts with "[java]" this is a direct FFI java type
    String podName  = ref.podName;
    String typeName = ref.typeName;
    if (podName.startsWith("[java]"))
    {
      Type t = Env.cur().loadJavaType(this, podName, typeName);
      if (ref.isNullable()) t = t.toNullable();
      return t;
    }

    // otherwise I need to handle if I am loading my own pod, because
    // I might not yet be added to the system namespace if I'm just
    // loading my own hollow types
    Pod pod = podName.equals(name) ? this : Pod.doFind(podName, true, null, null);
    Type type = pod.type(typeName, false);
    if (type != null)
    {
      if (ref.isNullable()) type = type.toNullable();
      return type;
    }

    // handle generic parameter types (for sys pod only)
    if (this.name.equals("sys"))
    {
      type = Sys.genericParamType(typeName);
      if (type != null)
      {
        if (ref.isNullable()) type = type.toNullable();
        return type;
      }
    }

    // lost cause
    throw UnknownTypeErr.make(podName + "::" + typeName);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static HashMap podsByName = new HashMap();
  static List allPodsList = null;

  final String name;
  final FanClassLoader classLoader;
  final Pod[] dependPods;
  Uri uri;
  FPod fpod;
  Version version;
  Map meta;
  List depends;
  ClassType[] types;
  HashMap typesByName;
  Class cls;
  List filesList;
  HashMap filesMap = new HashMap(11);
  Log log;
  boolean docLoaded;
  public String doc;

}