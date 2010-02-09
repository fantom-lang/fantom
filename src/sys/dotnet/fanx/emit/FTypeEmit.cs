//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Oct 06  Andy Frank  Creation
//

using System.Collections;
using System.IO;
using System.Reflection;
using ICSharpCode.SharpZipLib.Zip;
using Fan.Sys;
using Fanx.Fcode;
using Fanx.Util;

namespace Fanx.Emit
{
  /// <summary>
  /// FTypeEmit translates FType fcode to IL.
  /// </summary>
  public abstract class FTypeEmit
  {

  //////////////////////////////////////////////////////////////////////////
  // Factory
  //////////////////////////////////////////////////////////////////////////

    public static System.Type[] emitAndLoad(FType ftype)
    {
      string className = ftype.m_pod.nname(ftype.m_self);
      Assembly assembly = emitPod(ftype.m_pod, true, null);

      FTypeEmit[] emitted = (FTypeEmit[])ftypes[ftype];
      System.Type[] types = new System.Type[emitted.Length];
      for (int i=0; i<emitted.Length; i++)
      {
        FTypeEmit e = emitted[i];
        types[i] = assembly.GetType(e.className);
      }

      return types;
    }

    public static Assembly emitPod(FPod pod, bool load, string path)
    {
      string podName = pod.m_podName;
      Assembly assembly = (Assembly)assemblies[podName];
      if (assembly == null)
      {
        Emitter emitter = new Emitter(podName, path);

        // unzip the native.dll if one exists
        unzipToTemp(pod, podName + "Native_.dll");
        unzipToTemp(pod, podName + "Native_.pdb");

        // emit the pod class itself (which declares all constants)
        //FPodEmit.EmitAndLoad(emitter, pod);
        FPodEmit.emit(emitter, pod);

        // the Emitter needs base types to be defined before
        // descendant types, so make sure everything gets stubbed
        // out in the correct order ahead of time
        for (int i=0; i<pod.m_types.Length; i++)
          emitter.findType(pod.nname(pod.m_types[i].m_self));

        // emit all the rest of the types in this pod
        for (int i=0; i<pod.m_types.Length; i++)
        {
          FType ftype = pod.m_types[i];
          FTypeRef tref = ftype.m_pod.typeRef(ftype.m_self);
          Type parent = Type.find(tref.podName+"::"+tref.typeName, true);

          // make sure we have reflected to setup slots
          parent.reflect();

          // route based on type
          if ((ftype.m_flags & FConst.Mixin) != 0)
          {
            // interface
            FMixinInterfaceEmit iemit = new FMixinInterfaceEmit(emitter, parent, ftype);
            iemit.emit();

            // body class
            FMixinBodyEmit bemit = new FMixinBodyEmit(emitter, parent, ftype);
            bemit.emit();

            ftypes[ftype] = new FTypeEmit[] { iemit, bemit };
          }
          else if (parent.@is(Sys.ErrType))
          {
            // error
            FErrEmit emitErr = new FErrEmit(emitter, parent, ftype);
            emitErr.emit();

            FErrValEmit emitErrVal = new FErrValEmit(emitter, parent, ftype);
            emitErrVal.emit();

            ftypes[ftype] = new FTypeEmit[] { emitErr, emitErrVal };
          }
          else
          {
            // class
            FClassEmit emit = new FClassEmit(emitter, parent, ftype);
            emit.emit();
            ftypes[ftype] = new FTypeEmit[] { emit };
          }
        }

        // commit assembly
        byte[] buf = emitter.commit();
        if (load)
        {
          //long start = System.Environment.TickCount;

          // load assembly
          assembly = (buf == null)
            ? Assembly.LoadFile(emitter.fileName)
            : Assembly.Load(buf);
          assemblies[podName] = assembly;

          //long end = System.Environment.TickCount;
          //System.Console.WriteLine("load " + podName + " in " + (end-start) + " ms");

          // load $Pod type
          FPodEmit.load(assembly, pod);
        }
      }
      return assembly;
    }

    /// <summary>
    /// Unzip the file if it exists into the lib/tmp dir
    /// </summary>
    static void unzipToTemp(FPod pod, string filename)
    {
      if (pod.m_store == null) return; // compiled from script
      ZipEntry entry = pod.m_store.zipFile.GetEntry(filename);
      if (entry == null) return;

      BufferedStream fin = new BufferedStream(pod.m_store.zipFile.GetInputStream(entry));
      FileStream fout = System.IO.File.Create(
        FileUtil.combine(Fan.Sys.Sys.m_homeDir, "lib", "tmp", filename));

      byte[] b = new byte[4096];
      while (true)
      {
        int r = fin.Read(b, 0, b.Length);
        if (r <= 0) break;
        fout.Write(b, 0, r);
      }

      fout.Flush();
      fin.Close();
      fout.Close();
    }

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    protected FTypeEmit(Emitter emitter, Type parent, FType type)
    {
      this.emitter = emitter;
      this.parent  = parent;
      this.pod     = type.m_pod;
      this.type    = type;
    }

