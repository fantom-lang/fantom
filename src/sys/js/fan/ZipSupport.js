/**
 * CRC-32 (ISO 3309) using reflected polynomial 0xEDB88320
 */
class crc32 {

  static #table = (() => {
    const t = new Int32Array(256);
    for (let n=0; n<256; ++n) {
      let c = n;
      for (let k=0; k<8; ++k) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
      t[n] = c;
    }
    return t;
  })();

  /**
   * Compute unsigned CRC of bytes[0..<size] continuing from prev crc.
   * The bytes may be an array-like of bytes or a single byte number.
   */
  static unsigned(bytes, prev, size) {
    if (typeof bytes === "number") bytes = [bytes];
    if (size === undefined) size = bytes.length;
    let c = ~~prev ^ -1;
    for (let i=0; i<size; ++i) c = crc32.#table[(c ^ bytes[i]) & 0xFF] ^ (c >>> 8);
    return (c ^ -1) >>> 0;
  }
}

/*
=== yauzl ===

The MIT License (MIT)

Copyright (c) 2014 Josh Wolfe

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

class yauzl {

  static open(path, options) {
    if (options == null) options = {};
    if (options.autoClose == null) options.autoClose = true;
    if (options.decodeStrings == null) options.decodeStrings = true;
    if (options.validateEntrySizes == null) options.validateEntrySizes = true;
    if (options.strictFileNames == null) options.strictFileNames = false;

    const fd = node.fs.openSync(path, "r");

    try {
      return yauzl.fromFd(fd, options);
    } catch (e) {
      node.fs.closeSync(fd);
      throw e;
    }
  }

  static fromFd(fd, options) {
    if (options == null) options = {};
    if (options.autoClose == null) options.autoClose = false;
    if (options.decodeStrings == null) options.decodeStrings = true;
    if (options.validateEntrySizes == null) options.validateEntrySizes = true;
    if (options.strictFileNames == null) options.strictFileNames = false;

    const stats = node.fs.fstatSync(fd);
    const reader = new YauzlFileReader(fd);
    return yauzl.fromRandomAccessReader(reader, stats.size, options);
  }

  static fromRandomAccessReader(reader, totalSize, options) {
    if (options == null) options = {};
    if (options.autoClose == null) options.autoClose = true;
    if (options.decodeStrings == null) options.decodeStrings = true;
    const decodeStrings = !!options.decodeStrings;
    if (options.validateEntrySizes == null) options.validateEntrySizes = true;
    if (options.strictFileNames == null) options.strictFileNames = false;
    if (typeof totalSize !== "number")
      throw new Error("expected totalSize parameter to be a number");
    if (totalSize > Number.MAX_SAFE_INTEGER)
      throw new Error("zip file too large. only file sizes up to 2^52 are supported due to JavaScript's Number type being an IEEE 754 double.");

    // eocdr means End of Central Directory Record.
    // search backwards for the eocdr signature.
    // the last field of the eocdr is a variable-length comment.
    // the comment size is encoded in a 2-byte field in the eocdr, which we can't find without trudging backwards through the comment to find it.
    // as a consequence of this design decision, it's possible to have ambiguous zip file metadata if a coherent eocdr was in the comment.
    // we search backwards for a eocdr signature, and hope that whoever made the zip file was smart enough to forbid the eocdr signature in the comment.
    const eocdrWithoutCommentSize = 22;
    const maxCommentSize = 0xffff; // 2-byte size
    const bufferSize = Math.min(eocdrWithoutCommentSize + maxCommentSize, totalSize);
    const buffer = Buffer.allocUnsafe(bufferSize);
    const bufferReadStart = totalSize - buffer.length;
    yauzl.readAndAssertNoEof(reader, buffer, 0, bufferSize, bufferReadStart);

    for (let i = bufferSize - eocdrWithoutCommentSize; i >= 0; i -= 1) {
      if (buffer.readUInt32LE(i) !== 0x06054b50) continue;
      // found eocdr
      const eocdrBuffer = buffer.subarray(i);

      // 0 - End of central directory signature = 0x06054b50
      // 4 - Number of this disk
      const diskNumber = eocdrBuffer.readUInt16LE(4);
      if (diskNumber !== 0)
        throw new Error("multi-disk zip files are not supported: found disk number: " + diskNumber);

      // 6 - Disk where central directory starts
      // 8 - Number of central directory records on this disk
      // 10 - Total number of central directory records
      let entryCount = eocdrBuffer.readUInt16LE(10);
      // 12 - Size of central directory (bytes)
      // 16 - Offset of start of central directory, relative to start of archive
      let centralDirectoryOffset = eocdrBuffer.readUInt32LE(16);
      // 20 - Comment length
      const commentLength = eocdrBuffer.readUInt16LE(20);
      const expectedCommentLength = eocdrBuffer.length - eocdrWithoutCommentSize;
      if (commentLength !== expectedCommentLength)
        throw new Error("invalid comment length. expected: " + expectedCommentLength + ". found: " + commentLength);

      // 22 - Comment
      // the encoding is always cp437.
      const comment = decodeStrings ? yauzl.decodeBuffer(eocdrBuffer, 22, eocdrBuffer.length, false)
                                  : eocdrBuffer.subarray(22);

      if (!(entryCount === 0xffff || centralDirectoryOffset === 0xffffffff))
        return new YauzlZipFile(reader, centralDirectoryOffset, totalSize, entryCount, comment, options.autoClose, decodeStrings, options.validateEntrySizes, options.strictFileNames);

      // ZIP64 format

      // ZIP64 Zip64 end of central directory locator
      const zip64EocdlBuffer = Buffer.allocUnsafe(20);
      const zip64EocdlOffset = bufferReadStart + i - zip64EocdlBuffer.length;
      yauzl.readAndAssertNoEof(reader, zip64EocdlBuffer, 0, zip64EocdlBuffer.length, zip64EocdlOffset);

      // 0 - zip64 end of central dir locator signature = 0x07064b50
      if (zip64EocdlBuffer.readUInt32LE(0) !== 0x07064b50)
        throw new Error("invalid zip64 end of central directory locator signature");

      // 4 - number of the disk with the start of the zip64 end of central directory
      // 8 - relative offset of the zip64 end of central directory record
      const zip64EocdrOffset = yauzl.readUInt64LE(zip64EocdlBuffer, 8);
      // 16 - total number of disks

      // ZIP64 end of central directory record
      const zip64EocdrBuffer = Buffer.allocUnsafe(56);
      yauzl.readAndAssertNoEof(reader, zip64EocdrBuffer, 0, zip64EocdrBuffer.length, zip64EocdrOffset);

      // 0 - zip64 end of central dir signature                           4 bytes  (0x06064b50)
      if (zip64EocdrBuffer.readUInt32LE(0) !== 0x06064b50)
        throw new Error("invalid zip64 end of central directory record signature");

      // 4 - size of zip64 end of central directory record                8 bytes
      // 12 - version made by                                             2 bytes
      // 14 - version needed to extract                                   2 bytes
      // 16 - number of this disk                                         4 bytes
      // 20 - number of the disk with the start of the central directory  4 bytes
      // 24 - total number of entries in the central directory on this disk         8 bytes
      // 32 - total number of entries in the central directory            8 bytes
      entryCount = yauzl.readUInt64LE(zip64EocdrBuffer, 32);
      // 40 - size of the central directory                               8 bytes
      // 48 - offset of start of central directory with respect to the starting disk number     8 bytes
      centralDirectoryOffset = yauzl.readUInt64LE(zip64EocdrBuffer, 48);
      // 56 - zip64 extensible data sector                                (variable size)
      return new YauzlZipFile(reader, centralDirectoryOffset, totalSize, entryCount, comment, options.autoClose, decodeStrings, options.validateEntrySizes, options.strictFileNames);
    }
    throw new Error("end of central directory record signature not found");
  }

  static fromStream(in$) {
    const reader = new YauzlStreamReader(in$);
    return new YauzlZipFile(reader);
  }

  static readAndAssertNoEof(reader, buffer, offset, length, position, errCallback, self) {
    if (length === 0) return;

    const bytesRead = reader.read(buffer, offset, length, position);
    if (bytesRead < length) {
      const e = new Error("unexpected EOF");
      if (errCallback) return errCallback.call(self, e);
      else throw e;
    }
  }

  static readUInt64LE(buffer, offset) {
    // there is no native function for this, because we can't actually store 64-bit integers precisely.
    // after 53 bits, JavaScript's Number type (IEEE 754 double) can't store individual integers anymore.
    // but since 53 bits is a whole lot more than 32 bits, we do our best anyway.
    const lower32 = buffer.readUInt32LE(offset);
    const upper32 = buffer.readUInt32LE(offset + 4);
    // we can't use bitshifting here, because JavaScript bitshifting only works on 32-bit integers.
    return upper32 * 0x100000000 + lower32;
    // as long as we're bounds checking the result of this function against the total file size,
    // we'll catch any overflow errors, because we already made sure the total file size was within reason.
  }

  static #cp437 = '\u0000☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼ !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~⌂ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■ ';
  static decodeBuffer(buffer, start, end, isUtf8) {
    if (isUtf8) {
      return buffer.toString("utf8", start, end);
    } else {
      let result = "";
      for (let i = start; i < end; i++) {
        result += yauzl.#cp437[buffer[i]];
      }
      return result;
    }
  }

  static dosDateTimeToFantom(date, time) {
    const day = date & 0x1f; // 1-31
    const month = (date >> 5 & 0xf) - 1; // 1-12, 0-11
    const year = (date >> 9 & 0x7f) + 1980; // 0-128, 1980-2108

    const second = (time & 0x1f) * 2; // 0-29, 0-58 (even numbers)
    const minute = time >> 5 & 0x3f; // 0-59
    const hour = time >> 11 & 0x1f; // 0-23

    return DateTime.make(year, Month.vals().get(month), day, hour, minute, second);
  }
}

class YauzlZipFile {
  constructor(reader, centralDirectoryOffset, fileSize, entryCount, comment, autoClose, decodeStrings, validateEntrySizes, strictFileNames) {
    this.reader = reader;
    this.readEntryCursor = centralDirectoryOffset;
    this.fileSize = fileSize;
    this.entryCount = entryCount;
    this.comment = comment;
    this.entriesRead = 0;
    this.autoClose = !!autoClose;
    this.decodeStrings = !!decodeStrings;
    this.validateEntrySizes = !!validateEntrySizes;
    this.strictFileNames = !!strictFileNames;
    this.isOpen = true;
  }

  close() {
    if (!this.isOpen) return;
    this.isOpen = false;
    this.reader.close();
  }
  getEntry() {
    const self = this;
    if (this.entryCount === this.entriesRead) {
      // done with metadata
      return;
    }

    let buffer = Buffer.allocUnsafe(46);
    yauzl.readAndAssertNoEof(this.reader, buffer, 0, buffer.length, this.readEntryCursor, this.throwErrorAndAutoClose, self);

    const entry = new YauzlEntry();
    // 0 - Central directory file header signature
    const signature = buffer.readUInt32LE(0);
    if (signature !== 0x02014b50) return this.throwErrorAndAutoClose(new Error("invalid central directory file header signature: 0x" + signature.toString(16)));
    // 4 - Version made by
    entry.versionMadeBy = buffer.readUInt16LE(4);
    // 6 - Version needed to extract (minimum)
    entry.versionNeededToExtract = buffer.readUInt16LE(6);
    // 8 - General purpose bit flag
    entry.generalPurposeBitFlag = buffer.readUInt16LE(8);
    // 10 - Compression method
    entry.compressionMethod = buffer.readUInt16LE(10);
    // 12 - File last modification time
    entry.lastModFileTime = buffer.readUInt16LE(12);
    // 14 - File last modification date
    entry.lastModFileDate = buffer.readUInt16LE(14);
    // 16 - CRC-32
    entry.crc32 = buffer.readUInt32LE(16);
    // 20 - Compressed size
    entry.compressedSize = buffer.readUInt32LE(20);
    // 24 - Uncompressed size
    entry.uncompressedSize = buffer.readUInt32LE(24);
    // 28 - File name length (n)
    entry.fileNameLength = buffer.readUInt16LE(28);
    // 30 - Extra field length (m)
    entry.extraFieldLength = buffer.readUInt16LE(30);
    // 32 - File comment length (k)
    entry.fileCommentLength = buffer.readUInt16LE(32);
    // 34 - Disk number where file starts
    // 36 - Internal file attributes
    entry.internalFileAttributes = buffer.readUInt16LE(36);
    // 38 - External file attributes
    entry.externalFileAttributes = buffer.readUInt32LE(38);
    // 42 - Relative offset of local file header
    entry.relativeOffsetOfLocalHeader = buffer.readUInt32LE(42);

    if (entry.generalPurposeBitFlag & 0x40) return this.throwErrorAndAutoClose(new Error("strong encryption is not supported"));

    this.readEntryCursor += 46;

    buffer = Buffer.allocUnsafe(entry.fileNameLength + entry.extraFieldLength + entry.fileCommentLength);
    yauzl.readAndAssertNoEof(this.reader, buffer, 0, buffer.length, this.readEntryCursor, this.throwErrorAndAutoClose, self);

    // 46 - File name
    const isUtf8 = (entry.generalPurposeBitFlag & 0x800) !== 0;
    entry.fileName = this.decodeStrings ? yauzl.decodeBuffer(buffer, 0, entry.fileNameLength, isUtf8)
      : buffer.subarray(0, entry.fileNameLength);

    // 46+n - Extra field
    const fileCommentStart = entry.fileNameLength + entry.extraFieldLength;
    const extraFieldBuffer = buffer.subarray(entry.fileNameLength, fileCommentStart);
    entry.extraFields = [];
    let i = 0;
    while (i < extraFieldBuffer.length - 3) {
      const headerId = extraFieldBuffer.readUInt16LE(i + 0);
      const dataSize = extraFieldBuffer.readUInt16LE(i + 2);
      const dataStart = i + 4;
      const dataEnd = dataStart + dataSize;
      if (dataEnd > extraFieldBuffer.length) return this.throwErrorAndAutoClose(new Error("extra field length exceeds extra field buffer size"));
      const dataBuffer = Buffer.allocUnsafe(dataSize);
      extraFieldBuffer.copy(dataBuffer, 0, dataStart, dataEnd);
      entry.extraFields.push({
        id: headerId,
        data: dataBuffer,
      });
      i = dataEnd;
    }

    // 46+n+m - File comment
    entry.fileComment = this.decodeStrings ? yauzl.decodeBuffer(buffer, fileCommentStart, fileCommentStart + entry.fileCommentLength, isUtf8)
      : buffer.subarray(fileCommentStart, fileCommentStart + entry.fileCommentLength);
    // compatibility hack for https://github.com/thejoshwolfe/yauzl/issues/47
    entry.comment = entry.fileComment;

    this.readEntryCursor += buffer.length;
    this.entriesRead += 1;

    if (entry.uncompressedSize === 0xffffffff ||
      entry.compressedSize === 0xffffffff ||
      entry.relativeOffsetOfLocalHeader === 0xffffffff) {
      // ZIP64 format
      // find the Zip64 Extended Information Extra Field
      let zip64EiefBuffer = null;
      for (i = 0; i < entry.extraFields.length; i++) {
        const extraField = entry.extraFields[i];
        if (extraField.id === 0x0001) {
          zip64EiefBuffer = extraField.data;
          break;
        }
      }
      if (zip64EiefBuffer == null) {
        return this.throwErrorAndAutoClose(new Error("expected zip64 extended information extra field"));
      }
      let index = 0;
      // 0 - Original Size          8 bytes
      if (entry.uncompressedSize === 0xffffffff) {
        if (index + 8 > zip64EiefBuffer.length) {
          return this.throwErrorAndAutoClose(new Error("zip64 extended information extra field does not include uncompressed size"));
        }
        entry.uncompressedSize = yauzl.readUInt64LE(zip64EiefBuffer, index);
        index += 8;
      }
      // 8 - Compressed Size        8 bytes
      if (entry.compressedSize === 0xffffffff) {
        if (index + 8 > zip64EiefBuffer.length) {
          return this.throwErrorAndAutoClose(new Error("zip64 extended information extra field does not include compressed size"));
        }
        entry.compressedSize = yauzl.readUInt64LE(zip64EiefBuffer, index);
        index += 8;
      }
      // 16 - Relative Header Offset 8 bytes
      if (entry.relativeOffsetOfLocalHeader === 0xffffffff) {
        if (index + 8 > zip64EiefBuffer.length) {
          return this.throwErrorAndAutoClose(new Error("zip64 extended information extra field does not include relative header offset"));
        }
        entry.relativeOffsetOfLocalHeader = yauzl.readUInt64LE(zip64EiefBuffer, index);
        index += 8;
      }
      // 24 - Disk Start Number      4 bytes
    }

    // check for Info-ZIP Unicode Path Extra Field (0x7075)
    // see https://github.com/thejoshwolfe/yauzl/issues/33
    if (this.decodeStrings) {
      for (i = 0; i < entry.extraFields.length; i++) {
        const extraField = entry.extraFields[i];
        if (extraField.id === 0x7075) {
          if (extraField.data.length < 6) {
            // too short to be meaningful
            continue;
          }
          // Version       1 byte      version of this extra field, currently 1
          if (extraField.data.readUInt8(0) !== 1) {
            // > Changes may not be backward compatible so this extra
            // > field should not be used if the version is not recognized.
            continue;
          }
          // NameCRC32     4 bytes     File Name Field CRC32 Checksum
          const oldNameCrc32 = extraField.data.readUInt32LE(1);
          if (crc32.unsigned(buffer.subarray(0, entry.fileNameLength)) !== oldNameCrc32) {
            // > If the CRC check fails, this UTF-8 Path Extra Field should be
            // > ignored and the File Name field in the header should be used instead.
            continue;
          }
          // UnicodeName   Variable    UTF-8 version of the entry File Name
          entry.fileName = yauzl.decodeBuffer(extraField.data, 5, extraField.data.length, true);
          break;
        }
      }
    }

    // validate file size
    if (this.validateEntrySizes && entry.compressionMethod === 0) {
      let expectedCompressedSize = entry.uncompressedSize;
      if (entry.isEncrypted()) {
        // traditional encryption prefixes the file data with a header
        expectedCompressedSize += 12;
      }
      if (entry.compressedSize !== expectedCompressedSize) {
        const msg = "compressed/uncompressed size mismatch for stored file: " + entry.compressedSize + " != " + entry.uncompressedSize;
        return this.throwErrorAndAutoClose(new Error(msg));
      }
    }

    if (this.decodeStrings) {
      if (!this.strictFileNames) {
        // allow backslash
        entry.fileName = entry.fileName.replace(/\\/g, "/");
      }
      const errorMessage = this.validateFileName(entry.fileName);
      if (errorMessage != null) return this.throwErrorAndAutoClose(new Error(errorMessage));
    }
    return entry;
  }
  getEntryFromStream() {
    // Find local header
    let buffer = Buffer.alloc(30);

    if (yauzl.readAndAssertNoEof(this.reader, buffer, 0, buffer.length, 0, (err) => { return !!err; }))
      return null;
    while(buffer.readUInt32LE(0) !== 0x04034b50) {
      let i = 0;
      for(; i < buffer.length-3; i++) {
        if (buffer.readUInt32LE(i) === 0x04034b50) break;
        if (buffer.readUInt32LE(i) === 0x02014b50) return null; // central directory
      }
      buffer.copyWithin(0, i);
      if (yauzl.readAndAssertNoEof(this.reader, buffer, i, buffer.length - i, 0, (err) => { return !!err; }))
        return null;
    }

    const entry = new YauzlEntry();

    // all this should be redundant
    // 4 - Version needed to extract (minimum)
    entry.versionNeededToExtract = buffer.readUInt16LE(4);
    // 6 - General purpose bit flag
    entry.generalPurposeBitFlag = buffer.readUInt16LE(6);
    // 8 - Compression method
    entry.compressionMethod = buffer.readUInt16LE(8);
    // 10 - File last modification time
    entry.lastModFileTime = buffer.readUInt16LE(10);
    // 12 - File last modification date
    entry.lastModFileDate = buffer.readUInt16LE(12);
    // 14 - CRC-32
    entry.crc32 = buffer.readUInt32LE(14);
    // 18 - Compressed size
    entry.compressedSize = buffer.readUInt32LE(18);
    // 22 - Uncompressed size
    entry.uncompressedSize = buffer.readUInt32LE(22);
    // 26 - File name length (n)
    entry.fileNameLength = buffer.readUInt16LE(26);
    // 28 - Extra field length (m)
    entry.extraFieldLength = buffer.readUInt16LE(28);

    if (entry.generalPurposeBitFlag & 0x40) throw new Error("strong encryption is not supported");

    buffer = Buffer.allocUnsafe(entry.fileNameLength + entry.extraFieldLength);
    if (yauzl.readAndAssertNoEof(this.reader, buffer, 0, buffer.length, this.readEntryCursor, (err) => { return !!err }))
      return null;

    // 30 - File name
    const isUtf8 = (entry.generalPurposeBitFlag & 0x800) !== 0;
    entry.fileName = this.decodeStrings ? yauzl.decodeBuffer(buffer, 0, entry.fileNameLength, isUtf8)
      : buffer.subarray(0, entry.fileNameLength);

    // 30+n - Extra field
    const extraFieldBuffer = buffer.subarray(entry.fileNameLength);
    entry.extraFields = [];
    let i = 0;
    while (i < extraFieldBuffer.length - 3) {
      const headerId = extraFieldBuffer.readUInt16LE(i + 0);
      const dataSize = extraFieldBuffer.readUInt16LE(i + 2);
      const dataStart = i + 4;
      const dataEnd = dataStart + dataSize;
      if (dataEnd > extraFieldBuffer.length) throw new Error("extra field length exceeds extra field buffer size");
      const dataBuffer = Buffer.allocUnsafe(dataSize);
      extraFieldBuffer.copy(dataBuffer, 0, dataStart, dataEnd);
      entry.extraFields.push({
        id: headerId,
        data: dataBuffer,
      });
      i = dataEnd;
    }

    if (entry.uncompressedSize === 0xffffffff ||
        entry.compressedSize === 0xffffffff) {
      // ZIP64 format
      // find the Zip64 Extended Information Extra Field
      let zip64EiefBuffer = null;
      for (i = 0; i < entry.extraFields.length; i++) {
        const extraField = entry.extraFields[i];
        if (extraField.id === 0x0001) {
          zip64EiefBuffer = extraField.data;
          break;
        }
      }
      if (zip64EiefBuffer == null) {
        throw new Error("expected zip64 extended information extra field");
      }
      let index = 0;
      // 0 - Original Size          8 bytes
      if (entry.uncompressedSize === 0xffffffff) {
        if (index + 8 > zip64EiefBuffer.length) {
          throw new Error("zip64 extended information extra field does not include uncompressed size");
        }
        entry.uncompressedSize = yauzl.readUInt64LE(zip64EiefBuffer, index);
        index += 8;
      }
      // 8 - Compressed Size        8 bytes
      if (entry.compressedSize === 0xffffffff) {
        if (index + 8 > zip64EiefBuffer.length) {
          throw new Error("zip64 extended information extra field does not include compressed size");
        }
        entry.compressedSize = yauzl.readUInt64LE(zip64EiefBuffer, index);
        index += 8;
      }
      // 16 - Relative Header Offset 8 bytes
      // 24 - Disk Start Number      4 bytes
    }

    // check for Info-ZIP Unicode Path Extra Field (0x7075)
    // see https://github.com/thejoshwolfe/yauzl/issues/33
    if (this.decodeStrings) {
      for (i = 0; i < entry.extraFields.length; i++) {
        const extraField = entry.extraFields[i];
        if (extraField.id === 0x7075) {
          if (extraField.data.length < 6) {
            // too short to be meaningful
            continue;
          }
          // Version       1 byte      version of this extra field, currently 1
          if (extraField.data.readUInt8(0) !== 1) {
            // > Changes may not be backward compatible so this extra
            // > field should not be used if the version is not recognized.
            continue;
          }
          // NameCRC32     4 bytes     File Name Field CRC32 Checksum
          const oldNameCrc32 = extraField.data.readUInt32LE(1);
          if (crc32.unsigned(buffer.subarray(0, entry.fileNameLength)) !== oldNameCrc32) {
            // > If the CRC check fails, this UTF-8 Path Extra Field should be
            // > ignored and the File Name field in the header should be used instead.
            continue;
          }
          // UnicodeName   Variable    UTF-8 version of the entry File Name
          entry.fileName = yauzl.decodeBuffer(extraField.data, 5, extraField.data.length, true);
          break;
        }
      }
    }

    // validate file size
    if (this.validateEntrySizes && entry.compressionMethod === 0) {
      let expectedCompressedSize = entry.uncompressedSize;
      if (entry.isEncrypted()) {
        // traditional encryption prefixes the file data with a header
        expectedCompressedSize += 12;
      }
      if (entry.compressedSize !== expectedCompressedSize) {
        const msg = "compressed/uncompressed size mismatch for stored file: " + entry.compressedSize + " != " + entry.uncompressedSize;
        throw new Error(msg);
      }
    }

    if (this.decodeStrings) {
      if (!this.strictFileNames) {
        // allow backslash
        entry.fileName = entry.fileName.replace(/\\/g, "/");
      }
      const errorMessage = this.validateFileName(entry.fileName);
      if (errorMessage != null) throw new Error(errorMessage);
    }

    return entry;
  }
  getInStream(entry, options, bufferSize) {
    // parameter validation
    let relativeStart = 0;
    let relativeEnd = entry.compressedSize;

    // validate options that the caller has no excuse to get wrong
    if (options.decrypt != null) {
      if (!entry.isEncrypted()) {
        throw new Error("options.decrypt can only be specified for encrypted entries");
      }
      if (options.decrypt !== false) throw new Error("invalid options.decrypt value: " + options.decrypt);
      if (entry.isCompressed()) {
        if (options.decompress !== false) throw new Error("entry is encrypted and compressed, and options.decompress !== false");
      }
    }
    if (options.decompress != null) {
      if (!entry.isCompressed()) {
        throw new Error("options.decompress can only be specified for compressed entries");
      }
      if (!(options.decompress === false || options.decompress === true)) {
        throw new Error("invalid options.decompress value: " + options.decompress);
      }
    }
    if (options.start != null || options.end != null) {
      if (entry.isCompressed() && options.decompress !== false) {
        throw new Error("start/end range not allowed for compressed entry without options.decompress === false");
      }
      if (entry.isEncrypted() && options.decrypt !== false) {
        throw new Error("start/end range not allowed for encrypted entry without options.decrypt === false");
      }
    }
    if (options.start != null) {
      relativeStart = options.start;
      if (relativeStart < 0) throw new Error("options.start < 0");
      if (relativeStart > entry.compressedSize) throw new Error("options.start > entry.compressedSize");
    }
    if (options.end != null) {
      relativeEnd = options.end;
      if (relativeEnd < 0) throw new Error("options.end < 0");
      if (relativeEnd > entry.compressedSize) throw new Error("options.end > entry.compressedSize");
      if (relativeEnd < relativeStart) throw new Error("options.end < options.start");
    }
    // any further errors can either be caused by the zipfile,
    // or were introduced in a minor version of yauzl
    if (!this.isOpen) throw new Error("closed");
    if (entry.isEncrypted()) {
      if (options.decrypt !== false) throw new Error("entry is encrypted, and options.decrypt !== false");
    }

    const buffer = Buffer.allocUnsafe(30);
    yauzl.readAndAssertNoEof(this.reader, buffer, 0, buffer.length, entry.relativeOffsetOfLocalHeader);

    // 0 - Local file header signature = 0x04034b50
    const signature = buffer.readUInt32LE(0);
    if (signature !== 0x04034b50) {
      throw new Error("invalid local file header signature: 0x" + signature.toString(16));
    }
    // all this should be redundant
    // 4 - Version needed to extract (minimum)
    // 6 - General purpose bit flag
    // 8 - Compression method
    // 10 - File last modification time
    // 12 - File last modification date
    // 14 - CRC-32
    // 18 - Compressed size
    // 22 - Uncompressed size
    // 26 - File name length (n)
    const fileNameLength = buffer.readUInt16LE(26);
    // 28 - Extra field length (m)
    const extraFieldLength = buffer.readUInt16LE(28);
    // 30 - File name
    // 30+n - Extra field
    const localFileHeaderEnd = entry.relativeOffsetOfLocalHeader + buffer.length + fileNameLength + extraFieldLength;
    let decompress;
    if (entry.compressionMethod === 0) {
      // 0 - The file is stored (no compression)
      decompress = false;
    } else if (entry.compressionMethod === 8) {
      // 8 - The file is Deflated
      decompress = options.decompress != null ? options.decompress : true;
    } else {
      throw new Error("unsupported compression method: " + entry.compressionMethod);
    }
    const fileDataStart = localFileHeaderEnd;
    const fileDataEnd = fileDataStart + entry.compressedSize;
    if (entry.compressedSize !== 0) {
      // bounds check now, because the read streams will probably not complain loud enough.
      // since we're dealing with an unsigned offset plus an unsigned size,
      // we only have 1 thing to check for.
      if (fileDataEnd > this.fileSize) {
        throw new Error("file data overflows file bounds: " +
          fileDataStart + " + " + entry.compressedSize + " > " + this.fileSize);
      }
    }

    // In stream generation
    const base = new ZipInStream(this.reader, fileDataStart, entry.compressedSize, bufferSize);
    if (decompress)
      return new InflateInStream(base, node.zlib.inflateRawSync, bufferSize);
    else
      return base;
  }
  getInStreamFromStream(entry, options, bufferSize) {
    let decompress;
    if (entry.compressionMethod === 0) {
      // 0 - The file is stored (no compression)
      decompress = false;
    } else if (entry.compressionMethod === 8) {
      // 8 - The file is Deflated
      decompress = options.decompress != null ? options.decompress : true;
    } else {
      throw new Error("unsupported compression method: " + entry.compressionMethod);
    }

    let size = entry.compressedSize;
    if (entry.generalPurposeBitFlag & 0x8)
      size = Infinity;

    const base = new ZipInStream(this.reader, 0, size, bufferSize, entry);
    if (decompress)
      return new InflateInStream(base, node.zlib.inflateRawSync, bufferSize);
    else
      return base;
  }
  throwErrorAndAutoClose(err) {
    if (this.autoClose) this.close();
    throw err;
  }
  validateFileName(fileName) {
    if (fileName.indexOf("\\") !== -1) {
      return "invalid characters in fileName: " + fileName;
    }
    if (/^[a-zA-Z]:/.test(fileName) || /^(\/)/.test(fileName)) {
      return "absolute path: " + fileName;
    }
    if (fileName.split("/").indexOf("..") !== -1) {
      return "invalid relative path: " + fileName;
    }
    // all good
    return null;
  }
}

class YauzlEntry {

  // all these are numbers
  versionMadeBy;
  versionNeededToExtract;
  generalPurposeBitFlag;
  compressionMethod;
  lastModFileTime; // (MS-DOS format, see getLastModDateTime)
  lastModFileDate; // (MS-DOS format, see getLastModDateTime)
  crc32;
  compressedSize;
  uncompressedSize;
  fileNameLength; // (bytes)
  extraFieldLength; // (bytes)
  fileCommentLength; // (bytes)
  internalFileAttributes;
  externalFileAttributes;
  relativeOffsetOfLocalHeader;

  fileName;
  extraFields;
  fileComment;

  foundDataDescriptor = false;

  // getLastModDate() {
  //   return dosDateTimeToDate(this.lastModFileDate, this.lastModFileTime);
  // }
  isEncrypted() {
    return (this.generalPurposeBitFlag & 0x1) !== 0;
  }
  isCompressed() {
    return this.compressionMethod === 8;
  }
}

class YauzlFileReader {
  constructor(fd) {
    this.#fd = fd;
  }

  #fd;
  posMatters = true;

  read(buffer, offset, length, position) {
    return node.fs.readSync(this.#fd, buffer, offset, length, position);
  }

  unreadBuf() {}

  close() {
    node.fs.closeSync(this.#fd);
  }
}

class YauzlStreamReader {
  constructor(in$) {
    this.#in = in$;
  }

  #in;
  #pre;
  posMatters = false;

  read(buffer, offset, length) {
    let c1 = 0;
    if (this.#pre) {
      c1 = this.#pre.copy(buffer, offset, 0, Math.min(this.#pre.length, length));
      offset += c1;
      length -= c1;
      if (c1 == this.#pre.length)
        this.#pre = undefined;
      else
        this.#pre = this.#pre.subarray(c1);
    }

    let c2 = 0;
    if (length > 0) {
      const fanBuf = MemBuf.makeCapacity(length);
      c2 = this.#in.readBuf(fanBuf, length) || 0;
      Buffer.from(fanBuf.__unsafeArray()).copy(buffer, offset);
    }
    return c1 + c2;
  }

  unreadBuf(buf) {
    this.#pre = buf;
  }

  close() {}
}

/*
=== yazl ===

The MIT License (MIT)

Copyright (c) 2014 Josh Wolfe

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

const ZIP64_END_OF_CENTRAL_DIRECTORY_RECORD_SIZE = 56;
const ZIP64_END_OF_CENTRAL_DIRECTORY_LOCATOR_SIZE = 20;
const END_OF_CENTRAL_DIRECTORY_RECORD_SIZE = 22;
const LOCAL_FILE_HEADER_FIXED_SIZE = 30;
const VERSION_NEEDED_TO_EXTRACT_UTF8 = 20;
const VERSION_NEEDED_TO_EXTRACT_ZIP64 = 45;
// 3 = unix. 63 = spec version 6.3
const VERSION_MADE_BY = (3 << 8) | 63;
const FILE_NAME_IS_UTF8 = 1 << 11;
const UNKNOWN_CRC32_AND_FILE_SIZES = 1 << 3;
const DATA_DESCRIPTOR_SIZE = 16;
const ZIP64_DATA_DESCRIPTOR_SIZE = 24;
const CENTRAL_DIRECTORY_RECORD_FIXED_SIZE = 46;
const ZIP64_EXTENDED_INFORMATION_EXTRA_FIELD_SIZE = 28;
const EMPTY_BUFFER = (typeof Buffer !== 'undefined') ? Buffer.allocUnsafe(0) : new Array();

class yazl {
  static validateMetadataPath(metadataPath) {
    if (metadataPath === "") throw new Error("empty metadataPath");
    metadataPath = metadataPath.replace(/\\/g, "/");
    if (/^[a-zA-Z]:/.test(metadataPath) || /^(\/)/.test(metadataPath)) throw new Error("absolute path: " + metadataPath);
    if (metadataPath.split("/").indexOf("..") !== -1) throw new Error("invalid relative path: " + metadataPath);
    return metadataPath;
  }
  static writeUInt64LE(buffer, n, offset) {
    // can't use bitshift here, because JavaScript only allows bitshifting on 32-bit integers.
    const high = Math.floor(n / 0x100000000);
    const low = n % 0x100000000;
    buffer.writeUInt32LE(low, offset);
    buffer.writeUInt32LE(high, offset + 4);
  }
  static dateToDosDateTime(jsDate) {
    let date = 0;
    date |= jsDate.getDate() & 0x1f; // 1-31
    date |= ((jsDate.getMonth() + 1) & 0xf) << 5; // 0-11, 1-12
    date |= ((jsDate.getFullYear() - 1980) & 0x7f) << 9; // 0-128, 1980-2108
  
    let time = 0;
    time |= Math.floor(jsDate.getSeconds() / 2); // 0-59, 0-29 (lose odd numbers)
    time |= (jsDate.getMinutes() & 0x3f) << 5; // 0-59
    time |= (jsDate.getHours() & 0x1f) << 11; // 0-23
  
    return {date: date, time: time};
  }

  static #cp437 = '\u0000☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼ !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~⌂ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■ ';
  static #reverseCp437;
  static encodeCp437(string) {
    throw "TODO:encodeCp437(string)";
    // if (/^[\x20-\x7e]*$/.test(string)) {
    //   // CP437, ASCII, and UTF-8 overlap in this range.
    //   return bufferFrom(string, "utf-8");
    // }
  
    // // This is the slow path.
    // if (!yazl.#reverseCp437) {
    //   // cache this once
    //   let reverseCp437 = {};
    //   for (var i = 0; i < yazl.#cp437.length; i++) {
    //     reverseCp437[cp437[i]] = i;
    //   }
    // }
  
    // var result = bufferAlloc(string.length);
    // for (var i = 0; i < string.length; i++) {
    //   var b = reverseCp437[string[i]];
    //   if (b == null) throw new Error("character not encodable in CP437: " + JSON.stringify(string[i]));
    //   result[i] = b;
    // }
  
    // return result;
  }
}

class YazlZipFile {
  constructor(out) {
    this.out = out;
    this.entries = [];
    this.outputStreamCursor = 0;
    this.ended = false; // .end() sets this
    this.forceZip64Eocd = false; // configurable in .end()
  }

  #lastOut;
  addEntryAt(metadataPath, options) {
    metadataPath = yazl.validateMetadataPath(metadataPath);
    if (options == null) options = {};
    const entry = new YazlEntry(metadataPath, options);
    this.entries.push(entry);

    if (this.#lastOut) {
      this.#lastOut.close();
      const lastEntry = this.entries[this.entries.length-2];
      this.#writeToOutputStream(lastEntry.getDataDescriptor());
    }
    entry.relativeOffsetOfLocalHeader = this.outputStreamCursor;
    this.#writeToOutputStream(entry.getLocalFileHeader());

    if (entry.compress)
      this.#lastOut = new DeflateOutStream(this.out, node.zlib.deflateRawSync, options.level, this, entry);
    else
      this.#lastOut = new ZipOutStream(this, entry);
    return this.#lastOut;
  }

  #eocdrSignatureBuffer = Buffer.from([0x50, 0x4b, 0x05, 0x06]);
  end(options) {
    if (!options) options = {};
    if (this.ended) return;
    this.ended = true;

    if (this.#lastOut) {
      this.#lastOut.close();
      const lastEntry = this.entries[this.entries.length-1];
      this.#writeToOutputStream(lastEntry.getDataDescriptor());
    }

    this.forceZip64Eocd = !!options.forceZip64Format;
    // no comment.
    this.comment = EMPTY_BUFFER;
    this.#writeEocd();
  }

  #writeToOutputStream(buf) {
    this.out.writeBuf(MemBuf.__makeBytes(buf));
    this.outputStreamCursor += buf.length;
  }

  #writeEocd() {
    this.offsetOfStartOfCentralDirectory = this.outputStreamCursor;
    for(let i = 0; i < this.entries.length; i++) {
      const entry = this.entries[i];
      this.#writeToOutputStream(entry.getCentralDirectoryRecord());
    }
    this.#writeToOutputStream(this.#getEndOfCentralDirectoryRecord());
    this.out.close();
  }

  #getEndOfCentralDirectoryRecord(actuallyJustTellMeHowLongItWouldBe) {
    let needZip64Format = false;
    let normalEntriesLength = this.entries.length;
    if (this.forceZip64Eocd || this.entries.length >= 0xffff) {
      normalEntriesLength = 0xffff;
      needZip64Format = true;
    }
    const sizeOfCentralDirectory = this.outputStreamCursor - this.offsetOfStartOfCentralDirectory;
    let normalSizeOfCentralDirectory = sizeOfCentralDirectory;
    if (this.forceZip64Eocd || sizeOfCentralDirectory >= 0xffffffff) {
      normalSizeOfCentralDirectory = 0xffffffff;
      needZip64Format = true;
    }
    let normalOffsetOfStartOfCentralDirectory = this.offsetOfStartOfCentralDirectory;
    if (this.forceZip64Eocd || this.offsetOfStartOfCentralDirectory >= 0xffffffff) {
      normalOffsetOfStartOfCentralDirectory = 0xffffffff;
      needZip64Format = true;
    }
    if (actuallyJustTellMeHowLongItWouldBe) {
      if (needZip64Format) {
        return (
          ZIP64_END_OF_CENTRAL_DIRECTORY_RECORD_SIZE +
          ZIP64_END_OF_CENTRAL_DIRECTORY_LOCATOR_SIZE +
          END_OF_CENTRAL_DIRECTORY_RECORD_SIZE
        );
      } else {
        return END_OF_CENTRAL_DIRECTORY_RECORD_SIZE;
      }
    }

    const eocdrBuffer = Buffer.allocUnsafe(END_OF_CENTRAL_DIRECTORY_RECORD_SIZE + this.comment.length);
    // end of central dir signature                       4 bytes  (0x06054b50)
    eocdrBuffer.writeUInt32LE(0x06054b50, 0);
    // number of this disk                                2 bytes
    eocdrBuffer.writeUInt16LE(0, 4);
    // number of the disk with the start of the central directory  2 bytes
    eocdrBuffer.writeUInt16LE(0, 6);
    // total number of entries in the central directory on this disk  2 bytes
    eocdrBuffer.writeUInt16LE(normalEntriesLength, 8);
    // total number of entries in the central directory   2 bytes
    eocdrBuffer.writeUInt16LE(normalEntriesLength, 10);
    // size of the central directory                      4 bytes
    eocdrBuffer.writeUInt32LE(normalSizeOfCentralDirectory, 12);
    // offset of start of central directory with respect to the starting disk number  4 bytes
    eocdrBuffer.writeUInt32LE(normalOffsetOfStartOfCentralDirectory, 16);
    // .ZIP file comment length                           2 bytes
    eocdrBuffer.writeUInt16LE(this.comment.length, 20);
    // .ZIP file comment                                  (variable size)
    this.comment.copy(eocdrBuffer, 22);
  
    if (!needZip64Format) return eocdrBuffer;
  
    // ZIP64 format
    // ZIP64 End of Central Directory Record
    const zip64EocdrBuffer = Buffer.allocUnsafe(ZIP64_END_OF_CENTRAL_DIRECTORY_RECORD_SIZE);
    // zip64 end of central dir signature                                             4 bytes  (0x06064b50)
    zip64EocdrBuffer.writeUInt32LE(0x06064b50, 0);
    // size of zip64 end of central directory record                                  8 bytes
    yazl.writeUInt64LE(zip64EocdrBuffer, ZIP64_END_OF_CENTRAL_DIRECTORY_RECORD_SIZE - 12, 4);
    // version made by                                                                2 bytes
    zip64EocdrBuffer.writeUInt16LE(VERSION_MADE_BY, 12);
    // version needed to extract                                                      2 bytes
    zip64EocdrBuffer.writeUInt16LE(VERSION_NEEDED_TO_EXTRACT_ZIP64, 14);
    // number of this disk                                                            4 bytes
    zip64EocdrBuffer.writeUInt32LE(0, 16);
    // number of the disk with the start of the central directory                     4 bytes
    zip64EocdrBuffer.writeUInt32LE(0, 20);
    // total number of entries in the central directory on this disk                  8 bytes
    yazl.writeUInt64LE(zip64EocdrBuffer, this.entries.length, 24);
    // total number of entries in the central directory                               8 bytes
    yazl.writeUInt64LE(zip64EocdrBuffer, this.entries.length, 32);
    // size of the central directory                                                  8 bytes
    yazl.writeUInt64LE(zip64EocdrBuffer, sizeOfCentralDirectory, 40);
    // offset of start of central directory with respect to the starting disk number  8 bytes
    yazl.writeUInt64LE(zip64EocdrBuffer, this.offsetOfStartOfCentralDirectory, 48);
    // zip64 extensible data sector                                                   (variable size)
    // nothing in the zip64 extensible data sector
  
  
    // ZIP64 End of Central Directory Locator
    const zip64EocdlBuffer = Buffer.allocUnsafe(ZIP64_END_OF_CENTRAL_DIRECTORY_LOCATOR_SIZE);
    // zip64 end of central dir locator signature                               4 bytes  (0x07064b50)
    zip64EocdlBuffer.writeUInt32LE(0x07064b50, 0);
    // number of the disk with the start of the zip64 end of central directory  4 bytes
    zip64EocdlBuffer.writeUInt32LE(0, 4);
    // relative offset of the zip64 end of central directory record             8 bytes
    yazl.writeUInt64LE(zip64EocdlBuffer, this.outputStreamCursor, 8);
    // total number of disks                                                    4 bytes
    zip64EocdlBuffer.writeUInt32LE(1, 16);
  
  
    return Buffer.concat([
      zip64EocdrBuffer,
      zip64EocdlBuffer,
      eocdrBuffer,
    ]);
  }
}

class YazlEntry {
  constructor(metadataPath, options) {
    this.utf8FileName = Buffer.from(metadataPath);
    if (this.utf8FileName.length > 0xffff)
      throw new Error("utf8 file name too long. " + this.utf8FileName.length + " > " + 0xffff);
    this.isDirectory = metadataPath.endsWith("/");
    this.setLastModDate(options.mtime);
    if (options.mode != null) {
      this.setFileAttributesMode(options.mode);
    } else {
      this.setFileAttributesMode(this.isDirectory ? 0o40775 : 0o100664);
    }
    if (options.uncompressedSize != null &&
        options.compressedSize != null &&
        options.crc32 != null) {
      this.crcAndFileSizeKnown = true;
      this.crc32 = options.crc32;
      this.uncompressedSize = options.uncompressedSize;
      this.compressedSize = options.compressedSize;
    } else {
      // unknown so far
      this.crcAndFileSizeKnown = false;
      this.crc32 = null;
      this.uncompressedSize = null;
      this.compressedSize = null;
      if (options.uncompressedSize != null) this.uncompressedSize = options.uncompressedSize;
    }
    this.compress = options.compress != null ? !!options.compress : !this.isDirectory;
    this.forceZip64Format = !!options.forceZip64Format;
    if (options.fileComment) {
      if (typeof options.fileComment === "string") {
        this.fileComment = Buffer.from(options.fileComment, "utf-8");
      } else {
        // It should be a Buffer
        this.fileComment = options.fileComment;
      }
      if (this.fileComment.length > 0xffff) throw new Error("fileComment is too large");
    } else {
      // no comment.
      this.fileComment = EMPTY_BUFFER;
    }
    if (options.extra && options.extra.length > 0xffffffff)
      throw new Error("extra field data is too large");
    this.extra = options.extra || EMPTY_BUFFER;
  }
  setLastModDate(date) {
    const dosDateTime = yazl.dateToDosDateTime(date);
    this.lastModFileTime = dosDateTime.time;
    this.lastModFileDate = dosDateTime.date;
  }
  setFileAttributesMode(mode) {
    if ((mode & 0xffff) !== mode) throw new Error("invalid mode. expected: 0 <= " + mode + " <= " + 0xffff);
    // http://unix.stackexchange.com/questions/14705/the-zip-formats-external-file-attribute/14727#14727
    this.externalFileAttributes = (mode << 16) >>> 0;
  }
  useZip64Format() {
    return (
      (this.forceZip64Format) ||
      (this.uncompressedSize != null && this.uncompressedSize > 0xfffffffe) ||
      (this.compressedSize != null && this.compressedSize > 0xfffffffe) ||
      (this.relativeOffsetOfLocalHeader != null && this.relativeOffsetOfLocalHeader > 0xfffffffe)
    );
  }
  getLocalFileHeader() {
    let crc32 = 0;
    let compressedSize = 0;
    let uncompressedSize = 0;
    if (this.crcAndFileSizeKnown) {
      crc32 = this.crc32;
      compressedSize = this.compressedSize;
      uncompressedSize = this.uncompressedSize;
    }

    const fixedSizeStuff = Buffer.allocUnsafe(LOCAL_FILE_HEADER_FIXED_SIZE);
    let generalPurposeBitFlag = FILE_NAME_IS_UTF8;
    if (!this.crcAndFileSizeKnown) generalPurposeBitFlag |= UNKNOWN_CRC32_AND_FILE_SIZES;

    // local file header signature     4 bytes  (0x04034b50)
    fixedSizeStuff.writeUInt32LE(0x04034b50, 0);
    // version needed to extract       2 bytes
    fixedSizeStuff.writeUInt16LE(VERSION_NEEDED_TO_EXTRACT_UTF8, 4);
    // general purpose bit flag        2 bytes
    fixedSizeStuff.writeUInt16LE(generalPurposeBitFlag, 6);
    // compression method              2 bytes
    fixedSizeStuff.writeUInt16LE(this.getCompressionMethod(), 8);
    // last mod file time              2 bytes
    fixedSizeStuff.writeUInt16LE(this.lastModFileTime, 10);
    // last mod file date              2 bytes
    fixedSizeStuff.writeUInt16LE(this.lastModFileDate, 12);
    // crc-32                          4 bytes
    fixedSizeStuff.writeUInt32LE(crc32, 14);
    // compressed size                 4 bytes
    fixedSizeStuff.writeUInt32LE(compressedSize, 18);
    // uncompressed size               4 bytes
    fixedSizeStuff.writeUInt32LE(uncompressedSize, 22);
    // file name length                2 bytes
    fixedSizeStuff.writeUInt16LE(this.utf8FileName.length, 26);
    // extra field length              2 bytes
    fixedSizeStuff.writeUInt16LE(this.extra.length, 28);
    return Buffer.concat([
      fixedSizeStuff,
      // file name (variable size)
      this.utf8FileName,
      // extra field (variable size)
      this.extra
    ]);
  }
  getDataDescriptor() {
    if (this.crcAndFileSizeKnown) {
      // the Mac Archive Utility requires this not be present unless we set general purpose bit 3
      return EMPTY_BUFFER;
    }
    if (!this.useZip64Format()) {
      const buffer = Buffer.allocUnsafe(DATA_DESCRIPTOR_SIZE);
      // optional signature (required according to Archive Utility)
      buffer.writeUInt32LE(0x08074b50, 0);
      // crc-32                          4 bytes
      buffer.writeUInt32LE(this.crc32, 4);
      // compressed size                 4 bytes
      buffer.writeUInt32LE(this.compressedSize, 8);
      // uncompressed size               4 bytes
      buffer.writeUInt32LE(this.uncompressedSize, 12);
      return buffer;
    } else {
      // ZIP64 format
      const buffer = Buffer.allocUnsafe(ZIP64_DATA_DESCRIPTOR_SIZE);
      // optional signature (unknown if anyone cares about this)
      buffer.writeUInt32LE(0x08074b50, 0);
      // crc-32                          4 bytes
      buffer.writeUInt32LE(this.crc32, 4);
      // compressed size                 8 bytes
      yazl.writeUInt64LE(buffer, this.compressedSize, 8);
      // uncompressed size               8 bytes
      yazl.writeUInt64LE(buffer, this.uncompressedSize, 16);
      return buffer;
    }
  }
  getCentralDirectoryRecord() {
    const fixedSizeStuff = Buffer.allocUnsafe(CENTRAL_DIRECTORY_RECORD_FIXED_SIZE);
    let generalPurposeBitFlag = FILE_NAME_IS_UTF8;
    if (!this.crcAndFileSizeKnown) generalPurposeBitFlag |= UNKNOWN_CRC32_AND_FILE_SIZES;

    let normalCompressedSize = this.compressedSize;
    let normalUncompressedSize = this.uncompressedSize;
    let normalRelativeOffsetOfLocalHeader = this.relativeOffsetOfLocalHeader;
    let versionNeededToExtract;
    let zeiefBuffer;
    if (this.useZip64Format()) {
      normalCompressedSize = 0xffffffff;
      normalUncompressedSize = 0xffffffff;
      normalRelativeOffsetOfLocalHeader = 0xffffffff;
      versionNeededToExtract = VERSION_NEEDED_TO_EXTRACT_ZIP64;

      // ZIP64 extended information extra field
      zeiefBuffer = Buffer.allocUnsafe(ZIP64_EXTENDED_INFORMATION_EXTRA_FIELD_SIZE);
      // 0x0001                  2 bytes    Tag for this "extra" block type
      zeiefBuffer.writeUInt16LE(0x0001, 0);
      // Size                    2 bytes    Size of this "extra" block
      zeiefBuffer.writeUInt16LE(ZIP64_EXTENDED_INFORMATION_EXTRA_FIELD_SIZE - 4, 2);
      // Original Size           8 bytes    Original uncompressed file size
      yazl.writeUInt64LE(zeiefBuffer, this.uncompressedSize, 4);
      // Compressed Size         8 bytes    Size of compressed data
      yazl.writeUInt64LE(zeiefBuffer, this.compressedSize, 12);
      // Relative Header Offset  8 bytes    Offset of local header record
      yazl.writeUInt64LE(zeiefBuffer, this.relativeOffsetOfLocalHeader, 20);
      // Disk Start Number       4 bytes    Number of the disk on which this file starts
      // (omit)
    } else {
      versionNeededToExtract = VERSION_NEEDED_TO_EXTRACT_UTF8;
      zeiefBuffer = EMPTY_BUFFER;
    }

    // central file header signature   4 bytes  (0x02014b50)
    fixedSizeStuff.writeUInt32LE(0x02014b50, 0);
    // version made by                 2 bytes
    fixedSizeStuff.writeUInt16LE(VERSION_MADE_BY, 4);
    // version needed to extract       2 bytes
    fixedSizeStuff.writeUInt16LE(versionNeededToExtract, 6);
    // general purpose bit flag        2 bytes
    fixedSizeStuff.writeUInt16LE(generalPurposeBitFlag, 8);
    // compression method              2 bytes
    fixedSizeStuff.writeUInt16LE(this.getCompressionMethod(), 10);
    // last mod file time              2 bytes
    fixedSizeStuff.writeUInt16LE(this.lastModFileTime, 12);
    // last mod file date              2 bytes
    fixedSizeStuff.writeUInt16LE(this.lastModFileDate, 14);
    // crc-32                          4 bytes
    fixedSizeStuff.writeUInt32LE(this.crc32, 16);
    // compressed size                 4 bytes
    fixedSizeStuff.writeUInt32LE(normalCompressedSize, 20);
    // uncompressed size               4 bytes
    fixedSizeStuff.writeUInt32LE(normalUncompressedSize, 24);
    // file name length                2 bytes
    fixedSizeStuff.writeUInt16LE(this.utf8FileName.length, 28);
    // extra field length              2 bytes
    fixedSizeStuff.writeUInt16LE(zeiefBuffer.length + this.extra.length, 30);
    // file comment length             2 bytes
    fixedSizeStuff.writeUInt16LE(this.fileComment.length, 32);
    // disk number start               2 bytes
    fixedSizeStuff.writeUInt16LE(0, 34);
    // internal file attributes        2 bytes
    fixedSizeStuff.writeUInt16LE(0, 36);
    // external file attributes        4 bytes
    fixedSizeStuff.writeUInt32LE(this.externalFileAttributes, 38);
    // relative offset of local header 4 bytes
    fixedSizeStuff.writeUInt32LE(normalRelativeOffsetOfLocalHeader, 42);

    return Buffer.concat([
      fixedSizeStuff,
      // file name (variable size)
      this.utf8FileName,
      // extra field (variable size)
      zeiefBuffer,
      this.extra,
      // file comment (variable size)
      this.fileComment
    ]);
  }
  getCompressionMethod() {
    const NO_COMPRESSION = 0;
    const DEFLATE_COMPRESSION = 8;
    return this.compress ? DEFLATE_COMPRESSION : NO_COMPRESSION;
  }
}