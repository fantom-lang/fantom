//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Feb 2023  Brian Frank  Creation
//

package fan.dom;

public class StoragePeer
{
  public static StoragePeer make(Storage fan)
  {
    return DomPeerFactory.factory().makeStorage(fan);
  }
}