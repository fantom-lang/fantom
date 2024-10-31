//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

**
** List block parser
**
@Js
internal class ListBlockParser : BlockParser
{
  new make(ListBlock block)
  {
    this.block = block
  }

  private Bool hadBlankLine := false
  private Int linesAfterBlank := 0

  override ListBlock block { private set }

  override const Bool isContainer := true

  override Bool canContain(Block childBlock)
  {
    if (childBlock is ListItem)
    {
      // Another list item is added to this list block. If the previous line was
      // blank, that means this list block is "loose" (not tight).
      //
      // spec: a list is loose if any of its constituent list items are
      // separated by blank lines
      if (hadBlankLine && linesAfterBlank == 1)
      {
        block.tight = false
        this.hadBlankLine = false
      }
      return true
    }
    else return false
  }

  override BlockContinue? tryContinue(ParserState state)
  {
    if (state.isBlank)
    {
      this.hadBlankLine = true
      this.linesAfterBlank = 0
    }
    else if (hadBlankLine) ++linesAfterBlank

    // List blocks themselves don't have any markers, only list items. So try to
    // staty in the list. If there is a block start other than list item,
    // canContain makes sure that this list is closed
    return BlockContinue.atIndex(state.index)
  }

  static const BlockParserFactory factory := ListBlockParserFactory()
}

**************************************************************************
** ListBlockParserFactory
**************************************************************************

@Js
internal const class ListBlockParserFactory : BlockParserFactory
{
  override BlockStart? tryStart(ParserState state, MatchedBlockParser parser)
  {
    matched := parser.matchedBlockParser

    if (state.indent >= Parsing.code_block_indent) return BlockStart.none

    markerIndex := state.nextNonSpaceIndex
    markerColumn := state.column + state.indent
    inPara := !parser.paragraphLines.isEmpty
    listData := parseList(state.line.content, markerIndex, markerColumn, inPara)
    if (listData == null) return BlockStart.none

    newColumn := listData.contentColumn
    listItemParser := ListItemParser(state.indent, newColumn - state.column)

    // prepend the list block if needed
    if (!(matched is ListBlockParser) ||
          !(listsMatch((ListBlock)matched.block, listData.listBlock)))
    {
      listBlockParser := ListBlockParser(listData.listBlock)
      // we start out with assumign a list is tight. if we find a blank line, we set
      // it to loose later
      listData.listBlock.tight = true

      return BlockStart.of([listBlockParser, listItemParser]).atColumn(newColumn)
    }
    else return BlockStart.of([listItemParser]).atColumn(newColumn)
  }

  ** Parse a list marker and return data on the marker or null
  private static ListData? parseList(Str line, Int markerIndex, Int markerColumn, Bool inPara)
  {
    listMarker := parseListMarker(line, markerIndex)
    if (listMarker == null) return null
    listBlock := listMarker.listBlock

    indexAfterMarker := listMarker.indexAfterMarker
    markerLen := indexAfterMarker - markerIndex
    // marker doesn't include tabs, so counting them as columns directly is ok
    columnAfterMarker := markerColumn + markerLen
    // the column within the line where the content starts
    contentColumn := columnAfterMarker

    // see at which column the content starts if there is content
    hasContent := false
    len := line.size
    for (i := indexAfterMarker; i < len; ++i)
    {
      c := line[i]
      if (c == '\t') contentColumn += Parsing.columnsToNextTabStop(contentColumn)
      else if (c == ' ') ++contentColumn
      else { hasContent = true; break }
    }

    if (inPara)
    {
      // If the list item is ordered, the start number must be 1 to interrupt a paragraph
      if (listBlock is OrderedList && ((OrderedList)listBlock).startNumber != 1)
      {
        return null
      }
      // empty list item can not interrupt a paragraph
      if (!hasContent) return null
    }

    if (!hasContent || (contentColumn - columnAfterMarker) > Parsing.code_block_indent)
    {
      // if this line is blank or has a code block, default to 1 space after marker
      contentColumn = columnAfterMarker + 1
    }

    return ListData(listBlock, contentColumn)
  }

  private static ListMarkerData? parseListMarker(Str line, Int index)
  {
    c := line[index]
    switch (c)
    {
      // spec: a bullet list marker is a -, +, or * character
      case '-':
      case '+':
      case '*':
        if (isSpaceTabOrEnd(line, index+1))
        {
          bulletList := BulletList(c.toChar)
          return ListMarkerData(bulletList, index+1)
        }
        else return null
      default:
        return parseOrderedList(line, index)
    }
  }

  ** spec: An ordered list marker is a sequence of 1-9 arabic digits (0-9),
  ** followed by either a '.' character or a ')' character.
  private static ListMarkerData? parseOrderedList(Str line, Int index)
  {
    digits := 0
    len := line.size
    for (i := index; i < len; ++i)
    {
      c := line[i]
      if (c.isDigit)
      {
        ++digits
        if (digits > 9) return null
      }
      else if (c == '.' || c == ')')
      {
        if (digits >= 1 && isSpaceTabOrEnd(line, i+1))
        {
          number := line[index..<i]
          orderedList := OrderedList(number.toInt, c.toChar)
          return ListMarkerData(orderedList, i+1)
        }
        else return null
      }
      else return null
    }
    return null
  }

  private static Bool isSpaceTabOrEnd(Str line, Int index)
  {
    if (index < line.size)
    {
      switch (line[index])
      {
        case ' ':
        case '\t':
          return true
        default:
          return false
      }
    }
    else return true
  }

  ** Returns true if the two list items are of the same type,
  ** with the same delimiter and bullet character. This is used
  ** in agglomerating list items into lists
  private static Bool listsMatch(ListBlock a, ListBlock b)
  {
    if (a is BulletList && b is BulletList)
    {
      return a->marker == b->marker
    }
    else if (a is OrderedList && b is OrderedList)
    {
      return a->markerDelim == b->markerDelim
    }
    return false
  }
}

