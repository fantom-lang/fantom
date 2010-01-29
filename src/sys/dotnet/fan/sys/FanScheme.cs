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

    public override Type @typeof() { return Sys.FanSchemeType; }

    public override object get(Uri uri, object @base)
    {
      // don't support anything but relative fan: URIs right now
      if (uri.isPathAbs())
        throw ArgErr.make("Invalid format for 'fan:pod' URI - " + uri).val;

      // lookup pod
      string podName = (string)uri.path().get(0);
      Pod pod = Pod.find(podName, false);
      if (pod == null) throw UnresolvedErr.make(uri.toStr()).val;
      if (uri.path().size() == 1) return pod;

      // dive into file of pod
      File f = pod.file(uri);
      if (f == null) throw UnresolvedErr.make(uri.toStr()).val;
      return f;
    }

  }
}