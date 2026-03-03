# Raspberry Pi Hostname: project-if-rpi.local
# Username: pi
# Password: ???


# Create a shareable directory from the Raspberry Pi:
# note, add samba to startup script(?)


# install samba
sudo apt install samba samba-common-bin

# make a directory that can't be deleted called shared
sudo mkdir -m 1777 /pic_shared

# append folder info to the samba config file
echo "[pic_shared]
path = /pic_shared
writeable = yes
browseable = yes
create mask = 0777
directory mask = 0777
public = no" >> /etc/samba/smb.conf

# set password (add user, if user already exists, type in new password, press enter for old password)
sudo smbpasswd -a pi

sudo systemctl restart smbd