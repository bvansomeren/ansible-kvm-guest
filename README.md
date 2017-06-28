bvansomeren.kvm-guest
=====================

Ansible role that will set up CentOS 6 and 7 virtuals to an existing KVM hypervisor (bvansomeren.kvm) and optionally ZFS (bvansomeren.zfs)

Requirements
------------

Linux with KVM and ZFS installed. Currently only tested with CentOS 6 and 7. ZFS is optional.
Uses the virt-installer tool in combination with kickstart to install.

Role Variables
--------------

Many..

Dependencies
------------

See requirements. Still building those roles.

Example Playbook
----------------

This is a big fat todo on my side, but this should work:


    - hosts: all
      remote_user: root
      roles:
      - role: bvansomeren.kvm-guest
        kvm_vms: "{{ vms }}"

With the following variables:

     default_nameservers:
     - 8.8.8.8
     - 8.8.4.4

     default_support_user:
       username: "blah blah"
       crypted_password: $6$<stuff>
       sshkeys:
       - "ssh-rsa public key string here"
     
     vms:
     - name: vm1
       vcpu: 4
       memory: 2048
       swap: 1024
       root: 32768
       interfaces:
       - device: eth0
         ip: 10.1.1.1
         netmask: 255.255.255.0
         public_gateway: 10.1.1.254
         bridge: br1-wan
         nameservers: "{{ default_nameservers }}"
       - device: eth1
         ip: 172.16.1.1
         netmask: 255.255.255.0
         bridge: br2-dmz
       - device: eth2
         ip: 172.17.1.1
         netmask: 255.255.255.0
         bridge: br3-mgmt
         user: "{{ default_support_user }}"
         crypted_rootpassword: $6$<stuff>
         os: "{{ kvm_guest_centos6 }}"
     - name: vm2
       vcpu: 4
       memory: 2048
       swap: 1024
       root: 32768
       interfaces:
       - device: eth0
         ip: 10.1.1.2
         netmask: 255.255.255.0
         public_gateway: 10.1.1.254
         bridge: br1-wan
         nameservers: "{{ default_nameservers }}"
       - device: eth1
         ip: 172.16.1.2
         netmask: 255.255.255.0
         bridge: br2-dmz
       - device: eth2
         ip: 172.17.1.2
         netmask: 255.255.255.0
         bridge: br3-mgmt
       user: "{{ default_support_user }}"
       crypted_rootpassword: $6$<stuff>
       os: "{{ kvm_guest_centos6 }}" 

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
