//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 2017  Andy Frank   Creation
//   24 Nov 2026  Brian Frank  Keep the data in memory
//

package fan.dom;

import java.util.LinkedHashMap;
import fan.sys.*;

/**
 * DataTransferPeer is the JVM implementation of DataTransfer.  The
 * drag data is kept in memory.  Files and drag images are not
 * supported.
 */
public class DataTransferPeer
{
  public static DataTransferPeer make(DataTransfer fan)
  {
    return DomPeerFactory.factory().makeDataTransfer(fan);
  }

  public String dropEffect(DataTransfer self) { return dropEffect; }
  public void dropEffect(DataTransfer self, String dropEffect) { this.dropEffect = dropEffect; }

  public String effectAllowed(DataTransfer self) { return effectAllowed; }
  public void effectAllowed(DataTransfer self, String effectAllowed) { this.effectAllowed = effectAllowed; }

  public List types(DataTransfer self) { return List.make(Sys.StrType, data.keySet()); }

  public String getData(DataTransfer self, String type)
  {
    String val = (String)data.get(type);
    return val == null ? "" : val;
  }

  public DataTransfer setData(DataTransfer self, String type, String val)
  {
    data.put(type, val);
    return self;
  }

  public DataTransfer setDragImage(DataTransfer self, Elem image, long x, long y) { return self; }

  public List files(DataTransfer self) { return List.make(Type.find("dom::DomFile"), 0); }

  private String dropEffect = "none";
  private String effectAllowed = "uninitialized";
  private final LinkedHashMap data = new LinkedHashMap();   // Str:Str
}
