require 'mspec/expectations/expectations'
require_relative 'dotted'

class YamlFormatter < DottedFormatter
  def initialize(out=nil)
    super(nil)
    @examples_last = 0
    @finish = out.nil? ? $stdout : File.open(out, "w")
  end

  def register
    super
    MSpec.register :unload, self
  end

  def switch
    @out = @finish
  end

  def after(state) ; end

  def unload
    file_examples = @tally.counter.examples - @examples_last
    @examples_last = @tally.counter.examples
    ::STDOUT.write ".#{file_examples}"
  end

  def finish
    switch

    print "---\n"
    print "exceptions:\n"
    @exceptions.each do |exc|
      outcome = exc.failure? ? "FAILED" : "ERROR"
      str =  "#{exc.description} #{outcome}\n"
      str << exc.message << "\n" << exc.backtrace
      print "- ", str.inspect, "\n"
    end

    print "time: ",         @timer.elapsed,              "\n"
    print "files: ",        @tally.counter.files,        "\n"
    print "examples: ",     @tally.counter.examples,     "\n"
    print "expectations: ", @tally.counter.expectations, "\n"
    print "failures: ",     @tally.counter.failures,     "\n"
    print "errors: ",       @tally.counter.errors,       "\n"
    print "tagged: ",       @tally.counter.tagged,       "\n"
  end
end