    /// <summary>
    /// Initialize an Emitter to generate a class with given name,
    /// super class, interfaces, and class level access flags.
    /// <summary>
    public void init(string thisClass, string baseClass, string[] interfaces, int flags)
    {
      this.className = thisClass;
      this.baseClassName = baseClass;
      this.interfaces = interfaces;
      //this.cp.add(new CpDummy());  // dummy entry since constant pool starts at 1
      //this.thisClassIndex  = cls(thisClass);
      //this.superClassIndex = cls(superClass);
      //this.interfaces = new int[interfaces.length];
      //for (int i=0; i<interfaces.length; ++i)
      //  this.interfaces[i] = cls(interfaces[i]);
      //this.flags = flags;
      this.isAbstract = (flags & FConst.Abstract) != 0;
    }

  //////////////////////////////////////////////////////////////////////////
  // Emit
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Return true if this pod has already been emitted.
    /// </summary>
    public static bool isEmitted(string podName)
    {
      return assemblies[podName] != null;
    }

    /// <summary>
    /// Emit to IL assembly.
    /// </summary>
    public virtual void emit()
    {
      init(nname(type.m_self), @base(), mixins(), type.m_flags);
      this.selfName = className;

      // make sure type has been read
      if (type.m_hollow) type.read();

      // emit
      preview();
      emitType();
      for (int i=0; i<type.m_fields.Length;  i++) emit(type.m_fields[i]);
      for (int i=0; i<type.m_methods.Length; i++) emit(type.m_methods[i]);
      emitAttributes(type.m_attrs);
      emitMixinRouters();
      if (!hasInstanceInit) emitInstanceInit(null);
      if (!hasStaticInit) emitStaticInit(null);
      emitTypeConstFields();
    }

    /// <summary>
    /// Return the base type for this type.
    /// </summary>
    protected abstract string @base();

    protected virtual string[] mixins()
    {
      string[] mixins = new string[type.m_mixins.Length];
      for (int i=0; i<mixins.Length; i++)
        mixins[i] = nname(type.m_mixins[i]);
      return mixins;
    }

    private void preview()
    {
      this.isNative = (type.m_flags & FConst.Native) != 0;
      if (!this.isNative)
      {
        for (int i=0; i<type.m_methods.Length; ++i)
          if ((type.m_methods[i].m_flags & FConst.Native) != 0)
            { this.isNative = true; break; }
      }
    }

    /// <summary>
    /// Emit the type information for this type.
    /// </summary>
    protected abstract void emitType();

    /// <summary>
    /// Emit a attribute.
    /// </summary>
    private void emitAttributes(FAttrs attrs)
    {
      //if (attrs.sourceFile != null)
      //{
      //  AttrEmit attr = emitAttr("SourceFile");
      //  attr.info.u2(utf(attrs.sourceFile));
      //}
    }

    /// <summary>
    /// Emit a field.
    /// </summary>
    protected virtual void emit(FField f)
    {
      if ((f.m_flags & FConst.Storage) != 0)
        emitter.emitField("m_" + f.m_name, nname(f.m_type), fieldFlags(f.m_flags));
    }

    /// <summary>
    /// Emit a method.
    /// </summary>
    protected virtual void emit(FMethod m)
    {
      string n = m.m_name;
      bool isNative = (m.m_flags & FConst.Native) != 0;
      bool isCtor   = (m.m_flags & FConst.Ctor)   != 0;

      // static$init -> .cctor
      // instance$init -> .ctor
      if (n == "static$init")   { emitStaticInit(m); return; }
      if (n == "instance$init") { emitInstanceInit(m); return; }

      // handle native/constructor/normal method
      if (isNative)
      {
        new FMethodEmit(this, m).emitNative();
      }
      else if (isCtor)
      {
        new FMethodEmit(this, m).emitCtor();
      }
      else
      {
        new FMethodEmit(this, m).emitStandard();
      }
    }

