//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 2017  Andy Frank  Creation
//

package fan.dom;

import fan.sys.*;

public class EventPeer
{
  public static EventPeer make(Event fan)
  {
    return DomPeerFactory.factory().makeEvent(fan);
  }

  static public Event fromNative(Object event)
  {
    return DomPeerFactory.factory().eventFromNative(event);
  }

  public String       type        (Event self)                          { throw err(); }
  public Elem         target      (Event self)                          { throw err(); }
  public boolean      alt         (Event self)                          { throw err(); }
  public boolean      ctrl        (Event self)                          { throw err(); }
  public boolean      shift       (Event self)                          { throw err(); }
  public boolean      meta        (Event self)                          { throw err(); }
  public Long         button      (Event self)                          { throw err(); }
  public Key          key         (Event self)                          { throw err(); }
  public Err          err         (Event self)                          { throw err(); }
  public void         stop        (Event self)                          { throw err(); }
  public Object       get         (Event self, String name, Object def) { throw err(); }
  public void         set         (Event self, String name, Object val) { throw err(); }
  public Object       data        (Event self)                          { throw err(); }
  public DataTransfer dataTransfer(Event self)                          { throw err(); }

// cannot compile against "graphics" pod - see https://fantom.org/forum/topic/2886
// public Point       pagePos     (Event self)                          { throw err(); }
// public Point       delta       (Event self)                          { throw err(); }

  private static Err err() { return UnsupportedErr.make(); }
}