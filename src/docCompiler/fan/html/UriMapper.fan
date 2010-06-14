//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 May 07  Brian Frank  Creation
//

using compiler
using fandoc

**
** UriMapper is used to normalize fandoc URIs into hrefs to
** their HTML file representation using relative URLs.
**
class UriMapper : DocCompilerSupport
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(DocCompiler compiler) { this.compiler = compiler }

//////////////////////////////////////////////////////////////////////////
// DocCompilerSupport
//////////////////////////////////////////////////////////////////////////

  override DocCompiler compiler

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Given a fandoc uri string, map it to a relative URL
  ** to the resource's HTML by setting targetUri, targetIsCode
  ** and targetIsSlot fields.  If the URI cannot be mapped
  ** then an error is logged.
  **
  Uri map(Str fandocUri, Loc loc)
  {
    this.fandocUri    = fandocUri
    this.loc          = loc
    this.frag         = null
    this.targetUri    = null
    this.targetIsCode = false
    this.targetIsSlot = false

    // if document internal fragment identifer then
    // bail now before we do any work or use our cache
    // which spans all the documents in the current pod
    // reset working fields
    if (fandocUri.startsWith("#"))
      return targetUri = Uri.fromStr(fandocUri)

    // if absolute then bail
    if (fandocUri.startsWith("http:")  ||
        fandocUri.startsWith("https:") ||
        fandocUri.startsWith("ftp:")   ||
        fandocUri.startsWith("mailto:"))
      return targetUri = Uri.fromStr(fandocUri)

    // check the cache
    cached := cache[fandocUri]
    if (cached != null)
    {
      targetUri    = cached.targetUri
      targetIsCode = cached.targetIsCode
      return targetUri
    }

    // strip off fragment if specified
    pound := fandocUri.index("#")
    if (pound != null)
    {
      // if URI is to frag within doc we are done
      if (pound == 0) return targetUri = Uri.fromStr(fandocUri)

      // split off fragment identifier
      this.fandocUri = fandocUri[0..<pound]
      this.frag = fandocUri[pound+1..-1]
    }

    // map
    try
    {
      targetUri = doMap(fandocUri, loc)
      if (targetUri == null)
      {
        errReport(CompilerErr("Cannot map uri '$fandocUri'", loc))
        targetUri = fandocUri.toUri
      }

      // cache for next time
      if (!targetIsSlot)
        cache[fandocUri] = CachedUri(targetUri, targetIsCode)
    }
    catch (CompilerErr e)
    {
      targetUri = fandocUri.toUri
    }
    catch (Err e)
    {
      errReport(CompilerErr("Cannot map uri '$fandocUri'", loc, e))
      targetUri = fandocUri.toUri
    }

    // return result
    return targetUri
  }

  **
  ** Given a fandoc uri string, map it to a relative URL to the
  ** resource's HTML or return null if it cannot be mapped.
  ** If the fandocUri should be formatted as using a code font
  ** then set `targetIsCode`.
  **
  virtual Uri? doMap(Str fandocUri, Loc loc)
  {
    if (fandocUri.contains("::"))
      mapPod
    else if (compiler.pod != null)
      mapTypeOrFile(compiler.pod, this.fandocUri)
    return targetUri
  }

