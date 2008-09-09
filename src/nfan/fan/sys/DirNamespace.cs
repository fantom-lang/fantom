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
      if (!dir.isDir().val)  throw ArgErr.make("Not a dir: " + dir).val;
      if (!dir.exists().val) throw ArgErr.make("Dir does not exist: " + dir).val;
      this.m_dir = dir;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Str toStr() { return Str.make("DirNamespace " + m_dir); }

    public override Type type() { return Sys.DirNamespaceType; }

  //////////////////////////////////////////////////////////////////////////
  // Namespace
  //////////////////////////////////////////////////////////////////////////

    public override Obj get(Uri uri, Bool check)
    {
      File f = m_dir.plus(uri.relTo(this.uri()), Bool.False);
      if (f.exists().val) return f;
      if (!check.val) return null;
      throw UnresolvedErr.make(uri).val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private readonly File m_dir;

  }
}