//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Oct 2024  Matthew Giannini  Creation
//

**
** Parser for inline content (text, links, emphasized text, etc.)
**
@Js
mixin InlineParser
{
  ** Parse the lines as inline and append resulting nodes to node (as children)
  abstract Void parse(SourceLines lines, Node node)
}

**************************************************************************
** InlineParserContext
**************************************************************************

@Js
class InlineParserContext
{
  internal new make(Parser parser, Definitions defs)
  {
    this.factories = parser.inlineContentParserFactories
    this.customDelimiterProcessors = parser.delimiterProcessors
    this.customLinkProcessors = parser.linkProcessors
    this.customLinkMarkers = parser.linkMarkers
    this.definitions = defs
  }

  const InlineContentParserFactory[] factories
  const DelimiterProcessor[] customDelimiterProcessors
  const LinkProcessor[] customLinkProcessors
  const Int[] customLinkMarkers
  internal Definitions definitions

  ** Lookup a definition of a type for a given label.
  **
  ** Note that the label does not need to be normalized; implementations are
  ** responsible for doing this normalization before lookup.
  Block? def(Type type, Str label) { definitions.def(type, label) }
}

**************************************************************************
** InlineParserState
**************************************************************************

@Js
mixin InlineParserState
{
  ** Return a scanner for the input for the current position (on the trigger
  ** character that the inline parser was added for).
  **
  ** Note that this always returns the same instance, if you want to backtrack you
  ** need to use `Scanner.pos` and `Scanner.setPos`.
  abstract Scanner? scanner()
}

**************************************************************************
** InlineContentParserFactory
**************************************************************************

**
** A factory for extending inline content parsing.
**
@Js
const mixin InlineContentParserFactory
{
  ** An inline content parser needs to have a special "trigger" character which
  ** activates it. When this character is encountered during inline parsing,
  ** `InlineContentParser.tryParse` is called wit hthe current parser state.
  ** It can also register for more than one trigger character
  abstract Int[] triggerChars()

  ** Create an `InlineContentParser` that will do the parsing. Create is called
  ** once per text snippet of inline content inside block structures, and then
  ** called each time a trigger character is encountered.
  abstract InlineContentParser create()
}

**************************************************************************
** InlineContentParser
**************************************************************************

** Parser for a type of inline content. Registered via a `InlineContentParserFactory`
** and created by its `InlineContentParserFactory.create` method. The lifetime of this is
** tied to each inline content snippet that is parsed, as a new instance is created for
** each.
@Js
mixin InlineContentParser
{
  ** Try to parse inline content starting from the current position. Note that the
  ** character at the current position is one of `InlineContentParserFactory.triggerChars`
  ** of the factory that created this parser.
  **
  ** For a given inline content snippet that is being parsed, this method can be called
  ** multiple times: each time a trigger character is encountered.
  **
  ** Return the result of parsing; can indicate that this parser is not interested,
  ** or that parsing was successful.
  abstract ParsedInline? tryParse(InlineParserState inlineParserState)
}

**************************************************************************
** ParsedInline
**************************************************************************

@Js
class ParsedInline
{
  static new none() { null }
  static new of(Node node, Position pos) { ParsedInline.priv_make(node, pos) }
  private new priv_make(Node node, Position pos)
  {
    this.node = node
    this.pos  = pos
  }
  Node node { private set }
  const Position pos
}
