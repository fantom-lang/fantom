//
// Copyright (c) 2020, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 20  Matthew Giannini  Creation
//

**
** Native implementation of the Matrix mixin.
**
@NoDoc native class MMatrix : Matrix
{
  new make(Int numRows, Int numCols, Float fill := 0.0f)

  override Int nrows()

  override Int ncols()

  override Float get(Int i, Int j)

  override This set(Int i, Int j, Float val)

  override Matrix transpose()

  override This multScalar(Float x)

  @Operator override Matrix plus(Matrix b)

  @Operator override Matrix minus(Matrix b)

  @Operator override Matrix mult(Matrix b)

  override Float determinant()

  override Matrix cofactor()

  override Matrix inverse()
}