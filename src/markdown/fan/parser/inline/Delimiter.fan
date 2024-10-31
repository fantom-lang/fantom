//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Oct 2024  Matthew Giannini  Creation
//

// **
// ** A delimiter run is one or more of the same delimiter character, e.g. '***'
// **
// mixin DelimiterRun
// {
//   ** Whether this can open a delimiter
//   abstract Bool canOpen()

//   ** Whether this can close a delimiter
//   abstract Bool canClose()
// }

**************************************************************************
** Delimiter
**************************************************************************

**
** Delimiter (emphasis, strong emphasis, or custom emphasis)
**
@Js
class Delimiter
{
  // new makeThis(|This| f) { f(this) }
  new make(Text[] chars, Int delimChar, Bool canOpen, Bool canClose, Delimiter? prev)
  {
    this.chars = chars
    this.delimChar = delimChar
    this.canOpen = canOpen
    this.canClose = canClose
    this.prev = prev
    this.origSize = chars.size
  }

  Text[] chars { private set }
  const Int delimChar

  ** The number of characters originally in this delimiter run; at the start of processing,
  ** this is the same as `size`
  const Int origSize

  ** can open emphasis, see spec.
  const Bool canOpen

  ** can close emphasis, see spec.
  const Bool canClose

  Delimiter? prev
  Delimiter? next

  ** The number of characters in this delimiter run (that are left for processing)
  Int size() { chars.size }

  ** Return the innermost opening delimiter, e.g. for '***' this is the last '*'
  Text opener() { chars[chars.size - 1] }

  ** Return the innermost closing delimiter, e.g. for '***' this is the first '*'
  Text closer() { chars.first }

  ** Get the opening delimiter nodes for the specified number of delimiters.
  **
  ** For example, for a delimiter run '***', calling this with 1 would return the
  ** last '*'.  Calling it with 2 would return the second last '*' and last '*'.
  Text[] openers(Int len)
  {
    if (!(len >= 1 && len <= this.size))
      throw ArgErr("len must be between 1 and ${this.size}, was ${len}")

    return chars[(chars.size - len)..<chars.size]
  }

  ** Get the closing delimiter nodes for the specified number of delimiters.
  **
  ** For example, for a delimiter run '***', calling this with 1 would return the
  ** first '*', calling it with 2 would return the first '*' and the second '*'.
  Text[] closers(Int len)
  {
    if (!(len >= 1 && len <= this.size))
      throw ArgErr("len must be between 1 and ${this.size}, was ${len}")

    return chars[0..<len]
  }

  override Str toStr()
  {
    """Delimiter: ${delimChar.toChar} origSize=${origSize}
         chars:    ${chars}
         canOpen:  ${canOpen}
         canClose: ${canClose}"""
  }
}

**************************************************************************
** Bracket
**************************************************************************

**
** Opening bracket for links '[', images '![', or links with other markers.
**
@Js
internal class Bracket
{
  static new link(Text bracketNode, Position bracketPos, Position contentPos,
    Bracket? prev, Delimiter? prevDelim)
  {
    Bracket
    {
      it.markerNode = null
      it.markerPos = null
      it.bracketNode = bracketNode
      it.bracketPos = bracketPos
      it.contentPos = contentPos
      it.prev = prev
      it.prevDelim = prevDelim
    }
  }

  static new withMarker(Text markerNode, Position markerPos, Text bracketNode,
    Position bracketPos, Position contentPos, Bracket? prev, Delimiter? prevDelim)
  {
    Bracket
    {
      it.markerNode = markerNode
      it.markerPos = markerPos
      it.bracketNode = bracketNode
      it.bracketPos = bracketPos
      it.contentPos = contentPos
      it.prev = prev
      it.prevDelim = prevDelim

    }
  }
  new make(|This| f)
  {
    f(this)
  }

  ** The node of a marker such as '!' if present, null otherwise
  Text? markerNode { protected set }

  ** The position of the marker if present, null otherwise
  const Position? markerPos

  ** The node of '['
  Text bracketNode { protected set }

  ** The position of '['
  const Position bracketPos

  ** The position of the content (after the opening bracket)
  const Position contentPos

  ** The previous bracket
  Bracket? prev { private set }

  ** Previous delimiter (emphasis, etc) before this bracket
  Delimiter? prevDelim { private set }

  ** Whether this bracket is allowed to form a link/image (also known as "active")
  Bool allowed := true

  ** Whether there is an unescaped bracket (opening or closing) after this
  ** opening bracket in the text parsed so far.
  Bool bracketAfter := false

}