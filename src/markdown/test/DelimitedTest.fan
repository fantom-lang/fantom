//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Oct 2024  Matthew Giannini  Creation
//

@Js
class DelimitedTest : Test
{
  Void testEmphasis()
  {
    input := "* *emphasis* \n" +
             "* **strong** \n" +
             "* _important_ \n" +
             "* __CRITICAL__ \n"

    parser := Parser()
    doc := parser.parse(input)
    v := DelimitedTestVisitor()
    doc.walk(v)
    list := v.list
    verifyEq(4, list.size)

    emphasis := list[0]
    strong := list[1]
    important := list[2]
    critical := list[3]

    verifyEq("*", emphasis.openingDelim)
    verifyEq("*", emphasis.closingDelim)
    verifyEq("**", strong.openingDelim)
    verifyEq("**", strong.closingDelim)
    verifyEq("_", important.openingDelim)
    verifyEq("_", important.closingDelim)
    verifyEq("__", critical.openingDelim)
    verifyEq("__", critical.closingDelim)
  }
}

@Js
internal class DelimitedTestVisitor : Visitor
{
  new make() { this.list = Delimited[,] }
  Delimited[] list
  override Void visitEmphasis(Emphasis node) { list.add(node) }
  override Void visitStrongEmphasis(StrongEmphasis node) { list.add(node) }
  // override protected Void visitChildren(Node parent)
  // {
  //   echo("visitChildren: ${parent}")
  //   Visitor.super.visitChildren(parent)
  // }
}