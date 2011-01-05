#!/usr/bin/env fan

//
// Conversion from linux libc locales to Fantom props
//
// Original by Kamil Toman - Nov 2010
// Modified by Brian Frank - Jan 2011

class Main
{
  // skip languages without large populations (around < 5M), countries
  // which also use popular dual languages (English, Russia, etc), or
  // missing two-letter ISO codes
  static const Str[] skipLangs :=
  [
    // TODO
    "el",   // Greek not mapping months/weekdays?
    "uk",   // Not parsing right???

    // configured to skip for now
    "aa",   // Afar
    "af",   // Afrikaans
    "am",   // Amharic
    "an",   // Aragonese
    "as",   // Assamese
    "ast",  // Asturian Language Locale for Spain (3 letter code?)
    "az",   // Azerbaijani
    "be",   // Belarusian
    "ber",  // Amazigh Language Locale for Algeria (3 letter code?)
    "br",   // Breton
    "bs",   // Bosnian
    "byn",  // Blin language locale for Eritrea.
    "crh",  // Tatar - should be tt
    "csb",  // Kashubian locale for Poland
    "cv",   // Chuvash
    "cy",   // Welsh
    "dv",   // Maldivian
    "dz",   // Dzongkha
    "en",   // got it already
    "eo",   // Esperanto
    "et",   // Estonian
    "fil",  // Filipinio, should be tagalog tl
    "fo",   // Faroese
    "fur",  // Furlan locale for Italy
    "fy",   // Frisian
    "ga",   // Irish
    "gd",   // Gaelic
    "gl",   // Galician
    "gez",
    "gv",   // Manx
    "ha",   // Hausa
    "hne",  // Chhattisgarhi, but considered dialect of Hindi
    "hsb",  // german
    "ht",   // Breyol Language Locale for Haiti
    "hy",   // Armenian (speak Russian too?)
    "i18n",
    "ia",   // Interlingua
    "ig",   // Igbo language locale for Nigeria
    "ik",   // Inupiat
    "iu",   // Inuktitut
    "is",   // Icelandic
    "iw",   // Hebrew, official code is he
    "ka",   // Georgian
    "kl",   // Kalaallisut
    "kok",  // Konkani language locale for India
    "ks",   // Kashmiri
    "kw",   // Cornish
    "ky",   // Kirghiz
    "la",   // Latin
    "lg",   // Igbo language locale for Nigeria
    "li",   // Limburgan
    "lt",   // Lithuanian
    "lv",   // Latvian
    "mk",   // Macedonian
    "mi",   // Maori
    "mt",   // Maltese
    "nan",  // Minnan Language Locale for Taiwan
    "nds",  // Low(lands) Saxon Language Locale for Germany
    "nso",  // Northern Sotho locale for South Africa
    "nr",   // Ndebele, South
    "oc",   // Occitan
    "or",   // Oriya
    "pap",  // Papiamento Language for the (Netherland) Antilles
    "POSIX",
    "ps",   // Pushto
    "rw",   // Kinyarwanda
    "sa",   // Sanskrit
    "sc",   // Sardinian
    "se",   // Northern Sami
    "shs",  // Secwepemctsin (Shuswap) language locale for Canada
    "si",   // Sindhi
    "sid",  // Sidama language locale for Ethiopia.
    "sl",   // Slovenian
    "so",   // Sotho
    "ss",   // Swati
    "st",   // Sotho, Southern
    "ti",   // Tigrinya
    "tig",  // Tigre language locale for Eritrea
    "tlh",  // Klingon language locale for Britain based on the English locale
    "tk",   // Turkmen
    "tn",   // Tswana
    "ts",   // Tsonga
    "tt",   // Tatar
    "ug",   // Uighur
    "ve",   // Venda locale for South Africa
    "wal",  // Sidama language locale for Ethiopia.
    "wo",   // Wolof
    "xh",   // Xhosa
    "yi",   // Yiddish
    "yo",   // Yoruba
    "zu",   // Zulu
  ]

