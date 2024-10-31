//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Oct 2024  Matthew Giannini  Creation
//

**
** A block parser is able to parse a specific block node.
**
@Js
abstract class BlockParser
{
  ** Return true if the block that is parsed is a container (i.e. contains other blocks),
  ** or false (default) if it's a leaf.
  virtual Bool isContainer() { false }

  ** Return true if the block can have lazy continuation lines.
  **
  ** Lazy continuation lines are lines that were rejected by this `tryContinue` but
  ** didn't match any other block parser either.
  **
  ** If true is returned here, those lines will get added via `addLine`. For false (default),
  ** the block is closed instead.
  virtual Bool canHaveLazyContinuationLines() { false }

  ** Return true if the this block may contain the child block; false otherwise (default)
  virtual Bool canContain(Block childBlock) { false }

  ** Get the parsed block
  abstract Block block()

  ** Attempt to continue parsing the block from the given state
  abstract BlockContinue? tryContinue(ParserState state)

  ** Default implementation does nothing with the source line
  virtual Void addLine(SourceLine line) { }

  ** Add a source span of the currently parsed block. The default implementation
  ** adds it to the block. Unless you have some complicated parsing where you need to
  ** check source positions, you don't need to override this.
  virtual Void addSourceSpan(SourceSpan sourceSpan) { block.addSourceSpan(sourceSpan) }

  ** Return the definitions parsed by this parser. The definitions returned here
  ** can later be accessed during inline parsing.
  virtual DefinitionMap[] definitions() { DefinitionMap#.emptyList }

  ** Do any processing when the block is closed
  virtual Void closeBlock() { }

  ** Callback to parse inline content
  virtual Void parseInlines(InlineParser inlineParser) { }
}

**************************************************************************
** BlockParserFactory
**************************************************************************

**
** Parser factory for a block node for determining when a block starts.
**
@Js
abstract const class BlockParserFactory
{
  abstract BlockStart? tryStart(ParserState state, MatchedBlockParser matchedBlockParser)
}

**************************************************************************
** BlockStart
**************************************************************************

**
** Resulting object for starting parsing of a block. See `BlockParserFactory`.
**
@Js
final class BlockStart
{
  static new none() { null }

  static new of(BlockParser[] blockParsers) { BlockStart.make(blockParsers) }

  private new make(BlockParser[] blockParsers)
  {
    this.blockParsers = blockParsers
  }

  BlockParser[] blockParsers { private set }

  Int newIndex := -1 { private set }

  Int newColumn := -1 { private set }

  Bool isReplaceActiveBlockParser := false { private set }

  This atIndex(Int newIndex) { this.newIndex = newIndex; return this }
  This atColumn(Int newColumn) { this.newColumn = newColumn; return this }
  This replaceActiveBlockParser() { this.isReplaceActiveBlockParser = true; return this }
}

**************************************************************************
** BlockContinue
**************************************************************************

**
** Resulting object for continuing parsing of a block.
**
@Js
const class BlockContinue
{
  static new none() { null }

  static new atIndex(Int newIndex) { BlockContinue(newIndex, -1, false) }

  static new atColumn(Int newColumn) { BlockContinue(-1, newColumn, false) }

  static new finished() { BlockContinue(-1, -1, true) }

  private new priv_make(Int newIndex, Int newColumn, Bool finalize)
  {
    this.newIndex  = newIndex
    this.newColumn = newColumn
    this.finalize  = finalize
  }

  const Int newIndex
  const Int newColumn
  const Bool finalize
}