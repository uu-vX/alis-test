#!/usr/bin/env bash

#   lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd"
blk_device="$(lsblk --noheadings --nodeps --output name)"
for i in $blk_device
do
  blk_dvc+=("$i")
done
##############################################################################################################################
for i in "${!blk_dvc[@]}"
do
echo "${i}) ${blk_dvc[i]}"
done
echo "................................................."
read -a device_choice
if [ -n "$device_choice" ] && [ "${#blk_dvc[@]}" -gt "$device_choice" ]; then device="/dev/${blk_dvc[$device_choice]}"; echo "secili diski '${blk_dvc[$device_choice]}' olarak ata "; else echo "hatali giris yaptigini soyle ve statementa tekrar ata"; fi
echo "................................................."
#echo "${device#/dev/nvme}"
if [ "${device#/dev/nvme}" != "$device" ] ; then
partitions+=('boot_partition')
    boot_partition="${device}p${#partitions[@]}"
    partitions+=('swap_partition')
    swap_partition="${device}p${#partitions[@]}"
    partitions+=('root_partition') # add size
    root_partition="${device}p${#partitions[@]}"
    partitions+=('home_partition') # add if 
    home_partition="${device}p${#partitions[@]}"
elif [ "${device#/dev/sd}" != "$device" ] ; then
partitions+=('boot_partition')
    boot_partition="${device}${#partitions[@]}"
    partitions+=('swap_partition')
    swap_partition="${device}${#partitions[@]}"
    partitions+=('root_partition') # add size
    root_partition="${device}${#partitions[@]}"
    partitions+=('home_partition') # add if 
    home_partition="${device}${#partitions[@]}"
    else
    echo -ne "'/dev' empty \n"
fi
##############################################################################################################################
total_memory=$(awk '$1~/MemTotal:/ {print $2;}' /proc/meminfo)
swap_size="$(( $total_memory/1024^2 ))"
if (( $swap_size <= 1024 )); then  # RAM size 1G * 2
    ((swap_size += swap_size ))
elif (( $swap_size <= 4096 )); then  # RAM size 4G * 1.5
    ((swap_size += swap_size / 2 ))
elif (( $swap_size <= 8192 )); then  # RAM size 8G * 1.375
    ((swap_size += swap_size / 3))
elif (( $swap_size <= 16384 )); then  # RAM size 16G * 1.25
    ((swap_size += swap_size / 4 ))
elif (( $swap_size <= 32768 )); then  # RAM size 32G * 1.187
    ((swap_size += (swap_size *10) / 63 ))
elif (( $swap_size <= 65536 )); then  # RAM size 64G * 1.125
    ((swap_size += swap_size / 8))
elif (( $swap_size <= 131072 )); then  # RAM size 128G * 1.085
    ((swap_size += (swap_size ) / 9 ))
else
    ((swap_size += (swap_size ) / 10 )) # Greater than 128G RAM size
fi
##############################################################################################################################
#read -r device
#$device="/dev/nvme0n1" #ask user
esp_partition=$((1 + 300))
swap_partition=$(($swap_size + $esp_partition))
root_size=$((30720)) #add option to ask user decision of root partition size
root_partition=$(($swap_partition + $root_size))
parted --script $device mklabel gpt
parted --script $device mkpart "EFI system partition" fat32 1MiB "$esp_partition MiB"
parted --script set 1 esp on
parted --script $device mkpart "swap partition" linux-swap "$esp_partition MiB" "$swap_partition MiB"
parted --script set 2 swap on
parted --script $device mkpart "root partition" ext4 "$swap_partition MiB" "$root_partition MiB"
parted --script set 3 root on
parted --script $device mkpart "home partition" ext4 "$root_partition MiB" 100%
##############################################################################################################################
echo $device
echo ${boot_partition}
echo ${swap_partition}
echo ${root_partition}
echo ${home_partition}
echo "................................................."
echo ${partitions[@]}
echo "................................................."
##############################################################################################################################
# Formatting & Mounting
# add if structure : if not empty execute command
mkfs.fat -F32 ${root_partition}
mkswap -L swap ${swap_partition}
mkfs.ext4 -L root ${root_partition}
mkfs.ext4 -L home ${home_partition} 

swapon ${swap_partition}
mkdir -p /mnt/boot/efi
mount ${boot_partition} /mnt/boot/efi
mount ${root_partition} /mnt

#   Ask for home partition
mkdir -p /mnt/home
mount ${home_partition} /mnt/home
#   Add /var/tmp
#mkdir -p /mnt/var
