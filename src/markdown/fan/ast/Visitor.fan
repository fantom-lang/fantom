//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Oct 2024  Matthew Giannini  Creation
//

**
** Node visitor
**
@Js
mixin Visitor
{
  virtual Void visitBlockQuote(BlockQuote node) { visitChildren(node) }
  virtual Void visitBulletList(BulletList node) { visitChildren(node) }
  virtual Void visitCode(Code node) { visitChildren(node) }
  virtual Void visitCustomBlock(CustomBlock node) { visitChildren(node) }
  virtual Void visitDocument(Document node) { visitChildren(node) }
  virtual Void visitEmphasis(Emphasis node) { visitChildren(node) }
  virtual Void visitFencedCode(FencedCode node) { visitChildren(node) }
  virtual Void visitHardLineBreak(HardLineBreak node) { visitChildren(node) }
  virtual Void visitHeading(Heading node) { visitChildren(node) }
  virtual Void visitHtmlBlock(HtmlBlock node) { visitChildren(node) }
  virtual Void visitHtmlInline(HtmlInline node) { visitChildren(node) }
  virtual Void visitImage(Image node) { visitChildren(node) }
  virtual Void visitIndentedCode(IndentedCode node) { visitChildren(node) }
  virtual Void visitLink(Link node) { visitChildren(node) }
  virtual Void visitListItem(ListItem node) { visitChildren(node) }
  virtual Void visitLinkReferenceDefinition(LinkReferenceDefinition node) { visitChildren(node) }
  virtual Void visitOrderedList(OrderedList node) { visitChildren(node) }
  virtual Void visitParagraph(Paragraph node) { visitChildren(node) }
  virtual Void visitSoftLineBreak(SoftLineBreak node) { visitChildren(node) }
  virtual Void visitStrongEmphasis(StrongEmphasis node) { visitChildren(node) }
  virtual Void visitText(Text node) { visitChildren(node) }
  virtual Void visitThematicBreak(ThematicBreak node) { visitChildren(node) }

  ** Visit the children nodes of the parent
  virtual protected Void visitChildren(Node parent)
  {
    // a sub-class might modify the node, resulting in next returning a different node
    // after visiting it. So get the next node before visiting
    node := parent.firstChild
    while (node != null)
    {
      saveNext := node.next
      node.walk(this)
      node = saveNext
    }
  }
}
