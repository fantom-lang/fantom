//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 May 11  Brian Frank  Creation
//

**
** Query models a parsed query against the pod database.
** See `docFanr::Queries` for details and formal grammer.
**
const class Query
{
  ** Parse query string - see `docFanr::Queries` for format.
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      return Parser(s).parse
    }
    catch (Err e)
    {
      if (e isnot ParseErr) e = ParseErr("Internal err $e.toStr: $s", e)
      if (checked) throw e
      return null
    }
  }

  internal new make(QueryPart[] parts) { this.parts = parts }

  internal const QueryPart[] parts

  ** Return query string - see `docFanr::Queries` for format.
  override Str toStr() { parts.join(",") }

  ** Hash is based on query parts
  override Int hash() { parts.hash }

  ** Equality is based on query parts
  override Bool equals(Obj? that) { that is Query && parts == ((Query)that).parts }

  ** Match against full query (name, version, and meta)
  Bool include(PodSpec pod)
  {
    parts.any |part| { part.include(pod) }
  }

  ** Match against name only, but *not* version or meta
  Bool includeName(PodSpec pod)
  {
    parts.any |part| { part.includeName(pod) }
  }

}

**************************************************************************
** QueryPart
**************************************************************************

** QueryPart is one "OR" part of a Query.
internal const class QueryPart
{
  new make(Str namePattern, Depend? version, QueryMeta[] metas)
  {
    this.namePattern = namePattern
    if (namePattern.contains("*")) this.nameRegex = Regex.glob(namePattern)
    this.version = version
    this.metas   = metas
  }

  const Str namePattern
  const Depend? version
  const QueryMeta[] metas
  private const Regex? nameRegex

  Bool isNameExact() { nameRegex == null }

  override Int hash() { namePattern.hash }

  override Bool equals(Obj? that)
  {
    if (that isnot QueryPart) return false
    x := (QueryPart)that
    return namePattern == x.namePattern && version == x.version && metas == x.metas
  }

  override Str toStr()
  {
    s := StrBuf()
    s.add(namePattern)
    if (version != null)
    {
      v := version.toStr
      s.add(" ").add(v[v.index(" ")+1..-1])
    }
    metas.each |m| { s.add(" ").add(m) }
    return s.toStr
  }

  Bool include(PodSpec pod)
  {
    if (!includeName(pod)) return false
    if (!includeVersion(pod)) return false
    if (!includeMetas(pod)) return false
    return true
  }

  Bool includeName(PodSpec pod)
  {
    if (nameRegex == null)
      return namePattern == pod.name
    else
      return nameRegex.matches(pod.name)
  }

  Bool includeVersion(PodSpec pod)
  {
    if (version == null) return true
    return version.match(pod.version)
  }

  Bool includeMetas(PodSpec pod)
  {
    if (metas.isEmpty) return true
    return metas.all |meta| { meta.include(pod) }
  }
}

**************************************************************************
** QueryMeta
**************************************************************************

** QueryMeta is one pod meta property filter of a QueryPart
internal const class QueryMeta
{
  new make(Str name, QueryOp op, Obj? val)
  {
    this.name = name
    this.op   = op
    this.val  = val
  }

  override Str toStr()
  {
    if (op === QueryOp.has) return name
    valStr := val is Str ? ((Str)val).toCode : val.toStr
    return "$name $op $valStr"
  }

  override Int hash() { name.hash.xor(op.hash.shiftl(11)) }

  override Bool equals(Obj? that)
  {
    if (that isnot QueryMeta) return false
    x := (QueryMeta)that
    return name == x.name && op == x.op && val == x.val
  }

  Bool include(PodSpec pod)
  {
    // lookup prop string value
    actualStr := pod.meta[name]
    if (actualStr == null) return false

    // has just checks for presents of meta and that its not "false"
    if (op === QueryOp.has) return actualStr != "false"

    // attempt to coerce actual string to typed comparison value
    actual := coerce(val.typeof, actualStr)
    if (actual == null) return op === QueryOp.notEq

    // comparisons
    if (op === QueryOp.eq)    return actual == val
    if (op === QueryOp.notEq) return actual != val
    if (op === QueryOp.like)  return actual.toStr.lower.contains(val.toStr.lower)
    if (op === QueryOp.lt)    return actual < val
    if (op === QueryOp.ltEq)  return actual <= val
    if (op === QueryOp.gtEq)  return actual >= val
    if (op === QueryOp.gt)    return actual > val
    throw UnsupportedErr(op.toStr)
  }

  private Obj? coerce(Type type, Str s)
  {
    if (type === Str#) return s
    if (type === Int#) return Int.fromStr(s, 10, false)
    if (type === Date#) return DateTime.fromStr(s, false)?.date
    if (type === Version#) return Version.fromStr(s, false)
    throw UnsupportedErr(type.toStr)
  }

  const Str name
  const QueryOp op
  const Obj? val
}

**************************************************************************
** QueryOp
**************************************************************************

** QueryOp is a comparison operator for a QueryMeta filter
internal enum class QueryOp
{
  has   ("has"),
  eq    ("=="),
  notEq ("!="),
  like  ("~="),
  lt    ("<"),
  ltEq  ("<="),
  gtEq  (">="),
  gt    (">");

  private new make(Str symbol) { this.symbol  = symbol  }
  override Str toStr() { symbol }
  const Str symbol
}