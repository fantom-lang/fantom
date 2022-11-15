//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 May 11  Brian Frank  Creation
//

**
** PodSpec models a specific pod version
** See [docFanr]`docFanr::Concepts#podSpec`.
**
const class PodSpec
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Construct from a pod zip file
  static PodSpec load(File file) { doLoad(file.in, file) }

  ** Construct from an InStream
  static PodSpec read(InStream in) { doLoad(in, null) }

  private static PodSpec doLoad(InStream in, File? src)
  {
    // open as zip file (use read so that we can use any
    // file with input stream)
    zip := Zip.read(in)

    try
    {
      // find meta.props
      File? meta := null
      for (File? f; (f = zip.readNext) != null; )
        if (f.uri == `/meta.props`) { meta = f; break }
      if (meta == null) throw Err("Missing meta.props")

      // parse meta into PodSpec
      return make(meta.readProps, src)
    }
    finally zip.close
  }

  @NoDoc new make(Str:Str m, File? file)
  {
    this.name    = getReq(m, "pod.name")
    this.version = Version.fromStr(getReq(m, "pod.version"))
    this.depends = parseDepends(m)
    this.summary = getReq(m, "pod.summary")
    this.toStr   = "$name-$version"
    this.meta    = m
    this.file    = file
  }

  private static Str getReq(Str:Str m, Str n)
  {
    m[n] ?: throw Err("Missing '$n' in meta.props")
  }
  private static Depend[] parseDepends(Str:Str m)
  {
    s := getReq(m, "pod.depends").trim
    if (s.isEmpty) return Depend#.emptyList
    return s.split(';').map |tok->Depend| { Depend(tok) }
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  ** Name of this pod
  const Str name

  ** Version of this pod
  const Version version

  ** List of dependencies for this pod
  const Depend[] depends

  ** Summary string
  const Str summary

  ** Metadata name/value pairs for this pod
  const Str:Str meta

  ** Return pod file size in bytes or null if unknown
  Int? size() { file?.size }

  ** Get the build timestamp or null if not available
  DateTime? ts() { DateTime.fromStr((meta["build.ts"] ?: meta["build.time"]) ?: "", false) }

  ** If loaded from a local file
  @NoDoc const File? file

  ** String format is "{name}-{version}"
  override const Str toStr

  ** Hash code is based on name and version
  override final Int hash() { toStr.hash }

  ** Equality is based on name and version
  override final Bool equals(Obj? x) { x is PodSpec && toStr == x.toStr }

  ** Return true if this pod contains Fantom fcode
  @NoDoc Bool containsCode()
  {
    fcode := meta["pod.fcode"] ?: "true"
    return fcode != "false"
  }
}