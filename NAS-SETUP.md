# jefflill: This describes my UGREEN/UNRAID NAS setup

* UGREEN DXP4800 Plus
* 2x Samsung 990 EVP Plus 1TB Nvme
* 4x Seagate IronWolf Pro 30 TB Drives
* 512 GB Samsung USB-A thumbdrive

I decided to go with UNRAID as the operating system because
I wanted ZFS for bitrot protection.  I needed the **Unleashed**
edition due to having 7 I/O devices (the unused Nvme with the
original UGREEN OS counts as one).

1. Create a ""UNRAID.com** account and purchase licence

2. Download the UNRAID OS and follow instructions to
   configure the USB thumbdrive

3. Plug the USB Drive into the back USB 3.2 port to
   keep the front port available for backup drives.

3. Hook up a keyboard and monitor to the NAS.

4. Power up the NAS and continuously press CTRL+F12
   until you have a chance to go into BIOS Setup.

   a. Disable watchdog timer
   b. Disable boot from all devices except the USB drive.
   c. Make USB drive first boot priority
   d. Set the main system fan to MANUAL mode (my disks
      were on the verge of overheating without this)
   e. Save and reboot

5. By default, the NAS will named **tower**.  Open a browser
   to http://tower using **root** and go through the
   process of applying your UNRAID license and setting
   the root password.

6. In the WebUI, goto **SETTINGS/IDENTIFICATION** and update]
   the server name as required

7. Configure the 2 Nvme cards as a **Btrfs RAID1** pool
   named **cache**

8. Configure the 4 drives as a **ZFS** pool named **main-storage**

9. Create a user account (e.g. "jeff") with password

10. Configure the desired shares on **main-storage**:

    a. Set primary storage as **Cache**
    b. Minimum free space to **50MB** or maybe double the size
       of the largest file you'll be writing to the share
    c. Set secondary storage as **main-storage**
    d. Mover action: **Cache --> Main-storage**
    e. Export: **yes** (as required)
    d. Security: **private** when exporting
    e. Grant your user account **R/W access**

11. Click on the top **Main-storage** link on the **DASHBOARD**** or 
    **MAIN**** page and configure weekly **SCRUB**  for Sunday 4am.

12. Install **Community Applications** app

13. Install **Unraid Connect** app and then configure your
    **connect.myunraid.net** account to backup your USB
    drive.  Configure it to **AUTOSTART**.

