//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Oct 2024  Matthew Giannini  Creation
//

@Js
class LinkReferenceDefinitionParserTest : Test
{
  private LinkReferenceDefinitionParser? parser

  override Void setup()
  {
    super.setup
    this.parser = LinkReferenceDefinitionParser()
  }

  Void testStartLabel()
  {
    verifyState("[", LinkRefState.label, "[")
  }

  Void testStartNoLabel()
  {
    // not a label
    verifyPara("a")
    // can not go back to parsing link reference definitions
    parse("a")
    parse("[")
    verifyEq(LinkRefState.paragraph, parser.state)
    verifyParaLines("a\n[", parser)
  }

  Void testEmptyLabel()
  {
    verifyPara("[]: /")
    verifyPara("[ ]: /")
    verifyPara("[ \t\n\u000B\f\r ]: /")
  }

  Void testLabelColon()
  {
    // no space allowed between link label and colon
    verifyPara("[foo] : /")
  }

  Void testLabel()
  {
    verifyState("[foo]:", LinkRefState.destination, "[foo]:")
    verifyState("[ foo ]:", LinkRefState.destination, "[ foo ]:")
  }

  Void testLabelInvalid()
  {
    verifyPara("[foo[]:")
  }

  Void testLabelMultiline()
  {
    parse("[two")
    verifyEq(LinkRefState.label, parser.state)
    parse("lines]:")
    verifyEq(LinkRefState.destination, parser.state)
    parse("/url")
    verifyEq(LinkRefState.start_title, parser.state)
    verifyDef(parser.linkRefDefs.first, "two\nlines", `/url`, null)
  }

  Void testLabelStartsWithNewLine()
  {
    parse("[")
    verifyEq(LinkRefState.label, parser.state)
    parse("weird]:")
    verifyEq(LinkRefState.destination, parser.state)
    parse("/url")
    verifyEq(LinkRefState.start_title, parser.state)
    verifyDef(parser.linkRefDefs.first, "\nweird", `/url`, null)
  }

  Void testDestination()
  {
    parse("[foo]: /url")
    verifyEq(LinkRefState.start_title, parser.state)
    verifyParaLines("", parser)

    verifyEq(1, parser.linkRefDefs.size)
    verifyDef(parser.linkRefDefs.first, "foo", `/url`, null)

    parse("[bar]: </url2>")
    verifyEq(2, parser.linkRefDefs.size)
    verifyDef(parser.linkRefDefs.last, "bar", `/url2`, null)
  }

  Void testDestinationInvalid()
  {
    verifyPara("[foo]: <bar<>")
  }

  Void testTitle()
  {
    parse("[foo]: /url 'title'")
    verifyEq(LinkRefState.start_definition, parser.state)
    verifyParaLines("", parser)

    verifyEq(1, parser.linkRefDefs.size)
    verifyDef(parser.linkRefDefs.first, "foo", `/url`, "title")
  }

  Void testTitleStartWhitespace()
  {
    parse("[foo]: /url")
    verifyEq(LinkRefState.start_title, parser.state)
    verifyParaLines("", parser)

    parse("   ")

    verifyEq(LinkRefState.start_definition, parser.state)
    verifyParaLines("   ", parser)

    verifyEq(1, parser.linkRefDefs.size)
    verifyDef(parser.linkRefDefs.first, "foo", `/url`, null)
  }

  Void testTitleMultiline()
  {
    parse("[foo]: /url 'two")
    verifyEq(LinkRefState.title, parser.state)
    verifyParaLines("[foo]: /url 'two", parser)
    verifyEq(0, parser.linkRefDefs.size)

    parse("lines")
    verifyEq(LinkRefState.title, parser.state)
    verifyParaLines("[foo]: /url 'two\nlines", parser)
    verifyEq(0, parser.linkRefDefs.size)

    parse("'")
    verifyEq(LinkRefState.start_definition, parser.state)
    verifyParaLines("", parser)

    verifyEq(1, parser.linkRefDefs.size)
    verifyDef(parser.linkRefDefs.first, "foo", `/url`, "two\nlines\n")
  }

  Void testTitleMultiline2()
  {
    parse("[foo]: /url '")
    verifyEq(LinkRefState.title, parser.state)
    parse("title'")
    verifyEq(LinkRefState.start_definition, parser.state)

    verifyDef(parser.linkRefDefs.first, "foo", `/url`, "\ntitle")
  }

  Void testTitleMultiline3()
  {
    parse("[foo]: /url")
    verifyEq(LinkRefState.start_title, parser.state)
    // note that this looks like a valid title until we parse "bad", at which point we
    // need to treat the whole line as a paragraph line and discard any already parsed
    // title
    parse(Str<|"title" bad|>)
    verifyEq(LinkRefState.paragraph, parser.state)

    verifyDef(parser.linkRefDefs.first, "foo", `/url`, null)
  }

  Void testTitleMultiline4()
  {
    parse("[foo]: /url")
    verifyEq(LinkRefState.start_title, parser.state)
    parse("(title")
    verifyEq(LinkRefState.title, parser.state)
    parse("foo(")
    verifyEq(LinkRefState.paragraph, parser.state)

    verifyDef(parser.linkRefDefs.first, "foo", `/url`, null)
  }

  Void testTitleInvalid()
  {
    verifyPara("[foo]: /url (invalid(")
    verifyPara("[foo]: </url>'title'")
    verifyPara("[foo]: /url 'title' INVALID")
  }

  private Void parse(Str content)
  {
    parser.parse(SourceLine(content))
  }

  private Void verifyPara(Str input)
  {
    verifyState(input, LinkRefState.paragraph, input)
  }

  private Void verifyState(Str input, LinkRefState state, Str content)
  {
    parser := LinkReferenceDefinitionParser()
    // TODO: should we check things with source spans here?
    parser.parse(SourceLine(input))
    verifyEq(state, parser.state)
    verifyParaLines(content, parser)
  }

  private Void verifyDef(LinkReferenceDefinition def, Str label, Uri dest, Str? title)
  {
    verifyEq(label, def.label)
    verifyEq(dest.toStr, def.destination)
    verifyEq(title, def.title)
  }

  private Void verifyParaLines(Str expectedContent, LinkReferenceDefinitionParser parser)
  {
    actual := parser.paragraphLines.content
    verifyEq(expectedContent, actual)
  }
}