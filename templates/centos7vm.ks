#!/usr/bin/env python

#CIS bits inspired and copyright by Ross Hamilton. (See: https://github.com/rosshamilton1/cissec/blob/master/centos7-cis.ks)

install
lang en_GB.UTF-8
keyboard us
timezone Europe/Amsterdam
auth --useshadow --passalgo=sha512
selinux --disabled
firewall --enabled
services --enabled=sshd

{% for interface in item.interfaces %}
network --bootproto=static --device={{ interface.device }} --ip={{ interface.ip }} --netmask={{ interface.netmask }} {% if interface.public_gateway is defined %} --gateway={{ interface.public_gateway }} {% endif %} {% if interface.nameservers is defined %} {% for nameserver in interface.nameservers %} --nameserver={{ nameserver }} {% endfor %} {% endif %}

{% endfor %}

eula --agreed
ignoredisk --only-use=vda,vdb
reboot

bootloader --location=mbr --boot-drive=vda 
zerombr
clearpart --all --initlabel
part swap --asprimary --fstype="swap" --onpart=vdb
part /boot --fstype xfs --size=300
part pv.01 --size=1 --grow
volgroup {{ item.name }}vg pv.01
logvol / --fstype xfs --name=lv01 --vgname={{ item.name}}vg --size=1 --grow

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
aide        # CIS 1.3.1
setroubleshoot-server
ntp       # CIS 3.6
tcp_wrappers      # CIS 4.5.1
rsyslog       # CIS 5.1.1
cronie-anacron      # CIS 6.1.2
%end
%post --log=/root/postinstall.log

# Disable mounting of unneeded filesystems CIS 1.1.18 - 1.1.24
cat << EOF >> /etc/modprobe.d/CIS.conf
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install squashfs /bin/true
install udf /bin/true
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
EOF

rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7  # CIS 1.2.1

cat << EOF >> /etc/sysctl.conf
fs.suid_dumpable = 0          # CIS 1.6.1 
kernel.randomize_va_space = 2       # CIS 1.6.2
net.ipv4.ip_forward = 0         # CIS 4.1.1
net.ipv4.conf.all.send_redirects = 0      # CIS 4.1.2
net.ipv4.conf.default.send_redirects = 0    # CIS 4.1.2
net.ipv4.conf.all.accept_source_route = 0   # CIS 4.2.1
net.ipv4.conf.default.accept_source_route = 0   # CIS 4.2.1
net.ipv4.conf.all.accept_redirects = 0      # CIS 4.2.2
net.ipv4.conf.default.accept_redirects = 0    # CIS 4.2.2
net.ipv4.conf.all.secure_redirects = 0      # CIS 4.2.3
net.ipv4.conf.default.secure_redirects = 0    # CIS 4.2.3
net.ipv4.conf.all.log_martians = 1      # CIS 4.2.4
net.ipv4.conf.default.log_martians = 1      # CIS 4.2.4
net.ipv4.icmp_echo_ignore_broadcasts = 1    # CIS 4.2.5
net.ipv4.icmp_ignore_bogus_error_responses = 1    # CIS 4.2.6
net.ipv4.conf.all.rp_filter = 1       # CIS 4.2.7
net.ipv4.conf.default.rp_filter = 1     # CIS 4.2.7
net.ipv4.tcp_syncookies = 1       # CIS 4.2.8
net.ipv6.conf.all.accept_ra = 0       # CIS 4.4.1.1
net.ipv6.conf.default.accept_ra = 0       # CIS 4.4.1.1
net.ipv6.conf.all.accept_redirect = 0     # CIS 4.4.1.2
net.ipv6.conf.default.accept_redirect = 0   # CIS 4.4.1.2
net.ipv6.conf.all.disable_ipv6 = 1      # CIS 4.4.2
EOF

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
