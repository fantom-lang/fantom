//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Aug 08  Brian Frank  Creation
//
package fan.sys;

/**
 * FileScheme
 */
public class FileScheme
  extends UriScheme
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static FileScheme make() { return new FileScheme(); }

  public static void make$(FileScheme self) {}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.FileSchemeType; }

  public Object get(Uri uri, Object base)
  {
    File f = File.make(uri, false);
    if (f.exists()) return f;
    throw UnresolvedErr.make(uri);
  }

}