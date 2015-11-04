//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Nov 2015  Andy Frank  Creation
//

using concurrent

**************************************************************************
** KeyFrames
**************************************************************************

** KeyFrames defines a CSS animation from a list of KeyFrames.
@Js const class KeyFrames
{
  ** Construct new animation with given frames.
  new make(KeyFrame[] frames)
  {
    this.name = "kf-${id.getAndIncrement}"
    this.frames = frames

    // build style rule
    buf := StrBuf()
    out := buf.out
    ["-webkit-", "-moz-", ""].each |prefix|
    {
      out.printLine("@${prefix}keyframes $name {")
      frames.each |f|
      {
        out.print("  $f.step {")
        f.props.each |val,name|
        {
          names := Style.toVendor(name)
          names.each |n| { out.print(" $n:$val;") }
        }
        out.printLine(" }")
      }
      out.printLine("}")
    }

    // inject keyframe rules
    Win.cur.addStyleRules(buf.toStr)
  }

  ** Frames for this animation.
  const KeyFrame[] frames

  override Str toStr()
  {
    buf := StrBuf()
    out := buf.out
    out.printLine("@keyframes $name {")
    frames.each |f| { out.printLine("  $f.step $f.props") }
    out.printLine("}")
    return buf.toStr
  }

  internal const Str name
  private static const AtomicInt id := AtomicInt(0)
}

**************************************************************************
** KeyFrame
**************************************************************************

** KeyFrame defines a frame of a CSS animation.
@Js const class KeyFrame
{
  ** Construct new KeyFrame for given step and props.
  new make(Str step, Str:Obj props)
  {
    this.step  = step
    this.props = props
  }

  ** Position of this keyframe.
  const Str step

  ** Properies for this keyframe.
  const Str:Obj props
}