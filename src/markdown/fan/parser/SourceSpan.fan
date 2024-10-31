//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Oct 2024  Matthew Giannini  Creation
//

**
** References a snippet of text from the source input.
**
** It has a starting positiont (line and column index) and a length
** of how many characters it spans.
**
@Js
const class SourceSpan
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Int lineIndex, Int columnIndex, Int len)
  {
    this.lineIndex = lineIndex
    this.columnIndex = columnIndex
    this.len = len
  }

  ** 0-based index of line in source
  const Int lineIndex

  ** 0-based index of column (i.e. character on line) in source
  const Int columnIndex

  ** Length of the span in characters
  const Int len

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  override Bool equals(Obj? obj)
  {
    if (this === obj) return true
    that := obj as SourceSpan
    if (that == null) return false
    return this.lineIndex == that.lineIndex &&
           this.columnIndex == that.columnIndex &&
           this.len == that.len
  }

  override Int hash()
  {
    res := 1
    res = (31 * res) + lineIndex.hash
    res = (31 * res) + columnIndex.hash
    res = (31 * res) + len.hash
    return res
  }

  override Str toStr() { "SourceSpan(line=${lineIndex}, column=${columnIndex}, len=${len}" }
}

**************************************************************************
** IncludeSourceSpans
**************************************************************************

**
** Enum for configuring whether to include SourceSpans or not while parsing.
**
@Js
enum class IncludeSourceSpans
{
  ** Do not include source spans
  none,
  ** Include source spans on Block nodes
  blocks,
  ** Include source spans on block nodes and inline nodes
  blocks_and_inlines
}

**************************************************************************
** SourceSpans
**************************************************************************

**
** A list of source spans that can be added to. Takes care of merging
** adjacent source spans
**
@Js
class SourceSpans
{
  static new empty() { SourceSpans.priv_make() }

  new priv_make() { }

  SourceSpan[] sourceSpans := [,] { private set }

  Void addAllFrom(Node[] nodes)
  {
    nodes.each |node| { addAll(node.sourceSpans) }
  }

  Void addAll(SourceSpan[] other)
  {
    if (other.isEmpty) return

    if (sourceSpans.isEmpty) sourceSpans.addAll(other)
    else
    {
      lastIndex := sourceSpans.size - 1
      a := sourceSpans[lastIndex]
      b := other[0]
      throw Err("TODO: need new input index stuff from 0.24 java")
    }
  }
}