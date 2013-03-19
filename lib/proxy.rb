module Proxy
  MODULES = %w{dns dhcp tftp puppetca puppet bmc}
  GEMS = %W{dns dhcp bmc}
  VERSION = "1.1"

  require "checks"
  require "proxy/settings"
  require "fileutils"
  require "pathname"
  require "rubygems" if USE_GEMS # required for testing
  require "proxy/log"
  require "proxy/util"
  require "proxy/tftp"     if SETTINGS.tftp
  require "proxy/puppetca" if SETTINGS.puppetca
  require "proxy/puppet"   if SETTINGS.puppet

  # These pieces of the proxy have been abstracted out.
  GEMS.each do |gem|
    require "foreman-proxy-#{gem}" if SETTINGS.gem && Proxy::Util.proxy_gem_installed?(gem)
  end

  def self.features
    MODULES.collect{|mod| mod if SETTINGS.send mod}.compact
  end

  def self.version
    {:version => VERSION}
  end

end
