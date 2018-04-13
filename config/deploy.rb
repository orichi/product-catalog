require 'mina/rails'
require 'mina/git'
# require 'mina/rbenv'  # for rbenv support. (https://rbenv.org)
require 'mina/rvm'    # for rvm support. (https://rvm.io)
require 'mina/puma'

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :application_name, 'product'
set :domain, '192.168.146.128'
set :deploy_to, '/var/www/product'
set :repository, 'git@github.com:orichi/product-catalog.git'
set :branch, 'master'

# Optional settings:
  set :user, 'royan'          # Username in the server to SSH to.
#   set :port, '30000'           # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# Shared dirs and files will be symlinked into the app-folder by the 'deploy:link_shared_paths' step.
# Some plugins already add folders to shared_dirs like `mina/rails` add `public/assets`, `vendor/bundle` and many more
# run `mina -d` to see all folders and files already included in `shared_dirs` and `shared_files`
# set :shared_dirs, fetch(:shared_dirs, []).push('public/assets')
# set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/secrets.yml')

# This task is the environment that is loaded for all remote run commands, such as
# `mina deploy` or `mina rake`.
task :remote_environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  invoke :'rvm:use', 'ruby-2.2.1'
end

# Put any custom commands you need to run at setup
# All paths in `shared_dirs` and `shared_paths` will be created on their own.
task :setup do
  # command %{rbenv install 2.3.0 --skip-existing}
  # 在服务器项目目录的shared中创建log文件夹
  command %[mkdir -p "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/log"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/log"]

  # 在服务器项目目录的shared中创建config文件夹 下同
  command %[mkdir -p "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/config"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/config"]

  command %[touch "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/config/database.yml"]
  command %[touch "#{fetch(:deploy_to)}/#{fetch(:shared_path)}/config/secrets.yml"]

  # puma.rb 配置puma必须得文件夹及文件
  command %[mkdir -p "#{fetch(:deploy_to)}/shared/tmp/pids"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/tmp/pids"]

  command %[mkdir -p "#{fetch(:deploy_to)}/shared/tmp/sockets"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/tmp/sockets"]

  command %[touch "#{fetch(:deploy_to)}/shared/config/puma.rb"]
  command  %[echo "-----> Be sure to edit 'shared/config/puma.rb'."]

  # tmp/sockets/puma.state
  command %[touch "#{fetch(:deploy_to)}/shared/tmp/sockets/puma.state"]
  command  %[echo "-----> Be sure to edit 'shared/tmp/sockets/puma.state'."]

  # log/puma.stdout.log
  command %[touch "#{fetch(:deploy_to)}/shared/log/puma.stdout.log"]
  command  %[echo "-----> Be sure to edit 'shared/log/puma.stdout.log'."]

  # log/puma.stdout.log
  command %[touch "#{fetch(:deploy_to)}/shared/log/puma.stderr.log"]
  command  %[echo "-----> Be sure to edit 'shared/log/puma.stderr.log'."]

  command  %[echo "-----> Be sure to edit '#{fetch(:shared_path)}/config/database.yml'."]
end

desc "Deploys the current version to the server."
task :deploy do
  # uncomment this line to make sure you pushed your local branch to the remote origin
  # invoke :'git:ensure_pushed'
  run(:local) do
    command "scp config/secrets.yml #{fetch(:user)}@#{fetch(:domain)}:#{fetch(:shared_path)}/config/secrets.yml"
    command "scp config/mongoid.yml #{fetch(:user)}@#{fetch(:domain)}:#{fetch(:shared_path)}/config/mongoid.yml"
    command "scp config/puma.rb #{fetch(:user)}@#{fetch(:domain)}:#{fetch(:shared_path)}/config/puma.rb"
  end

  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
      # in_path(fetch(:current_path)) do
      #   command %{mkdir -p tmp/}
      #   command %{touch tmp/restart.txt}
      # end
      invoke :'puma:phased_restart'
    end
  end

  # you can use `run :local` to run tasks on local machine before of after the deploy scripts
  # run(:local){ say 'done' }
end

# For help in making your deploy script, see the Mina documentation:
#
#  - https://github.com/mina-deploy/mina/tree/master/docs
