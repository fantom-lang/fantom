//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Sep 08  Kevin McIntire  Creation
//

**
** JsonToken represents the tokens in JSON.
**
** See [docLib]`docLib::Json` for details.
** See [docCookbook]`docCookbook::Json` for coding examples.
**
internal class JsonToken
{
  internal static const Int OBJECT_START := '{'
  internal static const Int OBJECT_END := '}'
  internal static const Int COLON := ':'
  internal static const Int ARRAY_START := '['
  internal static const Int ARRAY_END := ']'
  internal static const Int COMMA := ','
  internal static const Int QUOTE := '"'
}
