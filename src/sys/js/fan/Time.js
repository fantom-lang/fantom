//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jun 09  Andy Frank  Creation
//

/**
 * Time
 */
fan.sys.Time = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Time.prototype.$ctor = function(hour, min, sec, ns)
{
  if (hour < 0 || hour > 23)     throw fan.sys.ArgErr.make("hour " + hour);
  if (min < 0 || min > 59)       throw fan.sys.ArgErr.make("min " + min);
  if (sec < 0 || sec > 59)       throw fan.sys.ArgErr.make("sec " + sec);
  if (ns < 0 || ns > 999999999)  throw fan.sys.ArgErr.make("ns " + ns);

  this.m_hour = hour;
  this.m_min  = min;
  this.m_sec  = sec;
  this.m_ns   = ns;
}

fan.sys.Time.make = function(hour, min, sec, ns)
{
  if (sec === undefined) sec = 0;
  if (ns === undefined)  ns = 0;
  return new fan.sys.Time(hour, min, sec, ns);
}

fan.sys.Time.now = function(tz)
{
  return fan.sys.DateTime.makeTicks(fan.sys.DateTime.nowTicks(), tz).time();
}

fan.sys.Time.fromStr = function(s, checked)
{
  if (checked === undefined) checked = true;
  try
  {
    var num = function(x,index) { return x.charCodeAt(index) - 48; }

    // hh:mm:ss
    var hour  = num(s, 0)*10  + num(s, 1);
    var min   = num(s, 3)*10  + num(s, 4);
    var sec   = num(s, 6)*10  + num(s, 7);

    // check separator symbols
    if (s.charAt(2) != ':' || s.charAt(5) != ':')
      throw new Error();

    // optional .FFFFFFFFF
    var i = 8;
    var ns = 0;
    var tenth = 100000000;
    var len = s.length;
    if (i < len && s.charAt(i) == '.')
    {
      ++i;
      while (i < len)
      {
        var c = s.charCodeAt(i);
        if (c < 48 || c > 57) break;
        ns += (c - 48) * tenth;
        tenth /= 10;
        ++i;
      }
    }

    // verify everything has been parsed
    if (i < s.length) throw new Error();

    // use local var to capture any exceptions
    var instance = new fan.sys.Time(hour, min, sec, ns);
    return instance;
  }
  catch (err)
  {
    if (!checked) return null;
    throw fan.sys.ParseErr.make("Time", s);
  }
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Time.prototype.equals = function(that)
{
  if (that instanceof fan.sys.Time)
  {
    return this.m_hour.valueOf() == that.m_hour.valueOf() &&
           this.m_min.valueOf() == that.m_min.valueOf() &&
           this.m_sec.valueOf() == that.m_sec.valueOf() &&
           this.m_ns.valueOf() == that.m_ns.valueOf();
  }
  return false;
}

fan.sys.Time.prototype.compare = function(that)
{
  if (this.m_hour.valueOf() == that.m_hour.valueOf())
  {
    if (this.m_min.valueOf() == that.m_min.valueOf())
    {
      if (this.m_sec.valueOf() == that.m_sec.valueOf())
      {
        if (this.m_ns.valueOf() == that.m_ns.valueOf()) return 0;
        return this.m_ns < that.m_ns ? -1 : +1;
      }
      return this.m_sec < that.m_sec ? -1 : +1;
    }
    return this.m_min < that.m_min ? -1 : +1;
  }
  return this.m_hour < that.m_hour ? -1 : +1;
}

fan.sys.Time.prototype.toStr = function()
{
  return this.toLocale("hh:mm:ss.FFFFFFFFF");
}

fan.sys.Time.prototype.$typeof = function()
{
  return fan.sys.Time.$type;
}

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

fan.sys.Time.prototype.hour = function() { return this.m_hour; }
fan.sys.Time.prototype.min = function() { return this.m_min; }
fan.sys.Time.prototype.sec = function() { return this.m_sec; }
fan.sys.Time.prototype.nanoSec = function() { return this.m_ns; }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

fan.sys.Time.prototype.toLocale = function(pattern)
{
  if (pattern === undefined) pattern = null;

  // locale specific default
  var locale = null;
  if (pattern == null)
  {
    if (locale == null) locale = fan.sys.Locale.cur();
    var pod = fan.sys.Pod.find("sys");
    pattern = fan.sys.Env.cur().locale(pod, "time", "hh:mm:ss", locale);
  }

  return new fan.sys.DateTimeStr.makeTime(pattern, locale, this).format();
}

fan.sys.Time.fromLocale = function(s, pattern, checked)
{
  if (checked === undefined) checked = true;
  return fan.sys.DateTimeStr.make(pattern, null).parseTime(s, checked);
}

//////////////////////////////////////////////////////////////////////////
// ISO 8601
//////////////////////////////////////////////////////////////////////////

fan.sys.Time.prototype.toIso = function() { return this.toStr(); }

fan.sys.Time.fromIso = function(s, checked)
{
  if (checked === undefined) checked = true;
  return fan.sys.Time.fromStr(s, checked);
}

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

fan.sys.Time.fromDuration = function(d)
{
  var ticks = d.m_ticks;
  if (ticks == 0) return fan.sys.Time.m_defVal;

  if (ticks < 0 || ticks > fan.sys.Duration.nsPerDay )
    throw fan.sys.ArgErr.make("Duration out of range: " + d);

  var hour = fan.sys.Int.div(ticks, fan.sys.Duration.nsPerHr);  ticks %= fan.sys.Duration.nsPerHr;
  var min  = fan.sys.Int.div(ticks, fan.sys.Duration.nsPerMin); ticks %= fan.sys.Duration.nsPerMin;
  var sec  = fan.sys.Int.div(ticks, fan.sys.Duration.nsPerSec); ticks %= fan.sys.Duration.nsPerSec;
  var ns   = ticks;

  return new fan.sys.Time(hour, min, sec, ns);
}

fan.sys.Time.prototype.toDuration = function()
{
  return fan.sys.Duration.make(this.m_hour*fan.sys.Duration.nsPerHr +
                               this.m_min*fan.sys.Duration.nsPerMin +
                               this.m_sec*fan.sys.Duration.nsPerSec +
                               this.m_ns);
}

fan.sys.Time.prototype.toDateTime = function(d, tz)
{
  return fan.sys.DateTime.makeDT(d, this, tz);
}

fan.sys.Time.prototype.toCode = function()
{
  if (this.equals(fan.sys.Time.m_defVal)) return "Time.defVal";
  return "Time(\"" + this.toString() + "\")";
}

fan.sys.Time.prototype.isMidnight = function()
{
  return this.equals(fan.sys.Time.m_defVal);
}

