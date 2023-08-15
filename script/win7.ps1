Set-ExecutionPolicy Restricted

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
    Write-Host "[ q  ]`t退出"
    Write-Host "[ qx ]`t关闭虚拟机然后退出"
}

# 定义关闭所有虚拟机的函数
function Stop-AllVMs 
{
    Write-Host "正在关闭所有虚拟机..."
    Get-VM | Where-Object {$_.State -eq 'Running'} | Stop-VM
    Write-Host "所有虚拟机均已关闭`n"
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
        Write-Host "虚拟机已启动完毕"
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
            Write-Host "获取IP超时"
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

        $choice = Read-Host "请输入您的选择"

        # 处理用户输入
        switch ($choice)
        {
            "q" { exit }
            "x" { Stop-AllVMs; break }
            "qx" { Stop-AllVMs; exit }
            { $_ -like "x*" }
            {
                $index = $_.Substring(1)
                if ([int]::TryParse($index, [ref]$null) -and $index -gt 0 -and $index -le $vmNames.Length)
                {
                    $vm = Get-VM -Name $vmNames[$index - 1]
                    if ($vm.State -eq 'Running')
                    {
                        Stop-VM -Name $vm.Name
                    }
                    Write-Host "该虚拟机已经关闭`n"
                }
                else
                {
                    Write-Host "输入不合法`n"
                }
                break
            }
            # {$_ -like "f*"}
            # {
            #     $index = $_.Substring(1)
            #     if ([int]::TryParse($index, [ref]$null) -and $index -gt 0 -and $index -le $vmNames.Length)
            #     {
            #         $vmName = $vmNames[$index - 1]
            #         Disable-VMFirewall $vmName
            #     }
            #     else
            #     {
            #         Write-Host "输入不合法`n"
            #     }
            #     break
            # }
            default
            {
                if ($choice -le 0 -or $choice -gt $vmNames.Length)
                {
                    Write-Host "输入不合法`n"
                }
                else
                {
                    # 获取虚拟机名称并启动虚拟机
                    $vmName = $vmNames[$choice - 1]
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
                break
            }
        }
    }
}

Run