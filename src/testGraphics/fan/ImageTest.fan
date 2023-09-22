//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 2022  Brian Frank  Creation
//

using graphics
using dom

@Js
class ImageTest : AbstractTest
{
  override Void onPaint(Size size, Graphics g)
  {
    jpg := load("test.jpg")  // 800x400
    png := load("test.png")
    svg := load("test.svg")
    imgs := [jpg, png, svg]

    // use jpeg @ 800x400 to test scaling
    g.push
    g.color = Color("#555")
    g.font = Font("12pt Arial")
    g.drawText("JPEG with Scaling", 10f, 25f)
    g.translate(10f, 30f)
    src := Rect(300f, 150f, 200f, 100f)
    g.drawImage(jpg, 0f, 0f)
    g.drawImage(jpg, 0f, 410f, 400f, 200f)
    g.drawImageRegion(jpg, src, Rect(410f, 410f, 200f, 100f))
    g.color = Color("lime")
    g.stroke = Stroke("[2,2]")
    g.drawRect(src.x, src.y, src.w, src.h)
    g.pop

    // draw png
    g.color = Color("#555")
    g.drawText("PNG", 650f, 455f)
    g.drawImage(png, 650f, 460f)

    // draw svg
    g.color = Color("#555")
    g.drawText("SVG", 700f, 455f)
    g.drawImage(svg, 680f, 460f)

    // there is no async framework at the moment, so for now just
    // schedule a repaint if any of the images are not loaded yet
    if (Env.cur.runtime == "js")
    {
       if (imgs.any { !it.isLoaded })
       {
         echo("Images not loaded yet...")
         Win.cur.setTimeout(1sec) { paint(size, g) }
       }
    }

    // only supported on java
    if (Env.cur.runtime == "java")
    {
      // create rendered img
      ren := Image.render(MimeType("image/png"), Size(128f, 128f)) |ig|
      {
        ig.color = Color("#e2e8f0")
        ig.fillRect(0f, 0f, 128f, 128f)
        ig.color = Color("#fb7185")
        ig.drawRect(0f, 0f, 127f, 127f)
        ig.drawLine(0f, 0f, 127f, 127f)
        ig.drawLine(0f, 127f, 127f, 0f)
      }

      // draw ren
      g.color = Color("#555")
      g.drawText("Rendered", 750f, 455f)
      g.drawImage(ren, 750f, 460f)

      // test Image.write
      write(png, "existing.png")
      write(ren, "rendered.png")
    }
  }

  Image load(Str name)
  {
    uri := Env.cur.runtime == "js" ?
          `/res/${name}` :
          `fan://testGraphics/res/${name}`
    x := GraphicsEnv.cur.image(uri)

    if (false)
    {
      echo("Load Image $uri [$x.typeof]")
      echo("  uri:      $x.uri")
      echo("  mime:     $x.mime")
      echo("  isLoaded: $x.isLoaded")
      echo("  w:        $x.w [$x.w.typeof]")
      echo("  h:        $x.h [$x.h.typeof]")
      echo("  size:     $x.size [$x.size.typeof]")
    }

    return x
  }

  Void write(Image img, Str filename)
  {
    temp := Env.cur.tempDir + `${filename}`
    out  := temp.out
    img.write(out)
    out.sync.close
  }
}

