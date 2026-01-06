Vagrant.configure(2) do |config|
  config.vm.boot_timeout = 600
  
  # Disable auto updating VirtualBox Guest Additions
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
    config.vbguest.no_remote = true
  end

  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_architecture = "amd64" # amd64(Windows), arm64(Mac)
  config.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=700,fmode=700"] # ディレクトリのアクセス権の設定は必須

  # Install Ansible
  config.vm.provision "shell", inline: <<-SHELL
    apt update
    apt install software-properties-common
    add-apt-repository --yes --update ppa:ansible/ansible
    apt install -y ansible
  SHELL
end
