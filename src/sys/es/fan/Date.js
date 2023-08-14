//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Feb 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   17 Apr 2023  Matthew Giannini Refactor to ES
//

/**
 * Date
 */
class Date extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(year, month, day) {
    super();
    this.#year = year;
    this.#month = month;
    this.#day = day;
  }
  
  #year;
  #month;
  #day;

  static #defVal;
  static defVal() {
    if (!Date.#defVal) Date.#defVal = new Date(2000, 0, 1)
    return Date.#defVal;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  equals(that) {
    if (that instanceof Date) {
      return this.#year.valueOf() == that.#year.valueOf() &&
            this.#month.valueOf() == that.#month.valueOf() &&
            this.#day.valueOf() == that.#day.valueOf();
    }
    return false;
  }

  compare(that) {
    if (this.#year.valueOf() == that.#year.valueOf()) {
      if (this.#month.valueOf() == that.#month.valueOf())
      {
        if (this.#day.valueOf() == that.#day.valueOf()) return 0;
        return this.#day < that.#day ? -1 : +1;
      }
      return this.#month < that.#month ? -1 : +1;
    }
    return this.#year < that.#year ? -1 : +1;
  }

  toIso() { return this.toStr(); }

  hash() { return (this.#year << 16) ^ (this.#month << 8) ^ this.#day; }

  toStr() {
    if (this.str$ == null) this.str$ = this.toLocale("YYYY-MM-DD");
    return this.str$;
  }

  year() { return this.#year; }
  month() { return Month.vals().get(this.#month); }
  day() { return this.#day; }

  weekday() {
    const weekday = (DateTime.__firstWeekday(this.#year, this.#month) + this.#day - 1) % 7;
    return Weekday.vals().get(weekday);
  }

  dayOfYear() { 
    return DateTime.__dayOfYear(this.year(), this.month().ordinal(), this.day())+1; 
  }

  weekOfYear(startOfWeek=Weekday.localeStartOfWeek()) {
    return DateTime.__weekOfYear(this.year(), this.month().ordinal(), this.day(), startOfWeek);
  }

  plus(d) {
    let ticks = d.ticks();

    // check even number of days
    if (ticks % Duration.nsPerDay$ != 0)
      throw ArgErr.make("Duration must be even num of days");

    let year = this.#year;
    let month = this.#month;
    let day = this.#day;

    let numDays = Int.div(ticks, Duration.nsPerDay$);
    const dayIncr = numDays < 0 ? +1 : -1;
    while (numDays != 0) {
      if (numDays > 0) {
        day++;
        if (day > this.#numDays(year, month)) {
          day = 1;
          month++;
          if (month >= 12) { month = 0; year++; }
        }
        numDays--;
      }
      else {
        day--;
        if (day <= 0) {
          month--;
          if (month < 0) { month = 11; year--; }
          day = this.#numDays(year, month);
        }
        numDays++;
      }
    }

    return new Date(year, month, day);
  }

  minus(d) { return this.plus(d.negate()); }

  minusDate(that) {
    // short circuit if equal
    if (this.equals(that)) return Duration.defVal();

    // compute so that a < b
    let a = this;
    let b = that;
    if (a.compare(b) > 0) { b = this; a = that; }

    // compute difference in days
    let days = 0;
    if (a.#year == b.#year) {
      days = b.dayOfYear() - a.dayOfYear(); }
    else
    {
      days = (DateTime.isLeapYear(a.#year) ? 366 : 365) - a.dayOfYear();
      days += b.dayOfYear();
      for (let i=a.#year+1; i<b.#year; ++i)
        days += DateTime.isLeapYear(i) ? 366 : 365;
    }

    // negate if necessary if a was this
    if (a == this) days = -days;

    // map days into ns ticks
    return Duration.make(days * Duration.nsPerDay$);
  }

  #numDays(year, mon) { return DateTime.__numDaysInMonth(year, mon); }

  firstOfMonth() {
    if (this.#day == 1) return this;
    return new Date(this.#year, this.#month, 1);
  }

  lastOfMonth() {
    const last = this.month().numDays(this.#year);
    if (this.#day == last) return this;
    return new Date(this.#year, this.#month, last);
  }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  toLocale(pattern=null, locale=Locale.cur()) {
    // locale specific default
    if (pattern == null) {
      const pod = Pod.find("sys");
      pattern = Env.cur().locale(pod, "date", "D-MMM-YYYY", locale);
    }
    return DateTimeStr.makeDate(pattern, locale, this).format();
  }

  static fromLocale(s, pattern=null, checked=true) {
    return DateTimeStr.make(pattern, null).parseDate(s, checked);
  }

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

  static make(year, month, day) {
    return new Date(year, month.ordinal(), day);
  }

  static today(tz=TimeZone.cur()) {
    return DateTime.makeTicks(DateTime.nowTicks(), tz).date();
  }

  static yesterday(tz=TimeZone.cur()) {
    return Date.today(tz).minus(Duration.oneDay$());
  }

  static tomorrow(tz=TimeZone.cur()) {
    return Date.today(tz).plus(Duration.oneDay$());
  }

  static fromStr(s, checked=true) {
    try {
      const num = function(x, index) { return x.charCodeAt(index) - 48; }

      // YYYY-MM-DD
      const year  = num(s, 0)*1000 + num(s, 1)*100 + num(s, 2)*10 + num(s, 3);
      const month = num(s, 5)*10   + num(s, 6) - 1;
      const day   = num(s, 8)*10   + num(s, 9);

      // check separator symbols and length
      if (s.charAt(4) != '-' || s.charAt(7) != '-' || s.length != 10)
        throw new Error();

      return new Date(year, month, day);
    }
    catch (err) {
      if (!checked) return null;
      throw ParseErr.makeStr("Date", s);
    }
  }

  static fromIso(s, checked=true) { return Date.fromStr(s, checked); }

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

  isYesterday() { return this.equals(Date.today().plus(Duration.negOneDay$())); }
  isToday() { return this.equals(Date.today()); }
  isTomorrow() { return this.equals(Date.today().plus(Duration.oneDay$())); }

  toDateTime(t, tz=TimeZone.cur()) {
    return DateTime.__makeDT(this, t, tz);
  }

  midnight(tz=TimeZone.cur()) {
    return DateTime.__makeDT(this, Time.defVal(), tz);
  }

  toCode() {
    if (this.equals(Date.defVal())) return "Date.defVal";
    return "Date(\"" + this.toString() + "\")";
  }

}