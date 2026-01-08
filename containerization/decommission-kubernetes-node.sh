#!/bin/bash

#---------------------------------------------------------------------------------------
#  Decommission Kuberenetes node and clean up host by removing all relevant files, 
#  directories, packages, and configuration artifacts.  Ideally, run this script after:
#    
#  sudo systemctl disable containerd.service && sudo systemctl disable kubelet.service
#
#  And then a full host reboot, such that no Kubernetes related processes are loaded 
#  in memory during script execution.  One use for this script is when you intend 
#  to re-deploy Kubernetes on the host, and prefer a clean slate before reinstalling 
# --------------------------------------------------------------------------------------

# Silence non-critical errors
exec 2>/dev/null

# Packages to remove
packages=(kubeadm kubectl kubelet containerd.io container.io kubernetes-cni)

# Directories and files to remove
dirs=(
    /etc/cni
    /etc/containerd
    /etc/kubernetes
    /var/lib/containerd
    /var/lib/etcd
    /var/lib/kubelet
    /var/log/pods
    /var/log/containers/*
    /opt/cni
    /opt/containerd
    "$HOME/.kube"
)

files=(
    /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    /etc/apt/sources.list.d/kubernetes.list
    /etc/default/kubelet
    /etc/apt/trusted.gpg.d/docker.gpg
    /etc/sysctl.d/kubernetes.conf
    /etc/apt/sources.list.d/archive_uri-https_download_docker_com_linux_ubuntu-jammy.list
)

# Remove files
echo "Clearing files..."
for file in "${files[@]}"; do
    [ -f "$file" ] && rm -f "$file" &>/dev/null
done
find /var/log -type f -iname "*.gz" -exec rm -f {} \; &>/dev/null
find /var/log -type f -regextype egrep -regex "/var/log/.*\.[0-9]" -exec rm -f {} \; &>/dev/null
echo "Files cleared successfully."

# Remove directories
echo "Clearing directories..."
for dir in "${dirs[@]}"; do
    rm -rf "$dir" &>/dev/null
done
echo "Directories cleared successfully."

# Remove packages only if installed
echo "Removing Kubernetes packages..."
for pkg in "${packages[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
        apt-mark unhold "$pkg" &>/dev/null
        apt remove -y -qq "$pkg" &>/dev/null
        apt purge -y -qq "$pkg" &>/dev/null
    fi
done

# Autoremove orphaned packages quietly
apt autoremove -y -qq &>/dev/null
echo "Kubernetes removed. System cleaned up successfully."

