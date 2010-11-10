#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jul 08  Brian Frank  Creation
//

using gfx
using fwt

**
** RichTextDemo illustrates how to use the RichText widget
**
class RichTextDemo
{
  Void main()
  {
    Doc? doc := Doc()
    doc.text = scriptFile.readAllLines.join("\n")

    //doc.text = "hello // world\n//what the heck!\nalpha beta gamma."
    //doc.log.level = LogLevel.debug

    Window
    {
      title = "RichText Demo"
      InsetPane
      {
        RichText
        {
          model=doc
          font = doc.defFont
          //hbar.onModify.add(&onScroll("hbar"))
          //vbar.onModify.add(&onScroll("vbar"))
          //onVerify.add |Event e| { echo("verify: $e.data") }
          //onVerifyKey.add |Event e| { echo("verify: $e") }
          //onSelect.add |Event e| { echo(e) }
        },
      },;
      size = Size(600,600)
    }.open
  }

  static Void onScroll(Str name, Event e)
  {
    ScrollBar sb := e.widget
    echo("-- onScroll $name $e  [val=$sb.val min=$sb.min max=$sb.max thumb=$sb.thumb page=$sb.page orient=$sb.orientation")
  }

  File scriptFile  := this.typeof->sourceFile.toStr.toUri.toFile
}

**
** This class provides a grossly inefficient implementation
** for managing a document.  But should be easy to understand.
**
class Doc : RichTextModel
{
  override Str text

  const Log log := Log.get("Doc")

  override Int charCount()
  {
    r := text.size
    log.debug("charCount => $r")
    return r
  }

  override Int lineCount()
  {
    r := text.splitLines.size
    log.debug("lineCount => $r")
    return r
  }

  override Str line(Int lineIndex)
  {
    r := text.splitLines[lineIndex]
    log.debug("line($lineIndex) => $r")
    return r
  }

  override Int lineAtOffset(Int offset)
  {
    line := 0
    for (i:=0; i<offset; ++i) if (text[i] == '\n') line++
    log.debug("lineAtOffset($offset) => $line")
    return line
  }

  override Int offsetAtLine(Int lineIndex)
  {
    Int r := text.splitLines[0..<lineIndex]
      .reduce(0) |Int o, Str line->Int| { return line.size+o+1 }
    log.debug("offsetAtLine($lineIndex) => $r")
    return r
  }

  override Str textRange(Int start, Int len)
  {
    r := text[start..<start+len]
    log.debug("textRange($start, $len) => $r.toCode")
    return r
  }

  override Void modify(Int start, Int len, Str newText)
  {
    log.debug("modify($start, $len, $newText)")

    // update model
    oldText := textRange(start, len)
    text = text[0..<start] + newText + text[start+len..-1]

    // must fire modify event
    tc := TextChange
    {
      it.startOffset    = start
      it.startLine      = lineAtOffset(start)
      it.oldText        = oldText
      it.newText        = newText
      it.oldNumNewlines = oldText.numNewlines
      it.newNumNewlines = newText.numNewlines
    }
    onModify.fire(Event { id = EventId.modified; data = tc })
  }

  override Obj[]? lineStyling(Int lineIndex)
  {
    // style { or } using brace color,
    // and // or ** as end of line comments
    line := line(lineIndex)
    styles := Obj[,]
    inComment := false
    last := 0
    line.each |Int ch, Int i|
    {
      if (inComment) return
      if (ch == '{' || ch == '}')
        { styles.add(i).add(brace).add(i+1).add(normal) }
      else if (ch == '/' && last == '/')
        { styles.add(i-1).add(comment); inComment = true }
      else if (ch == '*' && last == '*')
        { styles.add(i-1).add(comment); inComment = true }
      last = ch

    }
    if (styles.first != 0) styles.insert(0, 0).insert(1, normal)
    return styles
  }

  Font defFont := Font { name="Courier New"; size=9 }
  RichTextStyle normal  := RichTextStyle { font=defFont }
  RichTextStyle brace   := RichTextStyle { font=defFont; fg=Color.red }
  RichTextStyle comment := RichTextStyle { font=defFont; fg=Color.make(0x00_7f_00) }
}