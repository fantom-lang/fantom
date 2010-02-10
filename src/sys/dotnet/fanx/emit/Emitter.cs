//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Sep 06  Andy Frank  Creation
//

using System;
using System.Collections;
using System.IO;
using PERWAPI;
using Fanx.Util;

namespace Fanx.Emit
{
  /// <summary>
  /// Emitter.
  /// </summary>
  public class Emitter
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Convenience for init().
    /// </summary>
public Emitter(string assemblyName) : this(assemblyName, null) {}
    public Emitter(string assemblyName, string stubFileName)
    {
      init(assemblyName, stubFileName);
    }

    /// <summary>
    /// Uninitialized Emitter - must call init().
    /// </summary>
    public Emitter() {}

    /// <summary>
    /// Initialize an Emitter to generate types for an assembly
    /// with the given name.
    /// </summary>
public void init(string assemblyName) { init(assemblyName, null); } // TODO
    public void init(string assemblyName, string stubName)
    {
      this.assemblyName = assemblyName;
      if (stubName == null)
      {
        string libPath = Fan.Sys.Sys.m_homeDir + "/lib/tmp";
        if (!Directory.Exists(libPath))
          Directory.CreateDirectory(libPath);
        this.fileName = libPath + "/" +  assemblyName + ".dll";
      }
      else
      {
        this.fileName = stubName;
        this.stubFileName = stubName;
      }
      peFile = new PEFile(fileName, assemblyName);
      if (!debug && !cache)
      {
        // Normally we have to write the dll to disk in order to get
        // the .pdb file.  But if we don't need that, we can just
        // generate the whole assembly in memory
        buf = new MemoryStream(4096);
        peFile.SetOutputStream(buf);
      }
    }

