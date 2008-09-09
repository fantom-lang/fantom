//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Jul 08  Andy Frank  Creation
//

using web
using webapp

class GridPane : Widget
{

  override Void onGet()
  {
    body.table
    each |Widget w, Int i|
    {
      body.tr
      body.td; w.onGet; body.tdEnd
      body.trEnd
    }
    body.tableEnd
  }

  Int numCols := 1

}