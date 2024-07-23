#!/bin/bash

# Update and upgrade the system packages
sudo apt update && sudo apt upgrade -y

# Install necessary Python packages
sudo apt install -y python3-pip
pip3 install beautifulsoup4 pandas selenium webdriver-manager netifaces fake-useragent requests pytz

# Prompt the user for the number of IP addresses
read -p "Enter the number of IP addresses: " ip_count

# Initialize arrays to store IP address, subnet, gateway, and MAC address information
declare -a macaddresses
declare -a ip_addresses
declare -a subnets
declare -a gateways

# Loop to collect network configuration details for each interface
for (( i=0; i<ip_count; i++ ))
do
    read -p "Enter MAC address for eth$i (e.g., fa:16:3e:65:84:0c): " mac
    read -p "Enter IP address for eth$i (e.g., 5.34.192.194): " ip
    read -p "Enter subnet for eth$i (e.g., 22): " subnet
    read -p "Enter gateway for eth$i (e.g., 5.34.192.1): " gateway
    
    macaddresses+=($mac)
    ip_addresses+=($ip)
    subnets+=($subnet)
    gateways+=($gateway)
done

# Generate the netplan configuration file
cat <<EOF | sudo tee /etc/netplan/50-cloud-init.yaml
network:
    version: 2
    ethernets:
EOF

# Add configuration for each interface to the configuration file
for (( i=0; i<ip_count; i++ ))
do
    table=$((100 + 100 * i))
    priority=$((100 + 100 * i))

    cat <<EOF | sudo tee -a /etc/netplan/50-cloud-init.yaml
        eth$i:
            dhcp4: true
            match:
                macaddress: ${macaddresses[$i]}
            mtu: 1500
            set-name: eth$i
            addresses:
              - ${ip_addresses[$i]}/${subnets[$i]}
            routes:
              - to: 0.0.0.0/0
                via: ${gateways[$i]}
                table: $table
            routing-policy:
              - from: ${ip_addresses[$i]}
                table: $table
                priority: $priority
EOF
done

# Apply the netplan configuration
sudo netplan apply

# Display the network interfaces
ip -br -c a

# Display the SSH access message
echo "You can now access the server via SSH using the IP address configured for eth0: ${ip_addresses[0]}"
