#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Dec 08  Brian Frank  Creation
//

using xml
using sys::Unit as Unused

**
** Compile the oBIX units.obix into the Fan units.props
**
class BuildUnits
{

  Void usage()
  {
    echo("BuildUnits <obix input> <fan output>")
  }

  Void main(Str[] args)
  {
    if (args.size < 2) { usage; return }

    inFile := File.os(args[0])
    outFile := File.os(args[1])

    // parse obix input file into quantities
    dimless := Quantity { name="dimensionless" }
    quantities := [dimless]
    dims := Str:Dim[:]
    inDoc := XParser(inFile.in).parseDoc
    inDoc.root.elems.each |XElem x|
    {
      // href to name
      href := x.get("href")
      name := href["obix:units/".size .. -1]
      if (name == "null") return

      // if there is a dimension child this is
      // the abstract quantity unit
      xdim := dimChild(x)
      if (xdim != null)
      {
        dim := Dim(xdim)
        dims[href] = dim
        q := dim.quantity = Quantity { name = x.get("display"); dim = dim }
        quantities.add(q)
        return
      }

      unit := Unit { name = name }

      // symbol
      xsymbol := child(x, "symbol")
      unit.symbol = xsymbol?.get("val")

      // scale
      xscale := child(x, "scale")
      unit.scale = xscale?.get("val")?.toFloat ?: 1f

      // offset
      xoffset := child(x, "offset")
      unit.offset = xoffset?.get("val")?.toFloat ?: 0f

      // dimension
      contracts := x.get("is").split
      unit.dim = dims[contracts.first]
      if (unit.dim != null)
        unit.dim.quantity.units.add(unit)
      else
        dimless.units.add(unit)
    }

    // write output file
    out := outFile.out
    out.printLine("//")
    out.printLine("// Fan Unit Database")
    out.printLine("// Auto-generated conversion from oBIX database")
    out.printLine("// Generation script: adm/buildunits.fan")
    out.printLine("// Generated at $DateTime.now")
    out.printLine("//")
    out.printLine("// This file is formatted as a serialized list of quantities, where each")
    out.printLine("// quantity is itself a list. The first item in the quantity list is the")
    out.printLine("// name which maps to the Unit.quantity API, and the remainder of the list")
    out.printLine("// is the serialized units for the quantity.")
    out.printLine("//")
    out.printLine("")
    out.printLine("using sys::Unit")
    out.printLine("")
    out.printLine("// top list of quantities")
    out.printLine("[")
    quantities.each |Quantity q|
    {
      out.printLine("")
      out.printLine("// $q.name ($q.dim)")
      out.printLine("[")
      out.printLine("  $q.name.toCode,")
      q.units.each |Unit u| { out.printLine("  Unit($u.toStr.toCode),") }
      out.printLine("],")
    }
    out.printLine("] // end top list of quantities")
    out.close
  }

  static XElem? dimChild(XElem parent)
  {
    return parent.elems.find |XElem x->Bool| { return x.get("is", false) == "obix:Dimension" }
  }

  static XElem? child(XElem parent, Str name)
  {
    return parent.elems.find |XElem x->Bool| { return x.get("name", false) == name }
  }
}

**************************************************************************
** Quantity
**************************************************************************

class Quantity
{
  Str name
  Dim dim
  Unit[] units := Unit[,]
}

**************************************************************************
** Dim
**************************************************************************

class Dim
{
  new make(XElem x)
  {
    type.fields.each |Field f|
    {
      if (f.of != Int#) return
      ratio := BuildUnits.child(x, f.name)
      if (ratio != null) f.set(this, ratio.get("val").toInt)
    }
  }

  override Str toStr()
  {
    s := StrBuf()
    type.fields.each |Field f|
    {
      if (f.of != Int#) return
      exp := f.get(this)
      if (exp != 0)
      {
        if (s.size > 0) s.add("*")
        s.add(f.name).add(exp.toStr)
      }
    }
    return s.toStr
  }

  Quantity quantity
  Int kg; Int m; Int sec; Int K; Int A; Int mol; Int cd
}

**************************************************************************
** Unit
**************************************************************************

class Unit
{
  override Str toStr()
  {
    s := "$name; "
    if (symbol != null) s += symbol; s += "; "
    if (dim != null) s += dim;    s += "; "
    if (scale != 1f || offset != 0f) s += scale;  s += "; "
    if (offset != 0f) s += offset; s += "; "
    s = s.trim
    while (s.endsWith(";")) s = s[0..-2].trim
    return s
  }

  Dim? dim
  Str name
  Str? symbol
  Float scale := 1f
  Float offset := 0f
}