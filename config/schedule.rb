# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
#
# @example Running commands manually
#   bundle exec cap whenever:clear_crontab
#   bundle exec cap whenever:update_crontab
#
# @note If you want the cronjob to run only on one machine, use :job for the roles
#       otherwise, the :app role will run the cronjob on every server!
# @note The clear_crontab and update_crontab commands are run automatically when running cap deploy
#
# @see http://github.com/javan/whenever

set :output, "#{path}/log/wheneveroutput.log"

every :day, at: '12:00am', roles: [:app] do
  command '/scholarsphere/bin/whenever_generate_sitemap.sh'
end

# TODO: turn this back on once share notify implementation is back up and working
# every :day, at: "7:00am", roles: [:job] do
#   rake 'share:files'
# end

every :day, at: '7:00am', roles: [:job] do
  rake 'scholarsphere:expire:leases_and_embargoes'
end

# Stats email sent to users on the 2nd of every month at 9 am
every '0 9 2 * *' do
  rake 'scholarsphere:stats:notify'
end

every :day, at: '12:20am', roles: [:job] do
  command '/scholarsphere/bin/whenever_audit_repository.sh'
end

every :day, at: '1:00 am', roles: [:job] do
  command "#{path}/config/cronjobs/compare_solr.bash"
end

# Solr and Fedora are restarted each morning at 2am

every :day, at: '3:00 am', roles: [:job] do
  command "#{path}/config/cronjobs/update_user_stats.bash"
end

every :monday, at: '6:00 am', roles: [:job] do
  command "#{path}/config/cronjobs/send_weekly_stats.bash"
end

every 60.minutes, roles: [:app] do
  command "#{path}/config/cronjobs/temp_file_clean.bash"
end

# No particular time just needs to run hourly.
every :hour, at: 10, roles: [:job] do
  command "cd #{path} && RAILS_ENV=production bundle exec rake scholarsphere:resque:count"
end

every 10.minutes, roles: [:job] do
  command "#{path}/config/cronjobs/resque-cleanup.bash"
end

# yearly
every '0 0 1 1 *', at: '6:00 am', roles: [:job] do
  command "#{path}/config/cronjobs/dump_and_truncate_searches.bash"
end
