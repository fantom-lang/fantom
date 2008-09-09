//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Oct 07  Andy Frank  Creation
//

using System;
using System.Collections;
using System.IO;
using Fanx.Util;

namespace Fan.Sys
{
  /// <summary>
  /// TimeZone.
  /// </summary>
  public sealed class TimeZone : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    public static List listNames()
    {
      List list = new List(Sys.StrType);
      for (int i=0; i<indexNames.Length; ++i)
        if ((indexTypes[i] & 0x01) != 0)
          list.add(Str.make(indexNames[i]));
      return list.ro();
    }

    public static List listFullNames()
    {
      List list = new List(Sys.StrType);
      for (int i=0; i<indexNames.Length; ++i)
        if ((indexTypes[i] & 0x02) != 0)
          list.add(Str.make(indexNames[i]));
      return list.ro();
    }

    public static TimeZone fromStr(Str name) { return fromStr(name.val, true); }
    public static TimeZone fromStr(Str name, Bool check) { return fromStr(name.val, check.val); }
    public static TimeZone fromStr(string name, bool check)
    {
      // check cache first
      TimeZone tz;
      lock (cache)
      {
        tz = (TimeZone)cache[name];
        if (tz != null) return tz;
      }

      // try to load from database
      try
      {
        tz = loadTimeZone(name);
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
        throw IOErr.make("Cannot load from timezone database: " + name).val;
      }

      // if found, then cache and return
      if (tz != null)
      {
        lock (cache)
        {
          cache[tz.m_name.val] = tz;
          cache[tz.m_fullName.val] = tz;
          return tz;
        }
      }

      // not found
      if (check) throw ParseErr.make("TimeZone not found: " + name).val;
      return null;
    }

    public static TimeZone utc()
    {
      return m_utc;
    }

