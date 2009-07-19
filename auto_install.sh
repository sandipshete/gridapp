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
apt-get upgrade -y

for pkg in $(cat install_packages.list); do
	echo; echo Processing package $pkg...
	apt-get -y install --force-yes $pkg
done

echo "Preparing to install Condor..."
mkdir /opt/condor
chown griduser:griduser -R /opt/condor/
mkdir /tmp/condor
chown griduser:griduser -R /tmp/condor/

file  `ls | grep condor` | grep compressed > temp_file
CONDOR_TGZ=`cat temp_file |  awk 'BEGIN{FS=":"}; { print $1 }'`
rm -f temp_file
tar -xzf $CONDOR_TGZ

file  `ls | grep condor` | grep directory > temp_file
CONDOR_DIR=`cat temp_file |  awk 'BEGIN{FS=":"}; { print $1 }'`
rm -f temp_file
cd $CONDOR_DIR
./condor_install --prefix=/opt/condor --local-dir=/tmp/condor --type=execute,submit --owner=griduser
cd ..

wget "http://www.acis.ufl.edu/~yonggang/packages/ipop_8.0-1ubuntu9.04_i386.deb"
dpkg --install ipop_8.0-1ubuntu9.04_i386.deb

echo Y > yes
dpkg --install --force-overwrite --force-conflicts gridapp-config_0.2-1_i386.deb < yes
rm yes

mkdir /etc/condor
ln -s /usr/local/ipop/etc/condor_config /etc/condor/condor_config
chmod 777 /etc/condor/condor_config
mkdir /mnt/fd
chmod 770 /mnt/fd
chown root:users /mnt/fd

cp fdb.img /usr/local/ipop/
mount -t ext2 -o loop /usr/local/ipop/fdb.img /mnt/fd/

cp System.Runtime.Remoting.dll /usr/lib/mono/2.0/

mkdir /root/.ssh/
echo "/usr/local/ipop/fdb.img  /mnt/fd ext2    rw,loop 0       0" >> /etc/fstab
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtm6sRRyw4hMTCMdcOJJu6UYmXuAr5RCwf/YhbfwG+Jiw3FFi2hlJwPWSEvFM7BjFL8SDz+lHqawpEuQCRCYbg+qchQ+fcPJsw057WEDUVBifuQt3i9fg1GLdN/8vAXPm0Nen+MEHMyV6peSU3IF5+D1qF4FwJzRRdHt0/zPy8BF+E9qyBDGQEILhx5RmcexMsXgj5iJ9xO3YrCcDyJI32komO5iuSPidraf1Sfl48caZUecQBxU9QU+IPApKa/NYhMkmWJ1wPmiJ/vAzjROY6/tYrAGDwYMRvCiDQg/3mPdQ8LJZdDBtXvRvpS2mD6igLcTfRX0Wr4k/p3jpqxBpqQ== griduser@localhost" >> /root/.ssh/authorized_keys
mkdir /home/griduser/.ssh/
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtm6sRRyw4hMTCMdcOJJu6UYmXuAr5RCwf/YhbfwG+Jiw3FFi2hlJwPWSEvFM7BjFL8SDz+lHqawpEuQCRCYbg+qchQ+fcPJsw057WEDUVBifuQt3i9fg1GLdN/8vAXPm0Nen+MEHMyV6peSU3IF5+D1qF4FwJzRRdHt0/zPy8BF+E9qyBDGQEILhx5RmcexMsXgj5iJ9xO3YrCcDyJI32komO5iuSPidraf1Sfl48caZUecQBxU9QU+IPApKa/NYhMkmWJ1wPmiJ/vAzjROY6/tYrAGDwYMRvCiDQg/3mPdQ8LJZdDBtXvRvpS2mD6igLcTfRX0Wr4k/p3jpqxBpqQ== griduser@localhost" >> /home/griduser/.ssh/authorized_keys
chown griduser:griduser /home/griduser/ -R


