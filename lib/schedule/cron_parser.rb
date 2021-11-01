require "citrus"

module Citrus
  class Input < StringScanner
    def line_index(pos = pos())
      p = n = 0
      string.each_line do |line|
        next_p = p + line.length
        return n if p <= pos && pos < next_p
        p = next_p
        n += 1
      end
      0
    end
  end
end

Citrus.require("schedule/cron")

# require "polyglot"
# require "treetop"
# require "schedule/cron.treetop"

module Schedule
  module Cron
    Grammar = ScheduleCronParser

    class TableParser
      def self.valid?(user_crontab_string)
        !!parse(user_crontab_string)
      rescue Citrus::ParseError => e
        false
      end

      def self.parse(user_crontab_string)
        Grammar.parse(user_crontab_string, root: :user_crontab)
        # ::CrontabParser.new.parse(user_crontab_string, root: :user_crontab)
      end

      def initialize(user_crontab_string)
        @user_crontab = TableParser.parse(user_crontab_string) rescue nil
      end

      def valid?
        !!@user_crontab
      end

      def get_line_index(match)
        @user_crontab.input.line_index(match.offset)
      end

      def get_line_number(match)
        @user_crontab.input.line_number(match.offset)
      end
      
      def environment_vars
        @user_crontab&.capture(:environment)&.captures(:directive)
        # puts @user_crontab.methods.sort.inspect
        # puts @user_crontab.inspect
        # puts "*" * 80
        # puts @user_crontab.environment_spec.inspect
        # exit()
        # @user_crontab&.environment&.directive
      end

      def job_specs
        @user_crontab&.capture(:jobspecs)&.captures(:jobspec)
        # @user_crontab&.jobspecs&.jobspec
      end
    end

    class LineParser
      def self.valid?(cron_line)
        !!parse(cron_line)
      rescue Citrus::ParseError => e
        false
      end

      def self.parse(cron_line)
        Grammar.parse(cron_line, root: :jobspec, consume: false)
        # ::CrontabParser.new.parse(cron_line, root: :jobspec, consume_all_input: false)
      end
    end
  end
end
