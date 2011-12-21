//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 11  Brian Frank  Creation
//

using web

**
** DocLinker is responsible for mapping shortcut URI syntax
** to the actual URI for their HTML page.  A new instance is used
** for each link to check and resolve the link.
**
** The following link formats are built-in:
**
**    Format             Display     Links To
**    ------             -------     --------
**    pod::index         pod         absolute link to pod index
**    pod::pod-doc       pod         absolute link to pod doc chapter
**    pod::Type          Type        absolute link to type qname
**    pod::Types.slot    Type.slot   absolute link to slot qname
**    pod::Chapter       Chapter     absolute link to book chapter
**    pod::Chapter#frag  Chapter     absolute link to book chapter anchor
**    Type               Type        pod relative link to type
**    Type.slot          Type.slot   pod relative link to slot
**    slot               slot        type relative link to slot
**    Chapter            Chapter     pod relative link to book chapter
**    Chapter#frag       Chapter     pod relative link to chapter anchor
**    #frag              heading     chapter relative link to anchor
**
** All URI linking assumes a two level URI namespace of:
**    {pod}/index.html
**    {pod}/pod-doc.html
**    {pod}/{type}.html
**    {pod}/{type}-src.html
**    {pod}/{Chapter}.html
**
** The constructor parses the `link` string using the following
** standardized syntax:
**
**   // format
**   podPart::namePart.slotPart#fragPart
**
**   example       podPart  namePart  dotPart   fragPart
**   -------       -------  -------   -------   --------
**   foo::Bar#xyz  foo      Bar       null      xyz
**   foo::Bar.xyz  foo      Bar       xyz       null
**   foo::Bar      foo      Bar       null      null
**   Bar           null     Bar       null      null
**
class DocLinker
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** All subclasses must define a it-block constructor.
  new make(|This| f)
  {
    // call it-block
    f(this)

    // check base
    if (base is DocPod)
    {
      basePod = base
    }
    else if (base is DocType)
    {
      baseType = base
      basePod  = baseType.pod
    }
    else if (base is DocChapter)
    {
      baseChapter = base
      basePod = baseChapter.pod
    }
    else throw Err("Invalid base type: $base.typeof")

    // check absolute
    colon := link.index(":")
    if (colon != null && link[colon+1] != ':')
    {
      isAbs = link.startsWith("http:")  ||
              link.startsWith("https:") ||
              link.startsWith("ftp:")   ||
              link.startsWith("mailto:")
    }

    // split podPart::namePart
    namePart = link
    if (colon != null && link[colon+1] == ':')
    {
      podPart  = link[0..<colon]
      namePart = link[colon+2..-1]
    }

    // split namePart#fragPart
    pound := namePart.indexr("#")
    if (pound != null)
    {
      fragPart = namePart[pound+1..-1]
      namePart = namePart[0..<pound]
    }

    // split namePart.dotPart
    dot := namePart.index(".")
    if (dot != null)
    {
      dotPart  = namePart[dot+1..-1]
      namePart = namePart[0..<dot]
    }

    // figure out pod field which is pod to use for resolution;
    // either explicitly qualified by podPart or default to basePod
    pod = podPart == null ? basePod : env.space(podPart, false) as DocPod
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  ** Associated environment
  DocEnv env { internal set }

  ** Base of current link: must be `DocPod`, `DocType`, or `DocChapter`
  Obj base { internal set }

  ** Pod derived from `base`
  DocPod basePod { private set }

  ** Type derived from `base` or null if not inside a type definition
  const DocType? baseType

  ** Chapter derived from `base` or null if not inside a chapter
  const DocChapter? baseChapter

  ** Link string to parse
  const Str link

  ** Location for error reporting
  const DocLoc loc

  ** Is the link an absolute URI such as "http://foo/"
  const Bool isAbs

  ** Pod part if `link` is fully qualified with "::"
  const Str? podPart

  ** Main name of `link` with `podPart`, `dotPart`, `fragPart` stripped off
  const Str namePart

  ** Part of `link` which comes after "." dot
  const Str? dotPart

  ** Fragment anchor part if `link` has "#frag"
  const Str? fragPart

  ** This is the pod to use for resolution.  If `podPart` is non-null
  ** then this is resolved pod or null if pod was not found.  Otherwise
  ** we assume resolution inside `basePod`.
  DocPod? pod

//////////////////////////////////////////////////////////////////////////
// Resolution
//////////////////////////////////////////////////////////////////////////

  ** Resolve `link` and if not resolved throw DocErr
  virtual DocLink? resolve()
  {
    // unless explicitly handled, just map example URIs to fantom.org
    if (podPart == "examples")
     return DocLink(`http://fantom.org/doc/examples/${namePart}.html`, link)

    // if we weren't able to resolve our current pod, time to bail
    if (pod == null) throw err("unknown pod: $podPart")

    // check for absolute URIs
    if (isAbs) return resolveAbs

    // check for frag
    if (namePart.isEmpty && fragPart != null)
    {
      if (baseChapter == null) throw err("invalid frag outside of chapter")
      return resolveChapter(baseChapter)
    }

    // special: index
    if (namePart == "index") return resolvePodIndex

    // special: pod-doc
    if (namePart == "pod-doc")
    {
      if (pod.podDoc == null) throw err("unknown pod-doc: $pod.name")
      return resolveChapter(pod.podDoc)
    }

    // check for slot in current type
    slot := baseType?.slot(namePart, false)
    if (slot != null) return resolveSlot(slot, true)

    // if this pod is a manual, then it doesn't contain types
    if (pod.isManual)
    {
      // check ".slot" not defined
      if (dotPart != null) throw err("Cannot have dotPart in chapters")

      // resolve chapter
      chapter := pod.chapter(namePart, false)
      if (chapter == null) throw err("unknown chapter: ${pod}::${namePart}")
      return resolveChapter(chapter)
    }

    // at this point namePart must be type or chapter
    type := pod.type(namePart, false)
    if (type == null) throw err("unknown type: ${pod}::${namePart}")

    // if we don't have dotPart, then just go to type
    if (dotPart == null) return resolveType(type)

    // otherwise resolve slot
    slot = type.slot(dotPart, false)
    if (slot == null) throw err("unknown slot: ${type.qname}.${dotPart}")
    return resolveSlot(slot, false)

    throw err(null)
  }

  ** Resolve an absolute link such as "http://acme.com/"
  private DocLink resolveAbs()
  {
    DocLink(link.toUri, link, false)
  }

  ** Resolve `pod` to its index file
  private DocLink resolvePodIndex()
  {
    DocLink(toUri("index"), pod.name, !pod.isManual)
  }

  ** Check and resolve `pod` to its pod-doc fandoc file
  private DocLink resolveChapter(DocChapter c)
  {
    // check fragment maps to valid anchorId
    DocHeading? h := null
    if (fragPart != null)
    {
      h = c.heading(fragPart, false)
      if (h == null) throw err("invalid frag id: ${c.qname}#${fragPart}")
    }

    if (c.isPodDoc)
    {
      // pod-doc is rolled into index
      return DocLink(toUri("index", fragPart ?: "pod-doc"), pod.name, false)
    }
    else
    {
      // link to normal chapter
      return DocLink(toUri(c.name, fragPart), c.name, false)
    }
  }

  ** Resolve link to type
  private DocLink resolveType(DocType t)
  {
    DocLink(toUri(t.name), t.name, true)
  }

  ** Resolve link to slot anchor within a type
  private DocLink resolveSlot(DocSlot s, Bool inBaseType)
  {
    DocLink(toUri(s.parent.name, s.name), inBaseType ? s.name : s.dis, true)
  }

  ** Convert a basename within the scope of `pod` to a URI
  ** and append ".html" extension.  Also prefix path with "../"
  ** if pod != basePod.
  ** Example:
  **   toUri("Foo") ==> "../Foo.html"
  virtual Uri toUri(Str basename, Str? anchor := null)
  {
    s := StrBuf()
    if (pod.name != basePod.name) s.add("../").add(pod.name).add("/")
    s.add(basename)
    s.add(".html")
    if (anchor != null) s.add("#").add(anchor)
    return s.toStr.toUri
  }

//////////////////////////////////////////////////////////////////////////
// Error Handling
//////////////////////////////////////////////////////////////////////////

  ** Return exception to throw.
  DocErr? err(Str? subMsg)
  {
    s := StrBuf()
    s.add("Broken link `").add(link).add("`")
    if (subMsg != null) s.add("; ").add(subMsg)
    return DocErr(s.toStr, loc)
  }

}

**************************************************************************
** DocLink
**************************************************************************

**
** DocLink models a resolved URI - it is the result of `DocLinker`.
**
const class DocLink
{
  ** Construct with `uri`, `dis`, `isCode`
  new make(Uri uri, Str dis, Bool isCode := false)
  {
    this.uri    = uri
    this.dis    = dis
    this.isCode = isCode
  }

  ** URI to use for actual hyperlink
  const Uri uri

  ** Display string for hyperlink
  const Str dis

  ** Does link resolve to a code API like a pod, type, or slot
  ** in which case display using code style
  const Bool isCode
}


