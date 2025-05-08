//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Oct 2024  Matthew Giannini  Creation
//

**
** Block parsing state.
**
@Js
mixin ParserState
{
  ** The current source line being parsed (full line)
  abstract SourceLine? line()

  ** The current index within the line (0-based)
  abstract Int index()

  ** Get the index of the next non-space character starting from `index`
  ** (may be the same) (0-based)
  abstract Int nextNonSpaceIndex()

  ** The colum is the position within the line after tab characters have been
  ** processed as 4-space tab stops. If the line doesn't contain any tabs, it's
  ** the same as the `index`. If the line starts with a tab, followed by text, then
  ** the column for the first character of the text is 4 (the index is 1)
  **
  ** Returns the current column within the line (0-based)
  abstract Int column()

  ** Get the indentation in columns (either by spaces or tab stop of 4), starting
  ** from `column`.
  abstract Int indent()

  ** Return true if the current line is blank starting from the `index`
  abstract Bool isBlank()

  ** Get the deepest open block parser
  abstract BlockParser activeBlockParser()
}

**
** Parses text into a `Document` AST
**
@Js
internal class DocumentParser : ParserState
{
  ** Core block types
  static const Type[] core_block_types := [
    BlockQuote#,
    Heading#,
    FencedCode#,
    HtmlBlock#,
    ThematicBreak#,
    ListBlock#,
    IndentedCode#,
  ]

