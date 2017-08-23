#!/usr/bin/env python

#CIS bits inspired and copyright by Ross Hamilton. (See: https://github.com/rosshamilton1/cissec/blob/master/centos7-cis.ks)

install
lang en_GB.UTF-8
keyboard us
timezone Europe/Amsterdam
auth --useshadow --passalgo=sha512
selinux --{{ item.selinux | default('disabled') }}
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
{% for part in item.partitions %}
{% endfor %}
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
-setroubleshoot     # CIS 1.4.4
-mcstrans     # CIS 1.4.5
-telnet       # CIS 2.1.2
-rsh-server       # CIS 2.1.3
-rsh        # CIS 2.1.4
-ypbind       # CIS 2.1.5
-ypserv       # CIS 2.1.6
-tftp       # CIS 2.1.7
-tftp-server      # CIS 2.1.8
-talk       # CIS 2.1.9
-talk-server      # CIS 2.1.10
-xinetd       # CIS 2.1.11
-xorg-x11-server-common   # CIS 3.2
-avahi-daemon     # CIS 3.3
-cups       # CIS 3.4
-dhcp       # CIS 3.5
-openldap     # CIS 3.7
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
sshd_config='/etc/ssh/sshd_config'
sed -i "s/\#Protocol/Protocol/" ${sshd_config}        # CIS 6.2.1
sed -i "s/\#LogLevel/LogLevel/" ${sshd_config}        # CIS 6.2.2
chown root:root ${sshd_config}            # CIS 6.2.3
chmod 600 ${sshd_config}            # CIS 6.2.3
sed -i "s/X11Forwarding yes/X11Forwarding no/" ${sshd_config}   # CIS 6.2.4
sed -i "s/\#MaxAuthTries 6/MaxAuthTries 4/" ${sshd_config}    # CIS 6.2.5
sed -i "s/\#IgnoreRhosts yes/IgnoreRhosts yes/" ${sshd_config}    # CIS 6.2.6
sed -i "s/\#HostbasedAuthentication no/HostbasedAuthentication no/" ${sshd_config}  # CIS 6.2.7
sed -i "s/\#PermitRootLogin yes/PermitRootLogin no/" ${sshd_config} # CIS 6.2.8
sed -i "s/\#PermitEmptyPasswords no/PermitEmptyPasswords no/" ${sshd_config}  # CIS 6.2.9
sed -i "s/\#PermitUserEnvironment no/PermitUserEnvironment no/" ${sshd_config}  # CIS 6.2.10
line_num=$(grep -n "^\# Ciphers and keying" ${sshd_config} | cut -d: -f1)
sed -i "${line_num} a Ciphers aes128-ctr,aes192-ctr,aes256-ctr" ${sshd_config}  # CIS 6.2.11
sed -i "s/\#ClientAliveInterval 0/ClientAliveInterval 300/" ${sshd_config}  # CIS 6.2.12
sed -i "s/\#ClientAliveCountMax 3/ClientAliveCountMax 0/" ${sshd_config}  # CIS 6.2.12
#sed -i "s/\#Banner none/Banner \/etc\/issue\.net/" ${sshd_config}     # CIS 6.2.12
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

### Harden NTP ----
ntp_conf='/etc/ntp.conf'
sed -i "s/^restrict default/restrict default kod/" ${ntp_conf}
line_num="$(grep -n "^restrict default" ${ntp_conf} | cut -f1 -d:)"
sed -i "${line_num} a restrict -6 default kod nomodify notrap nopeer noquery" ${ntp_conf}
sed -i s/'^OPTIONS="-g"'/'OPTIONS="-g -u ntp:ntp -p \/var\/run\/ntpd.pid"'/ /etc/sysconfig/ntpd

### run updates ----
/usr/bin/yum -y remove NetworkManager
/usr/bin/yum -y update  >> /root/post_update.log

# Install AIDE                # CIS 1.3.1
echo "0 5 * * * /usr/sbin/aide --check" >> /var/spool/cron/root
#Initialise last so it doesn't pick up changes made by the post-install of the KS
/usr/sbin/aide --init -B 'database_out=file:/var/lib/aide/aide.db.gz'

%end