    public static TimeZone current()
    {
      return m_current;
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Str toStr() { return m_name; }

    public override Type type() { return Sys.TimeZoneType; }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public Str name()
    {
      return m_name;
    }

    public Str fullName()
    {
      return m_fullName;
    }

    public Duration offset(Int year)
    {
      return Duration.make(rule((int)year.val).offset * Duration.nsPerSec);
    }

    public Duration dstOffset(Int year)
    {
      Rule r = rule((int)year.val);
      if (r.dstOffset == 0) return null;
      return Duration.make(r.dstOffset * Duration.nsPerSec);
    }

    public Str stdAbbr(Int year)
    {
      return Str.make(rule((int)year.val).stdAbbr);
    }

    public Str dstAbbr(Int year)
    {
      return Str.make(rule((int)year.val).dstAbbr);
    }

    public string abbr(int year, bool inDST)
    {
      return inDST ? rule(year).dstAbbr : rule(year).stdAbbr;
    }

    internal Rule rule(int year)
    {
      // most hits should be in latest rule
      Rule rule = rules[0];
      if (year >= rule.startYear) return rule;

      // check historical time zones
      for (int i=1; i<rules.Length; ++i)
        if (year >= (rule = rules[i]).startYear) return rule;

      // return oldest rule
      return rules[rules.Length-1];
    }

    // This is mostly for testing right.
//    java.util.TimeZone java()
//    {
//      return java.util.TimeZone.getTimeZone(name.val);
//    }

  //////////////////////////////////////////////////////////////////////////
  // Database
  //////////////////////////////////////////////////////////////////////////

    //
    // TimeZone database format:
    //
    // ftz
    // {
    //   u8  magic ("fantz 01")
    //   utf summary
    //   u4  numIndexItems
    //   indexItems[]
    //   {
    //     utf  name
    //     u1   0x01=simple name, 0x02=full name
    //     u4   fileOffset
    //   }
    //   timeZones[]
    //   {
    //     utf  name
    //     utf  fullName
    //     u2   numRules
    //     rules[]
    //     {
    //       u2   startYear
    //       i4   utcOffset (seconds)
    //       utf  stdAbbr
    //       i4   dstOffset (seconds); if zero rest is skipped
    //       [
    //         utf       dstAbbr
    //         dstTime   dstStart
    //         dstTime   dstEnd
    //       ]
    //     }
    //   }
    //
    //   dstTime
    //   {
    //     u1  month
    //     u1  onMode 'd', 'l', '>', '<' (date, last, >=, and <=)
    //     u1  onWeekday (0-6)
    //     u1  onDay
    //     i4  atTime (seconds)
    //     u1  atMode 'w' , 's', 'u' (wall, standad, universal)
    //   }
    //
    //  The timezone database is generated by the "/adm/buildtz.fan"
    //  script.  Refer to the "zic.8.txt" source file the code
    //  distribution of the Olsen database to further describe
    //  model of the original data.
    //

    /// <summary>
    /// Load the name and file offset list from file into memory.
    /// </summary>
    static void loadIndex()
    {
      DataReader reader = new DataReader(new BufferedStream(dbFile.OpenRead()));
      try
      {
        // check magic "fantz 01"
        long magic = reader.ReadLong();
        if (magic != 0x66616e747a203031L)
          throw new IOException("Invalid magic 0x" + magic.ToString("X").ToLower());
        reader.ReadUTF();

        // load the name/offset pairs and verify in sort order
        int num = reader.ReadInt();
        indexNames   = new string[num];
        indexTypes   = new byte[num];
        indexOffsets = new int[num];
        for (int i=0; i<num; ++i)
        {
          indexNames[i]   = reader.ReadUTF();
          indexTypes[i]   = (byte)reader.ReadByte();
          indexOffsets[i] = reader.ReadInt();
          if (i != 0 && String.Compare(indexNames[i-1], indexNames[i], StringComparison.Ordinal) >= 0)
            throw new IOException("Index not sorted");
        }
      }
      finally
      {
        reader.Close();
      }
    }

    /// <summary>
    /// Find the specified name in the index and load a time zone
    /// definition.  If the name is not found then return null.
    /// </summary>
    static TimeZone loadTimeZone(string name)
    {
      // find index, which maps the file offset
      int ix = Array.BinarySearch(indexNames, name);
      if (ix < 0) return null;
      int seekOffset = indexOffsets[ix];

      // create time zone instance
      TimeZone tz = new TimeZone();
      tz.m_name = Str.make(name);

      // read time zone definition from database file
      FileStream f = dbFile.OpenRead();
      DataReader d = new DataReader(f);
      try
      {
        f.Seek(seekOffset, SeekOrigin.Begin);
        tz.m_name     = Str.make(d.ReadUTF());
        tz.m_fullName = Str.make(d.ReadUTF());
        int numRules  = d.ReadUnsignedShort();
        tz.rules = new Rule[numRules];
        for (int i=0; i<numRules; ++i)
        {
          Rule r = tz.rules[i] = new Rule();
          r.startYear = d.ReadUnsignedShort();
          r.offset    = d.ReadInt();
          r.stdAbbr   = d.ReadUTF();
          r.dstOffset = d.ReadInt();
          if (r.dstOffset == 0) continue;
          r.dstAbbr   = d.ReadUTF();
          r.dstStart  = loadDstTime(d);
          r.dstEnd    = loadDstTime(d);
          if (i != 0 && tz.rules[i-1].startYear <= r.startYear)
            throw new IOException("TimeZone rules not sorted: " + name);
        }
      }
      finally
      {
        f.Close();
      }
      return tz;
    }

    static DstTime loadDstTime(DataReader d)
    {
      DstTime t = new DstTime();
      t.mon       = d.ReadByte();
      t.onMode    = d.ReadByte();
      t.onWeekday = d.ReadByte();
      t.onDay     = d.ReadByte();
      t.atTime    = d.ReadInt();
      t.atMode    = d.ReadByte();
      return t;
    }

  //////////////////////////////////////////////////////////////////////////
  // DST Calculations
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Compute the daylight savings time offset (in seconds)
    /// for the specified parameters:
    ///  - Rule:    the rule for a given year
    ///  - mon:     month 0-11
    ///  - day:     day 1-31
    ///  - weekday: 0-6
    ///  - time:    seconds since midnight
    /// </summary>
    internal static int dstOffset(Rule rule, int year, int mon, int day, int time)
    {
      DstTime start = rule.dstStart;
      DstTime end   = rule.dstEnd;

      if (start == null) return 0;

      int s = compare(rule, start, year, mon, day, time);
      int e = compare(rule, end,   year, mon, day, time);

      // if end month comes earlier than start month,
      // then this is dst in southern hemisphere
      if (end.mon < start.mon)
      {
        if (e > 0 || s <= 0) return rule.dstOffset;
      }
      else
      {
        if (s <= 0 && e > 0) return rule.dstOffset;
      }

      return 0;
    }

    /// <summary>
    /// Compare the specified time to the dst start/end time.
    /// Return -1 if x < specified time and +1 if x > specified time.
    /// </summary>
    static int compare(Rule rule, DstTime x, int year, int mon, int day, int time)
    {
      int c = compareMonth(x, mon);
      if (c != 0) return c;

      c = compareOnDay(rule, x, year, mon, day);
      if (c != 0) return c;

      return compareAtTime(rule, x, time);
    }

    /// <summary>
    /// Compare month
    /// </summary>
    static int compareMonth(DstTime x, int mon)
    {
      if (x.mon < mon) return -1;
      if (x.mon > mon) return +1;
      return 0;
    }

    /// <summary>
    /// Compare on day.
    ///     'd'  5        the fifth of the month
    ///     'l'  lastSun  the last Sunday in the month
    ///     'l'  lastMon  the last Monday in the month
    ///     '>'  Sun>=8   first Sunday on or after the eighth
    ///     '<'  Sun<=25  last Sunday on or before the 25th (not used)
    /// </summary>
    static int compareOnDay(Rule rule, DstTime x, int year, int mon, int day)
    {
      // universal atTime might push us into the previous day
      if (x.atMode == 'u' && rule.offset + x.atTime < 0)
        ++day;

      switch (x.onMode)
      {
        case (byte)'d':
          if (x.onDay < day) return -1;
          if (x.onDay > day) return +1;
          return 0;

        case (byte)'l':
          int last = DateTime.weekdayInMonth(year, mon, x.onWeekday, -1);
          if (last < day) return -1;
          if (last > day) return +1;
          return 0;

        case (byte)'>':
          int start = DateTime.weekdayInMonth(year, mon, x.onWeekday, 1);
          while (start < x.onDay) start += 7;
          if (start < day) return -1;
          if (start > day) return +1;
          return 0;

        default:
          throw new Exception(""+(char)x.onMode);
      }
    }

    /// <summary>
    /// Compare at time.
    /// </summary>
    static int compareAtTime(Rule rule, DstTime x, int time)
    {
      int atTime = x.atTime;

      // if universal time, then we need to move atTime back to
      // local time (we might cross into the previous day)
      if (x.atMode == 'u')
      {
        if (rule.offset + x.atTime < 0)
          atTime = 24*60*60 + rule.offset + x.atTime;
        else
          atTime += rule.offset;
      }

      if (atTime < time) return -1;
      if (atTime > time) return +1;
      return 0;
    }

  //////////////////////////////////////////////////////////////////////////
  // Rule
  //////////////////////////////////////////////////////////////////////////

    internal class Rule
    {
      /// <summary>
      /// Return if this rule is wall time based.  We take a shortcut
      /// and assume that both start/end both use the same atMode - right
      /// now (2007) it appears this is a valid assumption with the
      /// single obscure exception being "Pacific/Tongatapu"
      /// </summary>
      public bool isWallTime() { return dstStart.atMode == 'w'; }

      public int startYear;     // year rule took effect
      public int offset;        // UTC offset in seconds
      public string stdAbbr;    // standard time abbreviation
      public int dstOffset;     // seconds
      public string dstAbbr;    // daylight time abbreviation
      public DstTime dstStart;  // starting time
      public DstTime dstEnd;    // end time
    }

    internal class DstTime
    {
      public byte mon;          // month (0-11)
      public byte onMode;       // 'd', 'l', '>', '<' (date, last, >=, and <=)
      public byte onWeekday;    // weekday (0-6)
      public byte onDay;        // weekday (0-6)
      public int  atTime;       // seconds
      public byte atMode;       // 'w' , 's', 'u' (wall, standard, universal)
    }

  //////////////////////////////////////////////////////////////////////////
  // Database Index
  //////////////////////////////////////////////////////////////////////////

    static FileInfo dbFile = new FileInfo(Sys.HomeDir + "/lib/timezones.ftz");
    static string[] indexNames = new string[0];
    static byte[] indexTypes   = new byte[0];
    static int[] indexOffsets  = new int[0];

    static Hashtable cache = new Hashtable(); // Str -> TimeZone
    internal static TimeZone m_utc;
    internal static TimeZone m_current = null;

    static TimeZone()
    {
      try
      {
        loadIndex();
      }
      catch (Exception e)
      {
        System.Console.WriteLine("ERROR: Cannot load timezone database");
        Err.dumpStack(e);
      }

      try
      {
        m_utc = fromStr(Str.make("Etc/UTC"));
      }
      catch (Exception e)
      {
        System.Console.WriteLine("ERROR: Cannot init UTC timezone");
        Err.dumpStack(e);

        m_utc.m_name = m_utc.m_fullName = Str.make("UTC");
        m_utc.rules = new Rule[] { new Rule() };
      }

      try
      {
        // first check system property
        Str sysProp = (Str)Sys.env().get(Str.make("fan.timezone"));
        if (sysProp != null)
        {
          m_current = fromStr(sysProp);
        }

        // we assume Java default uses Olsen name
        else
        {
          // TODO - no clue how to auto map this yet
          //current = fromStr(Str.make(java.util.TimeZone.getDefault().getID()));
          m_current = fromStr(Str.make("America/New_York"));
        }
      }
      catch (Exception e)
      {
        System.Console.WriteLine("ERROR: Cannot init current timezone");
        Err.dumpStack(e);

        m_current = m_utc;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Str m_name;       // time zone identifer
    private Str m_fullName;   // identifer in zoneinfo database
    private Rule[] rules;     // reverse sorted by year

  }
}