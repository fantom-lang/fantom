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
class JsonTestCase
{
  Str:Obj? map
  Str description

  Void javascript(Str resultVar, OutStream out)
  {
    this.writeJavascript(this.map, resultVar, out)
  }

  private Void writeJavascript(Str:Obj? map, Str resultVar, OutStream out)
  {
    if (map.size == 0)
    {
      out.printLine("var len = 0;")
      out.printLine("for (var v in "+resultVar+") len++;")
      out.printLine("if (len == 0)")
      pass("Object of length 0",out)
      out.printLine("else")
      pass("Object of length 0",out)
    }
    else
    {
      map.each |Obj? val, Str key|
      {
        if (val == null)
        {
          out.printLine("if ("+resultVar+"['"+key+"'] == null)")
          pass("Value for "+key+" is expected null",out)
          out.printLine("else")
          fail("Value for "+key+" is expected null",out)
        }
        else if (val is Uri)
        {
          out.printLine("if ("+resultVar+"['"+key+"'] != '`"+val.toStr+"`')")
          fail("Uri Equality to "+val, out)
          out.printLine("else")
          pass("Uri Equality to "+val, out)
        }
        else if (val is List)
        {
          out.printLine("if ("+resultVar+"['"+key+"'] == null)")
          fail("Value for "+key+" is null", out)
          out.printLine("else {")
          pass("Value for "+key+" is null", out)
          out.printLine("var list = "+resultVar+"['"+key+"'];")
          list := (List)val
          out.printLine("if (list.length != "+list.size+")")
          fail("List length did not match expected of "+list.size, out)
          out.printLine("else {")
          // TODO need to check each element, which could be a map or list itself
          pass("TODO need to check item by item", out)
          out.printLine("}")
          out.printLine("}")
        }
        else if (val is Map)
        {
          out.printLine("if ("+resultVar+"['"+key+"'] == null)")
          fail("Value for "+key+" is null", out)
          out.printLine("else {")
          inner := (Map)val
          out.printLine("var map = "+resultVar+"['"+key+"'];")
          out.printLine("var len = 0;")
          out.printLine("for (var v in map) len++;")
          out.printLine("if (len != "+inner.size+")")
          fail("Object length does not match expected of "+inner.size, out)
          out.printLine("else {")
          this.writeJavascript(inner, "map", out)
          out.printLine("}")
          out.printLine("}")
        }
        else if (val is Bool)
        {
          out.printLine("if ("+resultVar+"['"+key+"'] != "+val.toStr+")")
          fail("Boolean Test against expected "+val, out)
          out.printLine("else")
          pass("Boolean Test against expected "+val, out)
        }
        else
        {
          out.printLine("if ("+resultVar+"['"+key+"'] != '"+val.toStr+"')")
          fail("Simple Equality to "+val, out)
          out.printLine("else")
          pass("Simple Equality to "+val, out)
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
