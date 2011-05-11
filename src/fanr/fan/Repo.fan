//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 May 11  Brian Frank  Creation
//

**
** Repo models a database of pod versions
**
abstract const class Repo
{
  ** Find and create Repo implementation for URI based on its
  ** scheme (pluggable via indexed props)
  static Repo makeForUri(Uri uri, Str? username := null, Str? password := null)
  {
    if (uri.scheme == null)   return FileRepo(uri)
    if (uri.scheme == "file") return FileRepo(uri)
    if (uri.scheme == "file") return WebRepo(uri, username, password)
    throw Err("No repo available for URI scheme: $uri")
  }

  ** URI for this Repo
  abstract Uri uri()

  ** Find for pod versions which match query.  The 'numVersions'
  ** specifies how many different versions will be matched for a
  ** single pod.  Multiple pod versions are matched from highest
  ** version to lowest version, so a limit of one will always match
  ** the current (highest) version.
  abstract PodSpec[] query(Str query, Int numVersions := 1)

  ** Publish the given pod file.  If successful return the
  ** spec for newly added pod.  Throw err if the pod is
  ** malformed or already published in the database.
  abstract PodSpec publish(File podFile)

  override final Str toStr() { uri.toStr }
}