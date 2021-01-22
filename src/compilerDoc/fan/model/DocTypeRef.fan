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
abstract const class DocTypeRef
{

  ** Constructor from signature string
  static new fromStr(Str sig, Bool checked := true)
  {
    try
    {
      return DocTypeRefParser(sig).parseTop
    }
    catch (Err e)
    {
      if (!checked) return null
      if (e is ParseErr) throw e
      else throw ParseErr(sig, e)
    }
  }

  ** Pod name of the type.  For parameterized types this is
  ** always pod name of generic class itself.
  abstract Str pod()

  ** Simple name of the type such as "Str".  For parameterized
  ** types this is always name of generic class itself.
  abstract Str name()

  ** Qualified name formatted as "pod::name".  For parameterized
  ** types this is always the type of the generic class itself.
  abstract Str qname()

  ** Return the formal signature of this type.  In the case of
  ** non-parameterized types the signature is the same as qname.
  abstract Str signature()

  ** Get nice display name for type which excludes pod name
  ** even in parameterized types.
  abstract Str dis()

  ** Is this a nullable type such as 'Str?'
  abstract Bool isNullable()

  ** Is this one of the generic variable types such as 'sys::V'
  abstract Bool isGenericVar()

  ** Is this a parameterized generic type such as 'Str[]'
  abstract Bool isParameterized()

  ** If this a parameterized list or map get value type else null
  @NoDoc abstract DocTypeRef? v()

  ** If this a parameterized map get key type else null
  @NoDoc abstract DocTypeRef? k()

  ** If this a parameterized func type get parameterized param types
  @NoDoc abstract DocTypeRef[]? funcParams()

  ** If this a parameterized func type get return type else null
  @NoDoc abstract DocTypeRef? funcReturn()

  ** Return `signature`
  override final Str toStr() { signature }
}

**************************************************************************
** BasicTypeRef
**************************************************************************

internal const class BasicTypeRef : DocTypeRef
{
  new make(Str qname, Int colons)
  {
    this.pod   = qname[0..<colons]
    this.name  = qname[colons+2..-1]
    this.qname = qname
  }
  override const Str pod
  override const Str name
  override const Str qname
  override Str signature() { qname }
  override Str dis() { name }
  override Bool isNullable() { false }
  override Bool isParameterized() { false }
  override Bool isGenericVar() { name.size == 1 && pod == "sys" }
  override DocTypeRef? v() { null }
  override DocTypeRef? k() { null }
  override DocTypeRef[]? funcParams() { null }
  override DocTypeRef? funcReturn() { null }
}

**************************************************************************
** NullableTypeRef
**************************************************************************

internal const class NullableTypeRef : DocTypeRef
{
  new make(DocTypeRef base) { this.base = base }
  const DocTypeRef base
  override Str pod() { base.pod }
  override Str name() { base.name }
  override Str qname() { base.qname }
  override Str signature() { "${base}?" }
  override Str dis() { "${base.dis}?" }
  override Bool isNullable() { true }
  override Bool isParameterized() { base.isParameterized }
  override Bool isGenericVar() { base.isGenericVar }
  override DocTypeRef? v() { base.v }
  override DocTypeRef? k() { base.k }
  override DocTypeRef[]? funcParams() { base.funcParams }
  override DocTypeRef? funcReturn() { base.funcReturn }
}

**************************************************************************
** ListTypeRef
**************************************************************************

internal const class ListTypeRef : DocTypeRef
{
  new make(DocTypeRef v) { this.v = v }
  override Str pod() { "sys" }
  override Str name() { "List" }
  override Str qname() { "sys::List" }
  override Str signature() { "$v[]" }
  override Str dis() { "${v.dis}[]" }
  override Bool isNullable() { false }
  override Bool isParameterized() { true }
  override Bool isGenericVar() { false }
  override const DocTypeRef? v
  override DocTypeRef? k() { null }
  override DocTypeRef[]? funcParams() { null }
  override DocTypeRef? funcReturn() { null }
}

**************************************************************************
** MapTypeRef
**************************************************************************

