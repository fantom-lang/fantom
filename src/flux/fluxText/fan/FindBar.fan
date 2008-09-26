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
internal class FindBar : ContentPane, TextEditorSupport
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(TextEditor editor)
  {
    this.editor = editor

    findText = Text()
    findText.onFocus.add |Event e| { caretPos = richText.caretOffset }
    findText.onKeyDown.add |Event e| { if (e.key == Key.esc) hide }
    findText.onModify.add |Event e| { find(null, true) }

    matchCase = Button
    {
      mode = ButtonMode.check
      text = Flux#.loc("find.matchCase")
      onAction.add(&find(null, true))
    }

    findPane = InsetPane(4,4,4,4)
    {
      EdgePane
      {
        center = GridPane
        {
          numCols = 5
          ConstraintPane { minw=50; maxw=50; Label { text = Flux#.loc("find.name") }}
          ConstraintPane { minw=200; maxw=200; add(findText) }
          InsetPane(0,0,0,8) { matchCase }
          ToolBar
          {
            addCommand(cmdNext)
            addCommand(cmdPrev)
          }
          msg
        }
        right = ToolBar { addCommand(cmdHide) }
      }
    }

    replaceText = Text()
    replaceText.onKeyDown.add |Event e| { if (e.key == Key.esc) hide }
    replaceText.onModify.add |Event e|
    {
      v := findText.text.size > 0 && replaceText.text.size > 0
      cmdReplace.enabled = cmdReplaceAll.enabled = v
    }

    replacePane = InsetPane(0,4,4,4)
    {
      GridPane
      {
        numCols = 3
        ConstraintPane { minw=50; maxw=50; Label { text = Flux#.loc("replace.name") } }
        ConstraintPane { minw=200; maxw=200; add(replaceText) }
        InsetPane(0,0,0,8)
        {
          GridPane
          {
            numCols = 2
            Button { command = cmdReplace;    image = null }
            Button { command = cmdReplaceAll; image = null }
          }
        }
      }
    }

    content = BorderPane
    {
      content = EdgePane
      {
        top    = findPane
        bottom = replacePane
      }
      insets = Insets(2,0,0,0)
      onBorder = |Graphics g, Size size|
      {
        g.brush = Color.sysNormShadow
        g.drawLine(0, 0, size.w, 0)
        g.brush = Color.sysHighlightShadow
        g.drawLine(0, 1, size.w, 1)
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Show the FindBar with find only in the parent widget.
  **
  Void showFind()
  {
    show(false)
  }

  **
  ** Show the FindBar with find and replace in the parent widget.
  **
  Void showFindReplace()
  {
    show(true)
  }

  private Void show(Bool showReplace := false)
  {
    ignore = true
    oldVisible := visible
    visible = true
    replacePane.visible = showReplace
    parent?.parent?.parent?.relayout

    // bail if we were already visible
    if (oldVisible)
    {
      ignore = false
      return
    }

    // use current selection if it exists
    cur := richText.selectText
    if (cur.size > 0) findText.text = cur

    // make sure text is focued and selected
    findText.focus
    findText.selectAll

    // if text empty, make sure prev/next disabled
    if (findText.text.size == 0)
    {
      cmdPrev.enabled = false
      cmdNext.enabled = false
    }

    // clear any old msg text
    setMsg("")
    ignore = false
  }

  **
  ** Hide the FindBar in the parent widget.
  **
  Void hide()
  {
    visible = false
    parent?.parent?.parent?.relayout
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  **
  ** Find the current query string in the text document,
  ** starting at the given caret pos.  If pos is null,
  ** the caretPos recorded when the FindBar was focued
  ** will be used.  If forward is false, the document
  ** is searched backwards starting at pos.
  **
  internal Void find(Int fromPos, Bool forward := true)
  {
    if (!visible || ignore) return
    enabled := false
    try
    {
      q := findText.text
      if (q.size == 0)
      {
        setMsg("")
        return
      }

      enabled = true
      match := matchCase.selected
      pos   := fromPos ?: caretPos
      off   := forward ?
        doc.findNext(q, pos, match) :
        doc.findPrev(q, pos-q.size-1, match)

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
        off = doc.findNext(q, 0, match)
        if (off != null)
        {
          richText.select(off, q.size)
          setMsg(Flux#.loc("find.wrapToTop"))
          return
        }
      }

      // if not found, try from end of file
      if (pos < doc.size && !forward)
      {
        off = doc.findPrev(q, doc.size, match)
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
      enabled = false
    }
    finally
    {
      replaceEnabled := enabled && replaceText.text.size > 0
      cmdPrev.enabled       = enabled
      cmdNext.enabled       = enabled
      cmdReplace.enabled    = replaceEnabled
      cmdReplaceAll.enabled = replaceEnabled
    }
  }

  **
  ** Find the next occurance of the query string starting
  ** at the current caretPos.
  **
  internal Void next()
  {
    if (!visible) show
    find(richText.caretOffset)
  }

  **
  ** Find the previous occurance of the query string starting
  ** at the current caretPos.
  **
  internal Void prev()
  {
    if (!visible) show
    find(richText.caretOffset, false)
  }

  **
  ** Replace the current query string with the replace string.
  **
  internal Void replace()
  {
    newText := replaceText.text
    start   := richText.selectStart
    len     := richText.selectSize
    richText.modify(start, len, newText)
    richText.select(start, newText.size)
  }

  **
  ** Replace all occurences of the current query string with
  ** the replace string.
  **
  internal Void replaceAll()
  {
    echo("TODO: replaceAll")
  }

  private Void setMsg(Str text)
  {
    msg.text = text
    msg.parent.relayout
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  override readonly TextEditor editor
  private Int caretPos

  private Widget findPane
  private Widget replacePane
  private Text findText
  private Text replaceText
  private Button matchCase
  private Label msg := Label()
  private Bool ignore := false

  private Command cmdNext := Command.makeLocale(Flux#.pod, "findPrev", &prev)
  private Command cmdPrev := Command.makeLocale(Flux#.pod, "findNext", &next)
  private Command cmdHide := Command.makeLocale(Flux#.pod, "findHide", &hide)
  private Command cmdReplace    := Command.makeLocale(Flux#.pod, "replace",    &replace)
  private Command cmdReplaceAll := Command.makeLocale(Flux#.pod, "replaceAll", &replaceAll)
}
