//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Oct 2017  Brian Frank  Creation
//

**
** DeviceContext models the target device for graphical rendering.
** Typically this maps to a display, image buffer, printer, or output
** format such as PDF.
**
@Js
const class DeviceContext
{
  ** Return default device context for the VM which is typically
  ** the primary display device.
  static DeviceContext cur() { curRef }

  ** Assume default DPI using the CSS pixel which is 1/96"
  private const static DeviceContext curRef := make(96f)

  ** Constructor
  @NoDoc new make(Float dpi) { this.dpi = dpi }

  ** Dots per inch which defines graphical resolution of
  ** the device for the logical coordinate system
  const Float dpi

  ** Debub string
  override Str toStr() { "DeviceContext { dpi=$dpi }" }
}