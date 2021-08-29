#------------------------------------------------------------------------------
# NAME
#	  New-LinuxVM - Create a new Linux VM on Hyper-V
#
# DESCRIPTION
#     A script to create a new Linux VM on a local Hyper-V host using a base
#     disk image. Customization of the guest OS using cloud-init is supported
#     through this script if the base image also supports cloud-init.

#
# REQUIREMENTS
#     - A Hyper-V base image for a Linux OS
#     - Hyper-V host must have the Windows Assessment and Deployment Kit (ADK)
#       installed
#
# Created 28 August 2021
#
# Modified from script found on GitHub:
# https://gist.github.com/wipash/81064e811c08191428002d7fe5da5ca7
#
#------------------------------------------------------------------------------
param(
    # Path to the folder that VMs are stored in
    [string]$VMFolder = "C:\Users\Sean\Virtual Machines\",

    # Path to the SSH public key that will be added for the base user
    [string]$SSHPublicKeyPath = "C:\Users\Sean\Virtual Machines\homelab.pub",

    # Path to the oscdimg.exe binary
    [string]$oscdimgPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
)

function Get-Info {
    $cores = Read-Host "vCPU (Cores): "
    $mem = Read-Host "Memory (GB): "
    $diskSize = Read-Host "Disk size (GB): "
    $name = Read-Host "VM Name: "
    $notes = Read-Host "VM Notes (optional): "

    $VMObject = New-Object -TypeName psobject
    $VMObject | Add-Member -MemberType NoteProperty -Name "memory" -Value $([int]$mem)
    $VMObject | Add-Member -MemberType NoteProperty -Name "diskSize" -Value $([int]$diskSize)
    $VMObject | Add-Member -MemberType NoteProperty -Name "cores" -Value $([int]$cores)
    $VMObject | Add-Member -MemberType NoteProperty -Name "name" -Value $name
    $VMObject | Add-Member -MemberType NoteProperty -Name "notes" -Value $notes

    return $VMObject
}

function Setup-VM {
    param($VMObject, $basepath, $sshPubKey)

    $vmname = Get-NextVMNumber($VMObject.name)
    $diskSize = $VMObject.diskSize
    $path = "$basepath\$vmname"

    Write-Host "Creating VM: $vmname"

    Add-VMVHD -vmname $vmname -path $path -diskSize $diskSize
    Create-VM -VMObject $VMObject -vmname $vmname -path $path
    Create-CloudInit -vmname $vmname -path $path -sshPubKey $sshPubKey
    Set-VMProperties -VMObject $VMObject -vmname $vmname
    Add-VMDvdDrive -VMName $vmname
    Set-VMDvdDrive -VMName $vmname -path "$($path)\metadata.iso"
    Start-VM $vmname
    Write-Host "MAC: $((Get-VMNetworkAdapter -VMName $vmname).MacAddress)"
}

function Create-VM {
    param($VMObject, $vmname, $path)

    Write-host "Creating new virtual machine." -NoNewline
    New-VM -Name $vmname -MemoryStartupBytes ([int]($VMInfo.memory)*1GB) -BootDevice VHD -VHDPath "$path\$vmname.vhdx" -Path "$path\" -Generation 2 -SwitchName (Get-VMSwitch -SwitchType External).name | out-null
    Write-Host -ForegroundColor Green " Done."
}

function Create-CloudInit {
    param(
        $vmname,
        $path,
        $sshPubKey
    )

    $metaDataIso = "$($path)\metadata.iso"

$metadata = @"
instance-id: uuid-$([GUID]::NewGuid())
local-hostname: $($vmname)
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
"@

$username = "ladmin"
$fullname = "Local Administrator"

$userdata = @"
#cloud-config
users:
  - name: $username
    gecos: $fullname
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_import_id: None
    lock_passwd: true
    ssh_authorized_keys:
      - $sshPubKey
"@

    # Output meta and user data to files
    if(-not (Test-Path "$($path)\Bits")) {New-Item -ItemType Directory "$($path)\Bits" | out-null}
    sc "$($path)\Bits\meta-data" ([byte[]][char[]] "$metadata") -Encoding Byte
    sc "$($path)\Bits\user-data" ([byte[]][char[]] "$userdata") -Encoding Byte

    # Create meta data ISO image - this thing apparently outputs in stderr so it shows as red but it's not errors, it's just the progress for it.
    & $oscdimgPath "$($path)\Bits" $metaDataIso -j2 -lcidata | Out-null
}

