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
  ** Create a new matrix with the given number of rows and columsn.
  ** All elements of the matrix are initialized to zero.
  static Matrix create(Int numRows, Int numCols)
  {
    MMatrix(numRows, numCols)
  }

  ** The number of rows in the matrix.
  abstract Int numRows()

  ** The number of columns in the matrix.
  abstract Int numCols()

  ** Return true if the matrix is square.
  abstract Bool isSquare()

  ** Get the element at 'A[i,j]'
  abstract Float get(Int i, Int j)

  ** Set the element at 'A[i,j]' to val.
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