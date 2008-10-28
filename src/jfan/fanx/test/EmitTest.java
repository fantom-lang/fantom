//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//
package fanx.test;

import java.lang.reflect.*;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.io.File;
import java.io.FileOutputStream;
import fan.sys.*;
import fanx.emit.*;
import fanx.util.*;

/**
 * JEmitTest
 */
public class EmitTest
  extends Test
  implements EmitConst
{

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  public void run()
    throws Exception
  {
    verifyConstantPool();
    verifyBasics();
  }

//////////////////////////////////////////////////////////////////////////
// ConstantPool
//////////////////////////////////////////////////////////////////////////

  void verifyConstantPool()
    throws Exception
  {
    Emitter e = new Emitter("Foo", "java/lang/Object", new String[0], PUBLIC);

    // utf
    int foo = e.utf("foo");
    int bar = e.utf("bar");
    int ray = e.utf("ray");
    verify(e.utf("foo") == foo);
    verify(e.utf("foo") == foo);
    verify(e.utf("bar") == bar);
    verify(e.utf("foo") == foo);

    // string
    int sHello = e.strConst("hello");
    verify(e.strConst("hello") == sHello);
    verify(e.strConst("hello") == sHello);

    // int
    int i = e.intConst(77);
    verify(e.intConst(77) == i);

    // long
    int l = e.longConst(Long.MIN_VALUE);
    verify(e.longConst(Long.MIN_VALUE) == l);
    int l2 = e.longConst(0L);
    verify(l2 == l + 2); // double entries

    // float
    int f = e.floatConst(2.3f);
    verify(e.floatConst(2.3f) == f);
    int fNan = e.floatConst(Float.NaN);
    verify(e.floatConst(Float.NaN) == fNan);
    verify(e.floatConst(Float.NaN) == fNan);
    int fInf = e.floatConst(Float.POSITIVE_INFINITY);
    verify(e.floatConst(Float.POSITIVE_INFINITY) == fInf );

    // double
    int d = e.doubleConst(Double.MAX_VALUE);
    verify(e.doubleConst(Double.MAX_VALUE) == d);
    int d2 = e.doubleConst(0.0);
    verify(d2 == d + 2); // double entries
    int dNan = e.doubleConst(Double.NaN);
    verify(e.doubleConst(Double.NaN) == dNan);
    verify(e.doubleConst(Double.NaN) == dNan);
    int dInf = e.doubleConst(Double.POSITIVE_INFINITY);
    verify(e.doubleConst(Double.POSITIVE_INFINITY) == dInf);

    // cls
    int clsBar = e.cls("bad");
    int clsFoo = e.cls("foo");
    verify(e.cls("bad") == clsBar);

    // method
    int mFuncx = e.method("foo.funcx()I");
    verify(e.method("foo.funcx()I") == mFuncx);
    verify(e.method("foo.funcx()I") == mFuncx);

    // field
    int fKick = e.field("foo.kick:Z");
    verify(e.field("foo.kick:Z") == fKick);
  }

//////////////////////////////////////////////////////////////////////////
// Basic
//////////////////////////////////////////////////////////////////////////

  void verifyBasics()
    throws Exception
  {
    Emitter e = new Emitter("Foo", "java/lang/Object", new String[0], PUBLIC);

    // test basic fields
    int sref = e.emitField("s", "Ljava/lang/String;", PUBLIC).ref();
    int iref = e.emitField("i", "I", PUBLIC).ref();
    int lref = e.emitField("l", "J", PUBLIC).ref();
    int fref = e.emitField("f", "F", PUBLIC).ref();
    int dref = e.emitField("d", "D", PUBLIC).ref();
    int zref = e.emitField("z", "Z", PUBLIC).ref();

    // test <init> and invokespecial
    CodeEmit c;
    c = e.emitMethod("<init>", "()V", PUBLIC).emitCode();
      c.maxLocals = 10;
      c.maxStack = 10;
      c.op(ALOAD_0);
      c.op2(INVOKESPECIAL, e.method("java/lang/Object.<init>()V"));
      c.op(RETURN);

    // test basic code generation
    c = e.emitMethod("add", "(II)I", PUBLIC).emitCode();
      c.maxLocals = 10;
      c.maxStack = 10;
      c.op(ILOAD_1);
      c.op(ILOAD_2);
      c.op(IADD);
      c.op(IRETURN);

    // test all the constants: string, int, long, float, double
    c = e.emitMethod("sets", "()V", PUBLIC).emitCode();
      c.maxLocals = 10;
      c.maxStack = 10;
      c.op(ALOAD_0);
      c.op2(LDC_W, e.strConst("set it!"));
      c.op2(PUTFIELD, sref);
      c.op(ALOAD_0);
      c.op2(LDC_W, e.intConst(123));
      c.op2(PUTFIELD, iref);
      c.op(ALOAD_0);
      c.op2(LDC2_W, e.longConst(0xabcdef01234L));
      c.op2(PUTFIELD, lref);
      c.op(ALOAD_0);
      c.op2(LDC_W, e.floatConst(6.9f));
      c.op2(PUTFIELD, fref);
      c.op(ALOAD_0);
      c.op2(LDC2_W, e.doubleConst(700.007));
      c.op2(PUTFIELD, dref);
      c.op(RETURN);

    // verify class identity
    Class cls = load(e);
    verify(cls.getName().equals("Foo"));
    verify(cls.getSuperclass() == Object.class);
    verify(cls.getInterfaces().length == 0);
    verify(Modifier.isPublic(cls.getModifiers()));

    // make instance
    Object foo = cls.newInstance();

    // get fields
    Field s = cls.getField("s");
    Field i = cls.getField("i");
    Field l = cls.getField("l");
    Field f = cls.getField("f");
    Field d = cls.getField("d");

    // verify s field
    verify(s.getType() == String.class);
    verify(s.get(foo) == null);
    s.set(foo, "hello");
    verify(s.get(foo) == "hello");

    // try out add() method
    Method add = cls.getMethod("add", new Class[] { int.class, int.class });
    verify(add.getReturnType() == int.class);
    Integer r = (Integer)add.invoke(foo, new Object[] { new Integer(3), new Integer(5) });
    verify(r.intValue() == 8);

    // sets() method tests setting each field to constant
    Method sets = cls.getMethod("sets", new Class[] {});
    sets.invoke(foo, new Object[] {});
    /*
    System.out.println("s=" + s.get(foo));
    System.out.println("i=" + i.get(foo));
    System.out.println("l=" + l.get(foo));
    System.out.println("f=" + f.get(foo));
    System.out.println("d=" + d.get(foo));
    */
    verify(s.get(foo).equals("set it!"));
    verify(i.getInt(foo) == 123);
    verify(l.getLong(foo) == 0xabcdef01234L);
    verify(f.getFloat(foo) == 6.9f);
    verify(d.getDouble(foo) == 700.007);
  }

//////////////////////////////////////////////////////////////////////////
// Loader
//////////////////////////////////////////////////////////////////////////

  Class load(Emitter e)
    throws Exception
  {
    toLoad = e;
    return loader.loadClass(e.className);
  }

  void dumpToFile(String name, Box box)
  {
    try
    {
      File f = new File(name + ".class");
      System.out.println("Dump: " + f);
      FileOutputStream out = new FileOutputStream(f);
      out.write(box.buf, 0, box.len);
      out.close();
    }
    catch (Exception e)
    {
      e.printStackTrace();
    }
  }

  class Loader extends ClassLoader
  {
    protected Class loadClass(String name, boolean resolve)
      throws ClassNotFoundException
    {
      if (toLoad != null && toLoad.className.equals(name))
      {
        Box box = toLoad.pack();
        /*dumpToFile(name, box);*/
        Class cls = defineClass(name, box.buf, 0, box.len);
        toLoad = null;
        if (resolve) resolveClass(cls);
        return cls;
      }
      return findSystemClass(name);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ClassLoader loader = new Loader();
  Emitter toLoad;

}