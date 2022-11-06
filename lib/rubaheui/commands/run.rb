module Rubaheui
  module Commands
    class Run
      def self.process()
        puts Rubaheui::Parser.parse(' ')
      end
    end
  end
end