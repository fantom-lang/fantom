//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 08  Kevin McIntire  Creation
//


**
** BrowserTest
**
internal class BrowserTest
{
  public static Void main(Str[] args)
  {
    bt := BrowserTest.make
    bt.run
  }

  new make()
  {
    file := File.make(`js-test.html`)
    file.create
    this.out = file.out
  }

  Void run()
  {
    init
    doTests
    done
  }

  Void init()
  {
    this.out.printLine("<html>")
    this.out.printLine("<head><title>JSON test for Fan</title>")
    this.out.printLine("<style type=\"text/css\">")
    this.out.printLine("  .Pass { font-weight: bold; color: #00ff00; } .Fail { font-weight: bold; color: #ff0000; }")
    this.out.printLine("  .Test { }")
    this.out.printLine("</style>")
    this.out.printLine("</head><body><ul>")
  }

  Void done()
  {
    this.out.printLine("</ul></body></html>")
    this.out.close
  }

  Void doTests()
  {
    suite := JsonTestSuite.make
    suite.tests.each |JsonTestCase tc|
    {
      this.out.printLine("<li>"+tc.description)
      this.out.printLine("<ul>")
      this.out.printLine("<script>")
      this.out.print("var json = ")
      Json.write(this.out, tc.map)
      this.out.printLine("; var result = eval(json);")
      tc.javascript("result",this.out)
      this.out.printLine("</script>")
      this.out.printLine("</ul>")
      this.out.printLine("</li>")    }
  }

  private OutStream out;
}