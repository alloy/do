require File.dirname(__FILE__) + '/spec_helper'

describe DataObjects::Connection do
  before do
    @connection = DataObjects::Connection.new('mock://localhost')
  end 

  %w{acquire release}.each do |meth|
    it "should respond to class method ##{meth}" do 
      DataObjects::Connection.should respond_to(meth.intern)
    end
  end
  
  %w{begin_transaction real_close create_command}.each do |meth|
    it "should respond to ##{meth}" do 
      @connection.should respond_to(meth.intern)
    end
  end

  it "should have #to_s that returns the connection uri string" do
    @connection.to_s.should == 'mock://localhost'
  end

  describe "getting inherited" do
    class MyConnection < DataObjects::Connection; end

    it "should set the @connection_lock ivar to a Mutex" do
      MyConnection.instance_variable_get("@connection_lock").should_not be_nil
      MyConnection.instance_variable_get("@connection_lock").should be_kind_of(Mutex)
    end

    it "should set the @available_connections ivar to a Hash" do
      MyConnection.instance_variable_get("@available_connections").should_not be_nil
      MyConnection.instance_variable_get("@available_connections").should be_kind_of(Hash)
    end

    it "should set the @reserved_connections ivar to a Set" do
      MyConnection.instance_variable_get("@reserved_connections").should_not be_nil
      MyConnection.instance_variable_get("@reserved_connections").should be_kind_of(Set)
    end
  end

  describe "initialization" do
    it "should accept a connection uri as a String" do
      c = DataObjects::Connection.new('mock://localhost/database')
      # relying on the fact that mock connection sets @uri
      uri = c.instance_variable_get("@uri")

      uri.should be_kind_of(URI)
      uri.scheme.should == 'mock'
      uri.host.should == 'localhost'
      uri.path.should == '/database'
    end

    it "should accept a conneciton uri as a URI" do
      c = DataObjects::Connection.new(URI.parse('mock://localhost/database'))
      # relying on the fact that mock connection sets @uri
      uri = c.instance_variable_get("@uri")

      uri.should be_kind_of(URI)
      uri.to_s.should == 'mock://localhost/database'
    end

    it "should determine which DataObject adapter from the uri scheme" do
      DataObjects::Mock::Connection.should_receive(:acquire)
      DataObjects::Connection.new('mock://localhost/database')
    end

    it "should aquire a connection" do
      uri = URI.parse('mock://localhost/database')
      DataObjects::Mock::Connection.should_receive(:acquire).with(uri)

      DataObjects::Connection.new(uri)
    end

    it "should return the Connection specified by the scheme" do
      c = DataObjects::Connection.new(URI.parse('mock://localhost/database'))
      c.should be_kind_of(DataObjects::Mock::Connection)
    end
  end

  describe 'connection pooling' do
    before do
      @uri = URI.parse('mock://localhost/database')
    end

    it "should make a new connection if the pool is empty" do
      DataObjects::Mock::Connection.instance_variable_get("@available_connections")[@uri.to_s].should be_empty
      c = DataObjects::Mock::Connection.acquire(@uri)
      DataObjects::Mock::Connection.instance_variable_get("@available_connections")[@uri.to_s].should be_empty
      DataObjects::Mock::Connection.instance_variable_get("@reserved_connections").should include(c)
    end

    it "should reuse a connection if there's one available" do
      DataObjects::Mock::Connection.instance_variable_get("@available_connections")[@uri.to_s].should be_empty
      c = DataObjects::Mock::Connection.acquire(@uri)
      c.close
      DataObjects::Mock::Connection.instance_variable_get("@available_connections")[@uri.to_s].should_not be_empty
      c.should == DataObjects::Mock::Connection.acquire(@uri)
    end

    it "should make a new connection if they're all in use" do
      DataObjects::Mock::Connection.instance_variable_get("@available_connections")[@uri.to_s].should be_empty
      c = DataObjects::Mock::Connection.acquire(@uri)
      DataObjects::Mock::Connection.instance_variable_get("@available_connections")[@uri.to_s].should be_empty
      c.should_not == DataObjects::Mock::Connection.acquire(@uri)
    end

    it "should add the connection to available connections on release" do
      DataObjects::Mock::Connection.instance_variable_get("@available_connections")[@uri.to_s].should be_empty
      c = DataObjects::Mock::Connection.acquire(@uri)
      c.close
      DataObjects::Mock::Connection.instance_variable_get("@available_connections")[@uri.to_s].should_not be_empty
      DataObjects::Mock::Connection.instance_variable_get("@available_connections")[@uri.to_s].should include(c)
    end

  end

end