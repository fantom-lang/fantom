//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Feb 2023  Brian Frank  Creation
//

package fan.dom;

import fan.sys.*;

public class DataTransferPeer
{
  public static DataTransferPeer make(DataTransfer fan)
  {
    return DomPeerFactory.factory().makeDataTransfer(fan);
  }

  public String       dropEffect   (DataTransfer self)                             { throw err(); }
  public void         dropEffect   (DataTransfer self, String dropEffect)          { throw err(); }
  public String       effectAllowed(DataTransfer self)                             { throw err(); }
  public void         effectAllowed(DataTransfer self, String effectAllowed)       { throw err(); }
  public List         types        (DataTransfer self)                             { throw err(); }
  public String       getData      (DataTransfer self, String type)                { throw err(); }
  public DataTransfer setData      (DataTransfer self, String type, String val)    { throw err(); }
  public DataTransfer setDragImage (DataTransfer self, Elem image, long x, long y) { throw err(); }
  public List         files        (DataTransfer self)                             { throw err(); }

  private static Err err() { return UnsupportedErr.make(); }
}