require 'spec_helper'
require 'sem_version'

describe SemVersion do
  context "when parsing a version from string" do
    it "should correctly identify major, minor, patch" do
      v = SemVersion.new('0.1.2')
      v.major.should == 0
      v.minor.should == 1
      v.patch.should == 2
    end

    it "should correctly identify the pre-release" do
      v = SemVersion.new('0.1.2-three.4-5')
      v.pre.should == 'three.4-5'
      v.prerelease.should == 'three.4-5'
    end

    it "should correctly identify the metadata" do
      v1 = SemVersion.new('0.1.2+metadata.4.5')
      v2 = SemVersion.new('0.1.2-pre.four+five.6')

      v1.metadata.should == 'metadata.4.5'
      v2.metadata.should == 'five.6'
    end
  end

  context "when generating version strings" do
    it "do x.y.z correctly" do
      SemVersion.new('1.2.3').to_s.should == '1.2.3'
    end

    it "should do x.y.z-pre" do
      SemVersion.new('3.2.1-pre.4').to_s.should == '3.2.1-pre.4'
    end

    it "should do x.y.z+metadata" do
      SemVersion.new('1.2.3+metadata.4.five').to_s.should == '1.2.3+metadata.4.five'
    end

    it "should do x.y.z-pre+metadata" do
      SemVersion.new('3.2.1-pre.4+metadata.5.six').to_s.should == '3.2.1-pre.4+metadata.5.six'
    end
  end

  it "should correctly generate version arrays using #to_s" do
    SemVersion.new('1.2.3-pre.4+metadata.5').to_a.should == [1, 2, 3, 'pre.4', 'metadata.5']
  end

  context "when generating hashes using #to_h" do
    it "should correctly generate hashes" do
      SemVersion.new('1.2.3-pre.4+metadata.5').to_h.should == {:major => 1, :minor => 2, :patch => 3, :pre => 'pre.4', :metadata => 'metadata.5'}
    end

    it "should skip nil pre or metadata keys" do
      SemVersion.new('1.2.3').to_h.has_key?(:pre).should be_false
      SemVersion.new('1.2.3').to_h.has_key?(:metadata).should be_false
    end
  end

  context "when comparing versions" do
    it "should compare patch correctly" do
      SemVersion.new('0.0.1').should be == SemVersion.new('0.0.1')
      SemVersion.new('0.0.1').should be < SemVersion.new('0.0.2')
      SemVersion.new('0.0.1').should be < SemVersion.new('0.0.20')
    end

    it "should compare minor correctly" do
      SemVersion.new('0.1.0').should be == SemVersion.new('0.1.0')
      SemVersion.new('0.1.0').should be < SemVersion.new('0.1.1')
      SemVersion.new('0.1.0').should be < SemVersion.new('0.1.10')
    end

    it "should compare major correctly" do
      SemVersion.new('1.0.0').should be == SemVersion.new('1.0.0')
      SemVersion.new('1.0.0').should be < SemVersion.new('2.0.0')
      SemVersion.new('1.0.0').should be < SemVersion.new('20.0.0')
    end

    it "should compare pre correctly" do
      SemVersion.new('1.0.0-pre').should be == SemVersion.new('1.0.0-pre')
      SemVersion.new('1.0.0').should be > SemVersion.new('1.0.0-pre')
      SemVersion.new('1.0.0-alpha').should be < SemVersion.new('1.0.0-beta')
      SemVersion.new('1.0.0-1').should be < SemVersion.new('1.0.0-2')
      SemVersion.new('1.0.0-2').should be < SemVersion.new('1.0.0-11')
      SemVersion.new('1.0.0-a').should be > SemVersion.new('1.0.0-100')
      SemVersion.new('1.0.0-a.3.b').should be < SemVersion.new('1.0.0-a.3.c')
      SemVersion.new('1.0.0-a.4.b').should be > SemVersion.new('1.0.0-a.3.c')
      SemVersion.new('1.0.0-a.3.b').should be > SemVersion.new('1.0.0-a.3')
      SemVersion.new('1.0.0-a.3').should be < SemVersion.new('1.0.0-a.3.3')
    end

    it "should compare metadata correctly" do
      SemVersion.new('1.0.0-pre+metadata').should be == SemVersion.new('1.0.0-pre+metadata')
      SemVersion.new('1.0.0+metadata').should be == SemVersion.new('1.0.0+metadata')
      SemVersion.new('1.0.0+metadata').should be == SemVersion.new('1.0.0')
    end

    it "should pass the semver.org test cases" do
      SemVersion.new('1.0.0-alpha').should be < SemVersion.new('1.0.0-alpha.1')
      SemVersion.new('1.0.0-alpha.1').should be < SemVersion.new('1.0.0-alpha.beta')
      SemVersion.new('1.0.0-alpha.beta').should be < SemVersion.new('1.0.0-beta')
      SemVersion.new('1.0.0-beta').should be < SemVersion.new('1.0.0-beta.2')
      SemVersion.new('1.0.0-beta.2').should be < SemVersion.new('1.0.0-beta.11')
      SemVersion.new('1.0.0-beta.11').should be < SemVersion.new('1.0.0-rc.1')
      SemVersion.new('1.0.0-rc.1').should be < SemVersion.new('1.0.0')
    end
  end

  context "when satisfying constraints" do
    it "should correctly satisfy >" do
      SemVersion.new('1.0.1').satisfies?('> 1').should be_true
      SemVersion.new('1.0.1').satisfies?('> 1.0.1').should be_false
      SemVersion.new('0.9.9').satisfies?('> 1.0').should be_false
    end

    it "should correctly satisfy >=" do
      SemVersion.new('1.0.1').satisfies?('>= 1').should be_true
      SemVersion.new('1.0.1').satisfies?('>= 1.0.1').should be_true
      SemVersion.new('1.0.1').satisfies?('>= 1.0.2').should be_false
    end

    it "should correctly satisfy <" do
      SemVersion.new('1.0.1').satisfies?('< 1.0.2').should be_true
      SemVersion.new('1.0.1').satisfies?('< 1.0.1').should be_false
    end

    it "should correctly satisfy <=" do
      SemVersion.new('1.0.1').satisfies?('<= 1.0.2').should be_true
      SemVersion.new('1.0.1').satisfies?('<= 1.0.1').should be_true
      SemVersion.new('1.0.1').satisfies?('<= 1').should be_false
    end

    it "should correctly satisfy =" do
      SemVersion.new('1.0.0').satisfies?('= 1.0').should be_true
      SemVersion.new('1.0.1').satisfies?('1.0.1').should be_true
      SemVersion.new('1.0.1').satisfies?('= 1.0.2').should be_false
    end

    it "should correctly satisfy ~> x.y" do
      SemVersion.new('2.1.9').satisfies?('~> 2.2').should be_false
      SemVersion.new('2.2.0').satisfies?('~> 2.2').should be_true
      SemVersion.new('2.9.0').satisfies?('~> 2.2').should be_true
      SemVersion.new('3.0.0').satisfies?('~> 2.2').should be_false
    end

    it "should correctly satisfy ~> x.y.z" do
      SemVersion.new('2.1.9').satisfies?('~> 2.2.0').should be_false
      SemVersion.new('2.2.0').satisfies?('~> 2.2.0').should be_true
      SemVersion.new('2.3.0').satisfies?('~> 2.2.0').should be_false
    end
  end

  context "when given an invalid version" do
    it "should return correctly from ::valid?" do
      SemVersion.valid?('2.1.9').should be_true
      SemVersion.valid?('2.1').should be_false
      SemVersion.valid?('1.2.x').should be_false
      SemVersion.valid?('2.1.9-a.b').should be_true
      SemVersion.valid?('2.1.9-a!').should be_false
      SemVersion.valid?('2.1.9+a.b').should be_true
      SemVersion.valid?('2.1.9+a!').should be_false
      SemVersion.valid?('2.1.9-a.b+c.0').should be_true
      SemVersion.valid?('2.1.9+a.b-c.0').should be_true
    end

    it "should raise when ::new called with invalid string" do
      expect{ SemVersion.new('1.2.x') }.to raise_error(ArgumentError)
    end
  end

  context "when modifying specific parts of the version" do
    it "should modify major correctly" do
      v = SemVersion.new('1.2.3')
      v.major = 2
      v.major.should == 2
    end

    it "should complain if major is invalid" do
      v = SemVersion.new('1.2.3')
      expect{ v.major = -1 }.to raise_error(ArgumentError)
      expect{ v.major = 'a' }.to raise_error(ArgumentError)
    end

    it "should modify major correctly" do
      v = SemVersion.new('1.2.3')
      v.major = 2
      v.major.should == 2
    end

    it "should complain if minor is invalid" do
      v = SemVersion.new('1.2.3')
      expect{ v.minor = -1 }.to raise_error(ArgumentError)
      expect{ v.minor = 'a' }.to raise_error(ArgumentError)
    end

    it "should modify patch correctly" do
      v = SemVersion.new('1.2.3')
      v.patch = 2
      v.patch.should == 2
    end

    it "should complain if patch is invalid" do
      v = SemVersion.new('1.2.3')
      expect{ v.patch = -1 }.to raise_error(ArgumentError)
      expect{ v.patch = 'a' }.to raise_error(ArgumentError)
    end

    it "should modify prerelease correctly" do
      v = SemVersion.new('1.2.3-four.5')
      v.pre = 'five.6'
      v.pre.should == 'five.6'
      v.pre = nil
      v.pre.should == nil
    end

    it "should complain if prerelease is invalid" do
      v = SemVersion.new('1.2.3-four.5')
      expect{ v.pre = 1 }.to raise_error(ArgumentError)
      expect{ v.pre = 'a.' }.to raise_error(ArgumentError)
      expect{ v.pre = '.a' }.to raise_error(ArgumentError)
      expect{ v.pre = 'a.!' }.to raise_error(ArgumentError)
    end

    it "should modify metadata correctly" do
      v = SemVersion.new('1.2.3-four.5')
      v.metadata = 'five.6'
      v.metadata.should == 'five.6'
      v.metadata = nil
      v.metadata.should == nil
    end

    it "should complain if metadata is invalid" do
      v = SemVersion.new('1.2.3-four.5')
      expect{ v.metadata = 1 }.to raise_error(ArgumentError)
      expect{ v.metadata = 'a.' }.to raise_error(ArgumentError)
      expect{ v.metadata = '.a' }.to raise_error(ArgumentError)
      expect{ v.metadata = 'a.!' }.to raise_error(ArgumentError)
    end
  end

  it "allows SemVersion() to be used as an alias" do
    SemVersion.new('1.2.3') == SemVersion('1.2.3')
  end

  it "should identify open and closed contraints" do
    SemVersion.open_constraint?('1.2.3').should be_false
    SemVersion.open_constraint?('= 1.2.3').should be_false
    SemVersion.open_constraint?('== 1.2.3').should be_false
    SemVersion.open_constraint?('> 1.2.3').should be_true
    SemVersion.open_constraint?('>= 1.2.3').should be_true
    SemVersion.open_constraint?('< 1.2.3').should be_true
    SemVersion.open_constraint?('<= 1.2.3').should be_true
    SemVersion.open_constraint?('~> 1.2.3').should be_true
  end

  it "should correctly split the comparison and version from constraints" do
    SemVersion.split_constraint('1.2.3').should == ['=', '1.2.3']
    SemVersion.split_constraint('= 1.2.3').should == ['=', '1.2.3']
    SemVersion.split_constraint('== 1.2.3').should == ['=', '1.2.3']
    SemVersion.split_constraint('> 1.2.3').should == ['>', '1.2.3']
  end

  context "when parsing a version from array" do
    it "should correctly identify sections" do
      v = SemVersion.new([3, 4, 5, 'pre.4', 'metadata.5'])
      v.to_s.should == '3.4.5-pre.4+metadata.5'
      v2 = SemVersion.new(3, 4, 5, 'pre.4', 'metadata.5')
      v.to_s.should == '3.4.5-pre.4+metadata.5'
    end

    it "should moan if any parts are invalid" do
      expect{ SemVersion.new(3) }.to raise_error(ArgumentError)
      expect{ SemVersion.new(3, 4) }.to raise_error(ArgumentError)
      expect{ SemVersion.new(-1, 4, 5) }.to raise_error(ArgumentError)
      expect{ SemVersion.new(3, 4, 5, 'pre!') }.to raise_error(ArgumentError)
      expect{ SemVersion.new(3, 4, 5, nil, 'metadata.4') }.not_to raise_error
    end
  end

  context "when parsing a version from a hash" do
    it "should correctly identify sections" do
      v = SemVersion.new(:major => 3, :minor => 2, :patch => 1, :pre => 'pre.4', :metadata => 'metadata.5')
      v.to_s.should == '3.2.1-pre.4+metadata.5'
    end

    it "should allow :prerelease as well as :pre" do
      v = SemVersion.new(:major => 3, :minor => 2, :patch => 1, :prerelease => 'pre.4', :metadata => 'metadata.5')
      v.to_s.should == '3.2.1-pre.4+metadata.5'
    end
  end
end
