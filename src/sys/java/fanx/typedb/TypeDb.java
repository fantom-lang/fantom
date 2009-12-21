//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Dec 07  Brian Frank  Creation
//
package fanx.typedb;

import java.io.*;
import java.io.File;
import java.util.*;
import java.util.Map.Entry;
import fan.sys.*;
import fan.sys.List;
import fanx.serial.*;

/**
 * TypeDb is responsible for managing the indexes
 * on the the installed pods and types.
 */
public class TypeDb
{

//////////////////////////////////////////////////////////////////////////
// Get
//////////////////////////////////////////////////////////////////////////

  /**
   * Get the type database.  The database is lazily
   * loaded (and maybe rebuilt) on the first access.
   */
  public static TypeDb get()
  {
    synchronized (lock)
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
      // if type database exists
      if (dbFile.exists())
      {
        TypeDb db = new TypeDb();
        try
        {
          // open and check up-to-date
          if (db.open(true)) return db;
        }
        catch (Exception e)
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
      TypeDb db = new TypeDb();
      db.open(false);
      return db;
    }
    catch (Exception e)
    {
      log.err("Cannot load type database", e);
      throw Err.make("Cannot load type database", e).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// API
//////////////////////////////////////////////////////////////////////////

  /**
   * Implementation of 'Type.findByFacet'
   */
  public synchronized List findByFacet(String name, Object val, Object options)
  {
    // process options
    if (options == Boolean.TRUE && val instanceof Type)
      return findByFacetInheritance(name, (Type)val);

    // no options
    return doFindByFacet(name, val);
  }

  /**
   * Implementation when val is Type and options == true.
   * Return a query against the val's full inheritance hierarchy.
   */
  private List findByFacetInheritance(String name, Type val)
  {
    List inheritance = val.inheritance();
    List acc = new List(Sys.TypeType);
    for (int i=0; i<inheritance.sz(); ++i)
      acc.addAll(doFindByFacet(name, inheritance.get(i)));
    return acc.ro();
  }

  /**
   * Find all the types declared by the specified facet name/value pair.
   */
  private List doFindByFacet(String name, Object val)
  {
    try
    {
      // lookup the FacetIndex for that name
      FacetIndex index = readFacetIndex(name);

      // check if we have any types mapped for value
      Object result = index.valueToTypes.get(val);
      if (result == null) return noTypes;

      // if we've already done a lookup on this value,
      // then the result will already be a List of Types
      if (result instanceof List) return (List)result;

      // otherwise this is the first lookup, so we
      // have to map type ids to a List of Types
      Type[] types = resolve((int[])result);
      List list = new List(Sys.TypeType, types).ro();
      index.valueToTypes.put(val, list);
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

  /**
   * Open the type database.  If 'checkUpToDate' is true,
   * then verify the pods list is up to date - if not then
   * return close and false.
   */
  synchronized boolean open(boolean checkUpToDate)
    throws IOException
  {
    this.f = new RandomAccessFile(dbFile, "r");

    // read header
    if (u4() != MAGIC) throw new IOException("Bad magic");
    if (u4() != VERSION) throw new IOException("Bad version");

    // read pods list
    readPods();

    // check pods if needed
    if (checkUpToDate)
    {
      if (!checkUpToDate())
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
    throws IOException
  {
    pods = new PodInfo[u2()];
    podsByName = new HashMap(pods.length*2);
    for (int i=0; i<pods.length; ++i)
    {
      PodInfo p = pods[i] = new PodInfo();
      p.name     = utf();
      p.modified = u8();
      p.size     = u4();
      p.version  = Version.fromStr(utf());
      p.typesPos = u4();
      podsByName.put(p.name, p);
    }
  }

  private void readFacetIndices()
    throws IOException
  {
    int num = u2();
    facetIndices = new HashMap(num*2);
    for (int i=0; i<num; ++i)
    {
      FacetIndex index = new FacetIndex();
      index.name = utf();
      index.pos  = u4();
      facetIndices.put(index.name, index);
    }
  }

  boolean checkUpToDate()
  {
    Iterator it = Repo.findAllPods().entrySet().iterator();
    while (it.hasNext())
    {
      Entry entry = (Entry)it.next();
      String n = (String)entry.getKey();
      File f = (File)entry.getValue();

      // check that pod wasn't added
      PodInfo p = (PodInfo)podsByName.get(n);
      if (p == null)
      {
        log.debug("Out-of-date pod added: " + n);
        return false;
      }

      // check pod has not been modified
      if (p.modified != f.lastModified() || p.size != (int)f.length())
      {
        log.debug("Out-of-date pod modified : " + n);
        return false;
      }
      p.match = true;
    }

    // check that we matched all pods
    for (int i=0; i<pods.length; ++i)
      if (!pods[i].match)
      {
        log.debug("Out-of-date pod removed: " + pods[i].name);
        return false;
      }

    // up to date!
    return true;
  }

  /**
   * Close the database file.
   */
  synchronized void close()
  {
    if (f != null)
    {
      try { f.close(); } catch (IOException e) { e.printStackTrace(); }
      f = null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Types
//////////////////////////////////////////////////////////////////////////

  /**
   * Ensure that the list of types for the specified
   * pos has been lazy loaded.
   */
  synchronized void readPodTypes(PodInfo p)
    throws IOException
  {
    if (p.types != null) return;

    seek(p.typesPos);
    p.types = new TypeInfo[u2()];
    for (int i=0; i<p.types.length; ++i)
    {
      TypeInfo t = p.types[i] = new TypeInfo();
      t.name = utf();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Facet Indices
//////////////////////////////////////////////////////////////////////////

  /**
   * Ensure that the facet index by the given name is loaded.
   */
  synchronized FacetIndex readFacetIndex(String name)
    throws IOException
  {
    // find index by name
    FacetIndex index = (FacetIndex)facetIndices.get(name);
    if (index == null)
      throw Err.make("Facet not indexed: " + name).val;

    // if already loaded
    if (index.valueToTypes != null) return index;

    // lazy load
    seek(index.pos);
    int num = u2();
    index.valueToTypes = new HashMap(num*2);
    for (int i=0; i<num; ++i)
    {
      String val = utf();
      int[] types = new int[u2()];
      for (int j=0; j<types.length; ++j) types[j] = u4();
      index.valueToTypes.put(ObjDecoder.decode(val), types);
    }

    return index;
  }

//////////////////////////////////////////////////////////////////////////
// Type Resolve
//////////////////////////////////////////////////////////////////////////

  /**
   * Resolve an array of type identifiers to Type instances.
   */
  synchronized Type[] resolve(int[] qids)
    throws IOException
  {
    Type[] types = new Type[qids.length];
    for (int i=0; i<qids.length; ++i)
      types[i] = resolve(qids[i]);
    return types;
  }

  /**
   * Resolve a type identifiers to a Type instances.
   */
  synchronized Type resolve(int qids)
    throws IOException
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

  final int tell() throws IOException { return (int)f.getFilePointer(); }
  final void seek(int pos) throws IOException { f.seek(pos); }

  final int u1() throws IOException { return f.readUnsignedByte(); }
  final int u2() throws IOException { return f.readUnsignedShort(); }
  final int u4() throws IOException { return f.readInt(); }
  final long u8() throws IOException { return f.readLong(); }
  final String utf() throws IOException { return f.readUTF(); }

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

  static class PodInfo
  {
    Pod pod;
    String name;
    long modified;
    int size;
    Version version;
    int typesPos;
    TypeInfo[] types;
    boolean match;
  }

//////////////////////////////////////////////////////////////////////////
// TypeInfo
//////////////////////////////////////////////////////////////////////////

  static class TypeInfo
  {
    Type type;
    String name;
  }

//////////////////////////////////////////////////////////////////////////
// FacetIndex
//////////////////////////////////////////////////////////////////////////

  static class FacetIndex
  {
    String name;           // facet name
    HashMap valueToTypes;  // facet values Object -> int[]/Type[]
    int pos;               // file offset
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final int MAGIC   = 0x54795065;
  static final int VERSION = 0x01000019;
  static final File dbFile;
  static
  {
    String sep = File.separator;
    dbFile = new File(Repo.working().homeJava(), "etc"+sep+"sys"+sep+"types.db");
  }

  static Object lock = new Object();
  static Log log = Log.get("typedb");
  static TypeDb instance;
  static List noTypes = new List(Sys.TypeType).ro();

  RandomAccessFile f;
  PodInfo[] pods;
  HashMap podsByName;    // String -> PodInfo
  int facetIndicesPos;   // file offset for facet list
  HashMap facetIndices;  // String -> FacetIndex

}