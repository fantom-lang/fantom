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

  new of(Int lineIndex, Int columnIndex, Int inputIndex, Int len)
  {
    if (lineIndex < 0) throw ArgErr("lineIndex: ${lineIndex}")
    if (columnIndex < 0) throw ArgErr("columnIndex: ${lineIndex}")
    if (inputIndex < 0) throw ArgErr("inputIndex: ${lineIndex}")
    if (len < 0) throw ArgErr("len: ${lineIndex}")

    this.lineIndex = lineIndex
    this.columnIndex = columnIndex
    this.inputIndex = inputIndex
    this.len = len
  }

  ** 0-based line index, e.g. 0 for first line, 1 for second line, etc.
  const Int lineIndex

  ** 0-based index of column (i.e. character on line) in source, e.g. 0 for the
  ** first character of a line, 1 for the second character, etc.
  const Int columnIndex

  ** 0-based index in whole input
  const Int inputIndex

  ** Length of the span in characters
  const Int len

  SourceSpan subSpan(Int beginIndex, Int endIndex := this.len)
  {
    if (beginIndex < 0) throw ArgErr("beginIndex: ${beginIndex}")
    if (beginIndex > len) throw IndexErr("beginIndex ${beginIndex} must be <= length ${len}")
    if (endIndex < 0) throw ArgErr("endIndex: ${endIndex}")
    if (endIndex > len) throw IndexErr("endIndex ${endIndex} must be <= length ${len}")
    if (beginIndex > endIndex) throw IndexErr("beginIndex ${beginIndex} must be <= endIndex ${endIndex}")

    if (beginIndex == 0 && endIndex == len) return this
    return SourceSpan.of(lineIndex, columnIndex + beginIndex, inputIndex+beginIndex, endIndex-beginIndex)
  }

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
           this.inputIndex == that.inputIndex &&
           this.len == that.len
  }

  override Int hash()
  {
    res := 1
    res = (31 * res) + lineIndex.hash
    res = (31 * res) + columnIndex.hash
    res = (31 * res) + inputIndex.hash
    res = (31 * res) + len.hash
    return res
  }

  override Str toStr() { "SourceSpan(line=${lineIndex}, column=${columnIndex}, input=${inputIndex}, len=${len})" }
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
      if (a.inputIndex + a.len == b.inputIndex)
      {
        sourceSpans[lastIndex] = SourceSpan.of(a.lineIndex, a.columnIndex, a.inputIndex, a.len + b.len)
        sourceSpans.addAll(other[1..-1])
      }
      else sourceSpans.addAll(other)
    }
  }
}