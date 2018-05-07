component "module-puppetlabs-mailalias_core" do |pkg, settings, platform|
  pkg.version "1.0.2"

  instance_eval File.read("configs/components/_base-module.rb")
end
