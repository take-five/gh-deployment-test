# frozen_string_literal: true

require 'json'
require 'yaml'

# Parses JSON or YAML input document, tries to auto-detect the format.
class DocumentParser
  ParseError = Class.new(StandardError)

  JSON_DOCUMENT_MARKERS = %w({ [).freeze

  def self.parse(input)
    new(input).document
  end

  def initialize(input)
    @input = input.to_s.strip
  end

  def document
    if json?
      JSON.parse(@input)
    else
      YAML.safe_load(@input)
    end
  rescue JSON::ParserError, Psych::Exception => e
    raise ParseError, e.message
  end

  private

  def json?
    JSON_DOCUMENT_MARKERS.any? { |marker| @input.start_with?(marker) }
  end
end
