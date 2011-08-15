//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//

**
** DocTypeRef models a type reference in a type or slot signature.
**
const class DocTypeRef
{

  ** Constructor from signature string
  new make(Str sig)
  {
    this.signature = sig

    // check Func '|...|' sig
    first := sig[0]
    if (first == '|')
    {
      this.pod = "sys"
      this.name = "Func"
      this.qname = "sys::Func"
      this.isParameterized = true
      return
    }

    // check Map '[k:v]' signature
    if (first == '[')
    {
      this.pod = "sys"
      this.name = "Map"
      this.qname = "sys::Map"
      this.isParameterized = true
      return
    }

    // check List '...[]' or '...[]?' signature
    last := sig[-1]
    if (last == '?') last = sig[-2]
    if (last == ']')
    {
      this.pod = "sys"
      this.name = "List"
      this.qname = "sys::List"
      this.isParameterized = true
      return
    }

    // normal type
    colon := sig.index(":")
    this.pod = sig[0..<colon]
    if (sig[-1] == '?')
    {
      this.qname = sig[0..-2]
      this.name = sig[colon+2..-2]
    }
    else
    {
      this.qname = sig
      this.name = sig[colon+2..-1]
    }
  }

  ** Constructor simple pod::name type
  internal new makeSimple(Str pod, Str name)
  {
    this.pod       = pod
    this.name      = name
    this.qname     = "$pod::$name"
    this.signature = qname
  }

  ** Pod name of the type.  For parameterized types this is
  ** always pod name of generic class itself.
  const Str pod

  ** Simple name of the type such as "Str".  For parameterized
  ** types this is always name of generic class itself.
  const Str name

  ** Qualified name formatted as "pod::name".  For parameterized
  ** types this is always the type of the generic class itself.
  const Str qname

  ** Return the formal signature of this type.  In the case of
  ** non-parameterized types the signature is the same as qname.
  const Str signature

  ** Is this a parameterized generic type such as 'Str[]'
  const Bool isParameterized

  ** Return `signature`
  override final Str toStr() { signature }
}