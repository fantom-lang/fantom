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
const class DocPod : DocPage
{

  ** Load from a zip file.  The given env is ued for error reporting.
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
      this.toc         = loader.toc
      this.types       = loader.typeList
      this.typeMap     = loader.typeMap
      this.chapters    = loader.chapterList
      this.chapterMap  = loader.chapterMap
      this.podDoc      = loader.podDoc
      this.resources   = loader.resourceList
      this.resourceMap = loader.resourceMap
      this.sources     = loader.sourceList
      this.sourceMap   = loader.sourceMap
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
  override Str title() { name }

  ** Always return `name`.
  override Str toStr() { name }

  ** Get the meta name/value pairs for this pod.
  ** See [docLang]`docLang::Pods#meta`.
  const Str:Str meta

  ** List of the public, documented types in this pod.
  const DocType[] types

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

  ** Return pod-doc file as a chapter instance or null
  const DocChapter? podDoc

  ** A *manual* pod is a pod with only fandoc chapters and no types.
  Bool isManual() { types.isEmpty && !chapters.isEmpty }

  ** If this a API pod, this is the Str/DocType where the string indicates
  ** groupings such as "Classes", "Mixins", etc.  If this is a manual return
  ** the list of Str/DocChapter where Str indicates index grouping headers.
  const Obj[] toc

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
  ** The Uris are internal to the pod zip file.
  const Uri[] resources

  ** Return pod internal URI to resource for filename, or
  ** if not available return null/raise exception.
  Uri? resource(Str filename, Bool checked := true)
  {
    uri := resourceMap[filename]
    if (uri != null) return uri
    if (checked) throw UnresolvedErr("resource file: $filename")
    return null
  }
  private const Str:Uri resourceMap

  ** Source files in pod which should be included in documentation.
  ** The Uris are internal to the pod zip file.
  const Uri[] sources

  ** Return pod internal URI to source code for filename, or
  ** if not available return null/raise exception.
  Uri? source(Str filename, Bool checked := true)
  {
    uri := sourceMap[filename]
    if (uri != null) return uri
    if (checked) throw UnresolvedErr("source file: $filename")
    return null
  }
  private const Str:Uri sourceMap

}

**************************************************************************
** DocPodLoader
**************************************************************************

internal class DocPodLoader
{
  new make(DocEnv env, File file, DocPod pod)
   {
    this.env  = env
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
        }

        // if doc/{type}.fandoc
        if (f.ext == "fandoc")
        {
          chapter := DocChapter(env, pod, f)
          chapters[chapter.name] = chapter
        }

        // if doc/index.fog
        else if (f.name == "index.fog")
        {
          indexFog = f.readObj
        }

        // otherwise assume its a resource
        else
        {
          resources.add(f.uri)
        }
      }
      catch (Err e) env.err("Cannot parse", DocLoc("${name}::${f}", 0), e)
    }

    // finish
    finishTypes(types)
    finishChapters(env, chapters, indexFog)
    finishResources(resources)
    finishSources(sources)
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

  private Void finishChapters(DocEnv env, Str:DocChapter map, Obj[]? indexFog)
  {
    // create sorted list of chapters
    list := map.vals.sort |a, b| { a.name <=> b.name }

    // if this pod has types, it can't be a manual
    if (!typeList.isEmpty)
    {
      if (list.size == 1 && list.first.isPodDoc)
        this.podDoc = list.first
      this.chapterMap  = map.toImmutable
      this.chapterList = list.toImmutable
      return
    }

    // generate indexFog if not specified
    if (indexFog == null)
    {
      if (!map.isEmpty) env.err("Manual missing '${name}::index.fog'", DocLoc(name, 0))
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
      catch { env.err("Invalid item: $item", indexLoc); return }

      // lookup chapter and remove from map so we know it was indexed
      c := indexMap.remove(uri.toStr)
      if (c == null) { env.err("Unknown chapter: $uri", indexLoc); return }

      // add it toc
      toc.add(c)

      // map summary
      c.summaryRef.val = summary
    }

    // report errors for chapters not in index
    indexMap.each |c| { env.err("Chapter not in index: $c.name", indexLoc) }

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

  private Void finishResources(Uri[] list)
  {
    this.resourceList = list.sort.toImmutable
    this.resourceMap  = Str:Uri[:].addList(list) |uri| { uri.name }.toImmutable
  }

  private Void finishSources(Uri[] list)
  {
    this.sourceList = list.sort.toImmutable
    this.sourceMap  = Str:Uri[:].addList(list) |uri| { uri.name }.toImmutable
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
  Uri[]? resourceList           // finishResource
  [Str:Uri]? resourceMap        // finishResource
  Uri[]? sourceList             // finishSource
  [Str:Uri]? sourceMap          // finishSource
  Obj[]? toc                    // finishTypes/finishChapters
}


