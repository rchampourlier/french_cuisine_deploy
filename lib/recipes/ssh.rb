module FrenchCuisineDeploy::SSH
  extend self
  
  def command(user, target_server, local_port, target_port)
    "ssh -f #{user}@#{target_server} -L #{local_port}:127.0.0.1:#{target_port} -N"
  end # def command
  
end # module FrenchCuisineDeploy::DB

Capistrano::Configuration.instance.load do

  # Taps tools
  namespace :ssh do
    
    desc "Open a SSH tunnel to the first app server unless a specific ssh_target_server value is set."
    task :open_tunnel do
      _cset :ssh_target_server, roles[:app].servers.first.to_s
      _aset :user
      _aset :ssh_local_port
      _aset :ssh_target_port
      ssh_command = FrenchCuisineDeploy::SSH.command user, ssh_target_server, ssh_local_port, ssh_target_port
      run_locally "#{ssh_command} </dev/null >/dev/null 2>&1" # these keys ensure the process does return
    end # task :open_tunnel
    
    task :close_tunnel do
      _cset :ssh_target_server, roles[:app].servers.first.to_s
      _aset :user
      _aset :ssh_local_port
      _aset :ssh_target_port
      ssh_command = FrenchCuisineDeploy::SSH.command user, ssh_target_server, ssh_local_port, ssh_target_port
      run_locally "kill `ps auxww|grep '#{ssh_command}' | grep -v grep | awk '{print $2}'`"
    end
    
  end # namespace :ssh
  
end # Capistrano::Configuration.instance.load


# This may be another way for opening a tunnel, but not working as is.
# Setup port forwarding to access the taps server on the remote server
# (unreachable directly - 5000 is closed to the outside world).
#Net::SSH.start( target_server, user ) do |session|
  #session.forward.local( 5000, '127.0.0.1', 5000 )
  #session.loop
#end