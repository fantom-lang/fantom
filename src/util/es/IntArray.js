//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 2023  Matthew Giannini  Creation
//   11 Jul 2023  Matthew Giannini  Refactor for ES
//

/**
 * IntArray.
 */
class IntArray extends sys.Obj {

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  constructor(arr)
  {
    super();
    this.#arr = arr;
  }

  #arr;
  __arr() { return this.#arr; }

  typeof() { return IntArray.type$; }

  static makeS1(size) { return new IntArray(new Int8Array(size)); }

  static makeU1(size) { return new IntArray(new Uint8Array(size)); }

  static makeS2(size) { return new IntArray(new Int16Array(size)); }

  static makeU2(size) { return new IntArray(new Uint16Array(size)); }

  static makeS4(size) { return new IntArray(new Int32Array(size)); }

  static makeU4(size) { return new IntArray(new Uint32Array(size)); }

  static makeS8(size) { return new BigIntArray(new BigInt64Array(size)); }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  size() { return this.#arr.length; }

  get(index) { return this.#arr[index]; }

  set(index, val) { this.#arr[index] = val; }

  copyFrom(that, thatRange = null, thisOffset = 0)
  {
    this.#checkKind(that);
    let start = 0, end = 0;
    const thatSize = that.size();
    if (thatRange == null) { start = 0; end = thatSize; }
    else { start = thatRange.__start(thatSize); end = thatRange.__end(thatSize) + 1; }
    const slice = that.#arr.slice(start, end);
    this.#arr.set(slice, thisOffset);
    return this;
  }

  fill(val, range = null)
  {
    let start = 0, end = 0;
    const size = this.size();
    if (range == null) { start = 0; end = size - 1; }
    else { start = range.__start(size); end = range.__end(size); }
    for (let i=start; i<=end; ++i) this.#arr[i] = val;
    return this;
  }

  sort(range = null)
  {
    if (range == null) { this.#arr.sort(); }
    else
    {
      const size  = this.size();
      const start = range.__start(size);
      const end   = range.__end(size) + 1;

      const sortedPart = this.#arr.slice(start, end).sort();
      this.#arr.set(sortedPart, start);
    }
    return this;
  }

  #kind() { return this.#arr.constructor.name; }

  #checkKind(that)
  {
    if (this.#kind() != that.#kind())
      throw sys.ArgErr.make(`Mismatched arrays: ${this.#kind()} != ${that.#kind()}`);
  }
}

// **************************************************************************
// ** BigIntArray
// **************************************************************************

/** A little bit of sadness here. We need to wrap/unwrap bigints */
class BigIntArray extends IntArray
{
  constructor(arr) { super(arr); }
  get(index) { return parseInt(this.__arr()[index]); }
  set(index, val) { this.__arr()[index] = BigInt(val); }

}