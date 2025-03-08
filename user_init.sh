#!/bin/bash
# Allow bkenks to run sudo without password and set the file permissions
sh -c "echo 'bkenks ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/bkenks"
chmod 440 /etc/sudoers.d/bkenks

# SSH keys for bkenks
mkdir -p /home/bkenks/.ssh
sh -c "echo '<insert-the-ssh-ed25519-here>' > /home/bkenks/.ssh/authorized_keys"
chown -R bkenks:bkenks /home/bkenks/.ssh/
chmod 644 /home/bkenks/.ssh/authorized_keys
chmod 700 /home/bkenks/.ssh/
