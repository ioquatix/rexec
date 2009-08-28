
require 'etc'

module RExec
  
  # Set the user of the current process. Supply either a user ID
  # or a user name.
  #
  # Be aware that on Mac OS X / Ruby 1.8 there are bugs when the user id
  # is negative (i.e. it doesn't work). For example "nobody" with uid -2
  # won't work.
  def self.change_user(user)
    if user.kind_of?(String)
      user = Etc.getpwnam(user).uid
    end

    Process::Sys.setuid(user)
  end
  
  
  # Get the user of the current process. Returns the user name.
  def self.current_user
    uid = Process::Sys.getuid
    
    Etc.getpwuid(uid).name
  end
  
end