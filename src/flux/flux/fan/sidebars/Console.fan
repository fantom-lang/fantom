//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Sep 08  Brian Frank  Creation
//

using concurrent
using gfx
using fwt

**
** Console is used to run external programs and capture output.
**
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
    model.clear
    richText = RichText
    {
      it.model = this.model
      it.editable = false
      it.border = false
      it.font = Desktop.sysFontMonospace
      it.onMouseUp.add |e| { onRichTextMouseDown(e) }
    }
    content = EdgePane
    {
      top = EdgePane
      {
        top = BorderPane
        {
          border = Border("1,0,1,0 $Desktop.sysNormShadow,#000,$Desktop.sysHighlightShadow")
        }
        bottom = InsetPane(4,4,4,4)
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
          },
        }
      }
      center = BorderPane
      {
        it.content = richText
        it.border = Border("1,0,0,1 $Desktop.sysNormShadow")
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
  This clear()
  {
    model.clear
    richText.repaint
    return this
  }

  **
  ** Write the string to the end of the console
  **
  This append(Str s)
  {
    model.append(s)
    richText.repaint
    richText.select(model.size, 0)
    return this
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
  This exec(Str[] command, File? dir := null)
  {
    if (busy) throw Err("Console is busy")
    frame.marks = Mark[,]
    model.clear.append(command.join(" ") + "\n")
    richText.repaint
    busy = true
    params := ExecParams
    {
      it.frameId = frame.id
      it.command = command
      it.dir = dir
    }
    Actor(ActorPool(), |->| { execRun(params) }).send(null)
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
    catch (Err e)
    {
      e.trace
    }
    finally
    {
      Desktop.callAsync |->| { execDone(params.frameId) }
    }
  }

  **
  ** Called on UI thread by ConsoleOutStream when the
  ** process writes to stdout.
  **
  internal static Void execWrite(Str frameId, Str str)
  {
    try
    {
      Frame.findById(frameId).console.append(str)
    }
    catch (Err e)
    {
      e.trace
    }
  }

  **
  ** Called on UI thread by execRun when process completes.
  **
  internal static Void execDone(Str frameId)
  {
    try
    {
      frame := Frame.findById(frameId)
      console := frame.console
      console.busy = false
      frame.marks = console.model.toMarks
    }
    catch (Err e)
    {
      e.trace
    }
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  **
  ** Run the given function in another thread.
  ** TODO - this function is experimental and will change!
  **
  internal This run(Method method, Str[] params)
  {
    if (busy) throw Err("Console is busy")
    frame.marks = Mark[,]
    model.clear
    richText.repaint
    busy = true
    execParams := ExecParams
    {
      frameId = frame.id
      command = params
    }
    Actor(ActorPool(), |->| { doRun(method, execParams) }).send(null)
    return this
  }

  internal static Void doRun(Method method, ExecParams params)
  {
    try
    {
      results := (Str[])method.call(params)
      results.each |Str s| { Desktop.callAsync |->| { execWrite(params.frameId, s) } }
    }
    catch (Err e)
    {
      e.trace
    }
    finally
    {
      Desktop.callAsync |->| { execDone(params.frameId) }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  override Void onGotoMark(Mark mark)
  {
    model.curMark = mark
    line := model.lineForMark(mark)
    if (line != null) richText.showLine(line.index)
    richText.repaint
  }

  internal Void onRichTextMouseDown(Event event)
  {
    // clear current mark
    model.curMark = null

    // map event to line and check if line has mark
    offset := richText.offsetAtPos(event.pos.x, event.pos.y)
    if (offset != null)
    {
      line := model.lines[model.lineAtOffset(offset)]
      if (line.mark != null)
        model.curMark = line.mark
    }

    // update highlight
    richText.repaint

    // hyperlink to view
    if (model.curMark != null)
      frame.loadMark(model.curMark, LoadMode(event))
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

  internal ConsoleModel? model
  internal RichText? richText

  private Command copyCmd := Command.makeLocale(Flux#.pod, "copy") { onCopy }
  private Command hideCmd := Command.makeLocale(Flux#.pod, "navBar.close") { onClose }

}

**************************************************************************
** ConsoleModel
**************************************************************************

internal class ConsoleModel : RichTextModel
{
  override Str text
  {
    get { return lines.join(delimiter) |ConsoleLine line->Str| { return line.text } }
    set { modify(0, size, it) }
  }

  override Int charCount() { return size }

  override Int lineCount() { return lines.size }

  override Str line(Int lineIndex) { return lines[lineIndex].text }

  override Int offsetAtLine(Int lineIndex) { return lines[lineIndex].offset }

  override Int lineAtOffset(Int offset)
  {
    // binary search by offset, returns '-insertationPoint-1'
    key := ConsoleLine { it.offset = offset }
    line := lines.binarySearch(key) |ConsoleLine a, ConsoleLine b->Int| { return a.offset <=> b.offset }
    if (line < 0) line = -(line + 2)
    if (line >= lines.size) line = lines.size-1
    return line
  }

  override Void modify(Int startOffset, Int len, Str newText)
  {
    // we only allow appending to end of console text since we
    // are actually modifying the text displayed to show short
    // filenames versus full file paths
    throw UnsupportedErr("Cannot only call ConsoleModel.append")
  }

  This clear()
  {
    size = 0
    lines = [ConsoleLine { it.offset=0; it.text=""; it.fullText="" }]
    curMark = null
    return this
  }

  This append(Str s)
  {
    // save initial state for modification event
    startOffset := size
    startLineIndex := lines.last.index

    // normalize newlines
    newLines := s.splitLines
    numNewLines := newLines.size - 1

    // figure out if this we are starting a new line or need to append
    // to the last line; if appending to the last line we have to use
    // the original fullText to ensure we parse filenames correctly
    if (newLines.first == "")
    {
      newLines.removeAt(0)
      startLineIndex++
    }
    else
    {
      newLines[0] = lines.last.fullText + newLines.first
      lines.removeAt(-1)
    }

    // parse and append new lines
    newLines.each |Str line|
    {
      lines.add(parseLine(line))
    }

    // update total size, line offsets
    updateLines(lines)

    // fire modification event
    tc := TextChange
    {
      it.startOffset    = startOffset
      it.startLine      = startLineIndex
      it.oldText        = ""
      it.newText        = s
      it.oldNumNewlines = 0
      it.newNumNewlines = numNewLines
    }
    onModify.fire(Event { id =EventId.modified; data = tc })

    return this
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
      line.index  = i;
      line.offset = n
      n += line.text.size
      if (i != lastIndex) n += delimiterSize
    }

    // update total size
    size = n
  }

  ConsoleLine parseLine(Str t)
  {
    Obj[]? s := null
    full := t

    // attempt to parse mark (filename) in the line
    mp := MarkParser(t)
    m := mp.parse

    // don't show paths that are likely executables (bin)
    if (m != null && m.uri.path.contains("bin")) m = null

    // update the text to only show the filename (not the full path);
    // compute the styling to make filename appear as a hyperlink
    if (m != null)
    {
      start := mp.fileStart
      name  := m.uri.name
      t = t[0..<start] + name + t[mp.fileEnd+1..-1]
      if (start == 0)
        s = [0, link, name.size, norm]
      else
        s = [0, norm, start, link, start+name.size, norm]
    }

    return ConsoleLine { it.text = t; it.fullText = full; it.mark = m; it.styling = s }
  }

  override Obj[]? lineStyling(Int lineIndex)
  {
    return lines[lineIndex].styling
  }

  override Color? lineBackground(Int lineIndex)
  {
    if (curMark != null && lines[lineIndex].mark === curMark)
      return Color.yellow
    else
      return null
  }

  ConsoleLine? lineForMark(Mark m)
  {
    return lines.find |ConsoleLine line->Bool| { return line.mark === m }
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

  Int size
  ConsoleLine[] lines := ConsoleLine[,]
  Str delimiter := "\n"
  RichTextStyle norm := RichTextStyle {}
  RichTextStyle link := RichTextStyle { fg=Color.blue; underline = RichTextUnderline.single; }
  Mark? curMark
}

**************************************************************************
** ConsoleLine
**************************************************************************

internal class ConsoleLine
{
  new make(|This| f) { f(this) }

  ** Return 'text'.
  override Str toStr() { return text }

  ** Zero based line index
  Int index

  ** Zero based offset from start of document (this
  ** field is managed by the Doc).
  Int offset { internal set; }

  ** Text we show (short uri filename)
  const Str text := ""

  ** Full text we show (long uri)
  const Str fullText := ""

  ** If we matched a file location from text
  Mark? mark

  ** Styling
  Obj[]? styling
}

**************************************************************************
** ConsoleOutStream
**************************************************************************

internal class ConsoleOutStream : OutStream
{
  new make(Str frameId) : super(null) { this.frameId = frameId }

  override This write(Int b)
  {
    frameId := this.frameId
    str := Buf().write(b).flip.readAllStr
    Desktop.callAsync |->| { Console.execWrite(frameId, str) }
    return this
  }

  override This writeBuf(Buf b, Int n := b.remaining)
  {
    frameId := this.frameId
    str := Buf().writeBuf(b, n).flip.readAllStr
    Desktop.callAsync |->| { Console.execWrite(frameId, str) }
    return this
  }

  Str frameId
}

**************************************************************************
** ExecParams
**************************************************************************

internal const class ExecParams
{
  new make(|This| f) { f(this) }
  const Str frameId := ""
  const Str[] command := Str#.emptyList
  const File? dir
}