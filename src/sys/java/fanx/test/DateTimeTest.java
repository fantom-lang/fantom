//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//
package fanx.test;

import fan.sys.*;
import fan.sys.TimeZone;
import java.text.*;
import java.util.Date;
import java.util.*;

/**
 * DateTimeTest
 */
public class DateTimeTest
  extends Test
{

/*
  27 Oct 2007
  -----------
  Running the brute force test verifies that most of the common timezones
  work correctly 2000 to 2015.  The following historical time zones don't
  pass - I think it is because all of them switch offset in the middle of
  a year, where I've optimized rules to be year based:

  ERRORS:
    America/Araguaina  2002  2003
    America/Argentina/Buenos_Aires  2000
    America/Argentina/Catamarca  2000  2004
    America/Argentina/Cordoba  2000
    America/Argentina/Jujuy  2000
    America/Argentina/La_Rioja  2000  2004
    America/Argentina/Mendoza  2000  2004
    America/Argentina/Rio_Gallegos  2000  2004
    America/Argentina/San_Juan  2000  2004
    America/Argentina/Tucuman  2000  2004
    America/Argentina/Ushuaia  2000  2004
    America/Bahia  2002  2003
    America/Boa_Vista  2000
    America/Cambridge_Bay  2000  2001
    America/Cuiaba  2002  2003  2004
    America/Fortaleza  2000  2001  2002
    America/Havana  2004  2005  2006
    America/Indiana/Knox  2005  2006
    America/Indiana/Petersburg  2005  2006  2007
    America/Indiana/Tell_City  2005  2006
    America/Indiana/Vincennes  2005  2006  2007
    America/Indiana/Winamac  2005  2006  2007
    America/Iqaluit  2000
    America/Kentucky/Monticello  2000
    America/Maceio  2000  2001  2002
    America/Mexico_City  2001
    America/Montevideo  2004
    America/Noronha  2000  2001  2002
    America/North_Dakota/New_Salem  2002  2003
    America/Pangnirtung  2000
    America/Rankin_Inlet  2000  2001
    America/Recife  2000  2001  2002
    America/Resolute  2000  2001  2005  2006
    America/Santo_Domingo  2000
    Asia/Aqtau  2005
    Asia/Bishkek  2005
    Asia/Colombo  2006
    Asia/Dili  2000
    Asia/Oral  2005
    Asia/Tbilisi  2004  2005
    Australia/Eucla  2006  2007  2009
    Australia/Perth  2006  2007  2009
    Pacific/Fiji  2000
    Pacific/Tongatapu  2000  2002
*/

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  public void run()
    throws Exception
  {

    verifyTz("Etc/UTC", 1990);
    verifyTz("America/New_York", 1990);
    verifyTz("America/Chicago", 1990);
    verifyTz("America/Denver", 1990);
    verifyTz("America/Phoenix", 1990);
    verifyTz("America/Los_Angeles", 1990);
    verifyTz("Europe/London", 2000);
    verifyTz("Europe/Paris", 2000);
    verifyTz("Europe/Amsterdam", 2000);
    verifyTz("Europe/Riga", 1995);
    verifyTz("Australia/Sydney", 2000);
    verifyTz("America/Godthab", 2000);

    verifyTzInit();

    // this test is basically a brute-force check and very slow,
    // we don't normally run thru every timezone
    if (true) return;

    fan.sys.List all = fan.sys.TimeZone.listNames();
    for (int i=0; i<all.sz(); ++i)
      verifyTz(all.get(i).toString(), 2000);

    ErrRec[] errs = (ErrRec[])errors.values().toArray(new ErrRec[errors.size()]);
    Arrays.sort(errs);
    System.out.println();
    System.out.println("ERRORS:");
    for (int i=0; i<errs.length; ++i)
    {
      ErrRec err = errs[i];
      System.out.print("  " + err.name);
      for (int j=0; j<err.years.size(); ++j)
        System.out.print("  " + err.years.get(j));
      System.out.println();
    }
  }

  public void verifyTz(String tzName, int startYear)
  {
    System.out.print("     " + tzName + ": ");

    tzFan  = fan.sys.TimeZone.fromStr(tzName);
    tzJava = java.util.TimeZone.getTimeZone(tzName);
    num = 0;
    curYear = -1;

    cal.setTimeZone(tzJava);
    cal.set(Calendar.MILLISECOND, 0);

    cal.set(startYear, 1, 1, 0, 0, 0);
    long startMillis = cal.getTime().getTime();

    cal.set(2015, 1, 1, 0, 0, 0);
    long endMillis = cal.getTime().getTime();

    Random rand = new Random();
    long millis = startMillis + rand.nextInt(10000);
    while (true)
    {
      millis += 10L * 60L * 1000L + rand.nextInt(50000000);
      if (millis > endMillis) break;
      verifyTzAt(millis);
    }

    System.out.println();
  }

  public void verifyTzAt(long millis)
  {
    Date date = new Date(millis);
    cal.setTime(date);
    DateTime dt = DateTime.makeTicks(Long.valueOf((millis-946684800000L)*1000000L), tzFan);
    int year = cal.get(Calendar.YEAR);
    String name = tzFan.name();

    try
    {
      verifyEq(year,                             dt.year());
      verifyEq(cal.get(Calendar.MONTH),          dt.month().ordinal());
      verifyEq(cal.get(Calendar.DAY_OF_MONTH),   dt.day());
      verifyEq(cal.get(Calendar.HOUR_OF_DAY),    dt.hour());
      verifyEq(cal.get(Calendar.MINUTE),         dt.min());
      verifyEq(cal.get(Calendar.SECOND),         dt.sec());
      verifyEq(cal.get(Calendar.DAY_OF_WEEK)-1,  dt.weekday().ordinal());
      verifyEq(cal.getTimeZone().inDaylightTime(date), dt.dst());
    }
    catch (RuntimeException e)
    {
      ErrRec rec = (ErrRec)errors.get(name);
      if (rec == null) errors.put(name, rec = new ErrRec(name));
      rec.addYear(year);
    }

    if (year != curYear)
    {
      curYear = year;
      System.out.print(" " + (curYear%100<10?"0":"") + (curYear%100));
      System.out.flush();
    }

    num++;
    //if (num % 1000 == 0) System.out.println("  " + f.format(cal.getTime()));
  }

//////////////////////////////////////////////////////////////////////////
// Test the various hacks for dealing with Unix boxes
//////////////////////////////////////////////////////////////////////////

  public void verifyTzInit()
  {
    String os = Sys.os;
    verifyTzInit("New_York", "America/New_York");
    verifyTzInit("America/New_York", "America/New_York");
    verifyTzInit("Europe/London", "Europe/London");

    verifyTzInit("GMT0", "Etc/UTC");
    verifyTzInit("GMT+00:00", "Etc/UTC");
    verifyTzInit("GMT-00:00", "Etc/UTC");

    verifyTzInit("GMT-13:00", "Etc/GMT-13");
    verifyTzInit("GMT-10:00", "Etc/GMT-10");
    verifyTzInit("GMT-05:00", "Etc/GMT-5");
    verifyTzInit("GMT+06:00", "Etc/GMT+6");
    verifyTzInit("GMT+12:00", "Etc/GMT+12");
    verifyTzInit("GMT+6:00",  "Etc/GMT+6");
    verifyTzInit("GMT-5:00",  "Etc/GMT-5");

    verifyTzInit("US/Eastern",  "America/New_York");
    verifyTzInit("US/Central",  "America/Chicago");
    verifyTzInit("US/Mountain", "America/Denver");
    verifyTzInit("US/Pacific",  "America/Los_Angeles");
    verifyTzInit("US/Arizona",  "America/Phoenix");
  }

  public void verifyTzInit(String java, String fullName)
  {
    TimeZone tz = TimeZone.fromJava(java);
    verify(tz.fullName(), fullName);
  }

  static class ErrRec implements Comparable
  {
    ErrRec(String n) { name = n; }

    void addYear(int year)
    {
      Integer y = new Integer(year);
      if (!years.contains(y)) years.add(y);
    }

    public int compareTo(Object o) { return name.compareTo(((ErrRec)o).name); }

    String name;
    ArrayList years = new ArrayList();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  SimpleDateFormat f = new SimpleDateFormat("dd-MMM-yyyy EEE HH:mm:ss.SSS zzz");
  Calendar cal = new GregorianCalendar();
  fan.sys.TimeZone tzFan;
  java.util.TimeZone tzJava;
  int num;
  int curYear;
  HashMap errors = new HashMap();

}