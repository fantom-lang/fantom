//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 06  Brian Frank  Creation
//   06 Jul 07  Brian Frank  Port from Java
//

**
** TypeParser is used to parser formal type signatures into CTypes.
**
**   x::N
**   x::V[]
**   x::V[x::K]
**   |x::A, ... -> x::R|
**
class TypeParser
{

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the signature into a resolved CType.  We *don't*
  ** use the CNamespace's cache - it is using me when a signature
  ** isn't found in the cache.  But we do use the CPod's type cache
  ** via CPod.resolveType.
  **
  public static CType resolve(CNamespace ns, Str sig)
  {
    // if last char is ? then parse as nullable
    last := sig[-1]
    if (last == '?') return resolve(ns, sig[0..-2]).toNullable

    // if the last character isn't ] or |, then this a non-generic
    // type and we don't even need to allocate a parser
    if (last != ']' && last != '|')
    {
      colon    := sig.index("::")
      podName  := sig[0..<colon]
      typeName := sig[colon+2..-1]
      return ns.resolvePod(podName, null).resolveType(typeName, true)
    }

    // we got our work cut out for us - create parser
    return TypeParser.make(ns, sig).loadTop
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  private new make(CNamespace ns, Str sig)
  {
    this.ns    = ns
    this.sig   = sig
    this.len   = sig.size
    this.pos   = 0
    this.cur   = sig[pos]
    this.peek  = sig[pos+1]
  }

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  private CType loadTop()
  {
    t := loadAny
    if (cur != 0) throw err
    return t
  }

  private CType loadAny()
  {
    CType? t

    // |...| is function
    if (cur == '|')
      t = loadFunc

    // [...] is map
    else if (cur == '[')
      t = loadMap

    // otherwise must be basic[]
    else
      t = loadBasic

    // nullable
    if (cur == '?')
    {
      consume('?')
      t = t.toNullable
    }

    // anything left must be []
    while (cur == '[')
    {
      consume('[')
      consume(']')
      t = t.toListOf
    }

    // nullable
    if (cur == '?')
    {
      consume('?')
      t = t.toNullable
    }

    return t
  }

  private CType loadMap()
  {
    consume('[')
    key := loadAny
    consume(':')
    val := loadAny
    consume(']')
    return MapType.make(key, val)
  }

  private CType loadFunc()
  {
    consume('|')
    params := CType[,]
    names  := Str[,]
    if (cur != '-')
    {
      while (true)
      {
        params.add(loadAny)
        names.add(('a'+names.size).toChar)
        if (cur == '-') break
        consume(',')
      }
    }
    consume('-')
    consume('>')
    ret := loadAny
    consume('|')

    return FuncType.make(params, names, ret)
  }

  private CType loadBasic()
  {
    start := pos
    while (cur.isAlphaNum || cur == '_') consume
    consume(':')
    consume(':')
    while (cur.isAlphaNum || cur == '_') consume
    qname := sig[start..<pos]
    return ns.resolveType(qname)
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private Void consume(Int? expected := null)
  {
    if (expected != null && cur != expected) throw err
    cur = peek
    pos++
    peek = pos+1 < len ? sig[pos+1] : 0
  }

  private ArgErr err()
  {
    return ArgErr.make("Invalid type signature '" + sig + "'")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private CNamespace ns  // namespace we are loading from
  private Str sig        // signature being parsed
  private Int len        // length of sig
  private Int pos        // index of cur in sig
  private Int cur        // cur character; sig[pos]
  private Int peek       // next character; sig[pos+1]

}