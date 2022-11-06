module Rubaheui
  module Parser
    def initialize()
    end

    def self.parse(content)
      raise Rubaheui::Errors::TypeError '`content` must be `String` of length 1' unless content.kind_of?(String)
      raise Rubaheui::Errors::TypeError, '`content` must be `String` of length 1' unless content.length == 1
      ord = content.ord
      raise Rubaheui::Errors::ValueError, '`content` must be combined Hangul' unless '가'.ord <= ord && ord <= '힣'.ord
      return [((ord - 0xAC00) / 28) / 21, (ord - 0xAC00) / 28%  21, (ord - 0xAC00) % 28]
    end
  end
end

=begin
ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ
ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ
 ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ
=end

if __FILE__ == $0
  require_relative "commons"
  require_relative "errors"
  require_relative "parser"
  for s in '갃낳다라마바사아자차카타파하ㅎ'.split('')
    c = s + ' '
    Rubaheui::Parser.parse(s).each do |item|
      c += "%s(%s)" % [item, Rubaheui::Commons.stroke_counts[item]]
    end
    puts c
  end
end
