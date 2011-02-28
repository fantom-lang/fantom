using gfx
using fwt

class ImagePainedDemo
{
  static Void main()
  {
    // touch Desktop to boot SWT
    Desktop.sysFont

    // open Window
    Window
    {
      size = Size(400, 400)
      Label { image = makePaintedImage; halign=Halign.center },
    }.open
  }

  private static Image makePaintedImage()
  {
    size := Size(200, 200)
    return Image.makePainted(size) |Graphics g|
    {
      g.brush = Color.white
      g.fillRect(0, 0, size.w, size.h)

      g.brush = Gradient()
      g.fillRect(20, 20, size.w-40, size.h-40)

      g.brush = Color.black
      g.drawRect(0, 0, size.w-1, size.h-1)
      g.drawRect(20, 20, size.w-40, size.h-40)
    }
  }
}