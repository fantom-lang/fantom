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

  ** Map of value types to string format
  ** funcs (only those that don't use toStr)
  internal static const Type:|Obj->Str| valTypeToStrFunc :=
  [
    Uri#:      |Uri v->Str| { return v.encode },
    DateTime#: |DateTime v->Str| { return v.toLocale("YYYY-MM-DDThh:mm:ss.FFFz") }
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
    "uri":     |Str s->Obj| { return Uri.decode(s) },
    "abstime": |Str s, XElem elem->Obj| { return parseAbstime(s, elem) },
    "reltime": |Str s->Obj| { throw Err("TODO") },
    "date":    |Str s->Obj| { return Date.fromStr(s, true) },
    "time":    |Str s->Obj| { return Time.fromStr(s, true) }
  ]

  internal static DateTime parseAbstime(Str s, XElem elem)
  {
    tzAttr := elem.get("tz", false) ?: "UTC"
    tz := TimeZone.fromStr(tzAttr, false) ?: TimeZone.utc
    s = "$s $tz"
    return DateTime.fromStr(s, true)
  }

//////////////////////////////////////////////////////////////////////////
// Element -> Default Value
//////////////////////////////////////////////////////////////////////////

  ** Map of element names to default values
  internal const static Str:Obj elemNameToDefaultVal :=
  [
    "bool":    false,
    "int":     0,
    "real":    0f,
    "str":     "",
    "uri":     ``,
    "reltime": 0sec,
  ]

}