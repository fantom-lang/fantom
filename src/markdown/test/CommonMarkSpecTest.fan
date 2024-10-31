//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Oct 2024  Matthew Giannini  Creation
//

**
** Runs all the tests from the common mark specification
**
** The spec.json was generated from the [commonmark-spec]`https://github.com/commonmark/commonmark-spec`
** repo using this command:
** pre>
** python test/spec_tests.py --dump-tests > spec.json
** <pre
**
** The commonmark-java implementation actually does a simple parsing of the spec.md
** file to extrac the examples, but we can't do that because of fantom unicode issues.
** Also, it would require a bit more code to do that and this prcoess is not so bad.
**
class CommonMarkSpecTest : Test
{
  private File specFile := Env.cur.homeDir + `etc/markdown/tests/spec.json`
  private [Str:Example[]] bySection := [:] { ordered = true }
  private Example[] examples() { bySection.vals.flatten }

  private Parser parser := Parser()

  ** the spec says URL-escaping is optional, but the examples assume it's enabled
  private HtmlRenderer renderer := HtmlRenderer.builder.withPercentEncodeUrls.build

  private const Int[] expectedFailures := [
    208, // unicode issues with fantom
    356, // unicode issues with fantom
    542, // unicode issues with fantom
  ]

  Void test()
  {
    if (!init) return

    results := ExampleRes[,]
    // todo := [examples[617]]
    examples.each |example| { results.add(run(example)) }

    failedCount := 0
    results.each |result|
    {
      if (result.failed)
      {
        ex := result.example

        // ignore expected failures
        if (expectedFailures.contains(ex.id)) return

        ++failedCount
        echo("""${ex.section}: ${ex.id}
                === Markdown
                ${ex.markdown}
                === Expected
                ${ex.html}
                === Actual
                ${result.rendered}
                ===
                ${result.err.traceToStr}""")
      }
    }
    echo("${results.size-failedCount}/${results.size} tests passed.")
    if (failedCount > 0) fail("CommonMark spec tests did not pass.")
  }

  private ExampleRes run(Example example)
  {
    Str? r
    try
    {
      doc := parser.parse(example.markdown)
      // Node.tree(doc)
      r = renderer.render(doc)
      verifyEq(example.html, r)
      return ExampleRes(example)
    }
    catch (Err err)
    {
      return ExampleRes(example, err, r)
    }
  }

  private Bool init()
  {
    if (!specFile.exists)
    {
      echo(Str<|
                ************ WARNING ***********

                Common Mark spec.json not found.
                Skipping tests.

                ********************************
                |>)
      return false
    }

    // use reflection to load test examples
    in := specFile.in
    try
    {
      Map[] arr := Type.find("util::JsonInStream").make([specFile.in])->readJson
      arr.each |json|
      {
        example := Example(json)
        bySection.getOrAdd(example.section) |Str section->Example[]| { Example[,] }.add(example)
      }
    }
    finally in.close
    return true
  }
}

internal const class ExampleRes
{
  new makeOk(Example example) : this.make(example, null, null) { }
  new make(Example example, Err? err, Str? rendered)
  {
    this.example = example
    this.err = err
    this.rendered = rendered
  }

  const Example example
  const Err? err
  const Str? rendered
  Bool failed() { err != null }
}

internal const class Example
{
  new make(Map json)
  {
    this.json = json
  }

  const Map json
  Str markdown() { json["markdown"] }
  Str html() { json["html"] }
  Int id() { json["example"] }
  Str section() { json["section"] }

  override Str toStr() { "$id" }
}
