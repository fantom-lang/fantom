//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   09 Aug 08  Brian Frank  Creation
//

class FluxUtilTest : Test
{

  Void testMarkIdentity()
  {
    a := Mark { uri = `/a.txt`; line = 55 }
    b := Mark { uri = `/a.txt`; line = 8 }
    c := Mark { uri = `/b.txt`; line = 3 }
    d := Mark { uri = `/a.txt`; line = 55; col = 3 }

    verifyEq(a, Mark { uri = `/a.txt`; line = 55 })
    verifyNotEq(a, b)
    verifyNotEq(a, c)
    verifyNotEq(a, d)

    verifyEq(a <=> a, 0)
    verifyEq(a <=> b, +1)
    verifyEq(a <=> c, -1)
    verifyEq(a <=> d, -1)
  }

  Void testMarkParse()
  {
    f := Env.cur.homeDir + `etc/sys/config.props`
    verifyMark("${f.osPath}", f)
    verifyMark("${f.osPath} ${Env.cur.homeDir}", f)
    verifyMark("(${f.osPath})", f)
    verifyMark("---${f.osPath}---", f)
    verifyMark("${f.osPath}:8", f, 8)
    verifyMark("(${f.osPath}:20)", f, 20)
    verifyMark("${f.osPath} 208 33", f, 208, 33)
    verifyMark("(${f.osPath}:208:7)", f, 208, 7)
    verifyMark("$f.osPath(511:3)", f, 511, 3)
    verifyMark("file=${f.osPath} line=1234 col=8", f, 1234, 8)
  }

  Void verifyMark(Str text, File f, Int? line := null, Int? col := null)
  {
    mark := Mark(text)
    // echo("$text  =>  $mark")
    verifyEq(mark.uri.name, f.name)
    verifyEq(mark.line, line)
    verifyEq(mark.col, col)
  }

}