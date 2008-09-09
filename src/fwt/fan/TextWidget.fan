//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 08  Brian Frank  Creation
//

**
** TextWidget is the base class for `Text` and `RichText`.
**
abstract class TextWidget : Widget
{

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  **
  ** Draw a border around the text field.  Default is true.  This
  ** field cannot be changed once the widget is constructed.
  **
  const Bool border := true

  **
  ** False for text fields and true for multiline text areas.
  ** Default is false for `Text` widgets and true for `RichText`
  ** widgets.  This field cannot be changed once the widget
  ** is constructed.
  **
  const Bool multiLine := this is RichText

  **
  ** True to make wrap the text of a multiLine text widget.
  ** Default is false.  This field cannot be changed once the
  ** widget is constructed.
  **
  const Bool wrap := false

  **
  ** True use a horizontal scrollbar for multiLine text widget.
  ** Default is true.  This field cannot be changed once the
  ** widget is constructed.
  **
  const Bool hscroll := true

  **
  ** True use a vertical scrollbar for multiLine text widget.
  ** Default is true.  This field cannot be changed once the
  ** widget is constructed.
  **
  const Bool vscroll := true

  **
  ** The widget's current text
  **
  abstract Str text

  **
  ** The caret position as zero based offset
  ** from start of text.  Note that SWT doesn't allow
  ** setting of caret position for native widgets.
  **
  virtual native Int caretPos

  **
  ** Font for text. Defaults to null (system default).
  **
  virtual native Font font

//////////////////////////////////////////////////////////////////////////
// Selection
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the selected text or "" if nothing selected.
  **
  virtual native Str selectText()

  **
  ** Get the starting offset of the current selection.
  **
  virtual native Int selectStart()

  **
  ** Get the number of chars in the current selection.
  **
  virtual native Int selectSize()

  **
  ** Set the selection range.
  **
  virtual native Void select(Int startOffset, Int size)

  **
  ** Select the entire document.
  **
  virtual native Void selectAll()

  **
  ** Clear the selection.
  **
  virtual native Void selectClear()

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Replace the text with 'newText' starting at position 'start'
  ** for a length of 'replaceLen'.
  **
  abstract Void modify(Int start, Int replaceLen, Str newText)

  **
  ** Cuts the selected text to clipboard.
  **
  virtual native Void cut()

  **
  ** Copy the selected text to clipboard.
  **
  virtual native Void copy()

  **
  ** Paste the selected text to clipboard.
  **
  virtual native Void paste()

}

**************************************************************************
** TextChange
**************************************************************************

**
** Wraps up information regarding a text modification.
**
class TextChange
{
  ** Zero based offset of modification
  Int startOffset

  ** Zero based line number of modification
  Int startLine

  ** Old text which was replaced
  Str oldText

  ** New text inserted
  Str newText

  ** Number of newlines in `oldText` or zero if no newlines
  ** This field will lazily be calcualted if null.
  Int oldNumNewlines
  {
    get
    {
      if (@oldNumNewlines == null) @oldNumNewlines = oldText?.numNewlines
      return @oldNumNewlines
    }
  }

  ** Number of newlines in `newText` or zero if no newlines.
  ** This field will lazily be calcualted if null.
  Int newNumNewlines
  {
    get
    {
      if (@newNumNewlines == null) @newNumNewlines = newText?.numNewlines
      return @newNumNewlines
    }
  }

  ** Zero based offset of where repaint should start, or if
  ** null then `startOffset` is assumed.
  Int repaintStart

  ** Zero based offset of where repaint should end,
  ** or if null then 'newText.size' is assumed.
  Int repaintLen

  override Str toStr()
  {
    o := oldText.size < 10 ? oldText : oldText[0...10] + "..."
    n := newText.size < 10 ? newText : newText[0...10] + "..."
    return "startOffset=$startOffset startLine=$startLine " +
           "newText=$n.toCode oldText=$o.toCode " +
           "oldNumNewlines=$oldNumNewlines newNumNewlines=$newNumNewlines"
  }

//////////////////////////////////////////////////////////////////////////
// Undo/Redo Support
//////////////////////////////////////////////////////////////////////////

  **
  ** Undo this modification on the given widget.
  **
  Void undo(TextWidget widget)
  {
    widget.modify(startOffset, newText.size, oldText)
    widget.caretPos = startOffset + oldText.size
  }

  **
  ** Redo this modification on the given widget.
  **
  Void redo(TextWidget widget)
  {
    widget.modify(startOffset, oldText.size, newText)
    widget.caretPos = startOffset + newText.size
  }

}