    protected virtual void emitInstanceInit(FMethod m)
    {
      hasInstanceInit = true;
      PERWAPI.CILInstructions code = ctor.CreateCodeBuffer();

      // initalize code to call super
      code.Inst(PERWAPI.Op.ldarg_0);

      // if closure, push FuncType static field
      if (funcType != null)
      {
        code.FieldInst(PERWAPI.FieldOp.ldsfld, typeField);
        PERWAPI.Method baseCtor = emitter.findMethod(baseClassName, ".ctor",
          new string[] { "Fan.Sys.FuncType" }, "System.Void");
        baseCtor.AddCallConv(PERWAPI.CallConv.Instance); // if stub, make sure instance callconv
        code.MethInst(PERWAPI.MethodOp.call, baseCtor);
      }
      else
      {
        PERWAPI.Method baseCtor = emitter.findMethod(baseClassName, ".ctor",
          new string[0], "System.Void");
        baseCtor.AddCallConv(PERWAPI.CallConv.Instance); // if stub, make sure instance callconv
        code.MethInst(PERWAPI.MethodOp.call, baseCtor);
      }

      // make peer
      if (isNative)
      {
        //code.op(ALOAD_0);  // for putfield
        //code.op(DUP);      // for arg to make
        //code.op2(INVOKESTATIC, method(selfName + "Peer.make(L" + className + ";)L" + className + "Peer;"));
        //code.op2(PUTFIELD, peerField.ref());

        code.Inst(PERWAPI.Op.ldarg_0);
        code.Inst(PERWAPI.Op.dup);
        PERWAPI.Method peerMake = emitter.findMethod(className + "Peer", "make",
          new string[] { className }, className + "Peer");
        code.MethInst(PERWAPI.MethodOp.call, peerMake);
        code.FieldInst(PERWAPI.FieldOp.stfld, peerField);
      }

      if (m == null)
        code.Inst(PERWAPI.Op.ret);
      else
        new FCodeEmit(this, m, code).emit();
    }

    internal void emitStaticInit(FMethod m)
    {
      // make sure we add local defs
      if (m != null && m.m_localCount > 0)
      {
        PERWAPI.Local[] locals = new PERWAPI.Local[m.m_vars.Length];
        for (int i=0; i<locals.Length; i++)
        {
          string name = m.m_vars[i].name;
          string type = nname(m.m_vars[i].type);
          locals[i] = new PERWAPI.Local(name, emitter.findType(type));
        }
        cctor.AddLocals(locals, true);
      }

      hasStaticInit = true;
      PERWAPI.CILInstructions code = cctor.CreateCodeBuffer();

      // set $Type field with type (if we this is a closure,
      // then the FuncType will be the type exposed)
      if (!parent.isMixin())
      {
        Type t = parent;
        if (parent.@base() is FuncType) t = parent.@base();

        code.ldstr(t.signature());
        PERWAPI.Method findType = emitter.findMethod("Fan.Sys.Type", "find",
          new string[] { "System.String" }, "Fan.Sys.Type");
        code.MethInst(PERWAPI.MethodOp.call, findType);
        code.FieldInst(PERWAPI.FieldOp.stsfld, typeField);
      }

      if (m == null)
        code.Inst(PERWAPI.Op.ret);
      else
        new FCodeEmit(this, m, code).emit();
    }

