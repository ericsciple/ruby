# frozen_string_literal: true

# Creates a temporary directory in the current working directory
# (or the Windows temp directory) for temporary files created while
# running the specs. All specs should clean up any temporary files
# created so that the temp directory is empty when the process exits.

if /mswin|mingw/ =~ RUBY_PLATFORM
  temp_dir = ENV['TMPDIR'] || ENV['TEMP'] || ENV['TMP']
  if temp_dir and (temp_dir = temp_dir.dup.gsub("\\", "/")) and Dir.exist?(temp_dir)
    SPEC_TEMP_DIR = File.expand_path(ENV["SPEC_TEMP_DIR"] || "rubyspec_temp", temp_dir)
  else
    SPEC_TEMP_DIR = File.expand_path(ENV["SPEC_TEMP_DIR"] || "rubyspec_temp")
  end
else
  SPEC_TEMP_DIR = File.expand_path(ENV["SPEC_TEMP_DIR"] || "rubyspec_temp")
end

SPEC_TEMP_UNIQUIFIER = "0".dup

SPEC_TEMP_DIR_PID = Process.pid

at_exit do
  begin
    if SPEC_TEMP_DIR_PID == Process.pid
      Dir.delete SPEC_TEMP_DIR if File.directory? SPEC_TEMP_DIR
    end
  rescue SystemCallError
    STDERR.puts <<-EOM

-----------------------------------------------------
The rubyspec temp directory is not empty. Ensure that
all specs are cleaning up temporary files:
  #{SPEC_TEMP_DIR}
-----------------------------------------------------

    EOM
  rescue Object => e
    STDERR.puts "failed to remove spec temp directory"
    STDERR.puts e.message
  end
end

def tmp(name, uniquify=true)
  Dir.mkdir SPEC_TEMP_DIR unless Dir.exist? SPEC_TEMP_DIR

  if uniquify and !name.empty?
    slash = name.rindex "/"
    index = slash ? slash + 1 : 0
    name.insert index, "#{SPEC_TEMP_UNIQUIFIER.succ!}-"
  end

  File.join SPEC_TEMP_DIR, name
end
