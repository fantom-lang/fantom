//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Feb 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Duration
 */
fan.sys.Duration = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Duration.fromStr = function(s, checked)
{
  if (checked === undefined) checked = true;

  //   ns:   nanoseconds  (x 1)
  //   ms:   milliseconds (x 1,000,000)
  //   sec:  seconds      (x 1,000,000,000)
  //   min:  minutes      (x 60,000,000,000)
  //   hr:   hours        (x 3,600,000,000,000)
  //   day:  days         (x 86,400,000,000,000)
  try
  {
    var len = s.length;
    var x1  = s.charAt(len-1);
    var x2  = s.charAt(len-2);
    var x3  = s.charAt(len-3);
    var dot = s.indexOf('.') > 0;

    var mult = -1;
    var suffixLen  = -1;
    switch (x1)
    {
      case 's':
        if (x2 == 'n') { mult=1; suffixLen=2; } // ns
        if (x2 == 'm') { mult=1000000; suffixLen=2; } // ms
        break;
      case 'c':
        if (x2 == 'e' && x3 == 's') { mult=1000000000; suffixLen=3; } // sec
        break;
      case 'n':
        if (x2 == 'i' && x3 == 'm') { mult=60000000000; suffixLen=3; } // min
        break;
      case 'r':
        if (x2 == 'h') { mult=3600000000000; suffixLen=2; } // hr
        break;
      case 'y':
        if (x2 == 'a' && x3 == 'd') { mult=86400000000000; suffixLen=3; } // day
        break;
    }

    if (mult < 0) throw new Error();

    s = s.substring(0, len-suffixLen);
    if (dot)
    {
      var num = parseFloat(s);
      if (isNaN(num)) throw new Error();
      return fan.sys.Duration.make(Math.floor(num*mult));
    }
    else
    {
      var num = fan.sys.Int.fromStr(s);
      return fan.sys.Duration.make(num*mult);
    }
  }
  catch (err)
  {
    if (!checked) return null;
    throw fan.sys.ParseErr.make("Duration", s);
  }
}

fan.sys.Duration.now = function()
{
  var ms = new Date().getTime();
  return fan.sys.Duration.make(ms * fan.sys.Duration.nsPerMilli);
}

fan.sys.Duration.nowTicks = function()
{
  return fan.sys.Duration.now().ticks();
}

fan.sys.Duration.boot = function()
{
  return fan.sys.Duration.m_boot;
}

fan.sys.Duration.uptime = function()
{
  return fan.sys.Duration.now().minus(fan.sys.Duration.m_boot);
}

fan.sys.Duration.make = function(ticks)
{
  var self = new fan.sys.Duration();
  self.m_ticks = ticks;
  return self;
}

fan.sys.Duration.makeMillis = function(ms)
{
  return fan.sys.Duration.make(ms*1000000);
}

fan.sys.Duration.makeSec = function(secs)
{
  return fan.sys.Duration.make(secs*1000000000);
}

