//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Nov 2024  Matthew Giannini  Creation
//

**
** Extension for adding attributes to image nodes.
**
@Js
const class ImgAttrsExt : MarkdownExt
{
  override Void extendParser(ParserBuilder builder)
  {
    builder.customDelimiterProcessor(ImgAttrsDelimiterProcessor())
  }

  override Void extendHtml(HtmlRendererBuilder builder)
  {
    builder.attrProviderFactory |HtmlContext cx->AttrProvider| { ImgAttrsAttrProvider() }
  }

  override Void extendMarkdown(MarkdownRendererBuilder builder)
  {
    builder.nodeRendererFactory(|cx->NodeRenderer| { MarkdownImgAttrsRenderer(cx) })
  }
}

**************************************************************************
** ImgAttrs
**************************************************************************

@Js
class ImgAttrs : CustomNode, Delimited
{
  new make([Str:Str] attrs) { this.attrs = attrs }
  const [Str:Str] attrs

  override const Str openingDelim := "{"
  override const Str closingDelim := "}"

  override protected Str toStrAttributes() { "imgAttrs=${attrs}" }
}

**************************************************************************
** ImgAttrsDelimiterProcessor
**************************************************************************

@Js
internal const class ImgAttrsDelimiterProcessor : DelimiterProcessor
{
  private static const Str[] supported_attrs := ["width", "height"]

  override const Int openingChar := '{'

  override const Int closingChar := '}'

  override const Int minLen := 1

  override Int process(Delimiter openingRun, Delimiter closingRun)
  {
    if (openingRun.size != 1) return 0

    // check if the attributes can be applied - if the previous node is an image,
    // and if all the attributes are in the set of supported_attrs
    opener := openingRun.opener
    nodeToStyle := opener.prev
    if (nodeToStyle isnot Image) return 0

    toUnlink := Node[,]
    content := StrBuf()

    unsupported := false
    Node.eachBetween(opener, closingRun.closer) |node|
    {
      if (unsupported) return

      // only text nodes can be used for attributes
      if (node is Text)
      {
        content.add(((Text)node).literal)
        toUnlink.add(node)
      }
      else unsupported = true
    }
    if (unsupported) return 0

    attrs := [Str:Str][:] { ordered = true }
    res := content.toStr.split.eachWhile |s|
    {
      attr := s.split('=')
      if (attr.size > 1 && supported_attrs.contains(attr[0].lower))
      {
        attrs[attr[0]] = attr[1]
        return null
      }
      else
      {
        // attribute is unsupported
        return 0
      }
    }
    if (res != null) return 0

    // unlink the temp nodes
    toUnlink.each { it.unlink }

    if (!attrs.isEmpty)
    {
      nodeToStyle.appendChild(ImgAttrs(attrs))
    }

    return 1
  }
}

**************************************************************************
** ImgAttrsAttrProvider
**************************************************************************

@Js
internal class ImgAttrsAttrProvider : AttrProvider
{
  override Void setAttrs(Node node, Str tagName, [Str:Str?] attrs)
  {
    if (node is Image)
    {
      node.eachDescendant |c|
      {
        imgAttrs := c as ImgAttrs
        if (imgAttrs == null) return
        imgAttrs.attrs.each |v, k| { attrs[k] = v }

        // NOTE: the java implementation removes the node, but then the same
        // doc cannot be used for html and markdown rendering. not sure why
        // they do that. Gonna leave this commented out for now.

        // now that we have used the image attributes we remove the node
        // imgAttrs.unlink
      }
    }
  }
}

**************************************************************************
** MarkdownImgAttrsRenderer
**************************************************************************

@Js
internal class MarkdownImgAttrsRenderer : NodeRenderer, Visitor
{
  new make(MarkdownContext cx)
  {
    this.writer = cx.writer
  }

  private MarkdownWriter writer

  override const Type[] nodeTypes := [ImgAttrs#]

  override Void beforeRoot(Node root)
  {
    root.walk(this)
  }

  override Void afterRoot(Node root)
  {
    root.walk(this)
  }

  Void visitImgAttrs(ImgAttrs attrs)
  {
    if (attrs.parent is Image)
    {
      // if parent is an image, then this is pre-processing and we need to make
      // it the next sibling of the image so the attributes render correctly back
      // to markdown after the image is rendered
      img := attrs.parent
      attrs.unlink
      img.insertAfter(attrs)
    }
    else if (attrs.prev is Image)
    {
      // we are post-processing and want to put the node back as a child of the image
      // to try and preserve the original parsed AST
      img := attrs.prev
      attrs.unlink
      img.appendChild(attrs)
    }
  }


  override Void render(Node node)
  {
    attrs := node as ImgAttrs
    writer.raw(attrs.openingDelim)
    i := 0
    attrs.attrs.each |v,k|
    {
      if (i > 0) writer.raw(' ')
      writer.raw("${k}=${v}")
      ++i
    }
    writer.raw(attrs.closingDelim)
  }
}