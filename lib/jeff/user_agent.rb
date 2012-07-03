module Jeff
  module UserAgent
    USER_AGENT = begin
      hostname = `hostname`.chomp
      engine   = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
      language = [engine, RUBY_VERSION, "p#{RUBY_PATCHLEVEL}"].join ' '

      "Jeff/#{VERSION} (Language=#{language}; Host=#{hostname})"
    end
  end
end
