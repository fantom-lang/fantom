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
var sys_MimeType = sys_Obj.$extend(sys_Obj);
sys_MimeType.prototype.$ctor = function() {}
sys_MimeType.prototype.type = function() { return sys_Type.find("sys::MimeType"); }

//////////////////////////////////////////////////////////////////////////
// fromStr
//////////////////////////////////////////////////////////////////////////

sys_MimeType.fromStr = function(s, checked)
{
  if (checked == undefined) checked = true;
  try
  {
    // common interned mime types
    switch (s.charAt(0))
    {
      case 'i':
        if (s == "image/png")  return sys_MimeType.imagePng;
        if (s == "image/jpeg") return sys_MimeType.imageJpeg;
        if (s == "image/gif")  return sys_MimeType.imageGif;
        break;
      case 't':
        if (s == "text/plain") return sys_MimeType.textPlain;
        if (s == "text/html")  return sys_MimeType.textHtml;
        if (s == "text/xml")   return sys_MimeType.textXml;
        break;
      case 'x':
        if (s == "x-directory/normal") return sys_MimeType.dir;
        break;
    }

    var slash = s.indexOf('/');
    var media = s.substring(0, slash);
    var sub = s.substring(slash+1, s.length);
    var params = sys_MimeType.emptyParams();

    var semi = sub.indexOf(';');
    if (semi > 0)
    {
      //params = doParseParams(sub, semi+1);
      //sub = sub.substring(0, semi).trim();
      console.log("#### MIME TYPE - PARAMS NOT IMPLEMENTED!!! ####");
    }

    var r = new sys_MimeType();
    r.str = s;
    r.mediaType = sys_Str.lower(media);
    r.subType   = sys_Str.lower(sub);
    r.params    = params.ro();
    return r;
  }
  catch (err)
  {
    if (!checked) return null;
    throw sys_ParseErr.make("MimeType",  s);
  }
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

sys_MimeType.prototype.equals = function(obj)
{
  if (!(obj instanceof MimeType)) return false;
  return this.mediaType == obj.mediaType &&
         this.subType == obj.subType &&
         this.params == obj.params;
}


sys_MimeType.prototype.hash = function()
{
  return 0;
  //return this.mediaType.hashCode() ^
  //       this.subType.hashCode() ^
  //       this.params.hashCode();
}

sys_MimeType.prototype.toStr = function() { return this.str; }

sys_MimeType.prototype.type = function() { return sys_Type.find("sys::MimeType"); }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_MimeType.prototype.mediaType = function() { return this.mediaType; }
sys_MimeType.prototype.subType = function() { return this.subType; }
sys_MimeType.prototype.params = function() { return this.params; }

/*
sys_MimeType.prototype.charset = function()
{
  String s = (String)params().get("charset");
  if (s == null) return Charset.utf8;
  return Charset.fromStr(s);
}
*/

//////////////////////////////////////////////////////////////////////////
// Lazy Load
//////////////////////////////////////////////////////////////////////////

sys_MimeType.emptyParams = function()
{
  var q = sys_MimeType.emptyQuery;
  if (q == null)
  {
    q = new sys_Map(sys_Type.find("sys::Str"), sys_Type.find("sys::Str"));
    //q.caseInsensitive(true);
    //q = q.toImmutable();
    sys_MimeType.emptyQuery = q;
  }
  return q;
}
sys_MimeType.emptyQuery = null;

//////////////////////////////////////////////////////////////////////////
// Predefined
//////////////////////////////////////////////////////////////////////////

sys_MimeType.predefined = function(media, sub)
{
  var t = new sys_MimeType();
  t.mediaType = media;
  t.subType = sub;
  t.params = sys_MimeType.emptyParams();
  t.str = media + "/" + sub;
  return t;
}

//////////////////////////////////////////////////////////////////////////
// Static Fields
//////////////////////////////////////////////////////////////////////////

// see sysPod.js

