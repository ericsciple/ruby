require_relative '../fixtures/classes'

platform_is :windows do
  require 'win32ole'

  describe "WIN32OLE#_getproperty" do
    before :all do
      @ie = WIN32OLESpecs.new_ole('InternetExplorer.Application')
    end

    after :all do
      @ie.Quit
      @ie = nil
    end

    it "gets name" do
      @ie._getproperty(0, [], []).should =~ /explorer/i
    end
  end
end
