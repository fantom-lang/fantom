//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

**
** HTML block parser
**
@Js
internal class HtmlBlockParser : BlockParser
{
  internal new make(Regex? closingPattern)
  {
    this.closingPattern = closingPattern
  }

  private const Regex? closingPattern
  private Bool finished := false
  private BlockContent? content := BlockContent()

  override HtmlBlock block := HtmlBlock() { private set }

  override BlockContinue? tryContinue(ParserState state)
  {
    if (finished) return BlockContinue.none

    // blank line ends type 6 and type 7 blocks
    if (state.isBlank && closingPattern == null)
      return BlockContinue.none
    else
      return BlockContinue.atIndex(state.index)
  }

  override Void addLine(SourceLine line)
  {
    content.add(line.content)

    if (closingPattern != null && closingPattern.matcher(line.content).find)
    {
      this.finished = true
    }
  }

  override Void closeBlock()
  {
    block.literal = content.toStr
    this.content = null
  }

  static const BlockParserFactory factory := HtmlBlockParserFactory()
}

**************************************************************************
** HtmlBlockParserFactory
**************************************************************************

@Js
internal const class HtmlBlockParserFactory : BlockParserFactory
{
  private static const Str tagname := "[A-Za-z][A-Za-z0-9-]*"
  private static const Str attribute_name := "[a-zA-Z_:][a-zA-Z0-9:._-]*";
  private static const Str unquoted_val := "[^\"'=<>`\\x00-\\x20]+";
  private static const Str singlequote_val := "'[^']*'";
  private static const Str doublequote_val := "\"[^\"]*\"";
  private static const Str attribute_val
    := "(?:${unquoted_val}|${singlequote_val}|${doublequote_val})"
  private static const Str attribute_val_spec
    := "(?:\\s*=\\s*${attribute_val})"
  private static const Str attribute
    := "(?:\\s+${attribute_name}${attribute_val_spec}?)"

  private static const Str open_tag := "<${tagname}${attribute}*\\s*/?>"
  private static const Str close_tag := "</${tagname}\\s*[>]"

  private static const Regex?[][] block_patterns := Regex?[][
    [null, null], // not used (no type 0)
    [
      Regex("^<(?:script|pre|style|textarea)(?:\\s|>|\$)", "i"),
      Regex("</(?:script|pre|style|textarea)>", "i")
    ],
    [
      Regex("^<!--"),
      Regex("-->")
    ],
    [
      Regex("^<[?]"),
      Regex("\\?>")
    ],
    [
      Regex("^<![A-Z]"),
      Regex(">")
    ],
    [
      Regex("^<!\\[CDATA\\["),
      Regex("\\]\\]>")
    ],
    [
      Regex("^</?(?:" +
        "address|article|aside|" +
        "base|basefont|blockquote|body|" +
        "caption|center|col|colgroup|" +
        "dd|details|dialog|dir|div|dl|dt|" +
        "fieldset|figcaption|figure|footer|form|frame|frameset|" +
        "h1|h2|h3|h4|h5|h6|head|header|hr|html|" +
        "iframe|" +
        "legend|li|link|" +
        "main|menu|menuitem|" +
        "nav|noframes|" +
        "ol|optgroup|option|" +
        "p|param|" +
        "search|section|summary|" +
        "table|tbody|td|tfoot|th|thead|title|tr|track|" +
        "ul" +
        ")(?:\\s|[/]?[>]|\$)", "i"),
      null // terminated by blank line
    ],
    [
      Regex("^(?:${open_tag}|${close_tag})\\s*\$", "i"),
      null, // terminated by blank line
    ]
  ]

  override BlockStart? tryStart(ParserState state, MatchedBlockParser parser)
  {
    nextNonSpace := state.nextNonSpaceIndex
    line := state.line.content

    if (state.indent < Parsing.code_block_indent && line[nextNonSpace] == '<')
    {
      for (blockType := 1; blockType <= 7; ++blockType)
      {
        // type 7 can not interrupt a paragraph (not even a lazy one)
        if (blockType == 7 && (
          parser.matchedBlockParser.block is Paragraph ||
            state.activeBlockParser.canHaveLazyContinuationLines))
        {
          continue
        }
        opener := block_patterns[blockType][0]
        closer := block_patterns[blockType][1]
        matches := opener.matcher(line[nextNonSpace..<line.size]).find
        if (matches)
        {
          return BlockStart.of([HtmlBlockParser(closer)]).atIndex(state.index)
        }
      }
    }
    return BlockStart.none
  }
}

**************************************************************************
** BlockContent
**************************************************************************

@Js
internal class BlockContent
{
  new make() { }

  private StrBuf sb := StrBuf()
  private Int lineCount := 0

  Void add(Str line)
  {
    if (lineCount != 0) sb.addChar('\n')
    sb.add(line)
    ++lineCount
  }

  override Str toStr() { sb.toStr }
}