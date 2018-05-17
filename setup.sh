#!/bin/bash

if [ "$(id -u)" != "0" ]; then
	dialog --backtitle "Permission Error" --title "Error" --msgbox "To install you need to be root." 0 0
	exit 1
fi
ip=`(hostname -I | awk '{print $1}')`
configpath=$(eval echo ~pi)"/.config";
ARCH=$(eval dpkg --print-architecture);
rm -R /tmp/NzbDrone*
rm -R /tmp/Radarr*
rm -R /tmp/cardigann*

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb https://download.mono-project.com/repo/debian stable-raspbianstretch main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
wget -O - https://dev2day.de/pms/dev2day-pms.gpg.key | apt-key add -
sudo echo "deb https://dev2day.de/pms/ jessie main" >> /etc/apt/sources.list.d/pms.list
sudo add-apt-repository ppa:deluge-team/ppa -y
sudo apt update
sudo apt-get install apt-transport-https libmono-cil-dev mediainfo sqlite3 software-properties-common -y --force-yes


# Plex Media Server
sudo apt-get install plexmediaserver-installer -y --force-yes
sudo mkdir -p "/etc/systemd/system/plexmediaserver.service.d"
sudo cp -i  ./files/plex.conf /etc/systemd/system/plexmediaserver.service.d/override.conf
sudo mkdir -p "/home/pi/Library/Application Support"
sudo chown -R pi:pi "/home/pi/Library/Application Support"
sudo systemctl daemon-reload
sudo systemctl restart plexmediaserver


# Install Sonarr
wget "http://update.sonarr.tv/v2/master/mono/NzbDrone.master.tar.gz" -P /tmp/
rm -R /opt/NzbDrone
tar -xf /tmp/NzbDrone* -C /opt/
sudo chown -R pi:pi /opt/NzbDrone
sudo cp -i  ./files/nzbdrone /etc/init.d/nzbdrone
sudo chmod +x /etc/init.d/nzbdrone
update-rc.d nzbdrone defaults 98
service nzbdrone start

# Install Radarr
#
wget "https://github.com/Radarr/Radarr/releases/download/v0.2.0.1067/Radarr.develop.0.2.0.1067.linux.tar.gz" -P /tmp/
rm -R /opt/Radarr
tar -xf /tmp/Radarr* -C /opt/
sudo chown -R pi:pi /opt/Radarr
sudo cp -i  ./files/radarr /etc/init.d/radarr
sudo chmod +x /etc/init.d/radarr
update-rc.d radarr defaults 98
service radarr start

# Install Cadigann
if [ "$ARCH" == "armhf" ] ||  [ "$ARCH" == "arm64" ]; then
	wget "https://bin.equinox.io/c/3u8U4iwUn6o/cardigann-stable-linux-arm.tgz" -P /tmp/
elif [ "$ARCH" == "i386" ] ; then
# Testing with Virtual Box
	wget "https://bin.equinox.io/c/3u8U4iwUn6o/cardigann-stable-linux-386.tgz" -P /tmp/
fi
mkdir -p /opt/cardigann
tar -xf /tmp/cardigann* -C /opt/cardigann
sudo chown -R pi:pi /opt/cardigann
sudo chmod +x /opt/cardigann/cardigann
sudo cp -i ./files/cardigann /etc/systemd/system/cardigann.service
systemctl enable cardigann
service cardigann start

# Install Deluge
sudo apt-get install deluged deluge-web deluge-console -ys
cp -i ./files/deluge /etc/init.d/deluge
chmod a+x /etc/init.d/deluge
update-rc.d deluge defaults
sudo -u pi deluged
sleep 10
sudo -u pi deluge-console "config -s allow_remote True"
cp -i ./files/deluge-web.conf "$configpath/deluge/web.conf"
echo "pi:welcome:10" >> "$configpath/deluge/auth"
chown pi:pi "$configpath/deluge/auth"
sleep 5
pkill -9 deluged
service deluge start


echo "--------------------------------"
echo "-----------COMPLETED------------"
echo "--------------------------------"
echo "Plex : http://$ip:32400"
echo "Sonarr : http://$ip:8989"
echo "Radarr : http://$ip:7878"
echo "Cardigann : http://$ip:5060 (default password is welcome)"
echo "Deluge: http://$ip:8112 (default password is deluge)"
echo "--------------------------------"