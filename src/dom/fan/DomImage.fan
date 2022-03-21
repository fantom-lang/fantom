//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Mar 2022  Brian Frank  Creation
//

using graphics

**
** Dom implementation of the Image API backed by an HTMLImageElement
**
@Js
internal const class DomImage : Image
{
  new make(Uri uri, MimeType mime, Elem elem)
  {
    this.uri = uri
    this.mime = mime
    this.init(elem)
  }

  private native Void init(Elem elem)

  const override Uri uri

  const override MimeType mime

  override native Bool isLoaded()

  override native Size size()

  override native Float w()

  override native Float h()

  @Operator override Obj? get(Str prop) { null }

}


