//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Oct 10  Brian Frank  Creation
//

**
** JsIndexedProps is used to support JavaScript implementation
** of `sys::Env.index`
**
class JsIndexedProps
{
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
      addToIndex(pod, index)
    }

    index.each |vals, key|
    {
      writePair(out, key, vals)
    }
  }

  private Void addToIndex(Pod pod,  Str:Str[] index)
  {
    f := pod.file(`/index.props`, false)
    if (f == null) return

    // TODO this doesn't actually parse actual format yet
    f.eachLine |line|
    {
      eq  := line.index("=")
      key := line[0..<eq]
      val := line[eq+1..-1]
      list := index[key]
      if (list == null) index[key] = [val]
      else list.add(val)
    }
  }

  private Void writePair(OutStream out, Str key, Str[] vals)
  {
    // TODO
    out.printLine("// $key: $vals")
  }

  static Void main(Str[] args)
  {
    make.write(Env.cur.out)
  }
}

