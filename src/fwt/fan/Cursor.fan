//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Mar 11  Yuri Strot  Creation
//
using gfx

**
** Mouse cursor.
**
@Js
const class Cursor
{

  **
  ** The platform-dependent default cursor. Often rendered as an arrow.
  **
  static const Cursor defVal := predefine("default")

  **
  ** The pointer that indicates a link.
  **
  static const Cursor pointer := predefine("pointer")

  **
  ** Indicates text that may be selected. Often rendered as a vertical I-beam.
  **
  static const Cursor text  := predefine("text")

  **
  ** The crosshair, e.g. short line segments resembling a "+" sign.
  **
  static const Cursor crosshair := predefine("crosshair")

  **
  ** Indicates the program is busy and the user should wait.
  ** Often rendered as a watch or hourglass.
  **
  static const Cursor wait := predefine("wait")

  **
  ** Indicates help is available for the object under the cursor.
  ** Often rendered as a question mark or a balloon.
  **
  static const Cursor help := predefine("help")

  **
  ** A progress indicator. The program is performing some processing, but is
  ** different from `wait` in that the user may still interact with the program.
  ** Often rendered as a spinning beach ball, or an arrow with a watch or hourglass.
  **
  static const Cursor progress := predefine("progress")

  **
  ** Indicates something is to be moved.
  **
  static const Cursor move := predefine("move")

  **
  ** Indicates that the requested action will not be carried out.
  ** Often rendered as a circle with a line through it.
  **
  static const Cursor notAllowed := predefine("not-allowed")

  **
  ** Indicates edge movement starts from the north corner of the box.
  **
  static const Cursor nResize := predefine("n-resize")

  **
  ** Indicates edge movement starts from the south corner of the box.
  **
  static const Cursor sResize := predefine("s-resize")

  **
  ** Indicates edge movement starts from the west corner of the box.
  **
  static const Cursor wResize := predefine("w-resize")

  **
  ** Indicates edge movement starts from the east corner of the box.
  **
  static const Cursor eResize := predefine("e-resize")

  **
  ** Indicates edge movement starts from the south-west corner of the box.
  **
  static const Cursor swResize := predefine("sw-resize")

  **
  ** Indicates edge movement starts from the south-east corner of the box.
  **
  static const Cursor seResize := predefine("se-resize")

  **
  ** Indicates edge movement starts from the north-west corner of the box.
  **
  static const Cursor nwResize := predefine("nw-resize")

  **
  ** Indicates edge movement starts from the north-east corner of the box.
  **
  static const Cursor neResize := predefine("ne-resize")

  **
  ** Make a custom cursor based on the image, describing the desired
  ** cursor appearance and the x and y coordinates of the position
  ** in the cursor's coordinate system (left/top relative) which
  ** represents the precise position that is being pointed to.
  **
  new make(Image image, Int x := 0, Int y := 0)
  {
    this.image = image;
    this.name  = image.toStr()
    this.x     = x
    this.y     = y
  }

  ** Create predefined cursor with specified name
  private new predefine(Str name) { this.name = name }

  **
  ** List of all predefined cursors.
  **
  static const Cursor[] predefined :=
  [
    defVal, pointer, text, crosshair, wait, help, progress, move, notAllowed,
    nResize, sResize, wResize, eResize, swResize, seResize, nwResize, neResize
  ]

  ** Cursor name
  internal const Str name

  ** Image associated with cursor
  internal const Image? image

  ** The x coordinate of the cursor's hotspot
  internal const Int x

  ** The y coordinate of the cursor's hotspot
  internal const Int y

  ** Return cursor name
  override Str toStr() { name }

}