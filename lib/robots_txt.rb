require "uri"
require "robots_txt/version"

class RobotsTxt
  attr_accessor :user_agent
  attr_accessor :groups

  def initialize(txt, user_agent = "")
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
      allowed = most_matched_permissions.length == 1 ? most_matched_permissions.first == :allow : true
    end

    allowed
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
          parsed[:crawl_delay] = value
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
    Regexp.compile(
      pattern.gsub(/(^)|(%[0-9a-fA-F]{2})|(\*)|(.)/) {
        $1 ? "^" : $2 ? Regexp.escape(CGI.unescape($2)) : $3 ? ".*" : $4
      }
    )
  end
end
