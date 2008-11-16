//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Mar 08  Andy Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// DirNamespace aliases a directory tree
  /// </summary>
  internal sealed class DirNamespace : Namespace
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    internal DirNamespace(File dir)
    {
      if (!dir.isDir())  throw ArgErr.make("Not a dir: " + dir).val;
      if (!dir.exists()) throw ArgErr.make("Dir does not exist: " + dir).val;
      this.m_dir = dir;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override string toStr() { return "DirNamespace " + m_dir; }

    public override Type type() { return Sys.DirNamespaceType; }

  //////////////////////////////////////////////////////////////////////////
  // Namespace
  //////////////////////////////////////////////////////////////////////////

    public override object get(Uri uri, bool check)
    {
      File f = m_dir.plus(uri.relTo(this.uri()), false);
      if (f.exists()) return f;
      if (!check) return null;
      throw UnresolvedErr.make(uri).val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private readonly File m_dir;

  }
}