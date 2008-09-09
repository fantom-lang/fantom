//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Apr 06  Andy Frank  Creation
//

using web

// TODO - this whole pod needs a big refactoring

**
** ServletEnv.
**
class ServletEnv
  // TODO : WebEnv
{

//////////////////////////////////////////////////////////////////////////
// WebEnv
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the prefix URI this server is running under.
  **
  /*override*/ native Uri prefixUri()

  **
  ** Return the product name and version.
  **
  /*override*/ native Str product()

  **
  ** Log this message.
  **
  /*override*/ Void log(Str msg, Err err := null) {} // todo

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Service the current request.
  **
  native Void service()

}