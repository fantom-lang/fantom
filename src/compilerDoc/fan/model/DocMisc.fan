//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 11  Brian Frank  Creation
//

**************************************************************************
** DocTopIndex
**************************************************************************

**
** DocTopIndex models the top-level index
**
const class DocTopIndex : Doc
{
  ** It-block constructor
  new make(|This|? f := null) { if (f != null) f(this) }

  ** Spaces to index
  const DocSpace[] spaces := [,]

  ** Get the spaces which as instances of DocPod
  DocPod[] pods() { spaces.findType(DocPod#) }

  ** Throw UnsupportedErr
  override DocSpace space() { throw UnsupportedErr() }

  ** Throw UnsupportedErr
  override Str docName() { "index" }

  ** Default is "Doc Index"
  override const Str title := "Doc Index"

  ** Default renderer `DocTopIndexRenderer`
  override const Type renderer := DocTopIndexRenderer#

  ** Return true
  override Bool isTopIndex() { true}

  ** Debug string
  override Str toStr() { typeof.name }
}

**************************************************************************
** DocRes
**************************************************************************

**
** DocRes models a resource file within a pod.
**
const class DocRes : Doc
{
  ** Construct for pod and uri
  internal new make(DocPod pod, Uri uri)
  {
    this.pod = pod
    this.uri = uri
  }

  ** Pod which contains the resource
  const DocPod pod

  ** Uri of the resource file inside the pod
  const Uri uri

  ** The space for this doc is `pod`
  override DocSpace space() { pod }

  ** Document name under space is filename
  override Str docName() { uri.name }

  ** Title is the filename
  override Str title() { uri.name }

  ** Throw UnsupportedErr
  override Type renderer() { throw UnsupportedErr() }
}

**************************************************************************
** DocSrc
**************************************************************************

**
** DocSrc models a page of source code for display.
**
const class DocSrc : Doc
{
  ** Construct for pod and uri
  internal new make(DocPod pod, Uri uri)
  {
    this.pod = pod
    this.uri = uri
  }

  ** Pod which contains the source file
  const DocPod pod

  ** Uri of the source file inside the pod
  const Uri uri

  ** The space for this doc is `pod`
  override DocSpace space() { pod }

  ** Document name under space is "src-{filename}"
  override Str docName() { "src-${uri.name}" }

  ** Title is the filename
  override Str title() { uri.name }

  ** Breadcrumb name is the filename
  override Str breadcrumb() { uri.name }

  ** Default renderer is `DocSrcRenderer`
  override Type renderer() { DocSrcRenderer# }
}

**************************************************************************
** DocLoc
**************************************************************************

**
** DocLoc models a filename / linenumber
**
const class DocLoc
{
  const static DocLoc unknown := DocLoc("Unknown", 0)

  ** Construct with file and line number (zero if unknown)
  new make(Str file, Int line)
  {
    this.file = file
    this.line = line
  }

  ** Filename location
  const Str file

  ** Line number or zero if unknown
  const Int line

  ** Return string representation
  override Str toStr()
  {
    if (line <= 0) return file
    return "$file [Line $line]"
  }
}

**************************************************************************
** DocFandoc
**************************************************************************

**
** Wrapper for Fandoc string for a chapter, type, or slot
**
const class DocFandoc
{
  ** Construct from `loc` and `text`
  new make(DocLoc loc, Str text)
  {
    this.loc = loc
    this.text = text
  }

  ** Return the first sentence of fandoc
  DocFandoc firstSentence()
  {
    DocFandoc(loc, firstSentenceStrBuf.toStr)
  }

  ** Return the first sentence of fandoc as a StrBuf
  @NoDoc StrBuf firstSentenceStrBuf()
  {
    buf := StrBuf()
    for (i:=0; i<text.size; i++)
    {
      ch := text[i]
      peek := i<text.size-1 ? text[i+1] : -1
      if (ch == '.' && (peek == ' ' || peek == '\n'))
      {
        buf.addChar(ch)
        break;
      }
      else if (ch == '\n')
      {
        if (peek == -1 || peek == ' ' || peek == '\n') break
        else buf.addChar(' ')
      }
      else buf.addChar(ch)
    }
    if (buf.size > 1 && buf[-1] == ':') buf.remove(-1)
    return buf
  }

  ** Location of fandoc in source file
  const DocLoc loc

  ** Plain text fandoc string
  const Str text
}

