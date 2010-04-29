//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Apr 10  Brian Frank  Creation
//

**
** TableTest
**
class TableTest : Test
{

  Void testView()
  {
    // start off
    m := TestTableModel()
    t := Table { model = m }
    verifyView(t, null, SortMode.up, [true, true, true],
      [["A:0", "B:0", "C:0"],
       ["A:1", "B:1", "C:1"],
       ["A:2", "B:2", "C:2"]])

    // sort column 1
    t.sort(1)
    verifyView(t, 1, SortMode.up, [true, true, true],
      [["A:0", "B:0", "C:0"],
       ["A:2", "B:2", "C:2"],
       ["A:1", "B:1", "C:1"]])

    // sort column 1 descending
    t.sort(1, SortMode.down)
    verifyView(t, 1, SortMode.down, [true, true, true],
      [["A:1", "B:1", "C:1"],
       ["A:2", "B:2", "C:2"],
       ["A:0", "B:0", "C:0"]])

    // add row
    m.numRows = 4
    verifyView(t, 1, SortMode.down, [true, true, true],
      [["A:1", "B:1", "C:1"],
       ["A:2", "B:2", "C:2"],
       ["A:3", "B:3", "C:3"],
       ["A:0", "B:0", "C:0"]])

    // turn off column 0
    t.setColVisible(0, false)
    verifyView(t, 1, SortMode.down, [false, true, true],
      [["B:1", "C:1"],
       ["B:2", "C:2"],
       ["B:3", "C:3"],
       ["B:0", "C:0"]])

    // turn on column 0, turn off 1
    t.setColVisible(0, true)
    t.setColVisible(1, false)
    verifyView(t, 1, SortMode.down, [true, false, true],
      [["A:1", "C:1"],
       ["A:2", "C:2"],
       ["A:3", "C:3"],
       ["A:0", "C:0"]])

    // turn turn off 2, sort col 0
    t.view.setColVisible(2, false)
    t.sort(0)
    verifyView(t, 0, SortMode.up, [true, false, false],
      [["A:0"],
       ["A:1"],
       ["A:2"],
       ["A:3"]])
  }

  Void verifyView(Table t, Int? sortCol, SortMode sortMode,
                  Bool[] visible, Str[][] viewRows )
  {
    // verify fixed model
    verifyEq(t.model.numRows, viewRows.size)
    verifyEq(t.model.numCols, 3)
    3.times |c|
    {
      viewRows.size.times |r|
      {
        verifyEq(t.model.text(c, r), ('A'+c).toChar + ":" + r)
      }
    }

    // sort/visible
    verifyEq(t.sortCol, sortCol)
    verifyEq(t.sortMode, sortMode)
    visible.each |v, c| { verifyEq(t.isColVisible(c), v) }

    // verify view columns
    verifyEq(t.view.numCols, viewRows[0].size)
    viewRows[0].each |cell, c|
    {
      verifyEq(t.view.header(c), cell[0..0])
    }

    // verify view rows
    viewRows.each |row, r|
    {
      row.each |cell, c|
      {
        verifyEq(t.view.text(c, r), cell)
      }
    }
  }

}

internal class TestTableModel : TableModel
{
  override Int numRows := 3
  override Int numCols() { 3 }
  override Str header(Int col) { ('A' + col).toChar }
  override Str text(Int col, Int row) { "${header(col)}:$row" }

  override Int sortCompare(Int c, Int row1, Int row2)
  {
    if (c == 1) return bRanks[row1] <=> bRanks[row2]
    return super.sortCompare(c, row1, row2)
  }

  Int[] bRanks := [1, 4, 2, 2]  // ^ 0, 2, 3, 1 ; v 1, 3, 2, 0
}