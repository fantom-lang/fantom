//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 2008  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   31 Mar 2023  Matthew Giannini  Refactor to ES
//

/**
 * Type
 */
class Type extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(qname, base, mixins, facets={}, flags=0, jsRef=null) { 
    super();

    // workaround for inheritance
    if (qname === undefined) return;

    // mixins
    if (Type.type$ != null) {
      let acc = List.make(Type.type$, []);
      for (let i=0; i<mixins.length; ++i) {
        acc.add(Type.find(mixins[i]));
      }
      this.#mixins = acc.ro();
    }

    let s = qname.split('::');
    this.#qname = qname;
    this.#pod = Pod.find(s[0]);
    this.#name = s[1];
    this.#base = base == null ? null : Type.find(base);
    this.#myFacets = new Facets(facets);
    this.#flags = flags;
    this.#nullable = new NullableType(this);
    this.#slotsInfo = [];

    // add type to registry
    if (jsRef != null) {
      let ns = Type.$registry[this.#pod.name()];
      if (ns == null) Type.$registry[this.#pod.name()] = ns = {};
      ns[jsRef.name] = jsRef;
    }
  }

  #qname;
  #pod;
  #name;
  #base;
  #mixins;
  #myFacets;
  #flags;
  #nullable;
  #slotsInfo; // af$,am$

  static #noParams = null;
  static $registry =  {};
  
//////////////////////////////////////////////////////////////////////////
// Naming
//////////////////////////////////////////////////////////////////////////

  pod() { return this.#pod; }
  name() { return this.#name; }
  qname() { return this.#qname; }
  qnameJs$() { return `${this.#pod}.${this.#name}`; }
  signature() { return this.#qname; }

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  flags() { return this.#flags; };
  isAbstract() { return (this.flags() & FConst.Abstract) != 0; }
  isClass() { return (this.flags() & (FConst.Enum|FConst.Mixin)) == 0; }
  isConst() { return (this.flags() & FConst.Const) != 0; }
  isEnum() { return (this.flags() & FConst.Enum) != 0; }
  isFacet() { return (this.flags() & FConst.Facet) != 0; }
  isFinal() { return (this.flags() & FConst.Final) != 0; }
  isInternal() { return (this.flags() & FConst.Internal) != 0; }
  isMixin() { return (this.flags() & FConst.Mixin) != 0; }
  isPublic() { return (this.flags() & FConst.Public) != 0; }
  isSynthetic() { return (this.flags() & FConst.Synthetic) != 0; }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  trap(name, args=null) {
    // private undocumented access
    if (name == "flags") return this.flags();
    return super.trap(name, args);
  }

  equals(that) {
    if (that instanceof Type)
      return this.signature() === that.signature();
    else
      return false;
  }

//////////////////////////////////////////////////////////////////////////
// Value Types
//////////////////////////////////////////////////////////////////////////

  isVal() {
    return this === Bool.type$ ||
           this === Int.type$ ||
           this === Float.type$;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  log()       { return this.#pod.log(); }
  toStr()     { return this.signature(); }
  toLocale()  { return this.signature(); }
  typeof$()   { return Type.type$; }
  literalEncode$(out) { out.w(this.signature()).w("#"); }

//////////////////////////////////////////////////////////////////////////
// Nullable
//////////////////////////////////////////////////////////////////////////

  isNullable() { return false; }
  toNonNullable() { return this; }
  toNullable() { return this.#nullable; }

//////////////////////////////////////////////////////////////////////////
// Generics
//////////////////////////////////////////////////////////////////////////

  isGenericType() {
    return this == List.type$ ||
           this == Map.type$ ||
           this == Func.type$;
  }

  isGenericInstance() { return false; }

  isGenericParameter() {
    return this.#pod.name() === "sys" && this.#name.length === 1;
  }

  isGeneric() { return this.isGenericType(); }

  params() {
    if (Type.#noParams == null)
      Type.#noParams = Map.make(Str.type$, Type.type$).ro();
    return Type.#noParams;
  }

  parameterize(params) {
    if (this === List.type$) {
      let v = params.get("V");
      if (v == null) throw ArgErr.make("List.parameterize - V undefined");
      return v.toListOf();
    }

    if (this === Map.type$) {
      let v = params.get("V");
      let k = params.get("K");
      if (v == null) throw ArgErr.make("Map.parameterize - V undefined");
      if (k == null) throw ArgErr.make("Map.parameterize - K undefined");
      return new MapType(k, v);
    }

    if (this === Func.type$) {
      let r = params.get("R");
      if (r == null) throw ArgErr.make("Func.parameterize - R undefined");
      let p = [];
      for (let i=65; i<=72; ++i) {
        let x = params.get(String.fromCharCode(i));
        if (x == null) break;
        p.push(x);
      }
      return new FuncType(p, r);
    }

    throw UnsupportedErr.make(`not generic: ${this}`);
  }

  toListOf() {
    if (this.listOf$ == null) this.listOf$ = new ListType(this);
    return this.listOf$;
  }

  emptyList() {
    if (this.emptyList$ == null)
      this.emptyList$ = List.make(this).toImmutable();
    return this.emptyList$;
  }
  
//////////////////////////////////////////////////////////////////////////
// Make
//////////////////////////////////////////////////////////////////////////

  make(args) {
    if (args === undefined) args = null;

    let make = this.method("make", false);
    if (make != null && make.isPublic()) {
      if (this.isAbstract() && !make.isStatic()) {
        throw Err.make(`Cannot instantiate abstract class: ${this.#qname}`);
      }

      let numArgs = args == null ? 0 : args.size();
      let params = make.params();
      if ((numArgs == params.size()) ||
          (numArgs < params.size() && params.get(numArgs).hasDefault())) {
        return make.invoke(null, args);
      }
    }

    let defVal = this.slot("defVal", false);
    if (defVal != null && defVal.isPublic()) {
      if (defVal instanceof Field) return defVal.get(null);
      if (defVal instanceof Method) return defVal.invoke(null, null);
    }

    throw Err.make(`Typs missing 'make' or 'defVal' slots: ${this.toStr()}`);
  }

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

  slots() { return this.reflect().slotList$.ro(); }
  methods() { return this.reflect().methodList$.ro(); }
  fields() { return this.reflect().fieldList$.ro(); }

  slot(name, checked=true) {
    const slot = this.reflect().slotsByName$[name];
    if (slot != null) return slot;
    if (checked) throw UnknownSlotErr.make(this.m_qname + "." + name);
    return null;
  }

  method(name, checked=true) {
    const slot = this.slot(name, checked);
    if (slot == null) return null;
    return ObjUtil.coerce(slot, Method.type$);
  }

  field(name, checked=true) {
    const slot = this.slot(name, checked);
    if (slot == null) return null;
    return ObjUtil.coerce(slot, Field.type$);
  }

  // addMethod
  am$(name, flags, returns, params, facets) {
    const r = fanx_TypeParser.load(returns);
    const m = new Method(this, name, flags, r, params, facets);
    this.#slotsInfo.push(m);
    return this;
  }

  // addField
  af$(name, flags, of, facets) {
    const t = fanx_TypeParser.load(of);
    const f = new Field(this, name, flags, t, facets);
    this.#slotsInfo.push(f);
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Inheritance 
//////////////////////////////////////////////////////////////////////////

  base() { return this.#base; }

  mixins() {
    // lazy-build mxins list for Obj and Type
    if (this.#mixins == null)
      this.#mixins = Type.type$.emptyList();
    return this.#mixins;
  }

  inheritance() {
    if (this.inheritance$ == null) this.inheritance$ = Type.#buildInheritance(this);
    return this.inheritance$;
  }

  static #buildInheritance(self) {
    const map = {};
    const acc = List.make(Type.type$);

    // handle Void as a special case
    if (self == Void.type$) {
      acc.add(self);
      return acc.trim().ro();
    }

    // add myself
    map[self.qname()] = self;
    acc.add(self);

    // add my direct inheritance inheritance
    Type.#addInheritance(self.base(), acc, map);
    const mixins = self.mixins();
    for (let i=0; i<mixins.size(); ++i)
      Type.#addInheritance(mixins.get(i), acc, map);

    return acc.trim().ro();
  }

  static #addInheritance(t, acc, map) {
    if (t == null) return;
    const ti = t.inheritance();
    for (let i=0; i<ti.size(); ++i)
    {
      let x = ti.get(i);
      if (map[x.qname()] == null)
      {
        map[x.qname()] = x;
        acc.add(x);
      }
    }
  }

  fits(that) { return this.toNonNullable().is(that.toNonNullable()); }
  is(that) {
    // we don't take nullable into account for fits
    if (that instanceof NullableType)
      that = that.root;

    if (this.equals(that)) return true;

    // check for void
    if (this === Void.type$) return false;

    // check base class
    var base = this.#base;
    while (base != null) {
      if (base.equals(that)) return true;
      base = base.#base;
    }

    // check mixins
    let t = this;
    while (t != null)
    {
      let m = t.mixins();
      for (let i=0; i<m.size(); i++)
        if (Type.checkMixin(m.get(i), that)) return true;
      t = t.#base;
    }

    return false;
  }

  static checkMixin(mixin, that) {
    if (mixin.equals(that)) return true;
    const m = mixin.mixins();
    for (let i=0; i<m.size(); i++)
      if (Type.checkMixin(m.get(i), that))
        return true;
    return false;
  }

//////////////////////////////////////////////////////////////////////////
// Facets 
//////////////////////////////////////////////////////////////////////////

  hasFacet(type) { return this.facet(type, false) != null; }

  facets() {
    if (this.inheritedFacets$ == null) this.#loadFacets();
    return this.inheritedFacets$.list();
  }

  facet(type, checked=true) {
    if (this.inheritedFacets$ == null) this.#loadFacets();
    return this.inheritedFacets$.get(type, checked);
  }

  #loadFacets() {
    const f = this.#myFacets.dup();
    const inheritance = this.inheritance();
    for (let i=0; i<inheritance.size(); ++i) {
      let x = inheritance.get(i);
      if (x.#myFacets) f.inherit(x.#myFacets);
    }
    this.inheritedFacets$ = f;
  }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  reflect() {
    if (this.slotsByName$ != null) return this;
    this.doReflect$();
    return this;
  }

  doReflect$() {
    // these are working accumulators used to build the
    // data structures of my defined and inherited slots
    const slots = [];
    const nameToSlot  = {};   // String -> Slot
    const nameToIndex = {};   // String -> Int

    // merge in base class and mixin classes
    if (this.#mixins)
    {
      for (let i=0; i<this.#mixins.size(); i++)
      {
        this.#mergeType(this.#mixins.get(i), slots, nameToSlot, nameToIndex);
      }
    }
    this.#mergeType(this.#base, slots, nameToSlot, nameToIndex);

    // merge in all my slots
    for (let i=0; i<this.#slotsInfo.length; i++) {
      const slot = this.#slotsInfo[i]
      this.#mergeSlot(slot, slots, nameToSlot, nameToIndex);
    }

    // break out into fields and methods
    const fields  = [];
    const methods = [];
    for (let i=0; i<slots.length; i++) {
      const slot = slots[i];
      if (slot instanceof Field) fields.push(slot);
      else methods.push(slot);
    }

    // set lists
    this.slotList$    = List.make(Slot.type$, slots);
    this.fieldList$   = List.make(Field.type$, fields);
    this.methodList$  = List.make(Method.type$, methods);
    this.slotsByName$ = nameToSlot;
  }

  /**
   * Merge the inherit's slots into my slot maps.
   *  slots:       Slot[] by order
   *  nameToSlot:  String name -> Slot
   *  nameToIndex: String name -> Long index of slots
   */
  #mergeType(inheritedType, slots, nameToSlot, nameToIndex) {
    if (inheritedType == null) return;
    const inheritedSlots = inheritedType.reflect().slots();
    for (let i=0; i<inheritedSlots.size(); i++)
      this.#mergeSlot(inheritedSlots.get(i), slots, nameToSlot, nameToIndex);
  }

  /**
   * Merge the inherited slot into my slot maps.  Assume this slot
   * trumps any previous definition (because we process inheritance
   * and my slots in the right order)
   *  slots:       Slot[] by order
   *  nameToSlot:  String name -> Slot
   *  nameToIndex: String name -> Long index of slots
   */
  #mergeSlot(slot, slots, nameToSlot, nameToIndex) {
    // skip constructors which aren't mine
    if (slot.isCtor() && slot.parent() != this) return;

    const name = slot.name();
    const dup  = nameToIndex[name];
    if (dup != null) {
      // if the slot is inherited from Obj, then we can
      // safely ignore it as an override - the dup is most
      // likely already the same Object method inherited from
      // a mixin; but the dup might actually be a more specific
      // override in which case we definitely don't want to
      // override with the sys::Object version
      if (slot.parent() == Obj.type$)
        return;

      // if given the choice between two *inherited* slots where
      // one is concrete and abstract, then choose the concrete one
      const dupSlot = slots[dup];
      if (slot.parent() != this && slot.isAbstract() && !dupSlot.isAbstract())
        return;

  // TODO FIXIT: this is not triggering -- possibly due to how we generate
  // the type info via compilerJs?
      // check if this is a Getter or Setter, in which case the Field
      // trumps and we need to cache the method on the Field
      // Note: this works because we assume the compiler always generates
      // the field before the getter and setter in fcode
      if ((slot.flags$() & (FConst.Getter | FConst.Setter)) != 0)
      {
        const field = slots[dup];
        if ((slot.flags$() & FConst.Getter) != 0)
          field.getter$ = slot;
        else
          field.setter$ = slot;
        return;
      }

      nameToSlot[name] = slot;
      slots[dup] = slot;
    } else {
      nameToSlot[name] = slot;
      slots.push(slot);
      nameToIndex[name] = slots.length-1;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

  static find(sig, checked=true) {
    // try {
      return fanx_TypeParser.load(sig, checked);
    // }
    // catch (err) {
    //   console.log("TODO:FIXIT: not found: " + sig);
    //   console.log("" + err);
    //   console.log("" + err.traceToStr());
    //   throw err;
    // }
  }

  static of(obj) {
    if (obj instanceof Obj)
      return obj.typeof$();
    else
      return Type.toFanType(obj);
  }

  static toFanType(obj) {
    if (obj == null) throw Err.make("sys::Type.toFanType: obj is null");
    if (obj.fanType$ != undefined) return obj.fanType$;
    if ((typeof obj) == "boolean" || obj instanceof Boolean) return Bool.type$;
    if ((typeof obj) == "number"  || obj instanceof Number)  return Int.type$;
    if ((typeof obj) == "string"  || obj instanceof String)  return Str.type$;
    throw Err.make(`sys::Type.toFanType: Not a Fantom type: ${obj}`);
  }

  static common$(objs) {
    if (objs.length == 0) return Obj.type$.toNullable();
    let nullable = false;
    let best = null;
    for (let i=0; i<objs.length; i++)
    {
      const obj = objs[i];
      if (obj == null) { nullable = true; continue; }
      const t = ObjUtil.typeof$(obj);
      if (best == null) { best = t; continue; }
      while (!t.is(best)) {
        best = best.base();
        if (best == null) return nullable ? Obj.type$.toNullable() : Obj.type$;
      }
    }
    if (best == null) best = Obj.type$;
    return nullable ? best.toNullable() : best;
  }

}

/*************************************************************************
 * NullableType
 ************************************************************************/

class NullableType extends Type {

  constructor(root) {
    super();
    this.#root = root;
  }

  #root;

  get root() { return this.#root; }

  podName() { return this.root.podName(); }
  pod() { return this.root.pod(); }
  name() { return this.root.name(); }
  qname() { return this.root.qname(); }
  signature() { return `${this.root.signature()}?`; }
  flags() { return this.root.flags(); }

  base() { return this.root.base(); }
  mixins() { return this.root.mixins(); }
  inheritance() { return this.root.inheritance(); }
  is(type) { return this.root.is(type); }

  isVal() { return this.root.isVal(); }

  isNullable() { return true; }
  toNullable() { return this; }
  toNonNullable() { return this.root; }

  isGenericType() { return this.root.isGenericType(); }
  isGenericInstance() { return this.root.isGenericInstance(); }
  isGenericParameter() { return this.root.isGenericParameter(); }
  getRawType() { return this.root.getRawType(); }
  params() { return this.root.params(); }
  parameterize(params) { return this.root.parameterize(params).toNullable(); }

  fields() { return this.root.fields(); }
  methods() { return this.root.methods(); }
  slots() { return this.root.slots(); }
  slot(name, checked) { return this.root.slot(name, checked); }

  facets() { return this.root.facets(); }
  facet(type, checked) { return this.root.facet(type, checked); }

  doc() { return this.root.doc(); }
}

/*************************************************************************
 * GenericType 
 ************************************************************************/

class GenericType extends Type {
  constructor(qname, base, mixins, facets={}, flags=0) { 
    super(qname, base, mixins, facets, flags); 
  }

  params() {
    if (this.params$ == null) this.params$ = this.makeParams$();
    return this.params$;
  }

  makeParams$() { throw UnsupportedErr.make("Not implemented"); }

  doReflect$() {
    // ensure master type is reflected
    const master = this.base();
    master.doReflect$();
    const masterSlots = master.slots();

    // allocate slot data structures
    const slots = [];
    const fields = [];
    const methods = [];
    const slotsByName = {};

    // parameterize master's slots
    for (let i=0; i<masterSlots.size(); i++)
    {
      let slot = masterSlots.get(i);
      if (slot instanceof Method)
      {
        slot = this.parameterizeMethod$(slot);
        methods.push(slot);
      }
      else
      {
        slot = this.parameterizeField$(slot);
        fields.push(slot);
      }
      slots.push(slot);
      slotsByName[slot.name()] = slot;
    }

    this.slotList$ = List.make(Slot.type$, slots);
    this.fieldList$ = List.make(Field.type$, fields);
    this.methodList$ = List.make(Method.type$, methods);
    this.slotsByName$ = slotsByName;
  }

  parameterizeField$(f) {
    // if not generic, short circuit and reuse original
    let t = f.type();
    if (!t.isGenericParameter()) return f;

    // create new parameterized version
    t = this.parameterizeType$(t);
    //var pf = new Field(this, f.name, f.flags, f.facets, f.lineNum, t);
    const pf = new Field(this, f.name(), f.flags$(), t, f.facets());
    //pf.reflect = f.reflect;
    return pf;
  }

  parameterizeMethod$(m) {
    // if not generic, short circuit and reuse original
    if (!m.isGenericMethod()) return m;

    // new signature
    let ret;
    const params = List.make(Param.type$);

    // parameterize return type
    if (m.returns().isGenericParameter())
      ret = this.parameterizeType$(m.returns());
    else
      ret = m.returns();

    // narrow params (or just reuse if not parameterized)
    const arity = m.params().size();
    for (let i=0; i<arity; ++i) {
      const p = m.params().get(i);
      if (p.type().isGenericParameter())
      {
        //params.add(new fan.sys.Param(p.name, parameterize(p.type), p.mask));
        params.add(new Param(p.name(), this.parameterizeType$(p.type()), p.hasDefault()));
      }
      else
      {
        params.add(p);
      }
    }

    //var pm = new Method(this, m.name, m.flags, m.facets, m.lineNum, ret, m.inheritedReturns, params, m);
    const pm = new Method(this, m.name(), m.flags$(), ret, params, m.facets(), m)
    //pm.reflect = m.reflect;
    return pm;
  }

  parameterizeType$(t) {
    const nullable = t.isNullable();
    const nn = t.toNonNullable();
    if (nn instanceof ListType)
      t = this.parameterizeListType$(nn);
    else if (nn instanceof FuncType)
      t = this.parameterizeFuncType$(nn);
    else
      t = this.doParameterize$(nn);
    return nullable ? t.toNullable() : t;
  }

  parameterizeListType$(t) {
    return this.doParameterize$(t.v).toListOf();
  }

  parameterizeFuncType$(t) {
    const params = [];
    for (let i=0; i<t.pars.length; i++)
    {
      let param = t.pars[i];
      if (param.isGenericParameter()) param = this.doParameterize$(param);
      params[i] = param;
    }

    let ret = t.ret;
    if (ret.isGenericParameter()) ret = this.doParameterize$(ret);

    return new FuncType(params, ret);
  }

  doParameterize$(t) { throw UnsupportedErr.make("Not implemented"); }
}

/*************************************************************************
 * ListType
 ************************************************************************/

class ListType extends GenericType {
  constructor(v) {
    super("sys::List", List.type$.qname(), Type.type$.emptyList());
    this.#v = v;
  }

  #v;

  get v() { return this.#v; }

  signature() { return `${this.v.signature()}[]`; }

  equals(that) {
    if (that instanceof ListType)
      return this.v.equals(that.v);
    else
      return false;
  }

  is(that) {
    if (that instanceof ListType)
    {
      if (that.v.qname() == "sys::Obj") return true;
      return this.v.is(that.v);
    }
    if (that instanceof Type)
    {
      if (that.qname() == "sys::List") return true;
      if (that.qname() == "sys::Obj")  return true;
    }
    return false;
  }

  as(obj, that) {
    const objType = ObjUtil.typeof$(obj);

    if (objType instanceof ListType &&
        // TOOD:MAYBE - commenting out this check allows runtime coercion
        // of one list type to another
        // objType.v.qname() == "sys::Obj" &&
        that instanceof ListType)
      return obj;

    if (that instanceof NullableType &&
        that.root instanceof ListType)
      that = that.root;

    return objType.is(that) ? obj : null;
  }

  facets() { return List.type$.facets(); }
  facet(type, checked=true) { return List.type$.facet(type, checked); }

  makeParams$() {
    return Map.make(Str.type$, Type.type$)
      .set("V", this.v)
      .set("L", this).ro();
  }

  isGenericParameter() {
    return this.v.isGenericParameter();
  }

  doParameterize$(t) {
    if (t == Sys.VType) return this.v;
    if (t == Sys.LType) return this;
    throw new Error(t.toString());
  }
}

/*************************************************************************
 * MapType
 ************************************************************************/

class MapType extends GenericType {
  constructor(k, v) {
    super("sys::Map", Map.type$.qname(), Type.type$.emptyList());
    this.#k = k;
    this.#v = v;
  }

  #k;
  #v;

  get k() { return this.#k; }
  get v() { return this.#v; }


  signature() {
    return "[" + this.k.signature() + ':' + this.v.signature() + ']';
  }

  equals(that) {
    if (that instanceof MapType)
      return this.k.equals(that.k) && this.v.equals(that.v);
    else
      return false;
  }

  is(that) {
    if (that.isNullable()) that = that.root;

    if (that instanceof MapType) {
      return this.k.is(that.k) && this.v.is(that.v);
    }

    if (that instanceof Type) {
      if (that.qname() == "sys::Map") return true;
      if (that.qname() == "sys::Obj")  return true;
    }

    return false;
  }

  as(obj, that) {
    const objType = ObjUtil.typeof$(obj);
    if (objType instanceof MapType && that instanceof MapType)
      return obj;
    return objType.is(that) ? obj : null;
  }

  facets() { return Map.type$.facets(); }
  facet(type, checked=true) { return Map.type$.facet(type, checked); }

  makeParams$() {
    return Map.make(Str.type$, Type.type$)
      .set("K", this.k)
      .set("V", this.v)
      .set("M", this).ro();
  }

  isGenericParameter() {
    return this.v.isGenericParameter() && this.k.isGenericParameter();
  }

  doParameterize$(t) {
    if (t == Sys.KType) return this.k;
    if (t == Sys.VType) return this.v;
    if (t == Sys.MType) return this;
    throw new Error(t.toString());
  }
}

/*************************************************************************
 * FuncType
 ************************************************************************/

class FuncType extends GenericType {
  constructor(params, ret) {
    super("sys::Func", Obj.type$.qname(), Type.type$.emptyList());
    this.#pars = params;
    this.#ret = ret;

    // I am a generic parameter type if any my args or
    // return type are generic parameter types.
    this.#genericParameterType |= ret.isGenericParameter();
    for (let i=0; i<params.length; ++i)
      this.#genericParameterType |= params[i].isGenericParameter();
  }

  #pars;
  #ret;
  #genericParameterType=0;

  get pars() { return this.#pars; }
  get ret() { return this.#ret; }

  signature() {
    let s = '|'
    for (let i=0; i<this.pars.length; i++)
    {
      if (i > 0) s += ',';
      s += this.pars[i].signature();
    }
    s += '->';
    s += this.ret.signature();
    s += '|';
    return s;
  }

  equals(that) {
    if (that instanceof FuncType)
    {
      if (this.pars.length != that.pars.length) return false;
      for (let i=0; i<this.pars.length; i++)
        if (!this.pars[i].equals(that.pars[i])) return false;
      return this.ret.equals(that.ret);
    }
    return false;
  }

  is(that) {
    if (this == that) return true;
    if (that instanceof FuncType)
    {
      // match return type (if void is needed, anything matches)
      if (that.ret.qname() != "sys::Void" && !this.ret.is(that.ret)) return false;

      // match params - it is ok for me to have less than
      // the type params (if I want to ignore them), but I
      // must have no more
      if (this.pars.length > that.pars.length) return false;
      for (let i=0; i<this.pars.length; ++i)
        if (!that.pars[i].is(this.pars[i])) return false;

      // this method works for the specified method type
      return true;
    }
    // TODO FIXIT - need to add as FuncType in Type.$af
    if (that.toString() == "sys::Func") return true;
    if (that.toString() == "sys::Func?") return true;
    return this.base().is(that);
  }

  as(that) {
    // TODO FIXIT
    throw UnsupportedErr.make("TODO:FIXIT");
    return that;
  }

  // NOTE: removed toNullable() since it should be handled by base Type class

  facets() { return Func.type$.facets(); }
  facet(type, checked=true) { return Func.type$.facet(type, checked); }

  makeParams$() {
    const map = Map.make(Str.type$, Type.type$);
    for (let i=0; i<this.pars.length; ++i)
      map.set(String.fromCharCode(i+65), this.pars[i]);
    return map.set("R", this.ret).ro();
  }

  isGenericParameter() { return this.#genericParameterType; }

  doParameterize$(t) {
    // return
    if (t == Sys.RType) return ret;

    // if A-H maps to avail params
    const name = t.name().charCodeAt(0) - 65;
    if (name < this.pars.length) return this.pars[name];

    // otherwise let anything be used
    return Obj.type$;
  }
}