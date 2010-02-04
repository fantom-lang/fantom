//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Mar 06  Brian Frank  Creation
//

**
** Charset represents a specific character encoding used to decode
** bytes to Unicode characters, and encode Unicode characters to bytes.
**
@Serializable { simple = true }
const final class Charset
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Attempt to lookup a Charset by name.  Use one of the predefined
  ** methods such as `utf8` to get a standard encoding.  If charset not
  ** found and checked is false return null, otherwise throw ParseErr.
  **
  static Charset? fromStr(Str name, Bool checked := true)

  **
  ** Private constructor
  **
  private new privateMake()

  **
  ** Default value is `utf8`.
  **
  static Charset defVal()

//////////////////////////////////////////////////////////////////////////
// Standard Encodings
//////////////////////////////////////////////////////////////////////////

  **
  ** An charset for "UTF-8" format (Eight-bit UCS Transformation Format).
  **
  static Charset utf8()

  **
  ** An charset for "UTF-16BE" format (Sixteen-bit UCS Transformation
  ** Format, big-endian byte order).
  **
  static Charset utf16BE()

  **
  ** An charset for "UTF-16LE" format (Sixteen-bit UCS Transformation
  ** Format, little-endian byte order).
  **
  static Charset utf16LE()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the name of this character encoding.
  **
  Str name()

  **
  ** Compute hash code based on case-insensitive name.
  **
  override Int hash()

  **
  ** Charset equality is based on the character set name
  ** ignoring case (names are not case-sensitive).
  **
  override Bool equals(Obj? obj)

  **
  ** Return name().
  **
  override Str toStr()

}