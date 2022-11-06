module Rubaheui
  module Errors
    TypeError = Class.new(::RuntimeError)
    ValueError = Class.new(::RuntimeError)
    InvalidAheuiCodeError = Class.new(::RuntimeError)
  end
end