#!/bin/bash

# Function to prompt for user input and store it in a variable
prompt_input() {
    local prompt_text="$1"
    local input_variable
    read -p "$prompt_text" input_variable
    echo "$input_variable"
}

# Get the number of interfaces
num_interfaces=$(prompt_input "Enter the number of network interfaces: ")

# Initialize arrays to hold the network details
declare -a mac_addresses
declare -a ip_addresses
declare -a gateways

# Loop to collect MAC addresses, IP addresses and gateways for each interface
for ((i = 0; i < num_interfaces; i++)); do
    mac_addresses[i]=$(prompt_input "Enter the MAC address for eth$i: ")
    ip_addresses[i]=$(prompt_input "Enter the IP address for eth$i: ")
    gateways[i]=$(prompt_input "Enter the gateway for eth$i: ")
done

# Create the netplan configuration file
cat <<EOL | sudo tee /etc/netplan/01-netcfg.yaml
network:
    version: 2
    ethernets:
EOL

# Loop to append the details of each interface to the configuration file
for ((i = 0; i < num_interfaces; i++)); do
    cat <<EOL | sudo tee -a /etc/netplan/01-netcfg.yaml
        eth$i:
            dhcp4: true
            match:
                macaddress: ${mac_addresses[i]}
            mtu: 1500
            set-name: eth$i
            addresses:
              - ${ip_addresses[i]}/22
            routes:
              - to: 0.0.0.0/0
                via: ${gateways[i]}
                table: $((100 * (i + 1)))
            routing-policy:
              - from: ${ip_addresses[i]}
                table: $((100 * (i + 1)))
                priority: $((100 * (i + 1)))
EOL
done

# Apply the new network configuration
sudo netplan apply

# Verify the IPs
ip -br -c a
