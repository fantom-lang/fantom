//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Oct 2024  Matthew Giannini  Creation
//

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

  Node? next { private set }

  Node? prev { private set }

  Node? firstChild { private set }

  Node? lastChild { private set }

  SourceSpan[]? sourceSpans := null
  {
    get
    {
      &sourceSpans == null ? SourceSpan#.emptyList : &sourceSpans.toImmutable
    }
    private set
  }

  ** Walk the AST using the given visitor. By default, we use reflection
  ** to call 'visitor.visit${this.typeof.name}'
  virtual Void walk(Visitor visitor)
  {
    method := visitor.typeof.method("visit${this.typeof.name}", false)
    if (method == null) throw ArgErr("no visit method found for ${this.typeof}")
    method.callOn(visitor, [this])
    return visitor
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

  ** Add a source span to the end of the list
  Void addSourceSpan(SourceSpan sourceSpan)
  {
    if (sourceSpans == null) sourceSpans = SourceSpan[,]
    sourceSpans.add(sourceSpan)
  }

  ** Replace the current source spans with the provided list
  Void setSourceSpans(SourceSpan[] sourceSpans)
  {
    this.sourceSpans = sourceSpans.isEmpty ? null : sourceSpans.dup
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  ** Get nodes between start (exclusive) and end (exclusive)
  static Void eachBetween(Node start, Node end, |Node| f)
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

  ** Get all the children of the given parent node
  static Node[] children(Node parent)
  {
    acc := Node[,]
    for (child := parent.firstChild; child != null; child = child.next) acc.add(child)
    return acc
  }

  ** Recursively try to find a node with the given type within the children
  ** of the specified node. Throw if node could not be found
  static Node find(Node parent, Type nodeType)
  {
    tryFind(parent, nodeType) ?: throw Err("${nodeType} not found")
  }

  ** Recursively try to find a node with the given type within the children of the
  ** specified node.
  static Node? tryFind(Node parent, Type nodeType)
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

  ** Dump the node tree to given output stream
  @NoDoc static Void dumpTree(Node node, OutStream out := Env.cur.out, Int indent := 0)
  {
    sp := " " * indent
    out.writeChars("${sp}${node}\n")
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
