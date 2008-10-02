//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Sep 08  Brian Frank  Creation
//

using fwt

**
** Console is used to run external programs and capture output.
**
@fluxSideBar
class Console : SideBar
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Use `Frame.console` to get the console.
  **
  override Void onLoad()
  {
    model = ConsoleModel()
    richText = RichText
    {
      model = model
      editable = false
      border = false
      font = Font.sysMonospace
      onMouseUp.add(&onRichTextMouseDown)
    }
    content = EdgePane
    {
      top = BorderPane
      {
        InsetPane(4,4,4,4)
        {
          EdgePane
          {
            left = ToolBar
            {
              addCommand(copyCmd)
              addCommand(frame.command(CommandId.jumpPrev))
              addCommand(frame.command(CommandId.jumpNext))
            }
            right = ToolBar
            {
              addCommand(hideCmd)
            }
          }
        }
        insets  = Insets(2,0,0,0)
        onBorder = |Graphics g, Size size|
        {
          g.brush = Color.sysNormShadow
          g.drawLine(0, 0, size.w, 0)
          g.brush = Color.sysHighlightShadow
          g.drawLine(0, 1, size.w, 1)
        }
      }
      center = BorderPane
      {
        content = richText
        insets  = Insets(1,0,0,1)
        onBorder = |Graphics g, Size size|
        {
          g.brush = Color.sysNormShadow
          g.drawLine(0, 0, size.w, 0)
          g.drawLine(0, 0, 0, size.h)
        }
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// SideBar
//////////////////////////////////////////////////////////////////////////

  **
  ** Console is aligned at the bottom of the frame.
  **
  override Obj prefAlign() { return Valign.bottom }

//////////////////////////////////////////////////////////////////////////
// Write
//////////////////////////////////////////////////////////////////////////

  **
  ** Write the string to the end of the console
  **
  internal Void write(Str s)
  {
    model.modify(model.size, 0, s)
    richText.repaint
    richText.select(model.size, 0)
  }

//////////////////////////////////////////////////////////////////////////
// Exec
//////////////////////////////////////////////////////////////////////////

  **
  ** Return true if the console is busy executing a job.
  **
  readonly Bool busy := false

  **
  ** Execute an external process and capture its output
  ** in the console.  See `sys::Process` for a description
  ** of the command and dir parameters.
  **
  This exec(Str[] command, File dir := null)
  {
    if (busy) throw Err("Console is busy")
    frame.marks = Mark[,]
    model.text = command.join(" ") + "\n"
    richText.repaint
    busy = true
    params := ExecParams
    {
      frameId = frame.id
      command = command
      dir = dir
    }
    Thread(null, &execRun(params)).start
    return this
  }

  **
  ** This is the method which executes the process
  ** on a background thread.
  **
  internal static Void execRun(ExecParams params)
  {
    try
    {
      proc := Process(params.command, params.dir)
      proc.out = ConsoleOutStream(params.frameId)
      proc.run.join
    }
    finally
    {
      Desktop.callAsync(&execDone(params.frameId))
    }
  }

  **
  ** Called on UI thread by ConsoleOutStream when the
  ** process writes to stdout.
  **
  internal static Void execWrite(Str frameId, Str str)
  {
    Frame.findById(frameId).console.write(str)
  }

  **
  ** Called on UI thread by execRun when process completes.
  **
  internal static Void execDone(Str frameId)
  {
    frame := Frame.findById(frameId)
    console := frame.console
    console.busy = false
    frame.marks = console.model.toMarks
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  override Void onGotoMark(Mark mark)
  {
    // highlight the line with the current mark
    line := model.lines.find |ConsoleLine line->Bool|
    {
      return line.mark === mark
    }
    if (line != null)
      richText.select(line.offset, line.text.size)
  }

  internal Void onRichTextMouseDown(Event event)
  {
    // map event to line and check if line has mark
    offset := richText.offsetAtPos(event.pos.x, event.pos.y)
    if (offset == null) return
    line := model.lines[model.lineAtOffset(offset)]
    if (line.mark == null) return

    // select the entire line
    richText.select(line.offset, line.text.size)

    // hyperlink to view
    frame.loadMark(line.mark, LoadMode(event))
  }

  internal Void onCopy()
  {
    richText.selectAll
    richText.copy
  }

  internal Void onClose()
  {
    hide
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal ConsoleModel model
  internal RichText richText

  private Command copyCmd := Command.makeLocale(Flux#.pod, "copy", &onCopy)
  private Command hideCmd := Command.makeLocale(Flux#.pod, "navBar.close", &onClose)

}

**************************************************************************
** ConsoleModel
**************************************************************************

internal class ConsoleModel : RichTextModel
{
  override Str text
  {
    get { return lines.join(delimiter) |ConsoleLine line->Str| { return line.text } }
    set { modify(0, size, val) }
  }

  override Int charCount() { return size }

  override Int lineCount() { return lines.size }

  override Str line(Int lineIndex) { return lines[lineIndex].text }

  override Int offsetAtLine(Int lineIndex) { return lines[lineIndex].offset }

  override Int lineAtOffset(Int offset)
  {
    // binary search by offset, returns '-insertationPoint-1'
    key := ConsoleLine { offset = offset }
    line := lines.binarySearch(key) |ConsoleLine a, ConsoleLine b->Int| { return a.offset <=> b.offset }
    if (line < 0) line = -(line + 2)
    if (line >= lines.size) line = lines.size-1
    return line
  }

  override Void modify(Int startOffset, Int len, Str newText)
  {
    // compute the lines being replaced
    endOffset      := startOffset + len
    startLineIndex := lineAtOffset(startOffset)
    endLineIndex   := lineAtOffset(endOffset)
    startLine      := lines[startLineIndex]
    endLine        := lines[endLineIndex]
    oldText        := textRange(startOffset, len)

    // compute the new text of the lines being replaced
    offsetInStart := startOffset - startLine.offset
    offsetInEnd   := endOffset - endLine.offset
    newLinesText  := startLine.text[0...offsetInStart] + newText + endLine.text[offsetInEnd..-1]

    // split new text into new lines
    newLines := ConsoleLine[,] { capacity=32 }
    newLinesText.splitLines.each |Str s|
    {
      newLines.add(parseLine(s))
    }

    // merge in new lines
    lines.removeRange(startLineIndex..endLineIndex)
    lines.insertAll(startLineIndex, newLines)

    // update total size, line offsets, and multi-line comments/strings
    updateLines(lines)

    // fire modification event
    tc := TextChange
    {
      startOffset    = startOffset
      startLine      = startLineIndex
      oldText        = oldText
      newText        = newText
      oldNumNewlines = oldText.numNewlines
      newNumNewlines = newLines.size - 1
    }
    onModify.fire(Event { id =EventId.modified; data = tc })
  }

  private Void updateLines(ConsoleLine[] lines)
  {
    n := 0
    lastIndex := lines.size-1
    delimiterSize := delimiter.size

    // walk the lines
    lines.each |ConsoleLine line, Int i|
    {
      // update offset and total running size
      line.offset = n
      n += line.text.size
      if (i != lastIndex) n += delimiterSize
    }

    // update total size
    size = n
  }

  ConsoleLine parseLine(Str t)
  {
    Obj[] s := null
    mp := MarkParser(t)
    m := mp.parse
    if (m != null && !m.uri.toStr.contains("bin"))
    {
      start := mp.fileStart
      //t = t[0...start] + m.uri.name + t[mp.fileEnd+1..-1]
      if (start == 0)
        s = [0, link, mp.fileEnd+1, norm]
      else
        s = [0, norm, start, link, mp.fileEnd+1, norm]
    }
    return ConsoleLine { text = t; mark = m; styling = s }
  }

  override Obj[] lineStyling(Int lineIndex)
  {
    return lines[lineIndex].styling
  }

  Mark[] toMarks()
  {
    marks := Mark[,]
    lines.each |ConsoleLine line, Int i|
    {
      if (line.mark != null && i != 0) marks.add(line.mark)
    }
    return marks
  }

  Int maxLines := 10
  Int size := 0
  ConsoleLine[] lines := [ConsoleLine { offset=0; text="" }]
  Str delimiter := "\n"
  RichTextStyle norm := RichTextStyle {}
  RichTextStyle link := RichTextStyle { fg=Color.blue; underline = RichTextUnderline.single; }
}

**************************************************************************
** ConsoleLine
**************************************************************************

internal class ConsoleLine
{
  ** Return 'text'.
  override Str toStr() { return text }

  ** Zero based offset from start of document (this
  ** field is managed by the Doc).
  Int offset { internal set; }

  ** Text of line (without delimiter)
  const Str text

  ** If we matched a file location from text
  Mark mark

  ** Styling
  Obj[] styling
}

**************************************************************************
** ConsoleOutStream
**************************************************************************

internal class ConsoleOutStream : OutStream
{
  new make(Str frameId) : super(null) { this.frameId = frameId }

  override This write(Int b)
  {
    str := Buf().write(b).flip.readAllStr
    Desktop.callAsync(&Console.execWrite(frameId, str))
    return this
  }

  override This writeBuf(Buf b, Int n := b.remaining)
  {
    str := Buf().writeBuf(b, n).flip.readAllStr
    Desktop.callAsync(&Console.execWrite(frameId, str))
    return this
  }

  Str frameId
}

**************************************************************************
** ExecParams
**************************************************************************

internal const class ExecParams
{
  const Str frameId
  const Str[] command
  const File dir
}