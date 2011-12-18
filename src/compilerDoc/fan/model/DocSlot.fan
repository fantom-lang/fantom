//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//

**
** DocSlot models the documentation of a `sys::Slot`.
**
abstract const class DocSlot
{
  ** Constructor
  internal new make(DocAttrs attrs, DocTypeRef parent, Str name)
  {
    this.loc    = attrs.loc
    this.parent = parent
    this.name   = name
    this.qname  = parent.qname + "." + name
    this.flags  = attrs.flags
    this.doc    = attrs.doc
    this.facets = attrs.facets
  }

  ** Source code location of this slot
  const DocLoc loc

  ** Type which defines the slot
  const DocTypeRef parent

  ** Simple name of the slot such as "equals".
  const Str name

  ** Qualified name formatted as "sys::Str.replace".
  const Str qname

  ** Flags mask - see `DocFlags`
  const Int flags

  ** Display name is Type.name
  Str dis() { parent.name + "." + name }

  ** Fandoc documentation string
  const DocFandoc doc

  ** Facets defined on this slot
  const DocFacet[] facets

  ** Return given facet
  DocFacet? facet(Str qname, Bool checked := true)
  {
    f := facets.find |f| { f.type.qname == qname }
    if (f != null) return f
    if (checked) throw Err("Missing facet @$qname on $this.qname")
    return null
  }

  ** Return if given facet is defined on slot
  Bool hasFacet(Str qname) { facets.any |f| { f.type.qname == qname } }
}

**************************************************************************
** DocField
**************************************************************************

**
** DocField models the documentation of a `sys::Field`.
**
const class DocField : DocSlot
{
  ** Constructor
  internal new make(DocAttrs attrs, DocTypeRef parent, Str name,
                    DocTypeRef type, Str? init)
    : super(attrs, parent, name)
  {
    this.type = type
    this.init = init
    this.setterFlags = attrs.setterFlags
  }

  ** Type of the field
  const DocTypeRef type

  ** Expression used to initialize the field
  const Str? init

  ** Flags for setting method if different from overall field level
  ** flags, otherwise null.
  const Int? setterFlags
}

**************************************************************************
** DocMethod
**************************************************************************

**
** DocMethod models the documentation of a `sys::Method`.
**
const class DocMethod : DocSlot
{
  ** Constructor
  internal new make(DocAttrs attrs, DocTypeRef parent, Str name,
                    DocTypeRef returns, DocParam[] params)
    : super(attrs, parent, name)
  {
    this.returns = returns
    this.params  = params
  }

  ** Return type of the method
  const DocTypeRef returns

  ** Parameters of the method
  const DocParam[] params
}

**************************************************************************
** DocMethod
**************************************************************************

**
** DocParam models the documentation of a `sys::Param`
**
const class DocParam
{
  ** Constructor
  internal new make(DocTypeRef type, Str name, Str? def)
  {
    this.type = type
    this.name = name
    this.def  = def
  }

  ** Type of the parameter
  const DocTypeRef type

  ** Name of the parameter
  const Str name

  ** Default expression if defined
  const Str? def

  override Str toStr()
  {
    s := StrBuf().add(type).addChar(' ').add(name)
    if (def != null) s.add(" := ").add(def)
    return s.toStr
  }
}

