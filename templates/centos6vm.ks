install
lang en_GB.UTF-8
keyboard us
timezone Europe/Amsterdam
auth --useshadow --passalgo=sha512
selinux --disabled
firewall --disabled
services --enabled=sshd

{% for interface in item.interfaces %}
network --bootproto=static --device={{ interface.device }} --ip={{ interface.ip }} --netmask={{ interface.netmask }} {% if interface.public_gateway is defined %} --gateway={{ interface.public_gateway }} {% endif %} {% if interface.nameservers is defined %} {% for nameserver in interface.nameservers %} --nameserver={{ nameserver }} {% endfor %} {% endif %}

{% endfor %}

ignoredisk --only-use=vda,vdb
reboot

bootloader --location=mbr
zerombr
clearpart --all --initlabel
part swap --asprimary --fstype="swap" --onpart=vdb
part /boot --fstype ext4 --size=300
part pv.01 --size=1 --grow
volgroup {{ item.name }}vg pv.01
logvol / --fstype ext4 --name=lv01 --vgname={{ item.name}}vg --size=1 --grow

rootpw --iscrypted {{ item.crypted_rootpassword }}

repo --name=base --baseurl={{ item.os.repo_base_url }}
url --url="{{ item.os.url }}"

%packages --nobase --ignoremissing
@core
-*-firmware
sshd
wget
net-tools
curl
vim-minimal
vim-enhanced
qemu-guest-agent
unzip
deltarpm
yum-utils
yum-cron
%end

%post
#---- Disable SSH login for root and password login ----
/usr/bin/sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
/usr/bin/sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

#---- Create a support user ----

/usr/sbin/useradd -p {{ item.user.crypted_password }} {{ item.user.username }}

echo '{{ item.user.username }} ALL=(ALL)    NOPASSWD:ALL' >> /etc/sudoers

#---- Install our SSH key ----
mkdir -m0700 /home/{{ item.user.username }}/.ssh/

cat <<EOF >/home/{{ item.user.username }}/.ssh/authorized_keys
{% for sshkey in item.user.sshkeys %}
{{ sshkey }}
{% endfor %}
EOF

### set permissions ----
chmod 0600 /home/{{ item.user.username }}/.ssh/authorized_keys
chown -R {{ item.user.username }}:{{ item.user.username }} /home/{{ item.user.username }}/.ssh

### install epel ----

rpm -Uvh {{ item.os.extra_repo_url }} >> /root/post_update.log

### run updates ----
/usr/bin/yum -y remove NetworkManager
/usr/bin/yum -y update  >> /root/post_update.log
%end
