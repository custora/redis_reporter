require 'rubygems'
require 'bundler/setup'

require 'librato/metrics'
require 'yaml'

info = `redis-cli INFO`

data = {}
info.split("\n").each do |line|
  if line =~ /\w+:\w+/
    parts = line.split(':')
    data[parts[0].strip] = parts[1].strip
  end
end

params = YAML.load(File.open(ARGV[0], 'r').read)

Librato::Metrics.authenticate params['librato']['user'], params['librato']['token']

params['metrics'].each do |metric|
  met = {}
  met["redis.#{metric}"] = { value: data[metric], source: params['source'] }
  puts "Reporting #{metric} as #{data[metric]}"
  Librato::Metrics.submit met
end
