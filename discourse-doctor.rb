#!/usr/bin/env ruby
# coding: utf-8

Dir.chdir("/") do
  require 'bundler/inline'
  require 'net/http'
  require 'net/smtp'
  require 'pathname'

  gemfile(true, ui: false) do
    source 'https://rubygems.org'

    gem 'dnsruby'
    gem 'paint'
    gem 'sys-filesystem' # for checking available disk space
  end

  require 'sys/filesystem'
  include Sys
end

DISCOURSE_PATH = Pathname.new("/var/www/discourse")

def log(level, message)
  $stderr.puts("#{level} #{message}")
end

def warning(message)
  log(Paint['warning', :yellow], message)
end

def error(message, log = nil)
  log(Paint['error', :red], message)
  exit(1)
end

def info(message)
  log(Paint['info', :green], message)
end

def check_env_var(var)
  if ENV[var].nil? || ENV[var].empty?
    error("#{var} is blank, edit containers/app.yml variables")
  end
end

def check_smtp_config
  info("Check SMTP configuration...")

  check_env_var("DISCOURSE_SMTP_ADDRESS")
  check_env_var("DISCOURSE_SMTP_PORT")
  check_env_var("DISCOURSE_SMTP_USER_NAME")
  check_env_var("DISCOURSE_SMTP_PASSWORD")

  begin
    Net::SMTP.start(ENV["DISCOURSE_SMTP_ADDRESS"], ENV["DISCOURSE_SMTP_PORT"])
             .auth_login(ENV["DISCOURSE_SMTP_USER_NAME"], ENV["DISCOURSE_SMTP_PASSWORD"])
  rescue Exception => e
    error("Couldn’t connect to SMTP server: #{e}")
  end
end

def grep_logs
  info("Search logs for errors...")

  system("grep -E -w \"error|warning\" #{DISCOURSE_PATH.join("log/production.log")} | sort | uniq -c | sort -r")
end

def check_hostname
  info("Perform checks on the hostname...")

  check_env_var("DISCOURSE_HOSTNAME")

  begin
    resolver = Dnsruby::Resolver.new
    request = resolver.query(ENV["DISCOURSE_HOSTNAME"], Dnsruby::Types.TXT)
    answers = request.answer.map(&:to_s)

    if answers.select { |a| a.include?("spf") }.empty?
      warning("Please check SPF is correctly configured on this domain")
    end

    if answers.select { |a| a.include?("dkim") }.empty?
      warning("Please check DKIM is correctly configured on this domain")
    end
  rescue Dnsruby::NXDomain => e
    error("Non-existent Internet Domain Names Definition (NXDOMAIN) for: #{ENV["DISCOURSE_HOSTNAME"]}")
  end

  url = URI.parse("http://downforeveryoneorjustme.com/#{ENV["DISCOURSE_HOSTNAME"]}")
  request = Net::HTTP.new(url.host, url.port)
  result = request.request_get(url.path)
  if result.body.include?("It's not just you")
    error("The internets can’t reach: #{ENV["DISCOURSE_HOSTNAME"]}")
  end
end

def check_plugins
  unofficial_plugins = []

  base_plugins = %w(
    discourse-details
    discourse-narrative-bot
    discourse-nginx-performance-report
    lazyYT
    poll
  )

  Dir.chdir("plugins") do
    plugins = Dir.glob('*') - base_plugins
    plugins.each do |plugin|
      url = URI.parse("https://github.com/discourse/#{plugin}")
      request = Net::HTTP.new(url.host, url.port)
      request.use_ssl = true
      result = request.request_head(url.path)
      if result.code == "404"
        unofficial_plugins << plugin
      end
    end
  end

  unless unofficial_plugins.empty?
    warning("If you encounter issues, you might want to consider disabling these unofficial plugins: #{unofficial_plugins.join(',')}")
  end
end

def check_available_disk_space
  stat = Filesystem.stat(DISCOURSE_PATH.to_s)
  bytes_available = stat.blocks_available * stat.block_size
  if bytes_available < 10 * 1024
    warning("The available disk space at #{DISCOURSE_PATH} is less than 10MB")
  end
end

check_smtp_config
check_hostname
check_plugins
check_available_disk_space
grep_logs
