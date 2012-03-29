namespace :test do

  desc 'run cucumber tests'
  task :cucumber do
    ENV['NODE_ENV'] = "test"
    cuke_bin_path      = File.expand_path(File.join(File.dirname(__FILE__), 'node_modules', 'cucumber', 'bin'))
    cuke_feature_path  = File.expand_path(File.join(File.dirname(__FILE__), 'tests', 'features')) 
    cmd = "#{cuke_bin_path}/cucumber.js #{cuke_feature_path} -r #{cuke_feature_path}/step_definitions"
    exec(cmd)
  end

end