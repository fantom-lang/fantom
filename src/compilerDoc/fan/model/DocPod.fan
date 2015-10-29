//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//   19 Dec 11  Brian Frank  Redesign to make DocPod const
//

**
** DocPod models the documentation of a `sys::Pod`.
**
const class DocPod : DocSpace
{

  ** Load from a zip file.
  static DocPod load(DocEnv env, File file)
  {
    return DocPod(env, file)
  }

  ** Private constructor to copy loader fields
  @NoDoc new make(DocEnv env, File file)
  {
    this.file = file
    loader := DocPodLoader(env, file, this)
    zip := Zip.open(file)
    try
    {
      // first load meta data
      loader.loadMeta(zip)
      this.name    = loader.name
      this.version = loader.version
      this.summary = loader.summary
      this.meta    = loader.meta

      // next load meta
      loader.loadContent(zip)
      this.index      = loader.index
      this.types      = loader.typeList
      this.typeMap    = loader.typeMap
      this.podDoc     = loader.podDoc
      this.chapters   = loader.chapterList
      this.chapterMap = loader.chapterMap
      this.resList    = loader.resList
      this.resMap     = loader.resMap
      this.srcList    = loader.srcList
      this.srcMap     = loader.srcMap
    }
    finally zip .close
  }

  ** File the pod was loaded from
  const File file

  ** Simple name of the pod such as "sys".
  const Str name

  ** Version number for this pod.
  const Version version

  ** Summary string for the pod
  const Str summary

  ** Always return `name`.
  override Str toStr() { name }

  ** Get the meta name/value pairs for this pod.
  ** See [docLang]`docLang::Pods#meta`.
  const Str:Str meta

  ** Document which models the index page for this pod
  const DocPodIndex index

  ** List of the public, documented types in this pod.
  const DocType[] types

  ** Get the build timestamp or null if not available
  DateTime? ts() { DateTime.fromStr((meta["build.ts"] ?: meta["build.time"]) ?: "", false) }

  ** Find a type by name.  If the type doesn't exist and checked
  ** is false then return null, otherwise throw UnknownTypeErr.
  DocType? type(Str typeName, Bool checked := true)
  {
    t := typeMap[typeName]
    if (t != null) return t
    if (checked) throw UnknownTypeErr("${this.name}::${typeName}")
    return null
  }
  private const Str:DocType typeMap

  ** If this pod has an associated pod.fandoc chapter
  const DocChapter? podDoc

  ** A *manual* pod is a pod with two or more fandoc chapters and no types.
  Bool isManual() { types.isEmpty && chapters.size >= 2 }

  ** If this is a manual like docLang, return list of chapters.
  const DocChapter[] chapters

  ** Find a chapter by name.  If the chapter doesn't exist and
  ** checked is false then return null, otherwise throw Err.
  DocChapter? chapter(Str chapterName, Bool checked := true)
  {
    c := chapterMap[chapterName]
    if (c != null) return c
    if (checked) throw Err("Unknown chapter: ${this.name}::${chapterName}")
    return null
  }
  private const Str:DocChapter chapterMap

  ** Resource files in pod which are used to support the
  ** documentation such as images used by the fandoc chapters.
  ** Resources can only be located in doc/ sub-directory.
  const DocRes[] resList

  ** Return resource for filename, or if not available
  ** return null/raise exception.  This filenames is
  ** always relative to doc/ sub-directory.
  DocRes? res(Str filename, Bool checked := true)
  {
    uri := resMap[filename]
    if (uri != null) return uri
    if (checked) throw UnknownDocErr("resource file: $filename")
    return null
  }
  private const Str:DocRes resMap

  ** Source files in pod which should be included in documentation.
  const DocSrc[] srcList

  ** Return source code for filename, or if not
  ** available return null/raise exception.
  DocSrc? src(Str filename, Bool checked := true)
  {
    uri := srcMap[filename]
    if (uri != null) return uri
    if (checked) throw UnknownDocErr("source file: $filename")
    return null
  }
  private const Str:DocSrc srcMap

  ** Space name is same as `name`
  override Str spaceName() { name }

  **
  ** Find the document with the given name.  If not found raise
  ** UnknownDocErr or return null based on checked flag.
  ** The document namespace of a pod is:
  **   - "index": the DocPodIndex
  **   - "{type name}": DocType
  **   - "{chapter name}": DocChapter
  **   - "{filename}": DocRes
  **   - "src-{filename}": DocSrc
  **
  override Doc? doc(Str name, Bool checked := true)
  {
    // index
    if (name == "index") return index

    // type
    type := type(name, false)
    if (type != null) return type

    // chapter
    chapter := chapter(name, false)
    if (chapter != null) return chapter

    // source
    if (name.startsWith("src-"))
    {
      src := src(name[4..-1], false)
      if (src != null) return src
    }

    // resource
    res := res(name, false)
    if (res != null) return res

    // not found
    if (checked) throw UnknownDocErr("${this.name}::${name}")
    return null
  }

  override Void eachDoc(|Doc| f)
  {
    f(index)
    types.each(f)
    chapters.each(f)
    srcList.each(f)
    resList.each(f)
  }
}

