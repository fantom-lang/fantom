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

    public FPod(string podName, FStore store)
    {
      if (store != null) store.fpod = this;
      this.m_podName    = podName;
      this.m_store      = store;
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
        if (typeRef(m_types[i].m_self).typeName == nameToFind)
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
      if (x == null || opcode == FConst.CallNonVirtual) // don't use cache on nonvirt (see below)
      {
        int[] m = methodRef(index).val;
        string type  = nname(m[0]);
        string mName = name(m[1]);

        // if the type signature is java/lang then we route
        // to static methods on FanObj, FanFloat, etc
        string impl = FanUtil.toDotnetImplTypeName(type);
        bool explicitSelf = false;
        bool isStatic = false;
        if (type != impl)
        {
          explicitSelf = opcode == FConst.CallVirtual;
          isStatic = explicitSelf;
        }
        else
        {
          // if no object method than ok to use cache
          if (x != null) return x;
        }

        // equals => Equals
        if (!explicitSelf)
          mName = FanUtil.toDotnetMethodName(mName);

        string[] pars;
        if (explicitSelf)
        {
          pars = new string[m.Length-2];
          pars[0] = type;
          for (int i=1; i<pars.Length; i++) pars[i] = nname(m[i+2]);
        }
        else
        {
          pars = new string[m.Length-3];
          for (int i=0; i<pars.Length; i++) pars[i] = nname(m[i+3]);
        }

        string ret = nname(m[2]);
        if (opcode == FConst.CallNew) ret = type; // factory

        // Handle static mixin calls
        if (opcode == FConst.CallMixinStatic) impl += "_";

        x = new NMethod();
        x.parentType = impl;
        x.methodName = mName;
        x.returnType = ret;
        x.paramTypes = pars;
        x.isStatic   = isStatic;

        // we don't cache nonvirtuals on Obj b/c of conflicting signatures:
        // - CallVirtual: Obj.toStr => static FanObj.toStr(Object)
        // - CallNonVirtual: Obj.toStr => FanObj.toStr()
        if (type == impl || opcode != FConst.CallNonVirtual)
          m_ncalls[index] = x;
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
        nfield.parentType = FanUtil.toDotnetImplTypeName(nname(v[0]));
        nfield.fieldName  = "m_" + name(v[1]);
        nfield.fieldType  = nname(v[2]);
        m_nfields[index] = nfield;
      }
      return nfield;
    }

    /// <summary>
    /// Map a .NET type name (:: replaced wit .) via typeRefs table.
    /// <summary>
    public string nname(int index)
    {
      return typeRef(index).nname();
    }

  //////////////////////////////////////////////////////////////////////////
  // Read
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Read from a FStore which provides random access.
    /// </summary>
    public void read()
    {
      // pod meta
      readPodMeta(m_store.read("meta.props", true));

      m_names.read(m_store.read("fcode/names.def", true));
      m_typeRefs.read(m_store.read("fcode/typeRefs.def"));
      m_fieldRefs.read(m_store.read("fcode/fieldRefs.def"));
      m_methodRefs.read(m_store.read("fcode/methodRefs.def"));

      // type meta
      readTypeMeta(m_store.read("fcode/types.def", true));

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
      // handle sys bootstrap specially using just java.util.Properties
      string metaName;
      if ("sys" == m_podName)
      {
        Properties props = new Properties();
        props.load(input);
        input.Close();
        metaName =  props.getProperty("pod.name");
        m_podVersion = props.getProperty("pod.version");
        m_fcodeVersion = props.getProperty("fcode.version");
        m_depends = new Depend[0];
        return;
      }
      else
      {
        SysInStream sysIn = new SysInStream(input);
        this.m_meta = (Map)sysIn.readProps().toImmutable();
        sysIn.close();

        metaName = meta("pod.name");
        m_podVersion = meta("pod.version");

        m_fcodeVersion = meta("fcode.version");
        string dependsStr = meta("pod.depends").Trim();
        if (dependsStr.Length == 0) m_depends = new Depend[0];
        else
        {
          string[] toks = dependsStr.Split(';');
          m_depends = new Depend[toks.Length];
          for (int i=0; i<m_depends.Length; ++i) m_depends[i] = Depend.fromStr(toks[i].Trim());
        }
      }

      // check meta name matches podName passed to ctor
      if (m_podName == null) m_podName = metaName;
      if (m_podName != metaName)
        throw new System.IO.IOException("Pod name mismatch " + m_podName + " != " + metaName);

      // sanity checking
      if (FConst.FCodeVersion != m_fcodeVersion)
        throw new System.IO.IOException("Invalid fcode version " + m_fcodeVersion);
    }

    private string meta(string key)
    {
      string val = (string)m_meta.get(key);
      if (val == null) throw new System.IO.IOException("meta.prop missing " + key);
      return val;
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
        string n = typeRef(m_types[i].m_self).typeName;
        if (n == typeName) { m_types[i].read(input); return; }
      }

      throw new System.IO.IOException("Unexpected fcode file: " + name);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public string m_podName;       // pod's unique name
    public string m_podVersion;    // pod version
    public Depend[] m_depends;     // pod dependencies
    public string m_fcodeVersion;  // fcode format version
    public Map m_meta;             // meta Str:Str map
    public FStore m_store;        // store we using to read
    public FType[] m_types;       // pod's declared types
    public FTable m_names;        // identifier names: foo
    public FTable m_typeRefs;     // types refs:   [pod,type,variances*]
    public FTable m_fieldRefs;    // fields refs:  [parent,name,type]
    public FTable m_methodRefs;   // methods refs: [parent,name,ret,params*]
    public FLiterals m_literals;  // literal constants (on read fully or lazy load)
    private NMethod[] m_ncalls;   // cached fan methodRef -> .NET method signatures
    private NField[] m_nfields;   // cached fan fieldRef  -> .NET field signatures
  }
}