//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Oct 2024  Matthew Giannini  Creation
//

@Js
class NodeTest : Test
{
  Void test()
  {
    root := Document()
    verifyNull(root.parent)

    p1 := Paragraph()
    p2 := Paragraph()
    root.appendChild(p1)
    verifyNode(root, null, null, null, p1, p1)
    root.appendChild(p2)
    verifyNode(root, null, null, null, p1, p2)
    p1.unlink
    verifyNode(root, null, null, null, p2, p2)

    p2.insertBefore(p1)
    verifyNode(root, null, null, null, p1, p2)
    verifyNode(p2, root, null, p1, null, null)
    verifyNode(p1, root, p2, null, null, null)

    p1.unlink
    verifyNode(root, null, null, null, p2, p2)

    p2.insertAfter(p1)
    verifyNode(root, null, null, null, p2, p1)

  }


  private Void verifyNode(Node n, Node? parent, Node? next, Node? prev, Node? firstChild, Node? lastChild)
  {
    verifySame(n.parent, parent)
    verifySame(n.next, next)
    verifySame(n.prev, prev)
    verifySame(n.firstChild, firstChild)
    verifySame(n.lastChild, lastChild)
  }
}
