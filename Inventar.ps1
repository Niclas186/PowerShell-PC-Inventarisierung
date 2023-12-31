# PowerShell CSV PC Inventar Skript
# Inventar.ps1
# Version 1.0
# 
# Dieses PowerShell-Skript erfasst das Datum der Bestandsaufnahme, die IP- und MAC-Adresse, die Seriennummer, das Modell, die CPU, den RAM, die Gesamtspeichergröße, die GPU(s), das Betriebssystem, den Betriebssystem-Build, den angemeldeten Benutzer und die angeschlossenen Monitore. eines Computers.
# Nachdem diese Informationen gesammelt wurden, werden sie in eine CSV-Datei ausgegeben. Zunächst wird die CSV-Datei (sofern vorhanden) überprüft, um festzustellen, ob der Hostname bereits in der Datei vorhanden ist.
# Wenn der Hostname in der CSV-Datei vorhanden ist, wird er mit den neuesten Informationen überschrieben, sodass das Inventar auf dem neuesten Stand ist und keine doppelten Informationen vorhanden sind.
# Es ist für die Ausführung als Anmeldeskript und/oder als geplante/unmittelbare Aufgabe durch einen Domänenbenutzer konzipiert. Erweiterte Berechtigungen sind nicht erforderlich.
#
# WICHTIG: Teile die auf die Umgebung angepasst wurden sind markiert (##). 

## Speicherort der CSV-Datei (Wenn dieser nicht vorhanden ist, versucht das Skript, ihn zu erstellen. Benutzer benötigen die volle Kontrolle über die Datei
$csv = "\\your\CSV\path"

## Error log path (Optional, aber empfohlen. Wenn dieser nicht vorhanden ist, versucht das Skript, ihn zu erstellen. Benutzer benötigen vollständige Kontrolle über die Datei)
$ErrorLogPath = "\\your\error\path"

Write-Host "Gathering inventory information..."

# Datum
$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# IP
$IP = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway -ne $null }).IPAddress | Select-Object -First 1

# MAC address
$MAC = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway -ne $null } | Select-Object -ExpandProperty MACAddress

# Seriennummer
$SN = Get-WmiObject -Class Win32_Bios | Select-Object -ExpandProperty SerialNumber

# Model
$Model = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model

# CPU
$CPU = Get-WmiObject -Class win32_processor | Select-Object -ExpandProperty Name

# RAM
$RAM = Get-WmiObject -Class Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | ForEach-Object { [math]::Round(($_.sum / 1GB),2) }

# Speicher
$Storage = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$env:systemdrive'" | ForEach-Object { [math]::Round($_.Size / 1GB,2) }

#GPU(s)
function GetGPUInfo {
  $GPUs = Get-WmiObject -Class Win32_VideoController
  foreach ($GPU in $GPUs) {
    $GPU | Select-Object -ExpandProperty Description
  }
}

# GPU
$GPU0 = GetGPUInfo | Select-Object -Index 0
$GPU1 = GetGPUInfo | Select-Object -Index 1

# OS
$OS = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption

# OS Build
$OSBuild = (Get-Item "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue('ReleaseID')

# Username
$Username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Monitor(s)
function GetMonitorInfo {
  $Monitors = Get-WmiObject -Namespace "root\WMI" -Class "WMIMonitorID"
  foreach ($Monitor in $Monitors) {
    ([System.Text.Encoding]::ASCII.GetString($Monitor.ManufacturerName)).Replace("$([char]0x0000)","")
    ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName)).Replace("$([char]0x0000)","")
    ([System.Text.Encoding]::ASCII.GetString($Monitor.SerialNumberID)).Replace("$([char]0x0000)","")
  }
}

# Monitor
$Monitor1 = GetMonitorInfo | Select-Object -Index 0,1
$Monitor1SN = GetMonitorInfo | Select-Object -Index 2
$Monitor2 = GetMonitorInfo | Select-Object -Index 3,4
$Monitor2SN = GetMonitorInfo | Select-Object -Index 5
$Monitor3 = GetMonitorInfo | Select-Object -Index 6,7
$Monitor3SN = GetMonitorInfo | Select-Object -Index 8

$Monitor1 = $Monitor1 -join ' '
$Monitor2 = $Monitor2 -join ' '
$Monitor3 = $Monitor3 -join ' '

