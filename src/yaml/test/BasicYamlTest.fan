#! /usr/bin/env fan
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 2022  Kiera O'Flynn   Creation
//

using util

**
** A set of non-exhaustive tests to ensure basic functionality.
**
class BasicYamlTest : Test
{
  ** Tests flow-plain text and folding
  Void testPlain()
  {
    obj := YamlReader("Stick mice in my head".in).parse
    verifyEq(obj.decode, [,].add("Stick mice in my head"))

    obj = YamlReader("""---
                         And let them
                           back

                          out

                         """.in).parse
    verifyEq(obj.decode, [,].add("And let them back\nout"))
    verifyLoc(obj.val[0], 2, 2)

    obj = YamlReader("""---
                         And let them
                           back

                          out # Comment
                        #Comment 2
                         """.in).parse
    verifyEq(obj.decode, [,].add("And let them back\nout"))

    verifyErr (FileLocErr#) { YamlReader("---\nLine one # With a comment\nLine two".in) .parse }
  }

  ** Tests directives and completely empty documents
  Void testDirectives()
  {
    // Good tests
    obj := YamlReader("""%YAML 1.2
                         %TAG ! tag:fantom.org,2022:test/       # Try all three types of
                         %TAG !! tag:fantom.org,2022:test/      # tag handles
                         %TAG !test! tag:fantom.org,2022:test/
                         --- !!1

                         # Completely empty node
                         """.in).parse
    verifyEq(obj.val[0].tag, "tag:fantom.org,2022:test/1")
    verifyLoc(obj.val[0], 5, 5)
    verifyEq(obj.decode, [null])

    obj = YamlReader("""\uFFFE# No directives
                        --- !!1

                        # More complete emptiness
                        ...
                        # ..and even more!
                        ...""".in).parse
    verifyEq(obj.val[0].tag, "tag:yaml.org,2002:1")
    verifyLoc(obj.val[0], 2, 5)
    verifyEq(obj.decode, [null])

    obj = YamlReader("""%TAG !! tag:fantom.org,2022:test1/    # Multi-document
                        --- !!1
                        ...
                        %TAG !! tag:fantom.org,2022:test2/
                        --- !!1
                        """.in).parse
    verifyEq(obj.val[0].tag, "tag:fantom.org,2022:test1/1")
    verifyEq(obj.val[1].tag, "tag:fantom.org,2022:test2/1")
    verifyLoc(obj.val[0], 2, 5)
    verifyLoc(obj.val[1], 5, 5)
    verifyEq(obj.decode, [null, null])

    // Error tests
    verifyErr(FileLocErr#)
    {
      YamlReader("""%YAML 1.2.2    # invalid version format
                    ---
                    """.in).parse
    }
    verifyErr(FileLocErr#)
    {
      YamlReader("""%TAG ! tag:fantom.org,2022:test
                    %TAG ! tag:fantom.org,2022:test   # tags cannot be redefined
                    ---""".in).parse
    }
    verifyErr(FileLocErr#)
    {
      YamlReader("""%TAG ! tag:fantom.org,2022:test
                    This text isn't a comment or directive!
                    ---""".in).parse
    }
    verifyErr(FileLocErr#)
    {
      YamlReader("""%YAML 1.2""".in).parse
    }
  }

  ** Tests --- and ... with non-empty documents
  Void testDocSeparators()
  {
    obj := YamlReader("Test1
                       ---
                       Test2".in).parse
    verifyLoc(obj.val[0], 1, 1)
    verifyLoc(obj.val[1], 3, 1)

    verifyEq(
      obj.decode,
      [,].add("Test1")
         .add("Test2"))

    obj = YamlReader("Test1
                      ...
                      Test2".in).parse
    verifyLoc(obj.val[0], 1, 1)
    verifyLoc(obj.val[1], 3, 1)

    verifyEq(
      obj.decode,
      [,].add("Test1")
         .add("Test2"))

    verifyEq(
      YamlReader("|
                  Test1
                  ...
                  >-
                  Test2

                  ...".in).parse.decode,
      [,].add("Test1\n")
         .add("Test2"))
  }

  ** Tests single-quoted strings
  Void testSingleQuoted()
  {
    verifyEq(
      YamlReader("'This is a test'".in).parse.decode,
      [,].add("This is a test"))
    verifyEq(
      YamlReader("'Test 2'\n".in).parse.decode,
      [,].add("Test 2"))
    verifyEq(
      YamlReader("'It''s in the other room'".in).parse.decode,
      [,].add("It's in the other room"))
    verifyErr (FileLocErr#) { YamlReader("'This contains' 'two separate strings'".in).parse }

    verifyEq(
      YamlReader("'This is a   \n   multiline\n test #slay #not a comment\n\n\n hehe' #real comment\n  ".in).parse.decode,
      [,].add("This is a multiline test #slay #not a comment\n\nhehe"))
    verifyEq(
      YamlReader("   'Leading\n spaces'".in).parse.decode,
      [,].add("Leading spaces"))
  }

  ** Tests double-quoted strings
  Void testDoubleQuoted()
  {
    verifyEq(
      YamlReader("\"This is a test\"".in).parse.decode,
      [,].add("This is a test"))
    verifyEq(
      YamlReader("\"Test 2\"\n".in).parse.decode,
      [,].add("Test 2"))

    verifyEq(
      YamlReader(Str <|"Fun with \\"
                       ...
                       "\" \a \b \e \f"
                       ...
                       "\n \r \t \v \0"
                       ...
                       "\  \_ \N \L \P \
                       \x41 \u0041 \U00000041"
                       |>.in).parse.decode,
      [,].add("Fun with \\")
         .add("\" \u0007 \b \u001b \f")
         .add("\n \r \t \u000b \u0000")
         .add("\u0020 \u00a0 \u0085 \u2028 \u2029 A A A"))

    verifyEq(
      YamlReader("\"This is a   \n   multiline\n test #slay #not a comment\n\n\n hehe\" #real comment\n  ".in).parse.decode,
      [,].add("This is a multiline test #slay #not a comment\n\nhehe"))
    verifyEq(
      YamlReader("   \"Leading\n spaces\"".in).parse.decode,
      [,].add("Leading spaces"))
  }

  ** Tests literal block scalars
  Void testLiteral()
  {
    // Indentation
    verifyEq(
      YamlReader("|1\nThis is a test".in).parse.decode,
      [,].add("This is a test\n"))
    verifyEq(
      YamlReader("|\nThis is a test".in).parse.decode,
      [,].add("This is a test\n"))
    verifyEq(
      YamlReader("|\nThis is a test\n".in).parse.decode,
      [,].add("This is a test\n"))
    verifyEq(
      YamlReader("|2\n  This is a test\n".in).parse.decode,
      [,].add(" This is a test\n"))
    verifyEq(
      YamlReader("|\n  This is a test\n".in).parse.decode,
      [,].add("This is a test\n"))
    verifyErr(FileLocErr#)
    {
      YamlReader("|3\n This is a test\n".in).parse
    }

    // Leading lines
    verifyEq(
      YamlReader("|\n  \n   \n \n\n   Test\n".in).parse.decode,
      [,].add("\n\n\n\nTest\n"))
    verifyEq(
      YamlReader("|\n  \n   \n \n\n     Test\n".in).parse.decode,
      [,].add("\n\n\n\nTest\n"))
    verifyEq(
      YamlReader("|\n\n   \n \n\n   Test\n".in).parse.decode,
      [,].add("\n\n\n\nTest\n"))
    verifyErr(FileLocErr#)
    {
      YamlReader("|\n  \n   \n \n\n  Test\n".in).parse
    }

    // Multiple lines
    verifyEq(
      YamlReader("|\nTest \n    Test2".in).parse.decode,
      [,].add("Test \n    Test2\n"))
    verifyEq(
      YamlReader("|\n Test \n     Test2".in).parse.decode,
      [,].add("Test \n    Test2\n"))
    verifyEq(
      YamlReader("|+\na\n\n\n\n".in).parse.decode,
      [,].add("a\n\n\n\n"))
    verifyEq(
      YamlReader("|-\na\n\n\n\n".in).parse.decode,
      [,].add("a"))
    verifyEq(
      YamlReader("|\na\n\n\n\n".in).parse.decode,
      [,].add("a\n"))
    verifyEq(
      YamlReader(">\nTest1\n \nTest2".in).parse.decode,
      [,].add("Test1\n \nTest2\n"))
    verifyErr(FileLocErr#)
    {
      YamlReader("|\n  Test \n Test2".in).parse
    }
    verifyErr(FileLocErr#)
    {
      YamlReader("|\n  Test \n \t  Test2".in).parse
    }

    // Chomping
    verifyEq(
      YamlReader(Str <|# Strip
                         # Comments:
                       --- |-   # here too
                         # text

                        # Clip
                         # comments:

                       --- |
                         # text

                        # Keep
                         # comments:

                       --- |+
                         # text

                        # Trail
                         # comments.|>.in).parse.decode,
      [,].add("# text")
         .add("# text\n")
         .add("# text\n\n"))

    verifyEq(
      YamlReader(Str <|--- |-

                       --- |

                       --- |+

                       |>.in).parse.decode,
      [,].add("")
         .add("")
         .add("\n"))
  }

  ** Tests folded block scalars
  Void testFolded()
  {
    // Indentation
    verifyEq(
      YamlReader(">1\nThis is a test".in).parse.decode,
      [,].add("This is a test\n"))
    verifyEq(
      YamlReader(">\nThis is a test".in).parse.decode,
      [,].add("This is a test\n"))
    verifyEq(
      YamlReader(">\nThis is a test\n".in).parse.decode,
      [,].add("This is a test\n"))
    verifyEq(
      YamlReader(">2\n  This is a test\n".in).parse.decode,
      [,].add(" This is a test\n"))
    verifyEq(
      YamlReader(">\n  This is a test\n".in).parse.decode,
      [,].add("This is a test\n"))
    verifyErr(FileLocErr#)
    {
      YamlReader(">3\n This is a test\n".in).parse
    }

    // Leading lines
    verifyEq(
      YamlReader(">\n  \n   \n \n\n   Test\n".in).parse.decode,
      [,].add("\n\n\n\nTest\n"))
    verifyEq(
      YamlReader(">\n  \n   \n \n\n     Test\n".in).parse.decode,
      [,].add("\n\n\n\nTest\n"))
    verifyEq(
      YamlReader(">\n\n   \n \n\n   Test\n".in).parse.decode,
      [,].add("\n\n\n\nTest\n"))
    verifyErr(FileLocErr#)
    {
      YamlReader(">\n  \n   \n \n\n  Test\n".in).parse
    }

    // Multiple lines
    verifyEq(
      YamlReader(">\nTest \n    Test2".in).parse.decode,
      [,].add("Test \n    Test2\n"))
    verifyEq(
      YamlReader(">\n Test \n     Test2".in).parse.decode,
      [,].add("Test \n    Test2\n"))
    verifyEq(
      YamlReader(">\n Test \n Test2".in).parse.decode,
      [,].add("Test  Test2\n"))
    verifyEq(
      YamlReader(">\n Test \n \tTest2".in).parse.decode,
      [,].add("Test \n\tTest2\n"))
    verifyEq(
      YamlReader(">+\na\n\n\n\n".in).parse.decode,
      [,].add("a\n\n\n\n"))
    verifyEq(
      YamlReader(">-\na\n\n\n\n".in).parse.decode,
      [,].add("a"))
    verifyEq(
      YamlReader(">\na\n\n\n\n".in).parse.decode,
      [,].add("a\n"))
    verifyEq(
      YamlReader(">\nTest1\n \nTest2".in).parse.decode,
      [,].add("Test1\n \nTest2\n"))
    verifyEq(
      YamlReader(">-\n  trimmed\n  \n \n\n  as\n  space".in).parse.decode,
      [,].add("trimmed\n\n\nas space"))

    verifyErr(FileLocErr#)
    {
      YamlReader(">\n  Test \n Test2".in).parse
    }
    verifyErr(FileLocErr#)
    {
      YamlReader(">\n  Test \n \t  Test2".in).parse
    }

    // Chomping
    verifyEq(
      YamlReader(Str <|>

                        folded
                        line

                        next
                        line
                          * bullet

                          * list
                          * lines

                        last
                        line

                       # Comment|>.in).parse.decode,
      [,].add("\nfolded line\nnext line\n  * bullet\n\n  * list\n  * lines\n\nlast line\n"))

    verifyEq(
      YamlReader(Str <|--- >-

                       --- >

                       --- >+

                       |>.in).parse.decode,
      [,].add("")
         .add("")
         .add("\n"))
  }

  ** Tests flow sequences
  Void testFlowSeq()
  {
    verifyEq(
      YamlReader("[a,b,c]".in).parse.decode,
      [,].add(
        [,].addAll(["a","b","c"])))
    verifyEq(
      YamlReader("[a,b,[c,d]]".in).parse.decode,
      [,].add(
        [,].addAll(["a","b",
          [,].addAll(["c","d"])])))
    verifyEq(
      YamlReader("[a,b,c: d]".in).parse.decode,
      [,].add(
        [,].addAll(["a","b",
          [:].addAll(["c":"d"])])))
    verifyEq(
      YamlReader("[   'a'  ,  \"b\"    ,c, ]".in).parse.decode,
      [,].add(
        [,].addAll(["a","b","c"])))
    verifyEq(
      YamlReader("[this is fine,!!str,]".in).parse.decode,
      [,].add(
        [,].addAll(["this is fine",""])))
    verifyEq(
      YamlReader("[]".in).parse.decode,
      [,].add([,]))

    obj :=  YamlReader("[
                        \t\t! Two plastic
                              bags
                            drifting, o'er\t
                        the beach
                        ]".in).parse
    verifyEq(obj.decode,
      [,].add(
        [,].addAll(["Two plastic bags drifting", "o'er the beach"])))
    verifyLoc(obj.val[0], 1, 1)
    verifyLoc(obj.val[0].val->get(0), 2, 3)
    verifyLoc(obj.val[0].val->get(1), 4, 15)

    verifyErr(FileLocErr#)
    {
      YamlReader("[
                    |
                    This isn't a block node
                  ]".in).parse
    }

    verifyErr(FileLocErr#)
    {
      YamlReader("[too many,,]".in).parse
    }
  }

  ** Tests flow mappings
  Void testFlowMap()
  {
    verifyEq(
      YamlReader("{a: 1, b: 2, c: 3}".in).parse.decode,
      [,].add(
        [:].addAll(["a":1, "b":2, "c":3])))
    verifyEq(
      YamlReader("{a: 1,b: 2,{c: 1,d}:3}".in).parse.decode,
      [,].add(
        [:].addAll(["a":1,"b":2,
          [:].addAll(["c":1,"d":null]).toImmutable: 3])))
    verifyEq(
      YamlReader("{   'a' :1 , !  \"b\"    :2,c:   3, }".in).parse.decode,
      [,].add(
        [:].addAll(["a":1, "b":2, "c":3])))
    verifyEq(
      YamlReader("{this is fine,!!str,}".in).parse.decode,
      [,].add(
        [:].add("this is fine", null)
           .add("", null)))
    verifyEq(
      YamlReader("{}".in).parse.decode,
      [,].add([:]))
    verifyEq(
      YamlReader("{?
                  }".in).parse.decode(YamlSchema.failsafe),
      [,].add([:].add("", "")))

    verifyEq(
      YamlReader("{
                  \t\t! Two plastic
                        bags
                      drifting, o'er\t
                  the beach
                  }".in).parse.decode,
      [,].add(
        [:].addAll(["Two plastic bags drifting":null, "o'er the beach":null])))

    verifyErr(FileLocErr#)
    {
      YamlReader("{
                    ? |
                      This isn't a block node
                    : grr
                  }".in).parse
    }

    verifyErr(FileLocErr#)
    {
      YamlReader("{too many,,}".in).parse
    }
  }

  ** Tests anchors/aliases & self-nested nodes
  Void testAnchors()
  {
    // Anchors can be reassigned
    obj :=
      YamlReader("[
                    &A this is a test,
                    *A,
                    &A this is another test,
                    *A
                  ]".in).parse
    verifyEq(
      obj.decode,
      [,].add(
        [,].add("this is a test")
           .add("this is a test")
           .add("this is another test")
           .add("this is another test")))
    verifyLoc(obj.val[0].val->get(0), 2, 3)
    verifyLoc(obj.val[0].val->get(1), 3, 3)
    verifyLoc(obj.val[0].val->get(2), 4, 3)
    verifyLoc(obj.val[0].val->get(3), 5, 3)

    // But don't carry over between documents
    verifyErr(FileLocErr#)
    {
      YamlReader("---
                  &A test
                  ---
                  *A
                  ".in).parse
    }
  }

  ** Tests block sequences
  Void testBlockSeq()
  {
    verifyEq(
      YamlReader("-
                    First item
                  - !tagged [flow, node]


                  - # Empty".in).parse.decode,
      [,].add(
        [,].add("First item")
           .add([,].addAll(["flow", "node"]))
           .add(null))
      )

    obj :=
      YamlReader("  -   - Compact

                        - node
                    - yea

                  ".in).parse
    verifyEq(
      obj.decode,
      [,].add(
        [,].add([,].addAll(["Compact", "node"]))
           .add("yea"))
      )
    verifyLoc(obj.val[0], 1, 3)
    verifyLoc(obj.val[0].val->get(0), 1, 7)
    verifyLoc(obj.val[0].val->get(0)->content->get(0), 1, 9)
    verifyLoc(obj.val[0].val->get(0)->content->get(1), 3, 9)
    verifyLoc(obj.val[0].val->get(1), 4, 5)

    verifyEq(
      YamlReader("- First item
                   - same item".in).parse.decode,
      [,].add(
        [,].add("First item - same item"))
      )

    verifyErr (FileLocErr#)
    {
      YamlReader("  - Non-compact
                   - uneven node
                  ".in).parse
    }

    verifyErr (FileLocErr#)
    {
      YamlReader("- good
                  -bad
                  ".in).parse
    }

    verifyErr (FileLocErr#)
    {
      YamlReader("- good
                  - still good

                  bad now
                  ".in).parse
    }
  }

  ** Tests block maps
  Void testBlockMap()
  {
    verifyEq(
      YamlReader("   hr : 65    # Home runs
                     avg: 0.278 # Batting average
                     rbi: 147   # Runs Batted In".in).parse.decode,
      [,].add(
        [:].add("hr", 65)
           .add("avg", 0.278f)
           .add("rbi", 147))
      )

    verifyEq(
      YamlReader("indentation:
                  - works".in).parse.decode,
      [,].add(
        [:].add("indentation", [,].add("works")))
      )

    verifyEq(
      YamlReader("-
                   map: node
                   with:    multiple
                     lines of content
                  ".in).parse.decode,
      [,].add(
        [,].add(
          [:].addAll(["map":"node", "with":"multiple lines of content"])))
      )

    verifyEq(
      YamlReader("nested:
                    map: node
                    with:    multiple
                     lines of content
                  ".in).parse.decode,
      [,].add(
        [:].add("nested",
          [:].addAll(["map":"node", "with":"multiple lines of content"])))
      )

    verifyErr (FileLocErr#)
    {
      YamlReader("Multiple-line
                    key: shouldn't work
                  ".in).parse
    }

    YamlReader(("a" * 1024 + ": works!").in).parse

    verifyErr (FileLocErr#)
    {
      YamlReader(("a" * 1025 + ": doesn't work").in).parse
    }
  }

  ** Tests a full-length example from the spec
  Void testFull()
  {
    input     := Str<|--- !<tag:clarkevans.com,2002:invoice>
                      invoice: 34843
                      date   : 2001-01-23
                      bill-to: &id001
                        given  : Chris
                        family : Dumars
                        address:
                          lines: |
                            458 Walkman Dr.
                            Suite #292
                          city    : Royal Oak
                          state   : MI
                          postal  : 48046
                      ship-to: *id001
                      product:
                      - sku         : BL394D
                        quantity    : 4
                        description : Basketball
                        price       : 450.00
                      - sku         : BL4438H
                        quantity    : 1
                        description : Super Hoop
                        price       : 2392.00
                      tax  : 251.42
                      total: 4443.52
                      comments:
                        Late afternoon is best.
                        Backup contact is Nancy
                        Billsmer @ 338-4338.|>

    expected  := Str<|{
                        "invoice": 34843,
                        "date"   : "2001-01-23",
                        "bill-to":
                        {
                          "given"  : "Chris",
                          "family" : "Dumars",
                          "address":
                          {
                            "lines"   : "458 Walkman Dr.\nSuite #292\n",
                            "city"    : "Royal Oak",
                            "state"   : "MI",
                            "postal"  : 48046,
                          }
                        },
                        "ship-to":
                        {
                          "given"  : "Chris",
                          "family" : "Dumars",
                          "address":
                          {
                            "lines"   : "458 Walkman Dr.\nSuite #292\n",
                            "city"    : "Royal Oak",
                            "state"   : "MI",
                            "postal"  : 48046,
                          }
                        },
                        "product":
                        [
                          {
                            "sku"         : "BL394D",
                            "quantity"    : 4,
                            "description" : "Basketball",
                            "price"       : 450.00
                          },
                          {
                            "sku"         : "BL4438H",
                            "quantity"    : 1,
                            "description" : "Super Hoop",
                            "price"       : 2392.00
                          }
                        ],
                        "tax"  : 251.42,
                        "total": 4443.52,
                        "comments": "Late afternoon is best. Backup contact is Nancy Billsmer @ 338-4338."
                      }
                      |>

    verifyEq(YamlReader(input.in)   .parse.decode(YamlSchema.core),
             YamlReader(expected.in).parse.decode(YamlSchema.json))
  }

  Void testEncode()
  {
    verifyEq("test", decEnc("test"))
    verifyEq(null, decEnc(null))
    verifyEq(5, decEnc(5))
    verifyEq(-5.0f, decEnc(-5.0f))
    verifyEq(Float.negInf, decEnc(Float.negInf))
    verify(decEnc(Float.nan)->isNaN)
    verifyEq(true, decEnc(true))
    verifyEq("~", decEnc("~"))
    verifyEq("2022-08-22", decEnc(Date("2022-08-22")))
    verifyEq(
      [Obj:Obj?]
      [
        "x": 4,
        "y": -2,
        "w": 13,
        "h": 0
      ],
      decEnc(Rectangle
      {
        it.x = 4
        it.y = -2
        it.w = 13
        it.h = 0
      }))
    verifyEq(
      [Obj:Obj?]
      [
        "name": "Homer Simson",
        "each":
        Obj?[
          [Obj:Obj?]["name":"Bart",   "each": [,]],
          [Obj:Obj?]["name":"Lisa",   "each": [,]],
          [Obj:Obj?]["name":"Maggie", "each": [,]]
        ]
      ],
      decEnc(yaml::Person
      {
        name = "Homer Simson"
        yaml::Person { name = "Bart" },
        yaml::Person { name = "Lisa" },
        yaml::Person { name = "Maggie" },
      })
    )
    verifyEq(
      YamlMap
      (
        [YamlObj:YamlObj]
        [
          YamlScalar("name"): YamlScalar("Homer Simson"),
          YamlScalar("each"): YamlList
          (YamlObj[
            YamlMap
            (
              [YamlObj:YamlObj]
              [
                YamlScalar("name"): YamlScalar("Bart"),
                YamlScalar("each"): YamlList(YamlObj[,])
              ],
            "!fan/yaml::Person"),
            YamlMap
            (
              [YamlObj:YamlObj]
              [
                YamlScalar("name"): YamlScalar("Lisa"),
                YamlScalar("each"): YamlList(YamlObj[,])
              ],
            "!fan/yaml::Person"),
            YamlMap
            (
              [YamlObj:YamlObj]
              [
                YamlScalar("name"): YamlScalar("Maggie"),
                YamlScalar("each"): YamlList(YamlObj[,])
              ],
            "!fan/yaml::Person"),
          ])
        ],
      "!fan/yaml::Person"),
      YamlSchema.core.encode(yaml::Person
      {
        name = "Homer Simson"
        yaml::Person { name = "Bart" },
        yaml::Person { name = "Lisa" },
        yaml::Person { name = "Maggie" },
      })
    )
  }

  Void verifyLoc(YamlObj obj, Int line, Int col)
  {
    verifyEq(obj.loc.line, line)
    verifyEq(obj.loc.col, col)
  }

  Obj? decEnc(Obj? obj) { YamlSchema.core.decode(YamlSchema.core.encode(obj)) }
}

// Test w/ testEncode
@Serializable
internal class Rectangle
{
  Int x; Int y
  Int w; Int h
  @Transient Int area
}

@Serializable { collection = true }
internal class Person
{
  @Operator
  This add(Person kid) { kids.add(kid); return this }
  Void each(|Person kid| f) { kids.each(f) }
  Str name := ""
  @Transient private Person[] kids := Person[,]
}