**************************************************************************
** DocPodIndex
**************************************************************************

**
** DocPodIndex represents the index document of a DocPod.
**
const class DocPodIndex : Doc
{
  ** Constructor
  internal new make(DocPod pod, Obj[] toc)
  {
    this.pod = pod
    this.toc = toc
  }

  ** Parent pod
  const DocPod pod

  ** If this a API pod, this is the Str/DocType where the string indicates
  ** groupings such as "Classes", "Mixins", etc.  If this is a manual return
  ** the list of Str/DocChapter where Str indicates index grouping headers.
  const Obj[] toc

  ** The space for this doc is `pod`
  override DocSpace space() { pod }

  ** The document name under space is "index"
  override Str docName() { "index" }

  ** Title is pod name
  override Str title() { pod.name }

  ** Return true
  override Bool isSpaceIndex() { true }

  ** Default renderer is `DocPodIndexRenderer`
  override Type renderer() { DocPodIndexRenderer# }

  ** Index the type summary and all slot docs
  override Void onCrawl(DocCrawler crawler)
  {
    crawler.addKeyword(pod.name, pod.name, DocFandoc(DocLoc(pod.name, 0), pod.summary), null)
  }
}

**************************************************************************
** DocPodLoader
**************************************************************************

internal class DocPodLoader
{
  new make(DocEnv env, File file, DocPod pod)
  {
    this.env = env
    this.file = file
    this.pod  = pod
  }

  Void loadMeta(Zip zip)
  {
    // first read meta
    metaFile := zip.contents[`/meta.props`] ?: throw Err("Pod missing meta.props: $file")
    this.meta    = metaFile.readProps
    this.name    = getMeta("pod.name")
    this.summary = getMeta("pod.summary")
    this.version = Version.fromStr(getMeta("pod.version"))
  }

  private Str getMeta(Str n)
  {
    meta[n] ?: throw Err("Missing '$n' in meta.props")
  }

  Void loadContent(Zip zip)
  {
    // these are the data structures we'll be building up
    types     := Str:DocType[:]
    chapters  := Str:DocChapter[:]
    indexFog  := null
    resources := Uri[,]
    sources   := Uri[,]

    // iterate thru the zip file looking for the files we need
    zip.contents.each |f|
    {
      try
      {
        // if this is src/{file}, save to source list
        if (f.path[0] == "src")
        {
          if (f.path.size == 2) sources.add(f.uri)
          return
        }

        // we only care about files in doc/*
        if (f.path[0] != "doc") return

        // if doc/{type}.apidoc
        if (f.ext == "apidoc")
        {
          type := ApiDocParser(pod, f.in).parseType
          types[type.name] = type
          return
        }

        // if doc/{type}.fandoc
        if (f.ext == "fandoc")
        {
          chapter := DocChapter(this, f)
          chapters[chapter.name] = chapter
          return
        }

        // if doc/index.fog
        if (f.name == "index.fog")
        {
          indexFog = f.readObj
          return
        }

        // otherwise assume its a resource
        resources.add(f.uri)
      }
      catch (Err e) err("Cannot parse", DocLoc("${name}::${f}", 0), e)
    }

    // finish
    finishTypes(types)
    finishChapters(chapters, indexFog)
    finishResources(resources)
    finishSources(sources)
    finishIndex
  }

  private Void finishTypes(Str:DocType map)
  {
    // create sorted list
    list := map.vals.sort|a, b| { a.name <=> b.name }

    // filter out types which shouldn't be documented,
    // but leave them in the map for lookup
    list = list.exclude |t|
    {
      t.hasFacet("sys::NoDoc")     ||
      DocFlags.isInternal(t.flags) ||
      DocFlags.isSynthetic(t.flags)
    }

    // build toc
    toc := Obj[,]
    mixins  := DocType[,]
    classes := DocType[,]
    enums   := DocType[,]
    facets  := DocType[,]
    errs    := DocType[,]
    list.each |t|
    {
      if (t.isEnum) enums.add(t)
      else if (t.isFacet) facets.add(t)
      else if (t.isMixin) mixins.add(t)
      else if (t.isErr) errs.add(t)
      else classes.add(t)
    }
    if (mixins.size  > 0) toc.add("Mixins").addAll(mixins)
    if (classes.size > 0) toc.add("Classes").addAll(classes)
    if (enums.size   > 0) toc.add("Enums").addAll(enums)
    if (facets.size  > 0) toc.add("Facets").addAll(facets)
    if (errs.size    > 0) toc.add("Errs").addAll(errs)

    // save to fields
    this.typeMap  = map.toImmutable
    this.typeList = list.toImmutable
    this.toc      = toc.toImmutable
  }

  private Void finishChapters(Str:DocChapter map, Obj[]? indexFog)
  {
    // create sorted list of chapters
    list := map.vals.sort |a, b| { a.name <=> b.name }

    // if this pod has types, it can't be a manual
    if (!typeList.isEmpty || list.size <= 1)
    {
      this.podDoc = list.find |x| { x.isPodDoc }
      this.chapterList = this.podDoc == null ? DocChapter#.emptyList : DocChapter[podDoc]
      this.chapterMap  = Str:DocChapter[:].setList(this.chapterList) |x| { x.name }
      return
    }

    // generate indexFog if not specified
    if (indexFog == null)
    {
      if (!map.isEmpty) err("Manual missing '${name}::index.fog'", DocLoc(name, 0))
      indexFog = [,]
      list.each |c| { indexFog.add([c.name.toUri, ""]) }
    }

    // order the chapters by indexFog:
    //   - map DocChapter summary
    //   - check that chapters/index.fog match
    toc := Obj[,]
    indexLoc := DocLoc("${name}::index.fog", 0)
    indexMap := map.dup
    indexFog.each |item|
    {
      // grouping header
      if (item is Str) { toc.add(item); return }

      // get item as Uri/Str pair
      Uri? uri
      Str? summary
      try
      {
        uri = ((List)item).get(0)
        summary = ((List)item).get(1)
      }
      catch { err("Invalid item: $item", indexLoc); return }

      // lookup chapter and remove from map so we know it was indexed
      c := indexMap.remove(uri.toStr)
      if (c == null) { err("Unknown chapter: $uri", indexLoc); return }

      // add it toc
      toc.add(c)

      // map summary
      c.summaryRef.val = summary
    }

    // report errors for chapters not in index
    indexMap.each |c| { err("Chapter not in index: $c.name", indexLoc) }

    // redo list now that we have chapters ordered by index
    list = toc.findType(DocChapter#)

    // map DocChapter num/prev/next
    list.each |c, i|
    {
      c.numRef.val = i+1
      if (i > 0) c.prevRef.val = list[i-1]
      c.nextRef.val = list.getSafe(i+1)
    }

    // save to fields
    this.chapterMap  = map.toImmutable
    this.chapterList = list.toImmutable
    this.toc         = toc.toImmutable
  }

  private Void finishResources(Uri[] uris)
  {
    DocRes[] list := uris.sort.map |uri->DocRes| { DocRes(pod, uri) }
    this.resList = list.toImmutable
    this.resMap  = Str:DocRes[:].addList(list) |res| { res.uri.name }.toImmutable
  }

  private Void finishSources(Uri[] uris)
  {
    DocSrc[] list := uris.sort.map |uri->DocSrc| { DocSrc(pod, uri) }
    this.srcList = list.toImmutable
    this.srcMap  = Str:DocSrc[:].addList(list) |src| { src.uri.name }.toImmutable
  }

  private Void finishIndex()
  {
    this.index = DocPodIndex(pod, toc)
  }

  Void err(Str msg, DocLoc loc, Err? cause := null)
  {
    env.err(msg, loc, cause)
  }

  DocEnv env                    // ctor
  File file                     // ctor
  DocPod pod                    // ctor
  [Str:Str]? meta               // load
  Str? name                     // loadMeta
  Str? summary                  // loadMeta
  Version? version              // loadMeta
  DocType[]? typeList           // finishTypes
  [Str:DocType]? typeMap        // finishTypes
  DocChapter[]? chapterList     // finishChapters
  [Str:DocChapter]? chapterMap  // finishChapters
  DocChapter? podDoc            // finishChapters
  DocRes[]? resList             // finishResource
  [Str:DocRes]? resMap          // finishResource
  DocSrc[]? srcList             // finishSource
  [Str:DocSrc]? srcMap          // finishSource
  Obj[]? toc                    // finishTypes/finishChapters
  DocPodIndex? index            // finishIndex
}


