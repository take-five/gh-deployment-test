#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'octokit'
require 'optparse'

require_relative './lib/utils'
require_relative './lib/document_parser'
require_relative './lib/deployment'

# 1. Parse arguments
environment = ''

OptionParser.new do |opts|
  opts.banner = <<~USAGE
    This program verifies that provided Kubernetes Deployment manifest has a corresponding
    GitHub Deployment record for given repo, environment and commit sha.

    If provided manifest is correct the program exits with code=0, otherwise it prints
    the error and exits with code=1.

    Usage: #{$0} -e ENVIRONMENT [FILE]
  USAGE

  opts.on('-e ENVIRONMENT', '--environment ENVIRONMENT',
          'Expected GitHub Deployment environment name') do |value|
    environment = value.strip
  end

  opts.on('-h', '--help', 'Print this message and exit') do
    abort(opts.to_s)
  end
end.parse!

abort("You must specify environment. Run #{$0} with -h flag.") if environment.empty?

access_token = Utils.fetch_env_var!('GITHUB_ACCESS_TOKEN')

# 2. Validate manifests
client = Octokit::Client.new(access_token: access_token)

begin
  # TODO: support multi-document manifests
  document = DocumentParser.parse(ARGF.read)
  deployment = Deployment.new(document)

  gh_deployments = client.deployments(
    deployment.repo,
    sha: deployment.sha,
    environment: environment
  )

  if gh_deployments.empty?
    abort "Could not find deployment for #{deployment.repo}@#{deployment.sha} (#{environment})"
  end
rescue DocumentParser::ParseError, Deployment::InvalidDeployment => e
  abort "Invalid Deployment manifest: #{e.message}"
end
