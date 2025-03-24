# bin/brewix.rb
require 'git'

class Brewix
  def initialize
    @repo_base = "https://github.com/BrewixHub"
  end

  def install(package_name)
    package_repo = "#{@repo_base}/#{package_name}.git"
    puts "Installing package: #{package_name} from #{package_repo}"
    
    # Clone the package repository
    Git.clone(package_repo, "#{package_name}")

    puts "#{package_name} has been installed!"
  end

  def list
    puts "Listing installed packages..."
    # List installed packages (could be just a directory listing for now)
    installed = Dir.glob('*')
    installed.each { |pkg| puts pkg }
  end
end

# Main logic for running commands
if ARGV.empty?
  puts "Usage: brewix <command> [options]"
else
  brewix = Brewix.new
  case ARGV[0]
  when "install"
    brewix.install(ARGV[1])
  when "list"
    brewix.list
  else
    puts "Unknown command: #{ARGV[0]}"
  end
end
