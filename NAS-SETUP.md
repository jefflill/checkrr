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
    /mnt/main-storage/movies      --> /media/movies   (read-only)
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
    g. **Library:** Configure scanning schedule and generate
       preview thumbnails, chapter thumbnails, loudness,
       and markers.
    
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
       /mnt/main-storage/appdata/binhex-plex/Plex Media Server/ --> /config     (read/write)
     
       /mnt/main-storage/music         --> /mnt/main-storage/music              (read-only)
       /mnt/main-storage/movies        --> /mnt/main-storage/movies             (read-only)
       /mnt/main-storage/new           --> /mnt/main-storage/new                (read-only)
       /mnt/main-storage/no-media      --> /no-media                            (read-only)
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
        - .nra
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

    **NOTE:** I was able to get hardware acceleration going in the scan
    on my DXP4800 Plus but doing that was actually THREE TIMES SLOWER
    than just using the CPU, so this is disabled by default.

    You can enable HW acceleration by uncommeting this line
    in the [checkrr.yaml] config file.

    ```
    #ffmpegArgs: "-hwaccel vaapi"
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

27. Many of the apps are configured to keep their logs and other stuff 
    on the cache drive which is is running **btrfs** on the **Nvme** 
    drives.  This is a problem because **btrfs** is a **copy on write** 
    file system which will result in a lot of SSD wear (write amplification).
    The directory for this data is:

    ```
    /mnt/user/appdata
    ```
 
    This also keeps all of the app configuration on the **main-storage**
    array, so we should be able to just migrate to a new server by just
    moving the hard drives (since this is ZFS).
 
    Stop all apps, then for each app, you'll need to:
 
    a. Run the **Mover** to clear any transient files from the cache.
    
    b. Backup the **/mnt/user/appdata** folder to a temporary folder at
       **/mnt/main-storage/appdata-backup** for copying and just in case 
       we need to restore something.
    
       ```
       mkdir /mnt/main-storage/appdata-backup
       cp -r /mnt/user/appdata /mnt/main-storage/appdata-backup
       ```
    
    c. Copy the folders for the app from **/mnt/cache/appdata/APP-FOLDER**
       to **/mnt/main-storage/APP-FOLDER**
    
       **NOTE:** It's important that you **COPY** and not **MOVE**.  I
                 do this by copying from the backup folder.

       https://docs.unraid.net/unraid-os/manual/shares/user-shares/
    
       ```
       rm -r /mnt/user/appdata/APP-NAME
       cp -r /mnt/main-storage/appdata-backup/appdata/APP-FOLDER /mnt/main-storage/appdata/APP-FOLDER
       ```
        
    d. You may need to adjust the app's Docker host path mappings.

    e. Restart the app, check its logs, and verify that it's working.
     
    After confirming that all of the apps work, you should remove the 
    **appdata-backup** folder:

    ```
    rm -r /mnt/main-storage/appdata-backup
    ```
     
28. After configuring everything, I relocated the boot USB drive
    to a USB 2.0 port to free up the USB 3.2 port for a backup
    drive and I've heard this might make the USB drive more
    reliable.
 
===========================================================================
Backup script notes

https://forums.unraid.net/profile/1033-pauven/

* Install the **mergerFS for UNRAID** plug-in

* Format the drives as **exFAT (FAT64)**

* Label the drives **BACKUP-0** and **BACKUP-1**

* Connect the drives to the USB 3.2 ports and then use **blkid** to list
  the block devices like:

  ```
  /dev/sda1: LABEL_FATBOOT="UNRAID" LABEL="UNRAID" UUID="130B-130E" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="fd37e730-01"
  /dev/loop1: BLOCK_SIZE="131072" TYPE="squashfs"
  /dev/nvme0n1p1: UUID="31e9db7c-4d33-4959-a335-0ac9c912df1f" UUID_SUB="0ea790c4-40f4-4e18-a780-3ce50ac89e97" BLOCK_SIZE="4096" TYPE="btrfs"
  /dev/sdd1: LABEL="main-storage" UUID="18338773625610573138" UUID_SUB="15745215116711571004" BLOCK_SIZE="4096" TYPE="zfs_member" PARTUUID="1422c1d3-b4d9-401e-bbd3-060002df010f"
  /dev/sdb1: LABEL="main-storage" UUID="18338773625610573138" UUID_SUB="9591938035247704645" BLOCK_SIZE="4096" TYPE="zfs_member" PARTUUID="27b1a478-2ccc-4514-8ebf-5e394331ca33"
  /dev/nvme2n1p6: LABEL="UGREEN-SERVICE" UUID="a2f6723b-d58b-4266-a63c-28d99d9efb91" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="44837071-b6e8-aa4f-b98f-6b0204f00fe1"
  /dev/nvme2n1p4: LABEL="rootfs2" UUID="2cf7b686-078f-4d79-a2ca-923916071584" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="d9c12fe3-3a07-f941-8e5e-8ab9b85b824b"
  /dev/nvme2n1p2: BLOCK_SIZE="262144" TYPE="squashfs" PARTUUID="99009e79-d999-a659-32e5-993bfb698a02"
  /dev/nvme2n1p7: LABEL="USER-DATA" UUID="af175c65-cbf3-4148-891f-b853586a1db1" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="63acc8e2-965c-9648-a750-65781a621d7d"
  /dev/nvme2n1p5: LABEL="ugswap" UUID="b2ab99eb-e38a-4a2a-87e8-dbce9ebdf49e" TYPE="swap" PARTUUID="37ab82bc-0933-df46-9435-0ab8196dbdba"
  /dev/nvme2n1p3: LABEL="factory" UUID="e29eec30-01e3-4d97-8dd2-83a9aae69554" BLOCK_SIZE="1024" TYPE="ext4" PARTUUID="923dd0e1-76cf-7a48-bbe5-ada909ffd91a"
  /dev/nvme2n1p1: SEC_TYPE="msdos" LABEL_FATBOOT="kernel" LABEL="kernel" UUID="1234-ABCD" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="99009e79-d999-a659-32e5-993bfb698a01"
  /dev/loop0: BLOCK_SIZE="131072" TYPE="squashfs"
  /dev/sde1: LABEL="main-storage" UUID="18338773625610573138" UUID_SUB="1596818472322638747" BLOCK_SIZE="4096" TYPE="zfs_member" PARTUUID="08a8a5d8-35f6-404d-b21d-aa0f33f488bc"
  /dev/sdc1: LABEL="main-storage" UUID="18338773625610573138" UUID_SUB="17752503991717505069" BLOCK_SIZE="4096" TYPE="zfs_member" PARTUUID="8b21e298-063c-4b27-86d0-2985beca9928"
  /dev/nvme1n1p1: UUID="31e9db7c-4d33-4959-a335-0ac9c912df1f" UUID_SUB="ce27fe56-26a3-4299-8485-8751fdcfe0a0" BLOCK_SIZE="4096" TYPE="btrfs"
  /dev/sdf1: LABEL="WINDOWS10" UUID="6294-0B9A" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="f6f6d5d7-01"
  /dev/loop2: UUID="c35448fa-941b-4d83-a09c-20f4bce5215f" UUID_SUB="5ad39219-1138-475c-887d-00619de42f35" BLOCK_SIZE="4096" TYPE="btrfs"
  /dev/nvme2n1p128: PARTUUID="99009e79-d999-a659-32e5-993bfb698a80"
  ```

* Scan the file for lines with **LABEL="BACKUPx-0** and **LABEL="BACKUPx-1** and
  extract the disk path from the beginning of the matching lines.  Our convention 
  will that the **"x"** in **BACKUPx-*** refers to a backup disk set and the digit
  after the dash specifies the disk number in th set.

* Mount the disks like (using the labels to identify the drives):

  ```
  mount /dev/sdf1 /mnt/backupx-0
  mount /dev/sdg1 /mnt/backupx-1
  ```

* Copy the files being backed up.

* Unmount the drives like:

  ```
  unmount /mnt/backup-0
  unmount /mnt/backup-1
  ```
