component 'puppet-runtime' do |pkg, settings, platform|
  pkg.version '201801020'
  tarball_name = "agent-runtime-master-#{pkg.get_version}.#{platform.name}.tar.gz"

  pkg.sha1sum "http://builds.puppetlabs.lan/puppet-runtime/#{pkg.get_version}/artifacts/#{tarball_name}.sha1"
  pkg.url "http://builds.puppetlabs.lan/puppet-runtime/#{pkg.get_version}/artifacts/#{tarball_name}"

  pkg.install_only true

  # -k (keep-old-files or ignore-existing) is included in the rsync options so that the contents of the runtime's
  # /var directory don't clobber those of the build host (notably /var/run/sshd/)
  if platform.is_windows?
    # We need to make sure we're setting permissions correctly for the executables
    # in the ruby bindir since preserving permissions in archives in windows is
    # ... weird, and we need to be able to use cygwin environment variable use
    # so cmd.exe was not working as expected.
    install_command = [
      "gunzip -c #{tarball_name} | tar -C /cygdrive/c/ -xf -",
      "chmod 755 #{settings[:ruby_bindir].sub(/C:/, '/cygdrive/c')}/*"
    ]
  elsif platform.is_macos?
    # We can't untar into '/' because of SIP on macos; Just copy the contents of these directories instead:
    install_command = [
      "tar -xzf #{tarball_name}",
      "for f in opt var private; do rsync -ka \"$f/\" \"/$f/\"; done"
    ]
  else
    install_command = ["gunzip -c #{tarball_name} | #{platform.tar} -k -C / -xf -"]
  end

  pkg.install do
    install_command
  end
end
