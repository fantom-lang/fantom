//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jun 06  Brian Frank  Creation
//

**
** Uri is used to immutably represent a Universal Resource Identifier
** according to [RFC 3986]`http://tools.ietf.org/html/rfc3986`.
** The generic format for a URI is:
**
**   <uri>        := [<scheme> ":"] <body>
**   <body>       := ["//" <auth>] ["/" <path>] ["?" <query>] ["#" <frag>]
**   <auth>       := [<userInfo> "@"] <host> [":" <port>]
**   <path>       := <name> ("/" <name>)*
**   <name>       := <basename> ["." <ext>]
**   <query>      := <queryPair> (<querySep> <queryPair>)*
**   <querySep>   := "&" | ";"
**   <queryPair>  := <queryKey> ["=" <queryVal>]
**   <gen-delims> := ":" / "/" / "?" / "#" / "[" / "]" / "@"
**
** Uris are expressed in the following forms:
**   - Standard Form: any char allowed, general delimiters are "\" escaped
**   - Encoded Form: '%HH' percent encoded
**
** In standard form the full range of Unicode characters is allowed in all
** sections except the general delimiters which separate sections.  For
** example '?' is barred in any section before the query, but is permissible
** in the query string itself or the fragment identifier.  The scheme must
** be strictly defined in terms of ASCII alphanumeric, ".", "+", or "-".
** Any general delimiter used outside of its normal role, must be
** escaped using the "\" backslash character.  The backslash itself is
** escaped as "\\".  For example a filename with the "#" character is
** represented as "file \#2".  Only the path, query, and fragment sections
** can use escaped general delimiters; the scheme and authority sections
** cannot use escaped general delimters.
**
** Encoded form as defined by RFC 3986 uses a stricter set of rules for
** the characters allowed in each section of the URI (scheme, userInfo,
** host, path, query, and fragment).  Any character outside of the
** allowed set is UTF-8 encoded into octets and '%HH' percent encoded.
** The encoded form should be used when working with external applications
** such as HTTP, HTML, or XML.
**
** The Uri API is designed to work with the standard form of the Uri.
** Access methods like `host`, `pathStr`, or `queryStr` all use standard
** form.  To summarize different ways of working with Uri:
**   - `Uri.fromStr`:  parses a string from its standard form
**   - `Uri.toStr`:    returns the standard form
**   - `Uri.decode`:   parses a string from percent encoded form
**   - `Uri.encode`:   translate into percent encoded form
**
** Uri can be used to model either absolute URIs or relative references.
** The `plus` and `relTo` methods can be used to resolve and relativize
** relative references against a base URI.
**
@Serializable { simple = true }
const final class Uri
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the specified string into a Uri.  If invalid format
  ** and checked is false return null,  otherwise throw ParseErr.
  ** a standard form Unicode string into its generic parts.
  ** It does not unescape '%' or '+' and handles normal Unicode
  ** characters in the string.  If general delimiters such
  ** as the "?" or "#" characters are used outside their normal
  ** role, then they must be backslash escaped.
  **
  ** All Uris are automatically normalized as follows:
  **   - Replacing "." and ".." segments in the middle of a path
  **   - Scheme always normalizes to lowercase
  **   - If http then port 80 normalizes to null
  **   - If http then a null path normalizes to /
  **
  static Uri? fromStr(Str s, Bool checked := true)

  **
  ** Parse an ASCII percent encoded string into a Uri according to
  ** RFC 3986.  All '%HH' escape sequences are translated into octects,
  ** and then the octect sequence is UTF-8 decoded into a Str.  The '+'
  ** character in the query section is unescaped into a space.  If
  ** checked if true then throw ParseErr if the string is a malformed
  ** URI or if not encoded correctly, otherwise return null. Refer
  ** to `fromStr` for normalization rules.
  **
  static Uri? decode(Str s, Bool checked := true)

  **
  ** Default value is '``'.
  **
  static const Uri defVal

  **
  ** Private constructor
  **
  private new privateMake()

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Decode a map of query parameters which are URL encoded according
  ** to the "application/x-www-form-urlencoded" MIME type.  This method
  ** will unescape '%' percent encoding and '+' into space.  The parameters
  ** are parsed into map using the same semantics as `Uri.query`.  Throw
  ** ArgErr is the string is malformed.  See `encodeQuery`.
  **
  static Str:Str decodeQuery(Str s)

  **
  ** Encode a map of query parameters into URL percent encoding
  ** according to the "application/x-www-form-urlencoded" MIME type.
  ** See `decodeQuery`.
  **
  static Str encodeQuery(Str:Str q)

  **
  ** Return if the specified string is an valid name segment to
  ** use in an unencoded URI.  The name must be at least one char
  ** long and can never be "." or "..".  The legal characters are
  ** defined by as follows from RFC 3986:
  **
  **   unreserved  =  ALPHA / DIGIT / "-" / "." / "_" / "~"
  **   ALPHA       =  %x41-5A / %x61-7A   ; A-Z / a-z
  **   DIGIT       =  %x30-39 ; 0-9
  **
  ** Although RFC 3986 does allow path segments to contain other
  ** special characters such as 'sub-delims', Fantom takes a strict
  ** approach to names to be used in URIs.
  **
  static Bool isName(Str name)

  **
  ** If the specified string is not a valid name according
  ** to the `isName` method, then throw `NameErr`.
  **
  static Void checkName(Str name)

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Two Uris are equal if they have same string normalized representation.
  **
  override Bool equals(Obj? that)

  **
  ** Return a hash code based on the normalized string representation.
  **
  override Int hash()

  **
  ** Return normalized string representation.
  **
  override Str toStr()

  **
  ** Return `toStr`.  This method is used to enable 'toLocale' to
  ** be used with duck typing across most built-in types.
  **
  Str toLocale()

  **
  ** Return the percent encoded string for this Uri according to
  ** RFC 3986.  Each section of the Uri is UTF-8 encoded into octects
  ** and then percent encoded according to its valid character set.
  ** Spaces in the query section are encoded as '+'.
  **
  Str encode()

