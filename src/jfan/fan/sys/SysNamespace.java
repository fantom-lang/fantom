//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 May 08  Brian Frank  Creation
//
package fan.sys;

import java.util.*;

/**
 * SysNamespace manages the "/sys" URI namespace branch.
 */
final class SysNamespace
  extends Namespace
{

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.SysNamespaceType; }

//////////////////////////////////////////////////////////////////////////
// Namespace
//////////////////////////////////////////////////////////////////////////

  public Obj get(Uri uri, Bool checked)
  {
    // sanity check
    if (!uri.path.get(0).toString().equals("sys"))
      throw new IllegalStateException("SysNamespace cannot process: " + uri);

    // route on /sys/{key}/...
    if (uri.path.sz() >= 3)
    {
      String key = uri.path().get(1).toString();
      if (key.equals("pod")) return pod(uri, checked);
      if (key.equals("service")) return service(uri, checked);
    }

    return unresolved(uri, checked);
  }

  private Obj pod(Uri uri, Bool checked)
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

  private Obj service(Uri uri, Bool checked)
  {
    // /sys/service/qname
    if (uri.path().sz() == 3)
    {
      String qname = uri.path().get(2).toString();
      Thread t = Thread.findService(qname, false);
      if (t != null) return t;
    }

    return unresolved(uri, checked);
  }

  private Obj unresolved(Uri uri, Bool checked)
  {
    if (!checked.val) return null;
    throw UnresolvedErr.make(uri).val;
  }

}