fan.sys.Duration.prototype.$ctor = function(ticks)
{
  this.m_ticks = 0;
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Duration.prototype.equals = function(that)
{
  if (that instanceof fan.sys.Duration)
    return this.m_ticks == that.m_ticks;
  else
    return false;
}

fan.sys.Duration.prototype.compare = function(that)
{
  if (this.m_ticks < that.m_ticks) return -1;
  if (this.m_ticks == that.m_ticks) return 0;
  return +1;
}

fan.sys.Duration.prototype.$typeof = function()
{
  return fan.sys.Duration.$type;
}

fan.sys.Duration.prototype.ticks = function()
{
  return this.m_ticks;
}

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

fan.sys.Duration.prototype.negate = function() { return fan.sys.Duration.make(-this.m_ticks); }
fan.sys.Duration.prototype.plus = function(x)  { return fan.sys.Duration.make(this.m_ticks + x.m_ticks); }
fan.sys.Duration.prototype.minus = function(x) { return fan.sys.Duration.make(this.m_ticks - x.m_ticks); }
fan.sys.Duration.prototype.mult = function(x)  { return fan.sys.Duration.make(this.m_ticks * x); }
fan.sys.Duration.prototype.div = function(x)   { return fan.sys.Duration.make(this.m_ticks / x); }
fan.sys.Duration.prototype.floor = function(accuracy)
{
  if (this.m_ticks % accuracy.m_ticks == 0) return this;
  return fan.sys.Duration.make(this.m_ticks - (this.m_ticks % accuracy.m_ticks));
}
fan.sys.Duration.prototype.abs = function()
{
  if (this.m_ticks >= 0) return this;
  return fan.sys.Duration.make(-this.m_ticks);
}

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

fan.sys.Duration.prototype.toStr = function()
{
  if (this.m_ticks == 0) return "0ns";

  // if clean millisecond boundary
  var ns = this.m_ticks;
  if (ns % fan.sys.Duration.nsPerMilli == 0)
  {
    if (ns % fan.sys.Duration.nsPerDay == 0) return ns/fan.sys.Duration.nsPerDay + "day";
    if (ns % fan.sys.Duration.nsPerHr  == 0) return ns/fan.sys.Duration.nsPerHr  + "hr";
    if (ns % fan.sys.Duration.nsPerMin == 0) return ns/fan.sys.Duration.nsPerMin + "min";
    if (ns % fan.sys.Duration.nsPerSec == 0) return ns/fan.sys.Duration.nsPerSec + "sec";
    return ns/fan.sys.Duration.nsPerMilli + "ms";
  }

  // return in nanoseconds
  return ns + "ns";
}

fan.sys.Duration.prototype.$literalEncode = function(out) { out.writeChars(this.toStr()); }

fan.sys.Duration.prototype.toCode = function() { return this.toStr(); }

fan.sys.Duration.prototype.toMillis = function() { return Math.floor(this.m_ticks / fan.sys.Duration.nsPerMilli); }
fan.sys.Duration.prototype.toSec    = function() { return Math.floor(this.m_ticks / fan.sys.Duration.nsPerSec); }
fan.sys.Duration.prototype.toMin    = function() { return Math.floor(this.m_ticks / fan.sys.Duration.nsPerMin); }
fan.sys.Duration.prototype.toHour   = function() { return Math.floor(this.m_ticks / fan.sys.Duration.nsPerHr); }
fan.sys.Duration.prototype.toDay    = function() { return Math.floor(this.m_ticks / fan.sys.Duration.nsPerDay); }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

fan.sys.Duration.prototype.toLocale = function()
{
  var ticks = this.m_ticks;

  // less than 1000ns Xns
  if (ticks < 1000) return ticks + "ns";

  // less than 2ms X.XXXms
  if (ticks < 2*fan.sys.Duration.nsPerMilli)
  {
    var s = '';
    var ms = Math.floor(ticks/fan.sys.Duration.nsPerMilli);
    var us = Math.floor((ticks - ms*fan.sys.Duration.nsPerMilli)/1000);
    s += ms;
    s += '.';
    if (us < 100) s += '0';
    if (us < 10)  s += '0';
    s += us;
    if (s.charAt(s.length-1) == '0') s = s.substr(0, s.length-1);
    if (s.charAt(s.length-1) == '0') s = s.substr(0, s.length-1);
    s += "ms";
    return s;
  }

  // less than 2sec Xms
  if (ticks < 2*fan.sys.Duration.nsPerSec)
    return Math.floor(ticks/fan.sys.Duration.nsPerMilli) + "ms";

  // less than 2min Xsec
  if (ticks < 1*fan.sys.Duration.nsPerMin)
    return Math.floor(ticks/fan.sys.Duration.nsPerSec) + "sec";

  // [Xdays] [Xhr] Xmin Xsec
  var days = Math.floor(ticks/fan.sys.Duration.nsPerDay); ticks -= days*fan.sys.Duration.nsPerDay;
  var hr   = Math.floor(ticks/fan.sys.Duration.nsPerHr);  ticks -= hr*fan.sys.Duration.nsPerHr;
  var min  = Math.floor(ticks/fan.sys.Duration.nsPerMin); ticks -= min*fan.sys.Duration.nsPerMin;
  var sec  = Math.floor(ticks/fan.sys.Duration.nsPerSec);

  var s = '';
  if (days > 0) s += days + (days == 1 ? "day " : "days ");
  if (hr  > 0) s += hr + "hr ";
  if (min > 0) s += min + "min ";
  if (sec > 0) s += sec + "sec ";
  return s.substring(0, s.length-1);
}

//////////////////////////////////////////////////////////////////////////
// ISO 8601
//////////////////////////////////////////////////////////////////////////

fan.sys.Duration.prototype.toIso = function()
{
  var s = '';
  var ticks = this.m_ticks;
  if (ticks == 0) return "PT0S";

  if (ticks < 0) s += '-';
  s += 'P';
  var abs  = Math.abs(ticks);
  var sec  = Math.floor(abs / fan.sys.Duration.nsPerSec);
  var frac = abs % fan.sys.Duration.nsPerSec;

  // days
  if (sec > fan.sys.Duration.secPerDay)
  {
    s += Math.floor(sec/fan.sys.Duration.secPerDay) + 'D';
    sec = sec % fan.sys.Duration.secPerDay;
  }
  if (sec == 0 && frac == 0) return s;
  s += 'T';

  // hours, minutes
  if (sec > fan.sys.Duration.secPerHr)
  {
    s += Math.floor(sec/fan.sys.Duration.secPerHr) + 'H';
    sec = sec % fan.sys.Duration.secPerHr;
  }
  if (sec > fan.sys.Duration.secPerMin)
  {
    s += Math.floor(sec/fan.sys.Duration.secPerMin) + 'M';
    sec = sec % fan.sys.Duration.secPerMin;
  }
  if (sec == 0 && frac == 0) return s;

  // seconds and fractional seconds
  s += sec;
  if (frac != 0)
  {
    s += '.';
    for (var i=10; i<=100000000; i*=10) if (frac < i) s += '0';
    s += frac;
    var x = s.length-1;
    while (s.charAt(x) == '0') x--;
    s = s.substr(0, x+1);
  }
  s += 'S';
  return s;
}

fan.sys.Duration.fromIso = function(s, checked)
{
  if (checked === undefined) checked = true;
  try
  {
    var ticks = 0;
    var neg = false;
    var p = new fan.sys.IsoParser(s);

    // check for negative
    if (p.cur == 45) { neg = true; p.consume(); }
    else if (p.cur == 43) { p.consume(); }

    // next char must be P
    p.consume(80);
    if (p.cur == -1) throw new Error();

    // D
    var num = 0;
    if (p.cur != 84)
    {
      num = p.num();
      p.consume(68);
      ticks += num * fan.sys.Duration.nsPerDay;
      if (p.cur == -1) return fan.sys.Duration.make(ticks);
    }

    // next char must be T
    p.consume(84);
    if (p.cur == -1) throw new Error();
    num = p.num();

    // H
    if (num >= 0 && p.cur == 72)
    {
      p.consume();
      ticks += num * fan.sys.Duration.nsPerHr;
      num = p.num();
    }

    // M
    if (num >= 0 && p.cur == 77)
    {
      p.consume();
      ticks += num * fan.sys.Duration.nsPerMin;
      num = p.num();
    }

    // S
    if (num >= 0 && p.cur == 83 || p.cur == 46)
    {
      ticks += num * fan.sys.Duration.nsPerSec;
      if (p.cur == 46) { p.consume(); ticks += p.frac(); }
      p.consume(83);
    }

    // verify we parsed everything
    if (p.cur != -1) throw new Error();

    // negate if necessary and return result
    if (neg) ticks = -ticks;
    return fan.sys.Duration.make(ticks);
  }
  catch (err)
  {
    if (!checked) return null;
    throw fan.sys.ParseErr.make("ISO 8601 Duration",  s);
  }
}

fan.sys.IsoParser = function(s)
{
  this.s = s;
  this.cur = s.charCodeAt(0);
  this.off = 0;
  this.curIsDigit = false;
}

fan.sys.IsoParser.prototype.num = function()
{
  if (!this.curIsDigit && this.cur != -1 && this.cur != 46)
    throw new Error();
  var num = 0;
  while (this.curIsDigit)
  {
    num = num*10 + this.digit();
    this.consume();
  }
  return num;
}

fan.sys.IsoParser.prototype.frac = function()
{
  // get up to nine decimal places as milliseconds within a fraction
  var ticks = 0;
  for (var i=100000000; i>=0; i/=10)
  {
    if (!this.curIsDigit) break;
    ticks += this.digit() * i;
    this.consume();
  }
  return ticks;
}

fan.sys.IsoParser.prototype.digit = function() { return this.cur - 48; }

fan.sys.IsoParser.prototype.consume = function(ch)
{
  if (ch != null && this.cur != ch) throw new Error();

  this.off++;
  if (this.off < this.s.length)
  {
    this.cur = this.s.charCodeAt(this.off);
    this.curIsDigit = 48 <= this.cur && this.cur <= 57;
  }
  else
  {
    this.cur = -1;
    this.curIsDigit = false;
  }
}

