//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Feb 2023  Brian Frank  Creation
//

package fan.dom;

import fan.sys.*;

public class HttpReqPeer
{
  public static HttpReqPeer make(HttpReq fan)
  {
    return DomPeerFactory.factory().makeHttpReq(fan);
  }

  public void   send      (HttpReq self, String method, Object content, Func c) { throw err(); }
  public String encodeForm(HttpReq self, Map form)                              { throw err(); }

  private static Err err() { return UnsupportedErr.make(); }
}