//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//

**
** DocType models the documentation of a `sys::Type`.
**
const class DocType
{

  ** Constructor
  internal new make(|This| f) { f(this) }

  ** Representation of this type definition as a reference
  const DocTypeRef ref

  ** Pod name which defines this type
  Str pod() { ref.pod }

  ** Simple name of the type such as "Str".
  Str name() { ref.name }

  ** Qualified name formatted as "pod::name".
  Str qname() { ref.qname }

  ** Source code location of this type definition
  const DocLoc loc

  ** Flags mask - see `DocFlags`
  const Int flags

  ** Fandoc documentation string
  const Str doc

  ** Facets defined on this type
  const DocFacet[] facets

  ** The direct super class of this type (null for Obj)
  const DocTypeRef? base

  ** Mixins directly implemented by this type
  const DocTypeRef[] mixins

  ** Slots defined by this type
  const DocSlot[] slots

  ** Summary is the first sentence of `doc`
  Str summary() { DocUtil.firstSentence(doc) }

  internal Void dump(OutStream out)
  {
    out.printLine("#### $qname #####")
    out.printLine("ref    = $ref")
    out.printLine("pod    = $pod")
    out.printLine("name   = $name")
    out.printLine("flags  = " + DocFlags.toNames(flags))
    out.printLine("doc    = $doc.toCode")
    out.printLine("base   = $base")
    out.printLine("mixins = $mixins")
    facets.each |facet| { out.printLine(facet) }
    slots.each |slot| { slot.dump(out) }
    out.printLine.flush
  }

  static Void main()
  {
    file := Env.cur.homeDir + `lib/fan/xfoo.pod`
    zip  := Zip.open(file)
    zip.contents.vals.sort.each |f|
    {
      if (f.path.first == "doc2" && f.ext == "apidoc")
      {
if (f.basename != "Bar") return
         ApiDocParser("xfoo", f.in).parseType.dump(Env.cur.out)
      }
    }
  }

}