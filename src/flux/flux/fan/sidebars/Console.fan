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
  new make()
  {
    content = text
  }

//////////////////////////////////////////////////////////////////////////
// SideBar
//////////////////////////////////////////////////////////////////////////

  **
  ** Console is aligned at the bottom of the frame.
  **
  override Obj prefAlign() { return Valign.bottom }

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
    text.text = text.text + "\r\n------------------------------\r\n"
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
    proc := Process(params.command, params.dir)
    proc.out = ConsoleOutStream(params.frameId)
    proc.run.join
    Desktop.callAsync(&execDone(params.frameId))
  }

  **
  ** Called on UI thread by ConsoleOutStream when the
  ** process writes to stdout.
  **
  internal static Void write(Str frameId, Str str)
  {
    str = str.replace("\n", "\r\n") // TODO
    c := Frame.findById(frameId).console
    newText := c.text.text + str
    c.text.text = newText
    c.text.select(newText.size, 0)
  }

  **
  ** Called on UI thread by execRun when process completes.
  **
  internal static Void execDone(Str frameId)
  {
    c := Frame.findById(frameId).console
    c.busy = false
  }

  internal Text text := Text { multiLine=true; editable=false }
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
    Desktop.callAsync(&Console.write(frameId, str))
    return this
  }

  override This writeBuf(Buf b, Int n := b.remaining)
  {
    str := Buf().writeBuf(b, n).flip.readAllStr
    Desktop.callAsync(&Console.write(frameId, str))
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

//////////////////////////////////////////////////////////////////////////
// TODO
//////////////////////////////////////////////////////////////////////////

/*
@fluxSideBar
internal class LeftGreen : SideBar
{
  new make() { content = FooBox { bg = Color.green } }
  override Obj prefAlign() { return Halign.left }
}

@fluxSideBar
internal class LeftRed : SideBar
{
  new make() { content = FooBox { bg = Color.red } }
  override Obj prefAlign() { return Halign.left }
}

@fluxSideBar
internal class RightYellow : SideBar
{
  new make() { content = FooBox { bg = Color.yellow } }
  override Obj prefAlign() { return Halign.right }
}

@fluxSideBar
internal class RightBlue : SideBar
{
  new make() { content = FooBox { bg = Color.blue } }
  override Obj prefAlign() { return Halign.right }
}

@fluxSideBar
internal class BottomGray : SideBar
{
  new make() { content = FooBox { bg = Color.gray } }
  override Obj prefAlign() { return Valign.bottom }
}

@fluxSideBar
internal class BottomOrange : SideBar
{
  new make() { content = FooBox { bg = Color.orange } }
  override Obj prefAlign() { return Valign.bottom }
}

internal class FooBox : Widget
{
  Color bg
  override Void onPaint(Graphics g)
  {
    w := size.w
    h := size.h
    g.brush = bg
    g.fillRect(0, 0, w, h)
    g.brush = Color.black
    g.drawRect(1, 1, w-2, h-2)
  }
}

*/

