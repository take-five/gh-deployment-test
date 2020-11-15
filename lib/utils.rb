# frozen_string_literal: true

class Utils
  def self.fetch_env_var!(var_name)
    ENV.fetch(var_name) { abort("Environment variable #{var_name} must be set") }
  end

  def self.deep_set(hash, path, value)
    current = hash

    path.each do |part|
      current[part] ||= {}
    end

    current[part] = value
  end
end