    /// <summary>
    /// Commit the current definition to the PE file.
    /// </summary>
    public byte[] commit()
    {
      if (stub)
      {
        peFile.WritePEFile(false);
        return null;
      }
      else if (debug)
      {
        // if the file already exists, we'll just assume that
        // file is valid, and reuse it - this can occur when
        // multiple processes are running fan
        if (!File.Exists(fileName))
        {
          peFile.MakeDebuggable(true, true);
          peFile.WritePEFile(true);
        }
        return null;
      }
      else if (cache)
      {
        // if the file already exists, we'll just assume that
        // file is valid, and reuse it - this can occur when
        // multiple processes are running fan
        if (!File.Exists(fileName)) peFile.WritePEFile(false);
        return null;
      }
      else
      {
        peFile.WritePEFile(false);
        return (buf as MemoryStream).ToArray();
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Define a new class to emit for this assembly. This class
    /// becomes the 'current' class, where subsequent EmitMethod
    /// and EmitField calls will popuate this class.
    /// </summary>
    public void emitClass(string baseQName, string qname, string[] interfaces, TypeAttr attr)
    {
      string[] s = FanUtil.splitQName(qname);
      className = qname;

      // first check if this type was already stubbed out
      classDef = (ClassDef)types[qname];
      if (classDef == null)
      {
        // if not, we need to create it
        if (qname.IndexOf("/") != -1)
        {
          // Nested class
          PERWAPI.ClassDef cdef = (PERWAPI.ClassDef)findType(s[0]);
          classDef = cdef.AddNestedClass(attr, s[1]);
        }
        else
        {
          // Normal class
          classDef = peFile.AddClass(attr, s[0], s[1]);
        }
      }
      else
      {
        // if stubbed out, make sure we define the type correctly
        classDef.SetAttribute(attr);
      }

      // base class
      if (baseQName == null)
        classDef.SuperType = null;
      else
        classDef.SuperType = findType(baseQName) as PERWAPI.Class;

      // interfaces
      for (int i=0; i<interfaces.Length; i++)
        classDef.AddImplementedInterface(findType(interfaces[i]) as PERWAPI.Class);

      types[qname] = classDef;
    }

    /// <summary>
    /// Define a new field to emit for the current class.
    /// </summary>
    public void emitField(string name, string type, FieldAttr attr)
    {
      string key = className + "/F" + name;
      FieldDef fieldDef = (FieldDef)fields[key];
      if (fieldDef == null)
      {
        // only add if not already stubbed out
        fields[key] = classDef.AddField(attr, name, findType(type));
      }
      else
      {
        // is stubbed out, make sure we define field correctly
        fieldDef.SetFieldAttr(attr);
      }
    }

    /// <summary>
    /// Define a new method to emit for the current class.
    /// </summary>
    public CILInstructions emitMethod(
      string name, string retType, string[] paramNames, string[] paramTypes,
      MethAttr attr, string[] localNames, string[] localTypes)
    {
      Param[] pars = new Param[paramNames.Length];
      for (int i=0; i<pars.Length; i++)
        pars[i] = new Param(ParamAttr.Default, paramNames[i], findType(paramTypes[i]));

      // first check if this method was already stubbed out
      methodDef = (MethodDef)methods[getMethodKey(className, name, paramTypes)];
      if (methodDef == null)
      {
        // if not, we need to create it
        methodDef = classDef.AddMethod(attr, ImplAttr.IL, name, findType(retType), pars);
      }
      else
      {
        // if stubbed out, make sure we define the method correctly
        methodDef.SetMethAttributes(attr);
      }

      if ((attr & MethAttr.Static) != MethAttr.Static)
        methodDef.AddCallConv(CallConv.Instance);

      if (localNames.Length > 0)
      {
        Local[] locals = new Local[localNames.Length];
        for (int i=0; i<locals.Length; i++)
          locals[i] = new Local(localNames[i], findType(localTypes[i]));
        methodDef.AddLocals(locals, true);
      }

      // TODO - what the fuck should this be?
      methodDef.SetMaxStack(16 + pars.Length + localNames.Length);

      // add to lookup table
      addToMethodMap(className, name, paramTypes, methodDef);

      // don't create code buffer if abstract
      if ((attr & MethAttr.Abstract) == MethAttr.Abstract)
        return null;

      return methodDef.CreateCodeBuffer();
    }

    /// <summary>
    /// Add a MethodDef into the lookup table.
    /// </summary>
    public void addToMethodMap(string className, string name, string[] paramTypes, MethodDef def)
    {
      string key = getMethodKey(className, name, paramTypes);
      methods[key] = def;
    }

  //////////////////////////////////////////////////////////////////////////
  // Util
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Find the Type instance for this fully qualified type name.
    /// </summary>
    internal PERWAPI.Type findType(string qname)
    {
      // Always convert voids to native
      if (qname == "Fan.Sys.Void") qname = "System.Void";

      PERWAPI.Type type = (PERWAPI.Type)types[qname];
      if (type == null)
      {
        string aname = FanUtil.getPodName(qname);
        if (aname == null) aname = "mscorlib";
        if (qname.StartsWith("Fanx.")) aname = "sys";    // hack for support classes
        if (qname.EndsWith("Peer")) aname += "Native_";  // TODO

        // first check if this is a type in this pod that
        // hasn't been defined yet
        if (aname == assemblyName)
        {
          // stub out type - fill get filled in later (we hope)
          string[] sn = FanUtil.splitQName(qname);
          ClassDef stub = null;
          if (qname.IndexOf("/") != -1)
          {
            // Nested class
            PERWAPI.ClassDef cdef = (PERWAPI.ClassDef)findType(sn[0]);
            stub = cdef.AddNestedClass(PERWAPI.TypeAttr.NestedPublic, sn[1]);
          }
          else
          {
            // Normal class
            stub = peFile.AddClass(PERWAPI.TypeAttr.Public, sn[0], sn[1]);
          }
          types[qname] = stub;
          return stub;
        }

        AssemblyRef aref = (AssemblyRef)assemblies[aname];
        if (aref == null)
        {
          aref = peFile.MakeExternAssembly(aname);
          assemblies[aname] = aref;
        }

        string[] s = FanUtil.splitQName(qname);
        if (qname.IndexOf("/") != -1)
        {
          // Nested class
          PERWAPI.ClassRef cref = (PERWAPI.ClassRef)findType(s[0]);
          type = cref.AddNestedClass(s[1]);
        }
        /*
        else if (qname.IndexOf("<") != -1)
        {
          // Generic type
          //if (type == null) type = aref.AddClass(s[0], s[1]);
          PERWAPI.ClassRef cref = (PERWAPI.ClassRef)findType(s[0]);
          cref.SetGenericParams(new GenericParam[] { cref.GetGenericParam(0) });
          type = cref;
        }
        */
        else
        {
          // Normal class, get/add type
          type = aref.GetClass(s[0], s[1]);
          if (type == null) type = aref.AddClass(s[0], s[1]);
        }
        types[qname] = type;
      }
      return type;
    }

    /// <summary>
    /// Find the Field for this field on the given type.
    /// </summary>
    internal Field findField(string qname, string fieldName, string fieldType)
    {
      string key = qname + "/F" + fieldName;
      Field field = (Field)fields[key];
      if (field == null)
      {
        // should be same for both cases
        PERWAPI.Type ftype = findType(fieldType);

        // check for stubs
        object obj = findType(qname);
        if (obj is ClassDef)
        {
          // class is an internal stub, so we need to stub this field
          // out too, which is actually complete and not a stub
          ClassDef cdef = obj as ClassDef;

          // TODO - fix attr
          field = cdef.AddField(FieldAttr.Public, fieldName, ftype);
        }
        else if (obj is ClassRef)
        {
          // class is external, just get or add ref
          ClassRef cref = obj as ClassRef;
          field = cref.GetField(fieldName);
          if (field == null) field = cref.AddField(fieldName, ftype);
        }
        else throw new System.Exception("Don't know how to handle: " + obj.GetType());

        // remember to add field to lookup table
        fields[key] = field;
      }
      return field;
    }

    /// <summary>
    /// Find the Method for this method on the given type.
    /// </summary>
    internal Method findMethod(string qname, string methodName, string[] paramTypes, string returnType)
    {
      string key = getMethodKey(qname, methodName, paramTypes);
      Method method = (Method)methods[key];

      if (method == null)
      {
        // this stuff should be the same for both cases
        PERWAPI.Type rtype = findType(returnType);
        PERWAPI.Type[] pars = new PERWAPI.Type[paramTypes.Length];
        for (int i=0; i<paramTypes.Length; i++)
          pars[i] = findType(paramTypes[i]);

        // check for stubs
        object obj = findType(qname);
        if (obj is ClassDef)
        {
          // class is an internal stub, so we need to stub this
          // method out too, which should get flushed out later
          ClassDef cdef = obj as ClassDef;

          // TODO - need to fix attrs
          Param[] mpars = new Param[pars.Length];
          for (int i=0; i<mpars.Length; i++)
            mpars[i] = new Param(ParamAttr.Default, "v"+i, pars[i]);

          // TODO - fix param names
          // Use Public here for stub - real MethAttr will be set
          // when method is flushed out
          method = cdef.AddMethod(MethAttr.Public, ImplAttr.IL, methodName, rtype, mpars);
        }
        else if (obj is ClassRef)
        {
          // class is external, just get or add ref
          ClassRef cref = obj as ClassRef;
          method = cref.GetMethod(methodName, pars, new PERWAPI.Type[0]);
          if (method == null) method = cref.AddMethod(methodName, rtype, pars);
        }
        else throw new System.Exception("Don't know how to handle: " + obj.GetType());

        // make sure we add method to hashtable
        methods[key] = method;
      }

      return method;
    }

    /// <summary>
    /// Return the key for this method in the method lookup table.
    /// </summary>
    internal string getMethodKey(string qname, string methodName, string[] paramTypes)
    {
      string key = qname + "/M" + methodName;
       for (int i=0; i<paramTypes.Length; i++)
        key += "/" + paramTypes[i];
      return key;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public bool stub { get { return stubFileName != null; }}  // in stub mode?
    internal string stubFileName = null;                      // stub filename

    private bool cache = true;    // is assembly cached to disk?
    private bool debug = false;   // is emitter in debug mode?

    private string assemblyName;  // name of this assbemly
    internal string fileName;     // filename of assembly
    private MemoryStream buf;     // memory buffer for pe file
    private PEFile peFile;        // model for pe file

    private string className;     // the current class name being emitted
    internal ClassDef classDef;   // the current class being emitted
    internal MethodDef methodDef; // the current or last method emitted

    private Hashtable assemblies = new Hashtable();  // Assembly lookup table
    private Hashtable types = new Hashtable();       // Type lookup table
    private Hashtable fields = new Hashtable();      // Field lookup table
    private Hashtable methods = new Hashtable();     // Method lookup table
  }
}