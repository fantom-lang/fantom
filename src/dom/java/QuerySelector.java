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
      if (x.charAt(0) == '[' && x.charAt(len-1) == ']')
      {
        q.attrs.add(x.substring(1,len-1));
      }
    }

    return q;
  }

  public ArrayList classes = new ArrayList();
  public ArrayList attrs   = new ArrayList();
}