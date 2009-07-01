//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jun 09  Andy Frank  Creation
//

package fan.fwt;

import javafx.scene.*;
import javafx.scene.paint.*;
import javafx.scene.shape.*;
import javafx.scene.text.*;
import javafx.stage.*;

/**
 * Canvas is used to emulate the <canvas> tag in IE using JavaFX.
 */

//////////////////////////////////////////////////////////////////////////
// Stage
//////////////////////////////////////////////////////////////////////////

var scene = Scene {};
Stage
{
  width:  100
  height: 100
  scene: scene
}

//////////////////////////////////////////////////////////////////////////
// Graphics Context
//////////////////////////////////////////////////////////////////////////

class Context
{
  var tx = 0.0;
  var ty = 0.0;
  var brush = Color.BLACK;
  var strokeWidth = 1.0;
}

//////////////////////////////////////////////////////////////////////////
// Buf
//////////////////////////////////////////////////////////////////////////

var buf: Node[];
var cx = Context {};

function init()
{
  buf = [];
  cx = Context {};
}

function commit()
{
  scene.content = buf;
}

//////////////////////////////////////////////////////////////////////////
// Graphics API
//////////////////////////////////////////////////////////////////////////

function setColor(css:String)
{
  cx.brush = Color.web(css);
}

function setPen(width:Number)
{
  cx.strokeWidth = width;
}

function drawLine(x1:Number, y1:Number, x2:Number, y2:Number)
{
  insert Line
  {
    startX: cx.tx + x1
    startY: cx.ty + y1
    endX:   cx.tx + x2
    endY:   cx.ty + y2
    stroke:      cx.brush
    strokeWidth: cx.strokeWidth
  } into buf
}

function fillRect(x, y, w, h)
{
}

function drawOval(x1, y1, x2, y2)
{
}

function translate(x:Number, y:Number)
{
  cx.tx += x;
  cx.ty += y;
}

