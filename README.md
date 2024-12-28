<div align="center">

# SuperPlex

---

A comprehensive media server setup using Docker Compose, featuring Plex and various supporting services for content management, automation, and monitoring.

![image](https://img.shields.io/badge/Docker-2CA5E0?style=for-the-badge&logo=docker&logoColor=white)
![image](https://img.shields.io/badge/Plex-EBAF00?style=for-the-badge&logo=plex&logoColor=white)

---

</div>

## 🚀 Services

### Core Services
- **[Plex](https://github.com/linuxserver/docker-plex/)**: Media server (port: 32400)
- **[Overseerr](https://github.com/linuxserver/docker-overseerr)**: Media request management system (port: 5055)
- **[Tautulli](https://github.com/linuxserver/docker-tautulli)**: Plex monitoring and statistics (port: 8181) *optional*
- **[Organizr](https://github.com/causefx/Organizr)**: Web-based dashboard (port: 9983) *optional*
- **[FileBrowser](https://github.com/filebrowser/filebrowser)**: Web file management interface (port: 8080) *optional*

### Web & Network Services
- **[Nginx Proxy Manager](https://hub.docker.com/r/jc21/nginx-proxy-manager)**: Reverse proxy and SSL management (ports: 80, 81, 443) *optional*
- **[Transmission + OpenVPN](https://github.com/haugene/docker-transmission-openvpn/)**: Torrent client with VPN integration (port: 9091)

### Media Management
- **[Radarr](https://github.com/linuxserver/docker-radarr)**: Movie collection manager (port: 7878) 
- **[Sonarr](https://github.com/linuxserver/docker-sonarr)**: TV series collection manager (port: 8989)
- **[Prowlarr](https://github.com/linuxserver/docker-prowlarr)**: Indexer manager (port: 9696)

## 🛠️ Setup Instructions

Make sure you have [Docker](https://www.docker.com/) installed! These instructions are for just setting up the stack, you'll need to do more configuration in the apps (see the App Setup section below). 

### 📁 Directory Structure

1. Clone this repository to your desired location (or just manually make the `docker-compose.yml` file)
2. Create the following directory structure:
   ```
   .
   ├── config/
   │   └── ...
   ├── data/
   │   ├── downloads/
   │   │   ├── complete/
   │   │   ├── incomplete/
   │   │   └── watch/
   │   └── media/
   │       ├── movies/
   │       └── tv/
   ```

3. The config files are made automatically when Docker starts up, but you can also run:
   ```
   mkdir -p data data/downloads /data/media /data/media/movies /data/media/tv data/downloads/complete data/downloads/incomplete data/downloads/watch config
   ```

> **Note:** This setup assumes that all the final data is stored in the same directory as `docker-compose.yml`. If you want more space/add more drives, you need to add them to the relevant `volumes` section for each service.

### 🔒 Environment Variables

In the `.env` file, you need to set the following variables:

- `TZ`: Your timezone (default: `America/New_York`)
- `PUID`: User ID (default: 1000)
- `PGID`: Group ID (default: 1000)
- `OPENVPN_PROVIDER`: VPN provider (default: `custom`)
- `OPENVPN_CONFIG`: OpenVPN configuration file
- `OPENVPN_USERNAME`: OpenVPN username
- `OPENVPN_PASSWORD`: OpenVPN password

### 🔑 VPN

I use ProtonVPN as my provider, but the stack is compatible with any other VPN provider — you just need the OpenVPN configuration file and the username and password. Check [this page](https://haugene.github.io/docker-transmission-openvpn/) from the `docker-transmission-openvpn` project for more information on specific VPN provider configuration — some need custom `.sh` scripts and directories.

### 🌐 Ngnix

> **Note:** This is optional, and only if you want to be able to access the services from outside your local network (I personally have Overseerr, Tatutulli, and Organizr accessible). You'll need a static IP. 

1. Create an A record in your DNS provider pointing to your server's public IP address, with `overseerr` as the name.
2. In Ngnix, go to Hosts -> Proxy Hosts -> Add Proxy Host. Fill in the following: 
   1. Domain Names: `overseerr.mydomain.com`
   2. Scheme: `http`
   3. Forward Hostname/IP: `overseerr`
   4. Forward Port: `5055`
   5. Enable `Block Common Exploits` and `Websockets Support`
   6. Under SSL, select `Request New SSL Certificate`, `Force SSL`, and `HTTP/2 Support`.

### 🛠️ App Setup

You'll need to do more configuration in the apps themselves to make sure that everything works. Here are some resources: 

- [TRaSH Guides](https://trash-guides.info/) — Radarr, Sonarr, Prowlarr, Plex
- [Servarr Documentation](https://wiki.servarr.com/) — Radarr, Sonarr, Prowlarr
- [docker-transmission-openvpn Documentation](https://haugene.github.io/docker-transmission-openvpn/)
- [Ngnix Documentation](https://nginxproxymanager.com/)

## 🌐 Default Local Access

| Service | URL |
|---------|-----|
| Nginx Proxy Manager | [81](http://localhost:81) |
| Organizr | [9983](http://localhost:9983) |
| Filebrowser | [8081](http://localhost:8081) |
| Transmission | [9091](http://localhost:9091) |
| Radarr | [7878](http://localhost:7878) |
| Sonarr | [8989](http://localhost:8989) |
| Plex | [32400](http://localhost:32400/web) |
| Overseerr | [5055](http://localhost:5055) |
| Tautulli | [8181](http://localhost:8181) |
| Prowlarr | [9696](http://localhost:9696) |
