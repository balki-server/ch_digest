begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |spec|
    if ENV.has_key?('FORMAT')
      spec.rspec_opts ||= []
      spec.rspec_opts += ['--format', ENV['FORMAT']]
    end
  end
  Rake::Task[:spec].add_description "(Use FORMAT=... to specify rspec output format)"
rescue LoadError
end

task :default => :spec
