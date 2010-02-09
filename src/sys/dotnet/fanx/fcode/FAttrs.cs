//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System.Collections;
using Fan.Sys;

namespace Fanx.Fcode
{
  /// <summary>
  /// FAttrs is meta-data for a FType of FSlot - we only decode
  /// what we understand and ignore anything else.
  /// </summary>
  public class FAttrs
  {

  //////////////////////////////////////////////////////////////////////////
  // Read
  //////////////////////////////////////////////////////////////////////////

    public static FAttrs read(FStore.Input input)
    {
      int n = input.u2();
      if (n == 0) return none;
      FAttrs attrs = new FAttrs();
      for (int i=0; i<n; ++i)
      {
        string name = input.name();

        switch (name[0])
        {
          case 'E':
            if (name == FConst.ErrTableAttr) { attrs.errTable(input); continue; }
            break;
          case 'F':
            if (name == FConst.FacetsAttr) { attrs.facets(input); continue; }
            break;
          case 'L':
            if (name == FConst.LineNumberAttr) { attrs.lineNumber(input); continue; }
            if (name == FConst.LineNumbersAttr) { attrs.lineNumbers(input); continue; }
            break;
          case 'S':
            if (name == FConst.SourceFileAttr) { attrs.sourceFile(input); continue; }
            break;
        }
        int skip = input.u2();
        if (input.skip(skip) != skip)
          throw new System.IO.IOException("Can't skip over attr " + name);
      }
      return attrs;
    }

    private void errTable(FStore.Input input)
    {
      m_errTable = FBuf.read(input);
    }

    private void facets(FStore.Input input)
    {
      input.u2();
      int n = input.u2();
      m_facets = new FFacet[n];
      for (int i=0; i<n; ++i)
      {
        FFacet f = m_facets[i] = new FFacet();
        f.type = input.u2();
        f.val  = input.utf();
      }
    }

    private void lineNumber(FStore.Input input)
    {
      input.u2();
      m_lineNum = input.u2();
    }

    private void lineNumbers(FStore.Input input)
    {
      m_lineNums = FBuf.read(input);
    }

    private void sourceFile(FStore.Input input)
    {
      input.u2();
      m_sourceFile = input.utf();
    }

  //////////////////////////////////////////////////////////////////////////
  // FFacet
  //////////////////////////////////////////////////////////////////////////

    public class FFacet
    {
      public int type;      // facet type qname index
      public string val;    // serialized facet instance
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static readonly FAttrs none = new FAttrs();

    public FBuf m_errTable;
    public FFacet[] m_facets;
    public int m_lineNum;
    public FBuf m_lineNums;
    public string m_sourceFile;

  }
}