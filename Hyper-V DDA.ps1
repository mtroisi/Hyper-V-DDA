# Valid modes are "Dismount" and "Mount"
param (
    [Parameter(Mandatory=$true)][string]$VMName,
    [string]$InstanceId,
    [Parameter(Mandatory=$true)][string]$Mode
)



# Dismount Section
If ( $Mode -like "Dismount" ) {
    If ( (Get-VMAssignableDevice $VMName).Count -lt 1 ) {
        Write-Host "VM has no devices assigned"
        exit
    }


    Write-Host "Please select device to unassign"
    Write-Host ""
    
    # Create table
    try { $VMAssignableDevices.Clear() } catch {}
    $VMAssignableDevices = New-Object System.Data.DataTable
    $VMAssignableDevices.Columns.Add("Index", "string") | Out-Null
    $VMAssignableDevices.Columns.Add("Name", "string") | Out-Null
    $VMAssignableDevices.Columns.Add("LocationPath", "string") | Out-Null

    $index = 0    
    
    # Populate table
    Get-VMAssignableDevice $VMName | ForEach {
        $row = $VMAssignableDevices.NewRow()

        $row.Index = $index++
        $row.Name = $_.Name
        $row.LocationPath = $_.LocationPath
   
        $VMAssignableDevices.Rows.Add($row)
    }

    # Selecting from table
    $VMAssignableDevices | Format-Table
    Write-Host ""
    $LocationPath = $VMAssignableDevices[(Read-Host "Index")].LocationPath

    # Attempt to remove device from VM. If fail, stop vm and try again
    try {
        Remove-VMAssignableDevice -LocationPath $LocationPath -VMName $VMName
    }
    catch {
        Stop-VM -VMName $VMName
        Remove-VMAssignableDevice -LocationPath $LocationPath -VMName $VMName
        Start-VM -VMName $VMName
    }

    Write-Host "Enabling device..."
    # Mount the device back to the host
    Get-VMHostAssignableDevice | Mount-VMHostAssignableDevice

    # Enable device
    Get-PnpDevice | ForEach { 
    
        $tmp = Get-PnpDeviceProperty -KeyName DEVPKEY_Device_LocationPaths -InstanceId $_.InstanceId -WarningAction Ignore
        try {
            If ($tmp.Data[0] -like $LocationPath) {
                Enable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false
                Break
            }
        }
        catch {}
    
    }
}


# Mount section
If ( $Mode -like "Mount" ) {

    # Disable device
    Write-Host $InstaceId
    Disable-PnpDevice -InstanceId $InstanceId -Confirm:$false -WarningAction Ignore

    # Get location path
    $LocationPath = (Get-PnpDeviceProperty -KeyName DEVPKEY_Device_LocationPaths -InstanceId $InstanceId).Data[0]

    # Dismount device
    Dismount-VmHostAssignableDevice -LocationPath $LocationPath -Force
    
    # Add device to VM
    try {
        Add-VMAssignableDevice -VMName $VMName -LocationPath $LocationPath
    }
    catch {
        Stop-VM $VMName -WarningAction Ignore
        
        If ( (Get-VM $VMName).AutomaticStopAction -ne "ShutDown" ) {
            Write-Host "Setting VM to shutdown on host shutdown..."
            Set-VM $VMName -AutomaticStopAction ShutDown
        }

        If ( (Get-VM $VMName).DynamicMemoryEnabled ) {
            Write-Host "Setting minumum memory to equal startup memory..."
            Set-VM $VMName -MemoryMinimumBytes (Get-VM $VMName).MemoryStartup
        }

        Add-VMAssignableDevice -VMName $VMName -LocationPath $LocationPath

        Start-VM $VMName

    }
}