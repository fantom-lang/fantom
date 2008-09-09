//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Sep 06  Andy Frank  Creation
//

using System;
using System.Text;
using Fan.Sys;
using Uri = Fan.Sys.Uri;
using Fanx.Util;
using ICSharpCode.SharpZipLib.Zip;

namespace Fanx.Fcode
{
  /// <summary>
  /// FPod is the read/write fcode representation of sys::Pod.  It's main job in
  /// life is to manage all the pod-wide constant tables for names, literals,
  /// type/slot references and type/slot definitions.
  /// </summary>
  public sealed class FPod
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FPod(string podName, ZipFile zipFile)
    {
      this.m_podName    = podName;
      this.m_store      = zipFile == null ? null : new FStore(this, zipFile);
      this.m_names      = new FTable.Names(this);
      this.m_typeRefs   = new FTable.TypeRefs(this);
      this.m_fieldRefs  = new FTable.FieldRefs(this);
      this.m_methodRefs = new FTable.MethodRefs(this);
    }

  //////////////////////////////////////////////////////////////////////////
  // Lookup
  //////////////////////////////////////////////////////////////////////////

    public FType type(string nameToFind)
    {
      for (int i=0; i<m_types.Length; i++)
        if (name(typeRef(m_types[i].m_self).typeName) == nameToFind)
          return m_types[i];
      throw UnknownTypeErr.make(nameToFind).val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Tables
  //////////////////////////////////////////////////////////////////////////

    public string name(int index)       { return (string)m_names.get(index); }
    public FTypeRef typeRef(int index)  { return (FTypeRef)m_typeRefs.get(index); }
    public FTuple fieldRef(int index)   { return (FTuple)m_fieldRefs.get(index); }
    public FTuple methodRef(int index)  { return (FTuple)m_methodRefs.get(index); }

  //////////////////////////////////////////////////////////////////////////
  // .NET Emit Utils
  //////////////////////////////////////////////////////////////////////////

    public class NMethod
    {
      public string parentType;
      public string methodName;
      public string returnType;
      public string[] paramTypes;
      public bool isStatic = false;
    }

    /// <summary>
    /// Map a fcode method signature to a .NET method emit signature.
    /// </summary>
    public NMethod ncall(int index, int opcode)
    {
      if (m_ncalls == null) m_ncalls = new NMethod[m_methodRefs.size()];
      NMethod x = m_ncalls[index];
      if (x == null)
      {
        int[] m = methodRef(index).val;
        string parent = nname(m[0]);
        string mName = /*NameUtil.Upper(*/name(m[1]);/*);*/
        bool onObj = parent == "Fan.Sys.Obj";
        string[] pars = new string[m.Length-3];
        for (int i=0; i<pars.Length; i++) pars[i] = nname(m[i+3]);

        // static methods on sys::Obj are really FanObj
        if (onObj && (opcode == FConst.CallStatic || opcode == FConst.CallNonVirtual))
        {
          parent = "Fan.Sys.FanObj";
        }

        string ret = nname(m[2]);
        if (opcode == FConst.CallNew) ret = parent; // factory

        // Handle static mixin calls
        if (opcode == FConst.CallMixinStatic) parent += "_";

        x = new NMethod();
        x.parentType = parent;
        x.methodName = mName;
        x.returnType = ret;
        x.paramTypes = pars;
        if (!onObj) m_ncalls[index] = x;
      }
      return x;
    }

    public class NField
    {
      public string parentType;
      public string fieldName;
      public string fieldType;
    }

    /// <summary>
    /// Map a fcode field signature to a .NET field emit signature.
    /// </summary>
    public NField nfield(int index, bool mixin)
    {
      if (m_nfields == null) m_nfields = new NField[m_fieldRefs.size()];
      NField nfield = m_nfields[index];
      if (nfield == null)
      {
        int[] v = fieldRef(index).val;
        nfield = new NField();
        nfield.parentType = nname(v[0]);
        nfield.fieldName  = "m_" + name(v[1]);
        nfield.fieldType  = nname(v[2]);
        // TODO - put in map???
      }
      return nfield;
    }

    /// <summary>
    /// Map a .NET type name (:: replaced wit .) via typeRefs table.
    /// <summary>
    public string nname(int index)
    {
      if (m_nnames == null) m_nnames = new string[m_typeRefs.size()];
      string n = m_nnames[index];
      if (n == null)
      {
        FTypeRef refer = typeRef(index);
        n = m_nnames[index] = "Fan." + NameUtil.upper(name(refer.podName)) + '.' + name(refer.typeName);
      }
      return n;
    }

  //////////////////////////////////////////////////////////////////////////
  // Read
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Read from a FStore which provides random access.
    /// </summary>
    public void read()
    {
      m_names.read(m_store.read("names.def", true));
      m_typeRefs.read(m_store.read("typeRefs.def"));
      m_fieldRefs.read(m_store.read("fieldRefs.def"));
      m_methodRefs.read(m_store.read("methodRefs.def"));

      // pod meta
      readPodMeta(m_store.read("pod.def", true));

      // type meta
      readTypeMeta(m_store.read("types.def", true));

      // full fcode always lazy loaded in Type.reflect()
    }

    /// <summary>
    /// Read the literal constant tables (if not already loaded).
    /// </summary>
    public FLiterals readLiterals()
    {
      if (m_literals == null)
        m_literals = new FLiterals(this).read();
      return m_literals;
    }

    /// <summary>
    /// Read from an input stream (used for loading scripts from memory)
    /// </summary>
    public void readFully(ZipInputStream zip)
    {
      FStore.Input ins = new ReadFullyInput(this, zip);
      ZipEntry entry;
      m_literals = new FLiterals(this);
      while ((entry = zip.GetNextEntry()) != null)
      {
        string name = entry.Name;

        if (name == "names.def") m_names.read(ins);
        else if (name == "typeRefs.def") m_typeRefs.read(ins);
        else if (name == "fieldRefs.def") m_fieldRefs.read(ins);
        else if (name == "methodRefs.def") m_methodRefs.read(ins);
        else if (name == "pod.def") readPodMeta(ins);
        else if (name == "types.def") readTypeMeta(ins);
        else if (name.EndsWith(".fcode")) readType(name, ins);
        else if (name == "ints.def") m_literals.m_ints.read(ins);
        else if (name == "floats.def") m_literals.m_floats.read(ins);
        else if (name == "decimals.def") m_literals.m_decimals.read(ins);
        else if (name == "strs.def") m_literals.m_strs.read(ins);
        else if (name == "durations.def") m_literals.m_durations.read(ins);
        else if (name == "uris.def") m_literals.m_uris.read(ins);
        else System.Console.WriteLine("WARNING: unexpected file in pod: " + name);
      }
    }

    internal class ReadFullyInput : FStore.Input
    {
      public ReadFullyInput(FPod fpod, ZipInputStream zip) : base(fpod, zip) { this.zip = zip; }
      public override void Close() { zip.CloseEntry(); }
      ZipInputStream zip;
    };

    private void readPodMeta(FStore.Input input)
    {
      if (input.u4() != 0x0FC0DE05)
        throw new System.IO.IOException("Invalid magic");

      int version = input.u4();
      if (version != FConst.FCodeVersion)
        throw new System.IO.IOException("Invalid version 0x" + version.ToString("X").ToLower());
      this.m_version = version;

      m_podName = input.utf();
      m_podVersion = input.utf();
      m_depends = new Depend[input.u1()];
      for (int i=0; i<m_depends.Length; ++i)
        m_depends[i] = Depend.fromStr(Str.make(input.utf()));

      m_attrs = FAttrs.read(input);

      input.Close();
    }

    private void readTypeMeta(FStore.Input input)
    {
      m_types = new FType[input.u2()];
      for (int i=0; i<m_types.Length; i++)
      {
        m_types[i] = new FType(this).readMeta(input);
        m_types[i].m_hollow = true;
      }
      input.Close();
    }

    private void readType(string name, FStore.Input input)
    {
      if (m_types == null || m_types.Length == 0)
        throw new System.IO.IOException("types.def must be defined first");

      string typeName = name.Substring(0, name.Length-".fcode".Length);
      for (int i=0; i<m_types.Length; ++i)
      {
        string n = this.name(typeRef(m_types[i].m_self).typeName);
        if (n == typeName) { m_types[i].read(input); return; }
      }

      throw new System.IO.IOException("Unexpected fcode file: " + name);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public string m_podName;      // pod's unique name
    public string m_podVersion;   // pod version
    public Depend[] m_depends;    // pod dependencies
    public FAttrs m_attrs;        // pod attributes
    public FStore m_store;        // store we using to read
    public int m_version;         // fcode format version
    public FType[] m_types;       // pod's declared types
    public FTable m_names;        // identifier names: foo
    public FTable m_typeRefs;     // types refs:   [pod,type,variances*]
    public FTable m_fieldRefs;    // fields refs:  [parent,name,type]
    public FTable m_methodRefs;   // methods refs: [parent,name,ret,params*]
    public FLiterals m_literals;  // literal constants (on read fully or lazy load)
    private string[] m_nnames;    // cached fan typeRef   -> .net name
    private NMethod[] m_ncalls;   // cached fan methodRef -> .net method signatures
    private NField[] m_nfields;   // cached fan fieldRef  -> .net field signatures
  }
}