require "spec_helper"

def fixture(filename = "robots.txt")
  File.read("spec/fixtures/#{filename}")
end

RSpec.describe RobotsTxt do
  it "has a version number" do
    expect(RobotsTxt::VERSION).not_to be nil
  end

  context "basic behavior" do
    robots_txt = RobotsTxt.new(fixture, "Mozilla/99.9")

    it "allows if none matched" do
      expect(robots_txt.allowed?("/none-matched-path")).to be_truthy
    end

    it "disallows if disallowed path matched" do
      expect(robots_txt.allowed?("/protected/nanoha.txt")).to be_falsey
    end

    it "takes longest match condition" do
      expect(robots_txt.allowed?("/protected/public/fate.jpg")).to be_truthy
    end

    it "allows if allow/disallow rules are equivalent" do
      expect(robots_txt.allowed?("/ambiguous")).to be_truthy
    end
  end

  context "with special characters" do
    robots_txt = RobotsTxt.new(fixture, "Mozilla/99.9")

    it "disallows if disallow matched exactly" do
      expect(robots_txt.allowed?("/directory/")).to be_falsey
    end

    it "allows if disallow not matched exactly" do
      expect(robots_txt.allowed?("/directory/yuno.jpg")).to be_truthy
    end

    it "allows if disallow with wildcard matched" do
      expect(robots_txt.allowed?("/cgi-bin/admin.cgi")).to be_falsey
    end
  end

  context "with escaped" do
    robots_txt = RobotsTxt.new(fixture, "Mozilla/99.9")

    it "treats escaped $ (%24) as non-special character" do
      expect(robots_txt.allowed?("/special-$-character")).to be_falsey
      expect(robots_txt.allowed?("/special-$")).to be_falsey
      expect(robots_txt.allowed?("/special-%24")).to be_falsey
    end

    it "treats escaped * (%2a) as non-special character" do
      expect(robots_txt.allowed?("/special-super-character")).to be_truthy
      expect(robots_txt.allowed?("/special-*-character")).to be_falsey
      expect(robots_txt.allowed?("/special-%2A-character")).to be_falsey
    end

    it "works for complex case" do
      expect(robots_txt.allowed?("/special-*-$")).to be_falsey
      expect(robots_txt.allowed?("/special-*-$-character")).to be_falsey
    end
  end

  context "with disallow default" do
    robots_txt = RobotsTxt.new(fixture, "RisingHeart/99.9")

    it "disallows if not specifically allowed" do
      expect(robots_txt.allowed?("/hayate")).to be_falsey
    end
  end

  context "with multiple user-agents" do
    robots_txt = RobotsTxt.new(fixture)

    it "works for all user-agents" do
      expect(robots_txt.allowed?("/", "RisingHeart/99.9")).to be_falsey
      expect(robots_txt.allowed?("/", "Bardiche/99.9")).to be_falsey
    end
  end
end
