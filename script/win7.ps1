# 定义虚拟机名称数组
$vmNames = @("Windows 10 x64 LTSC", "Windows 7 x64")

# 显示选择菜单
Write-Host "请选择要连接的虚拟机："
for ($i = 0; $i -lt $vmNames.Length; $i++)
{
    Write-Host ("[" + ($i + 1) + "] " + $vmNames[$i])
}

# 获取用户输入
$choice = Read-Host "请输入您的选择"
if ($choice -lt 1 -or $choice -gt $vmNames.Length)
{
    Write-Host "无效的选择"
    exit
}

# 获取虚拟机名称
$vmName = $vmNames[$choice - 1]

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

# 获取虚拟机 IP 地址
Write-Host "尝试获取虚拟机IP..."
do
{
    $ipAddresses = Get-VMNetworkAdapter -VMName $vmName | Select-Object -ExpandProperty IPAddresses
    if ($ipAddresses.Length -eq 0)
    {
        Start-Sleep -Seconds 1
    }
    Write-Host "..."
} while ($ipAddresses.Length -eq 0)

Write-Host "正在连接虚拟机..."
$server = $ipAddresses[0]

$username = "62453"
$password = "1"

cmdkey /generic:TERMSRV/$server /user:"$username" /pass:"$password"
mstsc /v:$server /f

cmdkey /delete:TERMSRV/$server