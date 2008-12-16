//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 08  Andy Frank  Creation
//

using [java] java.lang
using [java] javax.script

**
** Runner takes a Fan qname and attempts to run the
** matching Javascript implemenation.
**
class Runner
{

  Void main()
  {
    if (Sys.args.size != 1)
    {
      echo("Usage: Runner <pod>::<type>.<method>")
      Sys.exit(-1)
    }

    // get args
    arg    := Sys.args.first
    pod    := arg
    type   := "Main"
    method := "main"

    // check for type
    if (pod.contains("::"))
    {
      i := pod.index("::")
      type = pod[i+2..-1]
      pod  = pod[0..i-1]
    }

    // check for method
    if (type.contains("."))
    {
      i := type.index(".")
      method = type[i+1..-1]
      type   = type[0..i-1]
    }

    // try to access to verify type.slot exists
    p := Pod.find(pod)
    t := Type.find("$pod::$type")
    m := t.method(method)

    // eval sys lib
    engine := ScriptEngineManager().getEngineByName("js");
    evalSys(engine)

    // TODO - eval pod dependencies

    // eval pod
    //script := p.files["/${p.name}.js".toUri]
    //if (script == null) throw Err("No script found in $p.name")
script := Sys.homeDir + "lib/javascript/${p.name}.js".toUri
if (!script.exists) throw Err("No script found in $p.name")
    try engine.eval(script.readAllStr);
    catch (Err e) throw Err("Pod eval failed: $p.name", e)

    // invoke target method
    jsname := t.qname.replace("::", "_")
    if (m.isStatic)
      engine.eval("${jsname}.$m.name();")
    else
      engine.eval("var obj = new $jsname(); obj.$m.name();")
  }

  **
  ** Load in the sys library.
  **
  static Void evalSys(ScriptEngine engine)
  {
    // load script zip
    sys := Sys.homeDir + `lib/javascript/sys.zip`
    zip := Zip.read(sys.in)

    // read all script files
    scripts := Str:Str[:]
    File? script
    while ((script = zip.readNext) != null)
      scripts[script.name] = script.readAllStr

    // sort in depends order
    keys := scripts.keys
    keys.sort |Str a, Str b->Int|
    {
      // Sys always first
      if (a == "Sys.js") return -1
      if (b == "Sys.js") return 1
      // then Obj
      if (a == "Obj.js") return -1
      if (b == "Obj.js") return 1
      // doesn't matter after that
      return 0
    }

    // now eval everything
    keys.each |Str k|
    {
      try engine.eval(scripts[k])
      catch (Err e) throw Err("Sys pod eval failed: $k", e)
    }
  }
}