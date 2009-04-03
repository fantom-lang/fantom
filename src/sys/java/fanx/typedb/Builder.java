//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Dec 07  Brian Frank  Creation
//
package fanx.typedb;

import java.io.*;
import java.util.*;
import java.util.zip.*;
import fan.sys.FanObj;
import fan.sys.List;
import fan.sys.Log;
import fan.sys.Sys;
import fan.sys.Version;
import fanx.fcode.*;
import fanx.serial.*;
import fanx.util.*;

/**
 * Builder is responsible for building up
 * the type db data structures.
 */
class Builder
{

//////////////////////////////////////////////////////////////////////////
// Build
//////////////////////////////////////////////////////////////////////////

  /**
   * Rebuild the typedb by assembling an index of all the pod files.
   */
  Builder build()
    throws Exception
  {
    long t1 = System.nanoTime();

    loadPods();
    map();
    resolve();
    indexFacets();
    write();
    persist();

    long t2 = System.nanoTime();
    log.debug("Rebuilt type database (" + (t2-t1)/1000000L + "ms)");
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Load
//////////////////////////////////////////////////////////////////////////

  /**
   * Load 'typedb.def' from each pod into memory.
   */
  void loadPods()
  {
    File[] files = TypeDb.podsDir.listFiles();
    ArrayList acc = new ArrayList(files.length);
    for (int i=0; i<files.length; ++i)
    {
      File f = files[i];
      if (f.getName().endsWith(".pod"))
      {
        try
        {
          acc.add(loadPod(f));
        }
        catch (Throwable e)
        {
          log.error("Cannot load " + f, e);
        }
      }
    }
    pods = (Pod[])acc.toArray(new Pod[acc.size()]);
  }

  /**
   * Load 'typedb.def' from the specified pod file.
   */
  Pod loadPod(File f)
    throws Exception
  {
    // file info
    Pod p = new Pod();
    p.name = f.getName().substring(0, f.getName().length()-4);
    p.modified = f.lastModified();
    p.size = (int)f.length();

    // open typedb.db in zip
    ZipFile zip = new ZipFile(f);
    try
    {
      ZipEntry entry = zip.getEntry("typedb.def");
      if (entry == null)
        throw new Exception("Pod missing /typedb.def: " + p.name);
      loadPod(p, new DataInputStream(new BufferedInputStream(zip.getInputStream(entry))));
    }
    finally
    {
      zip.close();
    }

    // done
    return p;
  }

  void loadPod(Pod p, DataInputStream in)
    throws Exception
  {
    // magic
    if (in.readInt() != FConst.TypeDbMagic)
      throw new IOException("Invalid magic");

    // typedb format version
    int version = in.readInt();
    if (version != FConst.TypeDbVersion)
      throw new IOException("Invalid version 0x" + Integer.toHexString(version));

    // pod name
    String podName = in.readUTF();
    if (!p.name.equals(podName))
      throw new Exception("Pod misnamed: " + p.name + ".pod != " + podName);

    // pod meta-data
    p.version = Version.fromStr(in.readUTF());

    // facet name index
    String[] facetNames = readStrings(in);

    // pod level facets
    p.facets = readFacets(p.name, facetNames, in);

    // types
    p.types = new Type[in.readUnsignedShort()];
    for (int i=0; i<p.types.length; ++i)
      p.types[i] = loadType(p, facetNames, in);
  }

  Type loadType(Pod p, String[] facetNames, DataInputStream in)
    throws Exception
  {
    Type t = new Type();
    t.pod         = p;
    t.name        = in.readUTF();
    t.qname       = p.name + "::" + t.name;
    t.baseQname   = in.readUTF();
    t.mixinQnames = readStrings(in);
    t.flags       = in.readInt();
    t.facets      = readFacets(t.qname, facetNames, in);
    numTypes++;
    return t;
  }

  String[] readStrings(DataInputStream in)
    throws Exception
  {
    int len = in.readUnsignedShort();
    if (len == 0) return emptyStrings;
    String[] s = new String[len];
    for (int i=0; i<len; ++i)
      s[i] = in.readUTF();
    return s;
  }

  Facets readFacets(String loc, String[] facetNames, DataInputStream in)
    throws Exception
  {
    int len = in.readUnsignedShort();
    if (len == 0) return emptyFacets;
    Facets facets = new Facets(loc);
    for (int i=0; i<len; ++i)
    {
      String name = facetNames[in.readUnsignedShort()];
      String val  = in.readUTF();
      facets.add(name, val);
    }
    return facets;
  }

//////////////////////////////////////////////////////////////////////////
// Map
//////////////////////////////////////////////////////////////////////////

  /**
   * Now that everything is loaded into memory, sort
   * all the pods/types, assign them integer ids, and
   * map them into hashtables.
   */
  void map()
  {
    qnameToType = new HashMap(numTypes*2);
    Arrays.sort(pods);
    for (int i=0; i<pods.length; ++i)
    {
      Pod p = pods[i];
      p.id = i;
      map(p);
    }
  }

  void map(Pod p)
  {
    Type[] types = p.types;
    Arrays.sort(types);
    for (int i=0; i<types.length; ++i)
    {
      Type t = types[i];
      t.qid = (p.id << 16) | i;
      t.id  = i;
      qnameToType.put(t.qname, t);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Resolve
//////////////////////////////////////////////////////////////////////////

  /**
   * Now that everything is loaded into memory and mapped
   * we can resolve qnames to their Builder.Type instances.
   */
  void resolve()
  {
    for (int i=0; i<pods.length; ++i)
    {
      Type[] types = pods[i].types;
      for (int j=0; j<types.length; ++j)
        resolve(types[j]);
    }
  }

  void resolve(Type t)
  {
    t.base = resolve(t.baseQname, t);
    t.mixins = new Type[t.mixinQnames.length];
    for (int i=0; i<t.mixins.length; ++i)
      t.mixins[i] = resolve(t.mixinQnames[i], t);
  }

  Type resolve(String qname, Type on)
  {
    Type t = (Type)qnameToType.get(qname);
    if (t != null) return t;
    if (qname.equals("")) return null;
    log.warn("Unresolved super type: " + qname + " [" + on + "]");
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Index Facets
//////////////////////////////////////////////////////////////////////////

  /**
   * Build the facet indices which map facet values to lists of Types.
   */
  void indexFacets()
  {
    // the facet names to index is configured
    // by the pod level facet indexFacets
    HashMap facetNames = new HashMap();
    for (int i=0; i<pods.length; ++i)
    {
      List names = pods[i].facets.getStrList("indexFacets");
      if (names == null) continue;
      for (int j=0; j<names.sz(); ++j)
      {
        String n = (String)names.get(j);
        if (facetNames.get(n) == null)
          facetNames.put(n, new FacetIndex(n));
      }
    }

    // now we know what our facet indices are
    FacetIndex[] indices = (FacetIndex[])facetNames.values().toArray(new FacetIndex[facetNames.size()]);
    this.facetIndices = indices;

    // populate facet indices
    for (int i=0; i<pods.length; ++i)
    {
      Type[] types = pods[i].types;
      for (int j=0; j<types.length; ++j)
      {
        Type t = types[j];
        if (t.facets.isEmpty()) continue;
        for (int k=0; k<indices.length; ++k)
          addToIndex(indices[k], t);
      }
    }
  }

  void addToIndex(FacetIndex index, Type t)
  {
    // check if this type declares the index's facet
    String val = t.facets.get(index.name);
    if (val == null) return;

    // check if value is a seralized list, then
    // we add each list item to the index
    if (val.endsWith("]"))
    {
      Object obj = t.facets.getObj(index.name);
      if (obj instanceof List)
      {
        List list = (List)obj;
        for (int i=0; i<list.sz(); ++i)
          index.add(ObjEncoder.encode(list.get(i)), t);
        return;
      }
    }

    // add using serialized value as key
    index.add(val, t);
  }

//////////////////////////////////////////////////////////////////////////
// Write
//////////////////////////////////////////////////////////////////////////

  /**
   * Write the 'types.db' file to a memory buffer.
   */
  void write()
  {
    Box buf = this.buf = new Box(new byte[65536], 0);

    // header
    buf.u4(TypeDb.MAGIC);
    buf.u4(TypeDb.VERSION);

    // pod list
    buf.u2(pods.length);
    for (int i=0; i<pods.length; ++i)
    {
      Pod p = pods[i];
      buf.utf(p.name);
      buf.u8(p.modified);
      buf.u4(p.size);
      buf.utf(p.version.toString());
      p.typesPos = ref();
    }

    // facet indices list
    buf.u2(facetIndices.length);
    for (int i=0; i<facetIndices.length; ++i)
    {
      FacetIndex index = facetIndices[i];
      buf.utf(index.name);
      index.pos = ref();
    }

    // podTypes
    for (int i=0; i<pods.length; ++i)
    {
      Pod p = pods[i];
      backpatch(p.typesPos);
      buf.u2(p.types.length);
      for (int j=0; j<p.types.length; ++j)
      {
        Type t = p.types[j];
        buf.utf(t.name);
      }
    }

    // facet indices
    for (int i=0; i<facetIndices.length; ++i)
      write(facetIndices[i]);
  }

  void write(FacetIndex index)
  {
    backpatch(index.pos);
    buf.u2(index.valueToTypes.size());
    Iterator it = index.valueToTypes.keySet().iterator();
    while (it.hasNext())
    {
      String val = (String)it.next();
      ArrayList types = (ArrayList)index.valueToTypes.get(val);
      buf.utf(val);
      buf.u2(types.size());
      for (int i=0; i<types.size(); ++i)
        buf.u4(((Type)types.get(i)).qid);
    }
  }

  int ref()
  {
    int pos = buf.len;
    buf.u4(0xfeeeeeef);
    return pos;
  }

  void backpatch(int ref)
  {
    buf.u4(ref, buf.len);
  }

//////////////////////////////////////////////////////////////////////////
// Persist
//////////////////////////////////////////////////////////////////////////

  /**
   * Flush the 'types.db' memory buffer to file.
   */
  void persist()
    throws Exception
  {
    OutputStream out = new FileOutputStream(TypeDb.dbFile);
    out.write(buf.buf, 0, buf.len);
    out.close();
  }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  void dump()
  {
    for (int i=0; i<pods.length; ++i)
      dump(pods[i]);
  }

  void dump(Pod p)
  {
    System.out.println("### " + p.name + " [" + p.id + "] ###");
    System.out.println("  modified: " + new Date(p.modified));
    System.out.println("  size:     " + (p.size/1024) + "kb");
    System.out.println("  version:  " + p.version);
    for (int i=0; i<p.types.length; ++i)
      dump(p.types[i]);
  }

  void dump(Type t)
  {
    System.out.println("--- " + t.name + " [" + t.id + "] ---");
    System.out.println("  base:   " + t.baseQname);
    System.out.println("  mixins: " + join(t.mixins));
    //t.facets.dump();
    System.out.println("  facets: " + t.facets);
  }

  void dump(FacetIndex[] indices)
  {
    for (int i=0; i<indices.length; ++i)
      dump(indices[i]);
  }

  void dump(FacetIndex index)
  {
    System.out.println("--- Facet Index: " + index.name + " ---");
    Iterator it = index.valueToTypes.keySet().iterator();
    while (it.hasNext())
    {
      String val = (String)it.next();
      ArrayList types = (ArrayList)index.valueToTypes.get(val);
      System.out.println("  " + val + ": " + join(types.toArray()));
    }
  }

  static String join(Object[] a)
  {
    StringBuffer s = new StringBuffer();
    for (int i=0; i<a.length; ++i)
    {
      if (i > 0) s.append(", ");
      s.append(a[i]);
    }
    return s.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Pod
//////////////////////////////////////////////////////////////////////////

  static final class Pod implements Comparable
  {
    public String toString() { return name; }

    public int compareTo(Object obj)
    {
      return name.compareTo(((Pod)obj).name);
    }

    int id;           // two byte pod id
    String name;      // name of pod
    long modified;    // modified millis of pod file
    int size;         // size of pod file
    Version version;  // pod version
    Facets facets;    // String -> String
    Type[] types;     // list of types
    int typesPos;     // backpatch position
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  static final class Type implements Comparable
  {
    public String toString() { return qname; }

    public int compareTo(Object obj)
    {
      return name.compareTo(((Type)obj).name);
    }

    Pod pod;               // parent pod
    String name;           // simple name within pod
    String qname;          // qualified name
    int qid;               // four byte qualified id
    int id;                // two byte id within pod
    String baseQname;      // base class qname
    String[] mixinQnames;  // mixin qnames
    Type base;             // resolved base Type
    Type[] mixins;         // resolved mixin Types
    int flags;             // bitmask
    Facets facets;         // String -> String
  }

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  static final class Facets
  {
    Facets(String loc)
    {
      this.loc = loc;
    }

    boolean isEmpty()
    {
      return map.size() == 0;
    }

    void add(String name, String val)
    {
      map.put(name, val);
    }

    String get(String name)
    {
      return (String)map.get(name);
    }

    Object getObj(String name)
    {
      String val = get(name);
      if (val == null) return null;
      try
      {
        return ObjDecoder.decode(val);
      }
      catch (Exception e)
      {
        log.warn("Cannot decode " + loc + "@" + name + ": " + val, e);
        return null;
      }
    }

    String getStr(String name)
    {
      Object v = getObj(name);
      if (v == null) return null;
      if (v instanceof String) return (String)v;
      log.warn("Expecting '" + loc + "@" + name + "' to be Str, not " + FanObj.type(v));
      return null;
    }

    List getStrList(String name)
    {
      Object v = getObj(name);
      if (v == null) return null;
      if (v instanceof List && ((List)v).of() == Sys.StrType) return (List)v;
      log.warn("Expecting '" + loc + "@" + name + "' to be Str[], not " + FanObj.type(v));
      return null;
    }

    void dump()
    {
      Iterator keys = map.keySet().iterator();
      while (keys.hasNext())
      {
        Object key= keys.next();
        System.out.println(key + "=" + map.get(key));
      }
    }

    String loc;
    HashMap map = new HashMap();
  }

//////////////////////////////////////////////////////////////////////////
// FacetIndex
//////////////////////////////////////////////////////////////////////////

  static class FacetIndex
  {
    FacetIndex(String name)
    {
      this.name = name;
      this.valueToTypes = new HashMap();
    }

    void add(String val, Type t)
    {
      ArrayList types = (ArrayList)valueToTypes.get(val);
      if (types == null)
      {
        types = new ArrayList(8);
        valueToTypes.put(val, types);
      }
      types.add(t);
    }

    String name;           // facet key
    HashMap valueToTypes;  // facet value String -> ArrayList
    int pos;               // backpatch position
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static Log log = TypeDb.log;

  String[] emptyStrings = new String[0];
  Facets emptyFacets = new Facets("empty");

  Pod[] pods;
  HashMap qnameToType;
  int numTypes;
  FacetIndex[] facetIndices;
  Box buf;

}