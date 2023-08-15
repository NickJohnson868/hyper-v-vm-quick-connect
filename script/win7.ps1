Set-ExecutionPolicy Restricted

# �����������������
$vmNames = @(Get-VM | Select-Object -ExpandProperty Name)

# ������ʾѡ��˵��ĺ���
function Show-Menu 
{
    Write-Host "��ѡ��Ҫ���ӵ��������"
    $vmStatuses = Get-VM | Select-Object -ExpandProperty State
    for ($i = 0; $i -lt $vmNames.Length; $i++)
    {
        Write-Host ("[ " + ($i + 1) + "  ]`t" + $vmNames[$i] + " (" + $vmStatuses[$i] + ")")
    }
    Write-Host "[ x  ]`t�ر����������"
    Write-Host "[ x* ]`t�ر�ĳ�������"
    Write-Host "[ q  ]`t�˳�"
    Write-Host "[ qx ]`t�ر������Ȼ���˳�"
}

# ����ر�����������ĺ���
function Stop-AllVMs 
{
    Write-Host "���ڹر����������..."
    Get-VM | Where-Object {$_.State -eq 'Running'} | Stop-VM
    Write-Host "������������ѹر�`n"
}

# ��������������ĺ���
function Start-VMByName($vmName) 
{
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
            Write-Host "." -NoNewline
        } while ($vm.State -ne "Running")

        Write-Host "."
        Write-Host "��������������"
    }
}

# �����ȡ����� IP ��ַ�ĺ���
function Get-VMIPAddress($vmName) 
{
    # ��ȡ����� IP ��ַ
    Write-Host "���Ի�ȡ�����IP..."
    $startTime = Get-Date

    do
    {
        $ipAddresses = Get-VMNetworkAdapter -VMName $vmName | Select-Object -ExpandProperty IPAddresses
        if (((Get-Date) - $startTime).TotalSeconds -gt 15)
        {
            Write-Host "."
            Write-Host "��ȡIP��ʱ"
            return $null
        }
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
    } while ($ipAddresses.Length -eq 0)

    Write-Host "."
    return $ipAddresses[0]
}

# �������ӵ�������ĺ���
function Connect-ToVM($server, $uname, $pass) 
{
    mstsc /v:$server /f

    # cmdkey /generic:TERMSRV/$server /user:"$uname" /pass:"$pass"
    # mstsc /v:$server /f
    # cmdkey /delete:TERMSRV/$server
}

# ����ر����������ǽ�ĺ���
function Disable-VMFirewall($vmName) 
{
    Invoke-Command -VMName $vmName -ScriptBlock {
        netsh advfirewall set allprofiles state off
    }

    Write-Host "�ѹر� $vmName �ķ���ǽ`n"
}
function Run() 
{
    while ($true)
    {
        # ��ʾѡ��˵�����ȡ�û�����
        Show-Menu

        $choice = Read-Host "����������ѡ��"

        # �����û�����
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
                    Write-Host "��������Ѿ��ر�`n"
                }
                else
                {
                    Write-Host "���벻�Ϸ�`n"
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
            #         Write-Host "���벻�Ϸ�`n"
            #     }
            #     break
            # }
            default
            {
                if ($choice -le 0 -or $choice -gt $vmNames.Length)
                {
                    Write-Host "���벻�Ϸ�`n"
                }
                else
                {
                    # ��ȡ��������Ʋ����������
                    $vmName = $vmNames[$choice - 1]
                    Start-VMByName $vmName

                    # ��ȡ����� IP ��ַ�����ӵ������
                    $server = Get-VMIPAddress $vmName

                    if ($server)
                    {
                        Write-Host "�������������..."
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