# Upgrade WIndows 7 Computers to Windows 10 in AD
# Author DaTi_Co
# Ver.: 0.001

# Import AD
Import-Module activedirectory
$c = Get-Credential
# Change DC and OU for your AD Structure
$XDMachines = Get-ADComputer -Credential $c -LDAPFilter "(name=*)"-SearchBase "OU=Computers,DC=Domain,DC=local" 
$Amount = $XDMachines.count
$a = 0
$Updated = 0
$Updating = 0
$Offline = 0
foreach ($XDMachine in $XDMachines) {
    Write-host "Connecting to:" $XDMachine.Name
    # Check PSRemote
    if (Test-WSMan -ComputerName $XDMachine.Name -ErrorAction Ignore) {
        Write-host 'Online' -BackgroundColor Green
        # Check Windows Version
        if (invoke-command -computerName $XDMachine.Name -scriptblock { Get-WmiObject Win32_OperatingSystem | Where-Object { $_.BuildNumber -match '7601' -or $_.BuildNumber -match '7600' }} -ErrorAction Ignore) {
            Write-host 'Windows 7 Found!' -ForegroundColor green
            Write-Host 'Starting Update Process...'
            $XDMachine.Name | add-content UPDATE_ONLINE_7.txt
            # MAGIC
            Invoke-Command -ComputerName $XDMachine.Name -ScriptBlock {
                $PC = $Using:XDMachine.Name
                $DRIVE = "W:"
                # Extracted windows 10 ISO Location 
                $NETWORKPATH = "\\SERVER\SHARE\10"
                ## PLAIN PASSWORD :( Change it!!
                $USER = "Domain\Domain_Admin"
                $PASS = "Password"
                $LOG = "C:\Temp\10"


                Write-Host "Mount Windows 10 Source"
                Net Use $DRIVE $NETWORKPATH /user:$USER $PASS /persistent:no
                Write-Host "Launch Upgrade installation file Silent"
                Start-Process -FilePath $DRIVE\setup.exe -ArgumentList '/auto upgrade /quiet /migratedrivers all /ShowOOBE none /Compat IgnoreWarning /Telemetry Disable /copylogs C:\Temp\10' -Wait
                Write-Host "Installation Launched"
                Copy-Item -Path $LOG\*.* -Destination $DRIVE\$PC -Force
                # Net Use $DRIVE /delete
                # Write-Host "Unmount Drive W"
            } -AsJob

            $Updating++
        }
        else {
            # Does not need UPDATE          
            Write-Host "WINDOWS 10" -BackgroundColor Blue
            Write-Host "SKIP..." -ForegroundColor DarkBlue
            $XDMachine.Name | add-content UPDATE_ONLINE_10.txt

            $Updated++
        }
    }
    else{
        # Cant Connect To machine
        write-host "OFFLINE?" -BackgroundColor Yellow
        # Write-Host "Save and Check after!" -ForegroundColor Yellow
        $XDMachine.Name | add-content UPDATE_OFFLINE_7.txt
        # Write-Host "Saved..."

        $Offline++
    }
    $a++
    Write-Progress -Activity "Working..." -CurrentOperation "$a complete of $Amount"  -Status "Please wait Updating Computers"
}

# Receive-Job *
# Get-Job *

Write-Host "Windows 10 Installed: " $Updated -ForegroundColor DarkGreen
Write-Host "Windows 10 Installing: " $Updating "Machines" -ForegroundColor Cyan
Write-Host "OFFLINE:" $Offline -ForegroundColor Red
Write-Host "Total:" $Amount "Computers"

#$parameters = @{
#  ComputerName = (Get-Content UPDATE_ONLINE_10.txt)
#  ScriptBlock = { Get-WmiObject Win32_OperatingSystem | Select-Object Version }
#}
#Invoke-Command @parameters
