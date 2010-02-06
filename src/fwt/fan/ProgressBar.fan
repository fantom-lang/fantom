//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Sep 08  Andy Frank  Creation
//

**
** ProgressBar displays a progess bar.
**
@Serializable
class ProgressBar : Widget
{

  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** The current value of the progess. Must be >= 0.
  ** Defaults to 0.
  **
  native Int val

  **
  ** The minimum value of the progess. Must be >= 0.
  ** Defaults to 0.
  **
  native Int min

  **
  ** The maximum value of the progress. Defaults to 100.
  **
  native Int max

  **
  ** Configure this progess bar to be indeterminate.
  **
  const Bool indeterminate := false

}