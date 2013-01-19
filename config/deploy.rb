# set :application, "set your application name here"
# set :repository,  "set your repository location here"

# # set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# # Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

# role :web, "your web-server here"                          # Your HTTP server, Apache/etc
# role :app, "your app-server here"                          # This may be the same as your `Web` server
# role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
# role :db,  "your slave db-server here"

# # if you want to clean up old releases on each deploy uncomment this:
# # after "deploy:restart", "deploy:cleanup"

# # if you're still using the script/reaper helper you will need
# # these http://github.com/rails/irs_process_scripts

# # If you are using Passenger mod_rails uncomment this:
# # namespace :deploy do
# #   task :start do ; end
# #   task :stop do ; end
# #   task :restart, :roles => :app, :except => { :no_release => true } do
# #     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
# #   end
# # end
# use multiple environments
#require 'capistrano/ext/multistage'

# ensures a bundle install is run after deployment
require 'bundler/capistrano'
#require "rvm/capistrano"
#require 'config/deploy/cap_notify.rb'
set :application, "store" 
set :user_sudo, true
set :user, "icicle" 
set :admin_runner, "icicle" 
ssh_options[:forward_agent] = true
default_run_options[:pty] = true

#path to git repository
set :repository, "git@github.com:avadheshyadav/fedena.git"

#path where to deploy the application
set :path, "/home/icicle/dump"
# multi-stage options
set :stages, %w(staging production developmet)   # add as many staging environments as you want; each needs a file in config/deploy/
set :default_stage, "development"

set :location, "192.168.1.66"
set :scm, :git
set :branch, "master"

role :web, "192.168.1.66" # Your HTTP server, Apache/etc
role :app, "192.168.1.66" # This may be the same as your `Web` server
role :db, "192.168.1.66" #, :primary => true # This is where Rails migrations will run
#role :db, "your slave db-server here"
#set :notify_emails, [""]
server location, :app, :web, :primary => true
set :deploy_to, "#{path}"
#ssh_options[:forward_agent] = true

#ssh_options[:keys] = %w(/home/icicle/.ssh/id_rsa)
ssh_options[:keys] = "192.168.1.66"

 namespace :db do

    desc <<-DESC
      Creates the database.yml configuration file in shared path.

      By default, this task uses a template unless a template
      called database.yml.erb is found either is :template_dir
      or /config/deploy folders. The default template matches
      the template for config/database.yml file shipped with Rails.

      When this recipe is loaded, db:setup is automatically configured
      to be invoked after deploy:setup. You can skip this task setting
      the variable :skip_db_setup to true. This is especially useful
      if you are using this recipe in combination with
      capistrano-ext/multistaging to avoid multiple db:setup calls
      when running deploy:setup for all stages one by one.
    DESC
    task :setup, :except => { :no_release => true } do

      default_template = <<-EOF
      base: &base
        adapter: mysql
        username: root
        password: macro129
      development:
        database: fedena_ultimate
        <<: *base
    
      test:
        database: fedena_ultimate_test
        <<: *base
      
      EOF

      location = fetch(:template_dir, "config/deploy") + '/database.yml.erb'
      template = File.file?(location) ? File.read(location) : default_template

      config = ERB.new(template)

      run "mkdir -p #{shared_path}/db"
      run "mkdir -p #{shared_path}/config"
      put config.result(binding), "#{shared_path}/config/database.yml"
    end

    desc <<-DESC
      [internal] Updates the symlink for database.yml file to the just deployed release.
    DESC
    task :symlink, :except => { :no_release => true } do
      run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
      
    end

    namespace :deploy do
      desc "Send email notification"
      task :send_notification do
        Notifier.deploy_notification(self).deliver 
      end
    end
end
  after "deploy:setup",  "db:setup"   unless fetch(:skip_db_setup, false)
  after "deploy:finalize_update", "db:symlink"
