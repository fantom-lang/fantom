//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 11  Brian Frank  Creation
//

using web

**
** DocErr models errors and their locations during doc compilation.
**
const class DocErr : Err
{
  ** Constructor with message, location, and optional cause
  new make(Str msg, DocLoc loc, Err? cause := null)
    : super(msg, cause)
  {
    this.loc = loc
  }

  ** Location of the error
  const DocLoc loc
}

**
** DocErrHandler is responsible for handling errors encountered
** during doc compilation including broken links and fandoc format
** errors.
**
class DocErrHandler
{

  ** Accumulated list of errors reported
  DocErr[] errs := [,]

  ** Handle a documentation error.  Default implementation
  ** logs it to stdout and stores it in `errs`.
  virtual Void onErr(DocErr err)
  {
    errs.add(err)
    echo("$err.loc: $err.msg")
    if (err.cause != null) err.cause.trace
  }

}