  static Void main(Str[] args)
  {
    locFilename := args.size > 0 ? args[0] : "locales/"
    outDirName := args.size > 1 ? args[1] : "out2/"
    outDir := File(outDirName.toUri)
    if (outDir.exists) outDir.delete
    outDir.create

    top := File(locFilename.toUri)
    prefix := (top.isDir) ? top.pathStr : (top.parent?.pathStr ?: "")

    numFiles := 0
    done := Str[,]

    lmap := LMap()
    top.walk { if (!it.isDir) process(it, outDir, prefix, lmap) }
    lmap.transform.each |LDesc desc|
    {
      lcode := desc.lcode

      // skip uncommon languages
      if (skipLangs.contains(lcode.language))
      {
        // echo("SKIPPING: $lcode")
        return
      }

      // skip country specific derivations
      if (lcode.country.size > 0) return

      if (!desc.props.isEmpty)
      {
        done.add(lcode.language)
        writeProps((outDir + "${lcode.toStr}.props".toUri), desc.props)
        numFiles++
      }
    }

    done.sort.each |d| { echo(d) }
    echo("Wrote $numFiles files")
  }

  static Void writeProps(File f, Str:Str props)
  {
    keys := props.keys.sort |a, b| { writeOrder(a) <=> writeOrder(b) }
    out := f.out
    keys.each |k| { out.printLine(k + "=" + props[k]) }
    out.close
  }

  static Int writeOrder(Str key)
  {
    switch (key)
    {
      case "janFull": return 1_01
      case "febFull": return 1_02
      case "marFull": return 1_03
      case "aprFull": return 1_04
      case "mayFull": return 1_05
      case "junFull": return 1_06
      case "julFull": return 1_07
      case "augFull": return 1_08
      case "sepFull": return 1_09
      case "octFull": return 1_10
      case "novFull": return 1_11
      case "decFull": return 1_12

      case "janAbbr": return 2_01
      case "febAbbr": return 2_02
      case "marAbbr": return 2_03
      case "aprAbbr": return 2_04
      case "mayAbbr": return 2_05
      case "junAbbr": return 2_06
      case "julAbbr": return 2_07
      case "augAbbr": return 2_08
      case "sepAbbr": return 2_09
      case "octAbbr": return 2_10
      case "novAbbr": return 2_11
      case "decAbbr": return 2_12

      case "sunFull": return 3_01
      case "monFull": return 3_02
      case "tueFull": return 3_03
      case "wedFull": return 3_04
      case "thuFull": return 3_05
      case "friFull": return 3_06
      case "satFull": return 3_07

      case "sunAbbr": return 4_01
      case "monAbbr": return 4_02
      case "tueAbbr": return 4_03
      case "wedAbbr": return 4_04
      case "thuAbbr": return 4_05
      case "friAbbr": return 4_06
      case "satAbbr": return 4_07

      default:        return 0
    }
  }

  static Void process(File f, File baseOutDir, Str prefix, LMap lmap)
  {
    try
    {
      lcode := LCode(f.name)

      in := f.in
      in.charset = Charset.fromStr("iso-8859-1")
      lmap[lcode] = LDesc(lcode, VMap().load(in).transform)
    }
    catch (Err e)
    {
      echo("Error processing file $f.pathStr: $e.msg")
      //e.trace
    }
  }
}

class LMap
{
  private LCode:LDesc lmap := [:]
  @Operator
  Void set (LCode lcode, LDesc desc) { lmap[lcode] = desc }
  @Operator
  LDesc get (LCode lcode) { lmap[lcode] }

  LDesc[] transform()
  {
    LDesc[] nlmap := [,]
    Str:LDesc defMap := [:]
    groups := langGroups
    groups.keys.each |Str lang|
    {
      desc := getDefault(lang)
      defMap[lang] = desc
      nlmap.add(desc)
    }
    groups.each |LDesc[] d, Str lang|
    {
      d.each { nlmap.add(LDesc.makeDiff(it, defMap[lang])) }
    }
    return nlmap
  }

  private Str:LDesc[] langGroups()
  {
    Str:LDesc[] lg := [:]
    lmap.each |LDesc m, LCode l|
    {
      lg.getOrAdd(l.language) { [lmap[l]] }.add(lmap[l])
    }
    return lg
  }

  private LDesc getDefault(Str language)
  {
    l := LCode(language)
    m := lmap[l]
           ?: (lmap[LCode("${language}_${language.upper}")]
           ?: lmap.find() |LDesc m, LCode c -> Bool| { c.language == language })
    return LDesc(l, m.props)
  }
}

