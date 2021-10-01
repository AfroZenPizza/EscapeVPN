#Requires -RunAsAdministrator

Clear-Host

# Create some useful Splats
$PriorityRoute = @{
    RouteMetric = 1
    NextHop = "0.0.0.0"
}

$DisableAutoMetric = @{
    InterfaceMetric = 110
}

$EnableAutoMetric = @{
    AutomaticMetric = "Enabled"
}

$interfaces = Get-NetIPInterface -AddressFamily IPv4

If ($interfaces.InterfaceAlias -contains "VPN"){    
    Write-Host "Found VPN Adapter... Press any key to skip auto application"
    Start-Sleep -Milliseconds 500
    $Host.UI.RawUI.FlushInputBuffer()
    $waitTime = 0
    While ( (-not $Host.UI.RawUI.KeyAvailable) -and ($waitTime -le 5)){        
        Start-Sleep -Seconds 1
        $waitTime++
    }
}

If (-not $Host.UI.RawUI.KeyAvailable){
    $int = [array]::IndexOf($interfaces.InterfaceAlias, "VPN")
} Else {
    Clear-Host

    Write-Host -ForegroundColor Green "Interfaces"
    For ($int = 0; $int -lt $interfaces.count; $int++){
        Write-Host -ForegroundColor Yellow "$int. " -NoNewline
        Write-Host $interfaces[$int].InterfaceAlias
    }
    Write-Output ""
    $int = Read-Host -Prompt "What interface is the VPN"
}
$intAlias = $interfaces[$int].InterfaceAlias
Clear-Host

If ($interfaces[$int].AutomaticMetric -eq "Enabled"){
    Write-Output "Disabled auto interface on $intAlias"
    Set-NetIPInterface @DisableAutometric `
        -InterfaceAlias $intAlias `
        -AddressFamily IPv4
    Set-NetIPInterface @DisableAutometric `
        -InterfaceAlias $intAlias `
        -AddressFamily IPv6
} Else {
    Write-Output "Enabled auto interface on $intAlias"
    Set-NetIPInterface @EnableAutoMetric `
        -InterfaceAlias $intAlias `
        -AddressFamily IPv4
    Set-NetIPInterface @EnableAutoMetric `
        -InterfaceAlias $intAlias `
        -AddressFamily IPv6
} 

$routes = @("172.20.0.0/16", "10.5.0.0/16", "10.85.0.0/16")

ForEach($route in $routes){
    If (
        Get-NetRoute `
            -InterfaceAlias $intAlias `
            -DestinationPrefix $route
    ){
        Write-Host "Updated route for $route"
        Set-NetRoute @PriorityRoute `
            -InterfaceAlias $intAlias `
            -DestinationPrefix $route
    } Else {
        Write-Host "Created route for $route"
        New-NetRoute @PriorityRoute `
            -InterfaceAlias $intAlias `
            -DestinationPrefix $route
    }
}

If ($intAlias -ne "VPN" -and ((Get-NetAdapter).Name -notcontains "VPN")){
    $ren = Read-Host -Prompt "Rename interface to VPN?"
    If ($ren -eq "y"){
        Rename-NetAdapter -Name $intAlias -NewName "VPN"
    }
}