require "uri"
require "cgi"
require "robots_txt/version"

class RobotsTxt
  attr_accessor :txt
  attr_accessor :user_agent
  attr_accessor :groups

  def initialize(txt, user_agent = "")
    self.txt = txt
    self.user_agent = user_agent
    self.groups = parse_robots_txt(txt)
  end

  def allowed?(uri, user_agent = self.user_agent)
    path = CGI.unescape(URI(uri).path)
    return true if path == "/robots.txt"

    allowed = true

    self.groups.each do |group|
      next unless user_agent.match(group[:user_agent])

      most_matched_permissions = []
      most_matched_length = 0
      group[:path].each do |(permission, regex)|
        next unless path.match(regex)

        if most_matched_length < $&.to_s.length
          most_matched_permissions = []
          most_matched_length = $&.to_s.length
        end

        most_matched_permissions << permission
      end

      most_matched_permissions.uniq!

      if most_matched_permissions.any?
        allowed = most_matched_permissions.length == 1 ? most_matched_permissions.first == :allow : true
      end
    end

    allowed
  end

  def crawl_delay(user_agent = self.user_agent)
    delay = nil

    self.groups.each do |group|
      next if !user_agent.match(group[:user_agent]) or !group[:crawl_delay]
      if delay.nil? or delay < group[:crawl_delay]
        delay = group[:crawl_delay]
      end
    end

    delay
  end

  class << self
    def load(txt)
      RobotsTxt.new(txt || "")
    end

    def dump(obj)
      case obj
      when String
        obj
      when self
        obj.txt
      else
        raise ArgumentError, "Could not dump #{obj.inspect}"
      end
    end
  end

  private

  def parse_robots_txt(robots_txt)
    groups = []

    robots_txt.gsub(/\r?\n/, "\n").split(/\n{2,}/).map(&:strip).each do |block|
      parsed = {
        user_agent: [],
        path: [],
        crawl_delay: nil,
        others: {},
      }

      block.each_line do |line|
        next if line =~ /^\s*#/
        next unless line =~ /(.+?)\s*:\s*([^\s#][^#]*)/
        key = $1
        value = $2
        key, value = key.downcase.gsub(/-/, "_").to_sym, value.strip

        case key
        when :user_agent
          parsed[:user_agent] << value
        when :allow, :disallow
          parsed[:path] << [key, pattern_to_regex(value)]
        when :crawl_delay
          parsed[:crawl_delay] = value.to_i
        else
          parsed[:others][key] ||= []
          parsed[:others][key] << value
        end
      end

      groups << {
        user_agent: parsed[:user_agent].any? ? Regexp.union(parsed[:user_agent].map { |ua| pattern_to_regex(ua) }) : //,
        path: parsed[:path],
        crawl_delay: parsed[:crawl_delay],
        others: parsed[:others],
      }
    end

    groups
  end

  def pattern_to_regex(pattern)
    Regexp.compile("^" + pattern.gsub(/(%[0-9a-fA-F]{2})|(\*)|(.)/) { $1 ? Regexp.escape(CGI.unescape($1)) : $2 ? ".*" : $3 })
  end
end