class Reader
{
  Int escapeChar := '\\'
  Int commentChar := '#'

  private InStream in

  new make(InStream in) { this.in = in }

  Str[] parseLine()
  {
    s := readLine
    while (s == "" || (s != null && s.startsWith("%")))
      s = readLine
    l := (s != null && !s.isEmpty) ? Regex<|\s|>.split(s, 2) : Str[,]
    return l.map { it.trim }
  }

  private Str decode(Str code)
  {
    n3 := code[0].fromDigit(16);
    n2 := code[1].fromDigit(16);
    n1 := code[2].fromDigit(16);
    n0 := code[3].fromDigit(16);
    return (n3.shiftl(12).or(n2.shiftl(8)).or(n1.shiftl(4)).or(n0)).toChar
  }

  private Str decodeLine(Str s)
  {
    m := Regex<|<U([0-9A-Fa-f]{4})>|>.matcher(s)
    buf := StrBuf(s.size)
    last := 0
    while (m.find)
    {
      buf.add(s[last..m.start-1]).add(decode(m.group(1)))
      last = m.end
    }
    buf.add(s[last..-1])

    return buf.toStr
  }

  private Str? readLine()
  {
    Int? c := in.readChar

    if (c == null)
      return null;

    if (c == commentChar)
    {
      while(c != null && c != '\n')
        c = in.readChar
      return ""
    }

    b := StrBuf()
    while (c != null && c != '\n')
    {
      if (c == escapeChar && in.peekChar == '\n')
        in.readChar
      else
        b.addChar(c)
      c = in.readChar
    }

    return decodeLine(b.toStr.trim).trim
  }
}

enum class DTokenType
{
  CONTROL,
  LITERAL,
  EOF
}

const class DToken
{
  const DTokenType type
  const Str val

  new make(DTokenType type, Str val)
  {
    this.type = type
    this.val = val
  }

  override Str toStr() { return val }
}

class DateTokenizer
{
  private InStream in

  new make(Str inStr)
  {
    //echo("inStr=$inStr");
    this.in = inStr.in
  }

  DToken[] tokenize()
  {
    dt := DToken[,]
    for (s := next; s.type != DTokenType.EOF; s = next)
      dt.add(s)
    return dt
  }

  private DToken readControl()
  {
    in.readChar
    c := in.readChar
    dashed := false
    while (c == '-' || c == '_' || c == 'O' || c == 'E')
    {
      // ignore localized conversion specifications %O? and %E?
      if (c == '-')
        dashed = true
      c = in.readChar
    }
    if (c == '%')
      return DToken(DTokenType.LITERAL, "%")
    if (c == null || (c < 'A' || c > 'Z') && (c < 'a' || c > 'z'))
      throw Err("Uknown control code '$c'.")

    return DToken(DTokenType.CONTROL, dashed ? "%-$c.toChar" : "%$c.toChar")
  }

  private DToken readLiteral()
  {
    b := StrBuf()
    c := in.readChar
    while(c != null && c != '%')
    {
      b.addChar(c)
      c = in.readChar
    }
    if (c != null) in.unreadChar(c)

    return DToken(DTokenType.LITERAL, b.toStr)
  }

  private DToken next()
  {
    switch(in.peekChar)
    {
      case '%':
        return readControl
      case '\n':
      case null:
        in.readChar
        return DToken(DTokenType.EOF, "")
      default:
        return readLiteral
    }
  }
}

enum class Section
{
  LC_IDENTIFICATION,
  LC_CTYPE,
  LC_COLLATE,
  LC_MONETARY,
  LC_NUMERIC,
  LC_TIME,
  LC_MESSAGES,
  LC_PAPER,
  LC_NAME,
  LC_ADDRESS,
  LC_TELEPHONE,
  LC_MEASUREMENT,
  NOSECTION
}

class VMap
{
  private [Str:Str] props := [:]
  private Section section
  private [Section:[Str:Str?]] vmap := [:]

  new make()
  {
    section = Section.NOSECTION
    props.ordered = true
  }

