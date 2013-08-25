source 'https://rubygems.org'

gem 'rails', '3.2.12'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'

gem 'json'
gem 'haml'
gem "therubyracer"
gem "sass"

#gem 'fastercsv'

group :development do
  gem 'haml-rails'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

group :development, :test, :ci do
  gem 'rspec-rails'
  gem 'simplecov'
end

group :test, :ci do
  gem 'cucumber'
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  gem 'shoulda'
  gem 'factory_girl'
  gem 'simplecov', :require => false
  gem 'pickle'
  gem 'fakeweb'
  gem 'webmock', :require => false

  gem 'capybara'
  gem 'rack-test'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'
