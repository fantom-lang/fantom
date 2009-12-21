//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 08  Kevin McIntire  Creation
//

**
** JsonTestCase
**
internal class JsonTestCase
{
  [Str:Obj?]? map
  Str? description

  Void javascript(Str resultVar, OutStream out)
  {
    this.writeJavascript(this.map, resultVar, out)
  }

  private Void writeNullJs(Str resultVar, Str key, OutStream out)
  {
    out.printLine("if ("+resultVar+"['"+key+"'] == null)")
    pass("Value for "+key+" is expected null",out)
    out.printLine("else")
    fail("Value for "+key+" is expected null",out)
  }

  private Void writeBoolJs(Str resultVar, Str key, Bool bool, OutStream out)
  {
    out.printLine("if ("+resultVar+"['"+key+"'] != "+bool.toStr+")")
    fail("Boolean Test against expected "+bool, out)
    out.printLine("else")
    pass("Boolean Test against expected "+bool, out)
  }

  private Void writeStrJs(Str resultVar, Str key, Str val, OutStream out)
  {
    out.printLine("if ("+resultVar+"['"+key+"'] != "+val.toCode+")")
    fail("Simple Equality to "+val.toCode, out)
    out.printLine("else")
    pass("Simple Equality to "+val.toCode, out)
  }

  private Void writeObjJs(Str resultVar, Str key, Obj val, OutStream out)
  {
    out.printLine("if ("+resultVar+"['"+key+"'] != '"+val.toStr+"')")
    fail("Simple Equality to "+val, out)
    out.printLine("else")
    pass("Simple Equality to "+val, out)
  }

  private Void writeEmptyJs(Str resultVar, OutStream out)
  {
    out.printLine("var len = 0;")
    out.printLine("for (var v in "+resultVar+") len++;")
    out.printLine("if (len == 0)")
    pass("Object of length 0",out)
    out.printLine("else")
    pass("Object of length 0",out)
  }

  private Void writeListJs(Str resultVar, Str key, List list, OutStream out)
  {
    out.printLine("if ("+resultVar+"['"+key+"'] == null)")
    fail("Value for "+key+" is null", out)
    out.printLine("else {")
    pass("Value for "+key+" is null", out)
    out.printLine("var list = "+resultVar+"['"+key+"'];")
    out.printLine("if (list.length != "+list.size+")")
    fail("List length did not match expected of "+list.size, out)
    out.printLine("else {")

    // TODO sort first?
    idx := 0
    out.printLine("var failed = false;")
    list.each |Obj? val|
    {
      // TODO need to handle list and maps here
      out.printLine("if (list["+idx+"] != "+val+") {")
      fail("List @ "+idx+" did not match expected of "+val, out)
      out.printLine("failed = true;")
      out.printLine("}")
      idx++
    }
    out.printLine("if (failed)")
    fail("Array values did not match", out)
    out.printLine("else")
    pass("Array values matched", out)

    out.printLine("}")
    out.printLine("}")
  }

  private Void writeMapJs(Str resultVar, Str key, Map map, OutStream out)
  {
    out.printLine("if ("+resultVar+"['"+key+"'] == null)")
    fail("Value for "+key+" is null", out)
    out.printLine("else {")
    out.printLine("var map = "+resultVar+"['"+key+"'];")
    out.printLine("var len = 0;")
    out.printLine("for (var v in map) len++;")
    out.printLine("if (len != "+map.size+")")
    fail("Object length does not match expected of "+map.size, out)
    out.printLine("else {")
    this.writeJavascript(map, "map", out)
    out.printLine("}")
    out.printLine("}")
  }

  // TODO pattern matching would be really nice here
  // would like to close over out
  private Void writeJavascript(Str:Obj? map, Str resultVar, OutStream out)
  {
    if (map.size == 0)
    {
      writeEmptyJs(resultVar, out)
    }
    else
    {
      map.each |Obj? val, Str key|
      {
        if (val == null)
        {
          writeNullJs(resultVar, key, out)
        }
        else if (val is List)
        {
          writeListJs(resultVar, key, val as List, out)
        }
        else if (val is Map)
        {
          writeMapJs(resultVar, key, val as Map, out)
        }
        else if (val is Bool)
        {
          writeBoolJs(resultVar, key, val as Bool, out)
        }
        else if (val is Str)
        {
          writeStrJs(resultVar, key, val as Str, out)
        }
        else
        {
          writeObjJs(resultVar, key, val, out)
        }
      }
    }
  }

  private Void pass(Str test, OutStream out)
  {
    showResult(test, "Pass", out)
  }

  private Void fail(Str test, OutStream out)
  {
    showResult(test, "Fail", out)
  }

  private Void showResult(Str test, Str status, OutStream out)
  {
    out.printLine("document.writeln('<li class=\"test\">"+test+":&nbsp<span class=\""+status+
                  "\">"+status+"</span></li>');")
  }

}