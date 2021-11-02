require "optparse"

# schedule --every 10m "my_command --foo --bar"

module ScheduleJob
  class Cli
    def self.run(argv = ARGV)
      cli = Cli.new
      args = cli.get_args(argv)
      cli.execute(args)
    end
    
    def get_args(argv = ARGV)
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: schedule [options] command"

        opts.on("-d", "--dryrun", "Report what would happen but do not install the scheduled job.") do |dryrun|
          options[:dryrun] = dryrun
        end

        opts.on("-l", "--list", "List installed cron jobs.") do |list|
          options[:list_jobs] = list
        end

        opts.on("-r", "--rm JOB_ID", "Remove the specified job id as indicated by --list") do |job_id_to_remove|
          options[:remove_job] = job_id_to_remove
        end

        opts.on("-u", "--user USER", "User that the crontab belongs to.") do |user|
          options[:crontab_user] = user
        end

        opts.on("-e", "--every DURATION", "Run command every DURATION units of time.
        For example:
        --every 10m                       # meaning, every 10 minutes
        --every 5h                        # meaning, every 5 hours
        --every 2d                        # meaning, every 2 days
        --every 3M                        # meaning, every 3 months
        ") do |every|
          options[:every] = every
        end

        opts.on("-c", "--cron CRON", "Run command on the given cron schedule.
        For example:
        --cron \"*/5 15 * * 1-5\"          # meaning, Every 5 minutes, at 3:00 PM, Monday through Friday
        --cron \"0 0/30 8-9 5,20 * ?\"     # meaning, Every 30 minutes, between 8:00 AM and 9:59 AM, on day 5 and 20 of the month
        ") do |cron_schedule|
          options[:cron] = cron_schedule
        end
      end.parse!

      options[:command] = ARGV.join(" ").strip
      options
    end

    def execute(args)
      case
      when args[:list_jobs]               # read jobs
        list_jobs(args)
      when args[:remove_job]              # remove job
        remove_job(args)
      when args[:cron] || args[:every]    # write jobs
        install_job(args)
      end
    end

    def list_jobs(args)
      user = args[:crontab_user]
      
      table = Cron::Table.new(user)
      
      puts table.to_s unless table.empty?
    end

    def install_job(args)
      dry_run = args[:dryrun]
      command = args[:command]
      user = args[:crontab_user]

      if command.empty?
        puts "A cron job command hasn't been specified. Please specify which command you would like to run."
        exit(1)
      end

      job = case
      when args[:cron]
        cron_schedule = args[:cron]
        Cron::Job.new(cron_schedule, command)
      when args[:every]
        duration = args[:every]
        match = duration.match(/(\d+)(m|h|d|M)/)
        if match
          qty = match[1].to_i
          unit_of_time = match[2].to_s
          Cron::Job.every(qty, unit_of_time, command)
        else
          puts "'#{duration}' is an invalid duration. The duration must be specified as: integer followed immediately by m (minutes), h (hours), d (days), M (months) (e.g. 10m)"
          exit(1)
        end
      end

      table = Cron::Table.new(user)
      table.add(job, dry_run)
    end

    def remove_job(args)
      dry_run = args[:dryrun]
      user = args[:crontab_user]
      job_id = args[:remove_job].to_i   # this is a 1-based index that should match the indices from the --list command

      table = Cron::Table.new(user)

      table.remove(job_id, dry_run)
    end
  end
end