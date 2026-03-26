//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 2017  Andy Frank  Creation
//   10 Jun 2023  Kiera O'Flynn  Refactor to ES
//

class DomCoordPeer extends sys.Obj {

  constructor(self) { super(); }

  static wrap(pos)
  {
    let x = DomCoord.make();
    x.peer.$coords = pos.coords;
    x.peer.$ts = pos.timestamp ? sys.Duration.fromStr(""+pos.timestamp+"ms") : null;
    return x;
  }

  $coords;
  $ts;

  lat(self)              { return this.$coords.latitude;  }
  lng(self)              { return this.$coords.longitude; }
  accuracy(self)         { return this.$coords.accuracy;  }
  altitude(self)         { return this.$coords.altitude; }
  altitudeAccuracy(self) { return this.$coords.altitudeAccuracy; }
  heading(self)          { return this.$coords.heading; }
  speed(self)            { return this.$coords.speed; }
  ts(self)               { return this.$ts; }
}