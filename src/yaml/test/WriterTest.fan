//
// Copyright (c) 2024, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Feb 2026  Mike Jarmy  Creation
//

class WriterTest : Test
{
  Void test()
  {
    verifyYaml(null)
    verifyYaml(1)
    verifyYaml(2.0f)
    verifyYaml("abc")
    verifyYaml(Obj?[null, 2, 3.0f, "xyz"])
    verifyYaml(Obj:Obj?[
      "a": 1,
    ])
    verifyYaml(Obj:Obj?[
      "a": null,
      "b": 2,
      "c": 3.0f,
      "d": "xyz",
      "e": Obj?[null, 2, 3.0f, "xyz"],
      "f": Obj?[null, Obj:Obj?["x":4, "y": Obj?[1, 2, 3]]],
    ])
  }

  Void testSpecialChars()
  {
    verifyYaml("key: value")
    verifyYaml("- list item")
    verifyYaml("#comment")
    verifyYaml("nested {json}")
    verifyYaml("C:\\Windows")

    verifyYaml("He said \"Hello\"");
    verifyYaml("It's a trap");
    verifyYaml("Tab\tSeparated");

    verifyEq(roundTrip("123.45"), 123.45f)
    verifyEq(roundTrip("007"), 7)

    verifyYaml("");
    verifyYaml("   spaces   ");
    verifyYaml(":");
  }

  Void testMultiline()
  {
    // N.B the YamlReader adds a newline to the end

    verifyEq(
      roundTrip(Obj:Obj?[
        "foo": "Line1\nLine2",
      ]),
      Obj:Obj?[
        "foo": "Line1\nLine2\n",
      ])
    verifyEq(
      roundTrip(Obj:Obj?[
        "foo": "Line1\nLine2", "bar": 1,
      ]),
      Obj:Obj?[
        "foo": "Line1\nLine2\n", "bar": 1,
      ])
  }

  private Void verifyYaml(Obj? val)
  {
    verifyEq(val, roundTrip(val))
  }

  private Obj? roundTrip(Obj? val)
  {
    buf := Buf()
    YamlWriter(buf.out).writeYaml(val)
    str := buf.flip.readAllStr

    //echo("-----------------------------------------")
    //echo(str)

    return YamlReader(str.in).parse[0].decode
  }
}
