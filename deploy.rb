# coding: UTF-8
#!/usr/bin/env ruby

require "open3"
require "colored"

def run_cmd cmd
  puts "#{cmd}".cyan
  stdin, stdout, stderr, wait_thread = Open3.popen3 cmd
  unless wait_thread.value.success?
    puts "Command failed with error:\n\n #{stderr.read}".red
    puts "Command standard output was:\n\n #{stdout.read}"
    system "say 'deploy failed'"
    abort
  end
end

def run_step description, *cmds
  puts description.blue
  cmds.each { |cmd| run_cmd cmd}
  puts
end

app_name        = "flo_test_deploy"
heroku_app_name = 'flotestdeploy'

run_step "Going to the development branch...",
  "git checkout development"

# we want to have the latest development
run_step "Rebasing from origin/development...",
  "git pull --rebase origin development"

# we want to have the latest master
run_step "Rebasing the master branch from origin/master...",
  "git checkout master",
  "git pull --rebase origin master"

run_step "Merging master into development to make sure hotfixes on master are included in development...",
  "git checkout development",
  "git merge master"

run_step "Running tests...",
  "rake spec" # it automatically runs rake db:test:prepare
  "rake cucumber"

run_step "Pushing development to origin/development...",
  "git push origin development"

run_step "Creating a manual Heroku backup of the production db...",
  "heroku pgbackups:capture -a #{heroku_app_name} --expire"

run_step "Importing this backup in your local development database...",
  "curl -o #{app_name}-production-db.dump `heroku pgbackups:url -a #{heroku_app_name}`",
  "pg_restore --verbose --clean --no-acl --no-owner -h localhost -d #{app_name}_development #{app_name}-production-db.dump"

run_step "Running migrations on this imported data...",
  "rake db:migrate"

run_step "TODO Verifying whether the db records are valid..."

run_step "Merging no-ff development into master",
  "git checkout master",
  "git merge --no-ff development"

run_step "Pushing to the Heroku production application... (Sainte Marie, Mère de Dieu, priez pour nous)",
  "git push production master"

run_step "Running migrations on the Heroku production application...",
  "heroku run rake db:migrate -a #{heroku_app_name}"

run_step "Restarting the Heroku production application...",
  "heroku restart -a #{heroku_app_name}"

puts "Displaying logs of the Heroku production application server...".blue
system "heroku logs -n 20 -a #{heroku_app_name}"

run_step "TODO Please enter create a new tag (version number and logs)"

puts "Hurray!!! It's over :) You can now share this successful new release by posting to TODO [releases list email address]".green
