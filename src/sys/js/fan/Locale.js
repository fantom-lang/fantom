//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   7 Jul 09  Andy Frank  Creation
//

/**
 * Locale.
 */
fan.sys.Locale = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.Locale.fromStr = function(s, checked)
{
  if (checked === undefined) checked = true;

  var len = s.length;
  try
  {
    if (len == 2)
    {
      if (fan.sys.Str.isLower(s))
        return new fan.sys.Locale(s, s, null);
    }

    if (len == 5)
    {
      var lang = s.substring(0, 2);
      var country = s.substring(3, 5);
      if (fan.sys.Str.isLower(lang) && fan.sys.Str.isUpper(country) && s.charAt(2) == '-')
        return new fan.sys.Locale(s, lang, country);
    }
  }
  catch (err) {}
  if (!checked) return null;
  throw fan.sys.ParseErr.make("Locale", s);
}

fan.sys.Locale.prototype.$ctor = function(str, lang, country)
{
  this.m_str       = str;
  this.m_lang      = lang;
  this.m_country   = country;
  this.m_strProps  = fan.sys.Uri.fromStr("locale/" + str + ".props");
  this.m_langProps = fan.sys.Uri.fromStr("locale/" + lang + ".props");
}

//////////////////////////////////////////////////////////////////////////
// Thread
//////////////////////////////////////////////////////////////////////////

fan.sys.Locale.cur = function()
{
  if (fan.sys.Locale.$cur == null) fan.sys.Locale.$cur = fan.sys.Locale.fromStr("en");
  return fan.sys.Locale.$cur;
}

fan.sys.Locale.setCur = function(locale)
{
  if (locale == null) throw fan.sys.NullErr.make();
  fan.sys.Locale.$cur = locale;
}

fan.sys.Locale.prototype.use = function(func)
{
  var old = fan.sys.Locale.cur();
  try
  {
    fan.sys.Locale.setCur(this);
    func.call(this);
  }
  finally
  {
    fan.sys.Locale.setCur(old);
  }
  return this;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Locale.prototype.lang = function() { return this.m_lang; }

fan.sys.Locale.prototype.country = function() { return this.m_country; }

fan.sys.Locale.prototype.$typeof = function() { return fan.sys.Locale.$type; }

fan.sys.Locale.prototype.hash = function() { return fan.sys.Str.hash(this.m_str); }

fan.sys.Locale.prototype.equals = function(obj)
{
  if (obj instanceof fan.sys.Locale)
    return obj.m_str == this.m_str;
  return false;
}

fan.sys.Locale.prototype.toStr = function() { return this.m_str; }

