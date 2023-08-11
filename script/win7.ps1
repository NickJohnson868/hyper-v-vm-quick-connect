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

# ��ȡ����� IP ��ַ
$server = (Get-VMNetworkAdapter -VMName $vmName | Select-Object -ExpandProperty IPAddresses)[0]

$username = "62453"
$password = "1"

cmdkey /generic:TERMSRV/$server /user:"$username" /pass:"$password"
mstsc /v:$server /f

cmdkey /delete:TERMSRV/$server