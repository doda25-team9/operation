# -*- mode: ruby -*-
# vi: set ft=ruby :

# Configuration variables
# These value can be changed to scale the cluster or adjust resources

NUM_WORKERS = 2              # Number of worker nodes (change to scale cluster)
CONTROLLER_MEMORY = 4096     # Controller RAM in MB (4GB)
CONTROLLER_CPUS = 1          # Controller CPU cores
WORKER_MEMORY = 6144         # Worker RAM in MB (6GB)
WORKER_CPUS = 2              # Worker CPU cores

# Vagrant configuration
# This block configures all VMs for the Kubernetes cluster

Vagrant.configure("2") do |config|
  
  # Controller VM (ctrl)
  
  config.vm.define "ctrl" do |ctrl|
    # Use Ubuntu 24.04 as base operating system
    ctrl.vm.box = "bento/ubuntu-24.04"
    
    # Set hostname inside the VM
    ctrl.vm.hostname = "ctrl"
    
    # VirtualBox-specific configuration
    ctrl.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-ctrl"                # Name shown in VirtualBox GUI
      vb.memory = CONTROLLER_MEMORY       # Allocate RAM
      vb.cpus = CONTROLLER_CPUS           # Allocate CPU cores
    end
  end
  
  # Worker VMs (node-1, node-2, ...)

  # This loop creates NUM_WORKERS worker VMs automatically
  (1..NUM_WORKERS).each do |i|
    # Define worker VM with sequential numbering (node-1, node-2, etc.)
    config.vm.define "node-#{i}" do |node|
      node.vm.box = "bento/ubuntu-24.04"
      
      # Set hostname with number (node-1, node-2, etc.)
      node.vm.hostname = "node-#{i}"
      
      # VirtualBox-specific configuration
      node.vm.provider "virtualbox" do |vb|
        vb.name = "k8s-node-#{i}"
        vb.memory = WORKER_MEMORY
        vb.cpus = WORKER_CPUS
      end
    end
  end
  
end
