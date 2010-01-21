//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Aug 08  Brian Frank  Creation
//
package fan.sys;

/**
 * FanScheme
 */
public class FanScheme
  extends UriScheme
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static FanScheme make() { return new FanScheme(); }

  public static void make$(FanScheme self) {}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.FanSchemeType; }

  public Object get(Uri uri, Object base)
  {
    return UriSpace.root.get(uri.pathOnly(), true);
  }

}