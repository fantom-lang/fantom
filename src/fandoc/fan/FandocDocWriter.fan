//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 14  Steve Eynon  Creation
//

**
** FandocDocWriter outputs a fandoc model to plain text fandoc format
**
@Js
class FandocDocWriter : DocWriter
{

  new make(OutStream out)
  {
    this.out = out
  }

  ** Callback to perform link resolution and checking for
  ** every Link element
  |Link link|? onLink := null

  override Void docStart(Doc doc)
  {
    if (doc.meta.isEmpty)
    {
      out.printLine
      return
    }

    out.printLine(Str.defVal.padl(72, '*'))
    doc.meta.each |v, k|
    {
      out.printLine("** ${k}: ${v}")
    }
    out.printLine(Str.defVal.padl(72, '*'))
    out.printLine
  }

  override Void docEnd(Doc doc) {}

  override Void elemStart(DocElem elem)
  {
    switch (elem.id)
    {
      case DocNodeId.emphasis:
        out.writeChar('*')

      case DocNodeId.strong:
        out.print("**")

      case DocNodeId.code:
        out.writeChar('\'')

      case DocNodeId.link:
        link := (Link) elem
        onLink?.call(link)
        out.writeChar('[')

      case DocNodeId.image:
        img := (Image) elem
        out.print("![${img.alt}")

      case DocNodeId.para:
        para := (Para) elem
        if (!listIndexes.isEmpty)
        {
          indent := listIndexes.size * 2
          out.printLine
          out.printLine
          out.print(Str.defVal.padl(indent))
        }

        if (inBlockquote)
          out.print("> ")
        if (para.admonition != null)
          out.print("${para.admonition}: ")
        if (para.anchorId != null)
          out.print("[#${para.anchorId}]")

      case DocNodeId.pre:
          inPre = true

      case DocNodeId.blockQuote:
        inBlockquote = true

      case DocNodeId.unorderedList:
        listIndexes.push(ListIndex())
        if (listIndexes.size > 1)
          out.printLine

      case DocNodeId.orderedList:
        ol := (OrderedList) elem
        listIndexes.push(ListIndex(ol.style))
        if (listIndexes.size > 1)
          out.printLine

      case DocNodeId.listItem:
        indent := (listIndexes.size - 1) * 2
        out.print(Str.defVal.padl(indent))
        out.print(listIndexes.peek)
        listIndexes.peek.increment
        inListItem = true
    }
  }

  override Void elemEnd(DocElem elem)
  {
    switch (elem.id)
    {
      case DocNodeId.emphasis:
        out.writeChar('*')

      case DocNodeId.strong:
        out.print("**")

      case DocNodeId.code:
        out.writeChar('\'')

      case DocNodeId.link:
        link := (Link) elem
        out.print("]`${link.uri}`")

      case DocNodeId.image:
        img := (Image) elem
        out.print("]`${img.uri}`")

      case DocNodeId.para:
        out.printLine
        out.printLine

      case DocNodeId.heading:
        head := (Heading) elem
        size := head.title.size
        if (head.anchorId != null)
        {
          out.print(" [#${head.anchorId}]")
          size += head.anchorId.size + 4
        }
        char := "#*=-".chars[head.level-1]
        line := Str.defVal.padl(size.max(3), char)
        out.printLine.printLine(line)

      case DocNodeId.pre:
        inPre = false

      case DocNodeId.blockQuote:
        inBlockquote = false

      case DocNodeId.unorderedList:
        listIndexes.pop
        if (listIndexes.isEmpty)
          out.printLine

      case DocNodeId.orderedList:
        listIndexes.pop
        if (listIndexes.isEmpty)
          out.printLine

      case DocNodeId.listItem:
        item := (ListItem) elem
        out.printLine
        inListItem = false
    }
  }

  override Void text(DocText text)
  {
    if (inPre)
    {
      endsWithLineBreak := text.str.endsWith("\n")
      if (!listIndexes.isEmpty || !endsWithLineBreak)
      {
        if (!listIndexes.isEmpty)
          out.printLine
        indentNo := (listIndexes.size + 1) * 2
        indent   := Str.defVal.padl(indentNo)
        text.str.splitLines.each
        {
          out.print(indent).printLine(it)
        }
      } else {
        out.printLine("pre>")
        out.print(text.str)
        out.printLine("<pre")
      }
      out.printLine
    }
    else out.print(text.str)
  }

  private OutStream out
  private ListIndex[] listIndexes := [,]
  private Bool inBlockquote
  private Bool inPre
  private Bool inListItem
}

**************************************************************************
** ListIndex
**************************************************************************

@Js
internal class ListIndex
{
  private static const Int:Str romans  := sortr([1000:"M", 900:"CM", 500:"D", 400:"CD", 100:"C", 90:"XC", 50:"L", 40:"XL", 10:"X", 9:"IX", 5:"V", 4:"IV", 1:"I"])

  OrderedListStyle? style
  Int index  := 1

  new make(OrderedListStyle? style := null)
  {
    this.style = style
  }

  This increment()
  {
    index++
    return this
  }

  override Str toStr()
  {
    switch (style)
    {
      case null:
        return "- "
      case OrderedListStyle.number:
        return "${index}. "
      case OrderedListStyle.lowerAlpha:
        return "${toB26(index).lower}. "
      case OrderedListStyle.upperAlpha:
        return "${toB26(index).upper}. "
      case OrderedListStyle.lowerRoman:
        return "${toRoman(index).lower}. "
      case OrderedListStyle.upperRoman:
        return "${toRoman(index).upper}. "
    }
    throw Err("Unsupported List Style: $style")
  }

  private static Str toB26(Int int)
  {
    int--
    dig := ('A' + (int % 26)).toChar
    return (int >= 26) ? toB26(int / 26) + dig : dig
  }

  private static Str toRoman(Int int)
  {
    l := romans.keys.find { it <= int }
    return (int > l) ? romans[l] + toRoman(int - l) : romans[l]
  }

  private static Int:Str sortr(Int:Str unordered)
  {
    // no ordered literal map... grr...
    // http://fantom.org/sidewalk/topic/1837#c14431
    sorted := [:] { it.ordered = true }
    unordered.keys.sortr.each { sorted[it] = unordered[it] }
    return sorted
  }
}