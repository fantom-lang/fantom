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
    Str a = Str.make("foobar ");
    Str b = Str.make(" yippee!");

    System.out.println("Java: " + java(a, b, Int.Zero));
    System.out.println("Fan:  " +  fan(a, b, Int.Zero));

    long t1 = System.nanoTime();
    for (int i=0; i<100000; ++i) java(a, b, Int.make(i % Int.POS));
    long t2 = System.nanoTime();
    for (int i=0; i<100000; ++i) fan(a, b, Int.make(i % Int.POS));
    long t3 = System.nanoTime();

    long t4 = System.nanoTime();
    for (int i=0; i<1000000; ++i) fan(a, b, Int.make(i % Int.POS));
    long t5 = System.nanoTime();
    for (int i=0; i<1000000; ++i) java(a, b, Int.make(i % Int.POS));
    long t6 = System.nanoTime();

    System.out.println("Java: " + (t2-t1) + "ns");
    System.out.println("Fan:  " + (t3-t2) + "ns");
    System.out.println();
    System.out.println("Java: " + (t6-t5) + "ns");
    System.out.println("Fan:  " + (t5-t4) + "ns");
  }

  public Str java(Str a, Str b, Int i)
  {
    StringBuilder s = new StringBuilder();
    s.append(a.val).append(i.val).append(b.val);
    return Str.make(s.toString());
  }

  public Str fan(Str a, Str b, Int i)
  {
    StrBuf s = new StrBuf(new StringBuilder());
    s.add(a).add(i).add(b);
    return s.toStr();
  }

}