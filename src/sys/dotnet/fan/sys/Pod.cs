//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Sep 06  Andy Frank  Creation
//

using System;
using System.Collections;
using System.IO;
using DirectoryInfo = System.IO.DirectoryInfo;
using FileInfo = System.IO.FileInfo;
using Fanx.Emit;
using Fanx.Fcode;
using Fanx.Util;
using ICSharpCode.SharpZipLib.Zip;

namespace Fan.Sys
{
  /// <summary>
  /// Pod is a module containing Types.  A Pod is always backed by a FPod
  /// instance which defines all the definition tables.  Usually the FPod
  /// is in turn backed by a FStore for the pod's zip file.  However in the
  /// case of memory-only pods defined by the compiler, the fpod.store field
  /// will be null.
  ///
  /// Pods is loaded as soon as it is constructed:
  ///  1) All the types defined by the fpod are mapped into hollow Types.
  ///  2) It is emitted as a Java class called "fan.{podName}.$Pod".  The
  ///     emitted class is basically a manifestation of the literal tables,
  ///     after which we can clear the fpod data structures.
  /// </summary>
  public class Pod : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Management
  //////////////////////////////////////////////////////////////////////////

    public static Pod of(object obj)
    {
      return Type.of(obj).pod();
    }

    public static Pod find(string name) { return doFind(name, true, null); }
    public static Pod find(string name, bool check) { return doFind(name, check, null); }
    public static Pod doFind(string name, bool check, FPod fpod)
    {
      try
      {
        lock (m_podsByName)
        {
          // TODO - .NET does not have soft references, so how could
          // we implement this?  See the Pod.java for the java impl.

          Pod pod = (Pod)m_podsByName[name];
          if (pod == null)
          {
            // if fpod is non-null, then we are "creating" this pod in
            // memory direct from the compiler, otherwise we need to
            // find the pod zip file and load it's meta-data
            if (fpod == null) fpod = readFPod(name);

            // sanity check
            if (fpod.m_podName != name)
              throw new Exception("Mismatched pod name b/w pod.def and pod zip filename: " + fpod.m_podName + " != " + name);

            // create the pod and register it
            pod = new Pod(fpod);
            m_podsByName[name] = pod;
          }
          return pod;
        }
      }
      catch (UnknownPodErr.Val e)
      {
        if (!check) return null;
        throw e;
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
        if (!check) return null;
        throw UnknownPodErr.make(name, e).val;
      }
    }

    public static Pod load(InStream @in)
    {
      FPod fpod = null;
      try
      {
        fpod = new FPod(null, null);
        fpod.readFully(new ZipInputStream(SysInStream.dotnet(@in)));
      }
      catch (Exception e)
      {
        throw Err.make(e).val;
      }

      string name = fpod.m_podName;
      lock (m_podsByName)
      {
        // check for duplicate pod name
        if (m_podsByName[name] != null)
          throw Err.make("Duplicate pod name: " + name).val;

        // create Pod and add to master table
        Pod pod = new Pod(fpod);
        m_podsByName[name] = pod; //new SoftReference(pod);
        return pod;
      }
    }

    public static FPod readFPod(string name)
    {
      FStore store = null;

      // handle sys specially for bootstrapping the VM
      if (name == "sys")
      {
        store = new FStore(new ZipFile(FileUtil.combine(Sys.m_podsDir, name + ".pod")));
      }

      // otherwise delegate to Env.cur to find the pod file
      else
      {
        FileSystemInfo file = null;
        Fan.Sys.File f = Env.cur().findPodFile(name);
        if (f != null) file = ((LocalFile)f).m_file;

        // if null or doesn't exist then its a no go
        if (file == null || !file.Exists) throw UnknownPodErr.make(name).val;

        // verify case since Windoze is case insensitive
        String actualName = file.Name; //getCanonicalFile().getName();
        actualName = actualName.Substring(0, actualName.Length-4);
        if (actualName != name) throw UnknownPodErr.make("Mismatch case: " + name + " != " + actualName).val;

        store = new FStore(new ZipFile(file.FullName));
      }

      // read in the FPod tables
      FPod fpod = new FPod(name, store);
      fpod.read();
      return fpod;
    }

