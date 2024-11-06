//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Nov 2024  Matthew Giannini  Creation
//

**
** Writer for Markdown (CommonMark) text.
**
@Js
class MarkdownWriter
{
  new make(OutStream out)
  {
    this.out = out
  }

  private OutStream out
  private Int blockSep := 0

  ** The last character that was written
  Int lastChar := 0 { private set }

  ** Wheter we're at the line start (not counting any prefixes),
  ** i.e. after a `line` or `block`.
  Bool atLineStart := true { private set }

  // stackso of settings that affect various rendering behaviors. The common pattern
  // here is that callers use "push" to change a setting, render some nodes, and then
  // "pop" the setting off the stack again to restore previous state
  private Str[] prefixes := [,]
  private Bool[] tight := [,]
  private |Int->Bool|[] rawEscapes := [,]

  ** Write the supplied string or character (raw/unescaped except if `pushRawEscape`
  ** was used).
  Void raw(Obj obj)
  {
    if (obj is Str) rawStr(obj)
    else rawCh(obj)
  }

  private Void rawStr(Str s)
  {
    flushBlockSeparator
    writeStr(s)
  }

  private Void rawCh(Int c)
  {
    flushBlockSeparator
    write(c)
  }

  ** Write the supplied string with escaping
  Void text(Str s, |Int->Bool|? escape := null)
  {
    if (s.isEmpty) return
    flushBlockSeparator
    writeStr(s, escape)

    lastChar = s[-1]
    atLineStart = false
  }

  ** Write a newline (line terminator).
  Void line()
  {
    write('\n')
    writePrefixes
    atLineStart = true
  }

  ** Enqueue a block separator to be written before the next text is written.
  ** Block separators are not written straight away because if there are no more blocks
  ** to write, we don't want a separator (at the end of the document)
  Void block()
  {
    // remember whether this should be a tight or loose separator now because tight
    // could get changed in between this and the next flush
    blockSep = isTight ? 1 : 2
    atLineStart = true
  }

  ** Push a prefix onto the top of the stack. All prefixes are written at the
  ** beginning of each line, until the prefix is popped again.
  Void pushPrefix(Str prefix) { prefixes.add(prefix) }

  ** Write a prefix
  Void writePrefix(Str prefix)
  {
    tmp := atLineStart
    rawStr(prefix)
    atLineStart = tmp
  }

  ** Remove the last prefix from the top of the stack
  Void popPrefix() { prefixes.pop }

  ** Change whether blocks are tight or loose. Loose is the default where blocks are
  ** separated by a blank line. Tight is where blocks are not separated by a blank line.
  ** Tight blocks are used in lists, if there are no blank lines within the list.
  **
  ** Note that changing this does not affect block separators that have already been
  ** enqueued with `block`, only future ones.
  Void pushTight(Bool tight) { this.tight.add(tight) }

  ** Remove the last "tight" setting from the top of the stack
  Void popTight() { this.tight.pop }

  ** Escape the characters matching the supplied matcher, in all text (text and raw).
  ** This might be usefult to extensions that add another layer of syntax, e.g. the
  ** tables extension that uses '|' to separate cells and needs all '|' characters to be
  ** escaped (even in code spans)
  Void pushRawEscape(|Int->Bool| rawEscape) { rawEscapes.add(rawEscape) }

  ** Remove the last raw escape from the top of the stack
  Void popRawEscape() { rawEscapes.pop }

  private Void write(Int c)
  {
    append(c)
    lastChar = c
    atLineStart = false
  }

  private Void writeStr(Str s, |Int->Bool|? escape := null)
  {
    if (rawEscapes.isEmpty && escape == null)
    {
      // normal fast path
      out.writeChars(s)
    }
    else
    {
      s.each |c| { append(c, escape) }
    }

    if (!s.isEmpty) lastChar = s[-1]
    atLineStart = false
  }

  private Void writePrefixes()
  {
    prefixes.each |prefix| { writeStr(prefix) }
  }

  ** If a block separator has been enqueued with `block` but not yet written, write it now
  private Void flushBlockSeparator()
  {
    if (blockSep != 0)
    {
      write('\n')
      writePrefixes
      if (blockSep > 1)
      {
        write('\n')
        writePrefixes
      }
      blockSep = 0
    }
  }

  private Void append(Int c, |Int->Bool|? escape := null)
  {
    if (needsEscaping(c, escape))
    {
      if (c == '\n')
      {
        // can't escape this with \, use numeric character reference
        out.writeChars("&#10;")
      }
      else
      {
        out.writeChar('\\')
        out.writeChar(c)
      }
    }
    else out.writeChar(c)
  }

  private Bool isTight() { !tight.isEmpty && tight.last }

  private Bool needsEscaping(Int c, |Int->Bool|? escape)
  {
    (escape != null && escape(c)) || rawNeedsEscaping(c)
  }

  private Bool rawNeedsEscaping(Int c)
  {
   rawEscapes.any |esc| { esc(c) }
  }
}