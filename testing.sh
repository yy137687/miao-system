#!/bin/bash

# Exit on any error
set -e

# Function to check if a command exists
command_exists () {
  type "$1" &> /dev/null
}

# Define log file
LOG_DIR="$HOME/miao-system"
LOG_FILE="$LOG_DIR/log-file.log"

# Create log directory if it doesn't exist
sudo mkdir -p $LOG_DIR
sudo chmod 777 $LOG_DIR

# Create or truncate the log file
: > $LOG_FILE

# Check if tcpdump is installed, if not install it
if ! command_exists tcpdump ; then
  echo "tcpdump not found. Installing..." | sudo tee -a $LOG_FILE
  sudo apt-get update
  sudo apt-get install -y tcpdump
fi

# Check if tshark is installed, if not install it
if ! command_exists tshark ; then
  echo "tshark not found. Installing..." | sudo tee -a $LOG_FILE
  sudo apt-get update
  sudo apt-get install -y tshark
fi

# Update and Upgrade
echo "Starting to update system..." | sudo tee -a $LOG_FILE
sudo apt-get update
sudo apt-get upgrade -y

echo "System update complete." | sudo tee -a $LOG_FILE

# Directory to save the capture and backup files
CAPTURE_DIR="/$HOME/miao-system/pcap_files"
CSV_DIR="/$HOME/miao-system/csv_files"
BACKUP_DIR="/$HOME/miao-system/backup_pcap_files"

# Make sure the directories exist
sudo mkdir -p $CAPTURE_DIR $CSV_DIR $BACKUP_DIR

# List of interfaces to capture on
INTERFACES=("eth0" "wlan0")

# Packet capture parameters
PACKET_COUNT=1000

ALL_SUCCESS=true

for INTERFACE in "${INTERFACES[@]}"; do
  PCAP="$CAPTURE_DIR/${INTERFACE}_traffic.pcap"
  CSV="$CSV_DIR/${INTERFACE}_traffic.csv"
  BACKUP="$BACKUP_DIR/${INTERFACE}_traffic_backup.pcap"

  # Capture packets
  if ! sudo tcpdump -i $INTERFACE -c $PACKET_COUNT -w "$PCAP"; then
    echo "Failed to capture packets on $INTERFACE." | sudo tee -a $LOG_FILE
    ALL_SUCCESS=false
    continue
  fi

  # Backup the PCAP file
  sudo cp $PCAP $BACKUP

  # Convert the PCAP to CSV format
  if ! tshark -r "$PCAP" -T fields -e ip.src -e ip.dst -E header=y -E separator=, > "$CSV"; then
    echo "Failed to convert PCAP to CSV for $INTERFACE." | sudo tee -a $LOG_FILE
    ALL_SUCCESS=false
  fi
done

if [ "$ALL_SUCCESS" = true ]; then
  echo "Data collection, backup, and conversion to CSV completed." | sudo tee -a $LOG_FILE
else
  echo "Some operations failed. Check the log for details." | sudo tee -a $LOG_FILE
fi