function Get-NextVMNumber {
    param($prefix)

    if((Get-VM -name "$prefix*").count -gt 0){
       $prefix += (([int](get-vm -name "$prefix*" | select @{ Label = 'Number' ;Expression = { $_.VMName.Substring($prefix.length,2) } } | sort number | select -Last 1).number) + 1).tostring().padleft(2,"0")
    } else {
        $prefix += "01"
    }

    return $prefix.ToUpper()
}

function Add-VMVHD {
    param($vmname, $path, $diskSize)

    $sizeInBytes = $diskSize * 1073741824

    $disks = Get-ChildItem -Path "$VMFolder\Base Images\"

    Write-Host "Please choose a base disk:"
    for ($i = 0; $i -lt $disks.count; $i++) {
        Write-Host "[$($i + 1)]: $($disks[$i].Name)"
    }

    [int]$number = Read-Host "Enter your selection: "

    $parent = $($disks[$number - 1].FullName)

    if(-not (Test-Path "$path\$vmname.vhdx")) {

        if (-not (Test-Path "$path")) { New-Item -Force -ItemType Directory -Path "$path" | out-null }
        Write-host "Creating new VHD from parent $parent." -NoNewline

        # This one creates a new Differencing VHD from original VM's VHD
        New-VHD -Path "$path\$vmname.vhdx" -ParentPath $parent -Differencing | Out-null

        # This method copies the original VHD and then renames it
        # Copy-Item -Path $parent -Destination "$path"
        # $parentVHDName = Split-Path $parent -Leaf
        # Rename-Item -Path "$path\Virtual Hard Disks\$parentVHDName" -NewName  "$path\Virtual Hard Disks\$vmname.vhdx"

        Resize-VHD -Path "$path\$vmname.vhdx" -SizeBytes $sizeInBytes

        Write-Host -ForegroundColor Green " Done."
    }
}

function Set-VMProperties {
    param($VMObject, $vmname)
    # $VMObject | Add-Member -MemberType NoteProperty -Name "memory" -Value $([int]$mem)
    # $VMObject | Add-Member -MemberType NoteProperty -Name "diskSize" -Value $([int]$diskSize)
    # $VMObject | Add-Member -MemberType NoteProperty -Name "cores" -Value $([int]$cores)
    # $VMObject | Add-Member -MemberType NoteProperty -Name "name" -Value $name

    Write-host "Customizing virtual machine." -NoNewline

    Set-VM -VMName $vmname -ProcessorCount $VMInfo.cores -AutomaticStopAction ShutDown -CheckpointType Standard -Notes $VMObject.notes -StaticMemory
    Set-VMFirmware -VMName $vmname -EnableSecureBoot Off -FirstBootDevice (get-VMHardDiskDrive -VMName $vmname)
    Get-VM -VMname $vmname | Enable-VMIntegrationService -Name *

    Write-Host -ForegroundColor Green " Done."
}

#=====================================
# The fun starts here
#=====================================
$sshPubKey = [IO.File]::ReadAllText($SSHPublicKeyPath)

$VMInfo = Get-Info

Write-Host "Starting timer.`n"
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

Setup-VM -VMObject $VMInfo -basepath $VMFolder -sshPubKey $sshPubKey

$stopwatch.Stop()
Write-host "Total time : $([math]::Round($stopwatch.Elapsed.TotalSeconds,0)) seconds for $many Virtual machines."