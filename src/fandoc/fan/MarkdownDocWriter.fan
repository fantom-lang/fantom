//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//

**
** MarkdownDocWriter outputs a fandoc model to
** [Markdown]`http://daringfireball.net/projects/markdown/`
**
@Js class MarkdownDocWriter : DocWriter
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(OutStream out := Env.cur.out)
  {
    this.out = out
  }

//////////////////////////////////////////////////////////////////////////
// Config
//////////////////////////////////////////////////////////////////////////

  ** Callback to perform link resolution and checking for
  ** every Link element
  |Link link|? onLink := null

//////////////////////////////////////////////////////////////////////////
// DocWriter
//////////////////////////////////////////////////////////////////////////

  override Void docStart(Doc doc)
  {
  }

  override Void docEnd(Doc doc)
  {
    out.flush
  }

  override Void elemStart(DocElem elem)
  {
    switch (elem.id)
    {
      case DocNodeId.para:
        para := elem as Para
        if (inListItem)
        {
          out.printLine
          out.print(Str.defVal.padl(indDef))
        }

        if (para.anchorId != null)
          out.print("[#${para.anchorId}]")
        if (inBlockquote)
          out.print("> ")

      case DocNodeId.blockQuote:
        inBlockquote = true

      case DocNodeId.pre:
        inPre = true

      case DocNodeId.heading:
        h := elem as Heading
        out.print(Str.defVal.padl(h.level, '#')).writeChar(' ')
        if (elem.anchorId != null)
          out.print("<a name=\"${elem.anchorId}\"></a>")

      case DocNodeId.unorderedList:
        listIndexes.push(ListIndex())

      case DocNodeId.orderedList:
        // Markdown only supports numbered ordered lists
        ol := elem as OrderedList
        listIndexes.push(ListIndex(OrderedListStyle.number))

      case DocNodeId.listItem:
        indent := (listIndexes.size - 1) * indDef
        out.print(Str.defVal.padl(indent))
        out.print(liSymbol)
        listIndexes.peek.increment

      case DocNodeId.link:
        link := elem as Link
        onLink?.call(link)
        out.writeChar('[')

      case DocNodeId.image:
        img := elem as Image
        out.print("![${img.alt}")

      case DocNodeId.emphasis:
        out.writeChar('*')

      case DocNodeId.strong:
        out.print("**")

      case DocNodeId.code:
        out.print("``")
    }
  }

  override Void elemEnd(DocElem elem)
  {
    switch (elem.id)
    {
      case DocNodeId.para:
        if (!inListItem)
          out.printLine // blank line

      case DocNodeId.blockQuote:
        inBlockquote = false

      case DocNodeId.pre:
        inPre = false

      case DocNodeId.orderedList:
      case DocNodeId.unorderedList:
        listIndexes.pop
        // fall-through
        if (listIndexes.isEmpty)
          out.printLine // blank line

      case DocNodeId.link:
        link := elem as Link
        out.print("](${link.uri})\n")

      case DocNodeId.image:
        img := elem as Image
        out.print("](${img.uri})\n")

      case DocNodeId.emphasis:
        out.writeChar('*')

      case DocNodeId.strong:
        out.print("**")

      case DocNodeId.code:
        out.print("``")
    }
  }

  override Void text(DocText text)
  {
    if (inPre)
    {
      indent := indCode
      if (inListItem) indent += (listIndexes.size - 1) * indDef
      pad := Str.defVal.padl(indent)
      text.str.splitLines.each |line| {
        out.print(pad).printLine(line)
      }
    }
    else
    {
      out.print(text.str)
      if (text.parent.isBlock)
        out.printLine
    }
  }

//////////////////////////////////////////////////////////////////////////
// MarkdownDocWriter
//////////////////////////////////////////////////////////////////////////

  ** Get the symbol to use for the current list item.
  private Str liSymbol()
  {
    li := listIndexes.peek
    if (li.style == null)
    {
      numUl := listIndexes.findAll { it.style == null }.size
      return ulSymbols[(numUl-1) % ulSymbols.size]
    }
    return li.toStr
  }

  private Bool inListItem()
  {
    !listIndexes.isEmpty
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  const static private Str[] ulSymbols := ["* ", "+ ", "- "]
  const static private Int indDef  := 4
  const static private Int indCode := 8

  private OutStream out
  private ListIndex[] listIndexes := [,]
  private Bool inBlockquote
  private Bool inPre

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  static Void main(Str[] args := Env.cur.args)
  {
    doc := FandocParser().parse(args[0], File(args[0].toUri).in)
    doc.write(MarkdownDocWriter())
  }

}
