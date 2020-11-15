# frozen_string_literal: true

require 'dry-schema'

# Kubernetes Deployment manifest object
class Deployment
  Schema = Dry::Schema.JSON do
    required(:apiVersion).filled(:string, eql?: 'apps/v1')
    required(:kind).filled(:string, eql?: 'Deployment')
    required(:metadata).hash do
      required(:annotations).hash do
        required(:'github.com/repo').filled(:string)
        required(:'github.com/sha').filled(:string)
      end
    end
  end

  InvalidDeployment = Class.new(StandardError)

  def initialize(data)
    result = Schema.call(data)

    if result.success?
      @data = result.to_h
    else
      raise InvalidDeployment, result.errors(full: true).to_h.values.join(', ')
    end
  end

  def repo
    annotation('github.com/repo')
  end

  def sha
    annotation('github.com/sha')
  end

  private

  def annotation(name)
    @data.dig(:metadata, :annotations, name.to_sym)
  end
end
