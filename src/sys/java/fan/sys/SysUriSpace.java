//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 May 08  Brian Frank  Creation
//    9 Jul 09  Brian        Rename from SysNamespace
//
package fan.sys;

import java.util.*;

/**
 * SysUriSpace manages the "/sys" uri space branch.
 */
final class SysUriSpace
  extends UriSpace
{

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.SysUriSpaceType; }

//////////////////////////////////////////////////////////////////////////
// UriSpace
//////////////////////////////////////////////////////////////////////////

  public Object get(Uri uri, boolean checked)
  {
    // sanity check
    if (!uri.path.get(0).toString().equals("sys"))
      throw new IllegalStateException("SysUriSpace cannot process: " + uri);

    // route on /sys/{key}/...
    if (uri.path.sz() >= 3)
    {
      String key = uri.path().get(1).toString();
      if (key.equals("pod")) return pod(uri, checked);
      if (key.equals("service")) return service(uri, checked);
    }

    return unresolved(uri, checked);
  }

  private Object pod(Uri uri, boolean checked)
  {
    // /sys/pod/{name}
    String name = uri.path().get(2).toString();
    Pod pod = Pod.find(name, false);
    if (pod == null) return unresolved(uri, checked);
    if (uri.path().sz() == 3) return pod;

    // /sys/pod/{name}/{file}
    Uri fileUri = uri.sliceToPathAbs(Range.makeInclusive(3, -1));
    File f = (File)pod.files().get(fileUri);
    if (f != null) return f;

    return unresolved(uri, checked);
  }

  private Object service(Uri uri, boolean checked)
  {
    // /sys/service/qname
    if (uri.path().sz() == 3)
    {
      String qname = uri.path().get(2).toString();
      Service s = Service$.find(qname, false);
      if (s != null) return s;
    }

    return unresolved(uri, checked);
  }

  private Object unresolved(Uri uri, boolean checked)
  {
    if (!checked) return null;
    throw UnresolvedErr.make(uri).val;
  }

}