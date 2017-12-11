//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 2017  Andy Frank  Creation
//

fan.dom.DomCoordPeer = fan.sys.Obj.$extend(fan.sys.Obj);
fan.dom.DomCoordPeer.prototype.$ctor = function() {}
fan.dom.DomCoordPeer.wrap = function(pos)
{
  var x = fan.dom.DomCoord.make();
  x.peer.m_coords = pos.coords;
  x.peer.m_ts = pos.timestamp ? fan.sys.Duration.fromStr(""+pos.timestamp+"ms") : null;
  return x;
}
fan.dom.DomCoordPeer.prototype.lat              = function() { return this.m_coords.latitude;  }
fan.dom.DomCoordPeer.prototype.lng              = function() { return this.m_coords.longitude; }
fan.dom.DomCoordPeer.prototype.accuracy         = function() { return this.m_coords.accuracy;  }
fan.dom.DomCoordPeer.prototype.altitude         = function() { return this.m_coords.altitude; }
fan.dom.DomCoordPeer.prototype.altitudeAccuracy = function() { return this.m_coords.altitudeAccuracy; }
fan.dom.DomCoordPeer.prototype.heading          = function() { return this.m_coords.heading; }
fan.dom.DomCoordPeer.prototype.speed            = function() { return this.m_coords.speed; }
fan.dom.DomCoordPeer.prototype.ts               = function() { return this.m_ts; }
