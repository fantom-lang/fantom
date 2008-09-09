//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Mar 08  Brian Frank  Creation
//
package fan.sys;

import java.util.*;

/**
 * DirNamespace aliases a directory tree
 */
final class DirNamespace
  extends Namespace
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  DirNamespace(File dir)
  {
    if (!dir.isDir().val)  throw ArgErr.make("Not a dir: " + dir).val;
    if (!dir.exists().val) throw ArgErr.make("Dir does not exist: " + dir).val;
    this.dir = dir;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Str toStr() { return Str.make("DirNamespace " + dir); }

  public Type type() { return Sys.DirNamespaceType; }

//////////////////////////////////////////////////////////////////////////
// Namespace
//////////////////////////////////////////////////////////////////////////

  public Obj get(Uri uri, Bool checked)
  {
    File f = dir.plus(uri.relTo(this.uri()), Bool.False);
    if (f.exists().val) return f;
    if (!checked.val) return null;
    throw UnresolvedErr.make(uri).val;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private final File dir;

}