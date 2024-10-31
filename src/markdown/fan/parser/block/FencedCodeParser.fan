//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

**
** Fenced code parser
**
@Js
internal class FencedCodeParser : BlockParser
{
  new make(Int fenceChar, Int fenceLen, Int fenceIndent)
  {
    this.fenceChar = fenceChar
    this.openingFenceLen = fenceLen
    this.block = FencedCode(fenceChar.toChar)
    block.openingFenceLen = fenceLen
    block.fenceIndent = fenceIndent
  }

  private const Int fenceChar
  private const Int openingFenceLen

  private Str? firstLine
  private StrBuf otherLines := StrBuf()

  override FencedCode block { private set }

  override BlockContinue? tryContinue(ParserState state)
  {
    nextNonSpace := state.nextNonSpaceIndex
    newIndex := state.index
    line := state.line.content
    if (state.indent < Parsing.code_block_indent && nextNonSpace < line.size && tryClosing(line, nextNonSpace))
    {
      // closing fence - we're at end of line, so we can finalize now
      return BlockContinue.finished
    }
    else
    {
      // skip optional spaces of fence indent
      i := block.fenceIndent
      len := line.size
      while (i > 0 && newIndex < len && line[newIndex] == ' ')
      {
        ++newIndex
        --i
      }
    }
    return BlockContinue.atIndex(newIndex)
  }

  ** spec: the content of the code block consists of all subsequent lines, until
  ** a closing code fence of the same type as the code block began with
  ** (backticks or tildes), and with at least as many backticks or tildes as the
  ** opening code fence.
  private Bool tryClosing(Str line, Int index)
  {
    fences := Chars.skip(fenceChar, line, index, line.size) - index
    if (fences < openingFenceLen) return false
    // spec: the closing code fence [...] may be followed only by spaces, which are ignored
    after := Chars.skipSpaceTab(line, index + fences, line.size)
    if (after == line.size)
    {
      block.closingFenceLen = fences
      return true
    }
    return false
  }

  override Void addLine(SourceLine line)
  {
    if (firstLine == null)
      firstLine = line.content
    else
    {
      otherLines.add(line.content).addChar('\n')
    }
  }

  override Void closeBlock()
  {
    // first line becomes info string
    block.info = firstLine == null ? null : Esc.unescapeStr(firstLine.trim)
    block.literal = otherLines.toStr
  }

  static const BlockParserFactory factory := FencedCodeParserFactory()
}

**************************************************************************
** FencedCodeParserFactory
**************************************************************************

@Js
internal const class FencedCodeParserFactory : BlockParserFactory
{
  override BlockStart? tryStart(ParserState state, MatchedBlockParser parser)
  {
    indent := state.indent
    if (indent >= Parsing.code_block_indent) return BlockStart.none

    nextNonSpace := state.nextNonSpaceIndex
    blockParser := checkOpener(state.line.content, nextNonSpace, indent)
    if (blockParser != null)
    {
      return BlockStart.of([blockParser])
        .atIndex(nextNonSpace + blockParser.block.openingFenceLen)
    }
    return BlockStart.none
  }

  ** spec: a code fence is a sequence of at least three consecutive
  ** backtick characters '`' or tildes '~' (they cannot be mixed).
  private static FencedCodeParser? checkOpener(Str line, Int index, Int indent)
  {
    backticks := 0
    tildes := 0
    len := line.size
    for (i := index; i < len; ++i)
    {
      switch (line[i])
      {
        case '`': ++backticks
        case '~': ++tildes
        default: break
      }
    }
    if (backticks >= 3 && tildes == 0)
    {
      // spec: if the info string comes after a backtick fence, it may not contain any
      // backtick characters
      if (Chars.find('`', line, index + backticks) != -1) return null
      return FencedCodeParser('`', backticks, indent)
    }
    else if (tildes >= 3 && backticks == 0)
    {
      // spec: info strings for tilde code blocks can contain backticks and tildes
      return FencedCodeParser('~', tildes, indent)
    }
    else return null

  }
}