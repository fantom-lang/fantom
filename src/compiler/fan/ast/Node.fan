//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//    3 Jun 06  Brian Frank  Ported from Java to Fan - Megan's b-day!
//

**
** Node is the base class of all classes which represent a node
** in the abstract syntax tree generated by the parser.
**
abstract class Node
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** All Node's must have a valid location in a source file.
  **
  new make(Location location)
  {
    if ((Obj?)location == null)
      throw NullErr("null location")
    this.location = location
  }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  **
  ** Print to std out
  **
  Void dump()
  {
    print(AstWriter.make)
  }

  **
  ** Pretty print this node and it's descendants.
  **
  abstract Void print(AstWriter out)

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  readonly Location location

}