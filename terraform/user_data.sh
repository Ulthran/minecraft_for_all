#!/bin/bash
BACKUP_BUCKET="${BACKUP_BUCKET}"
yum update -y

# Create a 2 GB swap file
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile swap swap defaults 0 0' >> /etc/fstab


# Install Java 21 (directly from Amazon Corretto) (ARM64 to use t4g instance)
cd /tmp
#wget https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.rpm
#sudo yum localinstall -y amazon-corretto-21-x64-linux-jdk.rpm
wget https://corretto.aws/downloads/latest/amazon-corretto-21-aarch64-linux-jdk.rpm
yum localinstall -y amazon-corretto-21-aarch64-linux-jdk.rpm

sudo yum groupinstall -y "Development Tools"          
yum install -y wget unzip aws-cli cronie python3 nc git make gcc

mkdir -p /home/ec2-user/minecraft
sudo chmod -R 777 /home/ec2-user/minecraft
cd /home/ec2-user/minecraft

# Download Minecraft server
#wget https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar -O server.jar
#echo "eula=true" > eula.txt

# Dowload PaperMC server
wget https://api.papermc.io/v2/projects/paper/versions/1.21.4/builds/225/downloads/paper-1.21.4-225.jar -O paper.jar
echo "eula=true" > eula.txt

# Configure server.properties for RCON
echo "enable-rcon=true" >> server.properties
echo "rcon.password=minecraft" >> server.properties
echo "rcon.port=25575" >> server.properties
echo "allow-flight=true" >> server.properties

# Create systemd service
cat << EOF > /etc/systemd/system/minecraft.service
[Unit]
Description=Minecraft Server
After=network.target

[Service]
WorkingDirectory=/home/ec2-user/minecraft
ExecStart=java -Xms2G -Xmx2G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -jar paper.jar --nogui

StandardOutput=null
StandardError=null
Restart=always
User=ec2-user

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable minecraft
sudo systemctl start minecraft

# Install MC RCON
cd /tmp
git clone https://github.com/Tiiffi/mcrcon.git
cd mcrcon
make
sudo install mcrcon /usr/local/bin

# Install plugins
cd /home/ec2-user/minecraft/plugins
wget https://cdn.modrinth.com/data/fALzjamp/versions/SmZRkQyR/Chunky-Bukkit-1.4.36.jar
wget https://cdn.modrinth.com/data/s86X568j/versions/asaBBItO/ChunkyBorder-Bukkit-1.2.23.jar
wget https://github.com/ViaVersion/ViaVersion/releases/download/5.3.2/ViaVersion-5.3.2.jar
wget https://cdn.modrinth.com/data/p1ewR5kV/versions/Ypqt7eH1/unifiedmetrics-platform-bukkit-0.3.8.jar
wget https://github.com/EssentialsX/Essentials/releases/download/2.21.0/EssentialsX-2.21.0.jar

# Wait up to 60s for port 25575 to be ready
for i in {1..30}; do
nc -z 127.0.0.1 25575 && break
echo "Waiting for Minecraft server to start..."
sleep 2
done

# Configure plugins
mcrcon -H 127.0.0.1 -P 25575 -p minecraft "chunky radius 3000"
mcrcon -H 127.0.0.1 -P 25575 -p minecraft "chunky border add"
mcrcon -H 127.0.0.1 -P 25575 -p minecraft "chunky world the_nether"
mcrcon -H 127.0.0.1 -P 25575 -p minecraft "chunky shape circle"
mcrcon -H 127.0.0.1 -P 25575 -p minecraft "chunky spawn"
mcrcon -H 127.0.0.1 -P 25575 -p minecraft "chunky radius 1000"
mcrcon -H 127.0.0.1 -P 25575 -p minecraft "chunky border add"
mcrcon -H 127.0.0.1 -P 25575 -p minecraft "chunky world the_end"
mcrcon -H 127.0.0.1 -P 25575 -p minecraft "chunky border remove"

mcrcon -H 127.0.0.1 -P 25575 -p minecraft "chunky world the_overworld"
mcrcon -H 127.0.0.1 -P 25575 -p minecraft "chunky start"

# Create backup script
cat << 'EOB' > /home/ec2-user/minecraft/backup.sh
#!/bin/bash
TIMESTAMP=$(date +%F-%H-%M)
BACKUP_DIR="/home/ec2-user/minecraft_backup/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
cp -r /home/ec2-user/minecraft/world "$BACKUP_DIR"
cd /home/ec2-user/minecraft_backup
zip -r "world-$TIMESTAMP.zip" "$TIMESTAMP"
aws s3 cp "world-$TIMESTAMP.zip" s3://${BACKUP_BUCKET}/
rm -rf "$BACKUP_DIR" "world-$TIMESTAMP.zip"
EOB

sudo chmod +x /home/ec2-user/minecraft/backup.sh
sudo echo "0 3 * * * /home/ec2-user/minecraft/backup.sh" >> /var/spool/cron/root

# Create idle check script
cat << 'EOF' > /home/ec2-user/minecraft/idle-check.sh
#!/bin/bash

RCON_HOST="127.0.0.1"
RCON_PORT=25575
RCON_PASSWORD="minecraft"
TIME_FILE="/home/ec2-user/minecraft/last_seen_players"
IDLE_LIMIT_MINUTES=60

# Get the number of online players using mcrcon
get_online_players() {
mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" "list" | grep -oP '(?<=There are )\d+' || echo -1
}

main() {
now=$(date +%s)

players=$(get_online_players)

if [ "$players" -gt 0 ]; then
echo "$now" > "$TIME_FILE"
echo "Players online: $players"
exit 0
fi

if [ ! -f "$TIME_FILE" ]; then
echo "$now" > "$TIME_FILE"
exit 0
fi

last_seen=$(cat "$TIME_FILE")
idle_minutes=$(( (now - last_seen) / 60 ))

echo "Idle for $idle_minutes minutes"

if [ "$idle_minutes" -gt "$IDLE_LIMIT_MINUTES" ]; then
echo "No players for $IDLE_LIMIT_MINUTES+ minutes. Shutting down..."
mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" "save-all"
mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" "say Server is shutting down due to inactivity."
sleep 10
