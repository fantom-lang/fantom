//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Nov 2026  Brian Frank  Creation
//

package fan.dom;

import java.util.ArrayList;
import java.util.HashSet;
import fan.sys.*;

/**
 * HtmlParser parses markup into the children of an element as a
 * browser does when 'innerHTML' is assigned.  It handles what well
 * formed markup needs and none of the error recovery of HTML5:
 *   - an element takes the namespace of its parent; 'svg' opens SVG
 *     and the children of 'foreignObject' are HTML again
 *   - an HTML name is lower case; an SVG name is kept as written
 *   - an HTML void element has no end tag, and '/>' closes only an
 *     SVG element
 *   - an end tag closes the nearest open element of its name
 *   - a comment is dropped
 *   - the content of 'script' and 'style' is not treated as raw text
 */
class HtmlParser
{
  static void parse(Elem parent, String src)
  {
    new HtmlParser(src).parse(parent);
  }

  private HtmlParser(String src) { this.src = src; }

  private void parse(Elem parent)
  {
    stack.add(parent);
    while (pos < src.length())
    {
      if (src.startsWith("<!--", pos)) comment();
      else if (isTag(pos, 1)) startTag();
      else if (src.startsWith("</", pos) && isTag(pos, 2)) endTag();
      else text();
    }
  }

  // is the char at this offset from a '<' the start of a tag name
  private boolean isTag(int at, int off)
  {
    return src.charAt(at) == '<' && at+off < src.length() && Character.isLetter(src.charAt(at+off));
  }

  private void comment()
  {
    int end = src.indexOf("-->", pos+4);
    if (end < 0) end = src.length();
    cur().add(DomComment.make(src.substring(pos+4, end)));
    pos = Math.min(end+3, src.length());
  }

  private void text()
  {
    int start = pos++;
    while (pos < src.length() && !(src.charAt(pos) == '<' && (isTag(pos, 1) || src.startsWith("</", pos) || src.startsWith("<!--", pos)))) pos++;
    cur().add(DomText.make(decode(src.substring(start, pos))));
  }

  private void startTag()
  {
    pos++;
    Elem parent = cur();
    String name = name();
    boolean svg = name.equals("svg") || (isSvg(parent) && !parent.tagName().equals("foreignObject"));
    Elem elem = Elem.make(svg ? name : name.toLowerCase(), svg ? svgns : null);

    boolean selfClosed = false;
    while (true)
    {
      skipSpace();
      if (pos >= src.length()) break;
      char c = src.charAt(pos);
      if (c == '>') { pos++; break; }
      if (c == '/') { pos++; selfClosed = true; continue; }
      selfClosed = false;
      attr(elem, svg);
    }

    parent.add(elem);
    boolean closed = svg ? selfClosed : voidTags.contains(elem.tagName());
    if (!closed) stack.add(elem);
  }

  private void attr(Elem elem, boolean svg)
  {
    int start = pos;
    while (pos < src.length() && !isSpace(src.charAt(pos)) && "=>/".indexOf(src.charAt(pos)) < 0) pos++;
    if (pos == start) { pos++; return; }
    String name = src.substring(start, pos);
    skipSpace();

    String val = "";
    if (pos < src.length() && src.charAt(pos) == '=')
    {
      pos++;
      skipSpace();
      char q = pos < src.length() ? src.charAt(pos) : '>';
      if (q == '"' || q == '\'')
      {
        int end = src.indexOf(q, pos+1);
        if (end < 0) end = src.length();
        val = src.substring(pos+1, end);
        pos = Math.min(end+1, src.length());
      }
      else
      {
        start = pos;
        while (pos < src.length() && !isSpace(src.charAt(pos)) && src.charAt(pos) != '>') pos++;
        val = src.substring(start, pos);
      }
    }
    elem.setAttr(svg ? name : name.toLowerCase(), decode(val));
  }

  private void endTag()
  {
    pos += 2;
    String name = name();
    int end = src.indexOf('>', pos);
    pos = end < 0 ? src.length() : end+1;

    // the root is the element assigned to, which markup cannot close
    for (int i=stack.size()-1; i>0; --i)
    {
      if (!stack.get(i).tagName().equalsIgnoreCase(name)) continue;
      while (stack.size() > i) stack.remove(stack.size()-1);
      return;
    }
  }

  private String name()
  {
    int start = pos;
    while (pos < src.length() && !isSpace(src.charAt(pos)) && "/>".indexOf(src.charAt(pos)) < 0) pos++;
    return src.substring(start, pos);
  }

  private void skipSpace()
  {
    while (pos < src.length() && isSpace(src.charAt(pos))) pos++;
  }

  private static boolean isSpace(char c) { return c == ' ' || c == '\n' || c == '\t' || c == '\r' || c == '\f'; }

  private static boolean isSvg(Elem elem) { return svgns.equals(elem.ns()); }

  private Elem cur() { return stack.get(stack.size()-1); }

  // decode the character references markup is written with; any
  // other is left as written
  private static String decode(String s)
  {
    if (s.indexOf('&') < 0) return s;
    StringBuilder buf = new StringBuilder(s.length());
    for (int i=0; i<s.length(); ++i)
    {
      char c = s.charAt(i);
      int semi = c == '&' ? s.indexOf(';', i) : -1;
      String ch = semi < 0 ? null : charRef(s.substring(i+1, semi));
      if (ch == null) { buf.append(c); continue; }
      buf.append(ch);
      i = semi;
    }
    return buf.toString();
  }

  private static String charRef(String name)
  {
    if (name.equals("amp"))  return "&";
    if (name.equals("lt"))   return "<";
    if (name.equals("gt"))   return ">";
    if (name.equals("quot")) return "\"";
    if (name.equals("apos")) return "'";
    if (name.equals("nbsp")) return " ";
    try
    {
      if (name.startsWith("#x") || name.startsWith("#X")) return new String(Character.toChars(Integer.parseInt(name.substring(2), 16)));
      if (name.startsWith("#")) return new String(Character.toChars(Integer.parseInt(name.substring(1))));
    }
    catch (RuntimeException e) {}
    return null;
  }

  private static final Uri svgns = Uri.fromStr("http://www.w3.org/2000/svg");

  // HTML elements which have no content and no end tag
  static final HashSet<String> voidTags = new HashSet<String>();
  static
  {
    String[] tags = { "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr" };
    for (int i=0; i<tags.length; i++) voidTags.add(tags[i]);
  }

  private final String src;
  private int pos;
  private final ArrayList<Elem> stack = new ArrayList<Elem>();
}
