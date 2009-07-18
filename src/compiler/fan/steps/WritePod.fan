//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Sep 05  Brian Frank  Creation
//   7 Oct 06  Brian Frank  Port from Java to Fan
//

**
** WritePod writes the FPod to a zip file.
**
class WritePod : CompilerStep
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Compiler compiler)
    : super(compiler)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  **
  ** Not used, use write instead
  **
  override Void run() { throw UnsupportedErr.make }

  **
  ** Run the step and return pod file written
  **
  File write()
  {
    dir  := compiler.input.outDir
    fpod := compiler.fpod
    podFile := dir + "${fpod.name}.pod".toUri
    location = Location.makeFile(podFile)

    log.info("WritePod [${podFile.toStr}]")

    // create output directory
    dir.create

    Zip? zip := null
    try
    {
      // open zip store
      zip = Zip.write(podFile.out)

      // write fpod data structures into zip file
      fpod.write(zip)

      // write type db indices
      if (!compiler.input.isScript)
        writeTypeDb(zip)

      // write resource files
      compiler.resFiles.each |File f| { writeRes(zip, f) }

      // if including fandoc write it out too
      if (compiler.input.includeDoc) writeDocs(zip)

      // if including source write it out too
      if (compiler.input.includeSrc) writeSrc(zip)
    }
    catch (CompilerErr e)
    {
      throw e
    }
    catch (Err e)
    {
      e.trace
      throw errReport(CompilerErr("Cannot write", location, e))
    }

    // close file
    if (zip != null) zip.close
    return podFile
  }

//////////////////////////////////////////////////////////////////////////
// Resource
//////////////////////////////////////////////////////////////////////////

  private Void writeRes(Zip zip, File file, Uri? path := null)
  {
    input := compiler.input
    if (path == null)
    {
      path = file.uri
      path = path.relTo(input.podDef.parent.uri)
    }

    try
    {
      out := zip.writeNext(path, file.modified)
      file.in.pipe(out)
      out.close
    }
    catch (Err e)
    {
      throw errReport(CompilerErr("Cannot write resource file '$path'", location, e))
    }
  }

//////////////////////////////////////////////////////////////////////////
// Doc
//////////////////////////////////////////////////////////////////////////

  private Void writeDocs(Zip zip)
  {
    writePodDoc(zip)
    compiler.types.each |TypeDef t|
    {
      if (!t.isSynthetic) writeTypeDoc(zip, t)
    }
  }

  **
  ** Pod fandoc follows same format as type apidocs except qname
  ** is "{podName}::pod" and symbols are "{podName}::pod.{symbol}".
  **
  private Void writePodDoc(Zip zip)
  {
    try
    {
      pod := compiler.pod
      out := zip.writeNext("doc/pod.apidoc".toUri)
      writeDoc(out, pod.name, pod)
      pod.symbolDefs.each |SymbolDef s|
      {
        writeDoc(out, s.qname, s)
      }
      out.close
    }
    catch (Err e)
    {
      throw errReport(CompilerErr("Cannot write pod fandoc", location, e))
    }
  }

  **
  ** FDoc is used to read/write a fandoc text file.  The fandoc file
  ** format is an extremely simple plan text format with left justified
  ** type/slot qnames, followed by the fandoc content indented two spaces.
  ** Addiontal type/slot meta-data is prefixed as "@name=value" lines.
  **
  private Void writeTypeDoc(Zip zip, TypeDef t)
  {
    try
    {
      out := zip.writeNext("doc/${t.name}.apidoc".toUri)
      writeDoc(out, t.qname, t)
      t.slotDefs.each |SlotDef s|
      {
        writeDoc(out, s.qname, s)
      }
      out.close
    }
    catch (Err e)
    {
      throw errReport(CompilerErr("Cannot write fandoc '$t.name'", t.location, e))
    }
  }

  private static Void writeDoc(OutStream out, Str key, DefNode node)
  {
    doc := node.doc
    meta := node.docMeta
    if (doc == null && (meta == null || meta.isEmpty)) return
    out.printLine(key)
    if (meta != null)
    {
      meta.each|Str val, Str name|
      {
        val = val.replace("\n", " ").replace("\r", " ")
        out.printLine("  @$name=$val")
      }
    }
    if (doc != null)
    {
      doc.each |Str line| { out.print("  ").printLine(line) }
    }
    out.printLine
  }