# Computertyp
$Chassis = Get-CimInstance -ClassName Win32_SystemEnclosure -Namespace 'root\CIMV2' -Property ChassisTypes | Select-Object -ExpandProperty ChassisTypes
# Chassiswerte stammen von https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-systemenclosure
if ($Chassis -eq "1") {
  $Chassis = "Other"
}
if ($Chassis -eq "2") {
  $Chassis = "Unknown"
}
if ($Chassis -eq "3") {
  $Chassis = "Desktop"
}
if ($Chassis -eq "4") {
  $Chassis = "Low Profile Desktop"
}
if ($Chassis -eq "5") {
  $Chassis = "Pizza Box"
}
if ($Chassis -eq "6") {
  $Chassis = "Mini Tower"
}
if ($Chassis -eq "7") {
  $Chassis = "Tower"
}
if ($Chassis -eq "8") {
  $Chassis = "Portable"
}
if ($Chassis -eq "9") {
  $Chassis = "Laptop"
}
if ($Chassis -eq "10") {
  $Chassis = "Notebook"
}
if ($Chassis -eq "11") {
  $Chassis = "Hand Held"
}
if ($Chassis -eq "12") {
  $Chassis = "Docking Station"
}
if ($Chassis -eq "13") {
  $Chassis = "All in One"
}
if ($Chassis -eq "14") {
  $Chassis = "Sub Notebook"
}
if ($Chassis -eq "15") {
  $Chassis = "Space-Saving"
}
if ($Chassis -eq "16") {
  $Chassis = "Lunch Box"
}
if ($Chassis -eq "17") {
  $Chassis = "Main System Chassis"
}
if ($Chassis -eq "18") {
  $Chassis = "Expansion Chassis"
}
if ($Chassis -eq "19") {
  $Chassis = "SubChassis"
}
if ($Chassis -eq "20") {
  $Chassis = "Bus Expansion Chassis"
}
if ($Chassis -eq "21") {
  $Chassis = "Peripheral Chassis"
}
if ($Chassis -eq "22") {
  $Chassis = "Storage Chassis"
}
if ($Chassis -eq "23") {
  $Chassis = "Rack Mount Chassis"
}
if ($Chassis -eq "24") {
  $Chassis = "Sealed-Case PC"
}
if ($Chassis -eq "35") {
  $Chassis = "Mini PC"
}


# Funktion um das Inventar in die CSV. zu schreiben
function OutputToCSV {
  Write-Host "Adding inventory information to the CSV file..."
  $infoObject = New-Object PSObject
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Date Collected" -Value $Date
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "IP Address" -Value $IP
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Hostname" -Value $env:computername
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "MAC Address" -Value $MAC
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "User" -Value $Username
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Type" -Value $Chassis
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Serial Number/Service Tag" -Value $SN
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Model" -Value $Model
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "CPU" -Value $CPU
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "RAM (GB)" -Value $RAM
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Storage (GB)" -Value $Storage
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "GPU 0" -Value $GPU0
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "GPU 1" -Value $GPU1
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "OS" -Value $OS
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "OS Version" -Value $OSBuild
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 1" -Value $Monitor1
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 1 Serial Number" -Value $Monitor1SN
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 2" -Value $Monitor2
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 2 Serial Number" -Value $Monitor2SN
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 3" -Value $Monitor3
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 3 Serial Number" -Value $Monitor3SN
  $infoObject
  $infoColl += $infoObject

  # Output in die CSV file
  try {
    $infoColl | Export-Csv -Path $csv -NoTypeInformation -Append
    Write-Host -ForegroundColor Green "Inventory was successfully updated!"
    # Clean up empty rows
    (Get-Content $csv) -notlike ",,,,,,,,,,,,,,,,,,,,*" | Set-Content $csv
    exit 0
  }
  catch {
    if (-not (Test-Path $ErrorLogPath))
    {
      New-Item -ItemType "file" -Path $ErrorLogPath
      icacls $ErrorLogPath /grant Everyone:F
    }
    Add-Content -Path $ErrorLogPath -Value "[$Date] $Username at $env:computername was unable to export to the inventory file at $csv."
    throw "Unable to export to the CSV file. Please check the permissions on the file."
    exit 1
  }
}

# Für den Fall, dass die CSV-Inventardatei nicht vorhanden ist, erstellen Sie die Datei und führen Sie die Inventarisierung aus.
if (-not (Test-Path $csv))
{
  Write-Host "Creating CSV file..."
  try {
    New-Item -ItemType "file" -Path $csv
    icacls $csv /grant Everyone:F
    OutputToCSV
  }
  catch {
    if (-not (Test-Path $ErrorLogPath))
    {
      New-Item -ItemType "file" -Path $ErrorLogPath
      icacls $ErrorLogPath /grant Everyone:F
    }
    Add-Content -Path $ErrorLogPath -Value "[$Date] $Username at $env:computername was unable to create the inventory file at $csv."
    throw "Unable to create the CSV file. Please check the permissions on the file."
    exit 1
  }
}

# Überprüfen Sie, ob die CSV-Datei vorhanden ist, und führen Sie dann das Skript aus..
function Check-IfCSVExists {
  Write-Host "Es wird geprüft ob die CSV-Datei existiert"
  $import = Import-Csv $csv
  if ($import -match $env:computername)
  {
    try {
      (Get-Content $csv) -notmatch $env:computername | Set-Content $csv
      OutputToCSV
    }
    catch {
      if (-not (Test-Path $ErrorLogPath))
      {
        New-Item -ItemType "file" -Path $ErrorLogPath
        icacls $ErrorLogPath /grant Everyone:F
      }
      Add-Content -Path $ErrorLogPath -Value "[$Date] $Username at $env:computername was unable to import and/or modify the inventory file located at $csv."
      throw "Unable to import and/or modify the CSV file. Please check the permissions on the file."
      exit 1
    }
  }
  else
  {
    OutputToCSV
  }
}

Check-IfCSVExists
