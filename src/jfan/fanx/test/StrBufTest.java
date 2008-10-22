//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Sep 05  Brian Frank  Creation
//
package fanx.test;

import fan.sys.*;

/**
 * StrBufTest
 */
public class StrBufTest
  extends Test
{

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  public void run()
    throws Exception
  {
    //perf();
  }

//////////////////////////////////////////////////////////////////////////
// Perf
//////////////////////////////////////////////////////////////////////////

  public void perf()
  {
    String a = "foobar ";
    String b = " yippee!";

    System.out.println("Java: " + java(a, b, 0L));
    System.out.println("Fan:  " +  fan(a, b, 0L));

    long t1 = System.nanoTime();
    for (int i=0; i<100000; ++i) java(a, b, Long.valueOf(i % 200));
    long t2 = System.nanoTime();
    for (int i=0; i<100000; ++i) fan(a, b, Long.valueOf(i % 200));
    long t3 = System.nanoTime();

    long t4 = System.nanoTime();
    for (int i=0; i<1000000; ++i) fan(a, b, Long.valueOf(i % 200));
    long t5 = System.nanoTime();
    for (int i=0; i<1000000; ++i) java(a, b, Long.valueOf(i % 200));
    long t6 = System.nanoTime();

    System.out.println("Java: " + (t2-t1) + "ns");
    System.out.println("Fan:  " + (t3-t2) + "ns");
    System.out.println();
    System.out.println("Java: " + (t6-t5) + "ns");
    System.out.println("Fan:  " + (t5-t4) + "ns");
  }

  public String java(String a, String b, long i)
  {
    StringBuilder s = new StringBuilder();
    s.append(a).append(i).append(b);
    return s.toString();
  }

  public String fan(String a, String b, long i)
  {
    StrBuf s = new StrBuf(new StringBuilder());
    s.add(a).add(i).add(b);
    return s.toStr();
  }

}