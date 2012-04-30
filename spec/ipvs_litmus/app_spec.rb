require 'spec_helper'

describe IPVSLitmus::App do
  def app
    IPVSLitmus::App
  end

  describe "GET /status" do
    it "works" do
      get "/status"

      last_response.should be_ok
      last_response.header["Content-Type"].should == "text/plain"
    end
  end

  describe "GET /:service/status" do
    it "is successful when the service is passing" do
      test_service = IPVSLitmus::Service.new('test', [AlwaysAvailableDependency.new], [ConstantMetric.new(100)])
      IPVSLitmus.services['test'] = test_service

      get "/test/status"

      last_response.should be_ok
      last_response.header["Content-Type"].should == "text/plain"
      last_response.body.should match(/Health: 100/)
      last_response.body.should match(/AlwaysAvailableDependency: OK/)
      last_response.body.should match(/ConstantMetric: 100/)
    end

    it "is 'service unavailable' when the check fails" do
      test_service = IPVSLitmus::Service.new('test', [NeverAvailableDependency.new], [ConstantMetric.new(100)])
      IPVSLitmus.services['test'] = test_service

      get "/test/status"

      last_response.status.should == 503
      last_response.header["Content-Type"].should == "text/plain"
    end

    it "is 'not found' when the service is unknown" do
      get "/unknown/status"

      last_response.status.should == 404
      last_response.header["Content-Type"].should == "text/plain"
    end

    it "is 'service unavailable' when a down file exists" do
      test_service = IPVSLitmus::Service.new('test', [NeverAvailableDependency.new], [ConstantMetric.new(100)])
      IPVSLitmus.services['test'] = test_service

      write_down_file "test", "Down for testing"

      get "/test/status"

      last_response.status.should == 503
      last_response.body.should match(/Down for testing/)
    end
  end
end
