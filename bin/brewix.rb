# bin/brewix.rb
require 'git'
require 'fileutils'

class Brewix
  def initialize(user_mode)
    @repo_base = "https://github.com/BrewixHub"
    @brewix_root = ENV['BREVARPKG'] || "/home/brewix/pkg"
    @brewix_git_root = ENV['BREVARGIT'] || "/home/brewix/git"

    # If using --user mode, change paths
    if user_mode
      @brewix_root = ENV['USRWIXPKG'] || "#{Dir.home}/.brewix/pkg"
      @brewix_git_root = ENV['USRWIXGIT'] || "#{Dir.home}/.brewix/git"
    end

    # Ensure directories exist
    FileUtils.mkdir_p(@brewix_root)
    FileUtils.mkdir_p(@brewix_git_root)
  end

  def install(package_name)
    package_repo = "#{@repo_base}/#{package_name}.git"
    package_git_path = "#{@brewix_git_root}/#{package_name}"
    package_install_path = "#{@brewix_root}/#{package_name}"

    puts "Installing package: #{package_name} from #{package_repo}"

    # Clone the package repository
    if Dir.exist?(package_git_path)
      puts "Updating existing package repo..."
      Git.open(package_git_path).pull
    else
      Git.clone(package_repo, package_git_path)
    end

    # Read metadata
    install_file = "#{package_git_path}/brewinit/install.txt"
    if File.exist?(install_file)
      config = File.read(install_file).split("\n").map { |line| line.split("=", 2) }.to_h
      package_name = config["NAME"] || package_name
      init_file = config["INIT"] || "N/A"

      # Store paths in environment variables
      ENV['BREVARGIT'] = package_git_path
      ENV['BREVARPKG'] = package_install_path

      # Copy package to installation path
      FileUtils.mkdir_p(package_install_path)
      FileUtils.cp_r("#{package_git_path}/.", package_install_path)

      # Save INIT path for future execution
      init_path = "#{package_install_path}/#{init_file}"
      File.write("#{package_install_path}/.brewix-init", init_path) if init_file != "N/A"

      puts "#{package_name} has been installed!"
      puts "Run it using: brewix run #{package_name}" if init_file != "N/A"
    else
      puts "Error: install.txt missing for #{package_name}!"
    end
  end

  def run(package_name)
    package_path = "#{@brewix_root}/#{package_name}"
    init_file = "#{package_path}/.brewix-init"

    if File.exist?(init_file)
      command = File.read(init_file).strip
      puts "Running #{package_name}..."
      exec(command)
    else
      puts "Error: No initialization script found for #{package_name}!"
    end
  end

  def list
    puts "Listing installed packages..."
    installed = Dir.glob("#{@brewix_root}/*").select { |f| File.directory?(f) }
    installed.each { |pkg| puts File.basename(pkg) }
  end
end

# Main logic for running commands
if ARGV.empty?
  puts "Usage: brewix <command> [options]"
else
  user_mode = (ARGV[1] == "--user")
  brewix = Brewix.new(user_mode)

  case ARGV[0]
  when "install"
    brewix.install(ARGV[1])
  when "run"
    brewix.run(ARGV[1])
  when "list"
    brewix.list
  else
    puts "Unknown command: #{ARGV[0]}"
  end
end