14. Install **Intel GPU TOP** plugin (used for debugging
    custom **checkrr** GPU settings.

15. Create alias Bash scripts in **/usr/bin** for:
    
    ```
    gpu-top --> intel_gpu_top "$@"
    ll      --> ls -lh "$@"
    ```

16. Install **binhex-plex** app, with these host to container
    mappings.
    
    NOTE: We only want to map the media folders for security.
          There's no reason to give Plex access to non-media
          shares like [data].

    ```
    /mnt/user/appdata/binhex-plex --> /config        (read/write)
    /mnt/main-storage/music       --> /media/music   (read-only)
    /mnt/main-storage/movie       --> /media/movie   (read-only)
    /mnt/main-storage/new         --> /media/new     (read-only)
    /mnt/main-storage/photos      --> /media/photos  (read-only)
    /mnt/main-storage/test        --> /media/test    (read-only)
    /mnt/main-storage/tv          --> /media/tv      (read-only)
    /mnt/main-storage/youtube     --> /media/youtube (read-only)
    ```

    Configure **Plex Docker container** to **AUTOSTART**
    
    Use Plex UI to create your libraries off of the local
    **/main-storage/*** folders and configure other settings.

17. **Settings:**

    a. (APC) **UPS Settings:** configure as required
    b. **Disk Settings:** Default spin down delay **never**
    c. **Identification:** Rename server as required
    d. **Network Settings:** Configure static IP as required
    e. **Schedule Settings:** Mover schedule=**hourly**,
       Trim schedule=**disabled**
    f. **Power mode:** **Best performance**
    
18. Configure static IP
 
    a. Goto Network Settings
    b. Configure the IP address, gateway, subnet mask and DNS
       (8.8.8.8 and 8.8.4.4)
    d. Reboot NAS
     
19. I configured **nas.lill.io** DNS to point to the static
    address so I can manage it with my phone on the local network.

20. Install my customized **checkrr** app from 
    https://github.com/jefflill/checkrr and 
    **ghcr.io/jefflill/checkrr:latest**.  This version
    uses **ffmpeg** to fully scan media files for
    better corruption detection.

    a. Install the **checkrr** app and configure it to **AUTOSTART**
    b. Go to the **Docker** tab and edit **checkrr**

       i. Change the **repository** to **ghcr.io/jefflill/checkrr:latest**

       ii. Configure Docker host/container path mappings.
       ```
       /mnt/main-storage/no-media      --> /no-media                            (read-only)
       /mnt/user/appdata/binhex-plex   --> /config                              (read/write)
     
       /mnt/main-storage/music         --> /mnt/main-storage/music              (read-only)
       /mnt/main-storage/movie         --> /mnt/main-storage/movie              (read-only)
       /mnt/main-storage/new           --> /mnt/main-storage/new                (read-only)
       /mnt/main-storage/photos        --> /mnt/main-storage/photos             (read-only)
       /mnt/main-storage/test          --> /mnt/main-storage/test               (read-only)
       /mnt/main-storage/tv            --> /mnt/main-storage/tv                 (read-only)
       /mnt/main-storage/video-capture --> /mnt/main-storage/video-capture      (read-only)
       ```
     
       **NOTE:** The **no-media** mapping is not actually scraped, we need this so that
                 **checkrr** won't have access to all of the shares.

       iv. Add the device mapping: **/dev/dri:/dev/dri** and name
           it **Devices**.

      Here's my config file on the host NAS at:
      **/mnt/main-storage/appdata/checkrr/config/checkrr.yaml**
      ```
      lang: "en-us"
      checkrr:
      checkpath: 
        - "/media/movie/"
        - "/media/music/"
        - "/media/new/"
        # - "/media/photos"
        # - "/media/test"
        - "/media/tv/"
      database: /etc/checkrr/checkrr.db
      debug: false
      csvfile: "/etc/checkrr/badfiles.csv"
      cron: "@daily"
      # ffmpegArgs: "-hwaccel vaapi"
      ignorehidden: true
      requireaudio: true
      ignorepaths:
      removevideo:
      removelang:
      removeaudio:
      ignoreexts:
        - .txt
        - .nfo
        - .nzb
        - .url
        - .ini
        - .db
        - .lnk
      webserver:
        port: 8585
        tls: false
        certs:
          cert: "/path/to/cert.pem"
          key: "/path/to/privkey.pem"
      baseurl: "/"
      trustedproxies:
        - 127.0.0.1
      logs:
        stdout:
          out: stdout
          formatter: default
      ```

21. Install the **Disk Location** app and then goto 
    **Tools/Dish Location** to configure it.  I configured
    2 row and 4 columns formatted as 300x150px with the
    first row displaying the spinning drives (so the drive
    numbers will match the external trays) and the second
    row displaying the Nvme cache drives.

    I also configured the trays to display text as white.

22. Install **NoIP** app:

    a. Enable **AUTOSTART**

    b. **NoIP** will create a config file at:

       **/mnt/user/appdata/NoIp/noip.conf** to look like:
       ```
       USERNAME='your login'
       PASSWORD='your password'
       DOMAINS='your domains (coma separated)'
       INTERVAL=30m
       ```

       NOTE: There should be no space between the interval
             amount and the trailing unit character.

    c. Edit the config file to add your noip.com credentials
       and host name.

    d. Restart the **NoIP** app.

23. Install the **User Scripts** and **Enhanced User Scripts** plugins.

NOTE: I was able to get hardware acceleration going in the scan
      on my DXP4800 Plus but doing that was actually THREE TIMES SLOWER
      than just using the CPU, so this is disabled by default.

      You can enable HW acceleration by uncommeting this line
      in the [checkrr.yaml] config file.

      # ffmpegArgs: "-hwaccel vaapi"

24. Configure the **video-capture** user and share.

25. Wireguard setup: https://docs.unraid.net/unraid-os/manual/security/vpn/
 
    a. **NOTE:** I have **NoIP.com** dynamic DNS service configured 
       with a **lill-home.ddns.net** **A** record that will map to
       my home's IP address.
    
    b. Add a **CNAME** record to GoDaddy that maps:
     
       ```
       CNAME: home.lill.io --> home.lill.io
       ``` 
     
    c. Follow the instructions in the link above:
    
       * Peer access: Remote access to server
       * Generate server public/private keys
       * Local endpoint: **home.lill.io:51820**
       * Add peer and generate peer public/private and shared keys
       * Save keys and network endpoint info to 1Password
       * Click the eyeball icon for the new peer, take a snapshot
         of the configuration and save it to 1Password
       * Make the new tunnel **ACTIVE** and enable **AUTOSTART**
       * Install Wireguard app on iPhone and then snap the QRCode 
         in the app to configure Wireguard peer.

         **NOTE:** 
         Xfinity routers don't support loopback so you'll 
         need to temporarily disable WiFi on the iPhone
         for this to work.

26. Configure Plex pass GPU pass-thru:

    https://www.reddit.com/r/UgreenNASync/comments/1dn5c1q/gpu_passthrough_working_on_plex/

    * Install **PortainerCE** app (configure **AUTOSTART** on)

    **NOTE:** 
    Plex pass only supports Nvideo GPUs and the UGREEN box only has 
    a low-power Intel CPU integrated GPU.  So, this won't work without
    an upgrade.
 
    I went aheade and installed **PortainerCE** anyway since it
    looks useful.
     
27. After configuring everything, I relocated the boot USB drive
    to a USB 2.0 port to free up the USB 3.2 port for a backup
    drive and I've heard this might make the USB drive more
    reliable.
 