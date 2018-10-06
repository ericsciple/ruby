require_relative '../../fixtures/classes'

platform_is :windows do
  require 'win32ole'

  describe :win32ole_setproperty, shared: true do
    before :all do
      @ie = WIN32OLESpecs.new_ole('InternetExplorer.Application')
    end

    after :all do
      @ie.Quit
      @ie = nil
    end

    it "raises ArgumentError if no argument is given" do
      lambda { @ie.send(@method) }.should raise_error ArgumentError
    end

    it "sets height to 500 and returns nil" do
      height = 500
      result = @ie.send(@method, 'Height', height)
      result.should == nil
    end
  end
end
