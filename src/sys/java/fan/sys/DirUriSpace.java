//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Mar 08  Brian Frank  Creation
//    9 Jul 09  Brian        Rename from DirNamespace
//
package fan.sys;

import java.util.*;

/**
 * DirUriSpace aliases a directory tree
 */
final class DirUriSpace
  extends UriSpace
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  DirUriSpace(File dir)
  {
    if (!dir.isDir())  throw ArgErr.make("Not a dir: " + dir).val;
    if (!dir.exists()) throw ArgErr.make("Dir does not exist: " + dir).val;
    this.dir = dir;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public String toStr() { return "DirUriSpace " + dir; }

  public Type typeof() { return Sys.DirUriSpaceType; }

//////////////////////////////////////////////////////////////////////////
// UriSpace
//////////////////////////////////////////////////////////////////////////

  public Object get(Uri uri, boolean checked)
  {
    File f = dir.plus(uri.relTo(this.uri()), false);
    if (f.exists()) return f;
    if (!checked) return null;
    throw UnresolvedErr.make(uri).val;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private final File dir;

}