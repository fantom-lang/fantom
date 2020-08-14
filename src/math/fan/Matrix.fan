//
// Copyright (c) 2020, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 20  Matthew Giannini  Creation
//

**
** Interface for matrix implementations. A matrix is a rectangular array of numbers.
**
mixin Matrix
{
  ** The number of rows in the matrix.
  abstract Int numRows()

  ** The number of columns in the matrix.
  abstract Int numCols()

  ** Return true if the matrix is square.
  abstract Bool isSquare()

  ** Get the element at 'A[i,j]', where 'i' is the row index, and 'j' is
  ** column index.
  abstract Float get(Int i, Int j)

  ** Set the element at 'A[i,j]', where 'i' is the row index, and 'j' is
  ** column index.
  abstract This set(Int i, Int j, Float val)

  ** Set every element in the matrix to the given val.
  abstract This fill(Float val)

  ** Get the transpose of the matrix.
  abstract Matrix transpose()

  ** Computes 'x * A'.
  abstract This multScalar(Float x)

  ** Computes 'A + B' and returns a new matrix.
  @Operator abstract Matrix plus(Matrix b)

  ** Computes 'A - B' and returns a new matrix.
  @Operator abstract Matrix minus(Matrix b)

  ** Computes 'A * B' and returns a new matrix.
  @Operator abstract Matrix mult(Matrix b)

  ** Compute the determinant of the matrix. The matrix must be square.
  abstract Float determinant()

  ** Compute the cofactor of the matrix. The matrix must be square.
  abstract Matrix cofactor()

  ** Compute the inverse of the matrix.
  abstract Matrix inverse()
}

**
** Native implementation of the Matrix mixin.
**
@NoDoc final native class MMatrix : Matrix
{
  new make(Int numRows, Int numCols)

  override Int numRows()

  override Int numCols()

  override Bool isSquare()

  override Float get(Int i, Int j)

  override This set(Int i, Int j, Float val)

  override This fill(Float val)

  override Matrix transpose()

  override This multScalar(Float x)

  @Operator override Matrix plus(Matrix b)

  @Operator override Matrix minus(Matrix b)

  @Operator override Matrix mult(Matrix b)

  override Float determinant()

  override Matrix cofactor()

  override Matrix inverse()
}