//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   02 Nov 2024  Matthew Giannini  Creation
//

**
** Extension for GFM tables using "|" pipes. (GitHub Flavored Markdown).
**
** See [Tables (extension) in GitHub Flavored Markdown Spec]`https://github.github.com/gfm/#tables-extension`
**
@Js
@NoDoc const class TablesExt : MarkdownExt
{
  override Void extendParser(ParserBuilder builder)
  {
    builder.customBlockParserFactory(TableParser.factory)
  }

  override Void extendRenderer(HtmlRendererBuilder builder)
  {
    builder.nodeRendererFactory |HtmlContext cx->NodeRenderer| { TableRenderer(cx) }
  }
}

**************************************************************************
** Nodes
**************************************************************************

** Table block containing a `TableHead` and optionally a `TableBody`
@Js
class Table : CustomBlock { }

** Head part of a `Table` containing `TableRow`s
@Js
class TableHead : CustomNode { }

** Body part of a `Table` containing `TableRow`s
@Js
class TableBody : CustomNode { }

** Table row of a `TableHead` or `TableBody` containing `TableCell`s
@Js
class TableRow : CustomNode { }

** Table cell of a `TableRow` containing inline nodes
@Js
class TableCell : CustomNode
{
  new make() : this.makeFields(false, Alignment.unspecified, 0) { }
  new makeFields(Bool header, Alignment alignment, Int width)
  {
    this.header = header
    this.alignment = alignment
    this.width = width
  }

  ** Is the cell a header or not
  Bool header

  ** The cell alignment
  Alignment alignment

  ** The cell width (the number of dash and colon characters in the delimiter
  ** row of the table for this column)
  Int width

  override protected Str toStrAttributes() { "(header=${header}, align=${alignment}, width=${width})" }
}

@Js
enum class Alignment { unspecified, left, center, right }

**************************************************************************
** TableParser
**************************************************************************

@Js
internal class TableParser : BlockParser
{
  new make(TableCell[] columns, SourceLine headerLine)
  {
    this.columns = columns
    this.rowLines.add(headerLine)
  }

  private TableCell[] columns
  private SourceLine[] rowLines := [,]

  override Table block := Table() { private set }

  override Bool canHaveLazyContinuationLines := true { private set }

  override BlockContinue? tryContinue(ParserState state)
  {
    content := state.line.content
    pipe := Chars.find('|', content, state.nextNonSpaceIndex)
    if (pipe != -1)
    {
      if (pipe == state.nextNonSpaceIndex)
      {
        // if we *only* have a pipe character (and whitespace), that is not a valid
        // table row and ends the table.
        if (Chars.skipSpaceTab(content, pipe+1) == content.size)
        {
          // we also don't want the pipe to be added via lazy continuation
          this.canHaveLazyContinuationLines = false
          return BlockContinue.none
        }
      }
      return BlockContinue.atIndex(state.index)
    }
    return BlockContinue.none
  }

  override Void addLine(SourceLine line) { rowLines.add(line) }

  override Void parseInlines(InlineParser parser)
  {
    sourceSpans := block.sourceSpans

    headerSourceSpan := !sourceSpans.isEmpty ? sourceSpans.first : null
    head := TableHead()
    head.addSourceSpan(headerSourceSpan)
    block.appendChild(head)

    headerRow := TableRow()
    headerRow.setSourceSpans(head.sourceSpans)
    head.appendChild(headerRow)

    headerCells := split(rowLines[0])
    headerCells.each |SourceLine cell, i|
    {
      tableCell := parseCell(cell, i, parser)
      tableCell.header = true
      headerRow.appendChild(tableCell)
    }

    TableBody? body := null
    // body starts at index 2. 0 is header, 1 is separator
    for (rowIndex := 2; rowIndex < rowLines.size; ++rowIndex)
    {
      rowLine := rowLines[rowIndex]
      sourceSpan := rowIndex < sourceSpans.size ? sourceSpans[rowIndex] : null
      cells := split(rowLine)
      row := TableRow()
      row.addSourceSpan(sourceSpan)

      // body can not have more columns than head
      for (i := 0; i < headerCells.size; ++i)
      {
        cell := i < cells.size ? cells[i] : SourceLine("", null)
        tableCell := parseCell(cell, i, parser)
        row.appendChild(tableCell)
      }

      if (body == null)
      {
        // it's valid to have a table without a body. in that case, don't add
        // an empty TableBody node
        body = TableBody()
        block.appendChild(body)
      }
      body.appendChild(row)
      body.addSourceSpan(sourceSpan)
    }
  }

  private TableCell parseCell(SourceLine cell, Int column, InlineParser parser)
  {
    tableCell := TableCell()
    tableCell.addSourceSpan(cell.sourceSpan)

    if (column < columns.size)
    {
      info := columns[column]
      tableCell.alignment = info.alignment
      tableCell.width = info.width
    }

    content := cell.content
    start := Chars.skipSpaceTab(content)
    end := Chars.skipSpaceTabBackwards(content, content.size-1, start)
    parser.parse(SourceLines(cell.substring(start, end+1)), tableCell)

    return tableCell
  }

