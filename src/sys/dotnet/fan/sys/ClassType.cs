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
using System.Reflection;
using System.Runtime.CompilerServices;
using Fanx.Emit;
using Fanx.Fcode;
using Fanx.Serial;
using Fanx.Util;

namespace Fan.Sys
{
  /// <summary>
  /// ClassType models a static type definition for an Obj class:
  ///
  ///  1) Hollow: in this state we know basic identity of the type, and
  ///     it's inheritance hierarchy.  A type is setup to be hollow during
  ///     Pod.load().
  ///  2) Reflected: in this state we read all the slot definitions from the
  ///     fcode to populate the slot tables used to for reflection.  At this
  ///     point clients can discover the signatures of the Type.
  ///  3) Emitted: the final state of loading a Type is to emit to a .NET
  ///     class called "Fan.{pod}.{type}".  Once emitted we can instantiate
  ///     the type or call it's methods.
  ///  4) Finished: once we have reflected the slots into memory and emitted
  ///     the .NET class, the last stage is to bind the all the System.Reflection
  ///     representations to the Slots for dynamic dispatch.  We delay this
  ///     until needed by Method or Field for a reflection invocation
  /// </summary>
  public class ClassType : Type
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    internal ClassType(Pod pod, FType ftype)
    {
      this.m_pod      = pod;
      this.m_ftype    = ftype;
      this.m_name     = pod.fpod.typeRef(ftype.m_self).typeName;
      this.m_qname    = pod.m_name + "::" + m_name;
      this.m_nullable = new NullableType(this);
      this.m_flags    = ftype.m_flags;
      if (Debug) Console.WriteLine("-- init:   " + m_qname);
    }

    // parameterized type constructor
    public ClassType(Pod pod, string name, int flags, Facets facets)
    {
      this.m_pod      = pod;
      this.m_name     = name;
      this.m_qname    = pod.m_name + "::" + name;
      this.m_nullable = new NullableType(this);
      this.m_flags    = flags;
      this.m_facets   = facets;
    }

  //////////////////////////////////////////////////////////////////////////
  // Naming
  //////////////////////////////////////////////////////////////////////////

    public override Pod pod()   { return m_pod; }
    public override string name()  { return m_name; }
    public override string qname() { return m_qname; }
    public override string signature() { return m_qname; }

    public override sealed Type toNullable() { return m_nullable; }

  //////////////////////////////////////////////////////////////////////////
  // Flags
  //////////////////////////////////////////////////////////////////////////

    internal override int flags() { return m_flags; }

    public override object trap(string name, List args)
    {
      // private undocumented access
      if (name == "lineNumber") { reflect(); return Long.valueOf(m_lineNum); }
      if (name == "sourceFile") { reflect(); return m_sourceFile; }
      return base.trap(name, args);
    }

  //////////////////////////////////////////////////////////////////////////
  // Slots
  //////////////////////////////////////////////////////////////////////////

    public override sealed List fields()  { return ((ClassType)reflect()).m_fields.ro(); }
    public override sealed List methods() { return ((ClassType)reflect()).m_methods.ro(); }
    public override sealed List slots()   { return ((ClassType)reflect()).m_slots.ro(); }

    public override sealed Slot slot(string name, bool check)
    {
      Slot slot = (Slot)((ClassType)reflect()).m_slotsByName[name];
      if (slot != null) return slot;
      if (check) throw UnknownSlotErr.make(this.m_qname + "." + name).val;
      return null;
    }

    public override sealed object make(List args)
    {
      return base.make(args);
    }

  //////////////////////////////////////////////////////////////////////////
  // Inheritance
  //////////////////////////////////////////////////////////////////////////

    public override Type @base() { return m_base; }

    public override List mixins() { return m_mixins; }

