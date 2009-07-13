//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 09  Brian Frank  Creation
//

**
** FSymbol is the read/write fcode representation of sys::Symbol.
**
class FSymbol : CSymbol, FConst
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
// CSymbol
//////////////////////////////////////////////////////////////////////////

  override CNamespace ns() { fpod.ns }
  override FPod pod()      { fpod }
  override Str name()      { fpod.n(nameIndex) }
  override Str qname()     { fpod.name + "." + name }
  override CType of()      { fpod.toType(ofIndex) }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  Void write(OutStream out)
  {
    out.writeI2(nameIndex)
    out.writeI4(flags)
    out.writeI2(ofIndex)
    out.writeUtf(val)
    FUtil.writeAttrs(out, fattrs)
  }

  This read(InStream in)
  {
    nameIndex = in.readU2
    flags     = in.readU4
    ofIndex   = in.readU2
    val       = in.readUtf
    fattrs    = FUtil.readAttrs(in)
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  readonly FPod fpod     // parent pod
  override Int flags     // bitmask
  Int nameIndex          // name index
  Int ofIndex            // typeRef index
  Str val := "null"      // serialized value string
  FAttr[]? fattrs        // meta-data attributes

}