require 'json'
require 'fileutils'

module VagrantHelper
  def vagrant_cwd
    File.expand_path("../..", __FILE__)
  end

  def vagrant(command, vm)
    log_file = [ "#{subject}.vagrant.log", "a" ]
    system "vagrant", command, vm, out: log_file, err: log_file
    $?.success?
  end

  def config_file
    File.expand_path("../../#{subject}.json", __FILE__)
  end

  def write_config(config)
    File.open(config_file, 'w') do |f|
      f.print(config.to_json)
    end
  end

  def gem_path_file
    File.expand_path('../../.gem_path', __FILE__)
  end

  # Store our GEM_PATH for later retrieval
  # The package-install of vagrant overrides this so we'll store it here so
  # we can load it back in via our Vagranfile
  def write_gem_path
    File.open(gem_path_file, 'w') do |f|
      f.print ENV['GEM_PATH']
    end
  end

  def provision(config)
    write_config config
    vagrant "provision", subject
  end
end

RSpec.configure do |c|
  c.include VagrantHelper

  c.before(:all) do
    Dir.chdir(vagrant_cwd)
    system "librarian-chef install"
    write_config run_list: []
    write_gem_path
    vagrant "up", subject
  end

  c.after(:all) do
    vagrant "halt", subject
    Dir['*.json'].each do |node_json|
      FileUtils.rm node_json
    end
  end
end
