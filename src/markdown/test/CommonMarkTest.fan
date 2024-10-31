//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Oct 2024  Matthew Giannini  Creation
//

@Js
@NoDoc abstract class MarkdownTest : Test
{
}

@Js
@NoDoc abstract class RenderingTest : MarkdownTest
{
  protected abstract Str render(Str source)

  protected Void verifyRendering(Str source, Str expected)
  {
    doVerifyRendering(source, expected, render(source))
  }

  private Void doVerifyRendering(Str source, Str expected, Str actual)
  {
    // include source for better assertion errors
    /*
    expected = showTabs("${expected}\n\n${source}")
    actual = showTabs("${actual}\n\n${source}")
    */
    // echo("$expected")
    // echo("==")
    // echo("${actual}")
    verifyEq(expected, actual)
  }

  private static Str showTabs(Str s)
  {
    // TODO:FIXIT - sadly, Fantom can't displya this in the console :-(
    // tabs are shown as "rightward arrow" for easier comaparsion
    // s.replace("\t", "\u2192")
    return s
  }
}

@Js
@NoDoc class CoreRenderingTest : RenderingTest
{
  private Parser? parser
  private HtmlRenderer? renderer

  override Void setup()
  {
    super.setup
    this.parser = Parser()
    this.renderer = HtmlRenderer()
  }

  override protected Str render(Str source)
  {
    // doc := parser.parse(source)
    // echo(Node.children(doc))
    // echo(Node.children(doc.firstChild))
    return renderer.render(parser.parse(source))
  }
}