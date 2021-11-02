require "active_support/core_ext/numeric/time"
require "active_support/core_ext/date_time"
require "cronex"
require "open3"
require "parse-cron"
require "shellwords"
require "stringio"

require_relative "./cron_parser"

module ScheduleJob
  module Cron

    class EnvironmentVar
      def initialize(name, value)
        @name = name
        @value = value
      end

      def to_s
        "#{@name} = #{@value}"
      end
    end

    class Table
      def initialize(user = nil)
        @user = user
        load(user)
      end

      def empty?
        @environment_vars.empty? && @jobs.empty?
      end

      def load(user = @user)
        @raw_crontab = read_crontab(user)
        @environment_vars, @jobs = parse_crontab(@raw_crontab)
      end

      def read_crontab(user = @user)
        command = ["crontab", "-l"]
        command << "-u #{user}" if user
        command = command.join(" ")

        stdout, stderr, exit_status = Open3.capture3(command)
        crontab_output = stdout
        error_output = stderr

        no_crontab = !exit_status.success? && error_output =~ /no crontab/

        raise("Unable to read crontab: #{error_output}") if !exit_status.success? && !no_crontab

        # puts "read_crontab()"
        # puts "stdout:"
        # puts stdout
        # puts "stderr:"
        # puts stderr
        
        crontab_output
      end

      # returns lines that represent valid cron job specification lines
      def parse_crontab(user_crontab)
        parser = TableParser.new(user_crontab)

        # user_crontab.each_line do |line|
        #   puts line
        #   puts "valid? #{LineParser.valid?(line)}"
        #   puts LineParser.parse(line)
        # end

        return [], [] unless parser.valid?

        # puts "valid!"

        environment_vars = parser.environment_vars&.map do |env_directive|
          name = env_directive[:var].to_s
          expr = env_directive[:expr].to_s
          EnvironmentVar.new(name, expr)
        end || []

        jobs = parser.job_specs&.map do |jobspec|
          schedule_spec = jobspec.capture(:schedule_spec).to_s
          command = jobspec.capture(:command).to_s
          line_number = parser.get_line_number(jobspec)
          Job.new(schedule_spec, command, line_number, jobspec.offset)
        end || []

        [environment_vars, jobs]
      end

      def add(job, dry_run = false)
        if @dry_run
          puts "Would schedule: #{job.to_s}"
        else
          puts "Scheduling: #{job.to_s}"
          install_cron_job(job)
        end
        puts "Next three runs:"
        cron_parser = CronParser.new(job.schedule_spec)
        first_run_time = cron_parser.next(Time.now)
        second_run_time = cron_parser.next(first_run_time)
        third_run_time = cron_parser.next(second_run_time)
        puts "1. #{first_run_time}"
        puts "2. #{second_run_time}"
        puts "3. #{third_run_time}"
      end

      def install_cron_job(job)
        job_spec = job.specification
        # puts "Installing new cron job: #{job_spec}"

        new_crontab = [read_crontab(@user).strip, job_spec.strip].reject(&:empty?).join("\n")
        write_crontab(new_crontab)
      end

      # because we print the table out with 1-based job IDs, job_id is a 1-based index into @jobs
      def remove(job_id, dry_run = false)
        job_index = job_id - 1

        if job_index >= @jobs.size
          puts "The specified job ID does not exist."
          exit(1)
        end

        job = @jobs[job_index]

        if dry_run
          puts "Would remove: #{job}"
        else
          puts "Removing: #{job}"
          new_crontab = @raw_crontab.lines.reject.with_index{|line, line_index| line_index == job.line_number - 1 }.join
          write_crontab(new_crontab)
        end
      end

      def write_crontab(new_crontab, user = @user)
        command = ["crontab"]
        command << "-u #{user}" if user
        command << "-"
        command = command.join(" ")

        # command = "(crontab -l ; echo \"#{job_spec}\") | crontab -"   # add new job to bottom of crontab, per https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job
        # puts "writing new crontab:"
        # puts new_crontab
        # puts "*" * 80

        # puts "write_crontab:"
        # puts "command: #{command}"
        # puts "new crontab:"
        # puts new_crontab

        stdout, stderr, exit_status = Open3.capture3(command, stdin_data: new_crontab)
        crontab_output = stdout
        error_output = stderr

        load(user)

        raise("Unable to write to crontab: #{error_output}") unless exit_status.success?
      end

      def to_s
        s = StringIO.new
        if !@environment_vars.empty?
          s.puts "Environment"
          s.puts @environment_vars.join("\n")
        end
        if !@jobs.empty?
          s.puts "Jobs"
          @jobs.each_with_index do |job, i|
            s.puts "#{i + 1}. #{job}"
          end
        end
        s.string
      end
    end


    class Job
      def self.every(duration_quantity, duration_unit_of_time, command)
        now = DateTime.now
        next_moment = now + 1.minute
        minute = next_moment.minute
        hour = next_moment.hour
        day = next_moment.day
        schedule_spec = case duration_unit_of_time
          when "m"
            "*/#{duration_quantity} * * * *"
          when "h"
            "#{minute} */#{duration_quantity} * * *"
          when "d"
            "#{minute} #{hour} */#{duration_quantity} * *"
          when "M"
            "#{minute} #{hour} #{day} */#{duration_quantity} *"
        end
        self.new(schedule_spec, command)
      end

      attr_reader :schedule_spec
      attr_reader :line_number

      # schedule_spec is a cron specification string: minutes hours day-of-month month day-of-week
      # see https://pkg.go.dev/github.com/robfig/cron?utm_source=godoc#hdr-CRON_Expression_Format
      # see https://github.com/mileusna/crontab
      # see https://github.com/josiahcarlson/parse-crontab

      # line_numbrer is the 1-based index into the crontab file that this job was found at
      # pos_offset is the 0-based index into the crontab file that this job was found at
      def initialize(schedule_spec, command, line_number = nil, pos_offset = nil)
        @schedule_spec = schedule_spec
        @command = command
        @pos_offset = pos_offset
        @line_number = line_number
      end

      def specification
        "#{@schedule_spec} #{escaped_command}"
      end

      def escaped_command
        Shellwords.escape(@command).gsub("%", "\%")   # % is a special character in cron job specifications; see https://serverfault.com/questions/274475/escaping-double-quotes-and-percent-signs-in-cron
      end

      def to_s
        schedule = Cronex::ExpressionDescriptor.new(@schedule_spec).description
        # str = "#{@command} #{schedule} (line #{@line_number}, pos #{@pos_offset})"
        str = "#{@command} #{schedule}"
      end

    end

  end
end