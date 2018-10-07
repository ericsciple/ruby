require_relative '../fixtures/classes'

platform_is :windows do
  require 'win32ole'

  describe "WIN32OLE#ole_methods" do
    before :all do
      @ie = WIN32OLESpecs.new_ole('InternetExplorer.Application')
    end

    after :all do
      @ie.Quit
      @ie = nil
    end

    it "raises ArgumentError if argument is given" do
      begin
        @ie.ole_methods(1)
      rescue => e
        e.should be_an_instance_of ArgumentError
      end
    end

    it "returns an array of WIN32OLE_METHODs" do
      @ie.ole_methods.all? { |m| m.kind_of? WIN32OLE_METHOD }.should be_true
    end

    it "contains a 'AddRef' method for Internet Explorer" do
      @ie.ole_methods.map { |m| m.name }.include?('AddRef').should be_true
    end
  end
end
