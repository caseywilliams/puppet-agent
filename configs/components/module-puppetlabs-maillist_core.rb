component "module-puppetlabs-maillist_core" do |pkg, settings, platform|
  pkg.load_from_json("configs/components/module-puppetlabs-maillist_core.json")

  pkg.build_requires "module-puppetlabs-mailalias_core"

  instance_eval File.read("configs/components/_base-module.rb")
end
