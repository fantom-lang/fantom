//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Sep 08  Andy Frank  Creation
//

using fwt
using flux

**
** FindBar finds text in the current TextEditor.
**
internal class FindBar : ContentPane
{
  new make(RichText richText)
  {
    this.richText = richText

    findText = Text()
    findText.onFocus.add |Event e| { caretPos = richText.caretPos }
    findText.onKeyDown.add |Event e| { if (e.key == Key.esc) hide }
    findText.onModify.add(&find(null,true))

    content = InsetPane(4,4,4,4)
    {
      EdgePane
      {
        center = GridPane
        {
          numCols = 4
          Label { text="Find" }
          add(Temp { findText })
          ToolBar
          {
            addCommand(cmdNext)
            addCommand(cmdPrev)
          }
          add(msg)
        }
        right = ToolBar { addCommand(cmdHide) }
      }
    }
  }

  **
  ** Show the FindBar in the parent widget.
  **
  Void show()
  {
    visible = true
    parent?.parent?.parent?.relayout

    // make sure text is focued and selected
    findText.focus
    findText.selectAll

    // if old text still in there, force find
    if (findText.text.size > 0) find(null)
  }

  **
  ** Hide the FindBar in the parent widget.
  **
  Void hide()
  {
    visible = false
    parent?.parent?.parent?.relayout
  }

  **
  ** Find the current query string in the text document,
  ** starting at the given caret pos.  If pos is null,
  ** the caretPos recorded when the FindBar was focued
  ** will be used.  If forward is false, the document
  ** is searched backwards starting at pos.
  **
  internal Void find(Int fromPos, Bool forward := true)
  {
    q := findText.text
    if (q.size == 0)
    {
      setMsg("")
      cmdPrev.enabled = false
      cmdNext.enabled = false
      return
    }

    pos  := fromPos ?: caretPos
    text := richText.text
    off  := (forward) ? text.index(q, pos) : text.indexr(q, pos-q.size-1)

    cmdPrev.enabled = true
    cmdNext.enabled = true

    // if found select next occurance
    if (off != null)
    {
      richText.select(off, q.size)
      setMsg("")
      return
    }

    // if not found, try from beginning of file
    if (pos > 0 && forward)
    {
      off = text.index(q, 0)
      if (off != null)
      {
        richText.select(off, q.size)
        setMsg(Flux#.loc("find.wrapToTop"))
        return
      }
    }

    // if not found, try from end of file
    if (pos < text.size && !forward)
    {
      off = text.indexr(q, text.size)
      if (off != null)
      {
        richText.select(off, q.size)
        setMsg(Flux#.loc("find.wrapToBottom"))
        return
      }
    }

    // not found
    richText.selectClear
    setMsg(Flux#.loc("find.notFound"))
    cmdPrev.enabled = false
    cmdNext.enabled = false
  }

  **
  ** Find the next occurance of the query string starting
  ** at the current caretPos.
  **
  internal Void next()
  {
    find(richText.caretPos)
  }

  **
  ** Find the previous occurance of the query string starting
  ** at the current caretPos.
  **
  internal Void prev()
  {
    find(richText.caretPos, false)
  }

  private Void setMsg(Str text)
  {
    msg.text = text
    msg.parent.relayout
  }

  private RichText richText
  private Int caretPos
  private Text findText
  private Label msg := Label()
  private Command cmdNext := Command.makeLocale(Flux#.pod, "findPrev", &prev)
  private Command cmdPrev := Command.makeLocale(Flux#.pod, "findNext", &next)
  private Command cmdHide := Command.makeLocale(Flux#.pod, "findHide", &hide)
}

internal class Temp : ContentPane
{
  override Size prefSize(Hints hints := Hints.def)
  {
    ps := super.prefSize(hints)
    return Size(200, ps.h)
  }
}