  static const [Type:BlockParserFactory] core_factories
  static
  {
    acc := [Type:BlockParserFactory][:] { ordered = true }
    acc[BlockQuote#]    = BlockQuoteParser.factory
    acc[Heading#]       = HeadingParser.factory
    acc[FencedCode#]    = FencedCodeParser.factory
    acc[HtmlBlock#]     = HtmlBlockParser.factory
    acc[ThematicBreak#] = ThematicBreakParser.factory
    acc[ListBlock#]     = ListBlockParser.factory
    acc[IndentedCode#]  = IndentedCodeParser.factory
    DocumentParser.core_factories = acc.toImmutable
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Parser parser)
  {
    this.parser = parser
    this.blockParserFactories  = parser.blockParserFactories
    this.includeSourceSpans    = parser.includeSourceSpans

    // initialize the document block parser
    this.documentBlockParser = DocumentBlockParser()
    activateBlockParser(OpenBlockParser(documentBlockParser, 0))
  }

  private DocumentBlockParser documentBlockParser
  private Definitions definitions := Definitions()

//////////////////////////////////////////////////////////////////////////
// Config
//////////////////////////////////////////////////////////////////////////

  const Parser parser
  const BlockParserFactory[] blockParserFactories
  const IncludeSourceSpans includeSourceSpans

  static BlockParserFactory[] calculateBlockParserFactories(BlockParserFactory[] custom, Type[] enabled)
  {
    acc := BlockParserFactory[,]
    // by having the custom factories come first, extensions are able to change behavior
    // of core syntax!
    acc.addAll(custom)
    enabled.each |type| { acc.add(core_factories[type]) }
    return acc
  }

  static Void checkEnabledBlockTypes(Type[] types)
  {
    types.each |type|
    {
      if (core_factories[type] == null)
        throw ArgErr("Can't enable block type ${type}, possible options are ${core_block_types}")
    }
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  override SourceLine? line := null { private set }

  ** Current line index (0-based)
  private Int lineIndex := -1

  override Int index := 0 { private set }

  override Int column := 0 { private set }

  ** Is the current column within a tab character (partially consumed tab)
  private Bool columnIsInTab := false

  override Int nextNonSpaceIndex := 0 { private set } // nextNonSpace

  private Int nextNonSpaceColumn := 0

  override Int indent := 0 { private set }

  override Bool isBlank := false { private set }

  override BlockParser activeBlockParser()
  {
    openBlockParsers.last.blockParser
  }

  ** Block parsers that are currently in the "open" state
  private OpenBlockParser[] openBlockParsers := [,]

  ** All block parsers
  private BlockParser[] allBlockParsers := [,]

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  ** Parse the input into a document AST
  Document parse(InStream in)
  {
    lineReader := LineReader(in)
    inputIndex := 0
    Str? line  := null
    while ((line = lineReader.readLine) != null)
    {
      parseLine(line, inputIndex)
      inputIndex += line.size
      eol := lineReader.lineTerminator
      if (eol != null) inputIndex += eol.size
    }

    return finalizeAndProcess
  }

  ** Inspect the current line and update the document accordingly.
  private Void parseLine(Str ln, Int inputIndex)
  {
    setLine(ln, inputIndex)

    // For each containing block, try to parse the associated line start.
    // The document will always match, so we can skip the first block parser
    // and start at 1 matches
    matches := 1
    for (i := 1; i < openBlockParsers.size; ++i)
    {
      openBlockParser := openBlockParsers[i]
      blockParser := openBlockParser.blockParser
      findNextNonSpace

      blockContinue := blockParser.tryContinue(this)

      // we found the first block parser that could *not*
      // continue parsing from the current state
      if (blockContinue == null) break

      // this open block parser matched
      openBlockParser.sourceIndex = this.index
      if (blockContinue.finalize)
      {
        addSourceSpans
        closeBlockParsers(openBlockParsers.size - i)
        return
      }
      else
      {
        if (blockContinue.newIndex != -1) setNewIndex(blockContinue.newIndex)
        else if (blockContinue.newColumn != -1) setNewColumn(blockContinue.newColumn)
        ++matches
      }
    }

    unmatchedBlocks := openBlockParsers.size - matches
    blockParser     := openBlockParsers[matches-1].blockParser
    startedNewBlock := false

    lastIndex := this.index

    // unless last matched container is a code block, try new container starts,
    // adding children to the last matched container:
    tryBlockStarts := blockParser.block is Paragraph || blockParser.isContainer
    while (tryBlockStarts)
    {
      lastIndex = this.index
      findNextNonSpace

      // this is a little performance optimization
      if (isBlank || (indent < Parsing.code_block_indent && Chars.isLetter(this.line.content, nextNonSpaceIndex)))
      {
        setNewIndex(nextNonSpaceIndex)
        break
      }

      blockStart := findBlockStart(blockParser)
      if (blockStart == null)
      {
        setNewIndex(nextNonSpaceIndex)
        break
      }

      startedNewBlock = true
      sourceIndex := this.index

      // We're starting a new block. If we have any previous blocks that need to
      // be closed, we need to do it now.
      if (unmatchedBlocks > 0)
      {
        closeBlockParsers(unmatchedBlocks)
        unmatchedBlocks = 0
      }

      if (blockStart.newIndex != -1)
        setNewIndex(blockStart.newIndex)
      else if (blockStart.newColumn != -1)
        setNewColumn(blockStart.newColumn)

      SourceSpan[]? replacedSourceSpans := null
      if (blockStart.isReplaceActiveBlockParser)
      {
        replacedBlock := prepareActiveBlockParserForReplacement
        replacedSourceSpans = replacedBlock.sourceSpans
      }

      blockStart.blockParsers.each |newBlockParser|
      {
        addChild(OpenBlockParser(newBlockParser, sourceIndex))
        if (replacedSourceSpans != null)
          newBlockParser.block.setSourceSpans(replacedSourceSpans)
        blockParser = newBlockParser
        tryBlockStarts = newBlockParser.isContainer
      }
    }

    // What remains at the offset is a text line.
    // Add the text to the appropriate block.

    // First check for a lazy continuation line
    if (!startedNewBlock && !isBlank && activeBlockParser.canHaveLazyContinuationLines)
    {
      // lazy paragraph continuation
      openBlockParsers.last.sourceIndex = lastIndex
      addLine
    }
    else
    {
      // finalize any blocks not matched
      if (unmatchedBlocks > 0)
        closeBlockParsers(unmatchedBlocks)

      if (!blockParser.isContainer)
      {
        addLine
      }
      else if (!isBlank)
      {
        // create paragraph container for line
        paragraphParser := ParagraphParser()
        addChild(OpenBlockParser(paragraphParser, lastIndex))
        addLine
      }
      else
      {
        // This can happen for a list item like this:
        // ```
        // *
        // list item
        // ```
        //
        // The first line does not start a paragraph yet, but we still want to
        // record the source position
        addSourceSpans
      }
    }
  }

  ** Update document parser state for a new line of input
  private Void setLine(Str ln, Int inputIndex)
  {
    // move to next line
    this.lineIndex++
    this.index = 0
    this.column = 0
    this.columnIsInTab = false

    // set current source line (with optional source span)
    lineContent := prepareLine(ln)
    SourceSpan? sourceSpan := null
    if (includeSourceSpans != IncludeSourceSpans.none)
      sourceSpan = SourceSpan.of(lineIndex, 0, inputIndex, lineContent.size)
    this.line = SourceLine(lineContent, sourceSpan)
  }

  private Void findNextNonSpace()
  {
    i    := this.index
    cols := this.column
    this.isBlank = true
    len := line.content.size
    while (i < len)
    {
      switch (line.content[i])
      {
        case ' ':
          ++i
          ++cols
          continue
        case '\t':
          // move cols to next tabstop
          ++i
          cols += Parsing.columnsToNextTabStop(cols)
          continue
      }
      this.isBlank = false
      break
    }
    this.nextNonSpaceIndex = i
    this.nextNonSpaceColumn = cols
    this.indent = nextNonSpaceColumn - this.column
  }

  private Void setNewIndex(Int newIndex)
  {
    if (newIndex >= nextNonSpaceIndex)
    {
      // we can start from here, no need to calculate tab stops again
      this.index  = nextNonSpaceIndex
      this.column = nextNonSpaceColumn
    }
    len := line.content.size
    while (index < newIndex && index != len) advance

    // If we're going to an index as opposed to a column, we're never within a tab
    this.columnIsInTab = false
  }

  private Void setNewColumn(Int newColumn)
  {
    if (newColumn >= nextNonSpaceColumn)
    {
      // we can start from here, no need to calcualte tab stops again
      this.index  = this.nextNonSpaceIndex
      this.column = this.nextNonSpaceColumn
    }
    len := line.content.size
    while (column < newColumn && index != len) advance

    if (column > newColumn)
    {
      // last character was a tab and we overshot our target
      --index
      this.column = newColumn
      this.columnIsInTab = true
    }
    else
    {
      this.columnIsInTab = false
    }
  }

  ** Advance to the next character in the line and update
  ** column taking into account tab stops.
  private Void advance()
  {
    c := line.content[index]
    index++
    if (c == '\t')
      column += Parsing.columnsToNextTabStop(column)
    else
      column++
  }

  ** Add line content to the active block parser. We assume it can accept lines --
  ** that check should be done before calling this.
  private Void addLine()
  {
    Str? content := null
    if (columnIsInTab)
    {
      // Our column is in a partially consumed tab. Expand the remaining
      // columns (to the next tab stop) to spaces
      afterTab := index + 1
      rest := line.content[afterTab..-1]
      spaces := Parsing.columnsToNextTabStop(column)
      sb := StrBuf(spaces + rest.size)
      spaces.times { sb.addChar(' ') }
      sb.add(rest)
      content = sb.toStr
    }
    else if (index == 0)
    {
      content = line.content
    }
    else
    {
      content = line.content[index..<line.content.size]
    }

    SourceSpan? sourceSpan := null
    if (includeSourceSpans === IncludeSourceSpans.blocks_and_inlines && index < line.sourceSpan.len)
    {
      // Note that if we're in a partially-consume tab, the length here corresponds to
      // the content but not to the actual source length. That sounds like a problem,
      // but I haven't found a test case where it matters (yet).
      sourceSpan = line.sourceSpan.subSpan(index)
    }

    activeBlockParser.addLine(SourceLine(content, sourceSpan))
    addSourceSpans
  }

  private Void addSourceSpans()
  {
    if (includeSourceSpans === IncludeSourceSpans.none) return

    // Don't add source spans for Document itself (it would get the whole source text),
    // so start at 1, not 0
    openBlockParsers[1..-1].each |openBlockParser|
    {
      // In case of a lazy continuation line, the index is less than where the block
      // parser would expect the contents to start, so let's use whichever is smaller.
      blockIndex := openBlockParser.sourceIndex.min(index)
      len := line.content.size - blockIndex
      if (len != 0)
      {
        openBlockParser.blockParser.addSourceSpan(line.sourceSpan.subSpan(blockIndex))
      }
    }
  }

  private BlockStart? findBlockStart(BlockParser blockParser)
  {
    matchedBlockParser := MatchedBlockParser(blockParser)
    return blockParserFactories.eachWhile |factory|
    {
      factory.tryStart(this, matchedBlockParser)
    }
  }

  ** Walk through a block & children recursively, parsing string content into
  ** inline content where appropriate.
  private Void processInLines()
  {
    cx := InlineParserContext(parser, definitions)
    inlineParser := DefaultInlineParser(cx)
    allBlockParsers.each |blockParser| { blockParser.parseInlines(inlineParser) }
  }

  ** Add block of type tag as a child of the tip. If the tip can't accept children,
  ** close and finalize it and try its parent, and so on until we find a block
  ** that can accept children.
  private Void addChild(OpenBlockParser openBlockParser)
  {
    block := openBlockParser.blockParser.block
    while (!activeBlockParser.canContain(block))
    {
      closeBlockParsers(1)
    }

    activeBlockParser.block.appendChild(block)
    activateBlockParser(openBlockParser)
  }

  private Void activateBlockParser(OpenBlockParser openBlockParser)
  {
    openBlockParsers.add(openBlockParser)
  }

  private OpenBlockParser deactivateBlockParser()
  {
    openBlockParsers.pop
  }

  private Block prepareActiveBlockParserForReplacement()
  {
    // Note that we don't want to parse inlines, as it's getting replaced
    old := deactivateBlockParser.blockParser

    if (old is ParagraphParser)
    {
      // Collect any link reference definitions. Note that replacing the
      // active block parser is done after a block parser got the current
      // paragraph content using MatchedBlockParer.content. In case the
      // paragraph started with link reference definitions, we parse and strip
      // them before the block parser gets the content. We want to keep them.
      // If no replacement happens, we collect the definitions as part of
      // finalizing blocks
      addDefinitionsFrom((ParagraphParser)old)
    }

    // Do this so that source positions are calculated, which we will carry over
    // to the replacing block
    old.closeBlock
    old.block.unlink
    return old.block
  }

  ** Prepares the input line by replacing '\0' characters with 'U+FFFD'.
  ** See § 2.3 - Insecure Characters.
  private static Str prepareLine(Str line)
  {
    if (!line.containsChar('\u0000')) return line
    return line.replace("\u0000", "\uFFFD")
  }

//////////////////////////////////////////////////////////////////////////
// Finalize
//////////////////////////////////////////////////////////////////////////

  private Document finalizeAndProcess()
  {
    closeBlockParsers(openBlockParsers.size)
    processInLines
    return documentBlockParser.block
  }

  private Void closeBlockParsers(Int count)
  {
    count.times |i|
    {
      blockParser := deactivateBlockParser.blockParser
      finalize(blockParser)
      // Remember for inline parsing. Note that a lot of blocks don't need inline
      // parsing. We could have a separate mixin (e.g. BlockParserWithInlines) so that
      // we donly have to remember those that actually have inlines to parse
      allBlockParsers.add(blockParser)
    }
  }

  ** Finalize a block. Close it and do any necessary post-processing; e.g. setting the
  ** content of blocks and collecting link reference definitions from paragraphs.
  private Void finalize(BlockParser blockParser)
  {
    addDefinitionsFrom(blockParser)
    blockParser.closeBlock
  }

  private Void addDefinitionsFrom(BlockParser blockParser)
  {
    blockParser.definitions.each |DefinitionMap defMap|
    {
      definitions.addDefinitions(defMap)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  // @NoDoc Void dumpState()
  // {
  //   s := StrBuf()
  //   s.add("line=${line.content} index=${index} col=${column} nextNonSpaceIndex=${nextNonSpaceIndex} nextNonSpaceColumn=${nextNonSpaceColumn} indent=${indent} isBlank=${isBlank}")
  //   echo(s)
  // }
}

**************************************************************************
** OpenBlockParser
**************************************************************************

@Js
internal class OpenBlockParser
{
  new make(BlockParser blockParser, Int sourceIndex)
  {
    this.blockParser = blockParser
    this.sourceIndex = sourceIndex
  }

  BlockParser blockParser { private set }
  Int sourceIndex
  override Str toStr() { "OpenBlockParser(${blockParser} ${sourceIndex})"}
}

**************************************************************************
** MatchedBlockParser
**************************************************************************

**
** Open block parser that was last matched during the continue phase. This
** is different from the currently active block parser, as an unmatched block
** is only closed when a new block is started.
**
@Js
class MatchedBlockParser
{
  new make(BlockParser matchedBlockParser)
  {
    this.matchedBlockParser = matchedBlockParser
  }

  BlockParser matchedBlockParser { private set }

  SourceLines paragraphLines()
  {
    if (matchedBlockParser is ParagraphParser)
    {
      return ((ParagraphParser)matchedBlockParser).paragraphLines
    }
    return SourceLines.empty
  }
}

**************************************************************************
** Parsing
**************************************************************************

@Js
@NoDoc class Parsing
{
  static const Int code_block_indent := 4

  static Int columnsToNextTabStop(Int column)
  {
    // Tab stop is 4
    4 - (column % 4)
  }
}