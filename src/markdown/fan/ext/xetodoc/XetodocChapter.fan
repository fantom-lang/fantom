//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Mar 2026  Brian Frank  Creation
//

**
** XetodocChapter is a simple DOM for the chapter meta and headings tree
** that can be used b/w compilerDoc and xetodoc
**
@Js @NoDoc
class XetodocChapter
{
  ** Parse a markdown file as a chapter into its meta and headings
  static XetodocChapter parse(Str file)
  {
    meta := Str:Str[:] { ordered = true }
    list := XetodocHeading[,]
    map  := Str:XetodocHeading[:]

    // read lines
    lines := file.splitLines

    // check leading comment for title: xxxx
    if (lines.first.trim == "<!--")
    {
      lines.eachWhile |line|
      {
        line = line.trim
        if (line == "-->") return "break"
        colon := line.index(":")
        if (colon == null) return null
        n := line[0..<colon].trim
        v := line[colon+1..-1].trim
        meta[n] = v
        return null
      }
    }

    // lazily parse just heading lines
    proc := HeadingProcessor()
    l := XetodocHeading[,]
    lines.each |line|
    {
      if (!line.startsWith("#")) return

      // compute level
      level := 0
      while (level+1 < line.size && line[level] == '#') level++

      // create heading instance
      text := line[level..-1].trim
      anchor := proc.toAnchor(text)
      h :=  XetodocHeading(level, text, anchor)

      // add to accumulator collections
      list.add(h)
      map[h.anchor] = h
    }

    // now organize into a tree
    top := XetodocHeading[,]
    list.each |h, i|
    {
      if (i == 1) { top.add(h); return }
      for (j := i-1; j >= 0; --j)
      {
        if (list[j].level < h.level)
        {
          parent := list[j]
          parent.children.add(h)
          return
        }
      }
      top.add(h)
    }

    return make {
      it.meta = meta
      it.top  = top
      it.byId = map
    }
  }

  private new make(|This| f) { f(this) }

  Str:Str meta

  Str? title() { meta["title"] }

  Str:Str anchorToTextMap() { byId.map |h->Str| { h.text } }

  XetodocHeading[] top

  Str:XetodocHeading byId

  Void dump()
  {
    echo("#####")
    echo(meta.join("\n"))
    echo("---")
    top.each |x| { x.dump(0) }
  }

  static Void main(Str[] args)
  {
    parse(args[0].toUri.toFile.readAllStr).dump
  }
}

**************************************************************************
** XetodocHeading
**************************************************************************

@Js @NoDoc
class XetodocHeading
{
  new make(Int level, Str text, Str anchor)
  {
    this.level  = level
    this.text   = text
    this.anchor = anchor
  }

  const Int level
  const Str text
  const Str anchor
  XetodocHeading[] children := [,]

  override Str toStr() { "$level | $text.toCode [#$anchor]" }

  Void dump(Int indent)
  {
    echo(Str.spaces(indent) + this)
    children.each |kid| { kid.dump(indent+2) }
  }
}

