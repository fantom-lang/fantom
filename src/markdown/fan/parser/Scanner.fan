//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Oct 2024  Matthew Giannini  Creation
//

**
** Scanner is a utility class for parsing lines
**
@Js
class Scanner
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new makeLine(SourceLine line) : this.make([line]) { }

  new makeSourceLines(SourceLines sourceLines) : this.make(sourceLines.lines) { }

  new make(SourceLine[] lines, Int lineIndex := 0, Int index := 0)
  {
    this.lines = lines
    this.lineIndex = lineIndex
    this.index = index
    if (!lines.isEmpty)
    {
      checkPos(lineIndex, index)
      setLine(lines[lineIndex])
    }
  }

  ** Lines without newlines at the end. The scanner will yield '\n' between lines
  ** becaue they're significant for parsing and the final output. There isno
  ** '\n' after the last line.
  private const SourceLine[] lines

  ** Which line we're at
  private Int lineIndex

  ** The index within the line. If index == length() we pretend that there's a '\n'
  ** and only advance after we yield that.
  private Int index

  ** Current line or "" if at the end of the lines (using "" isntead of null save check)
  private SourceLine line := SourceLine("")
  private Int lineLen := 0

  ** Char representing the end of input source (or outside of the text in case of the
  ** "previous" methods).
  **
  ** Note: we can use NULL to represent this because CommonMark does not allow those in
  ** the input (and they have already been replaced by this point)
  internal static const Int END := '\u0000'

//////////////////////////////////////////////////////////////////////////
// Scanner
//////////////////////////////////////////////////////////////////////////

  ** Peek at the next character without consuming it
  Int peek()
  {
    if (index < lineLen)
      return line.content[index]
    else
    {
      if (lineIndex < lines.size - 1) return '\n'
      else return END
    }
  }

  ** Peek at the next code point
  Int peekCodePoint()
  {
    if (index < lineLen)
    {
      c := line.content[index]
      return c
    }
    else
    {
      if (lineIndex < lines.size - 1) return '\n'
      else return END
    }
  }

  ** Peek at the previous codepoint
  Int peekPrevCodePoint()
  {
    if (index > 0)
    {
      prev := index - 1
      c := line.content[prev]
      return c
    }
    else
    {
      if (lineIndex > 0) return '\n'
      else return END
    }
  }

  ** Are there more characters to consume
  Bool hasNext()
  {
    if (index < lineLen) return true
    else
    {
      // no newline at end of last line
      return lineIndex < lines.size - 1
    }
  }

  ** Advance the scanner to the next character
  Void next()
  {
    ++index
    if (index > lineLen)
    {
      ++lineIndex
      if (lineIndex < lines.size)
        setLine(lines[lineIndex])
      else
        setLine(SourceLine(""))
      index = 0
    }
  }

  ** Consume as many 'ch' in a row as possible and return the number consumed.
  Int matchMultiple(Int ch)
  {
    count := 0
    while (peek == ch)
    {
      ++count
      next
    }
    return count
  }

  ** Consume characters while the given function returns 'true' and return
  ** the number of characters consumed.
  Int match(|Int->Bool| f)
  {
    count := 0
    while (f(peek))
    {
      ++count
      next
    }
    return count
  }

  ** Consume whitespace and return the number of whitespace characters consumed
  **
  ** Whitespace is defined as space, \t, \n, \u000B, \f, and \r
  Int whitespace()
  {
    count := 0
    done := false
    while (!done)
    {
      switch (peek)
      {
        case ' ':
        case '\t':
        case '\n':
        case '\u000B':
        case '\f':
        case '\r':
          // fall-through
          ++count
          next
        default:
          done = true
      }
    }
    return count
  }

  ** Scan until we find the given 'ch'.
  ** Return the number of characters skipped, or -1 if we hit
  ** the end of the line.
  Int find(Int ch)
  {
    count := 0
    while (true)
    {
      cur := peek
      if (cur == END) return -1
      else if (cur == ch) break
      ++count
      next
    }
    return count
  }

  ** Consume characters until the given function returns true, or the end-of-line
  ** is reached. Return the number of characters skipped, or -1 if we reach the end.
  Int findMatch(|Int->Bool| f)
  {
    count := 0
    while (true)
    {
      c := peek
      if (c == END) return -1
      else if (f(c)) break
      ++count
      next
    }
    return count
  }

  ** Check if the specified char is next and advance the position.
  **
  ** 'ch': the char to check (including newline chars)
  **
  ** Return true if matched and position was advanced; false otherwise
  Bool nextCh(Int ch)
  {
    if (peek == ch) { next; return true }
    return false
  }

  ** Check if we have the specified content on the line and advance the position.
  ** Note that if you want to match newline characters, use `nextCh`.
  **
  ** 'content': the text content to match on a single line (excluding newline)
  **
  ** Return true if matched and position was advanced; false otherwise
  Bool nextStr(Str content)
  {
    if (index < lineLen && index + content.size <= lineLen)
    {
      for (i := 0; i < content.size; ++i)
      {
        if (line.content[index+i] != content[i])
          return false
      }
      index += content.size
      return true
    }
    return false
  }

  ** Get the current position (current line, index into that line)
  Position pos() { Position(lineIndex, index) }

  ** Set the current position for the scanner
  Void setPos(Position pos)
  {
    checkPos(pos.lineIndex, pos.index)
    this.lineIndex = pos.lineIndex
    this.index = pos.index
    setLine(lines.get(this.lineIndex))
  }

  ** For cases where the caller appends the result to a StrBuf, we could offer another
  ** method to avoid some unnecessary copying.
  SourceLines source(Position begin, Position end)
  {
    if (begin.lineIndex == end.lineIndex)
    {
      // shortcut for common case of text from a single line
      line := lines[begin.lineIndex]
      newContent := line.content[begin.index..<end.index]
      SourceSpan? newSourceSpan := null
      sourceSpan := line.sourceSpan
      if (sourceSpan != null)
        newSourceSpan = sourceSpan.subSpan(begin.index, end.index)
      return SourceLines(SourceLine(newContent, newSourceSpan))
    }
    else
    {
      // get content between multiple lines
      sourceLines := SourceLines.empty
      firstLine := lines[begin.lineIndex]
      sourceLines.addLine(firstLine.substring(begin.index, firstLine.content.size))

      // lines between begin and end (we are appending the full line)
      for (line := begin.lineIndex + 1; line < end.lineIndex; ++line)
        sourceLines.addLine(lines[line])

      lastLine := lines[end.lineIndex]
      sourceLines.addLine(lastLine.substring(0, end.index))
      return sourceLines
    }
  }

  private Void setLine(SourceLine line)
  {
    this.line = line
    this.lineLen = line.content.size
  }

  private Void checkPos(Int lineIndex, Int index)
  {
    if (lineIndex < 0 || lineIndex >= lines.size)
      throw ArgErr("Line index ${lineIndex} out of range, number of lines: ${lines.size}")
    line := lines.get(lineIndex)
    if (index < 0 || index > line.content.size)
      throw ArgErr("Index ${index} out of range, line length: ${line.content.size}")
  }
}

**************************************************************************
** Position
**************************************************************************

**
** A position in the `Scanner` consists of its line index (i.e. line number)
** and its index within the line
**
@Js
const class Position
{
  new make(Int lineIndex, Int index)
  {
    this.lineIndex = lineIndex
    this.index = index
  }

  const Int lineIndex
  const Int index

  override Str toStr() { "pos(line=${lineIndex}, index=${index})" }
}

