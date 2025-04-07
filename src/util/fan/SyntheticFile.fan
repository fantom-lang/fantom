//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Apr 25  Brian Frank  Creation
//

**
** SyntheticFile provides default no-op implementation of File API
**
const class SyntheticFile : File
{
  ** Constructor
  new make(Uri uri) : super.makeNew(uri) {}

  ** Return false
  override Bool exists() { false }

  ** Return null
  override Int? size() { null }

  ** No-op
  override DateTime? modified
  {
    get { null }
    set { }
  }

  ** Return null
  override Str? osPath() { null }

  ** Return null
  override File? parent() { null }

  ** Return empty list
  override File[] list(Regex? pattern := null) { File#.emptyList }

  ** Return this
  override File normalize() { this }

  ** Return another instance of SyntheticFile
  override File plus(Uri uri, Bool checkSlash := true) { make(this.uri.plus(uri)) }

  ** Raise IOErr
  override File create() { throw IOErr() }

  ** Raise IOErr
  override File moveTo(File to) { throw IOErr() }

  ** Raise IOErr
  override Void delete() { throw IOErr() }

  ** Raise IOErr
  override File deleteOnExit() { throw IOErr() }

  ** Raise IOErr
  override Buf open(Str mode := "rw") { throw IOErr() }

  ** Raise IOErr
  override Buf mmap(Str mode := "rw", Int pos := 0, Int? size := this.size) { throw IOErr() }

  ** Raise IOErr
  override InStream in(Int? bufferSize := 4096) { throw IOErr() }

  ** Default implementation uses `SyntheticFile.in`
  override Obj? withIn([Str:Obj]? opts, |InStream->Obj?| f)
  {
    bufSize := 4096
    if (opts != null) bufSize = opts.get("bufferSize", bufSize)

    in := this.in(bufSize)
    try
      return f(in)
    finally
      in.close
  }

  ** Raise IOErr
  override OutStream out(Bool append := false, Int? bufferSize := 4096) { throw IOErr() }

  ** Default implementation uses `SyntehticFile.out`
  override Void withOut([Str:Obj]? opts, |OutStream| f)
  {
    append  := false
    bufSize := 4096
    if (opts != null)
    {
      append  = opts.get("append", append)
      bufSize = opts.get("bufferSize", bufSize)
    }

    out := this.out(append, bufSize)
    try
      f(out)
    finally
      out.close
  }
}

