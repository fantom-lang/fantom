//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 05  Brian Frank  Creation
//   19 Aug 06  Brian Frank  Ported from Java to Fan
//

**
** FType is the read/write fcode representation of sys::Type.
**
class FType : CType
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(FPod fpod)
  {
    this.fpod = fpod
    this.fattrs = FAttr[,]
  }

//////////////////////////////////////////////////////////////////////////
// CType
//////////////////////////////////////////////////////////////////////////

  override CNamespace ns() { return fpod.ns }
  override FPod pod() { return fpod }
  override once Str name() { return fpod.n(fpod.typeRef(self).typeName) }
  override once Str qname() { return "${fpod.name}::${name}" }
  override Str signature() { return qname }

  FAttr? attr(Str name)
  {
    fattrs.find |a| { fpod.n(a.name) == name }
  }

  override CType? base
  {
    get
    {
      if (&base == null) &base = fpod.toType(fbase)
      return &base
    }
  }

  override once CType[] mixins()
  {
    return fpod.resolveTypes(fmixins)
  }

  override once Bool isVal()
  {
    return isValType(qname)
  }

  override CFacet? facet(Str qname)
  {
    if (ffacets == null) reflect
    return ffacets.find |f| { f.qname == qname }
  }

  override Str:CSlot slots
  {
    get
    {
      if (slotsCached == null) reflect
      return slotsCached
    }
  }
  private [Str:CSlot]? slotsCached

  override once COperators operators() { COperators(this) }

  override Bool isNullable() { return false }

  override once CType toNullable() { return NullableType(this) }

  override Bool isGeneric()
  {
    return fpod.name == "sys" && (name == "List" || name == "Map" || name == "Func")
  }

  override Bool isParameterized() { return false }

  override Bool isGenericParameter()
  {
    return fpod.name == "sys" && name.size == 1
  }

  override once CType toListOf() { return ListType(this) }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  private Void reflect()
  {
    // lazy read from the pod file
    read

    // map all the declared fields and methods
    slotsCached = Str:CSlot[:]
    ffields.each  |FField f|  { slots[f.name] = f }
    fmethods.each |FMethod m|
    {
      f := (FField?)slots[m.name]
      if (f != null)
      {
        // if already mapped to field must be getter/setter
        if (m.flags.and(FConst.Getter) != 0)
          f.getter = m
        else if (m.flags.and(FConst.Setter) != 0)
          f.setter = m
        else
          throw Err("Conflicting slots: $f and $m")
      }
      else
      {
        slotsCached[m.name] = m
      }
    }

    // inherited slots
    if (base != null) inherit(base)
    mixins.each |CType t| { inherit(t) }
  }

  private Void inherit(CType t)
  {
    t.slots.each |CSlot newSlot|
    {
      // if slot already mapped, skip it
      if (slotsCached[newSlot.name] != null) return

      // we never inherit constructors, private slots,
      // or internal slots outside of the pod
      if (newSlot.isCtor || newSlot.isPrivate ||
          (newSlot.isInternal && newSlot.parent.pod != t.pod))
        return

      // inherit it
      slotsCached[newSlot.name] = newSlot
    }
  }

//////////////////////////////////////////////////////////////////////////
// Meta IO
//////////////////////////////////////////////////////////////////////////

  Void writeMeta(OutStream out)
  {
    out.writeI2(self)
    out.writeI2(fbase)
    out.writeI2(fmixins.size)
    fmixins.each |Int m| { out.writeI2(m) }
    out.writeI4(flags.and(FConst.FlagsMask))
  }

  This readMeta(InStream in)
  {
    self    = in.readU2
    fbase   = in.readU2
    fmixins = Int[,]
    in.readU2.times { fmixins.add(in.readU2) }
    flags   = in.readU4
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Body IO
//////////////////////////////////////////////////////////////////////////

  Uri uri()
  {
    return Uri.fromStr("/fcode/" + fpod.n(fpod.typeRef(self).typeName) + ".fcode")
  }

  Void write()
  {
    out := fpod.out(uri)

    out.writeI2(ffields.size)
    ffields.each |FField f| { f.write(out) }

    out.writeI2(fmethods.size)
    fmethods.each |FMethod m| { m.write(out) }

    out.writeI2(fattrs.size)
    fattrs.each |FAttr a| { a.write(out) }

    out.close
  }

  Void read()
  {
    in := fpod.in(uri)

    ffields = FField[,]
    in.readU2.times { ffields.add(FField(this).read(in)) }

    fmethods = FMethod[,]
    in.readU2.times { fmethods.add(FMethod(this).read(in)) }

    fattrs = FAttr[,]
    in.readU2.times { fattrs.add(FAttr.make.read(in)) }

    ffacets = FFacet.decode(fpod, attr(FConst.FacetsAttr))

    in.close
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  override Int flags    // bitmask
  Bool hollow := true   // have we only read meta-data
  FPod fpod             // parent pod
  Int self              // self typeRef index
  Int fbase             // base typeRef index
  Int[]? fmixins        // mixin typeRef indexes
  FField[]? ffields     // fields
  FMethod[]? fmethods   // methods
  FAttr[]? fattrs       // type attributes
  FFacet[]? ffacets     // decoded facet attributes

}