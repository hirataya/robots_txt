RobotsTxt - Yet another robots.txt parser
======

RobotsTxt is a parser for robots.txt.
It works according to the rules of the Robots Exclusion Protocol.
(Note that it is currently in Draft Standard state and is subject to change in the future.)


cf. [Internet Draft: Robots Exclusion Protocol](https://tools.ietf.org/html/draft-rep-wg-topic-00)

Installation
------------

Add this line to your application's Gemfile:

```ruby
gem "robots_txt", git: "https://github.com/hirataya/robots_txt"
```

And then execute:

```
$ bundle install
```

Usage
-----

```ruby
robots_txt = RobotsTxt.new(File.read("robots.txt"), "Mozilla/9.99")
robots_txt.allowed?("/")
robots_txt.allowed?("/search?q=fatechan")
```

Overriding UserAgent:

```ruby
robots_txt.user_agent = "Bardiche/1.0"
```

Without default UserAgent:

```ruby
robots_txt = RobotsTxt.new(File.read("robots.txt"))
robots_txt.allowed?("/", "Bardiche/1.0")
```

License
-------

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
