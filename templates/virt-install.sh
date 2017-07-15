#!/bin/bash
/usr/bin/virt-install \
    --name {{ item.name }} \
    --ram {{ item.memory }} \
{% if kvm_zfs %}
    --disk /dev/{{ zfs_pool }}/{{ item.name }}/root,bus=virtio,cache=none \
    --disk /dev/{{ zfs_pool }}/{{ item.name }}/swap,bus=virtio,cache=none \
{% else %}
    --disk path=/{{ kvm_image_location }}/{{ item.name }}-root.img,size={{ item.root }},bus=virtio,cache=none \
    --disk path=/{{ kvm_image_location }}/{{ item.name }}-swap.img,size={{ item.swap }},bus=virtio,cache=none \
{% endif %}
    --vcpus {{ item.vcpu }} \
    --os-type {{ item.os.ostype }} \
    --os-variant {{ item.os.osvariant }} \
{% for interface in item.interfaces %}
    --network bridge={{ interface.bridge }},model=virtio \
{% endfor %}
    --graphics none \
    --console pty,target_type=serial \
    --location '{{ item.os.repo_base_url }}' \
    --initrd-inject="{{ ksroot }}/{{ item.name }}-ks.ks" \
    --extra-args 'console=ttyS0,115200n8 serial ks=file:/{{ item.name }}-ks.ks'
