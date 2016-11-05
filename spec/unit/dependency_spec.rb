require 'spec_helper'

describe Dependency do
  let(:dependency) { Dependency.new 'rails', '2.1.3' }

  describe "#major" do
    it "returns the major version" do
      expect(dependency.major).to eq('2')
    end
  end

  describe "#minor" do
    it "returns the minor version" do
      expect(dependency.minor).to eq('1')
    end
  end

  describe "#patch" do
    it "returns the patch version" do
      expect(dependency.patch).to eq('3')
    end
  end

  describe '#initialize' do
    it 'allows a version with only two parts' do
      dep = Dependency.new 'foo', '4.2'
      expect(dep.major).to eq '4'
      expect(dep.minor).to eq '2'
      expect(dep.patch).to be_nil
    end

    it 'allows a version with only one part' do
      dep = Dependency.new 'foo', '4'
      expect(dep.major).to eq '4'
      expect(dep.minor).to be_nil
      expect(dep.patch).to be_nil
    end
  end
end
