source 'https://rubygems.org'
gemspec

# Set PADRINO_PATH to a padrino-framework checkout to test against it.
if ENV['PADRINO_PATH']
  %w[padrino-support padrino-core padrino-helpers].each do |name|
    gem name, :path => File.join(ENV['PADRINO_PATH'], name)
  end
end
