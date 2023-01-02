#! /usr/bin/env fan
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 2022  Kiera O'Flynn   Creation
//

using util

**************************************************************************
** YamlSuiteTest
**************************************************************************

**
** Runs the comprehensive YAML tests from https://github.com/yaml/yaml-test-suite/.
**
class YamlTestSuite : Test
{

//////////////////////////////////////////////////////////////////////////
// Running tests
//////////////////////////////////////////////////////////////////////////

  ** Run all tests in the suite
  Void testRunSuite()
  {
    if (!testDir.exists)
    {
      echo(Str<|
                ************************* WARNING *************************

                          Test suite files not locally downloaded,
                                       test exiting
                              Run 'build preptest' to download

                ***********************************************************
                |>)
      return
    }

    YamlRes[] results := [,]

    // Run each test folder
    testDir.walk |f|
    {
      if (f.isDir && (f + `===`).exists)
        results.add(run(f))
    }

    // Process the results, echoing any error messages.
    n := 0
    f := 0
    s := StrBuf()
    results.each |res|
    {
      n++
      if (res.err != null)
      {
        f++
        s.add(res.fname)
        echo("Error testing \"$res.name.trim\" in folder ${res.fname}.
              Error - $res.err.toStr
              ")
      }
    }

    echo(s.toStr)
    echo("${n-f}/$n tests passed.")
    if (f != 0)
      fail("$f YAML suite tests did not pass.")
  }

  ** Run a single test of interest for debugging purposes
  Void runOne()
  {
    test := testDir + `AZW3/`
    if (!test.exists)
      return echo("This test does not exist. Exiting.")
    res  := run(test)

    if (res.err != null)
      throw res.err
    else
      echo("Test $res.fname passed!")
  }

  ** Run a single test in a given folder
  private YamlRes run(File dir)
  {
    // Ensure that the folder is a directory
    if (!dir.isDir)
      throw Err("The input must be a directory, not a file.")

    // Read meta test files
    name     := (dir + `===`).readAllStr
    fname    := dir.uri.relTo(testDir.uri).toStr[0..-2]
    parseErr := (dir + `error`).exists
    argErr   := shouldArgErr.contains(fname)
    testErr  := shouldFail.contains(fname)
    schema   := useFailsafe.contains(fname) ? YamlSchema.failsafe : YamlSchema.core

    try
    {
      // Compare parsing result for each YAML/JSON file to in.yaml's result
      comp  := dir.listFiles.findAll |f| { f.uri.toStr.endsWith(".yaml") ||
                                           f.uri.toStr.endsWith(".json")
                                         }
      in1   := YamlReader((dir + `in.yaml`).in).parse
      inObj := in1.decode(schema)

      // Verify that all files in the folder produce the same results
      comp.each |f|
      {
        Obj? compObj := [,]

        // Process multiple documents in a JSON file with JsonInStream
        if (f.uri.toStr.endsWith(".json") && (inObj as Obj?[]).size > 1)
        {
          fin := f.in
          while (fin.avail != 0)
          {
            compObj->add(convert(JsonInStream(fin).readJson))
          }
        }

        // Process YAML documents normally
        else compObj = YamlReader(f.in).parse.decode(schema)

        verifyEq(inObj, compObj)
      }

      try
      {
        // Verify that writing the YamlObj to a string and reading
        // it back produces the same results
        verifyEq(in1, YamlReader(in1.toStr.in).parse)

        // Verify that writing the parsed object to a YamlObj and
        // reading it back produces the same result
        verifyEq(inObj, schema.decode(schema.encode(inObj)))

        if (schema != YamlSchema.failsafe)
          verifyEq(YamlSchema.failsafe.decode(in1),
                   YamlSchema.failsafe.decode(
                      YamlSchema.failsafe.encode(
                        YamlSchema.failsafe.decode(in1))))
      }
      catch (Err e)
      {
        // Error regardless of expectation - this should always work if you got this far
        return YamlRes(name, fname, e)
      }
    }
    catch (FileLocErr e)
    {
      if (!parseErr)
        // Error where none expected
        return YamlRes(name, fname, e)
      else
        // Success!
        return YamlRes(name, fname)
    }
    catch (ArgErr e)
    {
      if (!argErr)
        // Error where none (or a ParseErr) expected
        return YamlRes(name, fname, e)
      else
        // Success!
        return YamlRes(name, fname)
    }
    catch (TestErr e)
    {
      if (!testErr)
        // Error where none (or a ParseErr) expected
        return YamlRes(name, fname, e)
      else
        // Success!
        return YamlRes(name, fname)
    }
    catch (Err e)
    {
      // Error where none expected
      return YamlRes(name, fname, e)
    }

    if (parseErr || argErr || testErr)
      // No error where one expected
      return YamlRes(name, fname, Err("An error was expected, but none occurred."))
    else
      // Success!
      return YamlRes(name, fname)
  }

//////////////////////////////////////////////////////////////////////////
// Helper methods
//////////////////////////////////////////////////////////////////////////

  ** Converts a JsonInStream result to be type-compatible with YAML results.
  ** Specifically, recursively converts any Str:Obj?s to Obj:Obj?s.
  private Obj? convert(Obj? json)
  {
    if (json == null)
      return null

    else if (json.typeof.fits(List#))
      return (json as List).map |v| { convert(v) }

    else if (json.typeof.fits(Map#))
    {
      Obj:Obj? copy := [:]
      (json as Map).each |v,k| { copy.add(convert(k),convert(v)) }
      return copy
    }

    else return json
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** The directory containing the YAML test suite.
  private File testDir := Env.cur.homeDir + `etc/yaml/tests/`

  ** Tests that should error because of duplicate key entries.
  private Str[] shouldArgErr := ["2JQS", "X38W"]

  ** Needs to be decoded with the failsafe schema (e.g. because of null keys).
  private Str[] useFailsafe := ["SM9W/01", "S3PD", "6M2F", "DFF7", "FRK4",
                                "UKK6/00", "CFD4", "NHX8", "NKF9", "M2N8/00",
                                "FH7J", "PW8X"]

  ** Tests that should parse, but fail an equality test (e.g. because ints & floats are not equal in Fantom)
  private Str[] shouldFail := ["UGM3"]
}


**************************************************************************
** YamlRes
**************************************************************************

**
** Represents the result of a YAML suite test.
**
internal class YamlRes
{
  ** Descriptive name of the test
  Str name

  ** Name of the containing folder (e.g. ABCD or ABCD/00)
  Str fname

  ** Error that occurred in the test, or null if it succeeded
  Err? err

  new make(Str name, Str fname, Err? err := null)
  {
    this.name  = name
    this.fname = fname
    this.err   = err
  }
}