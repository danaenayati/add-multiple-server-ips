#!/bin/bash

# Update and upgrade the system packages
sudo apt update && sudo apt upgrade -y

# Prompt the user for network configuration details
read -p "Enter the MAC address (e.g., fa:16:3e:65:84:0c): " macaddress
read -p "Enter the IP address (e.g., 5.34.192.194): " your_ip
read -p "Enter the subnet (e.g., 22): " subnet
read -p "Enter the gateway (e.g., 5.34.192.1): " gateway

# Generate the netplan configuration file
cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml
network:
    version: 2
    ethernets:
        eth0:
            dhcp4: true
            match:
                macaddress: ${macaddress}
            mtu: 1500
            set-name: eth0
            addresses:
              - ${your_ip}/${subnet}
            routes:
              - to: 0.0.0.0/0
                via: ${gateway}
                table: 100
            routing-policy:
              - from: ${your_ip}
                table: 100
                priority: 100
EOF

# Apply the netplan configuration
sudo netplan apply

# Display the network interfaces
ip -br -c a
