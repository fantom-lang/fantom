//
// Copyright (c) 2020, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 20  Matthew Giannini  Creation
//

class MMatrixTest : Test
{
  Void testGetSet()
  {
    m := Math.matrix(2,2)
    m.set(0,0,1f); verify(m.get(0,0).approx(1f))
    m.set(1,1,4f); verify(m.get(1,1).approx(4f))
  }

  Void testFill()
  {
    verifyMatrixEq(Math.matrix(2,2).fill(5f), matrix(2,2,[5f,5f,5f,5f]))
  }

  Void testIsSquare()
  {
    verify(Math.matrix(1,1).isSquare)
    verify(Math.matrix(10,10).isSquare)
    verifyFalse(Math.matrix(1,2).isSquare)
  }

  Void testTranspose()
  {
    a := matrix(2,3,[1f,2f,3f,4f,5f,6f])
    at := matrix(3,2,[1f,4f,2f,5f,3f,6f])
    verifyMatrixEq(a.transpose, at)
    verifyMatrixEq(a.transpose.transpose, a)
  }

  Void testMultScalar()
  {
    a := matrix(2,3,[1f,2f,3f,4f,5f,6f])
    b := matrix(2,3,[2f,4f,6f,8f,10f,12f])
    verifyMatrixEq(a.multScalar(2f), b)
  }

  Void testPlus()
  {
    a := matrix(2,3,[1f,2f,3f,4f,5f,6f])
    b := matrix(2,3,[2f,4f,6f,8f,10f,12f])
    c := matrix(2,3,[3f,6f,9f,12f,15f,18f])
    verifyMatrixEq(a + b, c)
  }

  Void testMinus()
  {
    a := matrix(2,3,[1f,2f,3f,4f,5f,6f])
    b := matrix(2,3,[2f,4f,6f,8f,10f,12f])
    c := matrix(2,3,[-1f,-2f,-3f,-4f,-5f,-6f])
    verifyMatrixEq(a - b, c)
  }

  Void testMult()
  {
    a := matrix(2,3,[1f,2f,3f,4f,5f,6f])
    b := matrix(3,2,[7f,8f,9f,10f,11f,12f])
    c := matrix(2,2,[58f,64f,139f,154f])
    verifyMatrixEq(a * b, c)
  }

  Void testDeterminant()
  {
    a := matrix(1,1,[5f])
    verifyEq(a.determinant, 5f)

    a = matrix(2,2,[4f,6f,3f,8f])
    verifyEq(a.determinant, 14f)

    a = matrix(3,3,[6f,1f,1f, 4f,-2f,5f, 2f,8f,7f])
    verifyEq(a.determinant, -306f)

    a = matrix(4,4,[-1f,2f,3f,4f,
                    5f,-6f,7f,8f,
                    9f,10f,-11f,12f,
                    13f,14f,15f,-16f])
    verifyEq(a.determinant, -36416f)
  }

  Void testCofactor()
  {
    a := matrix(3,3,[1f,2f,3f, 0f,4f,5f, 1f,0f,6f])
    cf := matrix(3,3,[24f,5f,-4f, -12f,3f,2f, -2f,-5f,4f])
    verifyMatrixEq(a.cofactor, cf)
  }

  Void testInverse()
  {
    a := matrix(2,2,[4f,7f,2f,6f])
    i := matrix(2,2,[0.6f,-0.7f,-0.2f,0.4f])
    verifyMatrixEq(a.inverse, i)

    a = matrix(4,4,[-1f,2f,3f,4f,
                    5f,-6f,7f,8f,
                    9f,10f,-11f,12f,
                    13f,14f,15f,-16f])
    i = matrix(4,4,[
         -0.130492091388f, 0.0601933216169f, 0.0320738137083f, 0.0215289982425f,
         0.118189806678f, -0.0553602811951f, 0.0197715289982f, 0.0166959578207f,
         0.0953427065026f, 0.0250439367311f, -0.0268014059754f, 0.0162565905097f,
         0.0867750439367f, 0.0239455184534f, 0.0182337434095f, -0.0151581722320f])
    verifyMatrixEq(a.inverse, i)
  }

  private Matrix matrix(Int numRows, Int numCols, Float[] arr)
  {
    m := Math.matrix(numRows, numCols)
    for (i:=0;i<numRows;++i)
      for (j:=0;j<numCols;++j)
        m.set(i,j,arr[i*numCols + j])
    return m
  }

  private Void verifyMatrixEq(Matrix a, Matrix b, Float eps := 1.0E-6f)
  {
    verifyEq(a.numRows, b.numRows)
    verifyEq(a.numCols, b.numCols)
    for (i := 0; i < a.numRows; ++i)
    {
      for (j := 0; j < a.numCols; ++j)
      {
        verify(a.get(i,j).approx(b.get(i,j), eps))
      }
    }
  }
}