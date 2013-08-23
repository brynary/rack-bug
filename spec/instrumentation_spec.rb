require 'rack/insight/instrumentation'
require 'rack/insight/instrumentation/setup'

class One
  def initialize(arry)
    @array = arry
  end

  def self.record_self(array)
    array << self
  end

  def self.a_class_method(array)
    yield(array)
  end

  def an_instance_method()
    yield(@array)
  end
end

module Mod
  def module_method(array)
    yield(array)
  end
end

class Two < One
  def an_instance_method
    super
  end

  def self.a_class_method(array)
    super
  end
end

class Probeable
  include Rack::Insight::Instrumentation::Client
  class << self
    include Rack::Insight::Instrumentation::EigenClient
  end
end

module MyEigenClient;
  def self.included(base)
    base.send(:attr_accessor, :is_probed)
  end
end
module MyClient; def probe; "anal probe is #{self.class.is_probed}"; end; end
class MyPanel; include MyClient; class << self; include MyEigenClient; end; end
class MyPanel2; include MyClient; class << self; include MyEigenClient; end; end

describe "Validate Client Design" do
  it "MyPanel instance should respond to probe" do
    MyPanel.new.respond_to?(:probe).should be_true
  end
  it "MyPanel#probe should return 'anal_probe is '" do
    MyPanel.new.probe.should == 'anal probe is '
  end
  it "MyPanel class should respond to is_probed" do
    MyPanel.respond_to?(:is_probed).should be_true
  end
  it "MyPanel.is_probed should default to nil" do
    MyPanel.is_probed.should == nil
  end
  it "MyPanel.is_probed should be settable" do
    MyPanel.is_probed = 'fat mojo'
    MyPanel.is_probed.should == 'fat mojo'
    MyPanel.new.probe.should == 'anal probe is fat mojo'
  end
  it "MyPanel2.is_probed should not interfere with MyPanel.is_probed" do
    MyPanel.is_probed = 'fat mojo'
    MyPanel2.is_probed = 'nice banana'
    MyPanel.is_probed.should == 'fat mojo'
    MyPanel2.is_probed.should == 'nice banana'
    MyPanel.new.probe.should == 'anal probe is fat mojo'
    MyPanel2.new.probe.should == 'anal probe is nice banana'
  end
end

describe "Setting up probes" do
  let :method_calls do [] end
  let :method_subject do [] end
  let :recording_list do [] end

  let :test_collector do
    collector = Probeable.new
    collector.instance_variable_set("@calls", method_calls)
    def collector.after_detect(method_call, timing, arguments, results)
      @calls << [method_call, timing, arguments, results]
    end
    collector
  end

  let :instrument_setup do
    Rack::Insight::Instrumentation::Setup.new(nil)
  end

  let :fake_env do
    {}
  end

  before :each do
    test_collector.probe(test_collector) do
      instrument "One" do
        instance_probe :an_instance_method
        class_probe :a_class_method
        class_probe :record_self
        class_probe :allocate
      end
    end
    instrument_setup.setup(fake_env)
  end

  after :each do
    instrument_setup.teardown(fake_env, 200, {}, "")
  end

  # Test cases:
  #
  # Methods are called on
  #   instance
  #   class
  #   modules
  #
  # Methods are defined/probed at/called on
  # Called on:
  #   obj: instance of class C
  #
  # Defined:
  #   class C
  #   super class B
  #   class C and parent B (overridden)
  #   module Mc - included in C
  #   class C and Mc
  #   module Mb - included in B
  #   class C and Mb
  #   module Me - extended in obj
  #   Me and C - Me overrides C
  #
  # Probed:
  #   On C
  #   On B
  #   On Mc, Mb, Me
  #
  # Not interfere with:
  #   Arguments
  #   Blocks
  #   Return Values
  #   Exceptions
  #

  it "should catch class methods defined on a superclass" do
    #expect do
      One.allocate
    #end.to change(method_calls.length).by(1)
    method_calls.last[0].method.should == :allocate
  end

  it "should not interfere with instance method call on One" do
    expect do
      One.new(method_subject).an_instance_method{|arr| arr << __LINE__}
    end.to change{method_subject.length}.by(1)
  end

  it "should not interfere with class method call" do
    expect do
      One.a_class_method(method_subject){|arr| arr << __LINE__}
    end.to change{method_subject.length}.by(1)
  end

  it "should collect calls made on One#an_instance_method" do
    expect do
      One.new(method_subject).an_instance_method{|arr| arr << __LINE__}
    end.to change{method_calls.length}.by(1)
    method_calls.last[0].method.should == :an_instance_method
  end

  it "should collect calls made on One#a_class_method" do
    expect do
      One.a_class_method(method_subject){|arr| arr << __LINE__}
    end.to change{method_calls.length}.by(1)
    method_calls.last[0].method.should == :a_class_method
  end

  it "should not mess with receive of class methods" do
    One.record_self(recording_list)
    recording_list.should include(One)
  end

  it "should not mess with receive of class methods on subclasses" do
    Two.record_self(recording_list)
    recording_list.should include(Two)
  end


  it "should not interfere with instance method call on Two" do
    expect do
      Two.new(method_subject).an_instance_method{|arr| arr << __LINE__}
    end.to change{method_subject.length}.by(1)
  end

  it "should not interfere with class method call" do
    expect do
      Two.a_class_method(method_subject){|arr| arr << __LINE__}
    end.to change{method_subject.length}.by(1)
  end

  it "should collect calls made on Two#an_instance_method" do
    expect do
      Two.new(method_subject).an_instance_method{|arr| arr << __LINE__}
    end.to change{method_calls.length}.by(2)
    method_calls.each do |method_call|
      method_call[0].method.should == :an_instance_method
    end

    method_calls.map{|mc| mc[0].context}.should include("One", "Two")
  end

  it "should collect calls made on Two#a_class_method" do
    expect do
      Two.a_class_method(method_subject){|arr| arr << __LINE__}
    end.to change{method_calls.length}.by(2)
    method_calls.each do |method_call|
      method_call[0].method.should == :a_class_method
    end

    method_calls.map{|mc| mc[0].context}.should include("One", "Two")
  end
end
