//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Junc 09  Andy Frank  Creation
//

/**
 * MimeType represents the parsed value of a Content-Type
 * header per RFC 2045 section 5.1.
 */
fan.sys.MimeType = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.MimeType.prototype.$ctor = function() {}
fan.sys.MimeType.prototype.type = function() { return fan.sys.Type.find("sys::MimeType"); }

//////////////////////////////////////////////////////////////////////////
// fromStr
//////////////////////////////////////////////////////////////////////////

fan.sys.MimeType.fromStr = function(s, checked)
{
  if (checked == undefined) checked = true;
  try
  {
    // common interned mime types
    switch (s.charAt(0))
    {
      case 'i':
        if (s == "image/png")  return fan.sys.MimeType.imagePng;
        if (s == "image/jpeg") return fan.sys.MimeType.imageJpeg;
        if (s == "image/gif")  return fan.sys.MimeType.imageGif;
        break;
      case 't':
        if (s == "text/plain") return fan.sys.MimeType.textPlain;
        if (s == "text/html")  return fan.sys.MimeType.textHtml;
        if (s == "text/xml")   return fan.sys.MimeType.textXml;
        break;
      case 'x':
        if (s == "x-directory/normal") return fan.sys.MimeType.dir;
        break;
    }

    var slash = s.indexOf('/');
    var media = s.substring(0, slash);
    var sub = s.substring(slash+1, s.length);
    var params = fan.sys.MimeType.emptyParams();

    var semi = sub.indexOf(';');
    if (semi > 0)
    {
      //params = doParseParams(sub, semi+1);
      //sub = sub.substring(0, semi).trim();
      console.log("#### MIME TYPE - PARAMS NOT IMPLEMENTED!!! ####");
    }

    var r = new fan.sys.MimeType();
    r.str = s;
    r.mediaType = fan.sys.Str.lower(media);
    r.subType   = fan.sys.Str.lower(sub);
    r.params    = params.ro();
    return r;
  }
  catch (err)
  {
    if (!checked) return null;
    throw fan.sys.ParseErr.make("MimeType",  s);
  }
}

//////////////////////////////////////////////////////////////////////////
// Extension
//////////////////////////////////////////////////////////////////////////

fan.sys.MimeType.forExt = function(s)
{
  if (s == null) return null;
  try
  {
    // TODO FIXIT
    //return (MimeType)Repo.readSymbolsCached(etcUri, Duration.oneMin).get(FanStr.lower(s));
    return null;
  }
  catch (err)
  {
    fan.sys.Obj.echo("MimeType.forExt: " + s);
    fan.sys.Obj.echo(err);
    return null;
  }
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.MimeType.prototype.equals = function(obj)
{
  if (!(obj instanceof MimeType)) return false;
  return this.mediaType == obj.mediaType &&
         this.subType == obj.subType &&
         this.params == obj.params;
}


fan.sys.MimeType.prototype.hash = function()
{
  return 0;
  //return this.mediaType.hashCode() ^
  //       this.subType.hashCode() ^
  //       this.params.hashCode();
}

fan.sys.MimeType.prototype.toStr = function() { return this.str; }

fan.sys.MimeType.prototype.type = function() { return fan.sys.Type.find("sys::MimeType"); }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.MimeType.prototype.mediaType = function() { return this.mediaType; }
fan.sys.MimeType.prototype.subType = function() { return this.subType; }
fan.sys.MimeType.prototype.params = function() { return this.params; }

/*
fan.sys.MimeType.prototype.charset = function()
{
  String s = (String)params().get("charset");
  if (s == null) return Charset.utf8;
  return Charset.fromStr(s);
}
*/

//////////////////////////////////////////////////////////////////////////
// Lazy Load
//////////////////////////////////////////////////////////////////////////

fan.sys.MimeType.emptyParams = function()
{
  var q = fan.sys.MimeType.emptyQuery;
  if (q == null)
  {
    q = new fan.sys.Map(fan.sys.Type.find("sys::Str"), fan.sys.Type.find("sys::Str"));
    //q.caseInsensitive(true);
    //q = q.toImmutable();
    fan.sys.MimeType.emptyQuery = q;
  }
  return q;
}
fan.sys.MimeType.emptyQuery = null;

//////////////////////////////////////////////////////////////////////////
// Predefined
//////////////////////////////////////////////////////////////////////////

fan.sys.MimeType.predefined = function(media, sub)
{
  var t = new fan.sys.MimeType();
  t.mediaType = media;
  t.subType = sub;
  t.params = fan.sys.MimeType.emptyParams();
  t.str = media + "/" + sub;
  return t;
}

//////////////////////////////////////////////////////////////////////////
// Static Fields
//////////////////////////////////////////////////////////////////////////

// see sysPod.js

