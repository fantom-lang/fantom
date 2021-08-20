//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2021 Matthew Giannini   Creation
//

class DnTest : Test
{
  // TODO: these tests are by no means sufficient.

  Void testRfc4514Type()
  {
    verifyEq("CN", parse("cn=foo").first.shortName)
    verifyNull(parse("0.0.40.9999=foo").first.shortName)

    verifyErr(ParseErr#) { parse("00.1=foo") }
    verifyErr(ParseErr#) { parse("0.01=foo") }
    verifyErr(ParseErr#) { parse("0.0.=foo") }
  }

  Void testRfc4514Val()
  {
    verifyEq("foo", parse("cn=foo").first.val)
  }

  private Rdn[] parse(Str name)
  {
    DnParser(name).parse
  }

}