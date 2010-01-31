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
    // don't support anything but relative fan: URIs right now
    if (uri.auth() == null)
      throw ArgErr.make("Invalid format for fan: URI - " + uri).val;

    // lookup pod
    String podName = (String)uri.auth();
    Pod pod = Pod.find(podName, false);
    if (pod == null) throw UnresolvedErr.make(uri.toStr()).val;
    if (uri.pathStr().isEmpty()) return pod;

    // dive into file of pod
    return pod.file(uri);
  }

}