Set-ExecutionPolicy Restricted
Write-Host "��������Ϊ Restricted`n"

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
    Write-Host "[ r* ]`t����ĳ�������"
    Write-Host "[ q  ]`t�˳�����"
    Write-Host "[ qx ]`t�ر����������&�˳�����"
}

# ����ر�����������ĺ���
function Stop-AllVMs 
{
    Write-Host "���ڹر����������..."
    Get-VM | Where-Object {$_.State -eq 'Running'} | Stop-VM
    Write-Host "������������ѹر�`n" -ForegroundColor Green
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
        Write-Host "��������������" -ForegroundColor Green
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
            Write-Host "��ȡIP��ʱ" -ForegroundColor Red
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

        Write-Host "����������ѡ��" -NoNewline -ForegroundColor Blue 
        $choice = Read-Host

        # �����û�����
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
                            Write-Host "��������Ѿ��ر�`n" -ForegroundColor DarkGray
                        }
                    }
                    else
                    {
                        Write-Host "û�ж�Ӧ�������`n" -ForegroundColor Red
                    }
                }
                else
                {
                    Write-Host "���������Ϸ�`n" -ForegroundColor Red
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
                            Write-Host "�������δ����`n" -ForegroundColor DarkGray
                        }
                    }
                    else
                    {
                        Write-Host "û�ж�Ӧ�������`n" -ForegroundColor Red
                    }
                }
                else
                {
                    Write-Host "���������Ϸ�`n" -ForegroundColor Red
                }
                break
            }
            default
            {
                if ($choice -match "^\d+$")
                {
                    if ([int]$choice -le 0 -or [int]$choice -gt $vmNames.Length)
                    {
                        Write-Host "û�ж�Ӧ�������`n" -ForegroundColor Red
                    }
                    else
                    {
                        # ��ȡ��������Ʋ����������
                        $vmName = $vmNames[[int]$choice - 1]
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
                }
                else
                {
                    Write-Host "���������Ϸ�`n" -ForegroundColor Red
                }
                break
            }
        }
    }
}

Run