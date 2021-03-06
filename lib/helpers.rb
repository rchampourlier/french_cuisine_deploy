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
  
  unless exists?(name)
    Capistrano::CLI.ui.say("Need a value for '#{name}'. (You can set this value in your deploy.rb file.)")
    
    prompt = default_value.nil? ? "Enter value (return will abort): " : "Enter value:"
    if default_value && choices && choices.any?
      prompt = "Enter a value (possible choices: #{choices}). Default is:"
    elsif default_value
      prompt = "Enter a value. Default is:"
    elsif choices && choices.any?
      prompt = "Enter a value (possible choices: #{choices}). No entry will abort."
    else
      prompt = "Enter a value. No entry will abort."
    end
    
    value = Capistrano::CLI.ui.ask(prompt) do |q|
      q.default = default_value unless default_value.nil?
    end
    if value.length == 0
      exit
    else
      set(name, value)
    end 
  end
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

def is_using_nginx
  is_using('nginx',:web_server)
end

def is_using_passenger
  is_using('passenger',:app_server)
end

def is_using_unicorn
  is_using('unicorn',:app_server)
end

def is_using_monit
  is_using('monit', :process_monitorer)
end

def is_using_bluepill
  is_using('bluepill', :process_monitorer)
end

def is_using(something, with_some_var)
 exists?(with_some_var.to_sym) && fetch(with_some_var.to_sym).to_s.downcase == something
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