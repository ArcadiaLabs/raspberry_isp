#!/bin/bash

cd /tmp

doBackup() {
  cd $1
  echo -n " $2: "
  if [ -f $2.bak ]; then
    echo "Backup of $2 exists, not overwriting"
  else
    mv $2 $2.bak
    mv /tmp/raspberry_isp/$2 .
    echo "OK"
  fi
}

echo "Setting up Raspberry Pi to make Arduino work with GPIO"
echo "and allow ATmega chips to be programmed."
echo ""
echo "Checking ..."
echo -n "  System updates: "
apt-get -y update
apt-get -y dist-upgrade
echo "OK"

echo -n "  Arduino IDE: "
if [ ! -f /usr/share/arduino/hardware/arduino/programmers.txt ]; then
  apt-get -y install arduino
fi
echo "OK"

echo -n "  Avrdude GPIO version: "
fgrep -sq GPIO /etc/avrdude.conf
if [ $? != 0 ]; then
  wget http://project-downloads.drogon.net/gertboard/avrdude_5.10-4_armhf.deb
  dpkg -i avrdude_5.10-4_armhf.deb
  chmod 4755 /usr/bin/avrdude
fi
echo "OK"

echo -n "  Arduino auto-reset hack: "
if [ ! -f /usr/bin/avrdude-autoreset ]; then
  wget https://github.com/CaptainStouf/avrdude-rpi/archive/master.zip
  sudo unzip master.zip
  cd /tmp/avrdude-rpi-master/
  cp autoreset /usr/bin
  cp avrdude-autoreset /usr/bin
  mv /usr/bin/avrdude /usr/bin/avrdude-original
  ln -s /usr/bin/avrdude-autoreset /usr/bin/avrdude
  chmod 755 /usr/bin/avrdude-autoreset
  chmod 755 /usr/bin/autoreset
fi
echo "OK"

cd /usr/share/arduino/hardware/arduino
echo "Fetching/replacing files:"
for file in boards.txt programmers.txt ; do
  echo "  $file"
  #doBackup /usr/share/arduino/hardware/arduino $file
  mv /usr/share/arduino/hardware/arduino/$file /usr/share/arduino/hardware/arduino/$file.bak
  mv /tmp/raspberry_isp/$file /usr/share/arduino/hardware/arduino
done

echo "Replacing/updating files:"

cd /etc
echo -n "  /etc/inittab: "
if [ -f inittab.bak ]; then
  echo "Backup exists: not overwriting"
else
  cp -a inittab inittab.bak
  sed -e 's/^.*AMA0.*$/#\0/' < inittab > /tmp/inittab.$$
  mv /tmp/inittab.$$ inittab
  echo "OK"
fi

cd /boot
echo -n "  /boot/cmdline.txt: "
if [ -f cmdline.txt.bak ]; then
  echo "Backup exists: not overwriting"
else
  cp -a cmdline.txt cmdline.txt.bak
  cat cmdline.txt					|	\
		sed -e 's/console=ttyAMA0,115200//'	|	\
		sed -e 's/console=tty1//'		|	\
		sed -e 's/kgdboc=ttyAMA0,115200//' > /tmp/cmdline.txt.$$
  mv /tmp/cmdline.txt.$$ cmdline.txt
  echo "OK"
fi

echo -n "  ttyAMA0 to ttyS8 mapping: "
if [ ! -f /etc/udev/rules.d/99-tty.rules ]; then
  echo 'KERNEL=="ttyAMA0", SYMLINK+="ttyS8",GROUP="dialout",MODE:=0666' >> /etc/udev/rules.d/99-tty.rules
  echo 'KERNEL=="ttyACM0", SYMLINK+="ttyS9",GROUP="dialout",MODE:=0666' >> /etc/udev/rules.d/99-tty.rules
fi
echo "OK"

#doBackup /usr/share/arduino/hardware/arduino boards.txt
#doBackup /usr/share/arduino/hardware/arduino programmers.txt

echo "All Done."
echo "Check and reboot now to apply changes."
exit 0