//////////////////////////////////////////////////////////////////////////
// Map
//////////////////////////////////////////////////////////////////////////

  private Void mapPod()
  {
    // lookup pod
    colons := fandocUri.index("::")
    podName := fandocUri[0..<colons]

    // handle examples specially
    if (podName == "examples")
    {
      targetUri = mapExample(fandocUri[colons+2..-1])
      targetIsCode = false
      return
    }

    pod := Pod.find(podName, false)
    if (pod == null) throw err("Unknown pod '$podName'", loc)

    rest := fandocUri[colons+2..-1]
    mapTypeOrFile(pod, rest)
  }

  private Uri mapExample(Str file)
  {
    if (file == "index") return `../examples/index.html`

    // for now just assume examples maps to source path
    dash := file.index("-")
    if (dash == null) throw err("Invalid example script '$file'", loc)
    n1 := file[0..<dash]
    n2 := file[dash+1..-1]
    f := Env.cur.homeDir + `examples/${n1}/${n2}.fan`
    if (!f.exists) throw err("Unknown example script $f", loc)
    return `../examples/${file}.html`
  }

  private Void mapTypeOrFile(Pod pod, Str s)
  {
    typeName := s
    Str? rest := null

    if (s == "index")
    {
      targetUri = toUri(pod, "index.html", frag)
      return
    }

    if (s == "pod-doc")
    {
      targetUri = toUri(pod, "pod-doc.html", frag)
      return
    }

    dot := s.index(".")
    if (dot != null)
    {
      typeName = s[0..<dot]
      rest = s[dot+1..-1]
    }
    else if (compiler.curType != null)
    {
      // if this string maps to a slot in the current
      // type being processes - then slot name trumps
      t := compiler.curType
      slot := t.slot(s, false)
      if (slot != null)
      {
        targetIsSlot = true
        targetUri = toUri(slot.parent.pod, "${slot.parent.name}.html", slot.name)
        return
      }
    }

    // first try type in pod
    t := pod.type(typeName, false)
    if (t != null)
    {
      mapSlot(t, rest)
      return
    }

    // if dot ext, this must be a filename which we don't do yet
    // TODO: eventually we need we need a standard mechanism
    // to determine which resources to copy to the doc directory
    // probably under some specific dir, which we can map
    if (rest != null)
    {
      if (fandocUri.endsWith(".html"))
      {
        echo("WARNING: Need to fix unresolved fandoc uri bug: $fandocUri")
        targetUri = fandocUri.toUri
      }
      else
      {
        throw err("Unresolved fandoc uri '$fandocUri'", loc)
      }
    }

    // try to find fandoc file in pod
    fandocFile := pod.files.find |File f->Bool|
    {
      return f.basename == typeName && f.ext == "fandoc"
    }

    if (fandocFile == null)
      throw err("Unresolved fandoc uri '$fandocUri'", loc)

    // if this a fragment identifier within the
    // fandoc file then check that it exists
    if (frag != null)
    {
      // ensure we've parsed the fandoc file into memory
      // to create a table of all the fragment identifiers
      if (fandocFrags[fandocUri] == null)
        fandocFrags[fandocUri] = parseFandocFrags(fandocFile)

      // check that the fragment exists
      if (!fandocFrags[fandocUri].frags.containsKey(frag))
        throw err("Unknown fragment '#$frag' in '$fandocUri'", loc)
    }

    // we can now build our uri
    targetUri = toUri(pod, "${fandocFile.basename}.html", frag)
  }

  private Void mapSlot(Type t, Str? rest)
  {
    targetIsCode = true
    Str? slotFrag := null

    // if rest it must be a slot name
    if (rest != null)
    {
      slot := t.slot(rest, false)
      if (slot == null)
        throw err("Unresolved uri to slot '${t.qname}.$rest'", loc)
      if (slot.parent != t)
        throw err("Uri to inherited slot '${t.qname}.$rest' is declared on '$slot.parent'", loc)
      slotFrag = slot.name
      targetIsSlot = true
    }

    targetUri = toUri(t.pod, "${t.name}.html", slotFrag)
  }

  private Uri toUri(Pod pod, Str uri, Str? frag)
  {
    if (pod != compiler.pod) uri = "../$pod.name/" + uri
    if (frag != null) uri = uri + "#" + frag
    return Uri.fromStr(uri)
  }

//////////////////////////////////////////////////////////////////////////
// FandocFrag Parse
//////////////////////////////////////////////////////////////////////////

  private FandocFrags parseFandocFrags(File f)
  {
    try
    {
      log.debug("    Parse fandoc frag [$fandocUri]")
      docFrags := FandocFrags.make
      f.readAllLines.each |Str line|
      {
        x := line.index("[#")
        if (x != null)
        {
          y := line.index("]", x)
          if (y != null)
          {
            frag := line[x+2..<y]
            docFrags.frags[frag] = frag
          }
        }
      }
      return docFrags
    }
    catch (Err e)
    {
      e.trace
      throw err("Cannot parse fandoc file for fragments: $f", loc)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Str? fandocUri
  Str? frag
  Loc? loc
  Uri? targetUri
  Bool targetIsCode
  Bool targetIsSlot
  internal Str:CachedUri cache := Str:CachedUri[:]
  internal Str:FandocFrags fandocFrags := Str:FandocFrags[:]
}

internal class CachedUri
{
  new make(Uri uri, Bool isCode)
  {
    targetUri    = uri
    targetIsCode = isCode
  }

  Uri targetUri
  Bool targetIsCode
}

internal class FandocFrags
{
  Str:Str frags := Str:Str[:]
}