    internal void emitTypeConstFields()
    {
      // if during the emitting of all the methods we ran across a non-sys
      // LoadType opcode, then we need to generate a static field called
      // type${pod}${name} we can use to cache the type once it is looked up
//      if (typeLiteralFields == null) return;
//      Iterator it = typeLiteralFields.values().iterator();
//      while (it.hasNext())
//      {
//        String fieldName = (String)it.next();
//        emitField(fieldName, "Lfan/sys/Type;", EmitConst.PRIVATE|EmitConst.STATIC);
//      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Mixin Routers
  //////////////////////////////////////////////////////////////////////////

    private void emitMixinRouters()
    {
      // short circuit if no direct mixins implemented
      if (parent.mixins().isEmpty()) return;

      // first we have to find all the mixins I inherit thru my
      // direct mixin inheritances (but not my class extension) - these
      // are the ones I need routers for (but I can skip generating
      // routers for any mixins implemented by my super class)
      Hashtable acc = new Hashtable();
      findMixins(parent, acc);

      // emit routers for concrete instance methods
      IEnumerator en = acc.Values.GetEnumerator();
      while (en.MoveNext())
      {
        Type mixin = (Type)en.Current;
        emitMixinRouters(mixin);
      }
    }

    private void findMixins(Type t, Hashtable acc)
    {
      // if mixin I haven't seen add to accumulator
      string qname = t.qname();
      if (t.isMixin() && acc[qname] == null)
        acc[qname] = t;

      // recurse
      for (int i=0; i<t.mixins().sz(); ++i)
        findMixins((Type)t.mixins().get(i), acc);
    }

    private void emitMixinRouters(Type type)
    {
      // generate router method for each concrete instance method
      List methods = type.methods();
      for (int i=0; i<methods.sz(); i++)
      {
        Method m = (Method)methods.get(i);
        string name = m.name();

        // only emit router for non-abstract instance methods
        if (m.isStatic()) continue;
        if (m.isAbstract())
        {
          // however if abstract, check if a base class
          // has already implemented this method
          if (m.parent() == type && parent.slot(name, true).parent() == type)
          {
            Type b = parent.@base();
            while (b != null)
            {
              Slot s = b.slot(name, false);
              if (s != null && s.parent() == b)
              {
                new FMethodEmit(this).emitInterfaceRouter(b, m);
                break;
              }
              b = b.@base();
            }
          }
          continue;
        }

        // only emit the router unless this is the exact one I inherit
        if (parent.slot(name, true).parent() != type) continue;

        // do it
        new FMethodEmit(this).emitMixinRouter(m);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Map Fantom flags to .NET field flags.  Note we emit protected as
    /// public and internal/private as package-private so that we don't
    /// need to deal with scope issues for accessors like closures and
    /// helper classes.
    /// </summary>
    internal static PERWAPI.FieldAttr fieldFlags(int fflags)
    {
      /*
      PERWAPI.FieldAttr nflags = 0;
      if ((fflags & FConst.Private)   != 0) nflags |= PERWAPI.FieldAttr.Assembly;
      if ((fflags & FConst.Protected) != 0) nflags |= PERWAPI.FieldAttr.Public;
      if ((fflags & FConst.Public)    != 0) nflags |= PERWAPI.FieldAttr.Public;
      //if ((fflags & FConst.Internal)  != 0) nflags |= PERWAPI.FieldAttr.Assembly;
      if ((fflags & FConst.Static)    != 0) nflags |= PERWAPI.FieldAttr.Static;
      return nflags;
      */

      PERWAPI.FieldAttr nflags = PERWAPI.FieldAttr.Public;
      if ((fflags & FConst.Static)    != 0) nflags |= PERWAPI.FieldAttr.Static;
      return nflags;
    }

    /// <summary>
    /// Given a Fantom qname index, map to a .NET type name: sys/Bool
    /// </summary>
    internal string nname(int index)
    {
      return pod.nname(index);
    }

    /// <summary>
    /// Map a simple name index to it's string value
    /// </summary>
    internal string name(int index)
    {
      return pod.name(index);
    }

    /*
    /// <summary>
    /// Map a simple name index to it's string value
    /// </summary>
    internal string Name(int index)
    {
      return pod.Name(index);
    }

    /// <summary>
    /// Get method ref to sys::Sys.type(String, bool)
    /// </summary>
    internal int SysFindType()
    {
      if (sysFindType == 0)
        sysFindType = method("fan/sys/Sys.findType(Ljava/lang/String;Z)Lfan/sys/Type;");
      return sysFindType ;
    }
    private int sysFindType;
    */

  //////////////////////////////////////////////////////////////////////////
  // Cached CpInfo
  //////////////////////////////////////////////////////////////////////////

    internal PERWAPI.Method CompareSame;
    internal PERWAPI.Method CompareNotSame;
    internal PERWAPI.Method CompareNull;
    internal PERWAPI.Method CompareNotNull;
    internal PERWAPI.Method IsViaType;
    internal PERWAPI.Method IntVal;
    internal PERWAPI.Method ErrMake;
    internal PERWAPI.Field ErrVal;
    internal PERWAPI.Method TypeToNullable;
    internal PERWAPI.Method NullErrMakeCoerce;

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public string className;
    public string baseClassName;
    public string[] interfaces;

    internal PERWAPI.MethodDef ctor;   // cached .ctor emit object
    internal PERWAPI.MethodDef cctor;  // cahced .cctor emit object

    internal Emitter emitter;              // The emitter for the assembly for this type
    internal Type parent;
    internal FPod pod;
    internal FType type;
    internal string selfName;              // type name to use as self (for mixin body - this is interface)
    internal PERWAPI.Field typeField;      // private static final Type $Type
    internal PERWAPI.Field peerField = null;  // public static final TypePeer peer
    internal bool hasInstanceInit;         // true if we already emitted <init>
    internal bool hasStaticInit;           // true if we already emitted <clinit>
    internal FuncType funcType;            // if type is a closure
    internal Hashtable typeLiteralFields;  // signature Strings we need to turn into cached fields
    internal bool isNative = false;        // do we have any native methods requiring a peer
    internal bool isAbstract;              // are we emitting an abstract method

    private static Hashtable assemblies = new Hashtable();  // assembly cache
    private static Hashtable ftypes     = new Hashtable();  // ftype[] lookup

  }
}