    public override List inheritance()
    {
      if (m_inheritance == null)
      {
        Hashtable map = new Hashtable();
        List acc = new List(Sys.TypeType);

        // handle Void as a special case
        if (this == Sys.VoidType)
        {
          acc.add(this);
          return m_inheritance = acc.trim();
        }

        // add myself
        map[m_qname] = this;
        acc.add(this);

        // add my direct inheritance inheritance
        addInheritance(@base(), acc, map);
        List m = mixins();
        for (int i=0; i<m.sz(); i++)
          addInheritance((Type)m.get(i), acc, map);

        m_inheritance = acc.trim().ro();
      }
      return m_inheritance;
    }

    private void addInheritance(Type t, List acc, Hashtable map)
    {
      if (t == null) return;
      List ti = t.inheritance();
      for (int i=0; i<ti.sz(); i++)
      {
        Type x = (Type)ti.get(i);
        if (map[x.qname()] == null)
        {
          map[x.qname()] = x;
          acc.add(x);
        }
      }
    }

    public override bool @is(Type type)
    {
      // we don't take nullable into account for fits
      if (type is NullableType)
        type = ((NullableType)type).m_root;

      if (type == this || (type == Sys.ObjType && this != Sys.VoidType))
        return true;
      List inherit = inheritance();
      for (int i=0; i<inherit.sz(); ++i)
        if (inherit.get(i) == type) return true;
      return false;
    }

//TODO
/*
    /// <summary>
    /// Given a list of objects, compute the most specific type which they all
    /// share,or at worst return sys::Obj.  This method does not take into
    /// account interfaces, only extends class inheritance.
    /// </summary>
    public static Type common(object[] objs, int n)
    {
      if (objs.Length == 0) return Sys.ObjType;
      Type best = type(objs[0]);
      for (int i=1; i<n; ++i)
      {
        object obj = objs[i];
        if (obj == null) continue;
        Type t = type(obj);
        while (!t.@is(best))
        {
          best = best.m_base;
          if (best == null) return Sys.ObjType;
        }
      }
      return best;
    }
*/

  //////////////////////////////////////////////////////////////////////////
  // Facets
  //////////////////////////////////////////////////////////////////////////

    public override List facets()
    {
      return ((ClassType)reflect()).m_facets.list();
    }

    public override Facet facet(Type t, bool c)
    {
      return ((ClassType)reflect()).m_facets.get(t, c);
    }

  //////////////////////////////////////////////////////////////////////////
  // Documentation
  //////////////////////////////////////////////////////////////////////////

