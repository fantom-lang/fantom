//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jul 08  Brian Frank  Creation
//

using fwt
using flux

**
** TextEditor provides a syntax color coded editor for
** working with text files.
**
@fluxViewMimeType="text"
class TextEditor : View
{

//////////////////////////////////////////////////////////////////////////
// Loading
//////////////////////////////////////////////////////////////////////////

  override Widget buildToolBar()
  {
    return ToolBar
    {
      addCommand(frame.command(CommandId.cut))
      addCommand(frame.command(CommandId.copy))
      addCommand(frame.command(CommandId.paste))
      addSep
      addCommand(frame.command(CommandId.undo))
      addCommand(frame.command(CommandId.redo))
    }
  }

  override Widget buildStatusBar()
  {
    controller.updateCaretField()
    return GridPane
    {
      numCols = 2
      hgap = 10
      halignPane = Halign.right
      add(caretField)
      add(charsetField)
    }
  }

  override Void onLoad()
  {
    // init
    file = resource->file
    options  = TextEditorOptions.load
    syntax   = SyntaxOptions.load
    charset  = options.charset

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
    content = richText
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

  private Str[] readAllLines()
  {
    in := file.in { charset = charset }
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
    out := file.out { charset = charset }
    try
      doc.save(out)
    finally
      out.close
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  File file
  Charset charset
  TextEditorOptions options
  SyntaxOptions syntax
  SyntaxRules rules
  RichText richText
  Doc doc
  TextEditorController controller
  internal DateTime fileTimeAtLoad
  internal Label caretField := Label()
  internal Label charsetField := Label()
}