//////////////////////////////////////////////////////////////////////////
// Src
//////////////////////////////////////////////////////////////////////////

  private Void writeSrc(Zip zip)
  {
    compiler.srcFiles.each |File f|
    {
      writeRes(zip, f, "src/$f.name".toUri)
    }
  }

//////////////////////////////////////////////////////////////////////////
// TypeDb
//////////////////////////////////////////////////////////////////////////

  private Void writeTypeDb(Zip zip)
  {
    out := zip.writeNext(`/typedb.def`)

    // pod meta-data
    out.writeI4(FConst.TypeDbMagic)
    out.writeI4(FConst.TypeDbVersion)
    out.writeUtf(pod.name)
    out.writeUtf(compiler.fpod.version.toStr)

    // get pod facets we care about for typedb.def
    podFacets := pod.facets.exclude |f| { f.key.qname.startsWith("sys::podBuild") }

    // filter types
    types := pod.typeDefs.findAll |TypeDef t->Bool| { !t.isSynthetic }

    // compute list of all indexed facets
    facetNameList := Str[,]
    facetNameMap  := Str:Int[:]
    podFacets.each |FacetDef f|
    {
      facetNameMap[f.key.qname] = facetNameList.size
      facetNameList.add(f.key.qname)
    }
    types.each |TypeDef t|
    {
      t.indexedFacets = computeIndexedFacets(t.facets, facetNameList, facetNameMap)
    }

    // write facet names
    out.writeI2(facetNameList.size)
    facetNameList.each |Str n| { out.writeUtf(n) }

    // write pod level facets
    out.writeI2(podFacets.size)
    podFacets.each |FacetDef f|
    {
      out.writeI2(facetNameMap[f.key.qname])
      out.writeUtf(f.val.serialize)
    }

    // write types
    out.writeI2(types.size)
    types.each |TypeDef t| { writeTypeDbType(out, t, facetNameMap) }

    out.close
  }

  private FacetDef[] computeIndexedFacets(FacetDef[]? all, Str[] list, Str:Int map)
  {
    // if no facets defined, this is easy
    if (all == null || all.size == 0)
      return noFacets

    // strip out commonly used facets that we know aren't indexed
    // could eventually do a much better job here probably
    indexed := all.findAll |f|
    {
      qname := f.key.qname
      if (qname.startsWith("sys::"))
      {
        if (qname == "sys::js") return false
        if (qname == "sys::simple") return false
        if (qname == "sys::serializable") return false
        if (qname == "sys::collection") return false
        if (qname == "sys::nodoc") return false
      }
      return true
    }

    // map facet names into interned list/map
    indexed.each |FacetDef f|
    {
      qname := f.key.qname
      if (map[qname] == null)
      {
        map[qname] = list.size
        list.add(qname)
      }
    }

    return indexed
  }

  private Void writeTypeDbType(OutStream out, TypeDef t, Str:Int facetNames)
  {
    out.writeUtf(t.name)
    out.writeUtf(t.base == null ? "" : t.base.qname)
    out.writeI2(t.mixins.size)
    t.mixins.each |CType m| { out.writeUtf(m.qname) }
    out.writeI4(t.flags)
    out.writeI2(t.indexedFacets.size)
    t.indexedFacets.each |FacetDef f|
    {
      out.writeI2(facetNames[f.key.qname])
      out.writeUtf(f.val.serialize)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Location? location
  private FacetDef[] noFacets := FacetDef[,].ro
}