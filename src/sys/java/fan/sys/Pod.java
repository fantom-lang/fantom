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
          if (resolving != null && resolving.containsKey(name))
            throw new Exception("Cyclic dependency on '" + name + "'");

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
          if (resolving == null) resolving = new HashMap();
          resolving.put(name, name);
          for (int i=0; i<fpod.depends.length; ++i)
          {
            Depend d = fpod.depends[i];
            Pod dpod = doFind(d.name(), false, null, resolving);
            if (dpod == null)
              throw new Exception("Missing dependency for '" + name + "': " + d);
            if (!d.match(dpod.version()))
              throw new Exception("Missing dependency for '" + name + "': " + dpod.name() + " " + dpod.version() + " != " + d);
          }

          // create the pod and register it
          ref = new SoftReference(new Pod(fpod));
          podsByName.put(name, ref);
        }
        return (Pod)ref.get();
      }
    }
    catch (UnknownPodErr.Val e)
    {
      if (!checked) return null;
      throw e;
    }
    catch (Exception e)
    {
      e.printStackTrace();
      if (!checked) return null;
      throw UnknownPodErr.make(name, e).val;
    }
  }

  public static Pod load(InStream in)
  {
    FPod fpod = null;
    try
    {
      fpod = new FPod(null, null, null);
      fpod.readFully(new ZipInputStream(SysInStream.java(in)));
    }
    catch (Exception e)
    {
      throw Err.make(e).val;
    }

    String name = fpod.podName;
    synchronized(podsByName)
    {
      // check for duplicate pod name
      SoftReference ref = (SoftReference)podsByName.get(name);
      if (ref != null && ref.get() != null)
        throw Err.make("Duplicate pod name: " + name).val;

      // create Pod and add to master table
      Pod pod = new Pod(fpod);
      podsByName.put(name, new SoftReference(pod));
      return pod;
    }
  }

  public static FPod readFPod(String name)
    throws Exception
  {
    // handle sys specially for bootstrapping the VM
    // otherwise delegate to repo
    File file = null;
    Object repo = null;
    if (name.equals("sys"))
    {
      file = new File(Sys.podsDir, name + ".pod");
      repo = null; // can't load this class yet
    }
    else
    {
      Repo.PodFile r = Repo.findPod(name);
      if (r != null) { file = r.file; repo = r.repo; }
    }

    // if null or doesn't exist then its a no go
    if (file == null || !file.exists()) throw UnknownPodErr.make(name).val;

    // verify case since Windoze is case insensitive
    String actualName = file.getCanonicalFile().getName();
    actualName = actualName.substring(0, actualName.length()-4);
    if (!actualName.equals(name)) throw UnknownPodErr.make("Mismatch case: " + name + " != " + actualName).val;

    // read in the FPod tables
    FPod fpod = new FPod(name, new java.util.zip.ZipFile(file), repo);
    fpod.read();
    return fpod;
  }

  public static List list()
  {
    synchronized(podsByName)
    {
      // TODO - eventually we need a faster way to load
      //  pod meta-data into memory without actually loading
      //  every pod into memory
      if (allPodsList == null)
      {
        HashMap map = Repo.findAllPods();
        List pods = new List(Sys.PodType, map.size());
        Iterator it = map.keySet().iterator();
        while (it.hasNext())
        {
          String name = (String)it.next();
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
        allPodsList = pods.sort().ro();
      }
      return allPodsList;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  Pod(FPod fpod)
  {
    this.name = fpod.podName;
    this.repo = fpod.repo;
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
      depends = new List(Sys.DependType, fpod.depends).ro();
    return depends;
  }

  public final Uri uri()
  {
    if (uri == null) uri = Uri.fromStr("fan:/sys/pod/" + name + "/");
    return uri;
  }

  public final String toStr() { return name; }

//////////////////////////////////////////////////////////////////////////
// Repo
//////////////////////////////////////////////////////////////////////////

  public Repo repo()
  {
    if (repo == null && name.equals("sys")) repo = Repo.boot();
    return (Repo)repo;
  }

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  public Map facets() { return toFacets().map(); }
  public Object facet(Symbol key) { return toFacets().get(key, null); }
  public Object facet(Symbol key, Object def) { return toFacets().get(key, def); }

  private Facets toFacets()
  {
    if (facets == null) facets = fpod.attrs.facets();
    return facets;
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
    if (checked) throw UnknownTypeErr.make(this.name + "::" + name).val;
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Symbols
//////////////////////////////////////////////////////////////////////////

  public List symbols()
  {
    return new List(Sys.SymbolType, loadSymbols().values());
  }

  public Symbol symbol(String name) { return symbol(name, true); }
  public Symbol symbol(String name, boolean checked)
  {
    Symbol s = (Symbol)loadSymbols().get(name);
    if (s != null) return s;
    if (checked) throw UnknownSymbolErr.make(this.name + "::" + name).val;
    return null;
  }

  private HashMap loadSymbols()
  {
    synchronized (symbolsLock)
    {
      if (symbols != null) return symbols;
      symbols = new HashMap();

      // read symbols from fcode format
      try
      {
        fpod.readSymbols();
        if (fpod.symbols == null) return symbols;
      }
      catch (java.io.IOException e)
      {
        throw IOErr.make("Error loading symbols.def", e).val;
      }

      // map to sys::Symbol instances
      for (int i=0; i<fpod.symbols.length; ++i)
      {
        Symbol symbol = new Symbol(this, fpod.symbols[i]);
        symbols.put(symbol.name, symbol);
      }

      // clear list from fpod, no longer needed
      fpod.symbols = null;
      return symbols;
    }
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
        java.io.InputStream in = fpod.store.read("doc/pod.apidoc");
        if (in != null) { try { FDoc.read(in, this); } finally { in.close(); } }
      }
      catch (Exception e) { e.printStackTrace(); }
      docLoaded = true;
    }
    return doc;
  }

//////////////////////////////////////////////////////////////////////////
// Files
//////////////////////////////////////////////////////////////////////////

  public final Map files()
  {
    if (files == null)
      files = fpod.store.podFiles();
    return files;
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public final Log log()
  {
    if (log == null) log = Log.get(name);
    return log;
  }

  public final String config(String key)
  {
    return Env.cur().config(name, key);
  }

  public final String config(String key, String def)
  {
    return Env.cur().config(name, key, def);
  }

  public final String locale(String key)
  {
    return Env.cur().locale(name, key);
  }

  public final String locale(String key, String def)
  {
    return Env.cur().locale(name, key, def);
  }

// TODO
  public final String loc(String key)
  {
    return Locale.cur().doGet(this, name, key, Locale.getNoDef);
  }

// TODO
  public final String loc(String key, String def)
  {
    return Locale.cur().doGet(this, name, key, def);
  }

  public final Map props(Uri uri) { return props(uri.toStr()); }
  public final Map props(String uri)
  {
    Map map = null;
    synchronized(props) { map = (Map)props.get(uri); }
    if (map != null) return map;

    fan.sys.File f = (fan.sys.File)files().get(Uri.fromStr(uri));
    map = EnvProps.empty;
    try
    {
      if (f != null) map = (Map)f.readProps().toImmutable();
    }
    catch (Exception e)
    {
      System.out.println("ERROR: Cannot load props " + name + "::" + uri);
      System.out.println("  " + e);
    }

    synchronized(props) { props.put(uri, map); }
    return map;
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
        throw Err.make("Invalid pod: " + name + " type already defined: " + type.name).val;
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

      List mixins = new List(typeType, ftype.mixins.length);
      for (int j=0; j<ftype.mixins.length; ++j)
        mixins.add(type(ftype.mixins[j]));
      type.mixins = mixins.ro();
    }
  }

  synchronized Class emit()
  {
    if (cls == null)
      cls = FPodEmit.emitAndLoad(fpod);
    return cls;
  }

  synchronized void precompiled(Class cls)
    throws Exception
  {
    this.cls = cls;
    FPodEmit.initFields(fpod, cls);
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
      return JavaType.make(podName, typeName);

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
    throw UnknownTypeErr.make(podName + "::" + typeName).val;
  }

  /*
  void shutdown()
  {
    try
    {
      if (fpod != null && fpod.store != null)
        fpod.store.close();
    }
    catch (Exception e)
    {
    }
  }
  */

  /*
  public static void dumpMem()
  {
    int numPods  = 0;
    int numFreed = 0;
    int numTypes = 0;
    Iterator it = podsByName.values().iterator();
    while (it.hasNext())
    {
      SoftReference ref = (SoftReference)it.next();
      if (ref.get() != null)
      {
        numPods++;
        numTypes += ((Pod)ref.get()).types.length;
      }
      else
      {
        numFreed++;
      }
    }
    long mem = Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory();
    System.out.println(">>> Pods=" + numPods + "  Freed=" + numFreed + "  Types=" + numTypes + " Mem=" + mem/(1024L*1024L) + "MB");
  }
  */

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static HashMap podsByName = new HashMap();
  static List allPodsList = null;

  final String name;
  Uri uri;
  FPod fpod;
  Version version;
  List depends;
  Facets facets;
  ClassType[] types;
  HashMap typesByName;
  Class cls;
  Map files;
  HashMap props = new HashMap(4);
// TODO
HashMap locales = new HashMap(4);
  Log log;
  Object symbolsLock = new Object();
  HashMap symbols;
  boolean docLoaded;
  Uri fansymUri;
  public String doc;
  Object repo;


}