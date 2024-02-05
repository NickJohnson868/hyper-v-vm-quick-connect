Set-ExecutionPolicy Restricted
Write-Host "策略设置为 Restricted`n"

$vmNames = @(Get-VM | Select-Object -ExpandProperty Name)

# $InfoType = @{
#     UNKNOWN  = 0
#     SUCCESS  = 1
#     ERROR    = 2
#     WARNING  = 3
#     REMINDER = 4
# }

# function Print($text, $type) {
#     $colors = @{
#         $InfoType.SUCCESS  = "Green"
#         $InfoType.ERROR    = "Red"
#         $InfoType.WARNING  = "DarkYellow"
#         $InfoType.REMINDER = "Blue"
#     }
    
#     $color = $colors[$type] -or "White"
#     Write-Host $text -ForegroundColor $color
# }

function Show-Menu {
    Write-Host "请选择要连接的虚拟机："
    $vmStatuses = Get-VM | Select-Object -ExpandProperty State
    $vmItems = @()
    for ($i = 0; $i -lt $vmNames.Length; $i++) {
        $vmItems += "[ $($i + 1)  ]`t$($vmNames[$i]) ($($vmStatuses[$i]))"
    }
    $vmItems += "[ x  ]`t关闭所有虚拟机"
    $vmItems += "[ x* ]`t关闭某个虚拟机"
    $vmItems += "[ r* ]`t重启某个虚拟机"
    $vmItems += "[ q  ]`t退出程序"
    $vmItems += "[ c  ]`t清空屏幕"
    $vmItems += "[ qx ]`t关闭所有虚拟机&退出程序"
    $vmItems | ForEach-Object { Write-Host $_ }
}

function Stop-AllVMs {
    Write-Host "正在关闭所有虚拟机..."
    Get-VM | Where-Object { $_.State -eq 'Running' } | Stop-VM
    Write-Host "所有虚拟机均已关闭`n" -ForegroundColor Green
}

function Start-VMByName($vmName) {
    $vm = Get-VM -VMName $vmName
    if ($vm.State -ne "Running") {
        Write-Host "正在启动虚拟机..."
        Start-VM -VMName $vmName
        do {
            Start-Sleep -Seconds 1
            $vm = Get-VM -VMName $vmName
            Write-Host "." -NoNewline
        } while ($vm.State -ne "Running")
        Write-Host "."
        Write-Host "虚拟机已启动完毕" -ForegroundColor Green
    }
}

function Get-VMIPAddress($vmName) {
    Write-Host "尝试获取虚拟机IP..."
    $startTime = Get-Date
    do {
        $ipAddresses = Get-VMNetworkAdapter -VMName $vmName | Select-Object -ExpandProperty IPAddresses
        if (((Get-Date) - $startTime).TotalSeconds -gt 15) {
            Write-Host "."
            Write-Host "获取IP超时" -ForegroundColor Red
            return $null
        }
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
    } while ($ipAddresses.Length -eq 0)
    Write-Host "."
    return $ipAddresses[0]
}

function Connect-ToVM($server) {
    mstsc /v:$server /f
}

function Run {
    while ($true) {
        Show-Menu
        Write-Host "请输入您的选择：" -NoNewline -ForegroundColor Blue 
        $choice = Read-Host
        switch ($choice) {
            "q" {
                exit
            }
            "c" {
                clear
            }
            { $_ -in "x", "qx" } {
                Stop-AllVMs
                if ($choice -eq "qx") { exit }
            }
            { $_ -match "^[xr]\d+$" } {
                $action = $_.Substring(0, 1)
                $index = [int]$_.Substring(1)
                if ($index -gt 0 -and $index -le $vmNames.Length) {
                    $vm = Get-VM -Name $vmNames[$index - 1]
                    if ($vm.State -eq 'Running') {
                        if ($action -eq "x") { Stop-VM -Name $vm.Name }
                        elseif ($action -eq "r") { Restart-VM -Name $vm.Name }
                    } else {
                        Write-Host ("该虚拟机" + ("已关闭", "未启动")[$action -eq "r"] + "`n") -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host "没有对应的虚拟机`n" -ForegroundColor Red
                }
            }
            default {
                if ($choice -match "^\d+$") {
                    if ([int]$choice -le 0 -or [int]$choice -gt $vmNames.Length) {
                        Write-Host "没有对应的虚拟机`n" -ForegroundColor Red
                    } else {
                        $vmName = $vmNames[[int]$choice - 1]
                        Start-VMByName $vmName
                        $server = Get-VMIPAddress $vmName
                        if ($server) {
                            Write-Host "正在连接虚拟机..."
                            Connect-ToVM $server
                            Write-Host "`t`t"
                        }
                    }
                } else {
                    Write-Host "输入的命令不合法`n" -ForegroundColor Red
                }
            }
        }
    }
}

Run