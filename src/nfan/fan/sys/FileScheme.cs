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
  /// FileScheme
  /// </summary>
  public class FileScheme : UriScheme
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public new static FileScheme make() { return new FileScheme(); }

    public static void make_(FileScheme self) {}

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.FileSchemeType; }

    public override object get(Uri uri, object @base)
    {
      File f = File.make(uri, Boolean.False);
      if (f.exists().booleanValue()) return f;
      throw UnresolvedErr.make(uri).val;
    }

  }
}