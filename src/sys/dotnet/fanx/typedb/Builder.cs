//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Dec 07  Brian Frank  Creation
//

using System;
using System.Collections;
using System.IO;
using System.Text;
using FanObj = Fan.Sys.FanObj;
using List = Fan.Sys.List;
using Log = Fan.Sys.Log;
using Sys = Fan.Sys.Sys;
using Symbol = Fan.Sys.Symbol;
using Repo = Fan.Sys.Repo;
using Version = Fan.Sys.Version;
using ICSharpCode.SharpZipLib.Zip;
using Fanx.Fcode;
using Fanx.Serial;
using Fanx.Util;

namespace Fanx.Typedb
{
  /// <summary>
  /// Builder is responsible for building up the type db data structures.
  /// <summary>
  internal class Builder
  {

  //////////////////////////////////////////////////////////////////////////
  // Build
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Rebuild the typedb by assembling an index of all the pod files.
    /// </summary>
    internal Builder build()
    {
      long t1 = System.Environment.TickCount;

      loadPods();
      map();
      resolve();
      indexFacets();
      write();
      persist();

      long t2 = System.Environment.TickCount;
      log.debug("Rebuilt type database (" + (t2-t1) + "ms)");
      return this;
    }

  //////////////////////////////////////////////////////////////////////////
  // Load
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Load 'typedb.def' from each pod into memory.
    /// </summary>
    void loadPods()
    {
      Hashtable podFiles = Repo.findAllPods();
      ArrayList acc = new ArrayList(podFiles.Count);
      IDictionaryEnumerator en = podFiles.GetEnumerator();
      while (en.MoveNext())
      {
        string n = (string)en.Key;
        FileInfo f = (FileInfo)en.Value;
        try
        {
          acc.Add(loadPod(n, f));
        }
        catch (Exception e)
        {
          log.err("Cannot load " + f, e);
        }
      }
      pods = (Pod[])acc.ToArray(typeof(Pod));
    }

    /// <summary>
    /// Load 'typedb.def' from the specified pod file.
    /// </summary>
    Pod loadPod(string n, FileInfo f)
    {
      // file info
      Pod p = new Pod();
      p.name = n;
      p.modified = f.LastWriteTime.Ticks;
      p.size = (int)f.Length;

      // open typedb.db input zip
      ZipFile zip = new ZipFile(f.FullName);
      try
      {
        ZipEntry entry = zip.GetEntry("typedb.def");
        if (entry == null)
          throw new Exception("Pod missing /typedb.def: " + p.name);
        loadPod(p, new DataReader(new BufferedStream(zip.GetInputStream(entry))));
      }
      finally
      {
        zip.Close();
      }

      // done
      return p;
    }

    void loadPod(Pod p, DataReader input)
    {
      // magic
      //if (input.ReadInt() != FConst.TypeDbMagic)
      //  throw new IOException("Invalid magic");

      // typedb format version
      int version = input.ReadInt();
      //if (version != FConst.TypeDbVersion)
      //  throw new IOException("Invalid version 0x" + version.ToString("X"));

      // pod name
      string podName = input.ReadUTF();
      if (p.name != podName)
        throw new Exception("Pod misnamed: " + p.name + ".pod != " + podName);

      // pod meta-data
      p.version = Version.fromStr(input.ReadUTF());

      // facet name index
      string[] facetNames = readStrings(input);

      // pod level facets
      p.facets = readFacets(p.name, facetNames, input);

      // types
      p.types = new Type[input.ReadUnsignedShort()];
      for (int i=0; i<p.types.Length; ++i)
        p.types[i] = loadType(p, facetNames, input);
    }

    Type loadType(Pod p, string[] facetNames, DataReader input)
    {
      Type t = new Type();
      t.pod         = p;
      t.name        = input.ReadUTF();
      t.qname       = p.name + "::" + t.name;
      t.baseQname   = input.ReadUTF();
      t.mixinQnames = readStrings(input);
      t.flags       = input.ReadInt();
      t.facets      = readFacets(t.qname, facetNames, input);
      numTypes++;
      return t;
    }

