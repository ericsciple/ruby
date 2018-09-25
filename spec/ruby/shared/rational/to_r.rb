require_relative '../../spec_helper'

describe :rational_to_r, shared: true do
  #mathn
  unless ::Math.private_method_defined?(:rsqrt)
    it "returns self" do
      a = Rational(3, 4)
      a.to_r.should equal(a)

      a = Rational(bignum_value, 4)
      a.to_r.should equal(a)
    end
  end
end
