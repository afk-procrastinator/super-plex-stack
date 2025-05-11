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
- **[Cleanuperr](https://github.com/flmorg/cleanuperr)**: Download queue management and cleanup tool *optional*

> If you don't want to use any of the optional services, you can remove them from the `docker-compose.yml` file.

> :warning: **Warning:** This stack will not work out of the box. You'll need to do more configuration in the apps themselves. See the App Setup section below for more information. 

## 🛠️ Setup Instructions

Make sure you have [Docker](https://www.docker.com/) installed! These instructions are for just setting up the stack, you'll need to do more configuration in the apps (see the App Setup section below). 

### 📁 Directory Structure

1. Clone this repository to your desired location (or just manually make the `docker-compose.yml` file). If you make the Docker file manually, you'll also need to make the `config` subdirectory in the same location. 
2. Create this directory structure wherever you want the *data* to be stored. The top directory can be called whatever you want per your storage system—remember to update the `.env` file, instructions below: 
   ```
   .
   ├── data/
   │   ├── downloads/
   │   │   ├── complete/
   │   │   └── incomplete/
   │   ├── movies/
   |   └── tv/
   ```
   
3. Run this command to make all the relevant directories wherever you want the stuff stored, *within* the top directory (per default settings, these would be in the `data` directory):
   ```
   mkdir -p downloads movies tv downloads/complete downloads/incomplete
   ```

4. In the `.env` file, you need to set the following variables:
   - `TZ`: Your timezone (default: `America/New_York`)
   - `PUID`: User ID (default: 1000)
   - `PGID`: Group ID (default: 1000)
   - `OPENVPN_USERNAME`: VPN username
   - `OPENVPN_PASSWORD`: VPN password
   - `DATA_ROOT`: Path to your data directory (default puts the data in the same directory as the `docker-compose.yml` file —  `./data`)
   And, if you're using Cleanuparr: 
   - `SONARR_API_KEY`: Sonarr API key (from settings)
   - `RADARR_API_KEY`: Radarr API key (from settings)
   - `BITTORRENT_USERNAME`: qBittorrent UI username
   - `BITTORRENT_PASSWORD`: qBittorrent UI password

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
- [Servarr documentation](https://wiki.servarr.com/) — Radarr, Sonarr, Prowlarr
- [docker-transmission-openvpn documentation](https://haugene.github.io/docker-transmission-openvpn/)
- [Ngnix documentation](https://nginxproxymanager.com/)
- [Gluetun documentation for providers](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers)
- [Cleanuperr documentation, if you're using it](https://flmorg.github.io/cleanuperr/docs/cleanuperr)

The flow I find best is (in order of what to get working first): `Gluetun -> qBittorrent -> Prowlarr -> Sonarr/Radarr -> Plex`. Everything else can come after that. 

#### Cleanuperr Configuration

Cleanuperr is configured to:
- Clean up stalled and slow downloads
- Block malicious content using the official blacklist
- Manage seeding times and ratios
- Automatically search for replacements when needed

Key features:
- Queue Cleaner runs every 5 minutes
- Content Blocker runs every 5 minutes
- Download Cleaner runs once per hour
- Maintains logs in `./config/cleanuperr/logs`
- Uses `./config/cleanuperr/ignored.txt` for ignored downloads

> **Note:** You'll need to create `./config/data/cleanuperr/ignored.txt` for Cleanuperr to work. 

Required environment variables:
- `QBITTORRENT_USERNAME`: qBittorrent username
- `QBITTORRENT_PASSWORD`: qBittorrent password
- `SONARR_API_KEY`: Sonarr API key
- `RADARR_API_KEY`: Radarr API key

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
| Cleanuperr | CLI only | |

> 🔐 Services marked as "VPN Protected" run through the Gluetun VPN container, meaning:
> - All their network traffic is routed through your VPN connection
> - They're only accessible through ports exposed by the Gluetun container
> - This protects these services from being directly exposed to the internet (aka they run through the VPN)
> - All of these can be accessed via localhost, but you'll need to set up a reverse proxy in Nginx Proxy Manager to access them from outside your network (see the section above).

## ✅ TODO

- [ ] Add a script to help users onboard (e.g. directories, what images they want)
- [ ] Add more services to support the stack (Recyclarr, Whisparr, Notifiarr)
- [x] Add documentation for Gluetun VPN configuration with other providers