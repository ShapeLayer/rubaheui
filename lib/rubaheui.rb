# frozen_string_literal: true

require_relative 'rubaheui/version'

def require_all(path)
  glob = File.join(__dir__, path, "*.rb")
  Dir[glob].sort.each do |file|
    require file
  end
end

module Rubaheui
  autoload  :Errors,  'rubaheui/errors'
  autoload  :Parser,  'rubaheui/parser'
end


require_all 'rubaheui/commands'
