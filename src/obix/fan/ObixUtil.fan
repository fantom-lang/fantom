//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jan 09  Brian Frank  Creation
//

using xml

**
** ObixUtil encapsulates utility functions.
**
internal class ObixUtil
{

//////////////////////////////////////////////////////////////////////////
// Element Names
//////////////////////////////////////////////////////////////////////////

  **
  ** Map val types to element names
  **
  internal static const Str:Bool elemNames :=
  [
    "obj":     true,
    "bool":    true,
    "int":     true,
    "real":    true,
    "str":     true,
    "enum":    true,
    "uri":     true,
    "abstime": true,
    "reltime": true,
    "date":    true,
    "time":    true,
    "list":    true,
    "op":      true,
    "feed":    true,
    "ref":     true,
    "err":     true,
  ] { def = false }

//////////////////////////////////////////////////////////////////////////
// Value -> Element
//////////////////////////////////////////////////////////////////////////

  **
  ** Map val types to element names
  **
  internal static const Type:Str valTypeToElemName :=
  [
    Bool#:     "bool",
    Int#:      "int",
    Float#:    "real",
    Str#:      "str",
    Uri#:      "uri",
    DateTime#: "abstime",
    Duration#: "reltime",
    Date#:     "date",
    Time#:     "time",
  ]

//////////////////////////////////////////////////////////////////////////
// Value -> Str
//////////////////////////////////////////////////////////////////////////

  ** Encode the value in its XML string encoding (not necessarily escaped)
  internal static Str valToStr(Obj? val)
  {
    if (val == null) return "null"
    func := valTypeToStrFunc[val.type]
    if (func != null) return func(val)
    return val.toStr
  }

  ** Map of value types to string format
  ** funcs (only those that don't use toStr)
  internal static const Type:|Obj->Str| valTypeToStrFunc :=
  [
    Uri#:      |Uri v->Str|      { return v.encode },
    DateTime#: |DateTime v->Str| { return v.toIso },
    Duration#: |Duration v->Str| { return v.toIso },
    Date#:     |Date v->Str|     { return v.toIso },
    Time#:     |Time v->Str|     { return v.toIso },
  ]

//////////////////////////////////////////////////////////////////////////
// Str -> Value
//////////////////////////////////////////////////////////////////////////

  ** Map of element names to functions to parse a string
  internal const static Str:|Str,XElem->Obj| elemNameToFromStrFunc :=
  [
    "bool":    |Str s->Obj| { return Bool.fromStr(s, true) },
    "int":     |Str s->Obj| { return Int.fromStr(s, 10, true) },
    "real":    |Str s->Obj| { return Float.fromStr(s, true) },
    "str":     |Str s->Obj| { return s },
    "uri":     |Str s->Obj| { return parseUri(s) },
    "enum":    |Str s->Obj| { return s },
    "abstime": |Str s, XElem elem->Obj| { return parseAbstime(s, elem) },
    "reltime": |Str s->Obj| { return Duration.fromIso(s, true) },
    "date":    |Str s->Obj| { return Date.fromIso(s, true) },
    "time":    |Str s->Obj| { return Time.fromIso(s, true) }
  ]

  ** Map of element names to functions to parse a min/max string
  internal const static Str:|Str,XElem->Obj| elemNameToMinMaxFunc :=
  [
    "int":     |Str s->Obj| { return Int.fromStr(s, 10, true) },
    "real":    |Str s->Obj| { return Float.fromStr(s, true) },
    "str":     |Str s->Obj| { return Int.fromStr(s, 10, true) },
    "abstime": |Str s, XElem elem->Obj| { return parseAbstime(s, elem) },
    "reltime": |Str s->Obj| { return Duration.fromIso(s, true) },
    "date":    |Str s->Obj| { return Date.fromIso(s, true) },
    "time":    |Str s->Obj| { return Time.fromIso(s, true) }
  ]

  internal static Uri parseUri(Str s)
  {
    try { return Uri.decode(s) } catch (Err e) {}
    return Uri(s)
  }

  internal static DateTime parseAbstime(Str s, XElem elem)
  {
    tz := elem.get("tz", false)
    if (tz != null)
      return DateTime.fromStr("$s $tz", true)
    else
      return DateTime.fromIso(s, true)
  }

//////////////////////////////////////////////////////////////////////////
// Element -> Default Value
//////////////////////////////////////////////////////////////////////////

  ** Map of element names to default values
  internal const static Str defaultsToNull := "__null!__"
  internal const static Str:Obj elemNameToDefaultVal :=
  [
    "bool":    false,
    "int":     0,
    "real":    0f,
    "str":     "",
    "uri":     ``,
    "reltime": 0sec,
    "enum":    defaultsToNull,
    "abstime": defaultsToNull,
    "date":    defaultsToNull,
    "time":    defaultsToNull,
  ]

}