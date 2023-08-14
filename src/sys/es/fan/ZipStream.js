//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jul 2023  Kiera O'Flynn  Creation
//

/*************************************************************************
 * ZipInStream
 ************************************************************************/

// Reads from a Yauzl reader.
class ZipInStream extends InStream {

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor(reader, pos, len, bufferSize, entry) {
    super(null);
    this.#reader = reader;
    this.#pos = pos || 0;
    this.#start = this.#pos;
    this.#max = this.#pos + len;
    this.#buf = Buffer.allocUnsafe(bufferSize || 64);
    this.#entry = entry;
  }

//////////////////////////////////////////////////////////////////////////
// Reading
//////////////////////////////////////////////////////////////////////////

  #reader;
  #start;
  #pos;
  #max;
  #isClosed = false;

  // Compressed data
  #pre = [];
  #buf;
  #bufPos = 0;
  #availInBuf = 0;

  #entry;
  #nextBuf;
  #availInNextBuf = 0;

  #readInto(buf) {
    if (this.#max === Infinity) {
      if (!this.#nextBuf) {
        this.#nextBuf = Buffer.allocUnsafe(this.#buf.length);
        this.#availInNextBuf = this.#reader.read(this.#nextBuf, 0, this.#buf.length, this.#pos);
        this.#pos += this.#availInNextBuf;
      }

      const r1 = this.#availInNextBuf;
      this.#nextBuf.copy(buf, 0, 0, r1);
      this.#availInNextBuf = this.#reader.read(this.#nextBuf, 0, this.#buf.length, this.#pos);

      // scan for data descriptor
      const totalBuf = Buffer.concat([buf.subarray(0, r1), this.#nextBuf.subarray(0, Math.min(23, this.#availInNextBuf))]);
      for(let i = 0; i < totalBuf.length - 23; i++) {
        if (totalBuf.readUInt32LE(i) === 0x08074b50) {
          const compressedNormal = totalBuf.readUInt32LE(i+8);
          const compressed64 = yauzl.readUInt64LE(totalBuf, i+8);
          const compressedActual = this.#pos - r1 + i - this.#start;
          if (compressedActual != compressedNormal && compressedActual != compressed64)
            break;

          // found it!
          this.#max = this.#pos - r1 + i;
          this.#pos = this.#max;
          const useZip64 = compressedActual === compressed64;
          if (this.#entry) {
            // write crc32, sizes into entry
            this.#entry.crc32 = totalBuf.readUInt32LE(i+4);
            if (useZip64) {
              // zip64
              this.#entry.compressedSize = compressed64;
              this.#entry.uncompressedSize = yauzl.readUInt64LE(totalBuf, i+16);
            }
            else {
              this.#entry.compressedSize = compressedNormal;
              this.#entry.uncompressedSize = totalBuf.readUInt32LE(i+12);
            }
            this.#entry.foundDataDescriptor = true;
          }
          this.#reader.unreadBuf(Buffer.concat([buf.subarray(useZip64 ? i+24 : i+16), this.#nextBuf.subarray(0, this.#availInNextBuf)]));
          return i;
        }
      }

      // no data descriptor in sight
      this.#pos += this.#availInNextBuf;
      return r1;
    }

    const r = this.#reader.read(buf, 0, Math.min(this.#buf.length, this.remaining()), this.#pos);
    this.#pos += r;
    return r;
  }

  #load() {
    if (this.#bufPos >= this.#availInBuf) {
      this.#bufPos = 0;
      this.#availInBuf = this.#readInto(this.#buf);
    }
  }

