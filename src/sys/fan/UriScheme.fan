//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Aug 08  Brian Frank  Creation
//

**
** UriScheme are registered to handle a specific Uri
** scheme such as "file" or "http".  All subclasses must
** define the "uriScheme" facet with a value of a *lower
** case* scheme name.  See [docLang]`docLang::Naming`
** for the details of scheme handling works.
**
abstract const class UriScheme
{

  **
  ** Lookup a UriScheme for the specified scheme name.
  ** Scheme name must be lower case - note that `Uri.scheme`
  ** is always normalized to lower case.  If the scheme is
  ** not mapped and checked is true then throw UnresolvedErr
  ** otherwise return null.
  **
  static UriScheme? find(Str scheme, Bool checked := true)

  **
  ** Return the scheme name for this instance.  This method
  ** is implicitly defined based on the scheme name used to
  ** `find` the instance.
  **
  Str scheme()

  **
  ** Default implementation returns `scheme`.
  **
  override Str toStr()

  **
  ** Resolve the uri to a Fan object.  If uri cannot
  ** be resolved by this scheme then throw UnresolvedErr.
  **
  abstract Obj? get(Uri uri, Obj? base)

}

**************************************************************************
** FanScheme
**************************************************************************

@uriScheme="fan"
internal const class FanScheme : UriScheme
{
  override Obj? get(Uri uri, Obj? base)
}

**************************************************************************
** FileScheme
**************************************************************************

@uriScheme="file"
internal const class FileScheme : UriScheme
{
  override Obj? get(Uri uri, Obj? base)
}



