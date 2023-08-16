//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Oct 2010  Brian Frank  Creation
//   15 Aug 2023  Matthew Giannini  Refactor for ES
//

**
** JsIndexedProps is used to support JavaScript implementation
** of `sys::Env.index`
**
class JsIndexedProps
{
  new make(ModuleSystem ms)
  {
    this.ms = ms
  }

  private ModuleSystem ms

  **
  ** Write out a stream of indexed props to be added to the
  ** JavaScript implementation of `sys::Env`.  If pods is null
  ** index every pod installed, otherwise just the pods specified.
  **
  Void write(OutStream out, Pod[]? pods := null)
  {
    if (pods == null) pods = Pod.list

    index := Str:Str[][:]
    pods.each |pod|
    {
      try
        addToIndex(pod, index)
      catch (Err e)
        echo("ERROR: JsIndexProps.write: $pod.name\n$e.traceToStr")
    }

    ms.writeBeginModule(out)
    ms.writeInclude(out, "sys.ext")
    out.printLine("const i = sys.Map.make(sys.Str.type\$, sys.List.make(sys.Str.type\$).typeof());")
    out.printLine("const x = (k, v) => i.set(k, sys.List.make(sys.Str.type\$, v));")

    keys := index.keys.sort
    keys.each |key|
    {
      vals := index[key].sort
      v := vals.join(",") |v| { v.toCode }
      out.printLine("x(\"$key\", [${v}]);")
    }

    out.printLine("sys.Env.cur().__loadIndex(i);")
    ms.writeEndModule(out)
  }

  private Void addToIndex(Pod pod,  Str:Str[] index)
  {
    f := pod.file(`/index.props`, false)
    if (f == null) return


    f.in.readPropsListVals.each |v, n|
    {
      list := index[n]
      if (list == null) index[n] = list = Str[,]
      list.addAll(v)
    }
  }

  static Void main(Str[] args)
  {
    make(CommonJs(Env.cur.tempDir.plus(`jsIndexedProps/`))).write(Env.cur.out)
  }
}


