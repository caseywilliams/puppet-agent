# This file is a basis for vendor modules that should be installed alongside
# puppet-agent in settings[:module_vendordir]. It should not be used as a
# component; Instead, other module components should load it using
# `instance_eval`. Here's an example:
#
# component "module-puppetlabs-stdlib" do |pkg, settings, platform|
#   pkg.version "4.25.1"
#
#   instance_eval File.read("configs/components/_base-module.rb")
# end
#
# Module components must be named with the following format:
#   module-<module-author>-<module-name>.rb
#
# No dependency resolution is attempted automatically; You must define separate
# vanagon components for each module and make their dependencies explicit.

unless defined?(pkg)
  raise "_base-module.rb is not a valid vanagon component; Load it with `instance_eval` in another component instead."
end

match_data = pkg.get_name.match(/module-([^-]+)-([^-]+)/)
unless match_data
  raise "module components must be named with the format `module-<module-author>-<module-name>.rb`"
end
module_author, module_name = match_data.captures

unless pkg.get_version
  raise "You must set a version for the #{module_author}-#{module_name} module."
end

module_slug = "#{module_author}-#{module_name}-#{pkg.get_version}"

# Fetch module metadata from the forge
require 'net/http'

uri = URI.parse("#{settings[:forge_api_baseurl]}/#{settings[:forge_api_version]}/releases/#{module_slug}")
api = Net::HTTP.new(uri.host, uri.port)
api.use_ssl = true if uri.scheme == "https"
res = api.get(uri.request_uri)
raise "Unable to fetch #{module_slug} release data from #{uri} (#{res.code})" unless res.code.to_i == 200
metadata = JSON.parse(res.body)

# Set vanagon component properites based on data from the forge
pkg.md5sum metadata["file_md5"]
pkg.url "#{settings[:forge_api_baseurl]}#{metadata['file_uri']}"

# "Installing" just means extracting this tarball to the vendored modules directory with the right name
tarball_name = metadata["file_uri"].split("/").last

pkg.install do
  [
    "mkdir -p #{settings[:module_vendordir]}",
    "gunzip -c #{tarball_name} | #{platform.tar} -C #{settings[:module_vendordir]} -xf -",
    "mv #{File.join(settings[:module_vendordir], module_slug)} #{File.join(settings[:module_vendordir], module_name)}",
  ]
end

# This is just a tarball; Skip unpack, patch, configure, build, check steps
pkg.install_only true

# Modules must have puppet
pkg.build_requires 'puppet'

# Ensure the vendored modules directory makes it into the package
pkg.directory(settings[:module_vendordir])
