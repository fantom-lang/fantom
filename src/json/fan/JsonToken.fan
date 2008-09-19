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
class JsonToken
{
  public static const Int OBJECT_START := '{'
  public static const Int OBJECT_END := '}'
  public static const Int COLON := ':'
  public static const Int ARRAY_START := '['
  public static const Int ARRAY_END := ']'
  public static const Int COMMA := ','
  public static const Int QUOTE := '"'
}
