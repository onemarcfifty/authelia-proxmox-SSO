# authelia-proxmox-SSO

![language](https://img.shields.io/github/languages/top/onemarcfifty/authelia-proxmox-SSO)    ![License](https://img.shields.io/github/license/onemarcfifty/authelia-proxmox-SSO)    ![Last Commit](https://img.shields.io/github/last-commit/onemarcfifty/authelia-proxmox-SSO)     ![FileCount](https://img.shields.io/github/directory-file-count/onemarcfifty/authelia-proxmox-SSO)    ![Stars](https://img.shields.io/github/stars/onemarcfifty/authelia-proxmox-SSO)    ![Forks](https://img.shields.io/github/forks/onemarcfifty/authelia-proxmox-SSO)

Automated install for Authelia running in a container e.g. on Proxmox

You can use this repository in order to run an automated installation of Authelia into e.g. a Proxmox Container. If you want to run it in Proxmox, do the following:

1. Create a _privileged_ container
2. Give it 2 GB of RAM, 2 Cores, 8 GB of Disk (might be oversized)

The container needs to be privileged because it needs the `/dev/random` and/or `/dev/urandom` devices.

In order to install, open a shell on th container and type (as root)
```bash
wget https://raw.githubusercontent.com/onemarcfifty/authelia-proxmox-SSO/main/deploy_authelia.sh ; bash ./deploy_authelia.sh
```

## editing the config files

In order to edit the config files, you could use nano or vi. However, editing yaml Files in those editors is quite a challenge because you need to take care of proper indentation etc. Another possibility is to use WinSCP or FileZilla and connect over ssh or sftp to the container, and then edit with your favorite editor (e.g. Visual Studio).

To enable root password login over ssh in order to edit the files type
```bash
sed -i s/^\#PermitRootLogin\ prohibit-password$/PermitRootLogin\ yes/ /etc/ssh/sshd_config 
systemctl restart ssh
```

You can later change this back by typing
```bash
sed -i s/^PermitRootLogin\ yes/PermitRootLogin\ prohibit-password/ /etc/ssh/sshd_config 
systemctl restart ssh
```

## Watch the video on YouTube

The necessary changes to the config files and how to implement SSO are outlined in [This video](https://youtu.be/FMMCLt9TM2U). In the video we implement SSO for 

- Nextcloud
- Proxmox
- Portainer
- Gitea

## More resources

The [Authelia Documentation](https://www.authelia.com/integration/openid-connect/introduction/) shows how to integrate OpenID Connect (OIDC) with various software platforms