  This load(InStream in)
  {
    r := Reader(in)
    for (Str[] val := r.parseLine; !val.isEmpty; val = r.parseLine)
    {
      if (val.size == 2 && val[0] == "END")
        endSection(val[1])
      else
      {
        switch(section)
        {
          case Section.NOSECTION:
      if (val[0] == "escape_char") r.escapeChar = val[1][0]
      else if (val[0] == "comment_char") r.commentChar = val[1][0]
            else startSection(val[0])
          case Section.LC_MONETARY:
          case Section.LC_NUMERIC:
          case Section.LC_TIME:
            loadPair(val[0], val[1])
          default:
            // ignore
        }
      }
    }

    if (section != Section.NOSECTION)
      throw Err("Unended section $section")

    return this
  }

  Str:Str transform()
  {
    propTime("dateTime", Section.LC_TIME, "d_t_fmt")
    propTime("date", Section.LC_TIME, "d_fmt")
    propTime("time", Section.LC_TIME, "t_fmt")

    propNum("float")
    propNum("decimal")
    propNum("int")

    propEnum(Month.vals, "Abbr", "abmon")
    propEnum(Month.vals, "Full", "mon")

    propVal("weekdayStart", Section.LC_TIME, "first_weekday") |Str s -> Str|
    {
      m := Regex<|\s*([0-9]+)\s+|>.matcher(s)
      month := m.find ? Weekday.vals[Int.fromStr(m.group(1)) - 1] : Weekday.sun
      return month.toStr
    }

    propEnum(Weekday.vals, "Abbr", "abday")
    propEnum(Weekday.vals, "Full", "day")

    return props.ro
  }

  private Void startSection(Str sectionId) { section = Section(sectionId) }

  private Void endSection(Str sectionId)
  {
    if (Section(sectionId) != section)
      throw Err("Missing END section for $section")
    section = Section.NOSECTION
  }

  private Void loadPair(Str key, Str val)
  {
    if (vmap[section] == null)
      vmap[section] = [Str:Str?][:]
    vmap[section][key] = val
  }

  private Str getVal(Section section, Str key)
  {
    return vmap[section]?.get(key) ?: ""
  }

  private Str dequote(Str val)
  {
    return (val.size > 2 && val[0] == '"' && val[-1] == '"') ? val[1..-2] : val
  }

  private Void propTime(Str key, Section section, Str cval, |Str -> Str|? f := null)
  {
    val := remap(section, cval)
    if (!val.isEmpty)
      props[key] = (f != null) ? f(val) : val
  }

  private Void propVal(Str key, Section section, Str cval, |Str -> Str|? f := null)
  {
    val := getVal(section, cval)
    if (!val.isEmpty)
      props[key] = (f != null) ? f(val) : val
  }

  private Void propEnum(Enum[] vals, Str postfix, Str cname)
  {
    s := getVal(Section.LC_TIME, cname)
    if (!s.isEmpty)
    {
      abmon := s.split(';').map { dequote(it) }
      vals.map { it.name + postfix }.each |Str key, Int i|
      {
        props[key] = abmon[i]
      }
    }
  }

