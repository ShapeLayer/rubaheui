require 'test/unit'
require 'rubaheui'

class TestParser < Test::Unit::TestCase
  def test_simple
    assert_equal([0, 2, 2], Rubaheui.Parser.new().parse('갺'))
  end
end