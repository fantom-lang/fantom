//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Feb 2023  Steve Eynon  Creation
//

package fan.dom;

import fan.sys.*;

public class DomFilePeer
{
  public static DomFilePeer make(DomFile fan)
  {
    return DomPeerFactory.factory().makeDomFile(fan);
  }

  public String name         (DomFile self)                         { throw err(); }
  public long   size         (DomFile self)                         { throw err(); }
  public String type         (DomFile self)                         { throw err(); }
  public void   readAsDataUri(DomFile self, Func fn)                { throw err(); }
  public void   readAsText   (DomFile self, Func fn)                { throw err(); }

  private static Err err() { return UnsupportedErr.make(); }
}
