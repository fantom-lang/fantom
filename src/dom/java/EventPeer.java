//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 2017  Andy Frank  Creation
//

package fan.dom;

public class EventPeer
{
  public static EventPeer make(Event fan)
  {
    return DomPeerFactory.factory().makeEvent(fan);
  }
}