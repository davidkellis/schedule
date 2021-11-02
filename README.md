# ScheduleJob

schedule is a frontend around crontab to add/remove cron jobs from user cron tables.

## Installation

```
~ ❯ gem install schedule_job
Fetching schedule_job-1.0.1.gem
Successfully installed schedule_job-1.0.1
Parsing documentation for schedule_job-1.0.1
Installing ri documentation for schedule_job-1.0.1
Done installing documentation for schedule_job after 0 seconds
```

## Usage

Example usage:
```
~ ❯ schedule -h
Usage: schedule [options] command
    -d, --dryrun                     Report what would happen but do not install the scheduled job.
    -l, --list                       List installed cron jobs.
    -r, --rm JOB_ID                  Remove the specified job id as indicated by --list
    -u, --user USER                  User that the crontab belongs to.
    -e, --every DURATION             Run command every DURATION units of time.
        For example:
        --every 10m                       # meaning, every 10 minutes
        --every 5h                        # meaning, every 5 hours
        --every 2d                        # meaning, every 2 days
        --every 3M                        # meaning, every 3 months

    -c, --cron CRON                  Run command on the given cron schedule.
        For example:
        --cron "*/5 15 * * 1-5"          # meaning, Every 5 minutes, at 3:00 PM, Monday through Friday
        --cron "0 0/30 8-9 5,20 * ?"     # meaning, Every 30 minutes, between 8:00 AM and 9:59 AM, on day 5 and 20 of the month

~ ❯ schedule -l
~ ❯ schedule -d -e 10m backup.sh
Scheduling: backup.sh Every 10 minutes
Next three runs:
1. 2021-11-01 21:50:00 -0500
2. 2021-11-01 22:00:00 -0500
3. 2021-11-01 22:10:00 -0500
~ ❯ schedule -l
Jobs
1. backup.sh Every 10 minutes
~ ❯ crontab -l
*/10 * * * * backup.sh
~ ❯ schedule -e 3M quarterly_backup.sh
Scheduling: quarterly_backup.sh At 9:50 PM, on day 1 of the month, every 3 months
Next three runs:
1. 2022-01-01 21:50:00 -0600
2. 2022-04-01 21:50:00 -0500
3. 2022-07-01 21:50:00 -0500
~ ❯ schedule -l
Jobs
1. backup.sh Every 10 minutes
2. quarterly_backup.sh At 9:50 PM, on day 1 of the month, every 3 months
~ ❯ crontab -l
*/10 * * * * backup.sh
50 21 1 */3 * quarterly_backup.sh
~ ❯ schedule --dryrun --rm 1
Would remove: backup.sh Every 10 minutes
~ ❯ schedule --dryrun --rm 2
Would remove: quarterly_backup.sh At 9:50 PM, on day 1 of the month, every 3 months
~ ❯ schedule --rm 1
Removing: backup.sh Every 10 minutes
~ ❯ schedule -l
Jobs
1. quarterly_backup.sh At 9:50 PM, on day 1 of the month, every 3 months
~ ❯ schedule --rm 1
Removing: quarterly_backup.sh At 9:50 PM, on day 1 of the month, every 3 months
~ ❯ schedule -l
~ ❯ crontab -l
~ ❯
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
