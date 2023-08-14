# 定义虚拟机名称数组
$vmNames = Get-VM | Select-Object -ExpandProperty Name

# 定义显示选择菜单的函数
function Show-Menu {
    Write-Host "请选择要连接的虚拟机："
    $vmStatuses = Get-VM | Select-Object -ExpandProperty State
    for ($i = 0; $i -lt $vmNames.Length; $i++)
    {
        Write-Host ("[" + ($i + 1) + "]`t" + $vmNames[$i] + "(" + $vmStatuses[$i] + ")")
    }
    Write-Host "[x]`t关闭所有虚拟机"
    Write-Host "[q]`t退出"
}

# 定义关闭所有虚拟机的函数
function Stop-AllVMs {
    Write-Host "正在关闭所有虚拟机..."
    Get-VM | where {$_.State -eq 'Running'} | Stop-VM
    Write-Host "关闭完成`n"
}

# 定义启动虚拟机的函数
function Start-VMByName($vmName) {
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
            Write-Host "..."
        } while ($vm.State -ne "Running")

        Write-Host "虚拟机已启动完毕"
    }
}

# 定义获取虚拟机 IP 地址的函数
function Get-VMIPAddress($vmName) {
    # 获取虚拟机 IP 地址
    Write-Host "尝试获取虚拟机IP..."
    $startTime = Get-Date
    do
    {
        $ipAddresses = Get-VMNetworkAdapter -VMName $vmName | Select-Object -ExpandProperty IPAddresses
        if ($ipAddresses.Length -eq 0)
        {
            Start-Sleep -Seconds 1
            if (((Get-Date) - $startTime).TotalSeconds -gt 10)
            {
                Write-Host "获取IP超时"
                return $null
            }
        }
        Write-Host "..."
    } while ($ipAddresses.Length -eq 0)

    return $ipAddresses[0]
}

# 定义连接到虚拟机的函数
function Connect-ToVM($server, $username, $password) {
    cmdkey /generic:TERMSRV/$server /user:"$username" /pass:"$password"
    mstsc /v:$server /f

    cmdkey /delete:TERMSRV/$server
}

while ($true)
{
    # 显示选择菜单并获取用户输入
    Show-Menu
    $choice = Read-Host "请输入您的选择"

    # 处理用户输入
    if ($choice -eq "q")
    {
        exit
    }
    elseif ($choice -eq "x")
    {
        Stop-AllVMs
        continue
    }

    if ($choice -lt 0 -or $choice -gt $vmNames.Length)
    {
        Write-Host "输入不合法`n"
        continue
    }

    # 获取虚拟机名称并启动虚拟机
    $vmName = $vmNames[$choice - 1]
    Start-VMByName $vmName

    # 获取虚拟机 IP 地址并连接到虚拟机
    $server = Get-VMIPAddress $vmName

    if ($server)
    {
        Write-Host "正在连接虚拟机..."
        Connect-ToVM $server "62453" "1"
    }
}