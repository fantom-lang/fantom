//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Apr 2025  Matthew Giannini  Creation
//

**
** Text writer for markdown rendering
**
@Js
class TextWriter
{
  new make(OutStream out, LineBreakRendering lineBreakRendering := LineBreakRendering.compact)
  {
    this.out = out
    this.lineBreakRendering = lineBreakRendering
  }

  private OutStream out
  private const LineBreakRendering lineBreakRendering

  private Bool[] tight := [,]

  private Str? blockSeparator := null
  private Int lastChar := 0

  private static const Regex stripPattern := Regex<|[\r\n\s]+|>

  This whitespace()
  {
    if (lastChar != 0 && lastChar != ' ') writeChar(' ')
    return this
  }

  This colon()
  {
    if (lastChar != 0 && lastChar != ':') writeChar(':')
    return this
  }

  This line()
  {
    appendChar('\n')
    return this
  }

  This block()
  {
    // if (lineBreakRendering ===LineBreakRendering.strip)
    //   this.blockSeparator = " "
    // else if (lineBreakRendering === LineBreakRendering.compact || isTight)
    // {
    //   echo("B")
    //   this.blockSeparator = "\n"
    // }
    // else
    // {
    //   echo("C")
    //   this.blockSeparator = "\n\n"
    // }
    this.blockSeparator =
      lineBreakRendering === LineBreakRendering.strip
        ? " "
        : ((lineBreakRendering === LineBreakRendering.compact || isTight) ? "\n" : "\n\n")
    return this
  }

  This resetBlock()
  {
    this.blockSeparator = null
    return this
  }

  This writeStripped(Str s)
  {
    write(stripPattern.matcher(s).replaceAll(" "))
  }

  This writeChar(Int ch)
  {
    flushBlockSeparator
    appendChar(ch)
    return this
  }

  This write(Str s)
  {
    flushBlockSeparator
    append(s)
    return this
  }

  private Void appendChar(Int ch)
  {
    out.writeChar(ch)
    this.lastChar = ch
  }

  private Void append(Str s)
  {
    out.writeChars(s)
    if (!s.isEmpty) lastChar = s[-1]
  }

  ** Change whether blocks are tight or loose. Loose is the default where blocks are
  ** separated by a blank line.  Tight is where blocks are not spearated by a blank line.
  ** Tight blocks are used in lists, if there are no blank lines within the list.
  **
  ** Note that changing this does not affect block separators that have already been
  ** enqueued with `block`; only future ones.
  Void pushTight(Bool tight) { this.tight.push(tight) }

  ** Remove the last "tight" setting from the top of the stack.
  Void popTight() { this.tight.pop }

  private Bool isTight() { !tight.isEmpty && tight.last }

  ** If a block separator has been enqueued with `block` but not yet written, write it now
  private Void flushBlockSeparator()
  {
    if (this.blockSeparator != null)
    {
      // blockSeparator.each |ch| { appendChar(ch) }
      append(blockSeparator)
      blockSeparator = null
    }
  }
}