  internal static SourceLine[] split(SourceLine line)
  {
    row := line.content
    nonSpace := Chars.skipSpaceTab(row)
    cellStart := nonSpace
    cellEnd := row.size
    if (row[nonSpace] == '|')
    {
      // this row has leadin/trailing pipes - skip the leading pipe
      cellStart = nonSpace + 1
      // strip whitespace from the end but not the pipe or we could miss an empty '||' cell
      nonSpaceEnd := Chars.skipSpaceTabBackwards(row, row.size - 1, cellStart)
      cellEnd = nonSpaceEnd + 1
    }
    cells := SourceLine[,]
    sb := StrBuf()
    for (i := cellStart; i < cellEnd; ++i)
    {
      c := row[i]
      switch (c)
      {
        case '\\':
          if (i + 1 < cellEnd && row[i+1] == '|')
          {
            // pipe is special for table parsing. an escaped pipe doesn't result in
            // a new cell, but is passed down to inline parsing as an unescaped pipe.
            // Note that this applies even for the '\|' in an input like '\\|' - in
            // other words, table parsing doesn't support escaping backslashes
            sb.addChar('|')
            ++i
          }
          else
          {
            // preserve backslash before other characters or at end of line
            sb.addChar('\\')
          }
        case '|':
          content := sb.toStr
          cells.add(SourceLine(content, line.substring(cellStart, i).sourceSpan))
          sb.clear
          // + 1 to skip the pipe itself for the next cell's span
          cellStart = i + 1
        default:
          sb.addChar(c)
      }
    }
    if (sb.size > 0)
    {
      content := sb.toStr
      cells.add(SourceLine(content, line.substring(cellStart, line.content.size).sourceSpan))
    }
    return cells
  }

  static const BlockParserFactory factory := TableParserFactory()
}

**************************************************************************
** TableParserFactory
**************************************************************************

@Js
internal const class TableParserFactory : BlockParserFactory
{
  override BlockStart? tryStart(ParserState state, MatchedBlockParser parser)
  {
    paraLines := parser.paragraphLines.lines
    if (paraLines.size == 1 && Chars.find('|', paraLines.first.content, 0) != -1)
    {
      line := state.line
      separatorLine := line.substring(state.index, line.content.size)
      columns := parseSeparator(separatorLine.content)
      if (columns != null && !columns.isEmpty)
      {
        paragraph := paraLines[0]
        headerCells := TableParser.split(paragraph)
        if (columns.size >= headerCells.size)
        {
          return BlockStart.of([TableParser(columns, paragraph)])
            .atIndex(state.index)
            .replaceActiveBlockParser
        }
      }
    }
    return BlockStart.none
  }

  ** Examples of valid separators:
  **
  ** |-
  ** -|
  ** |-|
  ** -|-
  ** |-|-|
  ** --- | ---
  private static TableCell[]? parseSeparator(Str s)
  {
    // we only care about alignment and width, but re-use this type and ignore header field
    columns := TableCell[,]
    pipes := 0
    valid := false
    i := 0
    width := 0
    while (i < s.size)
    {
      c := s[i]
      switch (c)
      {
        case '|':
          ++i
          ++pipes
          if (pipes > 1)
          {
            // more than one adjacent pipe not allowed
            return null
          }
          // Need at least one pipe, even for a one column table
          valid = true
        case '-':
        case ':':
          if (pipes == 0 && !columns.isEmpty)
          {
            // Need a pipe after the first column (first column doesn't need to start
            // with one)
            return null
          }
          left  := false
          right := false
          if (c == ':') { left = true; ++i; ++width }
          haveDash := false
          while (i < s.size && s[i] == '-')
          {
            ++i
            ++width
            haveDash = true
          }
          if (!haveDash)
          {
            // need at least one dash
            return null
          }
          if (i < s.size && s[i] == ':') { right = true; ++i; ++width }
          columns.add(TableCell(false, toAlignment(left, right), width))
          width = 0
          // next, need another pipe
          pipes = 0
        case ' ':
        case '\t':
          // white space is allowed between pipes and columns
          ++i
        default:
          // any other character is invalid
          return null
      }
    }
    return valid ? columns : null
  }

  private static Alignment toAlignment(Bool left, Bool right)
  {
    if (left && right) return Alignment.center
    else if (left) return Alignment.left
    else if (right) return Alignment.right
    else return Alignment.unspecified
  }
}

**************************************************************************
** TableNodeRenderer
**************************************************************************

@Js
internal class TableRenderer : NodeRenderer, Visitor
{
  new make(HtmlContext cx)
  {
    this.cx = cx
    this.html = cx.writer
  }

  private HtmlContext cx
  private HtmlWriter html

  override const Type[] nodeTypes := [
    Table#,
    TableHead#,
    TableBody#,
    TableRow#,
    TableCell#,
  ]

  override Void render(Node node) { node.walk(this) }

  virtual Void visitTable(Table table)
  {
    renderTableNode(table, "table")
  }

  virtual Void visitTableHead(TableHead head)
  {
    renderTableNode(head, "thead")
  }

  virtual Void visitTableBody(TableBody body)
  {
    renderTableNode(body, "tbody")
  }

  virtual Void visitTableRow(TableRow row)
  {
    renderTableNode(row, "tr")
  }

  virtual Void visitTableCell(TableCell cell)
  {
    tagName := cell.header ? "th" : "td"
    renderTableNode(cell, tagName, cellAttrs(cell, tagName))
  }

  private Void renderTableNode(Node node, Str tagName, [Str:Str?] attrs := [:])
  {
    html.line
    html.tag(tagName, toAttrs(node, tagName, attrs))
    renderChildren(node)
    html.tag("/${tagName}")
    html.line
  }

  private Void renderChildren(Node parent)
  {
    node := parent.firstChild
    while (node != null)
    {
      next := node.next
      cx.render(node)
      node = next
    }
  }

  private [Str:Str] cellAttrs(TableCell cell, Str tagName)
  {
    attrs := [Str:Str][:] { ordered = true }
    if (cell.alignment !== Alignment.unspecified)
      attrs["align"] = cell.alignment.name.lower
    return attrs
  }

  private [Str:Str?] toAttrs(Node node, Str tagName, [Str:Str?] attrs)
  {
    cx.extendAttrs(node, tagName, attrs)
  }
}
