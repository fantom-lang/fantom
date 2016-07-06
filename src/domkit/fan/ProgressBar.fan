//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 2016  Andy Frank  Creation
//

using dom

**
** ProgressBar visualizes progress of a long running operation
**
@Js class ProgressBar : Elem
{
  new make(|This|? f := null) : super("div")
  {
    this.style.addClass("domkit-ProgressBar")
    if (f != null) f(this)
    update
  }

  ** Min progress value.
  Int min := 0
  {
    set
    {
      &min = it
      update
    }
  }

  ** Max progress value.
  Int max := 100
  {
    set
    {
      &max = it
      update
    }
  }

  ** Current progress value.
  Int val := 0
  {
    set
    {
      &val = it.max(min).min(max)
      update
    }
  }

  ** Callback to get progress bar text when `val` is modified.
  Void onText(|ProgressBar->Str| f) { this.cbText=f }

  ** Callback to get progress bar color (as CSS color value) when `val` is modified.
  Void onBarColor(|ProgressBar->Str| f) { this.cbBarColor=f }

  private Void update()
  {
    // text
    this.text = cbText==null ? "" : cbText(this)

    // bar style
    color  := cbBarColor== null ? "#3498db" : cbBarColor(this)
    offset := ((val-min).toFloat / (max-min).toFloat * 100f).toInt
    this.style->background = "linear-gradient(left, $color ${offset}%, $color ${offset}%, #fff ${offset}%)"
  }

  private Func? cbText
  private Func? cbBarColor
}