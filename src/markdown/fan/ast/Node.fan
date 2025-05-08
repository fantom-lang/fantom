//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Oct 2024  Matthew Giannini  Creation
//

using util

**
** Base class for all CommonMark AST nodes.
**
** The CommonMark AST is a tree of nodes where each node
** can have any number of children and one parent - except
** the root node which has no parent.
**
@Js
abstract class Node
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make()
  {
  }

  ** The parent node or null if this is the root of the AST
  virtual Node? parent() { this.p }

  ** Used by sub-classes to set or clear this node's parent
  protected virtual Void setParent(Node? p) { this.p = p }

  ** Private storage for parent
  private Node? p

  ** Get the root `Document` node or null if this node is mounted in a document yet
  Document? doc()
  {
    Node? n := this
    while(n != null && n isnot Document) n = n.parent
    return n
  }

  Node? next { private set }

  Node? prev { private set }

  Node? firstChild { private set }

  Node? lastChild { private set }

  SourceSpan[] sourceSpans := SourceSpan[,] { private set }

  ** Get the file location for this node from the original parsed source.
  ** If the location is not known or source spans were not enabled during
  ** parsing, then return `FileLoc.unknown`.
  FileLoc loc()
  {
    if (sourceSpans.isEmpty) return FileLoc.unknown
    file := doc?.file?.name ?: "inputs"
    span := sourceSpans.first
    // I think if the best way to report the location is using the first source span
    return FileLoc(file, span.lineIndex+1, span.columnIndex+1)
  }

  ** Walk the AST using the given visitor. By default, we use reflection
  ** to call 'visitor.visit${this.typeof.name}'
  virtual Void walk(Visitor visitor)
  {
    // This allows visitor sub-classes to have custom 'visit<CustomBlockorNode>()' methods
    method := visitor.typeof.method("visit${this.typeof.name}", false)
    if (method != null) method.callOn(visitor, [this])
    else
    {
      // otherwise default back to calling generic visitors for custom nodes
      if (this is CustomNode) visitor.visitCustomNode(this)
      else if (this is CustomBlock) visitor.visitCustomBlock(this)
      // else throw ArgErr("no visit method found for ${this.typeof}")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Tree modification
//////////////////////////////////////////////////////////////////////////

  ** Insert the child node as the last child node of this node.
  This appendChild(Node child)
  {
    child.unlink
    child.setParent(this)
    if (this.lastChild != null)
    {
      this.lastChild.next = child
      child.prev = this.lastChild
      this.lastChild = child
    }
    else
    {
      this.firstChild = child
      this.lastChild = child
    }
    return this
  }

  ** Completely detach this node from the AST
  Void unlink()
  {
    if (this.prev != null)
      this.prev.next = this.next
    else if (this.parent != null)
      this.parent.firstChild = this.next

    if (this.next != null)
      this.next.prev = this.prev
    else if (this.parent != null)
      this.parent.lastChild = this.prev

    this.p    = null
    this.next = null
    this.prev = null
  }

  ** Inserts the sibling node after this node
  Void insertAfter(Node sibling)
  {
    sibling.unlink
    sibling.next = this.next
    if (sibling.next != null) sibling.next.prev = sibling
    sibling.prev = this
    this.next = sibling
    sibling.p = this.parent
    if (sibling.next == null) sibling.parent.lastChild = sibling
  }

  ** Inserts the sibiling node before this node
  Void insertBefore(Node sibling)
  {
    sibling.unlink
    sibling.prev = this.prev
    if (sibling.prev != null) sibling.prev.next = sibling
    sibling.next = this
    this.prev = sibling
    sibling.p = this.parent
    if (sibling.prev == null) sibling.parent.firstChild = sibling
  }

  ** Add a source span to the end of the list. If it is null, this is a no-op
  Void addSourceSpan(SourceSpan? sourceSpan)
  {
    if (sourceSpan == null) return
    // Err("addSourceSpan").trace
    this.sourceSpans.add(sourceSpan)
  }

  ** Replace the current source spans with the provided list
  Void setSourceSpans(SourceSpan[] sourceSpans)
  {
    // Err("setSourceSpans").trace
    this.sourceSpans = sourceSpans.dup
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  ** Get nodes between start (exclusive) and end (exclusive) by iterating
  ** siblings of the start node.
  **
  ** pre>
  ** // A -> B -> C-> D-> E
  **         |->B1    |-> D1
  **         |->B2
  **
  ** Node.eachBetween(A, D, f)    => f(B), f(C)
  ** Node.eachBetween(B, null, f) => f(C), f(D), f(E)
  ** <pre
  static Void eachBetween(Node start, Node? end, |Node| f)
  {
    Node? node := start.next
    while (node != null && node !== end)
    {
      // need to stash next in case it gets modified by f()
      next := node.next
      f(node)
      node = next
    }
  }

  ** Get all the direct children of this node
  Node[] children()
  {
    acc := Node[,]
    for (child := this.firstChild; child != null; child = child.next) acc.add(child)
    return acc
  }

  ** Invoke the callback on each direct child of this node
  Void eachChild(|Node| f)
  {
    for (child := this.firstChild; child != null; child = child.next) f(child)
  }

  ** Recursively try to find a node with the given type within the children
  ** of this node. If checked, throw an error if the node could not be found;
  ** otherwise return null.
  Node? find(Type nodeType, Bool checked := true)
  {
    n := tryFind(this, nodeType)
    if (n != null) return n
    if (checked) throw Err("${nodeType} not found")
    return null
  }

  ** Recursively find all children of this node for which the callback returns true
  Node[] findAll(|Node->Bool| f)
  {
    acc := Node[,]
    eachDescendant |node|
    {
      if (f(node)) acc.add(node)
    }
    return acc
  }

  ** Recursively try to find a node with the given type within the children of the
  ** specified node.
  private Node? tryFind(Node parent, Type nodeType)
  {
    node := parent.firstChild
    while (node != null)
    {
      next := node.next
      if (node.typeof.fits(nodeType)) return node
      result := tryFind(node, nodeType)
      if (result != null) return result
      node = next
    }
    return null
  }

  ** Recursively walk the descendants of this node using a depth-first search and
  ** invoke the callback on each node.
  Void eachDescendant(|Node| f)
  {
    node := this.firstChild
    while (node != null)
    {
      saveNext := node.next
      f(node)
      node.eachDescendant(f)
      node = saveNext
    }
  }

  ** Dump the node tree to given output stream
  @NoDoc static Void dumpTree(Node node, OutStream out := Env.cur.out, Int indent := 0)
  {
    sp := " " * indent
    out.writeChars("${sp}${node} ${node.loc}\n")
    child := node.firstChild
    while (child != null)
    {
      dumpTree(child, out, indent + 2)
      child = child.next
    }
  }
  /* JAVA version
    private void tree(Node node) { tree(node, 0); }
    private void tree(Node node, int indent)
    {
        String sp = " ".repeat(indent);
        System.out.println(sp + node);
        Node child = node.getFirstChild();
        while (child != null) {
            tree(child, indent + 2);
            child = child.getNext();
        }
    }
    */

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  override Str toStr() { "${typeof.name}{${toStrAttributes}}" }

  virtual protected Str toStrAttributes() { "" }
}

**************************************************************************
** HardLineBreak
**************************************************************************

** Hard line break
@Js
class HardLineBreak : Node { }

**************************************************************************
** SoftLineBreak
**************************************************************************

** Soft line break
@Js
class SoftLineBreak : Node { }

**************************************************************************
** Delimited
**************************************************************************

** A node that uses delimiters in the source form, e.g. '*bold*'
@Js
mixin Delimited
{
  ** Return the opening (beginning) delimiter, e.g. '*'
  abstract Str openingDelim()

  ** Return the closing (ending) delimiter, e.g. '*'
  abstract Str closingDelim()
}

**************************************************************************
** StrongEmphasis
**************************************************************************

** Strong emphasis
@Js
class StrongEmphasis : Node, Delimited
{
  new make(Str delimiter) { this.delimiter = delimiter }

  const Str delimiter

  override Str openingDelim() { delimiter }
  override Str closingDelim() { delimiter }
}

**************************************************************************
** Emphasis
**************************************************************************

** Emphasis
@Js
class Emphasis : Node, Delimited
{
  new make(Str delimiter) { this.delimiter = delimiter }

  const Str delimiter

  override Str openingDelim() { delimiter }
  override Str closingDelim() { delimiter }
}

**************************************************************************
** Text
**************************************************************************

** Text
@Js
class Text : Node
{
  new make(Str literal) { this.literal = literal }
  Str literal
  override protected Str toStrAttributes() { "literal=${literal}" }
}

**************************************************************************
** Code
**************************************************************************

** Code
@Js
class Code : Node
{
  new make(Str literal) { this.literal = literal }
  const Str literal
  override protected Str toStrAttributes() { "literal=${literal}" }
}

**************************************************************************
** HtmlInline
**************************************************************************

** HTML inline
@Js
class HtmlInline : Node
{
  new make (Str? literal := null) { this.literal = literal }
  Str? literal
}

**************************************************************************
** CustomNode
**************************************************************************

** Custom node
@Js
class CustomNode : Node { }
