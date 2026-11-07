//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Nov 2026  Brian Frank  Creation
//

/**
 * Message digests MD5 (RFC 1321), SHA-1 and SHA-256 (FIPS 180-4),
 * HMAC (RFC 2104), and PBKDF2 (RFC 8018) over byte arrays.
 */
const buf_digest = (function () {

  const rotl = (x, n) => (x << n) | (x >>> (32 - n));
  const rotr = (x, n) => (x >>> n) | (x << (32 - n));

  const concat = (a, b) => {
    const r = new Uint8Array(a.length + b.length);
    r.set(a);
    r.set(b, a.length);
    return r;
  };

  // append 0x80, zeros, and 64-bit message bit length to 64 byte boundary
  const pad = (bytes, le) => {
    const n = bytes.length;
    const size = (((n + 8) >> 6) + 1) << 6;
    const m = new Uint8Array(size);
    m.set(bytes);
    m[n] = 0x80;
    const v = new DataView(m.buffer);
    const lo = (n * 8) >>> 0, hi = Math.floor(n / 0x20000000);
    if (le) { v.setUint32(size-8, lo, true); v.setUint32(size-4, hi, true); }
    else    { v.setUint32(size-8, hi);       v.setUint32(size-4, lo); }
    return v;
  };

  const toBytes = (words, le) => {
    const v = new DataView(new ArrayBuffer(words.length * 4));
    words.forEach((w, i) => v.setUint32(i*4, w >>> 0, le));
    return Array.from(new Uint8Array(v.buffer));
  };

//////////////////////////////////////////////////////////////////////////
// MD5
//////////////////////////////////////////////////////////////////////////

  // floor(abs(sin(i+1)) * 2^32)
  const md5T = [
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
    0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
    0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
    0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
    0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
  ];

  // per round shift amounts
  const md5S = [7, 12, 17, 22, 5, 9, 14, 20, 4, 11, 16, 23, 6, 10, 15, 21];

  const md5 = (bytes) => {
    const v = pad(bytes, true);
    const h = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476];
    const x = new Array(16);
    for (let off=0; off<v.byteLength; off+=64) {
      for (let j=0; j<16; ++j) x[j] = v.getUint32(off + j*4, true);
      let [a, b, c, d] = h;
      for (let i=0; i<64; ++i) {
        const r = i >> 4;
        let f, k;
        if (r == 0)      { f = (b & c) | (~b & d); k = i; }
        else if (r == 1) { f = (b & d) | (c & ~d); k = (5*i + 1) & 15; }
        else if (r == 2) { f = b ^ c ^ d;          k = (3*i + 5) & 15; }
        else             { f = c ^ (b | ~d);       k = (7*i) & 15; }
        const t = (a + f + md5T[i] + x[k]) | 0;
        a = d; d = c; c = b;
        b = (b + rotl(t, md5S[(r << 2) | (i & 3)])) | 0;
      }
      h[0] = (h[0] + a) | 0;
      h[1] = (h[1] + b) | 0;
      h[2] = (h[2] + c) | 0;
      h[3] = (h[3] + d) | 0;
    }
    return toBytes(h, true);
  };

//////////////////////////////////////////////////////////////////////////
// SHA-1
//////////////////////////////////////////////////////////////////////////

  const sha1 = (bytes) => {
    const v = pad(bytes, false);
    const h = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0];
    const w = new Array(80);
    for (let off=0; off<v.byteLength; off+=64) {
      for (let t=0; t<16; ++t) w[t] = v.getUint32(off + t*4);
      for (let t=16; t<80; ++t) w[t] = rotl(w[t-3] ^ w[t-8] ^ w[t-14] ^ w[t-16], 1);
      let [a, b, c, d, e] = h;
      for (let t=0; t<80; ++t) {
        let f, k;
        if (t < 20)      { f = (b & c) | (~b & d);          k = 0x5a827999; }
        else if (t < 40) { f = b ^ c ^ d;                   k = 0x6ed9eba1; }
        else if (t < 60) { f = (b & c) | (b & d) | (c & d); k = 0x8f1bbcdc; }
        else             { f = b ^ c ^ d;                   k = 0xca62c1d6; }
        const tmp = (rotl(a, 5) + f + e + k + w[t]) | 0;
        e = d; d = c; c = rotl(b, 30); b = a; a = tmp;
      }
      h[0] = (h[0] + a) | 0;
      h[1] = (h[1] + b) | 0;
      h[2] = (h[2] + c) | 0;
      h[3] = (h[3] + d) | 0;
      h[4] = (h[4] + e) | 0;
    }
    return toBytes(h, false);
  };

