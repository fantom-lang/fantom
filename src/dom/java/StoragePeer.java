//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Feb 2023  Brian Frank  Creation
//

package fan.dom;

import fan.sys.*;

public class StoragePeer
{
  public static StoragePeer make(Storage fan)
  {
    return DomPeerFactory.factory().makeStorage(fan);
  }

  public long   size  (Storage self)                         { throw err(); }
  public String key   (Storage self, long index)             { throw err(); }
  public Object get   (Storage self, String key)             { throw err(); }
  public void   set   (Storage self, String key, Object val) { throw err(); }
  public void   remove(Storage self, String key)             { throw err(); }
  public void   clear (Storage self)                         { throw err(); }

  private static Err err() { return UnsupportedErr.make(); }
}