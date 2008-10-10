//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   03 Nov 07  Brian Frank  Creation
//

**
** Locale models a cultural language and region/country.
** See `docLang::Localization` for details.
**
@simple
const class Locale
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a locale according to the `toStr` format.
  ** If invalid format and checked is false return null,
  ** otherwise throw ParseErr.
  **
  static Locale? fromStr(Str s, Bool checked := true)

  **
  ** Private constructor
  **
  private new privateMake()

//////////////////////////////////////////////////////////////////////////
// Thread
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the current thread's locale.
  **
  static Locale current()

  **
  ** Set the current thread's locale.
  ** Throw NullErr if null is passed.
  **
  static Void setCurrent(Locale locale)

  **
  ** Run the specified function using this locale as the
  ** the thread's current locale.  This method guarantees
  ** that upon return the thread current's locale remains
  ** unchanged.
  **
  Void with(|,| func)

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the language as a lowercase ISO 639 two letter code.
  **
  Str lang()

  **
  ** Get the country/region as an uppercase ISO 3166 two
  ** letter code.  Return null if the country is unspecified.
  **
  Str? country()

  **
  ** Compute hash code base on normalized toStr format.
  **
  override Int hash()

  **
  ** Equality is based on the normalized toStr format.
  **
  override Bool equals(Obj? obj)

  **
  ** Return string representation:
  **   <locale>  := <lang> ["-" <country>]
  **   <lang>    := lowercase ISO 636 two letter code
  **   <country> := uppercase ISO 3166 two letter code
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// Properties
//////////////////////////////////////////////////////////////////////////

  **
  ** Resolve a localized property for the specified pod/key pair.
  ** The following rules are used for resolution:
  **   1. Find the pod and use its resource files
  **   2. Lookup via '/locale/{Locale.toStr}.props'
  **   3. Lookup via '/locale/{Locale.lang}.props'
  **   4. Lookup via '/locale/en.props'
  **   5. If all else fails return the def parameter which
  **      defaults to 'pod::key'
  **
  ** Also see `Pod.loc` and `Type.loc`.
  **
  Str? get(Str pod, Str key, Str? def := "pod::key")

}