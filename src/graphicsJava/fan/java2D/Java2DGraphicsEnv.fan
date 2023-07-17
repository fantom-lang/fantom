//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Mar 2022  Brian Frank  Creation
//

using [java] java.awt::Font as AwtFont
using [java] java.awt::Image as AwtImage
using [java] java.awt::GraphicsEnvironment
using [java] javax.imageio
using [java] fanx.interop
using concurrent
using graphics

**
** Java2D graphics environment
**
const class Java2DGraphicsEnv : GraphicsEnv
{

//////////////////////////////////////////////////////////////////////////
// Fonts
//////////////////////////////////////////////////////////////////////////

  ** Map graphics font to an AWT font
  AwtFont awtFont(Font f)
  {
     // Java says its uses points, but really maps points directly to pixels
    size := (f.size * 1.333f).toInt

    // Map font names to installed font
    name := awtFontName(f.names)

    // I don't think font weights are really supported by Java; the
    // code to use them is below but commented out.  In meantime we
    // just support normal and bold weights

    // non-bold
    if (f.weight <= FontWeight.normal)
    {
      style := f.style.isNormal ? AwtFont.PLAIN : AwtFont.ITALIC
      awt := AwtFont(name, style, size)
      // echo("-> $f.name => $awt.getName")
      return awt
    }

    // bold
    else
    {
      style := f.style.isNormal ? AwtFont.BOLD : AwtFont.ITALIC.or(AwtFont.BOLD)
      awt := AwtFont(name, style, size)
      return awt
    }

    // doesn't really work, but theoretically seems like the it should work
    /*
    map := HashMap()
    map.put(TextAttribute.FAMILY, name)
    map.put(TextAttribute.SIZE, size)
    switch (it.weight.num)
    {
      case 100: map.put(TextAttribute.WEIGHT, TextAttribute.WEIGHT_EXTRA_LIGHT)
      case 200: map.put(TextAttribute.WEIGHT, TextAttribute.WEIGHT_LIGHT)
      case 300: map.put(TextAttribute.WEIGHT, TextAttribute.WEIGHT_DEMILIGHT)
      case 400: map.put(TextAttribute.WEIGHT, TextAttribute.WEIGHT_REGULAR)
      case 500: map.put(TextAttribute.WEIGHT, TextAttribute.WEIGHT_SEMIBOLD)
      case 600: map.put(TextAttribute.WEIGHT, TextAttribute.WEIGHT_MEDIUM)
      case 700: map.put(TextAttribute.WEIGHT, TextAttribute.WEIGHT_BOLD)
      case 800: map.put(TextAttribute.WEIGHT, TextAttribute.WEIGHT_HEAVY)
      case 900: map.put(TextAttribute.WEIGHT, TextAttribute.WEIGHT_ULTRABOLD)
      default:  map.put(TextAttribute.WEIGHT, it.weight.num)
    }
    if (it.style === FontStyle.italic)
    {
      map.put(TextAttribute.POSTURE, TextAttribute.POSTURE_OBLIQUE)
    }
    return AwtFont(map)
    */
  }

  ** Map font names to a font installed for Java2D
  private Str awtFontName(Str[] names)
  {
    // match name to installed font
    installed := installedFonts
    for (i := 0; i<names.size; ++i)
    {
      n := installed.get(names[i].lower)
      if (n != null) return n
    }

    // print out warning, then map a fallback family name
    echo("WARN: Java2D font not installed: " + names.join(", "))
    fallback := "Arial"
    installed[names.first] = fallback
    return fallback
  }

  ** Get installed fonts to use: logical name -> Java AWT name
  private once ConcurrentMap installedFonts()
  {
    // build map of lowercase name -> AWT name
    acc := ConcurrentMap()
    try
    {
      fonts := GraphicsEnvironment.getLocalGraphicsEnvironment.getAvailableFontFamilyNames
      fonts.each |Str n| { acc[n.lower] = n }
    }
    catch (Err e) e.trace

    // try to use decent default for monospace
    mono := acc["consolas"]
    if (mono == null) mono = "monaco"
    if (mono == null) mono = "courier new"
    if (mono == null) mono = "courier"
    if (mono != null) acc["monospace"] = mono

    // try to use decent default for sans-serf
    sans := acc["inter"]
    if (sans != null) sans = "inter regular" // so we don't use light
    if (sans == null) sans = "roboto"
    if (sans == null) sans = "helvetica neue"
    if (sans == null) sans = "arial"
    if (sans != null) acc["sans-serif"] = sans

    return acc
  }

//////////////////////////////////////////////////////////////////////////
// Images
//////////////////////////////////////////////////////////////////////////

  ** Get an image for the given uri.
  override Java2DImage image(Uri uri, Buf? data := null)
  {
    // get from cache
    image := images.get(uri) as Java2DImage
    if (image != null) return image

    // TODO: we are just loading synchronously
    if (data == null) data = resolveImageData(uri)
    image = loadImage(uri, data)

    // safely add to the cache
    return images.getOrAdd(uri, image)
  }

  ** Read memory data into BufferedImage
  Java2DImage loadImage(Uri uri, Buf data)
  {
    awt := ImageIO.read(Interop.toJava(data.in))
    mime := Image.mimeForExt(uri.ext ?: "")
    return Java2DImage(uri, mime, awt)
  }

  ** Hook to resolve a URI to its file data
  virtual Buf resolveImageData(Uri uri) { uri.toFile.readAllBuf }

  ** Image cache
  private const ConcurrentMap images := ConcurrentMap()
}

