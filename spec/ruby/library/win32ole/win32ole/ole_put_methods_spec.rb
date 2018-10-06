require_relative '../fixtures/classes'

platform_is :windows do
  require 'win32ole'

  describe "WIN32OLE#ole_put_methods" do
    before :all do
      @ie = WIN32OLESpecs.new_ole('InternetExplorer.Application')
    end

    after :all do
      @ie.Quit
      @ie = nil
    end

    it "raises ArgumentError if argument is given" do
      lambda { @ie.ole_put_methods(1) }.should raise_error ArgumentError
    end

    it "returns an array of WIN32OLE_METHODs" do
      @ie.ole_put_methods.all? { |m| m.kind_of? WIN32OLE_METHOD }.should be_true
    end

    it "contains a 'Height' method for Internet Explorer" do
      @ie.ole_put_methods.map { |m| m.name }.include?('Height').should be_true
    end
  end
end
