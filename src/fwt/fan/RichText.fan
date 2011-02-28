//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jul 08  Brian Frank  Creation
//

using gfx

**
** RichText is used to view and edit text styled with
** different fonts and colors.
**
@Js
@Serializable
class RichText : TextWidget
{

  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

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
  @Transient EventListeners onModify := EventListeners() { private set }

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
  @Transient EventListeners onVerify := EventListeners() { private set }

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
  @Transient EventListeners onVerifyKey := EventListeners() { private set }

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
  @Transient EventListeners onSelect := EventListeners() { private set }

  **
  ** Callback when the caret position is modified.
  **
  ** Event id fired:
  **   - `EventId.caret`
  **
  ** Event fields:
  **   - `Event.offset`: the new caret offset
  **
  @Transient EventListeners onCaret := EventListeners() { private set }

  **
  ** Horizontal scroll bar.
  **
  @Transient ScrollBar hbar := ScrollBar() { private set }

  **
  ** Vertical scroll bar.
  **
  @Transient ScrollBar vbar := ScrollBar() { private set }

  **
  ** Backing data model of text document.
  ** The model cannot be changed once the widget has been
  ** been mounted into an open window.
  **
  RichTextModel? model
  {
    set
    {
      if (attached) throw Err("Cannot change model once widget is attached")
      old := this.&model
      if (old != null) old.onModify.remove(onModelModifyFunc)
      if (it != null) it.onModify.add(onModelModifyFunc)
      this.&model = it
    }
  }

  private |Event| onModelModifyFunc := |e| { onModelModify(e) }
  internal native Void onModelModify(Event event)

  **
  ** Tab width measured in space characters.  Default is 2.
  **
  native Int tabSpacing

  **
  ** The zero based line index which is currently at the
  ** top of the scrolling viewport.
  **
  virtual native Int topLine

  **
  ** Convenience for 'model.text' (model must be installed).
  **
  override Str text
  {
    get { return model.text }
    set { model.text = it }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Map a coordinate on the widget to an offset in the text,
  ** or return null if no mapping at specified point.
  **
  native Int? offsetAtPos(Int x, Int y)

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

  **
  ** Ensure the editor is scrolled such that the specified line is visible.
  **
  native Void showLine(Int lineIndex)
}

**************************************************************************
** RichTextModel
**************************************************************************

**
** RichTextModel models the document and styling of a `RichText` document.
**
@Js
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
  @Transient EventListeners onModify := EventListeners() { private set }

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
      return lineText[offsetInLine..<offsetInLine+len]
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
        buf.add(lineText[0..<n])
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
  ** specifies a zero based char offset of the line using a pattern
  ** such as:
  **
  **   [Int, RichTextStyle, Int, RichTextStyle, ...]
  **
  virtual Obj[]? lineStyling(Int lineIndex) { return null }

  **
  ** Return the color to use for the specified line's background.
  ** Normal lineStyling backgrounds only cover the width of the text.
  ** However, the lineBackground covers the width of the entire
  ** edit area.  Return null for no special background.
  **
  virtual Color? lineBackground(Int lineIndex) { return null }
}

**************************************************************************
** RichTextStyle
**************************************************************************

**
** Defines the font and color styling of a text
** segment in a `RichTextModel`.
**
@Js
@Serializable
const class RichTextStyle
{
  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  ** Foreground color
  const Color? fg

  ** Background color or null
  const Color? bg

  ** Font of text segment
  const Font? font

  ** Underline color, if null then use fg color.
  const Color? underlineColor

  ** Underline style or none for no underline.
  const RichTextUnderline underline := RichTextUnderline.none

  override Str toStr()
  {
    s := StrBuf()
    if (fg != null) s.add("fg=$fg")
    if (bg != null) s.add(" bg=$bg")
    if (font != null) s.add(" font=$font")
    if (underline != RichTextUnderline.none) s.add(" underline=$underline")
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
@Js
enum class RichTextUnderline
{
  none,
  single,
  squiggle
}