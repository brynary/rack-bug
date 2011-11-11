
describe "Setting up probes" do
  class One
    def initialize(arry)
      @array = arry
    end

    def self.class_method(array)
      array << __LINE__
    end

    def instance_method
      @array << __LINE__
    end

    def self.other_class_method
    end
  end

  class Two < One
    def instance_method
    end

    def self.class_method
      super
    end

    def self.other_class_method
      super
    end
  end

  class Three < Two
    def self.another_class_method
    end
  end

  let :method_calls do [] end
  let :method_subject do [] end

  let :test_collector do
    collector = Object.new
    def collector.after_detect(method_call, timing, arguments, results)
      method_calls << [method_call, timing, arguments, results]
    end
  end


  before :each do
    test_collector.probe(test_collector) do
      instrument One do
        instance_probe :instance_method
        class_probe :class_method
      end
    end
  end

  it "should not interfere with instance method call" do
    expect do
      One.new(method_subject).instance_method
    end.to change{method_subject.length}.by(1)
  end

  it "should not interfere with class method call" do
    expect do
      One.class_method(method_subject)
    end.to change{method_subject.length}.by(1)
  end



  it "should collect calls made on One#instance_method" do
    expect do
      One.new(method_subject).instance_method
    end.to change{method_calls.length}.by(1)
    method_calls.last[0].should == "instance_method"
  end

  it "should collect calls made on One#class_method" do
    expect do
      One.class_method(method_subject)
    end.to change{method_calls.length}.by(1)
    method_calls.last[0].should == "class_method"
  end
end
