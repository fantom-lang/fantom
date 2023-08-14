//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Mar 2022  Brian Frank  Creation
//   10 Jun 2023 Kiera O'Flynn  Refactor to ES
//

/**
 * CanvasFontMetrics implements FontMetrics using HTML5 canvas TextMetrics.
 */
class CanvasFontMetrics extends graphics.FontMetrics {

  constructor() { super(); }
  typeof$() { return CanvasFontMetrics.type$; }

  init(cx)
  {
    const m = cx.measureText("Hg");
    this.#cx = cx
    this.#ascent =  Math.ceil(m.actualBoundingBoxAscent);
    this.#descent = Math.ceil(m.actualBoundingBoxDescent);
    this.#leading = Math.ceil(m.fontBoundingBoxAscent) - this.#ascent;
    this.#height = this.#leading + this.#ascent + this.#descent;
    return this;
  }

  #cx;
  #ascent;
  #descent;
  #leading;
  #height;

  height()   { return this.#height; }
  leading()  { return this.#leading; }
  ascent()   { return this.#ascent; }
  descent()  { return this.#descent; }
  width(str) { return this.#cx.measureText(str).width; }

}