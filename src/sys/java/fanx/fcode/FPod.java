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

  public FPod(String podName, java.util.zip.ZipFile zipFile)
  {
    this.podName    = podName;
    this.store      = zipFile == null ? null : new FStore(this, zipFile);
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
    throw UnknownTypeErr.make(name).val;
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
    names.read(store.read("names.def", true));
    typeRefs.read(store.read("typeRefs.def"));
    fieldRefs.read(store.read("fieldRefs.def"));
    methodRefs.read(store.read("methodRefs.def"));

    // pod meta
    readPodMeta(store.read("pod.def", true));

    // type meta
    readTypeMeta(store.read("types.def", true));

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

      if (name.equals("names.def")) names.read(in);
      else if (name.equals("typeRefs.def")) typeRefs.read(in);
      else if (name.equals("fieldRefs.def")) fieldRefs.read(in);
      else if (name.equals("methodRefs.def")) methodRefs.read(in);
      else if (name.equals("pod.def")) readPodMeta(in);
      else if (name.equals("types.def")) readTypeMeta(in);
      else if (name.endsWith(".fcode")) readType(name, in);
      else if (name.equals("ints.def")) literals.ints.read(in);
      else if (name.equals("floats.def")) literals.floats.read(in);
      else if (name.equals("decimals.def")) literals.decimals.read(in);
      else if (name.equals("strs.def")) literals.strs.read(in);
      else if (name.equals("durations.def")) literals.durations.read(in);
      else if (name.equals("uris.def")) literals.uris.read(in);
      else if (name.equals("symbols.def")) readSymbols(in);
      else System.out.println("WARNING: unexpected file in pod: " + name);
    }
  }

  private void readPodMeta(FStore.Input in) throws IOException
  {
    if (in.u4() != 0x0FC0DE05)
      throw new IOException("Invalid magic");

    int version = in.u4();
    if (version != FConst.FCodeVersion)
      throw new IOException("Invalid version 0x" + Integer.toHexString(version));
    this.version = version;

    podName = in.utf();
    podVersion = in.utf();
// TODO: fix this to be u2
    depends = new Depend[in.u1()];
    for (int i=0; i<depends.length; ++i)
      depends[i] = Depend.fromStr(in.utf());

    attrs = FAttrs.read(in);

    in.close();
  }

  private void readTypeMeta(FStore.Input in) throws IOException
  {
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

    String typeName = name.substring(0, name.length()-".fcode".length());
    for (int i=0; i<types.length; ++i)
    {
      String n = typeRef(types[i].self).typeName;
      if (n.equals(typeName )) { types[i].read(in); return; }
    }

    throw new IOException("Unexpected fcode file: " + name);
  }

  public void readSymbols() throws IOException
  {
    if (symbols != null) return;  // aready read
    FStore.Input in = store.read("symbols.def");
    if (in == null) return; // none defined
    readSymbols(in);
  }

  private void readSymbols(FStore.Input in) throws IOException
  {
    symbols = new FSymbol[in.u2()];
    for (int i=0; i<symbols.length; ++i)
      symbols[i] = new FSymbol(this).read(in);
    in.close();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public String podName;     // pod's unique name
  public String podVersion;  // pod's version
  public Depend[] depends;   // pod dependencies
  public FAttrs attrs;       // pod attributes
  public FStore store;       // store we using to read
  public int version;        // fcode format version
  public FType[] types;      // pod's declared types
  public FSymbol[] symbols;  // pod's declared symbols
  public FTable names;       // identifier names: foo
  public FTable typeRefs;    // types refs:   [pod,type,variances*]
  public FTable fieldRefs;   // fields refs:  [parent,name,type]
  public FTable methodRefs;  // methods refs: [parent,name,ret,params*]
  public FLiterals literals; // literal constants (on read fully or lazy load)

}