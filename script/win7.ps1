Set-ExecutionPolicy Restricted
Write-Host "策略设置为 Restricted`n"

# 定义虚拟机名称数组
$vmNames = @(Get-VM | Select-Object -ExpandProperty Name)

# 定义显示选择菜单的函数
function Show-Menu 
{
    Write-Host "请选择要连接的虚拟机："
    $vmStatuses = Get-VM | Select-Object -ExpandProperty State
    for ($i = 0; $i -lt $vmNames.Length; $i++)
    {
        Write-Host ("[ " + ($i + 1) + "  ]`t" + $vmNames[$i] + " (" + $vmStatuses[$i] + ")")
    }
    Write-Host "[ x  ]`t关闭所有虚拟机"
    Write-Host "[ x* ]`t关闭某个虚拟机"
    Write-Host "[ r* ]`t重启某个虚拟机"
    Write-Host "[ q  ]`t退出程序"
    Write-Host "[ qx ]`t关闭所有虚拟机&退出程序"
}

# 定义关闭所有虚拟机的函数
function Stop-AllVMs 
{
    Write-Host "正在关闭所有虚拟机..."
    Get-VM | Where-Object {$_.State -eq 'Running'} | Stop-VM
    Write-Host "所有虚拟机均已关闭`n" -ForegroundColor Green
}

# 定义启动虚拟机的函数
function Start-VMByName($vmName) 
{
    # 检查虚拟机状态
    $vm = Get-VM -VMName $vmName
    if ($vm.State -ne "Running")
    {
        # 启动虚拟机
        Write-Host "正在启动虚拟机..."
        Start-VM -VMName $vmName

        # 等待虚拟机启动完毕
        do
        {
            Start-Sleep -Seconds 1
            $vm = Get-VM -VMName $vmName
            Write-Host "." -NoNewline
        } while ($vm.State -ne "Running")

        Write-Host "."
        Write-Host "虚拟机已启动完毕" -ForegroundColor Green
    }
}

# 定义获取虚拟机 IP 地址的函数
function Get-VMIPAddress($vmName) 
{
    # 获取虚拟机 IP 地址
    Write-Host "尝试获取虚拟机IP..."
    $startTime = Get-Date

    do
    {
        $ipAddresses = Get-VMNetworkAdapter -VMName $vmName | Select-Object -ExpandProperty IPAddresses
        if (((Get-Date) - $startTime).TotalSeconds -gt 15)
        {
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

# 定义连接到虚拟机的函数
function Connect-ToVM($server, $uname, $pass) 
{
    mstsc /v:$server /f

    # cmdkey /generic:TERMSRV/$server /user:"$uname" /pass:"$pass"
    # mstsc /v:$server /f
    # cmdkey /delete:TERMSRV/$server
}

# 定义关闭虚拟机防火墙的函数
function Disable-VMFirewall($vmName) 
{
    Invoke-Command -VMName $vmName -ScriptBlock {
        netsh advfirewall set allprofiles state off
    }

    Write-Host "已关闭 $vmName 的防火墙`n"
}

function Run() 
{
    while ($true)
    {
        # 显示选择菜单并获取用户输入
        Show-Menu

        Write-Host "请输入您的选择：" -NoNewline -ForegroundColor Blue 
        $choice = Read-Host

        # 处理用户输入
        switch ($choice)
        {
            "q" { exit }
            "x" { Stop-AllVMs; break }
            "qx" { Stop-AllVMs; exit }
            { $_ -like "x*" }
            {
                $index = $_.Substring(1)
                if ($index -match "^\d+$")
                {
                    if ([int]$index -gt 0 -and [int]$index -le $vmNames.Length)
                    {
                        $vm = Get-VM -Name $vmNames[$index - 1]
                        if ($vm.State -eq 'Running')
                        {
                            Stop-VM -Name $vm.Name
                        }
                        else
                        {
                            Write-Host "该虚拟机已经关闭`n" -ForegroundColor DarkGray
                        }
                    }
                    else
                    {
                        Write-Host "没有对应的虚拟机`n" -ForegroundColor Red
                    }
                }
                else
                {
                    Write-Host "输入的命令不合法`n" -ForegroundColor Red
                }
                break
            }
            { $_ -like "r*" }
            {
                $index = $_.Substring(1)
                if ($index -match "^\d+$")
                {
                    if ([int]$index -gt 0 -and [int]$index -le $vmNames.Length)
                    {
                        $vm = Get-VM -Name $vmNames[$index - 1]
                        if ($vm.State -eq 'Running')
                        {
                            Restart-VM -Name $vm.Name
                        }
                        else
                        {
                            Write-Host "该虚拟机未启动`n" -ForegroundColor DarkGray
                        }
                    }
                    else
                    {
                        Write-Host "没有对应的虚拟机`n" -ForegroundColor Red
                    }
                }
                else
                {
                    Write-Host "输入的命令不合法`n" -ForegroundColor Red
                }
                break
            }
            default
            {
                if ($choice -match "^\d+$")
                {
                    if ([int]$choice -le 0 -or [int]$choice -gt $vmNames.Length)
                    {
                        Write-Host "没有对应的虚拟机`n" -ForegroundColor Red
                    }
                    else
                    {
                        # 获取虚拟机名称并启动虚拟机
                        $vmName = $vmNames[[int]$choice - 1]
                        Start-VMByName $vmName
    
                        # 获取虚拟机 IP 地址并连接到虚拟机
                        $server = Get-VMIPAddress $vmName
    
                        if ($server)
                        {
                            Write-Host "正在连接虚拟机..."
                            Connect-ToVM $server
                            Write-Host "`t`t"
                        }
                    }
                }
                else
                {
                    Write-Host "输入的命令不合法`n" -ForegroundColor Red
                }
                break
            }
        }
    }
}

Run