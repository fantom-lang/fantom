//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Oct 2024  Matthew Giannini  Creation
//

**
** Parse input text into a tree of nodes.
**
** The parser is thread-safe meaning the same parser can be
** shared by multiple actors.
**
@Js
const class Parser
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** Obtain a builder for configuring the parser
  static ParserBuilder builder() { ParserBuilder() }

  ** Get a parser with all the default configuration
  static new make() { builder.build }

  internal new makeBuilder(ParserBuilder builder)
  {
    this.blockParserFactories =
      DocumentParser.calculateBlockParserFactories(
        builder.blockParserFactories,
        builder.enabledBlockTypes)
    this.inlineContentParserFactories = builder.inlineContentParserFactories
    this.includeSourceSpans = builder.includeSourceSpans
    this.delimiterProcessors = builder.delimiterProcessors
    this.linkProcessors = builder.linkProcessors
    this.linkMarkers = builder.linkMarkers

    // install post-processors. We auto-inject a HeadingProcessor so that
    // anchor ids are always generated.
    this.postProcessorFactories =
      [|->HeadingProcessor| { HeadingProcessor() }]
        .addAll(builder.postProcessorFactories)

    // try to make an inline parser. invalid configuration might result in
    // an error, which we want to detect as soon as possible
    cx := InlineParserContext(this, Definitions())
    inline := DefaultInlineParser(cx)
  }

  internal const BlockParserFactory[] blockParserFactories
  internal const InlineContentParserFactory[] inlineContentParserFactories
  internal const IncludeSourceSpans includeSourceSpans
  internal const DelimiterProcessor[] delimiterProcessors
  internal const LinkProcessor[] linkProcessors
  internal const Int[] linkMarkers
  internal const |->PostProcessor|[] postProcessorFactories

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  ** Convenience to parse a file into a `Document`. If source span parsing
  ** is enabled the nodes will have access to the file location using `Node.loc`.
  Document parseFile(File file) { parseStream(file.in).withFile(file) }

  ** Convenience for 'parseStream(text.in)'
  Document parse(Str text) { parseStream(text.in) }

  ** Parse the contents of the input stream into a tree of nodes.
  **
  ** pre>
  ** doc := Parser().parse("Hello *Markdown*!")
  ** <pre
  **
  Document parseStream(InStream in)
  {
    docParser := createDocumentParser
    doc :=  docParser.parse(in)
    return postProcess(doc)
  }

  private DocumentParser createDocumentParser()
  {
    DocumentParser(this)
  }

  private Document postProcess(Node doc)
  {
    postProcessorFactories.each |factory| { doc = factory().process(doc) }
    return doc
  }
}

**************************************************************************
** ParserBuilder
**************************************************************************

**
** Builder for customizing the behavior of the common mark parser
**
@Js
final class ParserBuilder
{
  internal new make() { }

  ** Get the configured `Parser`
  Parser build() { Parser(this) }

  internal IncludeSourceSpans includeSourceSpans := IncludeSourceSpans.none
  internal BlockParserFactory[] blockParserFactories := [,]
  internal InlineContentParserFactory[] inlineContentParserFactories := [,]
  internal Type[] enabledBlockTypes := DocumentParser.core_block_types
  internal DelimiterProcessor[] delimiterProcessors := [,]
  internal LinkProcessor[] linkProcessors := [,]
  internal Int[] linkMarkers := [,]
  internal |->PostProcessor|[] postProcessorFactories := [,]

  ** Describe the list of markdown features the parser will recognize and parse.
  **
  ** By default, we will recognize and parse the following set of "block" elements:
  **
  ** - `Heading` ('#')
  ** - `HtmlBlock` ('<html></html>')
  ** - `ThematicBreak` (Horizontal Rule) ('---')
  ** - `FencedCode` ('```')
  ** - `IndentedCode`
  ** - `BlockQuote` ('>')
  ** - `ListBlock` (Ordered/Unordered List) ('1. / *')
  **
  ** To parse only a subset of the features listed above, pass a lsit of each feature's
  ** associated `Block` type.
  **
  ** Example: to parse only headings and lists:
  **
  **   Parser.builder.withEnabledBlockTypes([Heading#, ListBlock#])
  **
  This withEnabledBlockTypes(Type[] enabledBlockTypes)
  {
    DocumentParser.checkEnabledBlockTypes(enabledBlockTypes)
    this.enabledBlockTypes = enabledBlockTypes
    return this
  }

  ** Add a custom block parser factory.
  **
  ** Note that custom factories are applied *before* the built-in factories. This is
  ** so that extensions can change how some syntax is parsed that would otherwise be
  ** handled by built-in factories.
  This customBlockParserFactory(BlockParserFactory factory)
  {
    blockParserFactories.add(factory)
    return this
  }

  ** Add a factory for a custom inline content parser, for extending inline parsing
  ** or overriding built-in parsing.
  **
  ** Note that parsers are triggered based on a special character as specified by
  ** `InlineContentParserFactory.triggerChars`. It is possible to register multiple
  ** parsers for the same character, or even for some built-in special character
  ** such as '`'. The custom parsers are tried first in the order in which they are
  ** registered, and then the built-in ones.
  This customInlineContentParserFactory(InlineContentParserFactory factory)
  {
    inlineContentParserFactories.add(factory)
    return this
  }

  This postProcessorFactory(|->PostProcessor| factory)
  {
    postProcessorFactories.add(factory)
    return this
  }

  ** TODO: this feature not fully implemented yet
  @NoDoc This withIncludeSourceSpans(IncludeSourceSpans val)
  {
    this.includeSourceSpans = val
    return this
  }

  This customDelimiterProcessor(DelimiterProcessor delimiterProcessor)
  {
    delimiterProcessors.add(delimiterProcessor)
    return this
  }

  ** Add a custom link/image processor for inline parsing.
  **
  ** Multiple link processors can be added, and will be tried in the order in which they
  ** were added. If no processor applies, the normal behavior applies. That means these
  ** can override built-in link parsing.
  This linkProcessor(LinkProcessor linkProcessor)
  {
    linkProcessors.add(linkProcessor)
    return this
  }

  ** Add a custom link marker for link processing. A link marker is a character like
  ** '!' which, if it appears before the '[' of a link, changes the meaning of the link.
  **
  ** If a link marker followed by a valid link is parsed, the `LinkInfo` that is passed
  ** to the `LinkProcessor` will have its `LinkInfo.marker` set. A link processor
  ** should check the `Text.literal` and then do any processing, and will probably
  ** want to use `LinkResult.includeMarker`.
  This linkMarker(Int marker)
  {
    linkMarkers = linkMarkers.add(marker).unique
    return this
  }

  ** Configure the given extensions on this parser.
  This extensions(MarkdownExt[] exts)
  {
    exts.each |ext| { ext.extendParser(this) }
    return this
  }
}