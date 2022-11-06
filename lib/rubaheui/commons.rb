module Rubaheui
  module Commons
    @@stroke_counts = [nil, 2, 4, 4, 2, 5, 5, 3, 5, 7, 9, 9, 7, 9, 9, 8, 4, 4, 6, 2, 4, nil, 3, 4, 3, 4, nil]
    def self.is_integer?(val)
      val.to_i.to_s == val
    end
    def self.stroke_counts
      @@stroke_counts
    end
    def self.dir_bit_to_str(val)
      case val
      when 0 then return "DIR_UP"
      when 1 then return "DIR_RIGHT"
      when 2 then return "DIR_DOWN"
      when 3 then return "DIR_LEFT"
      when 4 then return "DIR_DUP"
      when 5 then return "DIR_DRIGHT"
      when 6 then return "DIR_DDOWN"
      when 7 then return "DIR_DLEFT"
      else return "UNDEFINED"
      end
    end
  end
end