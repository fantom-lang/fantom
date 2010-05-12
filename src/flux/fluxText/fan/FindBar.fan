//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Sep 08  Andy Frank  Creation
//

using concurrent
using gfx
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
    history := FindHistory.load

    findText = Combo() { editable = true }
    findText.items = history.find
    findText.onFocus.add  |->| { caretPos = richText.selectStart }
    findText.onBlur.add   |->| { updateHistory }
    findText.onModify.add |->| { find(null, true, true) }
    findText.onKeyDown.add |e|
    {
      switch (e.key)
      {
        case Key.esc:   hide; editor.richText.focus
        case Key.enter: next
      }
    }

    matchCase = Button
    {
      mode = ButtonMode.check
      text = Flux.locale("find.matchCase")
      onAction.add |->| { updateHistory; find(null, true, true) }
      selected = history.matchCase
    }

    findPane = InsetPane(4,4,4,4)
    {
      EdgePane
      {
        center = GridPane
        {
          numCols = 5
          ConstraintPane { minw=50; maxw=50; Label { text = Flux.locale("find.name") }, },
          ConstraintPane { minw=200; maxw=200; findText, },
          InsetPane(0,0,0,8) { matchCase, },
          ToolBar
          {
            addCommand(cmdNext)
            addCommand(cmdPrev)
          },
          msg,
        }
        right = ToolBar { addCommand(cmdHide) }
      },
    }

    replaceText = Combo() { editable = true }
    replaceText.items = history.find
    if (replaceText.items.size > 1)
      replaceText.selectedIndex = 1
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
        ConstraintPane { minw=50; maxw=50; Label { text = Flux.locale("replace.name") }, },
        ConstraintPane { minw=200; maxw=200; it.add(replaceText) },
        InsetPane(0,0,0,8)
        {
          GridPane
          {
            numCols = 2
            Button { command = cmdReplace;    image = null },
            Button { command = cmdReplaceAll; image = null },
          },
        },
      },
    }

    content = EdgePane
    {
      it.top = BorderPane
      {
        it.border = Border("1,0,1 $Desktop.sysNormShadow,#000,$Desktop.sysHighlightShadow")
      }
      it.center = EdgePane
      {
        it.top    = findPane
        it.bottom = replacePane
      }
    }

    visible = Actor.locals.get("fluxTest.findBar.show", false)
    replacePane.visible = Actor.locals.get("fluxTest.findBar.showReplace", false)
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
    find(null, true, true)
  }

  **
  ** Show the FindBar with find and replace in the parent widget.
  **
  Void showFindReplace()
  {
    show(true)
    find(null, true, true)
  }

  private Void show(Bool showReplace := false)
  {
    Actor.locals["fluxTest.findBar.show"] = true
    Actor.locals["fluxTest.findBar.showReplace"] = showReplace

    ignore = true
    oldVisible := visible
    visible = true
    replacePane.visible = showReplace
    parent?.parent?.parent?.relayout

    // use current selection if it exists
    cur := richText.selectText
    if (cur.size > 0) findText.text = cur

    // make sure text is focued and selected
    findText.focus
    //findText.selectAll

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
    Actor.locals["fluxTest.findBar.show"] = false
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
  ** is searched backwards starting at pos.  If calcTotal
  ** is true, the document is searched for the total
  ** number of occurances of the query string.
  **
  internal Void find(Int? fromPos, Bool forward := true, Bool calcTotal := false)
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

      // find total matches
      if (calcTotal)
      {
        total = 0
        Int? temp := 0
        while ((temp = doc.findNext(q, temp, match)) != null) { total++; temp++ }
      }
      matchStr := msgTotal

      // if found select next occurance
      if (off != null)
      {
        richText.select(off, q.size)
        setMsg(matchStr)
        return
      }

      // if not found, try from beginning of file
      if (pos > 0 && forward)
      {
        off = doc.findNext(q, 0, match)
        if (off != null)
        {
          richText.select(off, q.size)
          setMsg("$matchStr - " + Flux.locale("find.wrapToTop"))
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
          setMsg("$matchStr - " + Flux.locale("find.wrapToBottom"))
          return
        }
      }

      // not found
      richText.selectClear
      setMsg(Flux.locale("find.notFound"))
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
    updateHistory
    if (!visible) show
    find(richText.caretOffset)
  }

  **
  ** Find the previous occurance of the query string starting
  ** at the current caretPos.
  **
  internal Void prev()
  {
    updateHistory
    if (!visible) show
    find(richText.caretOffset, false)
  }

  **
  ** Replace the current query string with the replace string.
  **
  internal Void replace()
  {
    updateHistory
    newText := replaceText.text
    start   := richText.selectStart
    len     := richText.selectSize
    richText.modify(start, len, newText)
    richText.select(start, newText.size)
    total--
    if (total > 0) setMsg(msgTotal)
    else
    {
      cmdPrev.enabled       = false
      cmdNext.enabled       = false
      cmdReplace.enabled    = false
      cmdReplaceAll.enabled = false
      setMsg(Flux.locale("find.notFound"))
    }
 }

  **
  ** Replace all occurences of the current query string with
  ** the replace string.
  **
  internal Void replaceAll()
  {
    updateHistory
    query   := findText.text
    replace := replaceText.text
    match   := matchCase.selected
    pos     := 0
    off     := doc.findNext(query, pos, match)

    while (off != null)
    {
      richText.modify(off, query.size, replace)
      pos = off + replace.size
      off = doc.findNext(query, pos, match)
    }

    cmdPrev.enabled       = false
    cmdNext.enabled       = false
    cmdReplace.enabled    = false
    cmdReplaceAll.enabled = false
    setMsg(Flux.locale("find.notFound"))
  }

  private Void setMsg(Str text)
  {
    msg.text = text
    msg.parent.relayout
  }

  private Str msgTotal()
  {
    return total == 1
      ? "1 " + Flux.locale("find.match")
      : "$total " + Flux.locale("find.matches")
  }

  private Void updateHistory()
  {
    // save history
    history := FindHistory.load
    if (replacePane.visible)
      history.pushFind(replaceText.text)
    history.pushFind(findText.text)
    history.matchCase = matchCase.selected
    history.save

    // update ui
    updateCombo(findText)
    updateCombo(replaceText)
  }

  private Void updateCombo(Combo c)
  {
    text := c.text
    if (text.size == 0) return
    if (text == c.items.first) return

    // bubble text to top
    ignore = true
    items := c.items.dup
    items.remove(text)
    items.insert(0, text)

    // update combo, limit items
    c.items = items[0..<20.min(items.size)]
    c.text = text  // set items nukes text, so reset
    ignore = false
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  override readonly TextEditor editor
  private Int caretPos

  private Widget findPane
  private Widget replacePane
  private Combo findText
  private Combo replaceText
  private Button matchCase
  private Int total
  private Label msg := Label()
  private Bool ignore := false

  private Command cmdNext := Command.makeLocale(Flux#.pod, "findPrev") { prev }
  private Command cmdPrev := Command.makeLocale(Flux#.pod, "findNext") { next }
  private Command cmdHide := Command.makeLocale(Flux#.pod, "findHide") { hide }
  private Command cmdReplace    := Command.makeLocale(Flux#.pod, "replace")    { replace }
  private Command cmdReplaceAll := Command.makeLocale(Flux#.pod, "replaceAll") { replaceAll }
}