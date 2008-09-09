//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Aug 08  Brian Frank  Creation
//

using fwt

**
** AboutView is the default splash screen view
**
@fluxView=AboutResource#
internal class AboutView : View
{

  override Void onLoad()
  {
    logo := File.createTemp("fluxLogo", ".png").deleteOnExit
    Pod.find("icons").files[`/x48/flux.png`].copyTo(logo, ["overwrite":true])

    html :=
     "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"
       \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">
      <html xmlns='http://www.w3.org/1999/xhtml'>
      <head>
       <title>About Flux</title>
       <meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>
       <style type='text/css'>
         body {
          font-family: 'Lucida Grande', 'Segoe UI', Tahoma, sans-serif;
          margin-top: 75px;
         }
         h1 { font-size: 18px; margin: 5px 0 0 0; }
         p  { font-size: 11px; }
         p.ver  { margin-top: 0; }
         p.copy { margin-top: 30px; color: #666; }
         img { float: left; vertical-align: middle; margin-right: 10px; }
         div { width: 275px; margin: 0 auto; }
       </style>
      </head>
      <body>
       <div>
        <img src='file://$logo.uri' alt='Flux Logo' />
        <h1>Flux</h1>
        <p class='ver'>Version $type.pod.version</p>
        <p class='copy'>
         Copyright (c) 2008, Brian Frank and Andy Frank<br/>
         Licensed under the Academic Free License version 3.0<br/>
        </p>
       </div>
      </body>
      </html>"

    content = WebBrowser { loadStr(html) }
  }

}

**
** AboutResource models an about document.
**
internal class AboutResource : Resource
{
  new make(Uri uri) { this.uri = uri }

  override Uri uri

  override Str name() { return uri.toStr }

  override Image icon() { return Flux.icon(`/x16/dialog-information.png`) }
}