**************************************************************************
** ListItemParser
**************************************************************************

@Js
internal class ListItemParser : BlockParser
{
  new make(Int? markerIndent, Int? contentIndent)
  {
    this.contentIndent = contentIndent
    this.block = ListItem(markerIndent, contentIndent)
  }

  ** Minimum number of columns that the content has to be indented (relative
  ** to the cdontaing block) to be part of this list item.
  const Int contentIndent

  private Bool hadBlankLine := false

  override ListItem block { private set }

  override const Bool isContainer := true

  override Bool canContain(Block childBlock)
  {
    if (hadBlankLine)
    {
      // we saw a blank line in this list item, that means the list block is loose
      //
      // spec: if any of its constituent list items directly contain two block-level
      // elements with a blank line between them
      parent := block.parent
      if (parent is ListBlock) ((ListBlock)parent).tight = false
    }
    return true
  }

  override BlockContinue? tryContinue(ParserState state)
  {
    if (state.isBlank)
    {
      if (block.firstChild == null)
      {
        // blank line after empty list item
        return BlockContinue.none
      }
      else
      {
        activeBlock := state.activeBlockParser.block
        // if the active block is a code block, blank lines in it should
        // not affect if the list is tight
        hadBlankLine = activeBlock is Paragraph || activeBlock is ListItem
        return BlockContinue.atIndex(state.nextNonSpaceIndex)
      }
    }

    if (state.indent >= contentIndent)
      return BlockContinue.atColumn(state.column + contentIndent)
    else
    {
      // note: we'll hit this case for lazy continuation lines, they will get added later
      return BlockContinue.none
    }
  }
}

**************************************************************************
** ListData
**************************************************************************

@Js
internal class ListData
{
  new make(ListBlock listBlock, Int contentColumn)
  {
    this.listBlock = listBlock
    this.contentColumn = contentColumn
  }

  ListBlock listBlock { private set }
  const Int contentColumn
}

**************************************************************************
** ListMarkerData
**************************************************************************

@Js
internal class ListMarkerData
{
  new make(ListBlock listBlock, Int indexAfterMarker)
  {
    this.listBlock = listBlock
    this.indexAfterMarker = indexAfterMarker
  }

  ListBlock listBlock { private set }
  const Int indexAfterMarker
}