    public static List list()
    {
      lock (m_podsByName)
      {
        // TODO - eventually we need a faster way to load
        //  pod meta-data into memory without actually loading
        //  every pod into memory
        if (m_allPodsList == null)
        {
          List names = Env.cur().findAllPodNames();
          List pods = new List(Sys.PodType);
          for (int i=0; i<names.sz(); ++i)
          {
            string name = (string)names.get(i);
            try
            {
              pods.add(doFind(name, true, null));
            }
            catch (Exception e)
            {
              System.Console.WriteLine("ERROR: Invalid pod file: " + name);
              Err.dumpStack(e);
            }
          }
          m_allPodsList = pods.ro();
        }
        return m_allPodsList;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    internal Pod(FPod fpod)
    {
      this.m_name = fpod.m_podName;
      load(fpod);
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.PodType; }

    public string name()  { return m_name; }

    public Version version()
    {
      if (m_version == null)
        m_version = Version.fromStr(fpod.m_podVersion);
      return m_version;
    }

    public List depends()
    {
      if (m_depends == null)
        m_depends = (List)new List(Sys.DependType, fpod.m_depends).toImmutable();
      return m_depends;
    }

    public Uri uri()
    {
      if (m_uri == null) m_uri = Uri.fromStr("fan://" + m_name);
      return m_uri;
    }

    public override string toStr() { return m_name; }

    public Map meta()
    {
      if (m_meta == null)
      {
        try
        {
          if (fpod.m_meta != null) m_meta = (Map)fpod.m_meta;
          else
          {
            InStream input = new SysInStream(fpod.m_store.read("meta.props"));
            m_meta = (Map)input.readProps().toImmutable();
            input.close();
          }
        }
        catch (Exception e)
        {
          Err.dumpStack(e);
          m_meta = Sys.m_emptyStrStrMap;
        }
      }
      return m_meta;
    }

  //////////////////////////////////////////////////////////////////////////
  // Types
  //////////////////////////////////////////////////////////////////////////

    public List types() { return new List(Sys.TypeType, m_types); }

    public Type type(string name) { return type(name, true); }
    public Type type(string name, bool check)
    {
      Type type = (Type)typesByName[name];
      if (type != null) return type;
      if (check) throw UnknownTypeErr.make(this.m_name + "::" + name).val;
      return null;
    }

//////////////////////////////////////////////////////////////////////////
// Documentation
//////////////////////////////////////////////////////////////////////////

  public string doc()
  {
    if (!m_docLoaded)
    {
      try
      {
        Stream input = fpod.m_store.read("doc/pod.fandoc");
        if (input != null) m_doc = SysInStream.make(input, Long.valueOf(1024L)).readAllStr();
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
      }
      m_docLoaded = true;
    }
    return m_doc;
  }

  //////////////////////////////////////////////////////////////////////////
  // Files
  //////////////////////////////////////////////////////////////////////////

    public List files()
    {
      loadFiles();
      return m_filesList;
    }

    public Fan.Sys.File file(Uri uri) { return file(uri, true); }
    public Fan.Sys.File file(Uri uri, bool check)
    {
      loadFiles();
      if (!uri.isPathAbs())
        throw ArgErr.make("Pod.files Uri must be path abs: " + uri).val;
      if (uri.auth() != null && !uri.toStr().StartsWith(this.uri().toStr()))
        throw ArgErr.make("Invalid base uri `" + uri + "` for `" + this.uri() + "`").val;
      else
        uri = this.uri().plus(uri);
      Fan.Sys.File f = (Fan.Sys.File)m_filesMap[uri];
      if (f != null || !check) return f;
      throw UnresolvedErr.make(uri.toStr()).val;
    }

    private void loadFiles()
    {
      lock (m_filesMap)
      {
        if (m_filesList != null) return;
        this.m_filesList = (List)fpod.m_store.podFiles(uri()).toImmutable();
        for (int i=0; i<m_filesList.sz(); ++i)
        {
          Fan.Sys.File f = (Fan.Sys.File)m_filesList.get(i);
          m_filesMap[f.uri()] = f;
        }
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public Log log()
    {
      if (m_log == null) m_log = Log.get(m_name);
      return m_log;
    }

    public Map props(Uri uri, Duration maxAge)
    {
      return Env.cur().props(this, uri, maxAge);
    }

    public string config(string key)
    {
      return Env.cur().config(this, key);
    }

    public string config(string key, string def)
    {
      return Env.cur().config(this, key, def);
    }

    public string locale(string key)
    {
      return Env.cur().locale(this, key);
    }

    public string locale(string key, string def)
    {
      return Env.cur().locale(this, key, def);
    }

  //////////////////////////////////////////////////////////////////////////
  // Load
  //////////////////////////////////////////////////////////////////////////

    internal void load(FPod fpod)
    {
      this.fpod = fpod;
      this.typesByName = new Hashtable();

      // create a hollow Type for each FType (this requires two steps,
      // because we don't necessary have all the Types created for
      // superclasses until this loop completes)
      m_types = new ClassType[fpod.m_types.Length];
      for (int i=0; i<fpod.m_types.Length; i++)
      {
        // create type instance
        ClassType type = new ClassType(this, fpod.m_types[i]);

        // add to my data structures
        m_types[i] = type;
        if (typesByName[type.m_name] != null)
          throw Err.make("Invalid pod: " + m_name + " type already defined: " + type.m_name).val;
        typesByName[type.m_name] = type;
      }

      // get TypeType to use for mixin List (we need to handle case
      // when loading sys itself - and lookup within my own pod)
      Type typeType = Sys.TypeType;
      if (typeType == null)
        typeType = (Type)typesByName["Type"];

      // now that everthing is mapped, we can fill in the super
      // class fields (unless something is wacked, this will only
      // use Types in my pod or in pods already loaded)
      for (int i=0; i<fpod.m_types.Length; i++)
      {
        FType ftype = fpod.m_types[i];
        ClassType type = m_types[i];
        type.m_base = findType(ftype.m_base);

        List mixins = new List(typeType, ftype.m_mixins.Length);
        for (int j=0; j<ftype.m_mixins.Length; j++)
          mixins.add(findType(ftype.m_mixins[j]));
        type.m_mixins = mixins.ro();
      }
    }

    /*
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
    */

    internal Type findType(int qname)
    {
      if (qname == 0xFFFF || qname == -1) return null;

      // lookup type with typeRef index
      FTypeRef reference = fpod.typeRef(qname);

      // if generic instance, then this type must be used in a method
      // signature, not type meta-data (b/c I can't subclass generic types),
      // so it's safe that my pod has been loaded and is now registered (in
      // case the generic type is parameterized via types in my pod)
      if (reference.isGenericInstance())
        return TypeParser.load(reference.signature, true, this);

      // otherwise I need to handle if I am loading my own pod, because
      // I might not yet be added to the system namespace if I'm just
      // loading my own hollow types
      string podName  = reference.podName;
      string typeName = reference.typeName;
      Pod pod = podName == m_name ? this : doFind(podName, true, null);
      Type type = pod.type(typeName, false);
      if (type != null)
      {
        if (reference.isNullable()) type = type.toNullable();
        return type;
      }

       // handle generic parameter types (for sys pod only)
       if (m_name == "sys")
       {
         type = Sys.genericParamType(typeName);
        if (type != null)
        {
          if (reference.isNullable()) type = type.toNullable();
          return type;
        }
      }

      // lost cause
      throw UnknownTypeErr.make(podName + "::" + typeName).val;
    }

    /// <summary>
    /// Close the pod which should release any locks on the pod
    /// file.  This method exists only for testing, and should
    /// not otherwise be used.
    /// </summary>
    public void close()
    {
      fpod.m_store.close();
    }

  //////////////////////////////////////////////////////////////////////////
  // Compiler Support
  //////////////////////////////////////////////////////////////////////////

//TODO
/*
    // stub is used when sys.pod is not found, so that we can stub
    // enough to do self tests and compile sys itself
    internal Type stub(Type type)
    {
      if (typesByName == null) typesByName = new Hashtable();
      typesByName[type.name()] = type;
      return type;
    }
*/

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static Hashtable m_podsByName = new Hashtable();
    internal static List m_allPodsList = null;

    internal readonly string m_name;
    internal Uri m_uri;
    internal FPod fpod;
    internal Version m_version;
    internal List m_depends;
    internal ClassType[] m_types;
    internal Hashtable typesByName;
    internal List m_filesList;
    internal Hashtable m_filesMap = new Hashtable(11);
    internal Map m_meta;
    internal Hashtable locales = new Hashtable(4);
    internal Log m_log;
    internal bool m_docLoaded;
    public string m_doc;
  }
}