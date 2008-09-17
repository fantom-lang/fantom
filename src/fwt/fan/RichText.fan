//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jul 08  Brian Frank  Creation
//

**
** RichText is used to view and edit text styled with
** different fonts and colors.
**
class RichText : TextWidget
{

  **
  ** Callback when the text is modified.  This event occurs
  ** after the modification.  See `onVerify` to trap changes
  ** before they occur.
  **
  ** Event id fired:
  **   - `EventId.modified`
  **
  ** Event fields:
  **   - `Event.data`: the `TextChange` instance.
  **
  @transient readonly EventListeners onModify := EventListeners()

  **
  ** Callback before the text is modified.  This gives listeners
  ** a chance to intercept modifications and potentially modify
  ** the inserted text.  This event occurs before the modification.
  ** See `onModify` to trap changes after they occur.
  **
  ** Event id fired:
  **   - `EventId.verify`
  **
  ** Event fields:
  **   - `Event.data`: a `TextChange` instance where 'newText'
  **     specifies the proposed text being inserted.  The callback
  **     can update 'newText' with the actual text to be inserted
  **     or set to null to cancel the modification.
  **
  @transient readonly EventListeners onVerify := EventListeners()

  **
  ** Callback before a key event is processed.  This gives listeners
  ** a chance to trap the key event and [consume]`Event.consume`
  ** it before it is processed by the editor.
  **
  ** Event id fired:
  **   - `EventId.verifyKey`
  **
  ** Event fields:
  **   - `Event.keyChar`: unicode character represented by key event
  **   - `Event.key`: key code including the modifiers
  **
  @transient readonly EventListeners onVerifyKey := EventListeners()

  **
  ** Callback when the selection is modified.
  **
  ** Event id fired:
  **   - `EventId.select`
  **
  ** Event fields:
  **   - `Event.offset`: the starting offset
  **   - `Event.size`:   the number of chars selected
  **
  @transient readonly EventListeners onSelect := EventListeners()

  **
  ** Callback when the caret position is modified.
  **
  ** Event id fired:
  **   - `EventId.caret`
  **
  ** Event fields:
  **   - `Event.offset`: the new caret offset
  **
  @transient readonly EventListeners onCaret := EventListeners()

  **
  ** Backing data model of text document.
  **
  RichTextModel model
  {
    set
    {
      old := @model
      if (old != null) old.onModify.remove(onModelModifyFunc)
      if (val != null) val.onModify.add(onModelModifyFunc)
      @model = val
    }
  }

  private |Event| onModelModifyFunc := &onModelModify
  internal native Void onModelModify(Event event)

  **
  ** Tab width measured in space characters.  Default is 2.
  **
  native Int tabSpacing

  **
  ** Convenience for 'model.text' (model must be installed).
  **
  override Str text
  {
    get { return model.text }
    set { model.text = val }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Convenience for `RichTextModel.modify`.
  **
  override Void modify(Int start, Int replaceLen, Str newText)
  {
    model.modify(start, replaceLen, newText)
  }

//////////////////////////////////////////////////////////////////////////
// Painting
//////////////////////////////////////////////////////////////////////////

  **
  ** Repaint the line specified by the zero based line index.
  **
  Void repaintLine(Int lineIndex)
  {
    repaintRange(model.offsetAtLine(lineIndex), model.line(lineIndex).size)
  }

  **
  ** Repaint the specified text range.
  **
  native Void repaintRange(Int offset, Int len)
}

**************************************************************************
** RichTextModel
**************************************************************************

**
** RichTextModel models the document and styling of a `RichText` document.
**
abstract class RichTextModel
{

  **
  ** Callback model generated when the text is modified.
  **
  ** Event id fired:
  **   - `EventId.modified`
  **
  ** Event fields:
  **   - `Event.data`: the `TextChange`.
  **
  @transient readonly EventListeners onModify := EventListeners()

  **
  ** Get or set the entire text document.
  **
  abstract Str text

  **
  ** Return the number of characters in the content.
  **
  abstract Int charCount()

  **
  ** Return the number of lines.
  **
  abstract Int lineCount()

  **
  ** Return the line at the given zero based line index without delimiters.
  **
  abstract Str line(Int lineIndex)

  **
  ** Return the zero based line index at the given character offset.
  **
  abstract Int lineAtOffset(Int offset)

  **
  ** Return the character offset of the first character of the
  ** given zero based line index.
  **
  abstract Int offsetAtLine(Int lineIndex)

  **
  ** Return the line delimiter that should be used when inserting
  ** new lines. The default is "\n".
  **
  virtual Str lineDelimiter() { return "\n" }

  **
  ** Returns a string representing the content at the given range.
  ** The default implementation of textRange is optimized to assume
  ** the backing store is based on lines.
  **
  virtual Str textRange(Int start, Int len)
  {
    // map offsets to line, if the offset is the line's
    // delimiter itself, then offsetInLine will be negative
    lineIndex := lineAtOffset(start)
    lineOffset := offsetAtLine(lineIndex)
    lineText := line(lineIndex)
    offsetInLine := start-lineOffset

    // if this is a range within a single line, then use normal Str slice
    if (offsetInLine+len <= lineText.size)
    {
      return lineText[offsetInLine...offsetInLine+len]
    }

    // the range spans multiple lines
    buf := StrBuf(len)
    n := len

    // if the start offset is in the delimiter, then make sure
    // we start at next line, otherwise add the slice of the
    // first line to our buffer
    if (offsetInLine >= 0)
    {
      buf.add(lineText[offsetInLine..-1])
      n -= buf.size
    }

    // add delimiter of first line
    delimiter := lineDelimiter
    if (n > 0) { buf.add(delimiter);  n -= delimiter.size }

    // keep adding lines until we've gotten the full len
    while (n > 0)
    {
      lineText = line(++lineIndex)
      // full line (and maybe its delimiter)
      if (n >= lineText.size)
      {
        buf.add(lineText)
        n -= lineText.size
        if (n > 0) { buf.add(delimiter);  n -= delimiter.size }
      }
      // partial line
      else
      {
        buf.add(lineText[0...n])
        break
      }
    }
    return buf.toStr
  }

  **
  ** Replace the text with 'newText' starting at position 'start'
  ** for a length of 'replaceLen'.  The model implementation must
  ** fire the `onModify` event.
  **
  abstract Void modify(Int start, Int replaceLen, Str newText)

  **
  ** Return the styled segments for the given zero based line index.
  ** The result is a list of Int/RichTextStyle pairs where the Int
  ** specifies a zero based char offset of the line.
  **
  virtual Obj[] lineStyling(Int lineIndex) { return null }
}

**************************************************************************
** RichTextStyle
**************************************************************************

**
** Defines the font and color styling of a text
** segment in a `RichTextModel`.
**
@serializable
const class RichTextStyle
{
  ** Foreground color
  const Color fg

  ** Background color or null
  const Color bg

  ** Font of text segment
  const Font font

  ** Underline color, if null then use fg color.
  const Color underlineColor

  ** Underline style or none for no underline.
  const RichTextUnderline underline := RichTextUnderline.none

  override Str toStr()
  {
    s := StrBuf()
    if (fg != null) s.add("fg=$fg")
    if (bg != null) s.add(" bg=$bg")
    if (font != null) s.add(" font=$font")
    if (underline != null) s.add(" underline=$underline")
    if (underlineColor != null) s.add(" underlineColor=$underlineColor")
    return s.toStr.trim
  }
}

**************************************************************************
** RichTextUnderline
**************************************************************************

**
** Defines how to paint the underline of a RichText segment.
**
enum RichTextUnderline
{
  none,
  single,
  squiggle
}
