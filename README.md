# Hyper-V DDA
This is a PowerShell script written to assist in using Hyper-V Discrete Device Assignment for devices that support it. This script does not validate system configuration or check if the system is capable of doing so.

## Parameters
`Mode`: Required parameter to specify if a device is to be mounted to a VM, or unmounted from a VM and returned to the host. Valid options are "Mount" and "Dismount"

`VMName`: Required parameter to specify the VM name to mount a device to or unmount a device from.

`InstanceId`: Optional parameter only used when mounting a device to a VM. Please use InstanceId found from using the PowerShell command 'Get-PnPDevice'


## Features
When unmounting a device from a VM, the user can select which device to unmount from a VM. Useful if multiple devices are assigned to a VM.

When mounting a device, checks are in place to make sure that dynamic memory and the automatic stop action match required settings for discrete device assignment. **Doing so may automatically shut down the VM to make changes.** The VM is set to turn back on once the host device is assigned to the VM.
