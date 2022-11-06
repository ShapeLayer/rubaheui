module Rubaheui
  module Runner
    # Define constants
    # Direction: 0th, 1st bits
    # Is_double: 2nd bit
    # 
    # Bit table
    # Dir     bin   dir       bin
    # up    0 000   dup     4 100
    # right 1 001   dright  5 101
    # down  2 010   ddown   6 110
    # left  3 011   dleft   7 111
    DIR_UP = 0
    DIR_RIGHT = 1
    DIR_DOWN = 2
    DIR_LEFT = 3
    DIR_DUP = DIR_UP | 1 << 2
    DIR_DRIGHT = DIR_RIGHT | 1 << 2
    DIR_DDOWN = DIR_DOWN | 1 << 2
    DIR_DLEFT = DIR_LEFT | 1 << 2

    class Instance
      def initialize(code)
        raise Rubaheui::Errors::TypeError "`code` must be `String`." unless code.kind_of?(String)
        @code = code.split("\n").map(&:strip)
        @code_valid_cache = {}
        @ptr = {x: 0, y: 0, d: DIR_DOWN}
        # 27th container (ㅎ, "passage") is queue.
        # This operation is defined at AVIS.
        @container = Array.new(28) { Array.new() }
        @container_selected = 0
      end

      def get_code
        return @code
      end

      def process_current_point()
        raise Rubaheui::Errors::InvalidAheuiCodeError "Code of current point is invalid" unless code_in_current_is_valid
        code = Rubaheui::Parser.parse(@code[@ptr[:y]][@ptr[:x]])
        # operation flag
        # 0th bit: next_operation is reverse
        # 1st bit: operation is not completed (not applied)
        next_operation = 0
        case code[0]
        # Todo: next_operation = 1 << 0 is too replicated.
        # Use double case statements
        when 11 # ㅇ: Nil
          # 없음 명령
        when 18 # ㅎ: Exit(return)
          pop = process_pop_current
          exit pop != nil ? pop : 0
        when 3  # ㄷ: Add
          ab = process_try_double_pop_current
          if ab == nil then next_operation = 1 << 0
          else process_put_current(ab[0] + ab[1])
          end
        when 4  # ㄸ: Mul
          ab = process_try_double_pop_current
          if ab == nil then next_operation = 1 << 0
          else process_put_current(ab[0] * ab[1])
          end
        when 16 # ㅌ: Sub
          ab = process_try_double_pop_current
          if ab == nil then next_operation = 1 << 0
          else process_put_current(ab[1] - ab[0])
          end
        when 2  # ㄴ: Div
          ab = process_try_double_pop_current
          if ab == nil then next_operation = 1 << 0
          else process_put_current(ab[1] / ab[0])
          end
        when 5  # ㄹ: Remains
          ab = process_try_double_pop_current
          if ab == nil then next_operation = 1 << 0
          else process_put_current(ab[1] % ab[0])
          end
        when 6  # ㅁ: Pop
          val = process_pop_current
          if val == nil then next_operation = 1 << 0
          else
            case code[2]
            when 21
              print val
            when 27
              print [val].pack("U")
            end
          end
        when 7  # ㅂ: Put
          case code[2]
          when 21
            val = gets.strip
            # This operation is defined at AVIS.
            process_put_current(Rubaheui::Commons.is_integer?(val) ? val.to_i : -1)
          when 27
            val = gets.strip
            # This operation is defined at AVIS.
            process_put_current(val.length == 1 ? val.ord : -1)
          else
            # Note: Checking human error...
            raise Rubaheui::Errors::ValueError, "`code[2]` = %d is %s, it cannot be converted to stroke_counts. (Converted to %s)" % [code[2], code[2], Rubaheui::Commons.stroke_counts[code[2]]] if code[2] == nil
            process_put_current(Rubaheui::Commons.stroke_counts[code[2]])
          end
        when 8  # ㅃ: Duplicate
          val = process_pop_current
          if val == nil then next_operation = 1 << 0
          else
            for _i in 1..2
              process_put_current(val)
            end
          end
        when 17 # ㅍ: Swap
          ab = process_try_double_pop_current
          if ab == nil then next_operation = 1 << 0
          else
            process_put_current(ab[0])
            process_put_current(ab[1])
          end
        when 9  # ㅅ: Select
          @container_selected = code[2]
        when 10 # ㅆ: Move
          val = process_pop_current
          if val == nil then next_operation = 1 << 0
          else process_put(code[2], val)
          end
        when 12 # ㅈ: Compare
          val = process_try_double_pop_current
          if val == nil then next_operation = 1 << 0
          else process_put_current(val[1] >= val[0] ? 1: 0)
          end
        when 14 # ㅊ: Condition
          val = process_pop_current
          if val == nil then next_operation = 1 << 0
          else
            if val == 0 then next_operation = 1 << 0 end
          end
        end
        return next_operation
      end

      def process_put(selected, value)
        @container[selected] += [value]
      end
      def process_pop(selected)
        if @container[selected].length == 0 then return nil
        else
          # 27th container (ㅎ, "passage") is queue.
          # This operation is defined at AVIS.
          if selected == 21 || selected == 27 then return @container[selected].shift
          else return @container[selected].pop
          end
        end
      end

      def process_put_current(value)
        return process_put(@container_selected, value)
      end

      def process_pop_current()
        return process_pop(@container_selected)
      end

      def process_try_double_pop_current()
        a = process_pop_current        
        if a == nil then return nil end
        b = process_pop_current
        if b == nil then
          process_put_current(a)
          return nil
        end
        return [a, b]
      end

      def update_point_direction_current()
        update_point_direction_using_pos(@ptr[:x], @ptr[:y])
      end

      def update_point_direction_using_pos(x, y)
        # update internal value and return direction
        # x, y = @ptr[:x], @ptr[:y]
        target = @code[y][x]
        raise Rubaheui::Errors::InvalidAheuiCodeError "Cannot find valid code in pos (x: %d, y: %d)" % [x, y] if target == " "
        jong = Rubaheui::Parser.parse(target)[1]
        raise Rubaheui::Errors::InvalidAheuiCodeError "Cannot parse middle character (Jongseong) code in pos (x: %d, y: %d)" % [x, y] if jong < 0 || jong >= 21
        delta = get_point_direction_using_code(jong)
        @ptr[:d] = delta[:d]
        @ptr[:x] += delta[:dx]
        @ptr[:y] += delta[:dy]
      end

      def get_point_direction_using_code(code)
        # expecting end
        raise Rubaheui::Errors::InvalidAheuiCodeError "`code` (Jongseong Code) must be between 0 and 20." if (code < 0 || code >= 21)
        new_ptr = {dx: 0, dy: 0, d: @ptr[:d]}
        # returns direction, posdelta
        # 분리
        case code
        when 0 # ㅏ
          new_ptr[:d] = DIR_RIGHT
        when 2 # ㅑ
          new_ptr[:d] = DIR_DRIGHT
        when 4 # ㅓ
          new_ptr[:d] = DIR_LEFT
        when 6 # ㅕ
          new_ptr[:d] = DIR_DLEFT
        when 8 # ㅗ
          new_ptr[:d] = DIR_UP
        when 12 # ㅛ
          new_ptr[:d] = DIR_DUP
        when 13 # ㅜ
          new_ptr[:d] = DIR_DOWN
        when 17 # ㅠ
          new_ptr[:d] = DIR_DDOWN
        when 18 # ㅡ
          case new_ptr[:d]
          when DIR_UP, DIR_DUP, DIR_DOWN, DIR_DDOWN
            new_ptr[:d] ^= 010
          end
        when 20 # ㅣ
          case new_ptr[:d]
          when DIR_RIGHT, DIR_DRIGHT, DIR_LEFT, DIR_DLEFT
            new_ptr[:d] ^= 010
          end
        when 19 # ㅢ
          new_ptr[:x] += (new_ptr[:d] >> 0 ^ 0) * ((new_ptr[:d] >> 1 ^ 0) * -2 + 1)
          new_ptr[:y] += (new_ptr[:d] >> 0 ^ 1) * ((new_ptr[:d] >> 1 ^ 1) * -2 + 1)
          new_ptr[:d] ^= 010
        end
        return new_ptr
      end

      def get_valid_pos(x, y, d)
        raise Rubaheui::Errors::TypeError "`x` must be `Integer`." unless x.kind_of?(Integer)
        raise Rubaheui::Errors::TypeError "`y` must be `Integer`." unless y.kind_of?(Integer)
        raise Rubaheui::Errors::TypeError "`d` must be `Integer`." unless d.kind_of?(Integer)
        is_dir_horizontal = d & 1
        # puts "(%d, %d, %d, %d)" % [x, y, d, is_dir_horizontal]
        loop do
          if y < 0 then y += @code.length end
          if x < 0 then x += @code[y].length end
          if is_dir_horizontal == 1 then
            if y >= @code.length then y %= @code.length end
            if x >= @code[y].length then x %= @code[y].length end
          else
            if y >= @code.length then y %= @code.length end
          end
          unless @code_valid_cache.key?(y) then @code_valid_cache[y] = {} end
          unless @code_valid_cache[y].key?(x) then @code_valid_cache[y][x] = code_in_pos_is_valid(x, y) end
          if @code_valid_cache[y][x] == true then break end
          calced = calc_next_pos_dt_using_dir(x, y, d)
          x += calced[0]
          y += calced[1]
        end
        return [x, y]
      end

      def update_current_pos_to_valid()
        x, y = get_valid_pos(@ptr[:x], @ptr[:y], @ptr[:d])
        @ptr[:x] = x
        @ptr[:y] = y
      end

      def move_using_point_direction()
        calced = calc_next_pos_dt_using_dir(@ptr[:x], @ptr[:y], @ptr[:d])
        @ptr[:x] += calced[0]
        @ptr[:y] += calced[1]
      end

      def calc_next_pos_dt_using_dir(x, y, d)
        dx = (d & 1) * (1 + -2 * ((d >> 1) & 1)) * (1 + ((d >> 2) & 1))
        dy = ((d ^ 1) & 1) * (-1 + (d & 2)) * (1 + ((d >> 2) & 1))
        return [dx, dy]
      end

      def code_in_pos_is_valid(x, y)
        raise Rubaheui::Errors::TypeError "`x` must be `Integer`." unless x.kind_of?(Integer)
        raise Rubaheui::Errors::TypeError "`y` must be `Integer`." unless y.kind_of?(Integer)
        if y < 0 || y >= @code.length then return false end
        if x < 0 || x >= @code[y].length then return false end
        begin
          Rubaheui::Parser.parse(@code[y][x])
        rescue Rubaheui::Errors::ValueError
          return false
        end
        return true
      end

      def code_in_current_is_valid()
        return code_in_pos_is_valid(@ptr[:x], @ptr[:y])
      end

      def print_pointer_tracing()
        i = 0
        str = "(x: %d, y: %d, d: %d(%s), %s, s: %s)" % [@ptr[:x], @ptr[:y], @ptr[:d], Rubaheui::Commons.dir_bit_to_str(@ptr[:d]), @code[@ptr[:y]][@ptr[:x]], @container_selected]
        @container.each do |raw|
          str += "%d: " % i + raw.join(", ") + ' / '
          i += 1
        end
        puts str
      end
        

      # todo: stdout sync
      def run_one_step()
        update_current_pos_to_valid
        next_operation = process_current_point
        update_point_direction_current
        # print_pointer_tracing
        if next_operation & 1 == 1 then @ptr[:d] ^= 0 << 2 | 1 << 1 | 0 << 0 end
        move_using_point_direction
      end
    end
  end
end

if __FILE__ == $0
  require_relative "commons"
  require_relative "errors"
  require_relative "parser"
  file = File.open("../../scripts/99_beers.aheui")
  script = file.read
  runner = Rubaheui::Runner::Instance.new(script)
  puts runner.get_code
  loop do
    runner.run_one_step
  end
end
