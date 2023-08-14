//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Feb 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   19 Apr 2023  Andy Frank  Refactor to ES
//

/**
 * DateTime
 */
class DateTime extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constants
//////////////////////////////////////////////////////////////////////////

  // TODO - make fan.sys.Ints
  static #diffJs     = 946684800000; // 2000-1970 in milliseconds
  static #nsPerYear  = 365*24*60*60*1000000000;
  static #nsPerDay   = 24*60*60*1000000000;
  static #nsPerHr    = 60*60*1000000000;
  static #nsPerMin   = 60*1000000000;
  static #nsPerSec   = 1000000000;
  static #nsPerMilli = 1000000;
  static #minTicks   = -3124137600000000000; // 1901
  static #maxTicks   = 3155760000000000000;  // 2100

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor(ticks, ns, tz, fields) {
    super();
    this.#ticks = ticks;
    this.#ns = ns;
    this.#tz = tz;
    this.#fields = fields;
  }

  #ticks;
  #ns;
  #tz;
  #fields;
  static __boot = undefined;
  static #cached;
  static #cachedUtc;

  static #defVal;
  static defVal() {
    if (!DateTime.#defVal) {
      DateTime.#defVal = DateTime.make(2000, Month.jan(), 1, 0, 0, 0, 0, TimeZone.utc());
    }
    return DateTime.#defVal;
  }

  static now(tolerance=Duration.makeMillis(250)) {
    const now = DateTime.nowTicks();

    if (!DateTime.#cached)
      DateTime.#cached = DateTime.makeTicks(0, TimeZone.cur());

    const c = DateTime.#cached;
    if (tolerance != null && now - c.ticks() <= tolerance.ticks())
      return c;

    DateTime.#cached = DateTime.makeTicks(now, TimeZone.cur());
    return DateTime.#cached;
  }

  static nowUtc(tolerance=Duration.makeMillis(250)) {
    const now = DateTime.nowTicks();

    if (!DateTime.#cachedUtc)
      DateTime.#cachedUtc = DateTime.makeTicks(0, TimeZone.utc());

    const c = DateTime.#cachedUtc;
    if (tolerance != null && now - c.#ticks <= tolerance.ticks())
      return c;

    DateTime.#cachedUtc = DateTime.makeTicks(now, TimeZone.utc());
    return DateTime.#cachedUtc;
  }

  static nowTicks() {
    return (new js.Date().getTime() - DateTime.#diffJs) * DateTime.#nsPerMilli;
  }

  static boot() { return DateTime.__boot; }

//////////////////////////////////////////////////////////////////////////
// Constructor - Values
//////////////////////////////////////////////////////////////////////////

  static make(year, month, day, hour, min, sec=0, ns=0, tz=TimeZone.cur()) {
    return DateTime.__doMake(year, month, day, hour, min, sec, ns, undefined, tz);
  }

  static __doMake(year, month, day, hour, min, sec, ns, knownOffset, tz) {
    month = month.ordinal();

    if (year < 1901 || year > 2099) throw ArgErr.make("year " + year);
    if (month < 0 || month > 11)    throw ArgErr.make("month " + month);
    if (day < 1 || day > DateTime.__numDaysInMonth(year, month)) throw ArgErr.make("day " + day);
    if (hour < 0 || hour > 23)      throw ArgErr.make("hour " + hour);
    if (min < 0 || min > 59)        throw ArgErr.make("min " + min);
    if (sec < 0 || sec > 59)        throw ArgErr.make("sec " + sec);
    if (ns < 0 || ns > 999999999)   throw ArgErr.make("ns " + ns);

    // compute ticks for UTC
    const dayOfYear = DateTime.__dayOfYear(year, month, day);
    const timeInSec = hour*3600 + min*60 + sec;
    let ticks = Int.plus(DateTime.#yearTicks[year-1900],
                Int.plus(dayOfYear * DateTime.#nsPerDay,
                Int.plus(timeInSec * DateTime.#nsPerSec, ns)));

    // adjust for timezone and dst (we might know the UTC offset)
    const rule = tz.__rule(year);
    let dst;
    if (knownOffset == null) {
      // don't know offset so compute from timezone rule
      ticks -= rule.offset * DateTime.#nsPerSec;
      const dstOffset = TimeZone.__dstOffset(rule, year, month, day, timeInSec);
      if (dstOffset != 0) ticks -= dstOffset * DateTime.#nsPerSec;
      dst = dstOffset != 0;
    }
    else {
      // we known offset, still need to use rule to compute if in dst
      ticks -= knownOffset * DateTime.#nsPerSec;
      dst = knownOffset != rule.offset;
    }

    // compute weekday
    const weekday = (DateTime.__firstWeekday(year, month) + day - 1) % 7;

    // fields
    let fields = 0;
    fields |= ((year-1900) & 0xff) << 0;
    fields |= (month & 0xf) << 8;
    fields |= (day & 0x1f)  << 12;
    fields |= (hour & 0x1f) << 17;
    fields |= (min  & 0x3f) << 22;
    fields |= (weekday & 0x7) << 28;
    fields |= (dst ? 1 : 0) << 31;

    // commit
    const instance = new DateTime(ticks, ns, tz, fields);
    return instance;
  }

//////////////////////////////////////////////////////////////////////////
// Constructor - Date,Time
//////////////////////////////////////////////////////////////////////////

  static __makeDT(d, t, tz=TimeZone.cur()) {
    return DateTime.make(
      d.year(), d.month(), d.day(),
      t.hour(), t.min(), t.sec(), t.nanoSec(), tz);
  }

//////////////////////////////////////////////////////////////////////////
// Constructor - Ticks
//////////////////////////////////////////////////////////////////////////

  static makeTicks(ticks, tz=TimeZone.cur()) {
    // check boundary conditions 1901 to 2099
    if (ticks < DateTime.#minTicks || ticks >= DateTime.#maxTicks)
      throw ArgErr.make("Ticks out of range 1901 to 2099");

    // save ticks, time zone
    const origTicks = ticks;
    const origTz = tz;

    // compute the year
    let year = DateTime.#ticksToYear(ticks);

    // get the time zone rule for this year, and
    // offset the working ticks by UTC offset
    const rule = tz.__rule(year);
    ticks += rule.offset * DateTime.#nsPerSec;

    // compute the day and month; we may need to execute this
    // code block up to three times:
    //   1st: using standard time
    //   2nd: using daylight offset (if in dst)
    //   3rd: using standard time (if dst pushed us back into std)
    let month = 0, day = 0, dstOffset = 0;
    let rem;
    while (true) {
      // recompute year based on working ticks
      year = DateTime.#ticksToYear(ticks);
      rem = ticks - DateTime.#yearTicks[year-1900];
      if (rem < 0) rem += DateTime.#nsPerYear;

      // compute day of the year
      const dayOfYear = Int.div(rem, DateTime.#nsPerDay);
      rem %= DateTime.#nsPerDay;

      // use lookup tables map day of year to month and day
      if (DateTime.isLeapYear(year)) {
        month = DateTime.#monForDayOfYearLeap[dayOfYear];
        day   = DateTime.#dayForDayOfYearLeap[dayOfYear];
      }
      else {
        month = DateTime.#monForDayOfYear[dayOfYear];
        day   = DateTime.#dayForDayOfYear[dayOfYear];
      }

      // if dstOffset is set to max, then this is
      // the third time thru the loop: std->dst->std
      if (dstOffset == null) { dstOffset = 0; break; }

      // if dstOffset is non-zero we have run this
      // loop twice to recompute the date for dst
      if (dstOffset != 0) {
        // if our dst rule is wall time based, then we need to
        // recompute to see if dst wall time pushed us back
        // into dst - if so then run through the loop a third
        // time to get us back to standard time
        if (rule.isWallTime() && TimeZone.__dstOffset(rule, year, month, day, Int.div(rem, DateTime.#nsPerSec)) == 0) {
          ticks -= dstOffset * DateTime.#nsPerSec;
          dstOffset = null;
          continue;
        }
        break;
      }

      // first time in loop; check for daylight saving time,
      // and if dst is in effect then re-run this loop with
      // modified working ticks
      dstOffset = TimeZone.__dstOffset(rule, year, month, day, Int.div(rem, DateTime.#nsPerSec));
      if (dstOffset == 0) break;
      ticks += dstOffset * DateTime.#nsPerSec;
    }

    // compute time of day
    const hour = Int.div(rem, DateTime.#nsPerHr);  rem %= DateTime.#nsPerHr;
    const min  = Int.div(rem, DateTime.#nsPerMin); rem %= DateTime.#nsPerMin;

    // compute weekday
    const weekday = (DateTime.__firstWeekday(year, month) + day - 1) % 7;

    // compute nanos
    rem = ticks >= 0 ? ticks : ticks - DateTime.#yearTicks[0];
    const ns = rem % DateTime.#nsPerSec;

    // fields
    let fields = 0;
    fields |= ((year-1900) & 0xff) << 0;
    fields |= (month & 0xf) << 8;
    fields |= (day & 0x1f)  << 12;
    fields |= (hour & 0x1f) << 17;
    fields |= (min  & 0x3f) << 22;
    fields |= (weekday & 0x7) << 28;
    fields |= (dstOffset != 0 ? 1 : 0) << 31;

    return new DateTime(origTicks, ns, origTz, fields);
  }

//////////////////////////////////////////////////////////////////////////
// Constructor - FromStr
//////////////////////////////////////////////////////////////////////////

  static fromStr(s, checked=true, iso=false) {
    try {
      const num = (s, index) => { return s.charCodeAt(index) - 48; }

      // YYYY-MM-DD'T'hh:mm:ss
      const year  = num(s, 0)*1000 + num(s, 1)*100 + num(s, 2)*10 + num(s, 3);
      const month = num(s, 5)*10   + num(s, 6) - 1;
      const day   = num(s, 8)*10   + num(s, 9);
      const hour  = num(s, 11)*10  + num(s, 12);
      const min   = num(s, 14)*10  + num(s, 15);
      const sec   = num(s, 17)*10  + num(s, 18);

      // check separator symbols
      if (s.charAt(4)  != '-' || s.charAt(7)  != '-' ||
          s.charAt(10) != 'T' || s.charAt(13) != ':' ||
          s.charAt(16) != ':')
        throw new Error();

      // optional .FFFFFFFFF
      let i = 19;
      let ns = 0;
      let tenth = 100000000;
      if (s.charAt(i) == '.') {
        ++i;
        while (true) {
          const c = s.charCodeAt(i);
          if (c < 48 || c > 57) break;
          ns += (c - 48) * tenth;
          tenth /= 10;
          ++i;
        }
      }

      // zone offset
      let offset = 0;
      let c = s.charAt(i++);
      if (c != 'Z') {
        const offHour = num(s, i++)*10 + num(s, i++);
        if (s.charAt(i++) != ':') throw new Error();
        const offMin  = num(s, i++)*10 + num(s, i++);
        offset = offHour*3600 + offMin*60;
        if (c == '-') offset = -offset;
        else if (c != '+') throw new Error();
      }

      // timezone - we share this method b/w fromStr and fromIso
      let tz;
      if (iso) {
        if (i < s.length) throw new Error();
        tz = TimeZone.__fromGmtOffset(offset);
      }
      else {
        if (s.charAt(i++) != ' ') throw new Error();
        tz = TimeZone.fromStr(s.substring(i), true);
      }

      // use local var to capture any exceptions
      const instance = DateTime.__doMake(year, Month.vals().get(month), day, hour, min, sec, ns, offset, tz);
      return instance;
    }
    catch (err) {
      if (!checked) return null;
      if (err instanceof ParseErr) throw err;
      throw ParseErr.makeStr("DateTime", s);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals(obj) {
    if (obj instanceof DateTime) {
      return this.#ticks == obj.#ticks;
    }
    return false;
  }

  hash() { return this.#ticks; }

  compare(obj) {
    const that = obj.#ticks;
    if (this.#ticks < that) return -1; return this.#ticks  == that ? 0 : +1;
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  ticks() { return this.#ticks; }
  date() { return Date.make(this.year(), this.month(), this.day()); }
  time() { return Time.make(this.hour(), this.min(), this.sec(), this.nanoSec()); }
  year() { return (this.#fields & 0xff) + 1900; }
  month() { return Month.vals().get((this.#fields >> 8) & 0xf); }
  day() { return (this.#fields >> 12) & 0x1f; }
  hour() { return (this.#fields >> 17) & 0x1f; }
  min() { return (this.#fields >> 22) & 0x3f; }
  sec() {
    const rem = this.#ticks >= 0 ? this.#ticks : this.#ticks - DateTime.#yearTicks[0];
    return Int.div((rem % DateTime.#nsPerMin),  DateTime.#nsPerSec);
  }
  nanoSec() {
    //var rem = this.m_ticks >= 0 ? this.m_ticks : this.m_ticks - fan.sys.DateTime.yearTicks[0];
    //return rem % fan.sys.DateTime.nsPerSec;
    return this.#ns;
  }
  weekday() { return Weekday.vals().get((this.#fields >> 28) & 0x7); }
  tz() { return this.#tz; }
  dst() { return ((this.#fields >> 31) & 0x1) != 0; }
  tzAbbr() { return this.dst() ? this.#tz.dstAbbr(this.year()) : this.#tz.stdAbbr(this.year()); }

  dayOfYear() { return DateTime.__dayOfYear(this.year(), this.month().ordinal(), this.day())+1; }

  weekOfYear(startOfWeek=Weekday.localeStartOfWeek()) {
    return DateTime.__weekOfYear(this.year(), this.month().ordinal(), this.day(), startOfWeek);
  }

  static __weekOfYear(year, month, day, startOfWeek) {
    const firstWeekday = DateTime.__firstWeekday(year, 0); // zero based
    const lastDayInFirstWeek = 7 - (firstWeekday - startOfWeek.ordinal());

    // special case for first week
    if (month == 0 && day <= lastDayInFirstWeek) return 1;

    // compute from dayOfYear - lastDayInFirstWeek
    const doy = DateTime.__dayOfYear(year, month, day) + 1;
    const woy = Math.floor((doy - lastDayInFirstWeek - 1) / 7);
    return woy + 2; // add first week and make one based
  }

  hoursInDay() {
    const year  = this.year();
    const month = this.month().ordinal();
    const day   = this.day();
    const rule  = this.tz().__rule(year);
    if (rule.dstStart != null) {
      if (TimeZone.__isDstDate(rule, rule.dstStart, year, month, day)) return 23;
      if (TimeZone.__isDstDate(rule, rule.dstEnd, year, month, day))   return 25;
    }
    return 24;
  }

/////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  toLocale(pattern=null, locale=Locale.cur()) {
    // locale specific default
    if (pattern == null) {
      const pod = Pod.find("sys");
      pattern = Env.cur().locale(pod, "dateTime", "D-MMM-YYYY WWW hh:mm:ss zzz", locale);
    }

    return DateTimeStr.makeDateTime(pattern, locale, this).format();
  }

  static fromLocale(s, pattern, tz=TimeZone.cur(), checked=true) {
    return DateTimeStr.make(pattern, null).parseDateTime(s, tz, checked);
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  minusDateTime(time) {
    return Duration.make(this.#ticks-time.#ticks);
  }

  plus(duration) {
    const d = duration.ticks();
    if (d == 0) return this;
    return DateTime.makeTicks(this.#ticks+d, this.#tz);
  }

  minus(duration) {
    const d = duration.ticks();
    if (d == 0) return this;
    return DateTime.makeTicks(this.#ticks-d, this.#tz);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  toTimeZone(tz) {
    if (this.#tz == tz) return this;
    if (tz == TimeZone.rel() || this.#tz == TimeZone.rel()) {
      return DateTime.make(
        this.year(), this.month(), this.day(),
        this.hour(), this.min(), this.sec(), this.nanoSec(), tz);
    }
    else {
      return DateTime.makeTicks(this.#ticks, tz);
    }
  }

  toUtc() { return this.toTimeZone(TimeZone.utc()); }

  toRel() { return this.toTimeZone(TimeZone.rel()); }

  floor(accuracy) {
    if (this.#ticks % accuracy.ticks() == 0) return this;
    return DateTime.makeTicks(this.#ticks - (this.#ticks % accuracy.ticks()), this.#tz);
  }

  midnight() { return DateTime.make(this.year(), this.month(), this.day(), 0, 0, 0, 0, this.#tz); }

  isMidnight() { return this.hour() == 0 && this.min() == 0 && this.sec() == 0 && this.nanoSec() == 0; }

  toStr() { return this.toLocale("YYYY-MM-DD'T'hh:mm:ss.FFFFFFFFFz zzzz"); }

  static isLeapYear(year) {
    if ((year & 3) != 0) return false;
    return (year % 100 != 0) || (year % 400 == 0);
  }

  static weekdayInMonth(year, mon, weekday, pos) {
    mon = mon.ordinal();
    weekday = weekday.ordinal();

    // argument checking
    DateTime.#checkYear(year);
    if (pos == 0) throw ArgErr.make("Pos is zero");

    // compute the weekday of the 1st of this month (0-6)
    const firstWeekday = DateTime.__firstWeekday(year, mon);

    // get number of days in this month
    const numDays = DateTime.__numDaysInMonth(year, mon);

    if (pos > 0) {
      let day = weekday - firstWeekday + 1;
      if (day <= 0) day = 8 - firstWeekday + weekday;
      day += (pos-1)*7;
      if (day > numDays) throw ArgErr.make("Pos out of range " + pos);
      return day;
    }
    else {
      const lastWeekday = (firstWeekday + numDays - 1) % 7;
      let off = lastWeekday - weekday;
      if (off < 0) off = 7 + off;
      off -= (pos+1)*7;
      const day = numDays - off;
      if (day < 1) throw ArgErr.make("Pos out of range " + pos);
      return day;
    }
  }

  static __dayOfYear(year, mon, day) {
    return DateTime.isLeapYear(year) ?
      DateTime.#dayOfYearForFirstOfMonLeap[mon] + day - 1 :
      DateTime.#dayOfYearForFirstOfMon[mon] + day - 1;
  }

  static __numDaysInMonth(year, month) {
    if (month == 1 && DateTime.isLeapYear(year))
      return 29;
    else
      return DateTime.#daysInMon[month];
  }

  static #ticksToYear(ticks) {
    // estimate the year to get us in the ball park, then
    // match the exact year using the yearTicks lookup table
    let year = Int.div(ticks, DateTime.#nsPerYear) + 2000;
    if (DateTime.#yearTicks[year-1900] > ticks) year--;
    return year;
  }

  static __firstWeekday(year, mon) {
    // get the 1st day of this month as a day of year (0-365)
    const firstDayOfYear = DateTime.isLeapYear(year)
      ? DateTime.#dayOfYearForFirstOfMonLeap[mon]
      : DateTime.#dayOfYearForFirstOfMon[mon];

    // compute the weekday of the 1st of this month (0-6)
    return (DateTime.#firstWeekdayOfYear[year-1900] + firstDayOfYear) % 7;
  }

  static #checkYear(year) {
    if (year < 1901 || year > 2099)
      throw ArgErr.make("Year out of range " + year);
  }

//////////////////////////////////////////////////////////////////////////
// Native
//////////////////////////////////////////////////////////////////////////

  toJava() { return (this.#ticks / DateTime.#nsPerMilli) + 946684800000; }

  static fromJava(millis, tz=TimeZone.cur(), negIsNull=true) {
    if (millis <= 0 && negIsNull) return null;
    const ticks = (millis - 946684800000) * DateTime.#nsPerMilli;
    return DateTime.makeTicks(ticks, tz);
  }

  toJs() {
    const ms = (this.#ticks / DateTime.#nsPerMilli) + 946684800000;
    return new js.Date(ms);
  }

  static fromJs(jsdate, tz=TimeZone.cur()) {
    return DateTime.fromJava(jsdate.getTime(), tz);
  }

//////////////////////////////////////////////////////////////////////////
// HTTP
//////////////////////////////////////////////////////////////////////////

  toHttpStr() {
    return this.toTimeZone(TimeZone.utc()).toLocale(
      "WWW, DD MMM YYYY hh:mm:ss", Locale.fromStr("en")) + " GMT";
  }

  static fromHttpStr(s, checked=true) {
    const oldLoc = Locale.cur();
    const formats = ["WWW, DD MMM YYYY hh:mm:ss zzz",
                  "WWWW, DD-MMM-YY hh:mm:ss zzz",
                  // NOTE: this is not actual pattern for asctime(), but
                  // DateTime.fromLocale does not honor multiple spaces in a row.
                  // Not sure if that is a bug or not. Actual format is
                  //      "WWW MMM  D hh:mm:ss YYYY"
                  "WWW MMM D hh:mm:ss YYYY",]
    try {
      Locale.setCur(Locale.en());
      // Need to see if it is asctime() format and tweak the input s
      // so that it will match using DateTime.fromLocale
      let temp = s;
      if (s.substring(0, 9).endsWith('  '))
        temp = s.substring(0,8) + s.substring(9);
      for (let i = 0; i < formats.length; ++i) {
        const dt = DateTime.fromLocale(temp, formats[i], TimeZone.utc(), false);
        if (dt != null) return dt;
      }
    }
    finally {
      Locale.setCur(oldLoc);
    }
    if (!checked) return null;
    throw ParseErr.make("Invalid HTTP DateTime: '" + s + "'")
  }

//////////////////////////////////////////////////////////////////////////
// ISO 8601
//////////////////////////////////////////////////////////////////////////

  toIso() { return this.toLocale("YYYY-MM-DD'T'hh:mm:ss.FFFFFFFFFz"); }

  static fromIso(s, checked=true) { return DateTime.fromStr(s, checked, true); }

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

  toCode() {
    if (this.equals(DateTime.defVal())) return "DateTime.defVal";
    return "DateTime(\"" + this.toString() + "\")";
  }

//////////////////////////////////////////////////////////////////////////
// Lookup Tables
//////////////////////////////////////////////////////////////////////////

  // ns ticks for jan 1 of year 1900-2100
  static #yearTicks = [];

  // first weekday (0-6) of year indexed by year 1900-2100
  static #firstWeekdayOfYear = [];

  static { 
    DateTime.#yearTicks[0] = -3155673600000000000; // ns ticks for 1900
    DateTime.#firstWeekdayOfYear[0] = 1;
    for (let i=1; i<202; ++i) {
      let daysInYear = 365;
      if (DateTime.isLeapYear(i+1900-1)) daysInYear = 366;
      DateTime.#yearTicks[i] = DateTime.#yearTicks[i-1] + daysInYear * DateTime.#nsPerDay;
      DateTime.#firstWeekdayOfYear[i] = (DateTime.#firstWeekdayOfYear[i-1] + daysInYear) % 7;
    }
  }

  // number of days in each month indexed by month (0-11)
  static #daysInMon     = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];
  static #daysInMonLeap = [ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];

  // day of year (0-365) for 1st day of month (0-11)
  static #dayOfYearForFirstOfMon     = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  static #dayOfYearForFirstOfMonLeap = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  static {
    for (let i=1; i<12; ++i) {
      DateTime.#dayOfYearForFirstOfMon[i] =
        DateTime.#dayOfYearForFirstOfMon[i-1] + DateTime.#daysInMon[i-1];

      DateTime.#dayOfYearForFirstOfMonLeap[i] =
        DateTime.#dayOfYearForFirstOfMonLeap[i-1] + DateTime.#daysInMonLeap[i-1];
    }
  }

  // month and day of month indexed by day of the year (0-365)
  static #monForDayOfYear     = [];
  static #dayForDayOfYear     = [];
  static #monForDayOfYearLeap = [];
  static #dayForDayOfYearLeap = [];
  static #fillInDayOfYear(mon, days, daysInMon, len) {
    let m = 0, d = 1;
    for (let i=0; i<len; ++i) {
      mon[i] = m; days[i] = d++;
      if (d > daysInMon[m]) { m++; d = 1; }
    }
  }
  static {
    DateTime.#fillInDayOfYear(DateTime.#monForDayOfYear, DateTime.#dayForDayOfYear, DateTime.#daysInMon, 365);
    DateTime.#fillInDayOfYear(DateTime.#monForDayOfYearLeap, DateTime.#dayForDayOfYearLeap, DateTime.#daysInMonLeap, 366);
  }
}