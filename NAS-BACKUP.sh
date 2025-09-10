#!/bin/bash
echo "====================================================================="
echo "DESCRIPTION: UNRAID NAS Backup Script"
echo "FILE:        /boot/config/plugins/user.scripts/scripts/nas-backup/script"
echo
echo "ARGUMENTS:   --no-pause   - don't prompt to continue"
echo
echo "USAGE     nas-backup          - KEEPS extraneous files in backup set"
echo "          nas-backup --clean  - REMOVES extraneous files from backup set"
echo 
echo "REQUIRED: (2) external 30GB USB drives connected to the USB 3.2 ports"
echo "          on the NAS.  These must be formatted as exFAT (FAT64) and labeled"
echo "          BACKUP-0 and BACKUP-1."
echo
echo "          [mergerFS for UNRAID] must be installed."
echo "====================================================================="

#------------------------------------------------------------------------------
# FUNCTION: UnmountIfMounted(mountPath) 
#
# Unmounts the file system at the path passed if something is mounted there.

function UnmountIfMounted()
{
    local mountPath=$1

    # NOTE: The space at the end of the grep expression is important!

    if $(mount | grep -q "on $mountPath "); then
        echo "Unmount: $mountPath"
        umount $mountPath
    fi
}

#------------------------------------------------------------------------------
# FUNCTION: HumanizeSeconds(seconds)
# RETURNS:  $humanSeconds
#
# Formats the seconds argument into a nice human readable.

function HumanizeSeconds()
{
    local seconds=$1

    local days=$((SECONDS/60/60/24))
    local bours=$((SECONDS/60/60%24))
    local minutes=$((SECONDS/60%60))
    local seconds=$((SECONDS%60))

    printf -v humanSeconds "%02d %02d:%02d:%02d" $days $hours $minutes $seconds
}

#------------------------------------------------------------------------------
# Script Entrypoint

# Process command line options.

clean=false
noPrompt=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean)
            clean=true
            ;;
        --no-prompt)
            noPrompt=true
            ;;
        *)
            echo "***ERROR: Unknown option: $1" >&2
            exit 1
      ;;
  esac
  shift 1
done

echo "--clean:     $clean"
echo "--no-prompt: $noPrompt"

# Prompt the user to confirm when things are ready.

if ! $noPrompt; then
    echo "This would be a good time to run the MOVER if required."
    echo
    echo "Press ENTER to proceed with the backup or CTRL-C to cancel..."
    read
fi

# Check for: mergerfs 

echo "Checking: mergerfs"

if ! which mergerfs > /dev/null 2>&1 ; then
    echo                                                           >&2
    echo "** ERROR: [mergerFS for UNRAID] app plugin is required." >&2 
    echo                                                           >&2
    exit 1
fi

echo "    mergerfs is installed"

# Use [blkid] to list the attached block devices, looking for the BACKUP#-#
# drive labels and then extract the device path at the beginning of the line.
# Matching lines from [blkid] will look something like:
#
# /dev/sdc1: LABEL="BACKUP0-0" UUID="18338773625610573138" UUID_SUB="17752503991717505069" BLOCK_SIZE="4096" TYPE="vfat" PARTUUID="8b21e298-063c-4b27-86d0-2985beca9928"
# ...
#
# NOTE: The first digit in the drive labels specifies the backup disk set
#       and the second digit identifies the disk in the set.

echo 
echo "Locating backup drives"

