//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini Creation
//

**
** A general ASN.1 error
**
const class AsnErr : Err
{
  new make(Str msg := "", Err? cause := null) : super(msg, cause) { }
}
