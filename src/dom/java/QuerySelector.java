//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 2017  Andy Frank   Creation
//   24 Nov 2026  Brian Frank  Selector lists, combinators and pseudo-classes
//

package fan.dom;

import java.util.ArrayList;
import fan.sys.*;

/**
 * QuerySelector parses a CSS selector list and matches it against
 * elements.  It supports tag, id, class and attribute selectors, the
 * structural pseudo-classes, and the descendant, child and sibling
 * combinators.  An unsupported selector raises ArgErr instead of
 * silently matching nothing.
 */
public class QuerySelector
{

//////////////////////////////////////////////////////////////////////////
// Public
//////////////////////////////////////////////////////////////////////////

  /** Parse a selector list such as "div.a > [x=y], li:first-child" */
  public static QuerySelector parse(String selectors)
  {
    return new Parser(selectors).parseList(false);
  }

  /** Return if any selector in the list matches the element.  The
      scope is the element the query was called on, which is what
      :scope matches */
  public boolean matches(Elem elem, Elem scope)
  {
    for (int i=0; i<list.size(); i++)
      if (((Complex)list.get(i)).matches(elem, scope)) return true;
    return false;
  }

  /** Find the matching descendants of parent in document order and
      add them to acc, stopping once acc reaches the limit */
  public void findAll(DomNode parent, Elem scope, ArrayList acc, int limit)
  {
    ArrayList kids = parent.peer.kids;
    for (int i=0; i<kids.size() && acc.size() < limit; i++)
    {
      if (!(kids.get(i) instanceof Elem)) continue;
      Elem kid = (Elem)kids.get(i);
      if (matches(kid, scope)) acc.add(kid);
      findAll(kid, scope, acc, limit);
    }
  }

  private final ArrayList list = new ArrayList();   // Complex

//////////////////////////////////////////////////////////////////////////
// Complex
//////////////////////////////////////////////////////////////////////////

  /** A list of compound selectors joined by combinators, such as
      "ul > li a" */
  static class Complex
  {
    boolean matches(Elem e, Elem scope) { return matchAt(e, scope, parts.size()-1); }

    // Match right to left.  The element must match the last compound;
    // then each combinator says where to look for the one before it
    private boolean matchAt(Elem e, Elem scope, int i)
    {
      if (!((Compound)parts.get(i)).matches(e, scope)) return false;
      if (i == 0) return true;
      switch (((Character)combs.get(i-1)).charValue())
      {
        case '>':
          Elem p = e.parent();
          return p != null && matchAt(p, scope, i-1);
        case ' ':
          for (Elem a = e.parent(); a != null; a = a.parent())
            if (matchAt(a, scope, i-1)) return true;
          return false;
        case '+':
          Elem s = e.prevSibling();
          return s != null && matchAt(s, scope, i-1);
        default:
          for (Elem b = e.prevSibling(); b != null; b = b.prevSibling())
            if (matchAt(b, scope, i-1)) return true;
          return false;
      }
    }

    final ArrayList parts = new ArrayList();   // Compound
    final ArrayList combs = new ArrayList();   // Character: ' ', '>', '+', '~'
  }

//////////////////////////////////////////////////////////////////////////
// Compound
//////////////////////////////////////////////////////////////////////////

  /** A list of simple selectors which must all match one element,
      such as "li.item[x]:first-child" */
  static class Compound
  {
    boolean matches(Elem e, Elem scope)
    {
      for (int i=0; i<simples.size(); i++)
        if (!((Simple)simples.get(i)).matches(e, scope)) return false;
      return true;
    }

    final ArrayList simples = new ArrayList();   // Simple
  }

//////////////////////////////////////////////////////////////////////////
// Simple
//////////////////////////////////////////////////////////////////////////

  static abstract class Simple
  {
    abstract boolean matches(Elem e, Elem scope);
  }

  /** Match a tag name, ignoring case like HTML does */
  static class Tag extends Simple
  {
    Tag(String name) { this.name = name; }
    boolean matches(Elem e, Elem scope) { return e.tagName().equalsIgnoreCase(name); }
    final String name;
  }

  static class HasClass extends Simple
  {
    HasClass(String name) { this.name = name; }
    boolean matches(Elem e, Elem scope) { return e.style().hasClass(name); }
    final String name;
  }

  /** [name], or [name op value] where op is one of = ~= |= ^= $= *= */
  static class Attr extends Simple
  {
    Attr(String name, String op, String val, boolean ignoreCase)
    {
      this.name = name; this.op = op; this.val = ignoreCase ? val.toLowerCase() : val; this.ignoreCase = ignoreCase;
    }

    boolean matches(Elem e, Elem scope)
    {
      String x = e.attr(name);
      if (x == null) return false;
      if (op == null) return true;
      if (ignoreCase) x = x.toLowerCase();
      switch (op.charAt(0))
      {
        case '=': return x.equals(val);
        case '~': return val.length() > 0 && (" " + x.replaceAll("\\s+", " ") + " ").contains(" " + val + " ");
        case '|': return x.equals(val) || x.startsWith(val + "-");
        case '^': return val.length() > 0 && x.startsWith(val);
        case '$': return val.length() > 0 && x.endsWith(val);
        default:  return val.length() > 0 && x.contains(val);
      }
    }

