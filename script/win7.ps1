# �����������������
$vmNames = Get-VM | Select-Object -ExpandProperty Name

# ������ʾѡ��˵��ĺ���
function Show-Menu {
    Write-Host "��ѡ��Ҫ���ӵ��������"
    $vmStatuses = Get-VM | Select-Object -ExpandProperty State
    for ($i = 0; $i -lt $vmNames.Length; $i++)
    {
        Write-Host ("[" + ($i + 1) + "]`t" + $vmNames[$i] + "(" + $vmStatuses[$i] + ")")
    }
    Write-Host "[x]`t�ر����������"
    Write-Host "[q]`t�˳�"
}

# ����ر�����������ĺ���
function Stop-AllVMs {
    Write-Host "���ڹر����������..."
    Get-VM | where {$_.State -eq 'Running'} | Stop-VM
    Write-Host "�ر����`n"
}

# ��������������ĺ���
function Start-VMByName($vmName) {
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
}

# �����ȡ����� IP ��ַ�ĺ���
function Get-VMIPAddress($vmName) {
    # ��ȡ����� IP ��ַ
    Write-Host "���Ի�ȡ�����IP..."
    $startTime = Get-Date
    do
    {
        $ipAddresses = Get-VMNetworkAdapter -VMName $vmName | Select-Object -ExpandProperty IPAddresses
        if ($ipAddresses.Length -eq 0)
        {
            Start-Sleep -Seconds 1
            if (((Get-Date) - $startTime).TotalSeconds -gt 10)
            {
                Write-Host "��ȡIP��ʱ"
                return $null
            }
        }
        Write-Host "..."
    } while ($ipAddresses.Length -eq 0)

    return $ipAddresses[0]
}

# �������ӵ�������ĺ���
function Connect-ToVM($server, $username, $password) {
    cmdkey /generic:TERMSRV/$server /user:"$username" /pass:"$password"
    mstsc /v:$server /f

    cmdkey /delete:TERMSRV/$server
}

while ($true)
{
    # ��ʾѡ��˵�����ȡ�û�����
    Show-Menu
    $choice = Read-Host "����������ѡ��"

    # �����û�����
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
        Write-Host "���벻�Ϸ�`n"
        continue
    }

    # ��ȡ��������Ʋ����������
    $vmName = $vmNames[$choice - 1]
    Start-VMByName $vmName

    # ��ȡ����� IP ��ַ�����ӵ������
    $server = Get-VMIPAddress $vmName

    if ($server)
    {
        Write-Host "�������������..."
        Connect-ToVM $server "62453" "1"
    }
}