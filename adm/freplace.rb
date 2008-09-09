#
# file replace
#
# @author   Brian Frank
# @creation 4 Jan 06
#

class FReplace

  # process
  def process(f)
    puts "-- " + f
    oldlines = File.open(f).readlines
    changed = false
    #puts oldlines
    newlines = oldlines.collect do |oldline| 
      newline = oldline.gsub(@from, @to)
      if (oldline != newline) then
        puts newline 
        changed = true
      end
      newline
    end
    if changed then
      File.open(f, "w") { |f| f.write(newlines) }
    end
  end

  # main
  def main()
    # get args
    @from, @to, dir, ext = ARGV[0..3]    
    if (ext == nil)
      puts "usage <from> <to> <dir> <ext>"
      return
    end
    
    # process each dir
    files = Dir.glob(dir+"/**/*." + ext)
    files.each { |f| process(f) }
  end


end

# script
FReplace.new.main