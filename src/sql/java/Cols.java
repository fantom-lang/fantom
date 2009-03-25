//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Jul 07  Brian Frank  Creation
//
package fan.sql;

import java.util.HashMap;
import fan.sys.List;

public class Cols
{

  Cols(List list)
  {
    this.list = list.ro();
  }

  Col get(String name)
  {
    if (map == null)
    {
      map = new HashMap();
      for (int i=0; i<list.sz(); ++i)
      {
        Col col = (Col)list.get(i);
        map.put(col.name, col);
      }
    }
    return (Col)map.get(name);
  }

  public final List list;
  private HashMap map;
}