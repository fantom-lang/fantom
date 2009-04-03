//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 May 08  Brian Frank  Creation
//

using System;

namespace Fan.Sys
{
  /// <summary>
  /// SysNamespace manages the "/sys" URI namespace branch.
  /// </summary>
  internal sealed class SysNamespace : Namespace
  {

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.SysNamespaceType; }

  //////////////////////////////////////////////////////////////////////////
  // Namespace
  //////////////////////////////////////////////////////////////////////////

    public override object get(Uri uri, bool check)
    {
      // sanity check
      if (uri.m_path.get(0).ToString() != "sys")
        throw new ArgumentException("SysNamespace cannot process: " + uri);

      // route on /sys/{key}/...
      if (uri.m_path.sz() >= 3)
      {
        string key = uri.path().get(1).ToString();
        if (key == "pod") return pod(uri, check);
        if (key == "service") return service(uri, check);
      }

      return unresolved(uri, check);
    }

    private object pod(Uri uri, bool check)
    {
      // /sys/pod/{name}
      string name = uri.path().get(2).ToString();
      Pod pod = Pod.find(name, false);
      if (pod == null) return unresolved(uri, check);
      if (uri.path().sz() == 3) return pod;

      // /sys/pod/{name}/{file}
      Uri fileUri = uri.sliceToPathAbs(Range.makeInclusive(3, -1));
      File f = (File)pod.files().get(fileUri);
      if (f != null) return f;

      return unresolved(uri, check);
    }

    private object service(Uri uri, bool check)
    {
      // /sys/service/qname
      if (uri.path().sz() == 3)
      {
        string qname = uri.path().get(2).ToString();
        Service s = Service_.find(qname, false);
        if (s != null) return s;
      }

      return unresolved(uri, check);
    }

    private object unresolved(Uri uri, bool check)
    {
      if (!check) return null;
      throw UnresolvedErr.make(uri).val;
    }


  }
}