    final String name;
    final String op;     // null to test only that the attribute is there
    final String val;
    final boolean ignoreCase;
  }

  /** Match :not(list), :is(list) or :where(list) */
  static class Nested extends Simple
  {
    Nested(QuerySelector q, boolean negate) { this.q = q; this.negate = negate; }
    boolean matches(Elem e, Elem scope) { return q.matches(e, scope) != negate; }
    final QuerySelector q;
    final boolean negate;
  }

  /** Match :nth-child(an+b) or :nth-last-child(an+b).  Also used
      for :first-child and :last-child */
  static class Nth extends Simple
  {
    Nth(int a, int b, boolean fromEnd) { this.a = a; this.b = b; this.fromEnd = fromEnd; }

    boolean matches(Elem e, Elem scope)
    {
      int i = 1;
      for (Elem s = sibling(e); s != null; s = sibling(s)) i++;
      if (a == 0) return i == b;
      return (i - b) % a == 0 && (i - b) / a >= 0;
    }

    private Elem sibling(Elem e) { return fromEnd ? e.nextSibling() : e.prevSibling(); }

    final int a;
    final int b;
    final boolean fromEnd;
  }

  /** Match a pseudo-class which has no argument, such as :checked */
  static class Pseudo extends Simple
  {
    Pseudo(String name) { this.name = name; }

    boolean matches(Elem e, Elem scope)
    {
      if (name.equals("scope"))    return e == scope;
      if (name.equals("root"))     return e.parent() == null;
      if (name.equals("empty"))    return isEmpty(e);
      if (name.equals("checked"))  return isChecked(e);
      if (name.equals("disabled")) return e.attr("disabled") != null;
      if (name.equals("enabled"))  return e.attr("disabled") == null;
      if (name.equals("focus"))    return DomFuncs.hasFocus(e);
      if (name.equals("popover-open")) return e.peer.popoverOpen;
      if (name.equals("modal"))    return e.peer.modal;
      DocPeer doc = DocPeer.of(e);   // focus-within
      return doc != null && doc.active != null && e.containsChild(doc.active);
    }

    // use the checked property if it has been set, else the attribute
    private static boolean isChecked(Elem e)
    {
      Object v = e.prop("checked");
      return v instanceof Boolean ? ((Boolean)v).booleanValue() : v != null;
    }

    private static boolean isEmpty(Elem e)
    {
      ArrayList kids = e.peer.kids;
      for (int i=0; i<kids.size(); i++)
      {
        DomNode kid = (DomNode)kids.get(i);
        if (kid instanceof Elem || kid.text().length() > 0) return false;
      }
      return true;
    }

    static boolean isKnown(String name)
    {
      return name.equals("scope") || name.equals("root") || name.equals("empty") ||
             name.equals("checked") || name.equals("disabled") || name.equals("enabled") ||
             name.equals("focus") || name.equals("focus-within") || name.equals("popover-open") ||
             name.equals("modal");
    }

    final String name;
  }

//////////////////////////////////////////////////////////////////////////
// Parser
//////////////////////////////////////////////////////////////////////////

  static class Parser
  {
    Parser(String src) { this.src = src; }

    // Parse: complex (',' complex)*
    // A nested list is the argument of a pseudo-class and ends at
    // its ')'; otherwise the list ends at the end of the source
    QuerySelector parseList(boolean nested)
    {
      QuerySelector q = new QuerySelector();
      while (true)
      {
        skipSpace();
        q.list.add(complex());
        skipSpace();
        if (cur() == ',') { pos++; continue; }
        if (nested ? cur() == ')' : cur() == 0) return q;
        throw err("unexpected '" + cur() + "'");
      }
    }

    private Complex complex()
    {
      Complex c = new Complex();
      c.parts.add(compound());
      while (true)
      {
        boolean space = skipSpace();
        char ch = cur();
        if (ch == 0 || ch == ',' || ch == ')') return c;
        if (ch == '>' || ch == '+' || ch == '~') { pos++; skipSpace(); c.combs.add(Character.valueOf(ch)); }
        else if (space) c.combs.add(Character.valueOf(' '));
        else throw err("unexpected '" + ch + "'");
        c.parts.add(compound());
      }
    }

    private Compound compound()
    {
      Compound c = new Compound();
      int start = pos;
      if (cur() == '*') pos++;
      else if (isIdent(cur())) c.simples.add(new Tag(ident()));
      while (true)
      {
        char ch = cur();
        if (ch == '#') { pos++; c.simples.add(new Attr("id", "=", ident(), false)); }
        else if (ch == '.') { pos++; c.simples.add(new HasClass(ident())); }
        else if (ch == '[') { pos++; c.simples.add(attr()); }
        else if (ch == ':') { pos++; c.simples.add(pseudo()); }
        else break;
      }
      if (pos == start) throw err(cur() == 0 ? "unexpected end" : "unexpected '" + cur() + "'");
      return c;
    }

