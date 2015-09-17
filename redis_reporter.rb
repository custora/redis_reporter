require 'rubygems'
require 'bundler/setup'

require 'librato/metrics'
require 'yaml'

info = `/usr/local/bin/redis-cli INFO`

data = {}
info.split("\n").each do |line|
  if line =~ /(\w+):keys=(\d+),expires=(\d+),avg_ttl=(\d+)/
    data['keys'] ||= {}
    data['expires'] ||= {}
    data['avg_ttl'] ||= {}
    database = $1
    data['keys'][database] = $2.to_i
    data['expires'][database] = $3.to_i
    data['avg_ttl'][database] = $4.to_i
  elsif line =~ /\w+:\w+/
    parts = line.split(':')
    data[parts[0].strip] = parts[1].strip
  end
end

params = YAML.load(File.open(ARGV[0], 'r').read)

Librato::Metrics.authenticate params['librato']['user'], params['librato']['token']

params['metrics'].each do |metric|
  if data[metric].is_a?(Hash)
    data[metric].each do |db, value|
      source = "#{params['source']}.#{db}"
      met = {}
      met["redis.#{metric}"] = { value: value, source: source }
      puts "Reporting #{metric} as #{data[metric]} for source #{source}"
      Librato::Metrics.submit met
    end
  else
    met = {}
    met["redis.#{metric}"] = { value: data[metric], source: params['source'] }
    puts "Reporting #{metric} as #{data[metric]}"
    Librato::Metrics.submit met
  end
end