    string[] readStrings(DataReader input)
    {
      int len = input.ReadUnsignedShort();
      if (len == 0) return emptyStrings;
      string[] s = new string[len];
      for (int i=0; i<len; ++i)
        s[i] = input.ReadUTF();
      return s;
    }

    Facets readFacets(string loc, string[] facetNames, DataReader input)
    {
      int len = input.ReadUnsignedShort();
      if (len == 0) return emptyFacets;
      Facets facets = new Facets(loc);
      for (int i=0; i<len; ++i)
      {
        string name = facetNames[input.ReadUnsignedShort()];
        string val  = input.ReadUTF();
        facets.add(name, val);
      }
      return facets;
    }

  //////////////////////////////////////////////////////////////////////////
  // Map
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Now that everything is loaded into memory, sort
    /// all the pods/types, assign them integer ids, and
    /// map them into hashtables.
    /// </summary>
    void map()
    {
      qnameToType = new Hashtable(numTypes*2);
      Array.Sort(pods);
      for (int i=0; i<pods.Length; ++i)
      {
        Pod p = pods[i];
        p.id = i;
        map(p);
      }
    }

    void map(Pod p)
    {
      Type[] types = p.types;
      Array.Sort(types);
      for (int i=0; i<types.Length; ++i)
      {
        Type t = types[i];
        t.qid = (p.id << 16) | i;
        t.id  = i;
        qnameToType[t.qname] = t;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Resolve
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Now that everything is loaded into memory and mapped
    /// we can resolve qnames to their Builder.Type instances.
    /// </summary>
    void resolve()
    {
      for (int i=0; i<pods.Length; ++i)
      {
        Type[] types = pods[i].types;
        for (int j=0; j<types.Length; ++j)
          resolve(types[j]);
      }
    }

    void resolve(Type t)
    {
      t.super = resolve(t.baseQname, t);
      t.mixins = new Type[t.mixinQnames.Length];
      for (int i=0; i<t.mixins.Length; ++i)
        t.mixins[i] = resolve(t.mixinQnames[i], t);
    }

    Type resolve(string qname, Type on)
    {
      Type t = (Type)qnameToType[qname];
      if (t != null) return t;
      if (qname == "") return null;
      log.warn("Unresolved super type: " + qname + " [" + on + "]");
      return null;
    }

  //////////////////////////////////////////////////////////////////////////
  // Index Facets
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Build the facet indices which map facet values to lists of Types.
    /// </summary>
    void indexFacets()
    {
      // the facet names to index is configured
      // by the pod level facet indexFacets
      Hashtable facetNames = new Hashtable();
      for (int i=0; i<pods.Length; ++i)
      {
        List symbols = pods[i].facets.getSymbolList("sys::podIndexFacets");
        if (symbols == null) continue;
        for (int j=0; j<symbols.sz(); ++j)
        {
          string n = ((Symbol)symbols.get(j)).qname();
          if (facetNames[n] == null)
            facetNames[n] = new FacetIndex(n);
        }
      }

      // now we know what our facet indices are
      FacetIndex[] indices = new FacetIndex[facetNames.Count];
      facetNames.Values.CopyTo(indices, 0);
      this.facetIndices = indices;

      // populate facet indices
      for (int i=0; i<pods.Length; ++i)
      {
        Type[] types = pods[i].types;
        for (int j=0; j<types.Length; ++j)
        {
          Type t = types[j];
          if (t.facets.isEmpty()) continue;
          for (int k=0; k<indices.Length; ++k)
            addToIndex(indices[k], t);
        }
      }
    }

    void addToIndex(FacetIndex index, Type t)
    {
      // check if this type declares the index's facet
      string val = t.facets.get(index.name);
      if (val == null) return;

      // check if value is a seralized list, then
      // we add each list item to the index
      if (val.EndsWith("]"))
      {
        object obj = t.facets.getObj(index.name);
        if (obj is List)
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

    /// <summary>
    /// Write the 'types.db' file to a memory buffer.
    /// </summary>
    void write()
    {
      Box buf = this.buf = new Box(new byte[65536], 0);

      // header
      buf.u4(TypeDb.MAGIC);
      buf.u4(TypeDb.VERSION);

      // pod list
      buf.u2(pods.Length);
      for (int i=0; i<pods.Length; ++i)
      {
        Pod p = pods[i];
        buf.utf(p.name);
        buf.u8(p.modified);
        buf.u4(p.size);
        buf.utf(p.version.ToString());
        p.typesPos = @ref();
      }

      // facet indices list
      buf.u2(facetIndices.Length);
      for (int i=0; i<facetIndices.Length; ++i)
      {
        FacetIndex index = facetIndices[i];
        buf.utf(index.name);
        index.pos = @ref();
      }

      // podTypes
      for (int i=0; i<pods.Length; ++i)
      {
        Pod p = pods[i];
        backpatch(p.typesPos);
        buf.u2(p.types.Length);
        for (int j=0; j<p.types.Length; ++j)
        {
          Type t = p.types[j];
          buf.utf(t.name);
        }
      }

      // facet indices
      for (int i=0; i<facetIndices.Length; ++i)
        write(facetIndices[i]);
    }

    void write(FacetIndex index)
    {
      backpatch(index.pos);
      buf.u2(index.valueToTypes.Count);
      IDictionaryEnumerator en = index.valueToTypes.GetEnumerator();
      while (en.MoveNext())
      {
        string val = (string)en.Key;
        ArrayList types = (ArrayList)en.Value;
        buf.utf(val);
        buf.u2(types.Count);
        for (int i=0; i<types.Count; ++i)
          buf.u4(((Type)types[i]).qid);
      }
    }

    int @ref()
    {
      int pos = buf.len;
      buf.u4(0xfeeeeeef);
      return pos;
    }

    void backpatch(int @ref)
    {
      buf.u4(@ref, buf.len);
    }

  //////////////////////////////////////////////////////////////////////////
  // Persist
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Flush the 'types.db' memory buffer to file.
    /// </summary>
    void persist()
    {
      FileStream output = TypeDb.dbFile.OpenWrite();
      output.Write(buf.buf, 0, buf.len);
      output.Close();
    }

  //////////////////////////////////////////////////////////////////////////
  // Debug
  //////////////////////////////////////////////////////////////////////////

    void dump()
    {
      for (int i=0; i<pods.Length; ++i)
        dump(pods[i]);
    }

    void dump(Pod p)
    {
      System.Console.WriteLine("### " + p.name + " [" + p.id + "] ###");
      System.Console.WriteLine("  modified: " + new DateTime(p.modified));
      System.Console.WriteLine("  size:     " + (p.size/1024) + "kb");
      System.Console.WriteLine("  version:  " + p.version);
      for (int i=0; i<p.types.Length; ++i)
        dump(p.types[i]);
    }

    void dump(Type t)
    {
      System.Console.WriteLine("--- " + t.name + " [" + t.id + "] ---");
      System.Console.WriteLine("  base:   " + t.baseQname);
      System.Console.WriteLine("  mixins: " + join(t.mixins));
      System.Console.WriteLine("  facets: " + t.facets);
    }

    void dump(FacetIndex[] indices)
    {
      for (int i=0; i<indices.Length; ++i)
        dump(indices[i]);
    }

    void dump(FacetIndex index)
    {
      System.Console.WriteLine("--- Facet Index: " + index.name + " ---");
      IDictionaryEnumerator en = index.valueToTypes.GetEnumerator();
      while (en.MoveNext())
      {
        string val = (string)en.Key;
        ArrayList types = (ArrayList)en.Value;
        System.Console.WriteLine("  " + val + ": " + join(types.ToArray()));
      }
    }

    static string join(Object[] a)
    {
      StringBuilder s = new StringBuilder();
      for (int i=0; i<a.Length; ++i)
      {
        if (i > 0) s.Append(", ");
        s.Append(a[i]);
      }
      return s.ToString();
    }

  //////////////////////////////////////////////////////////////////////////
  // Pod
  //////////////////////////////////////////////////////////////////////////

    internal sealed class Pod : IComparable
    {
      public override string ToString() { return name; }

      public int CompareTo(object obj)
      {
        return name.CompareTo(((Pod)obj).name);
      }

      public int id;           // two byte pod id
      public string name;      // name of pod
      public long modified;    // modified millis of pod file
      public int size;         // size of pod file
      public Version version;  // pod version
      public Facets facets;    // string -> string
      public Type[] types;     // list of types
      public int typesPos;     // backpatch position
    }

  //////////////////////////////////////////////////////////////////////////
  // Type
  //////////////////////////////////////////////////////////////////////////

    internal sealed class Type : IComparable
    {
      public override string ToString() { return qname; }

      public int CompareTo(object obj)
      {
        return name.CompareTo(((Type)obj).name);
      }

      public Pod pod;               // parent pod
      public string name;           // simple name within pod
      public string qname;          // qualified name
      public int qid;               // four byte qualified id
      public int id;                // two byte id within pod
      public string baseQname;      // base class qname
      public string[] mixinQnames;  // mixin qnames
      public Type super;            // resolved base Type
      public Type[] mixins;         // resolved mixin Types
      public int flags;             // bitmask
      public Facets facets;         // string -> string
    }

  //////////////////////////////////////////////////////////////////////////
  // Facets
  //////////////////////////////////////////////////////////////////////////

    internal sealed class Facets
    {
      public Facets(string loc)
      {
        this.loc = loc;
      }

      public bool isEmpty()
      {
        return map.Count == 0;
      }

      public void add(string name, string val)
      {
        map[name] = val;
      }

      public string get(string name)
      {
        return (string)map[name];
      }

      public object getObj(string name)
      {
        string val = get(name);
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

      public string getStr(string name)
      {
        object v = getObj(name);
        if (v == null) return null;
        if (v is string) return (string)v;
        log.warn("Expecting '" + loc + "@" + name + "' to be string, not " + FanObj.@typeof(v));
        return null;
      }

      public List getSymbolList(string name)
      {
        object v = getObj(name);
        if (v == null) return null;
        if (v is List && ((List)v).of() == Sys.SymbolType) return (List)v;
        log.warn("Expecting '" + loc + "@" + name + "' to be Symbol[], not " + FanObj.@typeof(v));
        return null;
      }

      public string loc;
      public Hashtable map = new Hashtable();
    }

  //////////////////////////////////////////////////////////////////////////
  // FacetIndex
  //////////////////////////////////////////////////////////////////////////

    internal class FacetIndex
    {
      public FacetIndex(string name)
      {
        this.name = name;
        this.valueToTypes = new Hashtable();
      }

      public void add(string val, Type t)
      {
        ArrayList types = (ArrayList)valueToTypes[val];
        if (types == null)
        {
          types = new ArrayList(8);
          valueToTypes[val] = types;
        }
        types.Add(t);
      }

      public string name;             // facet key
      public Hashtable valueToTypes;  // facet value string -> ArrayList
      public int pos;                 // backpatch position
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    static Log log = TypeDb.log;

    string[] emptyStrings = new string[0];
    Facets emptyFacets = new Facets("empty");

    Pod[] pods;
    Hashtable qnameToType;
    int numTypes;
    FacetIndex[] facetIndices;
    Box buf;

  }
}