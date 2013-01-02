# This ask the user to set the value if not already set. This can be used
# for values which can't be set to defaults. If the user does not provide
# a value, the rake task is to be stopped.
#
# options is expected to be a hash. The following options are accepted:
#  - :default => a default value
#  - :choices => a list of choices that will be displayed with the prompt
#
def _aset(name, *options)
  
  if options.any?
    options = options.first
    default_value = options[:default]
    choices = options[:choices]
  else
    default_value = choices = nil
  end
  
  ask_for_value(name, options) unless exists?(name)
end

def ask_for_value(name, options = {})
  default = options[:default]
  choices = options[:choices]
  prompt = options[:prompt] || "Need a value for '#{name}'"

  Capistrano::CLI.ui.say("#{prompt} (you can set value for '#{name}' if you don't want to be asked anymore)")
    
  prompt = default.nil? ? "Enter value (return will abort): " : "Enter value:"
  prompt = (if default and choices and choices.any?
    "Enter a value (possible choices: #{choices}). Default is:"
  elsif default
    "Enter a value. Default is:"
  elsif choices and choices.any?
    "Enter a value (possible choices: #{choices}). No entry will abort."
  else
    "Enter a value. No entry will abort."
  end)
  
  value = Capistrano::CLI.ui.ask(prompt) do |q|
    q.default = default unless default.nil?
  end
  if value.length == 0
    exit
  else
    set(name, value)
  end 
end

# ask_for_file :file_name_variable, :with_prompt => "A beautiful prompt?", :unless_exists => 'some_file_path'
def ask_for_file(name, options = {})
  if (default = options[:unless_exists]).nil? or !FileTest.exist?(default)
    ask_for_value(name, options.merge(:prompt => options[:with_prompt]))
  else
    set(name, default)
  end
end

# ask_for_file_unless_set(:file_name_variable, :with_prompt => "A beautiful prompt?")
def ask_for_file_unless_set(name, options = {})
  ask_for_file(name, options) unless exists?(name)
end
    

# Code by Tim Riley
# https://github.com/timriley/capistrano-mycorp/blob/master/lib/mycorp/common.rb
# Part of the Capistrano-gem-making-tutorial at http://openmonkey.com/2010/01/19/making-your-capistrano-recipe-book/

def _cset(name, *args, &block)
  unless exists?(name)
    set(name, *args, &block)
  end
end

# Code by ricodigo
# https://github.com/ricodigo/ricodigo-capistrano-recipes/blob/master/lib/helpers.rb
# =========================================================================
# These are helper methods that will be available to your recipes.
# =========================================================================

# automatically sets the environment based on presence of
# :stage (multistage gem), :rails_env, or RAILS_ENV variable; otherwise defaults to 'production'

def environment
  if exists?(:stage)
    stage
  elsif exists?(:rails_env)
    rails_env
  elsif(ENV['RAILS_ENV'])
    ENV['RAILS_ENV']
  else
    "production"
  end
end

def is_using_git
  is_using('git', :scm)
end

def is_using_rvm
  is_using('rvm', :ruby_manager)
end

def is_using_rbenv
  is_using('rbenv', :ruby_manager)
end

def is_using_nginx
  is_using('nginx',:web_server)
end

def is_using_passenger
  is_using('passenger',:app_server)
end

def is_using_unicorn
  is_using('unicorn',:app_server)
end

def is_using_thin
  is_using('thin',:app_server)
end

def is_using_monit
  is_using('monit', :process_monitor)
end

def is_using_bluepill
  is_using('bluepill', :process_monitor)
end

def is_using_process_monitor
  process_monitor && process_monitor != :none
end

def is_using_god
  is_using('god', :process_monitor)
end

def is_using_background_processor
  background_processor && background_processor != :none
end

def is_using_delayed_job
  is_using('delayed_job', :background_processor)
end

def is_using(something, with_some_var)
 exists?(with_some_var.to_sym) && fetch(with_some_var.to_sym).to_s.downcase == something
end

# Helpers determining if the chosen process monitorer manages some processes completely,
# i.e. they don't need to be started up with the system boot service for example.
def process_monitor_manages_app_server
  is_using_god && is_using_thin ? true : false
end

def process_monitor_manages_background_processor
  is_using_god && is_using_delayed_job ? true : false
end

# Path to where the generators live
def templates_path
  expanded_path_for('../generators')
end

def docs_path
  expanded_path_for('../doc')
end

def expanded_path_for(path)
  e = File.join(File.dirname(__FILE__),path)
  File.expand_path(e)
end

def parse_config(file)
  require 'erb'  #render not available in Capistrano 2
  template=File.read(file)          # read it
  return ERB.new(template).result(binding)   # parse it
end

# =========================================================================
# Prompts the user for a message to agree/decline
# =========================================================================
def ask(message, default=true)
  Capistrano::CLI.ui.agree(message)
end

# Generates a configuration file parsing through ERB
# Fetches local file and uploads it to remote_file
# Make sure your user has the right permissions.
def generate_config(local_file,remote_file)
  temp_file = '/tmp/' + File.basename(local_file)
  buffer    = parse_config(local_file)
  File.open(temp_file, 'w+') { |f| f << buffer }
  upload temp_file, remote_file, :via => :scp
  `rm #{temp_file}`
end

# =========================================================================
# Executes a basic rake task.
# Example: run_rake log:clear
# =========================================================================
def run_rake(task)
  run "cd #{current_path} && rake #{task} RAILS_ENV=#{environment}"
end

def rvmsudo(task)
  run "cd #{current_path} && rvmsudo #{task}"
end

def deny_in_production
  if stage == "production"
    puts "Can't push to production"
    abort
  end
end