//////////////////////////////////////////////////////////////////////////
// Components
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if an absolute Uri which means it has a non-null scheme.
  **
  Bool isAbs()

  **
  ** Return if a relative Uri which means it has a null scheme.
  **
  Bool isRel()

  **
  ** A Uri represents a directory if it has a non-null path which
  ** ends with a "/" slash.  Directories are joined with other Uris
  ** relative to themselves versus non-directories which are joined
  ** relative to their parent.
  **
  ** Examples:
  **   `/a/b`.isDir   =>  false
  **   `/a/b/`.isDir  =>  true
  **   `/a/?q`.isDir  =>  true
  **
  Bool isDir()

  **
  ** Return the scheme component or null if not absolute.  The
  ** scheme is always normalized into lowercase.
  **
  ** Examples:
  **   `http://foo/a/b/c`.scheme      =>  "http"
  **   `HTTP://foo/a/b/c`.scheme      =>  "http"
  **   `mailto:who@there.com`.scheme  =>  "mailto"
  **
  Str? scheme()

  **
  ** The authority represents a network endpoint in the format:
  **   [<userInfo> "@"] host [":" <port>]
  **
  ** Examples:
  **   `http://user@host:99/`.auth  =>  "user@host:99"
  **   `http://host/`.auth          =>  "host"
  **   `/dir/file.txt`.auth         =>  null
  **
  Str? auth()

  **
  ** Return the host address of the URI or null if not available.  The
  ** host is in the format of a DNS name, IPv4 address, or IPv6 address
  ** surrounded by square brackets.  Return null if the uri is not
  ** absolute.
  **
  ** Examples:
  **   `ftp://there:78/file`.host            =>  "there"
  **   `http://www.cool.com/`.host           =>  "www.cool.com"
  **   `http://user@10.162.255.4/index`.host =>  "10.162.255.4"
  **   `http://[::192.9.5.5]/`.host          =>  "[::192.9.5.5]"
  **   `//foo/bar`.host                      =>  "foo"
  **   `/bar`.host                           =>  null
  **
  Str? host()

  **
  ** User info is string information embedded in the authority using
  ** the "@" character.  Its use is discouraged for security reasons.
  **
  ** Examples:
  **   `http://brian:pass@host/`.userInfo  =>  "brian:pass"
  **   `http://www.cool.com/`.userInfo     =>  null
  **
  Str? userInfo()

  **
  ** Return the IP port of the host for the network end point.  It is optionally
  ** embedded in the authority using the ":" character.  If unspecified then
  ** return null.
  **
  ** Examples:
  **   `http://foo:81/`.port        =>  81
  **   `http://www.cool.com/`.port  =>  null
  **
  Int? port()

  **
  ** Return the path parsed into a list of simple names or
  ** an empty list if the pathStr is "" or "/".  Any general
  ** delimiters in the path such "?" or "#" are backslash
  ** escaped.
  **
  ** Examples:
  **   `mailto:me@there.com`  =>  ["me@there.com"]
  **   `http://host`.path     =>  Str[,]
  **   `http://foo/`.path     =>  Str[,]
  **   `/`.path               =>  Str[,]
  **   `/a`.path              =>  ["a"]
  **   `/a/b`.path            =>  ["a", "b"]
  **   `../a/b`.path          =>  ["..", "a", "b"]
  **
  Str[] path()

  **
  ** Return the path component of the Uri.  Any general
  ** delimiters in the path such "?" or "#" are backslash
  ** escaped.
  **
  ** Examples:
  **   `mailto:me@there.com`  =>  "me@there.com"
  **   `http://host`          =>  ""
  **   `http://foo/`.pathStr  =>  "/"
  **   `/a`.pathStr           =>  "/a"
  **   `/a/b`.pathStr         =>  "/a/b"
  **   `../a/b`.pathStr       =>  "../a/b"
  **
  Str pathStr()

  **
  ** Return if the path starts with a leading slash.  If
  ** pathStr is null, then return false.
  **
  ** Examples:
  **   `http://foo/`.isPathAbs    =>  true
  **   `/dir/f.txt`.isPathAbs     =>  true
  **   `dir/f.txt`.isPathAbs      =>  false
  **   `../index.html`.isPathAbs  =>  false
  **
  Bool isPathAbs()

  **
  ** Return if this Uri contains only a path component.  The
  ** authority (scheme, host, port), query, and fragment must
  ** be null.
  **
  Bool isPathOnly()

  **
  ** Return simple file name which is path.last or ""
  ** if the path is empty.
  **
  ** Examples:
  **   `/`.name            =>  ""
  **   `/a/file.txt`.name  =>  "file.txt"
  **   `/a/file`.name      =>  "file"
  **   `somedir/`.name     =>  "somedir"
  **
  Str name()

  **
  ** Return file name without the extension (everything up
  ** to the last dot) or "" if name is "".
  **
  ** Examples:
  **   `/`.basename            =>  ""
  **   `/a/file.txt`.basename  =>  "file"
  **   `/a/file`.basename      =>  "file"
  **   `/a/file.`.basename     =>  "file"
  **   `..`.basename           =>  ".."
  **
  Str basename()

  **
  ** Return file name extension (everything after the last dot)
  ** or null if name is null or name has no dot.
  **
  ** Examples:
  **   `/`.ext            =>  null
  **   `/a/file.txt`.ext  =>  "txt"
  **   `/Foo.Bar`.ext     =>  "Bar"
  **   `/a/file`.ext      =>  null
  **   `/a/file.`.ext     =>  ""
  **   `..`.ext           =>  null
  **
  Str? ext()

  **
  ** Return the MimeType mapped by the `ext` or null if
  ** no mapping.  If this uri is to a directory, then
  ** "x-directory/normal" is returned.
  **
  ** Examples:
  **   `file.txt`  =>  text/plain
  **   `somefile`  =>  null
  **
  MimeType? mimeType()

  **
  ** Return the query parsed as a map of key/value pairs.  If no query
  ** string was specified return an empty map (this method will never
  ** return null).  The query is parsed such that pairs are separated by
  ** the "&" or ";" characters.  If a pair contains the "=", then
  ** it is split into a key and value, otherwise the value defaults
  ** to "true".  If delimiters such as "&", "=", or ";" are in the
  ** keys or values, then they are *not* escaped.  If duplicate keys
  ** are detected, then the values are concatenated together with a
  ** comma.
  **
  ** Examples:
  **   `http://host/path?query`.query  =>  ["query":"true"]
  **   `http://host/path`.query        =>  [:]
  **   `?a=b;c=d`.query                =>  ["a":"b", "c":"d"]
  **   `?a=b&c=d`.query                =>  ["a":"b", "c":"d"]
  **   `?a=b;;c=d;`.query              =>  ["a":"b", "c":"d"]
  **   `?a=b;;c`.query                 =>  ["a":"b", "c":"true"]
  **   `?x=1&x=2&x=3`.query            =>  ["x":"1,2,3"]
  **
  Str:Str query()

  **
  ** Return the query component of the Uri which is everything
  ** after the "?" but before the "#" fragment.  Return null if
  ** no query string specified.  Any delimiters used in keys
  ** or values such as "&", "=", or ";" are backslash escaped.
  **
  ** Examples:
  **   `http://host/path?query#frag`.queryStr =>  "query"
  **   `http://host/path?query`.queryStr      =>  "query"
  **   `http://host/path`.queryStr            =>  null
  **   `../foo?a=b&c=d`.queryStr              =>  "a=b&c=d"
  **   `?a=b;c;`.queryStr                     =>  "a=b;c;"
  **
  Str? queryStr()

  **
  ** Return the fragment component of the Uri which is everything
  ** after the "#".  Return null if no fragment specified.
  **
  ** Examples:
  **   `http://host/path?query#frag`.frag  =>  "frag"
  **   `http://host/path`                  =>  null
  **   `#h1`                               =>  "h1"
  **
  Str? frag()

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the parent directory of this Uri or null if a parent
  ** path cannot be computed from this Uri.  If the path is not
  ** empty, then this method is equivalent to 'slice(0..-2)'.
  **
  ** Examples:
  **   `http://foo/a/b/c?q#f`.parent  =>  `http://foo/a/b/`
  **   `/a/b/c/`.parent  =>  `/a/b/`)
  **   `a/b/c`.parent    =>  `a/b/`
  **   `/a`.parent       =>   `/`
  **   `/`.parent        =>   null
  **   `a.txt`.parent    =>   null
  **
  Uri? parent()

  **
  ** Return a new Uri with only a path part.  If this Uri has
  ** an authority, fragment, or query they are stripped off.
  **
  ** Examples:
  **   `http://host/a/b/c?query`.pathOnly =>  `/a/b/c`
  **   `http://host/a/b/c/`.pathOnly      =>  `/a/b/c/`
  **   `/a/b/c`.pathOnly                  =>  `/a/b/c`
  **   `file.txt`.pathOnly                =>  `file.txt`
  **
  Uri pathOnly()

  **
  ** Return a new Uri based on a slice of this Uri's path.  If the
  ** range starts at zero, then the authority is included otherwise
  ** it is stripped and the result is not path absolute.  If the
  ** range includes the last name in the path, then the query and
  ** fragment are included otherwise they are stripped and the result
  ** includes a trailing slash.  The range can include negative indices
  ** to access from the end of the path.  Also see `pathOnly` to create
  ** a slice without the authority, query, or fragment.
  **
  ** Examples:
  **   `http://host/a/b/c?q`[0..-1]  =>  `http://host/a/b/c?q`
  **   `http://host/a/b/c?q`[0..-2]  =>  `http://host/a/b/`
  **   `http://host/a/b/c?q`[0..-3]  =>  `http://host/a/`
  **   `http://host/a/b/c?q`[0..-4]  =>  `http://host/`
  **   `http://host/a/b/c?q`[1..-1]  =>  `b/c?q`
  **   `http://host/a/b/c?q`[2..-1]  =>  `c?q`
  **   `http://host/a/b/c?q`[3..-1]  =>  `?q`
  **   `/a/b/c/`[0..1]               =>  `/a/b/`
  **   `/a/b/c/`[0..0]               =>  `/a/`
  **   `/a/b/c/`[1..2]               =>  `b/c/`
  **   `/a/b/c/`[1..<2]              =>  `b/`
  **   `/a`[0..-2]                   =>  `/`
  **
  @Operator Uri getRange(Range r)

  ** TODO: use `getRange`
  @Deprecated Uri slice(Range r)

  **
  ** Return a slice of this Uri's path using the same semantics
  ** as `slice`.  However this method ensures that the result has
  ** a leading slash in the path such that `isPathAbs` returns true.
  **
  ** Examples:
  **   `/a/b/c/`.getRangeToPathAbs(0..1)  =>  `/a/b/`
  **   `/a/b/c/`.getRangeToPathAbs(1..2)  =>  `/b/c/`
  **   `/a/b/c/`.getRangeToPathAbs(1..<2) =>  `/b/`
  **
  Uri getRangeToPathAbs(Range r)

  ** TODO: use `getRangeToPathAbs`
  @Deprecated Uri sliceToPathAbs(Range r)

  **
  ** Return a new Uri with the specified Uri appended to this Uri.
  **
  ** Examples:
  **   `http://foo/path` + `http://bar/`  =>  `http://bar/`
  **   `http://foo/path?q#f` + `newpath`  =>  `http://foo/newpath`
  **   `http://foo/path/?q#f` + `newpath` =>  `http://foo/path/newpath`
  **   `a/b/c`  + `d`                     =>  `a/b/d`
  **   `a/b/c/` + `d`                     =>  `a/b/c/d`
  **   `a/b/c`  + `../../d`               =>  `d`
  **   `a/b/c/` + `../../d`               =>  `a/d`
  **   `a/b/c`  + `../../../d`            =>  `../d`
  **   `a/b/c/` + `../../../d`            =>  `d`
  **
  @Operator Uri plus(Uri toAppend)

  **
  ** Return a new Uri with a single path name appended to this
  ** Uri.  If asDir is true, then add a trailing slash to the Uri
  ** to make it a directory Uri.  This method is potentially
  ** much more efficient than using `plus` when appending a
  ** single name.
  **
  ** Examples:
  **   `dir/`.plusName("foo")        =>  `dir/foo`
  **   `dir/`.plusName("foo", true)  =>  `dir/foo/`
  **   `/dir/file`.plusName("foo")   =>  `/dir/foo`
  **   `/dir/#frag`.plusName("foo")  =>  `/dir/foo`
  **
  Uri plusName(Str name, Bool asDir := false)

  **
  ** Add a trailing slash to the path string of this Uri
  ** to make it a directory Uri.
  **
  ** Examples
  **   `http://h/dir`.plusSlash  => `http://h/dir/`
  **   `/a`.plusSlash            =>  `/a/`
  **   `/a/`.plusSlash           =>  `/a/`
  **   `/a/b`.plusSlash          =>  `/a/b/`
  **   `/a?q`.plusSlash          =>  `/a/?q`
  **
  Uri plusSlash()

  **
  ** Add the specified query key/value pairs to this Uri.
  ** If this uri has an existing query, then it is merged
  ** with the given query.  The key/value pairs should not
  ** be backslash escaped or percent encoded.  If the query
  ** param is null or empty, return this instance.
  **
  ** Examples:
  **   `http://h/`.plusQuery(["k":"v"])         =>  `http://h/?k=v`
  **   `http://h/?k=old`.plusQuery(["k":"v"])   =>  `http://h/?k=v`
  **   `/foo?a=b`.plusQuery(["k":"v"])          =>  `/foo?a=b&k=v`
  **   `?a=b`.plusQuery(["k1":"v1", "k2":"v2"]) =>  `?a=b&k1=v1&k2=v2`
  **
  Uri plusQuery([Str:Str]? query)

  **
  ** Relativize this uri against the specified base.
  **
  ** Examples:
  **   `http://foo/a/b/c`.relTo(`http://foo/a/b/c`) => ``
  **   `http://foo/a/b/c`.relTo(`http://foo/a/b`)   => `c`
  **   `/a/b/c`.relTo(`/a`)                         => `b/c`
  **   `a/b/c`.relTo(`/a`)                          => `b/c`
  **   `/a/b/c?q`.relTo(`/`)                        => `a/b/c?q`
  **   `/a/x`.relTo(`/a/b/c`)                       => `../x`
  **
  Uri relTo(Uri base)

  **
  ** Relativize this uri against its authority.  This method
  ** strips the authority if present and keeps the path, query,
  ** and fragment segments.
  **
  ** Examples:
  **   `http://host/a/b/c?q#frag`.relToAuth  => `/a/b/c?q#frag`
  **   `http://host/a/b/c`.relToAuth         => `/a/b/c`
  **   `http://user@host/index`.relToAuth    => `/index`
  **   `mailto:bob@bob.net`.relToAuth        => `bob@bob.net`
  **   `/a/b/c/`.relToAuth                   => `/a/b/c/`
  **   `logo.png`.relToAuth                  => `logo.png`
  **
  Uri relToAuth()

//////////////////////////////////////////////////////////////////////////
// Resolution
//////////////////////////////////////////////////////////////////////////

  **
  ** Convenience for File.make(this) - no guarantee is made
  ** that the file exists.
  **
  File toFile()

  **
  ** Resolve this Uri into an Fantom object.
  ** See [docLang]`docLang::Naming#resolving` for the resolve process.
  **
  Obj? get(Obj? base := null, Bool checked := true)

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  **
  ** Get this Uri as a Fantom code literal.  This method will
  ** escape the "$" interpolation character.
  **
  Str toCode()

}