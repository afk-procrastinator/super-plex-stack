<div align="center">

# ⚡ SuperPlex ⚡

A comprehensive media server setup using Docker Compose, featuring Plex and various supporting services for content management, automation, and monitoring. Offers a minimal but fully functional setup, with the ability to add reverse proxies. 

![image](https://img.shields.io/badge/Docker-2CA5E0?style=for-the-badge&logo=docker&logoColor=white)
![image](https://img.shields.io/badge/Plex-EBAF00?style=for-the-badge&logo=plex&logoColor=white)

---

</div>

## 🚀 Services

### Core Services
- **[Plex](https://github.com/linuxserver/docker-plex/)**: Media server 
- **[Overseerr](https://github.com/linuxserver/docker-overseerr)**: Media request management system 
- **[Tautulli](https://github.com/linuxserver/docker-tautulli)**: Plex monitoring and statistics  *optional*
- **[Organizr](https://github.com/causefx/Organizr)**: Web-based dashboard  *optional*
- **[FileBrowser](https://github.com/filebrowser/filebrowser)**: Web file management interface  *optional*
- **[Dozzle](https://github.com/amir20/dozzle)**: Real-time docker log viewer *optional*

### Web & Network Services
- **[Nginx Proxy Manager](https://hub.docker.com/r/jc21/nginx-proxy-manager)**: Reverse proxy and SSL management *optional*
- **[qBittorrent](https://github.com/linuxserver/docker-qbittorrent)**: Torrent client
- **[Gluetun](https://github.com/qdm12/gluetun)**: VPN client container

### Media Management
- **[Radarr](https://github.com/linuxserver/docker-radarr)**: Movie collection manager 
- **[Sonarr](https://github.com/linuxserver/docker-sonarr)**: TV series collection manager 
- **[Prowlarr](https://github.com/linuxserver/docker-prowlarr)**: Indexer manager 
- **[Bazarr](https://github.com/linuxserver/docker-bazarr)**: Subtitle manager *optional*

> If you don't want to use any of the optional services, you can remove them from the `docker-compose.yml` file.

> :warning: **Warning:** This stack will not work out of the box. You'll need to do more configuration in the apps themselves. See the App Setup section below for more information. 

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

> This setup assumes that all the final data is stored in the same directory as `docker-compose.yml`. If you want more space/add more drives, you need to add them to the relevant `volumes` section for each service.

4. In the `.env` file, you need to set the following variables:
   - `TZ`: Your timezone (default: `America/New_York`)
   - `PUID`: User ID (default: 1000)
   - `PGID`: Group ID (default: 1000)
   - `OPENVPN_USERNAME`: VPN username
   - `OPENVPN_PASSWORD`: VPN password

> The stack uses Gluetun for VPN connectivity, which I have preconfigured for ProtonVPN but supports many other providers. You can see the full list of providers and the documentation for how to configure them [here](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers). 

5. Run `docker compose up -d` to start the stack.
6. Profit! After setting up the apps, of course. Add media via Overseerr (or by manually adding them to Radarr and Sonarr). See the App Setup section for more information, and use documentation for each app to finish setting them up.

### 🌐 Ngnix

> **Note:** This is optional, and only if you want to be able to access the services from outside your local network. You'll need a static IP and forward the necessary ngnix ports. 

1. Create an A record in your DNS provider pointing to your server's public IP address, with `overseerr` as the name.
2. In Ngnix, go to Hosts -> Proxy Hosts -> Add Proxy Host. Fill in the following: 
   1. Domain Names: `overseerr.mydomain.com`
   2. Scheme: `http`
   3. Forward Hostname/IP: `gluetun` (for VPN-protected services) or service name (for others)
   4. Forward Port: `5055` (use the service's port)
   5. Enable `Block Common Exploits` and `Websockets Support`
   6. Under SSL, select `Request New SSL Certificate`, `Force SSL`, and `HTTP/2 Support`.
3. **Be sure to secure any services you forward outside your network!** 

> **Important:** For services running through the VPN (Overseerr, Radarr, Sonarr, Prowlarr), use `gluetun` as the Forward Hostname/IP in Nginx Proxy Manager. These services are accessed through the gluetun container.

### 🛠️ App Setup

You'll need to do more configuration in the apps themselves to make sure that everything works. Here are some resources: 

- [TRaSH Guides](https://trash-guides.info/) — Radarr, Sonarr, Prowlarr, Plex
- [Servarr Documentation](https://wiki.servarr.com/) — Radarr, Sonarr, Prowlarr
- [docker-transmission-openvpn Documentation](https://haugene.github.io/docker-transmission-openvpn/)
- [Ngnix Documentation](https://nginxproxymanager.com/)
- [Gluetun Documentation for providers](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers)

The flow I find best is (in order of what to get working first): `Gluetun -> qBittorrent -> Prowlarr -> Sonarr/Radarr -> Plex`. Everything else can come after that. 

## 🌐 Default Local Access

| Service | URL | Notes |
|---------|-----|-------|
| Nginx Proxy Manager | [81](http://localhost:81) | Admin interface |
| Organizr | [9983](http://localhost:9983) | |
| Filebrowser | [8081](http://localhost:8081) | |
| qBittorrent | [8080](http://localhost:8080) | VPN Protected |
| Radarr | [7878](http://localhost:7878) | VPN Protected |
| Sonarr | [8989](http://localhost:8989) | VPN Protected |
| Plex | [32400](http://localhost:32400/web) | Host Network Mode |
| Overseerr | [5055](http://localhost:5055) | VPN Protected |
| Tautulli | [8181](http://localhost:8181) | |
| Prowlarr | [9696](http://localhost:9696) | VPN Protected |
| Bazarr | [6767](http://localhost:6767) | |
| Dozzle | [9999](http://localhost:9999) | |

> 🔐 Services marked as "VPN Protected" run through the Gluetun VPN container, meaning:
> - All their network traffic is routed through your VPN connection
> - They're only accessible through ports exposed by the Gluetun container
> - This protects these services from being directly exposed to the internet (aka they run through the VPN)
> - All of these can be accessed via localhost, but you'll need to set up a reverse proxy in Nginx Proxy Manager to access them from outside your network (see the section above).

## ✅ TODO

- [ ] Add a script to help users onboard (e.g. directories, what images they want)
- [ ] Add more services to support the stack (Recyclarr, Whisparr, Notifiarr)
- [x] Add documentation for Gluetun VPN configuration with other providers