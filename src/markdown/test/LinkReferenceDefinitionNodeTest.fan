//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

@Js
class LinkReferenceDefinitionNodeTest : Test
{
  Void testDefinitionWithoutParagraph()
  {
    // doc := parse("This is a paragraph with a [foo] link\n\n[foo]: /url 'title'")
    doc := parse("This is a paragraph with a [foo] link.\n\n[foo]: /url 'title'")
    nodes := doc.children

    verifyEq(2, nodes.size)
    verifyType(nodes[0], Paragraph#)
    def := verifyDef(nodes[1], "foo")

    verifyEq("/url", def.destination)
    verifyEq("title", def.title)
  }

  Void testDefinitionWithParagraph()
  {
    doc := parse("[foo]: /url\nThis is a paragraph with a [foo] link.")
    nodes := doc.children

    verifyEq(2, nodes.size)
    // note that defintion is not part of the paragraph, it's a sibling
    verifyType(nodes[0], LinkReferenceDefinition#)
    verify(nodes[1] is Paragraph)
  }

  Void testMultipleDefinitions()
  {
    doc := parse("This is a paragraph with a [foo] link.\n\n[foo]: /url\n[bar]: /url")
    nodes := doc.children

    verifyEq(3, nodes.size)
    verifyType(nodes[0], Paragraph#)
    verifyDef(nodes[1], "foo")
    verifyDef(nodes[2], "bar")
  }

  Void testMultipleDefinitionsWithSameLabel()
  {
    doc := parse("This is a paragraph with a [foo] link.\n\n[foo]: /url1\n[foo]: /url2")
    nodes := doc.children

    verifyEq(3, nodes.size)
    verifyType(nodes[0], Paragraph#)
    def1 := verifyDef(nodes[1], "foo")
    verifyEq("/url1", def1.destination)
    // when there's multiple definitions with the same label, the first one "wins",
    // as in reference links will use that. But we still want to preserve the original
    // definitions in the document
    def2 := verifyDef(nodes[2], "foo")
    verifyEq("/url2", def2.destination)
  }

  Void testDefinitionOfReplacedBlock()
  {
    doc := parse("[foo]: /url\nHeading\n=======")
    nodes := doc.children

    verifyEq(2, nodes.size)
    verifyDef(nodes[0], "foo")
    verifyType(nodes[1], Heading#)
  }

  Void testDefinitionInListItem()
  {
    doc := parse("* [foo]: /url\n  [foo]\n")
    verifyType(doc.firstChild, BulletList#)
    item := doc.firstChild.firstChild
    verifyType(item, ListItem#)

    nodes := item.children
    verifyEq(2, nodes.size)
    verifyDef(nodes[0], "foo")
    verifyType(nodes[1], Paragraph#)
  }

  Void testDefinitionInListItem2()
  {
    doc := parse("* [foo]: /url\n* [foo]\n")
    verifyType(doc.firstChild, BulletList#)

    items := doc.firstChild.children
    verifyEq(2, items.size)
    item1 := items[0]
    item2 := items[1]

    verifyType(item1, ListItem#)
    verifyType(item2, ListItem#)

    verifyEq(1, item1.children.size)
    verifyDef(item1.firstChild, "foo")

    verifyEq(1, item2.children.size)
    verifyType(item2.firstChild, Paragraph#)
  }

  Void testDefinitionLabelCaseIsPreserved()
  {
    doc := parse("This is a paragraph with a [foo] link.\n\n[fOo]: /url 'title'")
    nodes := doc.children

    verifyEq(2, nodes.size)
    verifyType(nodes[0], Paragraph#)
    verifyDef(nodes[1], "fOo")
  }

  private LinkReferenceDefinition verifyDef(Node node, Str? label)
  {
    verify(node is LinkReferenceDefinition)
    def := node as LinkReferenceDefinition
    verifyEq(label, def.label)
    return def
  }

  private Node parse(Str input) { Parser().parse(input) }
}