//////////////////////////////////////////////////////////////////////////
// SHA-256
//////////////////////////////////////////////////////////////////////////

  // first 32 bits of fractional part of cube roots of first 64 primes
  const sha256K = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  const sha256 = (bytes) => {
    const v = pad(bytes, false);
    // first 32 bits of fractional part of square roots of first 8 primes
    const h = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
    const w = new Array(64);
    for (let off=0; off<v.byteLength; off+=64) {
      for (let t=0; t<16; ++t) w[t] = v.getUint32(off + t*4) | 0;
      for (let t=16; t<64; ++t) {
        const x = w[t-15], y = w[t-2];
        const s0 = rotr(x, 7) ^ rotr(x, 18) ^ (x >>> 3);
        const s1 = rotr(y, 17) ^ rotr(y, 19) ^ (y >>> 10);
        w[t] = (w[t-16] + s0 + w[t-7] + s1) | 0;
      }
      let [a, b, c, d, e, f, g, hh] = h;
      for (let t=0; t<64; ++t) {
        const t1 = (hh + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + sha256K[t] + w[t]) | 0;
        const t2 = ((rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c))) | 0;
        hh = g; g = f; f = e; e = (d + t1) | 0;
        d = c; c = b; b = a; a = (t1 + t2) | 0;
      }
      h[0] = (h[0] + a) | 0;
      h[1] = (h[1] + b) | 0;
      h[2] = (h[2] + c) | 0;
      h[3] = (h[3] + d) | 0;
      h[4] = (h[4] + e) | 0;
      h[5] = (h[5] + f) | 0;
      h[6] = (h[6] + g) | 0;
      h[7] = (h[7] + hh) | 0;
    }
    return toBytes(h, false);
  };

//////////////////////////////////////////////////////////////////////////
// HMAC / PBKDF2
//////////////////////////////////////////////////////////////////////////

  // return function to compute HMAC of data for given hash and key;
  // all our hashes use a 64 byte block size
  const mac = (hash, key) => {
    if (key.length > 64) key = hash(key);
    const ipad = new Uint8Array(64), opad = new Uint8Array(64);
    for (let i=0; i<64; ++i) {
      const b = i < key.length ? key[i] : 0;
      ipad[i] = b ^ 0x36;
      opad[i] = b ^ 0x5c;
    }
    return (data) => hash(concat(opad, hash(concat(ipad, data))));
  };

  const pbkdf2 = (hash, pass, salt, iterations, dkLen) => {
    const prf = mac(hash, pass);
    const dk = [];
    for (let i=1; dk.length<dkLen; ++i) {
      let u = prf(concat(salt, [i >>> 24, (i >>> 16) & 0xff, (i >>> 8) & 0xff, i & 0xff]));
      const t = u.slice();
      for (let c=1; c<iterations; ++c) {
        u = prf(u);
        for (let j=0; j<t.length; ++j) t[j] ^= u[j];
      }
      dk.push(...t);
    }
    return dk.slice(0, dkLen);
  };

//////////////////////////////////////////////////////////////////////////
// API
//////////////////////////////////////////////////////////////////////////

  const hashes = { "MD5": md5, "SHA1": sha1, "SHA-1": sha1, "SHA-256": sha256 };

  const find = (algorithm) => {
    const hash = hashes[algorithm];
    if (!hash) throw ArgErr.make("Unknown digest algorithm " + algorithm);
    return hash;
  };

  return {
    digest: (algorithm, data) => find(algorithm)(data),
    hmac:   (algorithm, data, key) => mac(find(algorithm), key)(data),
    pbkdf2: (algorithm, pass, salt, iterations, dkLen) => pbkdf2(find(algorithm), pass, salt, iterations, dkLen),
  };

})();
