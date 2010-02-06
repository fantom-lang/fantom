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
internal class JsonToken
{
  internal static const Int objectStart := '{'
  internal static const Int objectEnd := '}'
  internal static const Int colon := ':'
  internal static const Int arrayStart := '['
  internal static const Int arrayEnd := ']'
  internal static const Int comma := ','
  internal static const Int quote := '"'
  internal static const Int grave := '`'
}