internal const class MapTypeRef : DocTypeRef
{
  new make(DocTypeRef k, DocTypeRef v) { this.k = k; this.v = v }
  override Str pod() { "sys" }
  override Str name() { "Map" }
  override Str qname() { "sys::Map" }
  override Str signature() { "[$k:$v]" }
  override Str dis() { "[$k.dis:$v.dis]" }
  override Bool isNullable() { false }
  override Bool isParameterized() { true }
  override Bool isGenericVar() { false }
  override const DocTypeRef? k
  override const DocTypeRef? v
  override DocTypeRef[]? funcParams() { null }
  override DocTypeRef? funcReturn() { null }
}

**************************************************************************
** FuncTypeRef
**************************************************************************

internal const class FuncTypeRef : DocTypeRef
{
  new make(DocTypeRef[] p, DocTypeRef r) { funcParams = p; funcReturn = r }
  override Str pod() { "sys" }
  override Str name() { "Func" }
  override Str qname() { "sys::Func" }
  override Str signature()
  {
    s := StrBuf()
    s.add("|")
    funcParams.each |p, i| { if (i > 0) s.add(","); s.add(p.signature) }
    s.add("->")
    s.add(funcReturn)
    s.add("|")
    return s.toStr
  }
  override Str dis()
  {
    s := StrBuf()
    s.add("|")
    funcParams.each |p, i| { if (i > 0) s.add(","); s.add(p.dis) }
    s.add("->")
    s.add(funcReturn.dis)
    s.add("|")
    return s.toStr
  }
  override Bool isNullable() { false }
  override Bool isParameterized() { true }
  override Bool isGenericVar() { false }
  override DocTypeRef? v() { null }
  override DocTypeRef? k() { null }
  override const DocTypeRef[]? funcParams
  override const DocTypeRef? funcReturn
}

**************************************************************************
** DocTypeRefParser
**************************************************************************

internal class DocTypeRefParser
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  internal new make(Str sig)
  {
    this.sig   = sig
    this.len   = sig.size
    this.pos   = 0
    this.cur   = sig[pos]
    this.peek  = sig[pos+1]
  }

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  internal DocTypeRef parseTop()
  {
    t := parseAny
    if (cur != 0) throw err
    return t
  }

  private DocTypeRef parseAny()
  {
    DocTypeRef? t

    // |...| is function
    if (cur == '|')
      t = parseFunc

    // [ is either [ffi]xxx or [K:V] map
    else if (cur == '[')
    {
      ffi := true
      for (i:=pos+1; i<len; ++i)
      {
        ch := sig[i]
        if (isIdChar(ch)) continue
        ffi = (ch == ']')
        break
      }

      if (ffi)
        t = parseBasic
      else
        t = parseMap
    }

    // otherwise must be basic[]
    else
      t = parseBasic

    // nullable and []
    while (cur == '?' || cur == '[')
    {
      if (cur == '?')
      {
        consume('?')
        t = NullableTypeRef(t)
      }

      if (cur == '[')
      {
        consume('[')
        consume(']')
        t = ListTypeRef(t)
      }
    }

    return t
  }

  private DocTypeRef parseMap()
  {
    consume('[')
    key := parseAny
    consume(':')
    val := parseAny
    consume(']')
    return MapTypeRef(key, val)
  }

  private DocTypeRef parseFunc()
  {
    consume('|')
    params := DocTypeRef[,]
    if (cur != '-')
    {
      while (true)
      {
        params.add(parseAny)
        if (cur == '-') break
        consume(',')
      }
    }
    consume('-')
    consume('>')
    ret := parseAny
    consume('|')

    return FuncTypeRef(params, ret)
  }

  private DocTypeRef parseBasic()
  {
    // pod
    start := pos
    while (cur != ':' || peek != ':') consume

    // ::
    colons := pos - start
    consume(':')
    consume(':')

    // type name or [Baz for FFI
    while (cur == '[') consume
    while (isIdChar(cur)) consume

    return BasicTypeRef(sig[start..<pos], colons)
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private Void consume(Int? expected := null)
  {
    if (expected != null && cur != expected || cur == 0) throw err
    cur = peek
    pos++
    peek = pos+1 < len ? sig[pos+1] : 0
  }

  private static Bool isIdChar(Int ch)
  {
    ch.isAlphaNum || ch == '_'
  }

  private ParseErr err()
  {
    ParseErr("Invalid type signature '" + sig + "'")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Str sig        // signature being parsed
  private Int len        // length of sig
  private Int pos        // index of cur in sig
  private Int cur        // cur character; sig[pos]
  private Int peek       // next character; sig[pos+1]

}