//
// Copyright (c) 2018, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Nov 2018  Andy Frank  Creation
//

package fan.dom;

import java.util.ArrayList;

public class QuerySelector
{
  /* Parse a query selector string */
  public static QuerySelector parse(String selectors)
  {
    QuerySelector q = new QuerySelector();

    String[] r = selectors.split("\\s");
    for (int i=0; i<r.length; i++)
    {
      String x = r[i];
      int len  = x.length();
      if (len > 0 && x.charAt(0) == '[' && x.charAt(len-1) == ']')
      {
        // one or more attribute selectors which must all match:
        // [name] or [name=value], where the value may be quoted
        String[] parts = x.substring(1,len-1).split("\\]\\[");
        ArrayList attrs = new ArrayList();
        for (int j=0; j<parts.length; j++)
        {
          String part = parts[j];
          int eq = part.indexOf('=');
          String name = eq < 0 ? part : part.substring(0, eq);
          String val  = eq < 0 ? null : unquote(part.substring(eq+1));
          attrs.add(new String[] { name, val });
        }
        q.attrs.add(attrs);
      }
    }

    return q;
  }

  private static String unquote(String s)
  {
    int len = s.length();
    if (len >= 2 && (s.charAt(0) == '"' || s.charAt(0) == '\'') && s.charAt(len-1) == s.charAt(0)) return s.substring(1, len-1);
    return s;
  }

  /* Does any of the attribute selectors match the attributes */
  public boolean matches(fan.sys.Map elemAttrs)
  {
    for (int i=0; i<attrs.size(); i++)
    {
      ArrayList all = (ArrayList)attrs.get(i);
      boolean ok = true;
      for (int j=0; ok && j<all.size(); j++)
      {
        String[] a = (String[])all.get(j);
        String val = (String)elemAttrs.get(a[0]);
        ok = val != null && (a[1] == null || a[1].equals(val));
      }
      if (ok) return true;
    }
    return false;
  }

  public ArrayList classes = new ArrayList();
  public ArrayList attrs   = new ArrayList();
}