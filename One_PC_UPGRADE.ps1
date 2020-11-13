$Server = Read-Host -Prompt 'Enter Computer Name to Upgrade'
$c = Get-Credential

Invoke-Command -ComputerName $Server -Credential $c -ScriptBlock {
    $DRIVE = "W:"
    # Windows Installation Pass
    $NETWORKPATH = "\\Server\Share\10"
    # Plain Password | lazy to change in code
    $USER = "Domain\User"
    $PASS = "Password"

    Write-Host "Mount Windows 10 Source"
    Net Use $DRIVE $NETWORKPATH /user:$USER $PASS /persistent:no
    Write-Host "Launch Upgrade installation file Silent"
    Start-Process -FilePath $DRIVE\setup.exe -ArgumentList '/auto upgrade /quiet /migratedrivers all /ShowOOBE none /Compat IgnoreWarning /Telemetry Disable /copylogs C:\Temp\10.log' -Wait
    Write-Host "Installation Launched"
    # Net Use $DRIVE /delete
    # Write-Host "Unmount Drive W"
}
