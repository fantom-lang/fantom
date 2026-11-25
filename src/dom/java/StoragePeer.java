//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 2017  Andy Frank   Creation
//   24 Nov 2026  Brian Frank  Keep the values in memory
//

package fan.dom;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import fan.sys.*;

/**
 * StoragePeer keeps its values in memory for as long as its window.
 */
public class StoragePeer
{
  public static StoragePeer make(Storage fan)
  {
    return DomPeerFactory.factory().makeStorage(fan);
  }

  public long   size  (Storage self)                         { return map.size(); }
  public List   keys  (Storage self)                         { return List.make(Sys.StrType, map.keySet()); }
  public Object get   (Storage self, String key)             { return map.get(key); }
  public void   set   (Storage self, String key, Object val) { map.put(key, val); }
  public void   remove(Storage self, String key)             { map.remove(key); }
  public void   clear (Storage self)                         { map.clear(); }

  public String key(Storage self, long index)
  {
    return index < 0 || index >= map.size() ? null : (String)new ArrayList(map.keySet()).get((int)index);
  }

  private final LinkedHashMap map = new LinkedHashMap();   // Str:Obj
}
