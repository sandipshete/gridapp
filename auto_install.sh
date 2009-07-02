#!/bin/bash

echo "Starting auto installation script"

id > temp_file
TEMP=`cat temp_file |  awk 'BEGIN{FS="("}; { print $1 }'`
TEMP1=`echo $TEMP |  awk 'BEGIN{FS="="}; { print $2 }'`
if [ $TEMP1 -ne 0 ]
then
	echo "Permission denied! Please run in supervisor mode"
	exit 1
fi


ping google.com -c 1
if [ $? -ne 0 ]
then
	echo "Internet connectivity not available... Aborting installation"
	exit $?
fi


echo "deb http://us.archive.ubuntu.com/ubuntu/ jaunty-backports main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb-src http://us.archive.ubuntu.com/ubuntu/ jaunty-backports main restricted universe multiverse" >> /etc/apt/sources.list
apt-get update
apt-get upgrade

for pkg in $(cat install_packages.list); do
	echo; echo Processing package $pkg...
	apt-get -y install --force-yes $pkg
done

echo "Preparing to install Condor..."
mkdir /opt/condor
chown griduser:griduser -R /opt/condor/
mkdir /tmp/condor

file  `ls | grep condor` | grep directory > temp_file
CONDOR_TGZ=`cat temp_file |  awk 'BEGIN{FS=":"}; { print $1 }'`
rm -f temp_file
tar -xzf $CONDOR_TGZ

file  `ls | grep condor` | grep directory > temp_file
CONDOR_DIR=`cat temp_file |  awk 'BEGIN{FS=":"}; { print $1 }'`
rm -f temp_file
cd $CONDOR_DIR
./condor_install --prefix=/opt/condor --local-dir=/tmp/condor --type=execute,submit
cd ..

wget http://www.grid-appliance.org/files/packages/ipop.deb
dpkg --install ipop.deb
dpkg --install ipop.deb

mkdir /etc/condor
ln -s /usr/local/ipop/etc/condor_config /etc/condor/condor_config
chmod 777 /etc/condor/condor_config
mkdir /mnt/fd
chmod 770 /mnt/fd
chown root:users /mnt/fd


cp fdb.img /usr/local/ipop/
sudo mount -t ext2 -o loop /usr/local/ipop/fdb.img /mnt/fd/

sudo bash
echo "/usr/local/ipop/fdb.img  /mnt/fd ext2    rw,loop 0       0" >> /etc/fstab
exit


