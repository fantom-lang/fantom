//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Aug 08  Andy Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// FanScheme
  /// </summary>
  public class FanScheme : UriScheme
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public new static FanScheme make() { return new FanScheme(); }

    public static void make_(FanScheme self) {}

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.FanSchemeType; }

    public override object get(Uri uri, object @base)
    {
      return Sys.ns().get(uri.pathOnly(), true);
    }

  }
}
