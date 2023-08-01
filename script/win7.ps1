$server = (Get-VMNetworkAdapter -VMName "Windows 7 x64" | Select-Object -ExpandProperty IPAddresses)[0]

$username = "johnson"
$password = "33872006"

cmdkey /generic:TERMSRV/$server /user:"$username" /pass:"$password"
mstsc /v:$server /f

cmdkey /delete:TERMSRV/$server