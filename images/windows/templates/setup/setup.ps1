#
# Prepare a fresh clone of our winserver template VM for action runner installs 
#

Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"

# Switch network connection to private mode
$profile = Get-NetConnectionProfile
Set-NetConnectionProfile -Name $profile.Name -NetworkCategory Private

# Configure WinRM to allow basic auth
cmd.exe /c winrm set "winrm/config/service/auth" '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{CredSSP="true"}'

# netsh firewall add portopening TCP 5986 "Port 5986"
netsh advfirewall firewall add rule name= "WinRM HTTPS" dir=in action=allow protocol=TCP localport=5986 profile=private

# Enable ping&smb SMB
netsh advfirewall firewall set rule name= "File and Printer Sharing (Echo Request - ICMPv4-In)" new enable=yes profile=private
netsh advfirewall firewall set rule name= "File and Printer Sharing (SMB-In)" new enable=yes profile=private

# Restart WinRM
cmd.exe /c net stop winrm
cmd.exe /c net start winrm

# No more need for this
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value 0
# Annoying
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask

# Disable recovery partition and grow C: to fill the disk
reagentc /disable
diskpart /s a:\diskpart.txt

# Fix up the system languages
$user_lang = New-WinUserLanguageList -Language en-SE
$user_lang.add("en-US")
Set-WinUserLanguageList -Force -LanguageList $user_lang

Set-WinSystemLocale -SystemLocale en-US
Set-WinUILanguageOverride -Language en-US
Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True
