//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Mar 2022  Brian Frank  Creation
//   10 Jun 2023 Kiera O'Flynn  Refactor to ES
//

/**
 * CanvasGraphics implements Graphics using HTML5 canvas.
 */
class CanvasGraphics extends sys.Obj {

  constructor() { super(); }
  typeof$() { return CanvasGraphics.type$; }

  cx;

  // render
  static render(canvas, cb)
  {
    const cx = canvas.peer.elem.getContext("2d");
    const g = new CanvasGraphics();
    if (!canvas.peer.__inited)
    {
      // first time thru scale by half a pixel to avoid blurry lines
      canvas.peer.__inited = true;
      cx.translate(0.5, 0.5);
    }
    g.cx = cx;
    cb(g);
  }

  // Paint paint
  #paint = graphics.Color.black();
  paint(it)
  {
    if (it === undefined) return this.#paint;

    this.#paint = it;
    this.cx.fillStyle = it.asColorPaint().toStr();
    this.cx.strokeStyle = it.asColorPaint().toStr();
  }

  // Color color
  #color = graphics.Color.black();
  color(it)
  {
    if (it === undefined) return this.#color;

    this.#color = it;
    this.paint(it);
  }

  // Stroke stroke
  #stroke = graphics.Stroke.defVal();
  stroke(it)
  {
    if (it === undefined) return this.#stroke;

    this.#stroke       = it;
    this.cx.lineWidth  = it.width();
    this.cx.lineCap    = it.cap().toStr();
    this.cx.lineJoin   = it.join() == graphics.StrokeJoin.radius() ? "round" : it.join().toStr();
    this.cx.setLineDash(this.#toStrokeDash(it.dash()));
  }

  #toStrokeDash(x)
  {
    if (x == null) return [];
    return graphics.GeomUtil.parseFloatList(x).__values();
  }

  // Float alpha
  #alpha = null;
  alpha(it)
  {
    if (it === undefined) return this.#alpha;

    this.#alpha = it;
    this.cx.globalAlpha = it;
  }

  // Font font
  #font = null;
  font(it)
  {
    if (it === undefined) return this.#font;

    this.#font = it;
    this.cx.font = it.toStr();
  }

  // FontMetrics metrics()
  metrics()
  {
    return new CanvasFontMetrics().init(this.cx);
  }

  // GraphicsPath path()
  path()
  {
    this.cx.beginPath();
    const path = new CanvasGraphicsPath();
    path.cx = this.cx;
    return path;
  }

  // This drawLine(Float x1, Float y1, Float x2, Float y2)
  drawLine(x1, y1, x2, y2)
  {
    this.cx.beginPath();
    this.cx.moveTo(x1, y1);
    this.cx.lineTo(x2, y2);
    this.cx.stroke();
    return this;
  }

  // This drawRect(Float x, Float y, Float w, Float h)
  drawRect(x, y, w, h)
  {
    this.cx.strokeRect(x, y, w, h);
    return this;
  }

  // This fillRect(Float x, Float y, Float w, Float h)
  fillRect(x, y, w, h)
  {
    this.cx.fillRect(x, y, w, h);
    return this;
  }

  // This clipRect(Float x, Float y, Float w, Float h)
  clipRect(x, y, w, h)
  {
    this.cx.beginPath();
    this.cx.rect(x, y, w, h)
    this.cx.clip();
    return this;
  }

  // This drawRoundRect(Float x, Float y, Float w, Float h, Float wArc, Float hArc)
  drawRoundRect(x, y, w, h, wArc, hArc)
  {
    this.pathRoundRect(x, y, w, h, wArc, hArc);
    this.cx.stroke();
    return this;
  }

  // This fillRoundRect(Float x, Float y, Float w, Float h, Float wArc, Float hArc)
  fillRoundRect(x, y, w, h, wArc, hArc)
  {
    this.pathRoundRect(x, y, w, h, wArc, hArc);
    this.cx.fill();
    return this;
  }

  // generate path for a rounded rectangle
  pathRoundRect(x, y, w, h, wArc, hArc)
  {
    this.cx.beginPath();
    this.cx.moveTo(x + wArc, y);
    this.cx.lineTo(x + w - wArc, y);
    this.cx.quadraticCurveTo(x + w, y, x + w, y + hArc);
    this.cx.lineTo(x + w, y + h - hArc);
    this.cx.quadraticCurveTo(x + w, y + h , x + w - wArc, y + h);
    this.cx.lineTo(x + wArc, y + h);
    this.cx.quadraticCurveTo(x, y + h , x, y + h - hArc);
    this.cx.lineTo(x, y + hArc);
    this.cx.quadraticCurveTo(x, y, x + wArc, y);
  }

  // This drawText(Str s, Float x, Float y)
  drawText(s, x, y)
  {
    this.cx.fillText(s, x, y);
    return this;
  }

  // This drawImage(Image img, Float x, Float y, Float w := img.w, Float h := img.h)
  drawImage(img, x, y, w, h)
  {
    if (w === undefined) w = img.w();
    if (h === undefined) h = img.h();
    this.cx.drawImage(img.peer.elem, x, y, w, h);
    return this;
  }

  // This drawImageRegion(Image img, Rect src, Rect dst)
  drawImageRegion(img, src, dst)
  {
    this.cx.drawImage(img.peer.elem,
      src.x(), src.y(), src.w(), src.h(),
      dst.x(), dst.y(), dst.w(), dst.h());
    return this;
  }

  // This translate(Float x, Float y)
  translate(x, y)
  {
    this.cx.translate(x, y);
    return this;
  }

  // This transform(Transform transform)
  transform(t)
  {
    this.cx.transform(t.a(), t.b(), t.c(), t.d(), t.e(), t.f());
    return this;
  }

  // This push(Rect? r := null)
  push(r)
  {
    this.cx.save();
    if (r !== undefined && r !== null)
    {
      this.cx.beginPath();
      this.cx.translate(r.x(), r.y());
      this.cx.rect(0, 0, r.w(), r.h());
      this.cx.clip();
    }
    const state = {
      paint:  this.#paint,
      color:  this.#color,
      stroke: this.#stroke,
      alpha:  this.#alpha,
      font:   this.#font
    }
    this.#stack.push(state);
    return this;
  }

  // This pop()
  pop()
  {
    this.cx.restore();
    const state = this.#stack.pop();
    this.#paint  = state.paint;
    this.#color  = state.color;
    this.#stroke = state.stroke;
    this.#alpha  = state.alpha;
    this.#font   = state.font;
    return this;
  }

  // state for fields in push/pop
  #stack = new Array();

}