  read() {
    if (this.#isClosed) throw IOErr.make("Cannot read from closed stream");

    this.#load();
    if (this.avail() == 0) return null;
    if (this.#pre.length > 0) return this.#pre.pop();

    const r = this.#buf.readUInt8(this.#bufPos);
    this.#bufPos++;
    return r;
  }

  readBuf(buf, n) {
    const out = buf.out();
    let read = 0;
    let r;
    while (n > 0) {
      r = this.read();
      if (r === null) break;
      out.write(r);
      n--;
      read++;
    }
    out.close();
    return read == 0 ? null : read;
  }

  unread(n) { 
    this.#pre.push(n); 
    return this;
  }

  skip(n, override) {
    if (this.#isClosed && !override) throw IOErr.make("Cannot skip in closed stream");
    let skipped = 0;

    if (this.#pre.length > 0) {
      const len = Math.min(this.#pre.length, n);
      this.#pre = this.#pre.slice(0, -len);
      skipped += len;
    }
    if (this.#reader.posMatters && this.#max !== Infinity) {
      const s = Math.min(this.remaining() - skipped, Math.max(0, n - skipped - this.avail()));
      this.#pos += s;
      skipped += s;
    }
    if (skipped == n || this.#pos == this.#max) return skipped;

    if (this.avail() === 0) this.#load();

    while (true) {
      const a = this.avail();
      if (a === 0 || skipped == n) break;
      const rem = Math.min(n - skipped, this.remaining());
      if (rem < a) {
        skipped += rem;
        this.#bufPos += rem;
        break;
      }
      skipped += a;
      this.#load();
    }
    return skipped;
  }

  close() {
    this.#isClosed = true;
  }

//////////////////////////////////////////////////////////////////////////
// Info
//////////////////////////////////////////////////////////////////////////

  avail() {
    return this.#pre.length + (this.#availInBuf - this.#bufPos);
  }

  /** The number of bytes left in the stream. */
  remaining() {
    return this.#max - this.#pos;
  }

}

/*************************************************************************
 * InflateInStream
 ************************************************************************/

class InflateInStream extends InStream {

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor(in$, method, bufferSize) {
    super(in$);
    this.#in = in$;
    this.#method = method;
    this.#bufSize = bufferSize;
  }

  static makeInflate(in$, opts=null) {
    const instance = new InflateInStream(in$, node.zlib.inflateSync, 4096);
    if (opts) {
      if (opts.get("nowrap") === true)
        instance.#method = node.zlib.inflateRawSync;
    }
    return instance;
  }
  
  static makeGunzip(in$) {
    return new InflateInStream(in$, node.zlib.gunzipSync, 4096);
  }

//////////////////////////////////////////////////////////////////////////
// Reading
//////////////////////////////////////////////////////////////////////////

  #in;
  #method;
  #bufSize; // of raw data

  // Inflated data
  #pre = [];
  #buf = EMPTY_BUFFER;
  #bufPos = 0;

  #load() {
    const rawBuf = MemBuf.makeCapacity(this.#bufSize);
    const rawBufLen = this.#in.readBuf(rawBuf, this.#bufSize);
    this.#bufPos = 0;
    if (rawBufLen == null) {
      this.#buf = EMPTY_BUFFER;
      return;
    }

    this.#buf = this.#method(rawBuf.__getBytes(0, rawBufLen), {
      chunkSize: this.#bufSize
    });
  }

  read() {
    if (this.avail() == 0)
      this.#load();
    if (this.#buf.length === 0)
      return null;
    return this.#buf.readUInt8(this.#bufPos++);
  }

  readBuf(buf, n) {
    const out = buf.out();
    let read = 0;
    let r;
    while (n > 0) {
      r = this.read();
      if (r === null) break;
      out.write(r);
      n--;
      read++;
    }
    out.close();
    return read == 0 ? null : read;
  }

  unread(n) { 
    this.#pre.push(n); 
    return this;
  }

  skip(n, skipCompressed) {
    if (skipCompressed)
      return this.#in.skip(n, true);

    //same as skipping in a file in stream
    let skipped = 0;

    if (this.#pre.length > 0) {
      const len = Math.min(this.#pre.length, n);
      this.#pre = this.#pre.slice(0, -len);
      skipped += len;
    }
    if (skipped == n) return skipped;

    if (this.avail() === 0) this.#load();

    while (true) {
      const a = this.avail();
      if (a === 0 || skipped == n) break;
      const rem = n - skipped;
      if (rem < a) {
        skipped += rem;
        this.#bufPos += rem;
        break;
      }
      skipped += a;
      this.#load();
    }
    return skipped;
  }

  avail() {
    return this.#buf.length - this.#bufPos;
  }

  remaining() {
    // remaining compressed bytes, in this case
    return this.#in.remaining();
  }

}

/*************************************************************************
 * ZipOutStream
 ************************************************************************/

class ZipOutStream extends OutStream {
  constructor(yazlZip, entry) {
    super(yazlZip.out);
    this.#yazlZip = yazlZip;
    this.#entry = entry;
  }

  #yazlZip;
  #entry;
  #isClosed = false;

  close() {
    this.#isClosed = true;
    return true;
  }

  write(b) {
    if (this.#isClosed)
      throw IOErr.make("stream is closed");

    this.#yazlZip.outputStreamCursor++;
    if (!this.#entry.crcAndFileSizeKnown) {
      this.#entry.crc32 = crc32.unsigned(b, this.#entry.crc32);
      this.#entry.uncompressedSize++;
      this.#entry.compressedSize++;
    }

    this.#yazlZip.out.write(b);
    return this;
  }

  writeBuf(buf, n=buf.remaining()) {
    if (this.#isClosed)
      throw IOErr.make("stream is closed");
    if (buf.remaining() < n)
      throw IOErr.make("not enough bytes in buf");

    this.#yazlZip.outputStreamCursor += n;
    if (!this.#entry.crcAndFileSizeKnown) {
      this.#entry.crc32 = crc32.unsigned(buf.__getBytes(buf.pos(), n), this.#entry.crc32);
      this.#entry.uncompressedSize += n;
      this.#entry.compressedSize += n;
    }

    this.#yazlZip.out.writeBuf(buf, n);
    return this;
  }
}

/*************************************************************************
 * DeflateOutStream
 ************************************************************************/

class DeflateOutStream extends OutStream {

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor(out, method, level, yazlZip, entry) {
    super(out);
    this.#out = out;
    this.#method = method;
    this.#level = level;
    this.#yazlZip = yazlZip;
    this.#entry = entry;
  }

  static makeDeflate(out, opts=null) {
    const instance = new DeflateOutStream(out, node.zlib.deflateSync);
    if (opts) {
      if (opts.get("nowrap") === true)
        instance.#method = node.zlib.deflateRawSync;
      instance.#level = opts.get("level");
    }
    return instance;
  }

  static makeGzip(out) {
    return new DeflateOutStream(out, node.zlib.gzipSync)
  }

//////////////////////////////////////////////////////////////////////////
// Writing
//////////////////////////////////////////////////////////////////////////

  #yazlZip;
  #entry;

  #out;
  #method;
  #level;
  #isClosed = false;

  #buf = Buffer.allocUnsafe(16 * 1024); // default zlib chunk size
  #availInBuf = 0;

  close() {
    this.#isClosed = true;
    this.flush();
    this.#buf = undefined;
    if (!this.#yazlZip)
      this.#out.close();
    return true;
  }

  flush() {
    this.#writeDeflated();
    this.#out.flush();
  }

  write(b) {
    if (this.#isClosed)
      throw IOErr.make("stream is closed");

    if (this.#availInBuf == this.#buf.length)
      this.#writeDeflated();
    this.#buf.writeUInt8(b, this.#availInBuf);
    this.#availInBuf++;
    return this;
  }

  writeBuf(buf, n=buf.remaining()) {
    if (this.#isClosed)
      throw IOErr.make("stream is closed");
    if (buf.remaining() < n)
      throw IOErr.make("not enough bytes in buf");

    if (this.#availInBuf == this.#buf.length)
      this.#writeDeflated();
    if (this.#availInBuf + n <= this.#buf.length) {
      Buffer.from(buf.__getBytes(buf.pos(), n)).copy(this.#buf, this.#availInBuf);
      this.#availInBuf += n;
    }
    else {
      const totalBuf = Buffer.concat([
        this.#buf.subarray(0, this.#availInBuf),
        buf.__getBytes(buf.pos(), n)
      ]);
      this.#availInBuf += n;
      this.#writeDeflated(totalBuf);
    }
    return this;
  }

  #writeDeflated(buf=this.#buf) {
    if (this.#availInBuf > 0) {
      const inputBuf = buf.subarray(0, this.#availInBuf);
      const outputBuf = this.#method(inputBuf, {
        level: this.#level || undefined
      });
      const n = outputBuf.length;

      if (this.#yazlZip) {
        this.#yazlZip.outputStreamCursor += n;
        if (!this.#entry.crcAndFileSizeKnown) {
          this.#entry.crc32 = crc32.unsigned(inputBuf, this.#entry.crc32);
          this.#entry.uncompressedSize += inputBuf.length;
          this.#entry.compressedSize += n;
        }
      }

      this.#out.writeBuf(MemBuf.__makeBytes(outputBuf), n);
      this.#availInBuf = 0;
    }
  }
}