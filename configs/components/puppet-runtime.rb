component 'puppet-runtime' do |pkg, settings, platform|
  pkg.version '201802020'
  tarball_name = "agent-runtime-1.10.x-#{pkg.get_version}.#{platform.name}.tar.gz"

  pkg.sha1sum "http://builds.puppetlabs.lan/puppet-runtime/#{pkg.get_version}/artifacts/#{tarball_name}.sha1"
  pkg.url "http://builds.puppetlabs.lan/puppet-runtime/#{pkg.get_version}/artifacts/#{tarball_name}"

  # The contents of the runtime replace the following:
  pkg.replaces 'pe-augeas'
  pkg.replaces 'pe-openssl'
  pkg.replaces 'pe-ruby'
  pkg.replaces 'pe-ruby-mysql'
  pkg.replaces 'pe-rubygems'
  pkg.replaces 'pe-libyaml'
  pkg.replaces 'pe-libldap'
  pkg.replaces 'pe-ruby-ldap'
  pkg.replaces 'pe-ruby-augeas'
  pkg.replaces 'pe-ruby-selinux'
  pkg.replaces 'pe-ruby-shadow'
  pkg.replaces 'pe-ruby-stomp'
  pkg.replaces 'pe-rubygem-deep-merge'
  pkg.replaces 'pe-rubygem-net-ssh'

  pkg.install_only true

  if platform.is_cross_compiled_linux? || platform.is_solaris? || platform.is_aix?
    pkg.build_requires 'runtime'
  end

  # Even though puppet's ruby comes from puppet-runtime, we still need a ruby
  # to build with on these platforms:
  if platform.architecture == "sparc"
    if platform.os_version == "10"
      # ruby1.8 is not new enough to successfully cross-compile ruby 2.1.x (it
      # doesn't understand the --disable-gems flag)
      pkg.build_requires 'ruby20'
    elsif platform.os_version == "11"
      pkg.build_requires 'pl-ruby'
    end
  elsif platform.is_cross_compiled_linux?
    pkg.build_requires 'pl-ruby'
  end

  if platform.is_windows?
    # We need to make sure we're setting permissions correctly for the executables
    # in the ruby bindir since preserving permissions in archives in windows is
    # ... weird, and we need to be able to use cygwin environment variable use
    # so cmd.exe was not working as expected.
    install_command = [
      "gunzip -c #{tarball_name} | tar -k -C /cygdrive/c/ -xf -",
      "chmod 755 #{settings[:ruby_bindir].sub(/C:/, '/cygdrive/c')}/*"
    ]
  elsif platform.is_macos?
    # We can't untar into '/' because of SIP on macOS; Just copy the contents
    # of these directories instead:
    install_command = [
      "tar -xzf #{tarball_name}",
      "for d in opt var private; do rsync -ka \"$${d}/\" \"/$${d}/\"; done"
    ]
  else
    install_command = ["gunzip -c #{tarball_name} | #{platform.tar} -k -C / -xf -"]
  end

  pkg.install do
    install_command
  end
end
