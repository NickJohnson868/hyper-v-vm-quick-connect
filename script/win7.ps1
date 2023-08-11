# �����������������
$vmNames = @("Windows 10 x64 LTSC", "Windows 7 x64")

# ��ʾѡ��˵�
Write-Host "��ѡ��Ҫ���ӵ��������"
for ($i = 0; $i -lt $vmNames.Length; $i++)
{
    Write-Host ("[" + ($i + 1) + "] " + $vmNames[$i])
}

# ��ȡ�û�����
$choice = Read-Host "����������ѡ��"
if ($choice -lt 1 -or $choice -gt $vmNames.Length)
{
    Write-Host "��Ч��ѡ��"
    exit
}

# ��ȡ���������
$vmName = $vmNames[$choice - 1]

# ��������״̬
$vm = Get-VM -VMName $vmName
if ($vm.State -ne "Running")
{
    # ���������
    Write-Host "�������������..."
    Start-VM -VMName $vmName

    # �ȴ�������������
    do
    {
        Start-Sleep -Seconds 1
        $vm = Get-VM -VMName $vmName
        Write-Host "..."
    } while ($vm.State -ne "Running")

    Write-Host "��������������"
}

# ��ȡ����� IP ��ַ
Write-Host "���Ի�ȡ�����IP..."
do
{
    $ipAddresses = Get-VMNetworkAdapter -VMName $vmName | Select-Object -ExpandProperty IPAddresses
    if ($ipAddresses.Length -eq 0)
    {
        Start-Sleep -Seconds 1
    }
    Write-Host "..."
} while ($ipAddresses.Length -eq 0)

Write-Host "�������������..."
$server = $ipAddresses[0]

$username = "62453"
$password = "1"

cmdkey /generic:TERMSRV/$server /user:"$username" /pass:"$password"
mstsc /v:$server /f

cmdkey /delete:TERMSRV/$server