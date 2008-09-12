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
    GeneralOptions opt
    opt = Flux.loadOptions("FluxUtilTest", GeneralOptions#)
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

}
