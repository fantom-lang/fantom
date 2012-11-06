//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Jun 2009  Andy Frank  Creation
//

using gfx
using fwt

**************************************************************************
** GMap embeds a GoogleMap in a widget.
**************************************************************************
@NoDoc
@Js
class GMap : ContentPane
{
  ** Add a marker to place on the map.
  native Void addMarker(MapMarker marker)

  **
  ** Add a route to place on the map. List should be pairs of
  ** lat,lng coords.
  **
  native Void addRoute(Float[] route, Color? color := null)

  ** The zoom level for this map. Defaults to 4.
  native Int zoom

  ** Center point for this map. Value should be a single lat,lng
  ** pair.  Defaults to center of US.
  native Float[] center

  ** Configure map to automatically fit all markers/routes into
  ** view.  This may override `zoom` and `center` fields.
  Bool fitBounds := true

  ** Type of map to display.
  MapType mapType := MapType.roadMap
}

**************************************************************************
** Type of map to display for GMap.
**************************************************************************
@NoDoc
@Js
enum class MapType
{
  roadMap,
  satellite,
  hybrid,
  terrain
}

**************************************************************************
** Marker placed on maps.
**************************************************************************
@NoDoc
@Js
class MapMarker
{
  ** Constructor.
  new make(|This| f) { f(this) }

  ** Lat pos for marker.
  const Float lat

  ** Long pos for marker.
  const Float lng

  ** Marker color, or null for default.
  const Color? color := null

  ** HTML markup to display in InfoPopup when marker is clicked.
  const Str? infoHtml := null
}
