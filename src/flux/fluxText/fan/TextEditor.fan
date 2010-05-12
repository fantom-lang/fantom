//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jul 08  Brian Frank  Creation
//

using concurrent
using gfx
using fwt
using flux

**
** TextEditor provides a syntax color coded editor for
** working with text files.
**
class TextEditor : View
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  override Widget? buildToolBar()
  {
    return EdgePane
    {
      top = InsetPane(4,4,5,4)
      {
        ToolBar
        {
          addCommand(frame.command(CommandId.save))
          addSep
          addCommand(frame.command(CommandId.cut))
          addCommand(frame.command(CommandId.copy))
          addCommand(frame.command(CommandId.paste))
          addSep
          addCommand(frame.command(CommandId.undo))
          addCommand(frame.command(CommandId.redo))
        },
      }
      bottom = find
    }
  }

  override Widget? buildStatusBar()
  {
    controller.updateCaretStatus()
    return GridPane
    {
      it.numCols = 2
      it.hgap = 10
      it.halignPane = Halign.right
      it.add(caretField)
      it.add(charsetField)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  override Void onActive()
  {
    frame.command(CommandId.find).enabled = true
    frame.command(CommandId.findNext).enabled = true
    frame.command(CommandId.findPrev).enabled = true
    frame.command(CommandId.replace).enabled = true
    frame.command(CommandId.goto).enabled = true

    // restore viewport and caret position
    caretOffset := Actor.locals["fluxText.caretOffset.$resource.uri"]
    topLine := Actor.locals["fluxText.topLine.$resource.uri"]
    if (caretOffset != null) richText.caretOffset = caretOffset
    if (topLine != null) richText.topLine = topLine
    richText.focus
  }

  override Void onInactive()
  {
    // save viewport and caret position
    Actor.locals["fluxText.caretOffset.$resource.uri"] = richText.caretOffset
    Actor.locals["fluxText.topLine.$resource.uri"] = richText.topLine
  }

  override Void onCommand(Str id, Event? event)
  {
    controller.trap("on${id.capitalize}", [event])
  }

  override Void onMarks(Mark[] marks)
  {
    doc.updateMarks(marks)
  }

  override Void onGotoMark(Mark mark)
  {
    controller.onGotoMark(mark)
  }

//////////////////////////////////////////////////////////////////////////
// Loading
//////////////////////////////////////////////////////////////////////////

  override Void onLoad()
  {
    // init
    file = resource->file

    // load the document into memory
    loadDoc
    charsetField.text = charset.toStr

    // create rich text widget
    richText = RichText { model = doc; border = false }

    richText.font = syntax.font
    richText.tabSpacing = options.tabSpacing

    // initialize controller
    controller = TextEditorController(this)
    controller.register

    // update ui
    find = FindBar(this)
    content = BorderPane
    {
      it.content  = richText
      it.border   = Border("1,0,1,1 $Desktop.sysNormShadow")
    }
  }

  internal Void loadDoc()
  {
    // read document into memory, if we fail with the
    // configured charset, then fallback to ISO 8859-1
    // which will always "work" since it is byte based
    lines := readAllLines
    if (lines == null)
    {
      charset = Charset.fromStr("ISO-8859-1")
      lines   = readAllLines
    }

    // save this time away to check on focus events
    fileTimeAtLoad = file.modified

    // figure out what syntax file to use
    // based on file extension and shebang
    rules = SyntaxRules.load(syntax, file, lines.first)

    // load document
    doc = Doc(options, syntax, rules)
    doc.load(lines)
  }

  private Str[]? readAllLines()
  {
    in := file.in { it.charset = this.charset }
    try
      return in.readAllLines
    catch
      return null
    finally
      in.close
  }

//////////////////////////////////////////////////////////////////////////
// Saving
//////////////////////////////////////////////////////////////////////////

  override Void onSave()
  {
    out := file.out { it.charset = this.charset }
    try
      doc.save(out)
    finally
      out.close
    fileTimeAtLoad = file.modified
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  File? file
  TextEditorOptions options := TextEditorOptions.load
  SyntaxOptions syntax := SyntaxOptions.load
  Charset charset := options.charset
  SyntaxRules? rules
  RichText? richText
  Doc? doc
  internal TextEditorController? controller
  internal FindBar? find
  internal DateTime? fileTimeAtLoad
  internal Label caretField := Label()
  internal Label charsetField := Label()
}