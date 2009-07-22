//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   09 Aug 08  Brian Frank  Creation
//

class FluxUtilTest : Test
{

  Void testOptions()
  {
    file := Flux.homeDir + `FluxUtilTest.fog`
    file.delete
    verifyFalse(file.exists)

    // default
    opt := Flux.loadOptions("FluxUtilTest", GeneralOptions#) as GeneralOptions
    verifyEq(opt.homePage, `flux:start`)

    // write file
    file.out.print("flux::GeneralOptions { homePage=`/foo` }").close
    file.modified = DateTime.now + -2min
    opt = Flux.loadOptions("FluxUtilTest", GeneralOptions#)
    verifyEq(opt.homePage, `/foo`)

    // cached
    opt = Flux.loadOptions("FluxUtilTest", GeneralOptions#)
    verifyEq(opt.homePage, `/foo`)

    // update file (we need to manually change timestamp)
    file.out.print("flux::GeneralOptions { homePage=`/bar` }").close
    opt = Flux.loadOptions("FluxUtilTest", GeneralOptions#)
    verifyEq(opt.homePage, `/bar`)

    // cleanup
    file.delete
    opt = Flux.loadOptions("FluxUtilTest", GeneralOptions#)
    verifyEq(opt.homePage, `flux:start`)
  }

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
    f := Repo.boot.home + `lib/sys.props`
    verifyMark("${f.osPath}", f)
    verifyMark("${f.osPath} ${Repo.boot.home}", f)
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