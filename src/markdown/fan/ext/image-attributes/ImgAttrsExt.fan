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

  override Void extendRenderer(HtmlRendererBuilder builder)
  {
    builder.attrProviderFactory |HtmlContext cx->AttrProvider| { ImgAttrsAttrProvider() }
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
  override Void setAttrs(Node node, Str tagName, [Str:Str] attrs)
  {
    if (node is Image)
    {
      Node.eachChild(node) |c|
      {
        imgAttrs := c as ImgAttrs
        if (imgAttrs == null) return
        imgAttrs.attrs.each |v, k| { attrs[k] = v }
        // now that we have used the image attributes we remove the node
        imgAttrs.unlink
      }
    }
  }
}