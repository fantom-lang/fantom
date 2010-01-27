**
** Split a text file up into words and count occurences using:
**   - File IO
**   - String split
**   - Maps
**
class Wordcount
{
  static Void main(Str[] args)
  {
    if (args.size != 1)
    {
      echo("usage: Wordcount <file>")
      Env.cur.exit(-1)
    }

    // Set up our map to count each word, and set its default to zero
    wordCounts := Str:Int[:] { def = 0 }

    // Open the file, read each line in order
    file := Uri(args[0]).toFile
    file.eachLine |line|
    {
      // skip empty lines
      if (line.trim.isEmpty) return

      // split and trim on whitespace into words
      words := line.split

      // count each one
      words.each |word| { wordCounts[word] += 1 }
    }

    // Show each word found, with its count, in alphabetical order
    wordCounts.keys.sort.each |key|
    {
      echo("$key ${wordCounts[key]}")
    }
  }
}