    public override string doc()
    {
      if (!m_docLoaded)
      {
        try
        {
          Stream input = m_pod.fpod.m_store.read("doc/" + m_name + ".apidoc");
          if (input != null)
          {
            try { FDoc.read(input, this); } finally { input.Close(); }
          }
        }
        catch (Exception e)
        {
          Err.dumpStack(e);
        }
        m_docLoaded = true;
      }
      return m_doc;
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

//TODO
/*
    public void encode(ObjEncoder @out)
    {
      @out.w(m_qname).w("#");
    }
*/

  //////////////////////////////////////////////////////////////////////////
  // Reflection
  //////////////////////////////////////////////////////////////////////////

    [MethodImpl(MethodImplOptions.Synchronized)]
    public override Type reflect()
    {
      // short circuit if already reflected
      if (m_slotsByName != null) return this;

      if (Debug) Console.WriteLine("-- reflect: " + m_qname + " " + m_slotsByName);

      // do it
      doReflect();

      // return this
      return this;
    }

    private void doReflect()
    {
      // if the ftype is non-null, that means it was passed in non-hollow
      // ftype (in-memory compile), otherwise we need to read it from the pod
      if (m_ftype.m_hollow)
      {
        try
        {
          m_ftype.read();
        }
        catch (IOException e)
        {
          Err.dumpStack(e);
          throw IOErr.make("Cannot read " + m_qname + " from pod", e).val;
        }
      }

      // these are working accumulators used to build the
      // data structures of my defined and inherited slots
      List slots  = new List(Sys.SlotType, 64);
      Hashtable nameToSlot  = new Hashtable();   // String -> Slot
      Hashtable nameToIndex = new Hashtable();   // String -> Long

      // merge in base class and mixin classes
      for (int i=0; i<m_mixins.sz(); i++) merge((Type)m_mixins.get(i), slots, nameToSlot, nameToIndex);
      merge(m_base, slots, nameToSlot, nameToIndex);

      // merge in all my slots
      FPod fpod   = this.m_pod.fpod;
      FType ftype = this.m_ftype;
      for (int i=0; i<ftype.m_fields.Length; i++)
      {
        Field f = map(fpod, ftype.m_fields[i]);
        merge(f, slots, nameToSlot, nameToIndex);
      }
      for (int i=0; i<ftype.m_methods.Length; i++)
      {
        Method m = map(fpod, ftype.m_methods[i]);
        merge(m, slots, nameToSlot, nameToIndex);
      }

      // break out into fields and methods
      List fields  = new List(Sys.FieldType,  slots.sz());
      List methods = new List(Sys.MethodType, slots.sz());
      for (int i=0; i<slots.sz(); i++)
      {
        Slot slot = (Slot)slots.get(i);
        if (slot is Field)
          fields.add(slot);
        else
          methods.add(slot);
      }
      this.m_slots       = slots.trim();
      this.m_fields      = fields.trim();
      this.m_methods     = methods.trim();
      this.m_slotsByName = nameToSlot;
      this.m_facets      = Facets.mapFacets(m_pod, ftype.m_attrs.m_facets);

      // facets
      this.m_lineNum    = m_ftype.m_attrs.m_lineNum;
      this.m_sourceFile = m_ftype.m_attrs.m_sourceFile;
    }

    /// <summary>
    /// Merge the inherit's slots into my slot maps.
    ///   slots:       Slot[] by order
    ///   nameToSlot:  String name -> Slot
    ///   nameToIndex: String name -> Long index of slots
    /// </summary>
    private void merge(Type inheritedType, List slots, Hashtable nameToSlot, Hashtable nameToIndex)
    {
      if (inheritedType == null) return;
      List inheritedSlots = inheritedType.reflect().slots();
      for (int i=0; i<inheritedSlots.sz(); ++i)
        merge((Slot)inheritedSlots.get(i), slots, nameToSlot, nameToIndex);
    }

    /// <summary>
    /// Merge the inherited slot into my slot maps.  Assume this slot
    /// trumps any previous definition (because we process inheritance
    /// and my slots in the right order)
    ///   slots:       Slot[] by order
    ///   nameToSlot:  String name -> Slot
    ///   nameToIndex: String name -> Long index of slots
    /// </summary>
    private void merge(Slot slot, List slots, Hashtable nameToSlot, Hashtable nameToIndex)
    {
      // skip constructors which aren't mine
      if (slot.isCtor() && slot.m_parent != this) return;

      string name = slot.m_name;
      if (nameToIndex[name] != null)
      {
        int dup = (int)nameToIndex[name];

        // if the slot is inherited from Obj, then we can
        // safely ignore it as an override - the dup is most
        // likely already the same Obj method inherited from
        // a mixin; but the dup might actually be a more specific
        // override in which case we definitely don't want to
        // override with the sys::Obj version
        if (slot.parent() == Sys.ObjType)
          return;

        // if given the choice between two *inherited* slots where
        // one is concrete and abstract, then choose the concrete one
        Slot dupSlot = (Slot)slots.get(dup);
        if (slot.parent() != this && slot.isAbstract() && !dupSlot.isAbstract())
          return;

        // check if this is a Getter or Setter, in which case the Field
        // trumps and we need to cache the method on the Field
        // Note: this works because we assume the compiler always generates
        // the field before the getter and setter in fcode
        if ((slot.m_flags & (FConst.Getter|FConst.Setter)) != 0)
        {
          Field field = (Field)slots.get(dup);
          if ((slot.m_flags & FConst.Getter) != 0)
            field.m_getter = (Method)slot;
          else
            field.m_setter = (Method)slot;
          return;
        }

        nameToSlot[name] = slot;
        slots.set(dup, slot);
      }
      else
      {
        nameToSlot[name] = slot;
        slots.add(slot);
        nameToIndex[name] = slots.sz()-1;
      }
    }

    /// <summary>
    /// Map fcode field to a sys::Field.
    /// </summary>
    private Field map(FPod fpod, FField f)
    {
      string name = String.Intern(f.m_name);
      Type fieldType = m_pod.findType(f.m_type);
      Facets facets = Facets.mapFacets(m_pod, f.m_attrs.m_facets);
      return new Field(this, name, f.m_flags, facets, f.m_attrs.m_lineNum, fieldType);
    }

    /// <summary>
    /// Map fcode method to a sys::Method.
    /// </summary>
    private Method map(FPod fpod, FMethod m)
    {
      string name = String.Intern(m.m_name);
      Type returnType = m_pod.findType(m.m_ret);
      Type inheritedReturnType = m_pod.findType(m.m_inheritedRet);
      List pars = new List(Sys.ParamType, m.m_paramCount);
      for (int j=0; j<m.m_paramCount; j++)
      {
        FMethodVar p = m.m_vars[j];
        int pflags = (p.def == null) ? 0 : Param.HAS_DEFAULT;
        pars.add(new Param(String.Intern(p.name), m_pod.findType(p.type), pflags));
      }
      Facets facets = Facets.mapFacets(m_pod, m.m_attrs.m_facets);
      return new Method(this, name, m.m_flags, facets, m.m_attrs.m_lineNum, returnType, inheritedReturnType, pars);
    }

  //////////////////////////////////////////////////////////////////////////
  // Emit
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Emit to a .NET Type.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    public System.Type emit()
    {
      if (m_type == null)
      {
        if (Debug) Console.WriteLine("-- emit:   " + m_qname);

        // make sure we have reflected to setup slots
        reflect();

        // if sys class, just load it by name
        string podName = m_pod.m_name;
        if (podName == "sys")
        {
          try
          {
            m_dotnetRepr = FanUtil.isDotnetRepresentation(this);
            m_type = System.Type.GetType(FanUtil.toDotnetImplTypeName(podName, m_name));
          }
          catch (Exception e)
          {
            Err.dumpStack(e);
            throw Err.make("Cannot load precompiled class: " + m_qname, e).val;
          }
        }

        // otherwise we need to emit it
        else
        {
          try
          {
            System.Type[] types = FTypeEmit.emitAndLoad(m_ftype);
            this.m_type = types[0];
            if (types.Length > 1)
              this.m_auxType = types[1];
          }
          catch (Exception e)
          {
            Err.dumpStack(e);
            throw Err.make("Cannot emit: " + m_qname, e).val;
          }
        }

        // we are done with our ftype now, gc it
        this.m_ftype = null;
      }
      return m_type;
    }

  //////////////////////////////////////////////////////////////////////////
  // Finish
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Finish ensures we have reflected and emitted, then does
    /// the final binding between slots and .NET members.
    /// </summary>
    [MethodImpl(MethodImplOptions.Synchronized)]
    public override void finish()
    {
      if (m_finished) return;
      try
      {
        // ensure reflected and emitted
        reflect();
        emit();
        m_finished = true;

        // map .NET members to my slots for reflection; if
        // mixin then we do this for both the interface and
        // the static methods only of the implementation class
        finishSlots(m_type, false);
        if (isMixin()) finishSlots(m_auxType, true);
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
        throw Err.make("Cannot emitFinish: " + m_qname + "." + m_finishing, e).val;
      }
      finally
      {
        m_finishing = null;
      }
    }

    /// <summary>
    /// Map the Java members of the specified
    /// class to my slots for reflection.
    /// </summary>
    private void finishSlots(System.Type type, bool staticOnly)
    {
      // map the class's fields to my slots
      FieldInfo[] fields = type.GetFields();
      for (int i=0; i<fields.Length; i++)
        finishField(fields[i]);

      // map the class's methods to my slots
      MethodInfo[] methods = type.GetMethods();
      for (int i=0; i<methods.Length; i++)
        finishMethod(methods[i], staticOnly);
    }

    private void finishField(FieldInfo f)
    {
      m_finishing = f.Name;
      Slot s = slot(f.Name.Substring(2), false); // remove 'm_'
      if (s == null || !(s is Field)) return;
      Field field = (Field)s;
      if (field.m_reflect != null) return; // first one seems to give us most specific binding
      //f.setAccessible(true); // TODO - equiv in C# ???
      field.m_reflect = f;
    }

    private void finishMethod(MethodInfo m, bool staticOnly)
    {
      m_finishing = m.Name;
      string name = FanUtil.toFanMethodName(m.Name);
      Slot s = slot(name, false);
      if (s == null) return;
      if (s.parent() != this) return;
      if (staticOnly && !s.isStatic()) return;
      if (s is Method)
      {
        Method method = (Method)s;

        // alloc System.Reflection.MethodInfo[] array big enough
        // to handle all the versions with default parameters
        if (method.m_reflect == null)
        {
          int n = 1;
          for (int j=method.@params().sz()-1; j>=0; j--)
          {
            if (((Param)method.@params().get(j)).hasDefault()) n++;
            else break;
          }
          method.m_reflect = new MethodInfo[n];
        }

        // get parameters, if sys we need to skip the
        // methods that use non-Fantom signatures
        ParameterInfo[] pars = m.GetParameters();
        int numParams = pars.Length;
        if (m_pod == Sys.m_sysPod)
        {
          if (!checkAllFan(pars)) return;
          if (m_dotnetRepr)
          {
            bool dotnetStatic = m.IsStatic;
            if (!dotnetStatic) return;
            if (!method.isStatic() && !method.isCtor()) --numParams;
          }
        }

        // zero index is full signature up to using max defaults
        method.m_reflect[method.@params().sz()-numParams] = m;
      }
      else
      {
        Field field = (Field)s;
        if (m.ReturnType.ToString() == "System.Void")
          field.m_setter.m_reflect = new MethodInfo[] { m };
        else
          field.m_getter.m_reflect = new MethodInfo[] { m };
      }
    }

    bool checkAllFan(ParameterInfo[] pars)
    {
      for (int i=0; i<pars.Length; i++)
      {
        System.Type p = pars[i].ParameterType;
        if (!p.FullName.StartsWith("Fan.") && FanUtil.toFanType(p, false) == null)
          return false;
      }
      return true;
    }

    public override bool dotnetRepr() { return m_dotnetRepr; }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

//TODO
/*
    internal static readonly bool Debug = false;
    internal static object noParams;
*/

    // available when hollow
    internal readonly Pod m_pod;
    internal readonly string m_name;
    internal readonly string m_qname;
    internal readonly int m_flags;
    internal readonly Type m_nullable;
    internal int m_lineNum;
    internal string m_sourceFile = "";
    internal Facets m_facets;
    internal Type m_base = null;
    internal List m_mixins;
    internal List m_inheritance;
    internal FType m_ftype;   // we only keep this around for memory compiles
    internal bool m_docLoaded;
    public string m_doc;

    // available when reflected
    internal List m_fields;
    internal List m_methods;
    internal List m_slots;
    internal Hashtable m_slotsByName;  // string:Slot

    // available when emitted
    internal System.Type m_type;     // main .NET type representation
    internal System.Type m_auxType;  // implementation .NET type if mixin/Err

    // flags to ensure we finish only once
    bool m_finished;
    string m_finishing;

    // misc
    internal bool m_dotnetRepr;     // if representation a .NET type, such as Fan.Sys.Long

  }
}