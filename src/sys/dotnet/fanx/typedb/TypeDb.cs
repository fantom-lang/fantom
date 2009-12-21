//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Dec 07  Andy Frank  Creation
//

using System.Collections;
using System.IO;
using System.Runtime.CompilerServices;
using Fan.Sys;
using Fanx.Serial;
using Fanx.Util;

namespace Fanx.Typedb
{
  /// <summary>
  /// TypeDb is responsible for managing the indexes
  /// on the the installed pods and types.
  /// </summary>
  public class TypeDb
  {

  //////////////////////////////////////////////////////////////////////////
  // Get
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Get the type database.  The database is lazily
    /// loaded (and maybe rebuilt) on the first access.
    /// </summary>
    public static TypeDb get()
    {
      lock (lockObj)
      {
        if (instance == null)
          instance = load();
        return instance;
      }
    }

    private static TypeDb load()
    {
      try
      {
        TypeDb db;

        // if type database exists
        if (dbFile.Exists)
        {
          db = new TypeDb();
          try
          {
            // open and check up-to-date
            if (db.open(true)) return db;
          }
          catch (System.Exception e)
          {
            log.err("Cannot load type database", e);
          }

          // close it so we can rebuild
          db.close();
          db = null;
        }

        // rebuild the database
        new Builder().build();

        // now re-open the database (no check needed)
        db = new TypeDb();
        db.open(false);
        return db;
      }
      catch (System.Exception e)
      {
        log.err("Cannot load type database", e);
        throw Err.make("Cannot load type database", e).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // API
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Implementation of 'Type.findByFacet'
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    public List findByFacet(string name, object val, object options)
    {
      // process options
      if (options == Boolean.True && val is Type)
        return findByFacetInheritance(name, (Type)val);

      // no options
      return doFindByFacet(name, val);
    }

    /// <summary>
    /// Implementation when val is Type and options == true.
    /// Return a query against the val's full inheritance hierarchy.
    /// </summary>
    private List findByFacetInheritance(string name, Type val)
    {
      List inheritance = val.inheritance();
      List acc = new List(Sys.TypeType);
      for (int i=0; i<inheritance.sz(); ++i)
        acc.addAll(doFindByFacet(name, inheritance.get(i)));
      return acc.ro();
    }

    /// <summary>
    /// Find all the types declared by the specified facet name/value pair.
    /// </summary>
    private List doFindByFacet(string name, object val)
    {
      try
      {
        // lookup the FacetIndex for that name
        FacetIndex index = readFacetIndex(name);

        // check if we have any types mapped for value
        object result = index.valueToTypes[val];
        if (result == null) return noTypes;

        // if we've already done a lookup on this value,
        // then the result will already be a List of Types
        if (result is List) return (List)result;

        // otherwise this is the first lookup, so we
        // have to map type ids to a List of Types
        Type[] types = resolve((int[])result);
        List list = new List(Sys.TypeType, types).ro();
        index.valueToTypes[val] = list;
        return list;
      }
      catch (IOException e)
      {
        throw IOErr.make(e).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Open/Close
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Open the type database.  If 'checkUpToDate' is true,
    /// then verify the pods list is up to date - if not then
    /// return close and false.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    bool open(bool checkUpToDate)
    {
      this.f = dbFile.OpenRead();
      this.r = new DataReader(f);

      // read header
      if (u4() != MAGIC) throw new IOException("Bad magic");
      if (u4() != VERSION) throw new IOException("Bad version");

      // read pods list
      readPods();

      // check pods if needed
      if (checkUpToDate)
      {
        if (!this.checkUpToDate())
        {
          close();
          return false;
        }
      }

      // finish reading facet indices
      readFacetIndices();
      return true;
    }

    private void readPods()
    {
      pods = new PodInfo[u2()];
      podsByName = new Hashtable(pods.Length*2);
      for (int i=0; i<pods.Length; ++i)
      {
        PodInfo p = pods[i] = new PodInfo();
        p.name     = utf();
        p.modified = u8();
        p.size     = u4();
        p.version  = Version.fromStr(utf());
        p.typesPos = u4();
        podsByName[p.name] = p;
      }
    }

    private void readFacetIndices()
    {
      int num = u2();
      facetIndices = new Hashtable(num*2);
      for (int i=0; i<num; ++i)
      {
        FacetIndex index = new FacetIndex();
        index.name = utf();
        index.pos  = u4();
        facetIndices[index.name] = index;
      }
    }

    bool checkUpToDate()
    {
      IDictionaryEnumerator en = Repo.findAllPods().GetEnumerator();
      while (en.MoveNext())
      {
        string n = (string)en.Key;
        FileInfo f = (FileInfo)en.Value;

        // check that pod wasn't added
        PodInfo p = (PodInfo)podsByName[n];
        if (p == null)
        {
          log.info("Out-of-date pod added: " + n);
          return false;
        }

        // check pod has not been modified
        if (p.modified != f.LastWriteTime.Ticks || p.size != (int)f.Length)
        {
          log.debug("Out-of-date pod modified: " + n);
          return false;
        }
        p.match = true;
      }

      // check that we matched all pods
      for (int i=0; i<pods.Length; ++i)
        if (!pods[i].match)
        {
          log.debug("Out-of-date pod removed: " + pods[i].name);
          return false;
        }

      // up to date!
      return true;
    }

    /// <summary>
    /// Close the database file.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    void close()
    {
      if (f != null)
      {
        try { f.Close(); } catch (IOException e) { Err.dumpStack(e); }
        f = null;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Types
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Ensure that the list of types for the specified
    /// pos has been lazy loaded.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    void readPodTypes(PodInfo p)
    {
      if (p.types != null) return;

      seek(p.typesPos);
      p.types = new TypeInfo[u2()];
      for (int i=0; i<p.types.Length; ++i)
      {
        TypeInfo t = p.types[i] = new TypeInfo();
        t.name = utf();
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Facet Indices
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Ensure that the facet index by the given name is loaded.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    FacetIndex readFacetIndex(string name)
    {
      // find index by name
      FacetIndex index = (FacetIndex)facetIndices[name];
      if (index == null)
        throw Err.make("Facet not indexed: " + name).val;

      // if already loaded
      if (index.valueToTypes != null) return index;

      // lazy load
      seek(index.pos);
      int num = u2();
      index.valueToTypes = new Hashtable(num*2);
      for (int i=0; i<num; ++i)
      {
        string val = utf();
        int[] types = new int[u2()];
        for (int j=0; j<types.Length; ++j) types[j] = u4();
        index.valueToTypes[ObjDecoder.decode(val)] = types;
      }

      return index;
    }

  //////////////////////////////////////////////////////////////////////////
  // Type Resolve
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Resolve an array of type identifiers to Type instances.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    Type[] resolve(int[] qids)
    {
      Type[] types = new Type[qids.Length];
      for (int i=0; i<qids.Length; ++i)
        types[i] = resolve(qids[i]);
      return types;
    }

    /// <summary>
    /// Resolve a type identifiers to a Type instances.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    Type resolve(int qids)
    {
      int podId  = (qids >> 16) & 0xffff;
      int typeId = qids & 0xffff;

      PodInfo pi = pods[podId];
      readPodTypes(pi);
      TypeInfo ti = pi.types[typeId];
      if (ti.type != null) return ti.type;

      if (pi.pod == null) pi.pod = Pod.find(pi.name, true);
      Type t = pi.pod.findType(ti.name, true);
      ti.type = t;
      ti.name = t.name();
      return t;
    }

  //////////////////////////////////////////////////////////////////////////
  // Helpers
  //////////////////////////////////////////////////////////////////////////

    int tell() { return (int)f.Position; }
    void seek(int pos) { f.Seek(pos, SeekOrigin.Begin); }

    int u1() { return r.ReadUnsignedByte(); }
    int u2() { return r.ReadUnsignedShort(); }
    int u4() { return r.ReadInt(); }
    long u8() { return r.ReadLong(); }
    string utf() { return r.ReadUTF(); }

  //////////////////////////////////////////////////////////////////////////
  // Type Database format
  //////////////////////////////////////////////////////////////////////////

    //
    //  Type Database Format:
    //
    //  typedb
    //  {
    //    u4     magic
    //    u4     version
    //    u2     numPods
    //    pod[]  podList
    //    u2     facetIndex count
    //    facetIndices[]
    //    {
    //      utf  facet name
    //      u4   facetIndex offset (LAZY LOAD)
    //    }
    //  }
    //
    //  pod
    //  {
    //    utf  name
    //    u8   pod file modified millis
    //    u4   pod file size
    //    utf  pod version
    //    u4   podTypes offset (LAZY LOAD)
    //  }
    //
    //  podTypes
    //  {
    //    u2  type count
    //    types[]
    //    {
    //      utf   simple type name
    //    }
    //  }
    //
    //  facetIndex
    //  {
    //    u2 count
    //    values[]
    //    {
    //      utf   serialized value
    //      u2    type count
    //      u4[]  type info offsets
    //    }
    //  }
    //
    //  podId  - index into podList
    //  typeId - index into podTypes
    //  qid    - podId::typeId (2 bytes << 16 | 2 bytes)
    //

  //////////////////////////////////////////////////////////////////////////
  // Pod
  //////////////////////////////////////////////////////////////////////////

    internal class PodInfo
    {
      public Pod pod;
      public string name;
      public long modified;
      public int size;
      public Version version;
      public int typesPos;
      public TypeInfo[] types;
      public bool match;
    }

  //////////////////////////////////////////////////////////////////////////
  // TypeInfo
  //////////////////////////////////////////////////////////////////////////

    internal class TypeInfo
    {
      public Type type;
      public string name;
    }

  //////////////////////////////////////////////////////////////////////////
  // FacetIndex
  //////////////////////////////////////////////////////////////////////////

    internal class FacetIndex
    {
      public string name;             // facet name
      public Hashtable valueToTypes;  // facet values object -> int[]/Type[]
      public int pos;                 // file offset
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal const int MAGIC   = 0x54795065;
    internal const int VERSION = 0x01000019;
    internal static readonly FileInfo dbFile =
      new FileInfo(Repo.working().homeDotnet().FullName +
                   Path.DirectorySeparatorChar + "etc" +
                   Path.DirectorySeparatorChar + "sys" +
                   Path.DirectorySeparatorChar + "types.db");

    internal static object lockObj = new object();
    internal static Log log = Log.get("typedb");
    internal static TypeDb instance;
    internal static List noTypes = new List(Sys.TypeType).ro();

    internal FileStream f;
    internal DataReader r;
    internal PodInfo[] pods;
    internal Hashtable podsByName;    // string -> PodInfo
    internal Hashtable facetIndices;  // string -> FacetIndex

  }
}