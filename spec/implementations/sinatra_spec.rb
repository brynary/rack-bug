require 'spec_helper'

describe SampleApp do
  def root
    get "/" do
      yield
    end
  end

  it("raises no error") { root { expect(last_response).to be_ok } }
  it("has enable button") { root { expect( last_response.body ).to match /rack-insight-enabler/ } }
end
