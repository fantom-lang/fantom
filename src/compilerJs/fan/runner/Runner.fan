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
** matching JavaScript implemenation.
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

    // create engine and eval pods
    engine := ScriptEngineManager().getEngineByName("js");
    evalPodScript(engine, p)

    // invoke target method
    jsname := "fan.${t.pod}.${t.name}"
    if (m.isStatic)
      engine.eval("${jsname}.$m.name();")
    else
      engine.eval("var obj = new $jsname(); obj.$m.name();")
  }

  **
  ** Load and eval the pod script file, and all its
  ** dependenceis in the specifed ScriptEngine.
  **
  static Void evalPodScript(ScriptEngine engine, Pod pod)
  {
    // eval dependecies
    pod.depends.each |Depend d|
    {
      script := Pod.find(d.name).files["/${d.name}.js".toUri]
      if (script != null)
      {
        try engine.eval(script.readAllStr)
        catch (Err e) throw Err("Pod eval failed: $d.name", e)
      }
    }

    // eval given pod
    script := pod.files["/${pod.name}.js".toUri]
    if (script == null) throw Err("No script found in $pod.name")
    try engine.eval(script.readAllStr);
    catch (Err e) throw Err("Pod eval failed: $pod.name", e)
  }
}