  // date(1) -> Fantom locale  (date_fmt default)
  private [Str:Str?] dmap :=
    ["%a":"WWW",    // abbr weekday [abday]
    "%A":"WWWW",    // full weekday [day]
    "%b":"MMM",   // abbr month name [abmon]
    "%B":"MMMM",    // full month name [mon]
    "%c":"@d_t_fmt",    // locale long date and time (d_t_fmt)
    "%C":null,          // decimal century, year/100, zero lpadded
    "%d":"DD",          // day of month
    "%-d":"D",          // one/two day of month
    "%D":"MM/DD/YY",  // en date
    "%e":"D",         // day of month, space padded
    "%-e":"D",          // day of month
    "%F":"YYYY-MM-DD",  // full en date
    "%g":null,    // two digit week of year of %V
    "%G":null,    // four digit year of %V
    "%h":"MMM",         // same as %b
    "%H":"hh",          // 24 hour, 0-23
    "%-H":"h",          // 24 hour, 0-23
    "%k":"h",         // 24 hour, 0-23
    "%-k":"h",          // 24 hour, 0-23
    "%I":"kk",          // 12 hour, 1-12
    "%-I":"k",          // 12 hour, 1-12
    "%l":"k",         // 12 hour, 1-12
    "%-l":"k",          // 12 hour, 1-12
    "%m":"MM",          // two digit month
    "%-m":"M",          // one/two digit month
    "%M":"mm",          // two digit minute
    "%-M":"m",          // one/two digit minute
    "%n":"'\n'",        // newline
    "%N":null,          // nanoseconds
    "%p":"aa",      // lowercase am,pm [am_pm]
    "%P":"AA",      // upppercase AM,PM [am_pm]
    "%r":"@t_fmt_ampm", // time, 12-hour (t_fmt_ampm)
    "%R":"hh:mm", // time, 24-hour
    "%s":null,    // seconds since 1970
    "%S":"ss",    // seconds
    "%-S":"s",    // one/two digit seconds
    "%t":"'\t'",  // horizontal tab
    "%T":"hh:mm:ss",// time, 24-hour
    "%u":null,    // week day number (1..7)
    "%U":null,    // week number of year, sunday
    "%V":null,    // week number of year, monday
    "%w":null,    // day of week number variant
    "%W":null,    // week number of year variant
    "%x":"@d_fmt",  // date (d_fmt)
    "%X":"@t_fmt",  // time (t_fmt)
    "%y":"YY",    // two digit year
    "%Y":"YYYY",  // four digit year
    "%z":"z",   // timezone offset
    "%Z":"zzz"]   // abbr timezone

  private Str remap(Section section, Str cval)
  {
    input := dequote(getVal(section, cval))
    return DateTokenizer(input).tokenize.map |DToken token -> Str|
    {
      Str? val
      if (token.type == DTokenType.CONTROL)
      {
        val = dmap[token.val]
        if (val != null && val.startsWith("@"))
          val = remap(section, val[1..-1])
      }
      else if (Regex<|[A-Za-z]+|>.matches(token.val))
        val = "'$token.val'"
      else
        val = token.val

      if (val == null)
        throw Err("Can't map token $token.val")

      return val
    }.join("").trim
  }

  //FIXME! fantom formatting ignores 2nd+ grouping
  private const [Str:Str] gmap :=
  ["0;0":"#.0##",
    "-1":"#.0##",
    "2;3":"#,###,##.0##",
    "3":"#,###.0##",
    "3;2":"##,##,###.0##",
    "3;2;":"#,##,###.0##",
    "3;3":"#,###,###.0##"]

  private Void propNum(Str key)
  {
    grouping := getVal(Section.LC_NUMERIC, "grouping")
    if (!grouping.isEmpty)
    {
      formatting := gmap[grouping]
      if (formatting == null)
  throw Err("Can't map formatting for grouping $grouping")
      if (key == "int")
  formatting = formatting[0..<formatting.index(".")]
      props[key] = formatting
    }
  }
}

class LDesc
{
  LCode lcode
  Str:Str props

  new make(LCode lcode, Str:Str props)
  {
    this.lcode = lcode
    this.props = props.dup
  }

  new makeDiff(LDesc desc, LDesc def)
  {
    this.lcode = desc.lcode
    props = [:]
    desc.props.each |Str v, Str k|
    {
      if (v != def.props[k])
        props[k] = v
    }
  }
}

const class LCode
{
  const Str language
  const Str country := ""
  const Str modifier := ""

  new make(Str id)
  {
    if (id.index("_") == null)
    {
      language = id
      return
    }

    m := Regex<|([a-z0-9]*)_([A-Z0-9]*)\.*([^@]*)@*(.*)|>.matcher(id)
    if (!m.find)
      throw Err("Can't parse locale '$id'")

    language = m.group(1)
    country = m.group(2)
    modifier = m.group(4)
  }

  override Str toStr()
  {
    r := language
    if (country != "")
    {
      r += "-$country"
      if (modifier != "")
        r += "@$modifier"
    }
    return r
  }

  override Bool equals(Obj? that)
  {
    if (that == null) return false
    if (that.typeof == this.typeof)
    {
      t := (LCode) that
      return this.language == t.language
        && this.country == t.country
        && this.modifier == t.modifier
    }
    return false
  }

  override Int hash()
  {
    return language.hash + 100 * country.hash
  }
}