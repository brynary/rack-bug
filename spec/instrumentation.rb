require 'insight/instrumentation'
require 'insight/instrumentation/setup'

class One
  def initialize(arry)
    @array = arry
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

describe "Setting up probes" do
  let :method_calls do [] end
  let :method_subject do [] end

  let :test_collector do
    collector = Object.new
    collector.extend Insight::Instrumentation::Client
    collector.instance_variable_set("@calls", method_calls)
    def collector.after_detect(method_call, timing, arguments, results)
      @calls << [method_call, timing, arguments, results]
    end
    collector
  end

  let :instrument_setup do
    Insight::Instrumentation::InstrumentSetup.new(nil)
  end

  let :fake_env do
    {}
  end

  before :each do
    test_collector.probe(test_collector) do
      instrument "One" do
        instance_probe :an_instance_method
        class_probe :a_class_method
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
    method_calls.last[0].method.should == "an_instance_method"
  end

  it "should collect calls made on One#a_class_method" do
    expect do
      One.a_class_method(method_subject){|arr| arr << __LINE__}
    end.to change{method_calls.length}.by(1)
    method_calls.last[0].method.should == "a_class_method"
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
    end.to change{method_calls.length}.by(1)
    method_calls.last[0].method.should == "an_instance_method"
  end

  it "should collect calls made on Two#a_class_method" do
    expect do
      Two.a_class_method(method_subject){|arr| arr << __LINE__}
    end.to change{method_calls.length}.by(1)
    method_calls.last[0].method.should == "a_class_method"
  end
end
