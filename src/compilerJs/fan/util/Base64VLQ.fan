//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Jul 15  Matthew Giannini  Creation
//

**
** Base64 VLQ encoding used by source map v3 mappings. The sign is
** moved into the low bit, then 5-bit groups are emitted least significant
** first as base64 digits with 0x20 as the continuation bit.
**
class Base64VLQ
{
  static Str encode(Int val)
  {
    v := val < 0 ? (-val).shiftl(1).or(1) : val.shiftl(1)
    buf := StrBuf()
    while (true)
    {
      digit := v.and(0x1f)
      v = v.shiftr(5)
      if (v > 0) digit = digit.or(0x20)
      buf.addChar(digits[digit])
      if (v == 0) break
    }
    return buf.toStr
  }

  private static const Str digits := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
}
