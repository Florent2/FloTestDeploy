require 'spec_helper'

describe Product do
  it "is true" do
    Product.create.should be_valid
  end
end
