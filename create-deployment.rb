#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'octokit'
require 'optparse'
require 'yaml'

require_relative './lib/utils'
require_relative './lib/document_parser'

environment = 'production'
ref = 'main'
manifest_file = nil

OptionParser.new do |opts|
  opts.banner = <<~USAGE
    This program creates a GitHub deployment for the given repository, ref and environment.
    Optionally, can inject github.com annotations into deployment manifest.

    Usage: #{$0} -e ENVIRONMENT -r ref REPO
  USAGE

  opts.on('-e', '--environment ENVIRONMENT',
          'Expected GitHub Deployment environment name. Default: production') do |value|
    environment = value
  end

  opts.on('-r', '--ref REF',
          'The ref to deploy. This can be a branch, tag, or SHA. Default: main.') do |value|
    ref = value
  end

  opts.on('-m', '--manifest PATH', 'Deployment manifest file to inject GitHub annotations into') do |value|
    manifest_file = value
  end

  opts.on('-h', '--help', 'Print this message and exit') do
    abort(opts.to_s)
  end
end.parse!

repo = ARGV.first&.strip || ''
abort('Repository name is missing') if repo.empty?

manifest = manifest_file && DocumentParser.parse(File.read(manifest_file))

access_token = Utils.fetch_env_var!('GITHUB_ACCESS_TOKEN')
client = Octokit::Client.new(access_token: access_token)

deployment = client.create_deployment(repo, ref, environment: environment)

if manifest
  # inject annotations into the manifest
  metadata = (manifest['metadata'] ||= {})
  annotations = (metadata['annotations'] ||= {})
  annotations['github.com/repo'] = repo
  annotations['github.com/sha'] = deployment.sha

  puts manifest.to_yaml
else
  puts <<~DOC
    Deployment created:
    - id: #{deployment.id}
    - url: #{deployment.url}
    - sha: #{deployment.sha}
    - environment: #{deployment.environment}
  DOC
end
