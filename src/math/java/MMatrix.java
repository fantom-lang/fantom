//
// Copyright (c) 2020, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 20  Matthew Giannini  Creation
//
package fan.math;

import fan.sys.*;
import java.util.Arrays;

public class MMatrix extends FanObj implements Matrix
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static MMatrix make(final long numRows, final long numCols)
  {
    return new MMatrix(numRows, numCols, new double[(int)numRows * (int)numCols]);
  }

  private MMatrix(final long numRows, final long numCols, final double[] array)
  {
    if (numRows <= 0 || numCols <= 0)
      throw ArgErr.make(String.format("Invalid matrix dimensions %d x %d", numRows, numCols));
    if (array.length != numRows * numCols)
        throw ArgErr.make("Invalid array");

    this.numRows = numRows;
    this.numCols = numCols;
    this.array   = array;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  /* Model the storage as 1-dimensional array */
  private double[] array;

  private final long numRows;
  private final long numCols;

  /** Utility to get the matrix in a 2-dimensional array */
  public double[][] toArray2D()
  {
    double[][] arr = new double[(int)numRows][(int)numCols];
    for (int row = 0; row < numRows; ++row)
    {
      for (int col = 0; col < numCols; ++col)
      {
        arr[row] = new double[(int)numCols];
        System.arraycopy(array, row * (int)numCols, arr[row], 0, (int)numCols);
      }
    }
    return arr;
  }

//////////////////////////////////////////////////////////////////////////
// Matrix
//////////////////////////////////////////////////////////////////////////

  public long numRows() { return numRows; }
  public long numCols() { return numCols; }

  public boolean isSquare() { return numRows == numCols; }

  public double get(final long i, final long j)
  {
    return array[idx(i,j)];
  }

  public MMatrix set(final long i, final long j, double val)
  {
    array[idx(i,j)] = val;
    return this;
  }

  public MMatrix fill(final double val)
  {
    Arrays.fill(array, val);
    return this;
  }

  private int idx(final long i, final long j) { return (int)(i * numCols + j); }

  public Matrix transpose()
  {
    MMatrix t = new MMatrix(numCols(), numRows(), new double[array.length]);
    for (int r = 0; r < numRows; ++r)
    {
      for (int c = 0; c < numCols; ++c)
      {
        t.set(c, r, get(r, c));
      }
    }
    return t;
  }

  public Matrix multScalar(final double x)
  {
    for (int i = 0; i < array.length; ++i) { array[i] *= x; }
    return this;
  }

  public Matrix plus(final Matrix b)
  {
    checkDimsEq(b);
    final MMatrix m = new MMatrix(numRows, numCols, new double[array.length]);
    for (int i = 0; i < numRows; ++i)
    {
      for (int j = 0; j < numCols; ++j)
      {
        m.set(i, j, this.get(i,j) + b.get(i,j));
      }
    }
    return m;
  }

  public Matrix minus(final Matrix b)
  {
    checkDimsEq(b);
    final MMatrix m = new MMatrix(numRows, numCols, new double[array.length]);
    for (int i = 0; i < numRows; ++i)
    {
      for (int j = 0; j < numCols; ++j)
      {
        m.set(i, j, this.get(i,j) - b.get(i,j));
      }
    }
    return m;
  }

  public Matrix mult(final Matrix b)
  {
    if (this.numCols != b.numRows())
      throw ArgErr.make(String.format("Matrix cols don't match rows: %d != %d", numCols, numRows));

    final int numRows = (int)this.numRows();
    final int numCols = (int)b.numCols();
    final MMatrix m = new MMatrix(numRows, numCols, new double[numRows*numCols]);
    for (int i = 0; i < numRows; ++i)
    {
      for (int j = 0; j < numCols; ++j)
      {
        double sum = 0d;
        for (int k = 0; k < this.numCols; ++k) { sum += get(i,k) * b.get(k,j); }
        m.set(i, j, sum);
      }
    }
    return m;
  }

  public double determinant()
  {
    checkSquare();
    if (numRows == 1) return get(0,0);
    if (numRows == 2) return (get(0,0) * get(1,1)) - (get(0,1) * get(1,0));
    return determinantLU();
  }

  public Matrix cofactor()
  {
    checkSquare();
    final double[] m = new double[array.length];
    for (int i=0; i<numRows; ++i)
    {
      for (int j=0; j<numCols; ++j)
      {
        double x = slice(i,j).determinant();
        if (i % 2 == 0) x = -x;
        if (j % 2 == 0) x = -x;
        m[idx((int)numRows, i, j)] = x;
      }
    }
    return new MMatrix(numRows, numCols, m);
  }

  private Matrix slice(final long exRow, final long exCol)
  {
    final int aNumRows = (int)(numRows - 1);
    final int aNumCols = (int)(numCols - 1);
    final double[] m = new double[aNumRows * aNumCols];
    int ar = 0;
    for (int i=0; i<numRows; ++i)
    {
      if (i == exRow) continue;
      int ac = 0;
      for (int j=0; j<numCols; ++j)
      {
        if (j == exCol) continue;
        m[idx(aNumCols, ar, ac)] = get(i,j);
        ++ac;
      }
      ++ar;
    }
    return new MMatrix(aNumRows, aNumCols, m);
  }

  public Matrix inverse()
  {
    final double det = this.determinant();
    if (det == 0d) throw Err.make("Determinant is zero, the matrix is not invertible");
    return this.cofactor().transpose().multScalar(1.0d/det);
  }

  public String toStr()
  {
    return dump(10,10);
  }

//////////////////////////////////////////////////////////////////////////
// LU
//////////////////////////////////////////////////////////////////////////

  /**
  * Calculate the determinant for a matrix using Croat's method
  * to obtain an LU-decomposition of the matrix. Once the LUD is
  * obtained, the determinant is simply the product of all values
  * on the main diagonal.
  *
  * NOTE: an LUD does not require a square matrix, but calculating
  * a determinant does. This method assumes the matrix is square.
  */
  private double determinantLU()
  {
    final int m = (int)numRows;
    final int n = (int)numCols;
    final double[] lu = new double[m*n];
    System.arraycopy(this.array, 0, lu, 0, array.length);

    final int[] piv = new int[m];
    for (int i=0; i<m; ++i) { piv[i] = i; }
    int pivSign = 1;

    for (int j=0; j<n; ++j)
    {
      // make a copy of the j-th column to localize references
      double[] luColj = new double[m];
      for (int i=0; i<m; ++i) { luColj[i] = lu[idx(n, i, j)]; }

      // apply previous transformation
      for (int i=0; i<m; ++i)
      {
        // dot product
        final int kmax = java.lang.Math.min(i,j);
        double s = 0d;
        for (int k=0; k<kmax; ++k) { s += lu[idx(n, i, k)] * luColj[k]; }

        luColj[i] -= s;
        lu[idx(n, i, j)] = luColj[i];
      }

      // find pivot and exchange if necessary
      int p = j;
      for (int i=j+1; i < m; ++i)
      {
        if (java.lang.Math.abs(luColj[i]) > java.lang.Math.abs(luColj[p])) p = i;
      }
      if (p != j)
      {
        for (int k=0; k<n; ++k)
        {
          double t = lu[idx(n, p, k)];
          lu[idx(n, p, k)] = lu[idx(n, j, k)];
          lu[idx(n, j, k)] = t;
        }
        final int k = piv[p];
        piv[p] = piv[j];
        piv[j] = k;
        pivSign = -pivSign;
      }

      // compute multipliers
      if (j < m && lu[idx(n, j, j)] != 0d)
      {
        for (int i=j+1; i < m; ++i)
        {
          lu[idx(n, i, j)] /= lu[idx(n, j, j)];
        }
      }
    }
    double det = (double)pivSign;
    for (int j=0; j < n; ++j) { det *= lu[idx(n, j, j)]; }
    return det;
  }

  private static int idx(final int numCols, final int row, final int col) { return row * numCols + col; }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  private void checkDimsEq(final Matrix b)
  {
    if (this.numRows != b.numRows() || this.numCols != b.numCols())
      throw ArgErr.make(String.format("Matrix dimensions not equal: %d x %d != %d x %d", this.numRows, this.numCols, b.numRows(), b.numCols()));
  }

  private void checkSquare()
  {
    if (!isSquare())
      throw ArgErr.make(String.format("Matrix is not square: %d x %d", numRows, numCols));
  }

  public String dump(long m, long n)
  {
    final StringBuilder sb = new StringBuilder();
    sb.append(numRows + " x " + numCols).append('\n');

    m = java.lang.Math.min(m, numRows);
    n = java.lang.Math.min(n, numCols);

    final String eor = n < numCols ? "...\n" : "\n";

    for (int i = 0; i < m; ++i)
    {
      for (int j = 0; j < n; ++j)
      {
        sb.append(String.format(" %12.12s", String.format("%.6g", get(i,j))));
      }
      sb.append(eor);
    }
    if (m < numRows()) sb.append(" ...\n");

    return sb.toString();
  }
}