    // Parse: name | name op value ('i' | 's')?
    private Attr attr()
    {
      skipSpace();
      String name = ident();
      skipSpace();
      if (cur() == ']') { pos++; return new Attr(name, null, "", false); }

      String op = "=";
      if (cur() != '=')
      {
        if ("~|^$*".indexOf(cur()) < 0 || peek() != '=') throw err("expected attribute operator");
        op = String.valueOf(cur());
        pos++;
      }
      pos++;
      skipSpace();
      String val = cur() == '"' || cur() == '\'' ? quoted() : ident();
      boolean space = skipSpace();
      boolean ignoreCase = false;
      if (space && (cur() == 'i' || cur() == 'I' || cur() == 's' || cur() == 'S'))
      {
        ignoreCase = cur() == 'i' || cur() == 'I';
        pos++;
        skipSpace();
      }
      if (cur() != ']') throw err("expected ']'");
      pos++;
      return new Attr(name, op, val, ignoreCase);
    }

    private Simple pseudo()
    {
      if (cur() == ':') throw err("pseudo-elements are not supported");
      String name = ident().toLowerCase();
      if (cur() != '(')
      {
        if (name.equals("first-child")) return new Nth(0, 1, false);
        if (name.equals("last-child"))  return new Nth(0, 1, true);
        if (name.equals("only-child"))  return only();
        if (Pseudo.isKnown(name))       return new Pseudo(name);
        throw err("pseudo-class :" + name + " is not supported");
      }

      pos++;
      Simple x;
      if (name.equals("not")) x = new Nested(parseList(true), true);
      else if (name.equals("is") || name.equals("where")) x = new Nested(parseList(true), false);
      else if (name.equals("nth-child")) x = nth(false);
      else if (name.equals("nth-last-child")) x = nth(true);
      else throw err("pseudo-class :" + name + "() is not supported");
      if (cur() != ')') throw err("expected ')'");
      pos++;
      return x;
    }

    private Simple only()
    {
      QuerySelector q = new QuerySelector();
      Complex c = new Complex();
      Compound both = new Compound();
      both.simples.add(new Nth(0, 1, false));
      both.simples.add(new Nth(0, 1, true));
      c.parts.add(both);
      q.list.add(c);
      return new Nested(q, false);
    }

    // Parse the argument of nth-child: odd, even, a number, or an+b
    private Nth nth(boolean fromEnd)
    {
      int start = pos;
      while (cur() != ')' && cur() != 0) pos++;
      String s = src.substring(start, pos).replaceAll("\\s+", "").toLowerCase();
      if (s.equals("odd"))  return new Nth(2, 1, fromEnd);
      if (s.equals("even")) return new Nth(2, 0, fromEnd);
      try
      {
        int n = s.indexOf('n');
        if (n < 0) return new Nth(0, Integer.parseInt(s), fromEnd);
        String a = s.substring(0, n);
        String b = s.substring(n+1);
        int an = a.equals("") || a.equals("+") ? 1 : (a.equals("-") ? -1 : Integer.parseInt(a));
        return new Nth(an, b.equals("") ? 0 : Integer.parseInt(b.startsWith("+") ? b.substring(1) : b), fromEnd);
      }
      catch (NumberFormatException e) { throw err("invalid nth '" + s + "'"); }
    }

    // Parse a name.  A backslash escapes the next char, for example
    // the colon in the class "hover\:underline"
    private String ident()
    {
      StringBuilder s = new StringBuilder();
      while (true)
      {
        char ch = cur();
        if (ch == '\\' && pos+1 < src.length()) { s.append(src.charAt(pos+1)); pos += 2; }
        else if (isIdent(ch)) { s.append(ch); pos++; }
        else break;
      }
      if (s.length() == 0) throw err(cur() == 0 ? "unexpected end" : "expected name, not '" + cur() + "'");
      return s.toString();
    }

    private String quoted()
    {
      char quote = cur();
      pos++;
      StringBuilder s = new StringBuilder();
      while (cur() != quote)
      {
        if (cur() == 0) throw err("unclosed quote");
        if (cur() == '\\' && pos+1 < src.length()) pos++;
        s.append(cur());
        pos++;
      }
      pos++;
      return s.toString();
    }

    private static boolean isIdent(char ch)
    {
      return Character.isLetterOrDigit(ch) || ch == '-' || ch == '_';
    }

    private boolean skipSpace()
    {
      int start = pos;
      while (pos < src.length() && Character.isWhitespace(src.charAt(pos))) pos++;
      return pos > start;
    }

    private char cur() { return pos < src.length() ? src.charAt(pos) : 0; }

    private char peek() { return pos+1 < src.length() ? src.charAt(pos+1) : 0; }

    private Err err(String msg) { return ArgErr.make("Invalid selector '" + src + "': " + msg); }

    private final String src;
    private int pos;
  }
}
