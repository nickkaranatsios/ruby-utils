server 'linode', user: 'webapp', roles: %w{web app db}, port: 1122

set :rvm_ruby_version, '2.2.0'
set :rails_env, :production
set :puma_env, fetch(:rack_env, fetch(:rails_env, 'production'))
set :puma_threads, [4, 8]
set :puma_workers, 1
set :puma_preload_app, false
set :puma_prune_bundler, true