backupDrive0Entry=$(blkid | grep LABEL=\"BACKUP[0-9]-0\")
backupDrive1Entry=$(blkid | grep LABEL=\"BACKUP[0-9]-1\")

backupDrive0Label=$(echo $backupDrive0Entry | grep -o "LABEL=\"BACKUP[0-9]-0\"")
backupDrive0Label=${backupDrive0Label:7:9}

backupDrive1Label=$(echo $backupDrive1Entry | grep -o "LABEL=\"BACKUP[0-9]-1\"")
backupDrive1Label=${backupDrive1Label:7:9}

backupDrive0=$(echo $backupDrive0Entry | grep -o '^[^:]*')
backupDrive1=$(echo $backupDrive1Entry | grep -o '^[^:]*')

echo "    Backup Drives:"
echo "    --------------------------------"
echo "    $backupDrive0Label: $backupDrive0"
echo "    $backupDrive1Label: $backupDrive1"

if [ -z "$backupDrive0" ]; then
    echo                                                          >&2
    echo "*** ERROR: Cannot locate BACKUP#-0 external USB drive." >&2
    echo "***        Plug this into one of the USB 3.2 ports."    >&2
    echo                                                          >&2
    exit 1
fi

if [ -z "$backupDrive1" ]; then
    echo                                                          >&2
    echo "*** ERROR: Cannot locate BACKUP#-1 external USB drive." >&2
    echo "***        Plug this into one of the USB 3.2 ports."    >&2
    echo                                                          >&2
    exit 1
fi

# Get the system into a known state where all of the backup related
# mountpoints are unmounted.  Here are tbebackup mountpoints:

driveCheckMount=/tmp/drive-check
driveMount0=/tmp/backup-drive0
driveMount1=/tmp/backup-drive1
backupMount=/tmp/backup

echo
echo "Putting backup mounts into a known (unmounted) state"

UnmountIfMounted $driveCheckMount
UnmountIfMounted $driveMount0
UnmountIfMounted $driveMount1
UnmountIfMounted $backupMount

# Verify that the backup drives are from the same backup set.

echo
echo "Checking backup set"

drive0BackupSet=${backupDrive0Label:0:7}
drive1BackupSet=${backupDrive1Label:0:7}

if [[ $drive0BackupSet != $drive1BackupSet ]]; then
    echo                                                                                             >&2
    echo "*** ERROR: Drives are not for the same backup set: $backupDrive0Label, $backupDrive1Label" >&2
    echo                                                                                             >&2
    exit 1
fi

echo "   Backup set: OK"

# Make sure the apps that manage data at [/mnt/user] are stopped.

dataApps="checkrr info plex"

echo
echo "Stopping apps..."
echo "----------------"
docker stop $dataApps

# Mount the drives individually remove the and [System Volume Information]
# folder if present.  It looks like Windows creates this when it
# formats drives.

# Check: drive 0

if [ ! -d $driveCheckMount ]; then
    echo "Create: $driveCheckMount"
    mkdir /tmp/drive-check
fi

mount $backupDrive0 $driveCheckMount

if [ -d "$driveCheckMount/System Volume Information" ]; then
    echo "Remove: $driveCheckMount/System Volume Information"
    rm -r "$driveCheckMount/System Volume Information"
fi

# Check: drive 1

mount $backupDrive1 $driveCheckMount

if [ -d "$driveCheckMount/System Volume Information" ]; then
    echo "Remove: $driveCheckMount/System Volume Information"
    rm -r "$driveCheckMount/System Volume Information"
fi

umount $driveCheckMount

# Mount the two drives with mergerfs.  We're going to mount the backup
# drives at [/tmp/backup-drive0] and [/tmp/backup-drive1] and the merged 
# file system at [/tmp/backup].

echo
echo "Mounting drives via [mergerfs] at: $backupMount"

# Create the backup folder if it doesn't already exist.

if [ ! -d $backupMount ]; then
    echo "Creating: $backupMount"
    mkdir -p $backupMount
fi

# Mount the backup drives and then the mergerFS file system.

mkdir -p $driveMount0
mount $backupDrive0 $driveMount0

mkdir -p $driveMount1
mount $backupDrive1 $driveMount1

if ! mergerfs -o "category.create=mfs" "$driveMount0:$driveMount1" $backupMount; then
    echo                                          >&2
    echo "*** ERROR: Cannot mount merged drives." >&2
    echo                                          >&2
    exit 1
fi

# Use [rsync] to backup [/mnt/main-storage] to the backup drives. 
# We're  backing up this instead of [/mnt/user] because we don't
# want to copy the [system] folder.
#
# Useful Options:
#
#   --delete-during     - delete extraneous files from backup set
#   --recursive         - copy subfolders too
#   --force             - force deletion of dirs even if not empty
#   --times             - preserve file modification times

# By default, this script won't remove extranious files on the target when they
# don't exist on the source.  This is a safety thing to prevent the loss of 
# backed up files due to mistakes or corruption in the source (this happened
# to me before I had a NAS).
#
# If the "--clean"" option was present, we'll remove extranious files 
# from the backup.

if $clean; then
    cleanOptions="--delete-during --force"
fi

echo
echo "Backup target: $backupMount"

if ! rsync $cleanOptions --recursive --times --progress /mnt/user/ $backupMount/; then

    # Convert the the script run time into a nice string.

    HumanizeSeconds $SECONDS # --> $humanSeconds
    
    echo                                            >&2
    echo "****************************************" >&2
    echo "* ERROR: Backup was cancelled or failed." >&2
    echo "* Elapsed Time: $humanSeconds"
    echo "****************************************" >&2
    echo                                            >&2
    exit 1
fi

# Unmount the backup drives so cached data will be flushed
# and the drives will be able to idle out and spin down.

umount $driveMount0
umount $driveMount1
umount $backupMount

# Restart the Docker apps.

echo "Restarting apps..."
docker start $dataApps

# Convert the the script run time into a nice string.

HumanizeSeconds $SECONDS # --> $humanSeconds

echo
echo "***************************"
echo "* Backup Completed"
echo "* Elapsed Time: $humanSeconds"
echo "***************************"
echo
exit 0
