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
** file to extract the examples, but we can't do that because of fantom unicode issues.
** Also, it would require a bit more code to do that and this prcoess is not so bad.
**
abstract class CommonMarkSpecTest : Test
{
  private const File specFile := Env.cur.homeDir + `etc/markdown/tests/spec.json`
  protected [Str:Example[]] bySection := [:] { ordered = true }
  protected Example[] examples() { bySection.vals.flatten }

  ** These all fail because of unicode issues in fantom
  protected virtual Int[] expectedFailures() { [208, 356, 542] }

  protected virtual Example[] examplesToRun() { examples }

  protected abstract ExampleRes run(Example example)

  Void test()
  {
    if (!init) return

    results := ExampleRes[,]
    examplesToRun.each |example| { results.add(run(example)) }

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

  protected Bool init()
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

class HtmlCoreSpecTest : CommonMarkSpecTest
{
  private Parser parser := Parser()

  ** the spec says URL-escaping is optional, but the examples assume it's enabled
  private HtmlRenderer renderer := HtmlRenderer.builder.withPercentEncodeUrls.build

  protected override ExampleRes run(Example example)
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
}

@NoDoc const class ExampleRes
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

@NoDoc const class Example
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
