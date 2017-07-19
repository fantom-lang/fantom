
@Js
class MarkdownTest : Test
{
  Void testFandoc() {
    // first lets sanity check the fandoc by doing a round trip parse / write
    fandoc := FandocParser().parseStr(fandocCheatsheet)

    buf := StrBuf()
    fandoc.writeChildren(FandocDocWriter(buf.out))
    // echo(buf.toStr)
    verifyEq(buf.toStr, fandocCheatsheet)
  }

  Void testMarkdown() {
    // now do similar with markdown
    fandoc := FandocParser().parseStr(fandocCheatsheet)

    buf := StrBuf()
    fandoc.writeChildren(MarkdownDocWriter(buf.out))
    // echo(buf.toStr)
    verifyEq(buf.toStr, markdownCheatsheet)
  }

  Str fandocCheatsheet := "Heading 1
                           #########
                           Heading 2
                           *********
                           Heading 3
                           =========
                           Heading 4
                           ---------
                           Heading with anchor tag [#id]
                           -----------------------------
                           This is *italic*

                           This is **bold**

                           This is a 'code' span.

                           This is a code block:

                             Void main() {
                                 echo(Note the leading 4 spaces)
                             }

                           This is a link to [Fantom-Lang]`http://fantom-lang.org/`

                           ![Fanny the Fantom Image]`http://fantom-lang.org/png/fannyEvolved-x128.png`

                           Above the rule

                           ---

                           Below the rule

                           > This is a block quote. - said Fanny

                           - An unordered list
                           - An unordered list
                           - An unordered list

                           Another list:

                           1. An ordered list
                           2. An ordered list
                           3. An ordered list

                           "

  Str markdownCheatsheet := "# Heading 1

                             ## Heading 2

                             ### Heading 3

                             #### Heading 4

                             #### <a name=\"id\"></a>Heading with anchor tag

                             This is *italic*

                             This is **bold**

                             This is a `code` span.

                             This is a code block:

                                 Void main() {
                                     echo(Note the leading 4 spaces)
                                 }

                             This is a link to [Fantom-Lang](http://fantom-lang.org/)

                             ![Fanny the Fantom Image](http://fantom-lang.org/png/fannyEvolved-x128.png)

                             Above the rule

                             ---

                             Below the rule

                             > This is a block quote. - said Fanny


                             * An unordered list
                             * An unordered list
                             * An unordered list


                             Another list:

                             1. An ordered list
                             2. An ordered list
                             3. An ordered list


                             "
}
