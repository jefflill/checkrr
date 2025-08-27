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

5. Configure the 2 Nvme cards as a **Btrfs RAID1** pool
   named **cache**

6. Configure the 4 drives as a **ZFS** pool named **main-storage**

6. Create a user account (e.g. "jeff") with password

7. Configure the desired shares on **main-storage**:

   a. Set primary storage as **Cache**
   b. Minimum free space to **50MB** or maybe double the size
      of the largest file you'll be writing to the share
   c. Set secondary storage as **main-storage**
   d. Mover action: **Cache --> Main-storage**
   e. Export: **yes** (as required)
   d. Security: **secure** when exporting (couldn't get
      **public** to work from Windows
   e. Grant your user account **R/W access**

8. Install **Community Applications** app

9. Install **Unraid Connect** app and then configure your
   **connect.myunraid.net** account to backup your USB
   drive.  Configure it to **AUTOSTART**.

10. Install **Intel GPU TOP** plugin (used for debugging
    custom **checkrr** GPU settings.

11. Create alias Bash scripts in **/usr/bin** for:
    
    gpu-top --> intel_gpu_top "$@"
    ll      --> ls -lh "$@"

13. Install **binhex-plex** app, with these host to container
    mappings:
    
    ```
    /mnt/user/appdata/binhex-plex --> /config
    /mnt/main-storage             --> /main-storage
    ```

    Configure **Plex Docker container** to **AUTOSTART**
    
    Use Plex UI to create your libraries off of the local
    **/main-storage** and configure other settings.

14. **Settings:**

    a. (APC) **UPS Settings:** configure as required
    b. **Disk Settings:** Default spin down delay **never**
    c. **Identification:** Rename server as required
    d. **Network Settings:** Configure static IP as required
    e. **Schedule Settings:** Mover schedule=**hourly**,
       Trim schedule=**disabled**
    f. **Power mode:** **Best performance**

15. Install my customized **checkrr** app from 
    https://github.com/jefflill/checkrr and 
    **ghcr.io/jefflill/checkrr:latest**.  This version
    uses **ffmpeg** to fully scan media files for
    better corruption detection.

    a. Install the **checkrr** app and configure it to **AUTOSTART**
    b. Go to the **Docker** tab and edit **checkrr**

       i. Change **Name** to **checkrr-jeff** to indicate
          that this is the customized version

       ii. Change the **repository** to **ghcr.io/jefflill/checkrr:latest**

       iii. Configure Docker host/container path mappings:
       ```
       /mnt/user/appdata/checkrr/config/ --> /etc/checkrr/
       /mnt/main-storage                 --> /media/
       ```

       iv. Add the device mapping: **/dev/dri:/dev/dri** and name
           it **Devices**.

      Here's my config file on the host NAS at:
      **//mnt/main-storage/appdata/checkrr/config/checkrr.yaml**
      ```
      lang: "en-us"
      checkrr:
      checkpath: 
         - "/media/movie/"
         - "/media/music/"
         - "/media/new/"
         - "/media/tv/"
         # - /media/test
      database: /etc/checkrr/checkrr.db
      debug: false
      csvfile: "/etc/checkrr/badfiles.csv"
      cron: "@daily"
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

16. Install the **Disk Location** app and then goto 
    **Tools/Dish Location** to configure it.  I configured
    2 row and 4 columns formatted as 300x150px with the
    first row displaying the spinning drives (so the drive
    numbers will match the external trays) and the second
    row displaying the Nvme cache drives.

    I also configured the trays to display text as white.

17. Install **NoIP** app:

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

NOTE: I was able to get hardware acceleration going in the scan
      on my DXP4800 Plus but doing that was actually THREE TIMES SLOWER
      than just using the CPU, so this is disabled by default.

      You can manually enable HW acceleration by adding this 
      environment variable to the **checkrr-jeff** Docker template:

      HW_ACCEL_ARG=-hwaccel vaapi
