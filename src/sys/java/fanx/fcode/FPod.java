//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 05  Brian Frank  Creation
//
package fanx.fcode;

import java.io.*;
import java.util.*;
import java.util.zip.*;
import fan.sys.*;
import fan.sys.Map;
import fanx.util.*;

/**
 * FPod is the read/write fcode representation of sys::Pod.  It's main job in
 * life is to manage all the pod-wide constant tables for names, literals,
 * type/slot references and type/slot definitions.
 */
public final class FPod
  implements FConst
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public FPod(String podName, FStore store)
  {
    if (store != null) store.fpod = this;
    this.podName    = podName;
    this.store      = store;
    this.names      = new FTable.Names(this);
    this.typeRefs   = new FTable.TypeRefs(this);
    this.fieldRefs  = new FTable.FieldRefs(this);
    this.methodRefs = new FTable.MethodRefs(this);
  }

//////////////////////////////////////////////////////////////////////////
// Lookup
//////////////////////////////////////////////////////////////////////////

  public FType type(String name)
  {
    for (int i=0; i<types.length; ++i)
      if (typeRef(types[i].self).typeName.equals(name))
        return types[i];
    throw UnknownTypeErr.make(name);
  }

//////////////////////////////////////////////////////////////////////////
// Tables
//////////////////////////////////////////////////////////////////////////

  public final String name(int index)          { return (String)names.get(index);   }
  public final FTypeRef typeRef(int index)     { return (FTypeRef)typeRefs.get(index);  }
  public final FFieldRef fieldRef(int index)   { return (FFieldRef)fieldRefs.get(index);  }
  public final FMethodRef methodRef(int index) { return (FMethodRef)methodRefs.get(index); }

//////////////////////////////////////////////////////////////////////////
// Read
//////////////////////////////////////////////////////////////////////////

  /**
   * Read from a FStore which provides random access
   */
  public void read() throws IOException
  {
    // pod meta
    readPodMeta(store.read("meta.props", true));

    names.read(store.read("fcode/names.def"));
    typeRefs.read(store.read("fcode/typeRefs.def"));
    fieldRefs.read(store.read("fcode/fieldRefs.def"));
    methodRefs.read(store.read("fcode/methodRefs.def"));

    // type meta
    readTypeMeta(store.read("fcode/types.def"));

    // full fcode always lazy loaded in Type.reflect()
  }

  /**
   * Read the literal constant tables (if not already loaded).
   */
  public FLiterals readLiterals() throws IOException
  {
    if (literals == null)
      literals = new FLiterals(this).read();
    return literals;
  }

  /// debug forces full load of Types too
  public void readFully() throws IOException
  {
    read();
    for (int i=0; i<types.length; ++i)
      types[i].read();
  }

  /**
   * Read from an input stream (used for loading scripts from memory)
   */
  public void readFully(final ZipInputStream zip) throws IOException
  {
    FStore.Input in = new FStore.Input(this, zip)
    {
      public void close() throws IOException { zip.closeEntry(); }
    };

    ZipEntry entry;
    literals = new FLiterals(this);
    while ((entry = zip.getNextEntry()) != null)
    {
      String name = entry.getName();
      if (name.equals("meta.props")) { readPodMeta(in); continue; }
      else if (name.startsWith("fcode/") && name.endsWith(".fcode")) readType(name, in);
      else if (name.equals("fcode/names.def")) names.read(in);
      else if (name.equals("fcode/typeRefs.def")) typeRefs.read(in);
      else if (name.equals("fcode/fieldRefs.def")) fieldRefs.read(in);
      else if (name.equals("fcode/methodRefs.def")) methodRefs.read(in);
      else if (name.equals("fcode/types.def")) readTypeMeta(in);
      else if (name.equals("fcode/ints.def")) literals.ints.read(in);
      else if (name.equals("fcode/floats.def")) literals.floats.read(in);
      else if (name.equals("fcode/decimals.def")) literals.decimals.read(in);
      else if (name.equals("fcode/strs.def")) literals.strs.read(in);
      else if (name.equals("fcode/durations.def")) literals.durations.read(in);
      else if (name.equals("fcode/uris.def")) literals.uris.read(in);
      else System.out.println("WARNING: unexpected file in pod: " + name);
    }
  }

  private void readPodMeta(FStore.Input in) throws IOException
  {
    // handle sys bootstrap specially using just java.util.Properties
    String metaName;
    if ("sys".equals(podName))
    {
      Properties props = new Properties();
      props.load(in);
      in.close();
      metaName =  props.getProperty("pod.name");
      podVersion = props.getProperty("pod.version");
      fcodeVersion = props.getProperty("fcode.version");
      depends = new Depend[0];
      return;
    }
    else
    {
      SysInStream sysIn = new SysInStream(in);
      this.meta = (Map)sysIn.readProps().toImmutable();
      sysIn.close();

      metaName = meta("pod.name");
      podVersion = meta("pod.version");

      fcodeVersion = (String)meta.get("fcode.version");
      if (fcodeVersion == null) fcodeVersion = "unspecified";

      String dependsStr = meta("pod.depends").trim();
      if (dependsStr.length() == 0) depends = new Depend[0];
      else
      {
        String[] toks = dependsStr.split(";");
        depends = new Depend[toks.length];
        for (int i=0; i<depends.length; ++i) depends[i] = Depend.fromStr(toks[i].trim());
      }
    }

    // check meta name matches podName passed to ctor
    if (podName == null) podName = metaName;
    if (!podName.equals(metaName))
      throw new IOException("Pod name mismatch " + podName + " != " + metaName);
  }

  private String meta(String key) throws IOException
  {
    String val = (String)meta.get(key);
    if (val == null) throw new IOException("meta.prop missing " + key);
    return val;
  }

  private void readTypeMeta(FStore.Input in) throws IOException
  {
    if (in == null) { types = new FType[0]; return; }

    // if we have types, then ensure we have correct fcode
    if (!FConst.FCodeVersion.equals(fcodeVersion))
      throw new IOException("Invalid fcode version: " + fcodeVersion + " != " + FConst.FCodeVersion);

    types = new FType[in.u2()];
    for (int i=0; i<types.length; ++i)
    {
      types[i] = new FType(this).readMeta(in);
      types[i].hollow = true;
    }
    in.close();
  }

  private void readType(String name, FStore.Input in) throws IOException
  {
    if (types == null || types.length == 0)
      throw new IOException("types.def must be defined first");

    String typeName = name.substring(6, name.length()-".fcode".length());
    for (int i=0; i<types.length; ++i)
    {
      String n = typeRef(types[i].self).typeName;
      if (n.equals(typeName )) { types[i].read(in); return; }
    }

    throw new IOException("Unexpected fcode file: " + name);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public String podName;      // pod's unique name
  public String podVersion;   // pod's version
  public Depend[] depends;    // pod dependencies
  public String fcodeVersion; // fcode format version
  public Map meta;            // meta Str:Str map
  public FStore store;        // store we using to read
  public FType[] types;       // pod's declared types
  public FTable names;        // identifier names: foo
  public FTable typeRefs;     // types refs:   [pod,type,variances*]
  public FTable fieldRefs;    // fields refs:  [parent,name,type]
  public FTable methodRefs;   // methods refs: [parent,name,ret,params*]
  public FLiterals literals;  // literal constants (on read fully or lazy load)

}