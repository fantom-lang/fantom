//
// Copyright (c) 2020, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 20  Matthew Giannini  Creation
//


**
** This mixin contains a set of utilities and functions for various math operations.
**
final class Math
{
  ** Create a new `Matrix` with the given number of rows and columns.
  ** All elements of the matrix are initialized to zero.
  static Matrix matrix(Int numRows, Int numCols) { MMatrix(numRows, numCols) }
}