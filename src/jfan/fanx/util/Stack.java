//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//
package fanx.util;

/**
 * Stack is a very simple FILO array of objects used for tree walking
 */
public class Stack
{

  public boolean empty()
  {
    return n == 0;
  }

  public Object peek()
  {
    if (n == 0) return null;
    return stack[n-1];
  }

  public Object pop()
  {
    Object pop = stack[n-1];
    stack[--n] = null;
    return pop;
  }

  public void push(Object obj)
  {
    try
    {
      stack[n++] = obj;
    }
    catch (Exception e)
    {
      throw new RuntimeException("Stack overflow - abstract syntax tree too deep");
    }
  }

  public void dump()
  {
    for (int i=0; i<n; ++i)
      System.out.println("stack[" + i + "] " + stack[i]);
  }

  public Object[] stack = new Object[256];
  public int n;

}
