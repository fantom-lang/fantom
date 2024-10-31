//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 2024  Matthew Giannini  Creation
//

@Js
class ListTightLooseTest : CoreRenderingTest
{
  Void testTight()
  {
    verifyRendering(
      """- foo
         - bar
         + baz
         """,
      """<ul>
         <li>foo</li>
         <li>bar</li>
         </ul>
         <ul>
         <li>baz</li>
         </ul>
         """)
  }

  Void testLoose()
  {
    verifyRendering(
      """- foo

         - bar


         - baz\n""",
      """<ul>
         <li>
         <p>foo</p>
         </li>
         <li>
         <p>bar</p>
         </li>
         <li>
         <p>baz</p>
         </li>
         </ul>\n""")
  }

  Void testLooseNested()
  {
    verifyRendering(
      """- foo
           - bar

             baz""",
      """<ul>
         <li>foo
         <ul>
         <li>
         <p>bar</p>
         <p>baz</p>
         </li>
         </ul>
         </li>
         </ul>\n""")
  }

  Void testLooseNested2()
  {
    verifyRendering(
      """- a
           - b

             c
         - d\n""",
      """<ul>
         <li>a
         <ul>
         <li>
         <p>b</p>
         <p>c</p>
         </li>
         </ul>
         </li>
         <li>d</li>
         </ul>\n""")
  }

  Void testOuter()
  {
    verifyRendering(
      """- foo
           - bar


           baz""",
      """<ul>
         <li>
         <p>foo</p>
         <ul>
         <li>bar</li>
         </ul>
         <p>baz</p>
         </li>
         </ul>\n""")
  }

  Void testLooseListItem()
  {
    verifyRendering(
      """- one

           two\n""",
      """<ul>
         <li>
         <p>one</p>
         <p>two</p>
         </li>
         </ul>\n""")
  }

  Void testTightWithBlankLineAfter()
  {
    verifyRendering(
      """- foo
         - bar
         \n""",
      """<ul>
         <li>foo</li>
         <li>bar</li>
         </ul>\n""")
  }

  Void testTightListWithCodeBlock()
  {
    verifyRendering(
      """- a
         - ```
           b


           ```
         - c\n""",
      """<ul>
         <li>a</li>
         <li>
         <pre><code>b


         </code></pre>
         </li>
         <li>c</li>
         </ul>\n""")
  }

  Void testTightListWithCodeBlock2()
  {
    verifyRendering(
      """* foo
           ```
           bar

           ```
           baz\n""",
      """<ul>
         <li>foo
         <pre><code>bar

         </code></pre>
         baz</li>
         </ul>\n""")
  }

  Void testLooseEmptyListItem()
  {
    verifyRendering(
      """* a
         *

         * c""",
      """<ul>
         <li>
         <p>a</p>
         </li>
         <li></li>
         <li>
         <p>c</p>
         </li>
         </ul>\n""")
  }

  Void testLooseBlankLineAfterCodeBlock()
  {
    verifyRendering(
      """1. ```
            foo
            ```

            bar""",
      """<ol>
         <li>
         <pre><code>foo
         </code></pre>
         <p>bar</p>
         </li>
         </ol>\n""")
  }
}