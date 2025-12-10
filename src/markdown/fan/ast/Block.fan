//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Oct 2024  Matthew Giannini  Creation
//

**
** A block node.
**
** We can think of a document as a sequence of blocks - structural
** elements like paragraphs, block quotations, lists, headings, rules,
** and code blocks. Some blocks contain other blocks; others contain
** inline content (text, images, code spans, etc.).
**
@Js
abstract class Block : Node
{
  override Block? parent() { super.parent }

  protected override Void setParent(Node? p)
  {
    if (p isnot Block)
      throw ArgErr("Parent of block must also be a block")
    super.setParent(p)
  }
}

**************************************************************************
** Document
**************************************************************************

** Document is the root node of the AST
@Js
final class Document : Block
{
  new make() { }

  ** Get the file this document was generated from, or null if not known
  File? file { private set }

  ** Set the file that was used to generate this document
  This withFile(File file) { this.file = file; return this }
}

**************************************************************************
** Heading
**************************************************************************

** A heading (ATX or Setext):
** pre>
** First heading
** =============
**
** ## Another heading
** <pre
@Js
class Heading : Block
{
  new make(Int level := 0) { this.level = level }

  ** The heading "level"
  const Int level

  ** The anchor id to use for this heading.
  Str? anchor

  override protected Str toStrAttributes() { "level=${level} anchor=${anchor}" }
}

**************************************************************************
** BlockQuote
**************************************************************************

** A block quote:
** pre>
** > some quoted text
** <pre
** Note that child nodes are themselves blocks, e.g. `Paragraph`, `ListBlock`, etc.
@Js
class BlockQuote : Block { }

**************************************************************************
** FencedCode
**************************************************************************

** Fenced code block
** pre>
** ```
** foo
** bar
** ```
** <pre
@Js
class FencedCode : Block
{
  new make(Str? fenceChar := null)
  {
    this.fenceChar = fenceChar
  }

  ** The fence character that was used, e.g. '`', or '~', if available, or null otherwise
  Str? fenceChar

  Int fenceIndent := 0

  ** The length of the opening fence (how many of the `fenceChar` were used to start
  ** the code block) if available, or null otherwise
  Int? openingFenceLen
  {
    set {
      if (it != null && it < 3) throw ArgErr("openingFenceLen needs to be >= 3")
      checkFenceLens(it, closingFenceLen)
      &openingFenceLen = it
    }
  }

  ** The length of the closing fence (how many of the `fenceChar` were used to end
  ** the code block) if available, or null otherwise
  Int? closingFenceLen
  {
    set {
      if (it != null && it < 3) throw ArgErr("closingFenceLen needs to be >= 3")
      checkFenceLens(openingFenceLen, it)
      &closingFenceLen = it
    }
  }

  ** Optional info string (see spec), e.g. 'fantom' in '```fantom'
  Str? info

  Str? literal

  private static Void checkFenceLens(Int? openingFenceLen, Int? closingFenceLen)
  {
    if (openingFenceLen != null && closingFenceLen != null)
    {
      if (closingFenceLen < openingFenceLen)
        throw ArgErr("fence lengths required to be: closingFenceLen >= openingFenceLen")
    }
  }
}

**************************************************************************
** HtmlBlock
**************************************************************************

** HTML block
@Js
class HtmlBlock : Block
{
  new make(Str? literal := null) { this.literal = literal }

  Str? literal
}

**************************************************************************
** ThematicBreak
**************************************************************************

** A thematic break, e.g. between text:
** pre>
** Some text
**
** ---
**
** Some other text.
** <pre
@Js
class ThematicBreak : Block
{
  new make(Str? literal := null) { this.literal = literal }

  ** source literal that represents this break, if available
  Str? literal
}

**************************************************************************
** IndentedCode
**************************************************************************

** An indented code block:
** pre>
** Code follows:
**
**     foo
**     bar
** <pre
@Js
class IndentedCode : Block
{
  new make(Str? literal := null) { this.literal = literal }

  ** Indented code literal
  Str? literal
}

** Abstract base class for list blocks
@Js
abstract class ListBlock : Block
{
  ** Whether this list is tight or loose
  **
  ** spec: A list is loose if any of its constituent list items are separated by blank
  ** lines, or if any of its constituent list items directly contain two block-level
  ** elements with a blank line between them. Otherwise, a list is tight.
  ** (The difference in HTML output is that paragraphs in a loose list are
  ** wrapped in <p> tags, while paragraphs in a tight list are not.)
  Bool tight := false
}

**************************************************************************
** BulletList
**************************************************************************

** A bullet list:
** pre>
** - One
** - Two
** - Three
** <pre
** The children are `ListItem` blocks, which contain other blocks (or nested lists).
@Js
class BulletList : ListBlock
{
  new make(Str? marker := null) { this.marker = marker }

  ** The bullet list marker that was used, e.g. '-', '*', or '+', if available,
  ** or null otherwise.
  Str? marker
}

**************************************************************************
** OrderedList
**************************************************************************

** An ordered list:
** pre>
** 1. One
** 2. Two
** 3. Three
** <pre
** The children are `ListItem` blocks, which contain other blocks (or nested lists).
@Js
class OrderedList : ListBlock
{
  new make(Int? startNumber, Str? markerDelim)
  {
    this.startNumber = startNumber
    this.markerDelim = markerDelim
  }

  ** The start number used in the marker, e.g. '1', if available, or null otherwise
  Int? startNumber

  ** The delimiter used in the marker, e.g. '.' or ')', if available, or null otherwise
  Str? markerDelim
}

**************************************************************************
** ListItem
**************************************************************************

** A child of a `ListBlock`, containing other blocks (e.g. `Paragraph`, other lists, etc.)
@Js
class ListItem : Block
{
  new make(Int? markerIndent, Int? contentIndent)
  {
    this.markerIndent = markerIndent
    this.contentIndent = contentIndent
  }

  ** The indent of the marker such as '-' or '1.' in columns (spaces or tab stop of 4)
  ** if available, or null otherwise.
  **
  **  - '- Foo'    (marker indent: 0)
  **  - ' - Foo'   (marker indent: 1)
  **  - '  1. Foo' (marker indent: 2)
  Int? markerIndent

  ** The indent of the content in columns (spaces or tab stop of 4) if available
  ** or null otherwise. The content indent is counted from the beginning of the line
  ** and includes the marker on the first line
  **
  **  - '- Foo'     (content indent: 2)
  **  - ' - Foo'    (content indent: 3)
  **  - '  1. Foo'  (content indent: 5)
  **
  ** Note that subsequent lines in the same list item need to be indented by at least
  ** the content indent to be counted as part of the list item.
  Int? contentIndent
}

**************************************************************************
** Paragraph
**************************************************************************

** A paragraph block contains inline nodes such as `Text`.
@Js
class Paragraph : Block { }

**************************************************************************
** CustomBlock
**************************************************************************

** Custom Block
@Js
abstract class CustomBlock : Block { }