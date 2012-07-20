//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Jun 09  Andy Frank  Creation
//

using gfx
using fwt

**
** GMap embeds a GoogleMap in a widget.
**
@NoDoc
@Js
class GMap : ContentPane
{
  **
  ** Add a marker to place on the map.
  **
  native Void addMarker(Float lat, Float lng, Str? info := null)

  **
  ** Add a route to place on the map. List should be pairs of
  ** lat,lng coords.
  **
  native Void addRoute(Float[] route, Color? col := null)

  **
  ** The zoom level for this map.
  **
  Int zoom := 4

  **
  ** Type of map to display.
  **
  MapType mapType := MapType.roadMap

}

**
** Type of map to display for GMap.
**
@NoDoc
@Js
enum class MapType
{
  roadMap,
  satellite,
  hybrid,
  terrain
}

