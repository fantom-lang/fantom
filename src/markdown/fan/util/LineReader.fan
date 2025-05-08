//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 May 2025  Matthew Giannini  Creation
//

**
** Reads lines from an `InStream` but also retursn the line terminators.
**
** Line terminators can be either a line feed '\n', carriage return '\r', or a
** carriage return followed by a line feed '\r\n'. Call `lineTerminator` after
** `readLine` to obtain the corresponding line terminator. If a stream has a line at
** the end without a terminator, `lineTerminator` returns null.
**
@Js
internal class LineReader
{
  new make(InStream in)
  {
    this.in = in
  }

  internal static const Int buf_size := 8192
  private static const Int expected_line_len := 80

  private InStream in
  private StrBuf cbuf := StrBuf(buf_size)
  private Int pos := 0
  private Int limit := 0

  ** Get the line terminator of the last read line
  Str? lineTerminator { private set }

  ** Read a line of text.
  **
  ** Return the line, or null when the end of the stream has been reached and no
  ** more lines can be read.
  Str? readLine()
  {
    StrBuf? sb := null
    cr := false

    while (true)
    {
      if (pos >= limit) fill

      if (cr)
      {
        // we saw a CR before, check if we have CR LF or just CR
        if (pos < limit && cbuf[pos] == '\n')
        {
          pos++
          return line(sb.toStr, "\r\n")
        }
        else
        {
          return line(sb.toStr, "\r")
        }
      }

      if (pos >= limit)
      {
        // end of stream, return either the last line without terminator or null for end
        return line(sb?.toStr, null)
      }

      start := pos
      i := pos
      for (; i < limit; ++i)
      {
        c := cbuf[i]
        if (c == '\n')
        {
          pos = i + 1
          return line(finish(sb, start, i), "\n")
        }
        else if (c == '\r')
        {
          if (i + 1 < limit)
          {
            // we know what the next character is so we can check now whether we have
            // a CR LF or just a CR and return
            if (cbuf[i+1] == '\n')
            {
              pos = i + 2
              return line(finish(sb, start, i), "\r\n")
            }
            else
            {
              pos = i + 1
              return line(finish(sb, start, i), "\r")
            }
          }
          else
          {
            // we don't know what the next character is yet, check on next iteration
            cr = true
            pos = i + 1
            break
          }
        }
      }

      if (pos < i) pos = i

      // haven't found a finished line yet, copy the data from the buffer so that we can
      // fill the buffer again
      if (sb == null) sb = StrBuf(expected_line_len)
      len := i - start
      sb.add(cbuf[start..<(start+len)])
    }
    throw Err("Should never get here")
  }

  Void close()
  {
    in.close
  }

  private Void fill()
  {
    cbuf.clear
    read := 0
    while (true)
    {
      if (read > buf_size) break
      ch := in.readChar
      if (ch == null) break
      cbuf.addChar(ch)
      ++read
    }
    if (read > 0)
    {
      this.limit = read
      this.pos = 0
    }
  }

  private Str? line(Str? line, Str? term)
  {
    this.lineTerminator = term
    return line
  }

  private Str finish(StrBuf? sb, Int start, Int end)
  {
    sb == null
      ? cbuf[start..<end]
      : sb.add(cbuf[start..<end]).toStr
  }
}