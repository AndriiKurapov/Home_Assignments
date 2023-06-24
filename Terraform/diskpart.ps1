$diskNumber = 0

# Get the disk object
$disk = Get-Disk -Number $diskNumber

# Extend the partition to use all available space
$partition = Get-Partition -DiskNumber $diskNumber | Where-Object {$_.PartitionNumber -eq 2}
$partition | Resize-Partition -Size ($partition.Size + 1GB) # Add 1GB to the current size

# Extend the volume to use all available space
$volume = Get-Volume -Partition $partition
$volume | Resize-Volume -Size ($volume.Size + 1GB) # Add 1GB to the current size