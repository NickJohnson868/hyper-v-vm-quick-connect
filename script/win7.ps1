# �����������������
$vmNames = @("Windows 10 x64 LTSC", "Windows 7 x64")

while ($true)
{
    # ��ʾѡ��˵�
    Write-Host "��ѡ��Ҫ���ӵ��������"
    for ($i = 0; $i -lt $vmNames.Length; $i++)
    {
        Write-Host ("[" + ($i + 1) + "]`t" + $vmNames[$i])
    }
    Write-Host "[x]`t�ر����������"
    Write-Host "[q]`t�˳�"

    # ��ȡ�û�����
    $choice = Read-Host "����������ѡ��"
    if ($choice -eq "q")
    {
        exit
    }
    elseif ($choice -eq "x")
    {
        Write-Host "���ڹر����������..."
        Get-VM | where {$_.State -eq 'Running'} | Stop-VM
        Write-Host "�ر����`n"
        continue
    }

    # ��ȡ���������
    $vmName = $vmNames[$choice - 1]

    Write-Host ""
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
                continue
            }
        }
        Write-Host "..."
    } while ($ipAddresses.Length -eq 0)

    if ($ipAddresses.Length -gt 0)
    {
        Write-Host "�������������..."
        $server = $ipAddresses[0]

        $username = "62453"
        $password = "1"

        cmdkey /generic:TERMSRV/$server /user:"$username" /pass:"$password"
        mstsc /v:$server /f

        cmdkey /delete:TERMSRV/$server
    }
}