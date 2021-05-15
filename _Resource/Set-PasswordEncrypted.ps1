Function Set-PasswordEncrypted() {
<# 
.SYNOPSIS Эта функция шифрует пароль и сохраняет в реестр для последующего получения функцией Get-PasswordFromKeePass. 
.DESCRIPTION Эта функция сохранит пароль, зашифрованный таким образом, что пароль сможет расшифровать только текущая учетная запись, в кусте реестра HKCU текущей учетной записи. Пароль в последующем может быть использован функцией Get-PasswordFromKeePass. 
.PARAMETER Name Имя пароля, необходимо для последующего извлечения этого пароля из реестра. 
.PARAMETER PlainPassword Пароль в виде нешифрованного текста. 
.EXAMPLE Set-PasswordEncrypted -Name 'saqwel' -PlainPassword 'P@ssw0rd' 
#>
     param(
        [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$Name,
        [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$PlainPassword
    )
 
    $SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
    $RegPath = "HKCU:\Software\Passwords"
    if(!(Test-Path -Path $RegPath)) {
        New-Item -Path $RegPath -Confirm:$false -Force -ErrorAction Stop | Out-Null
    } else {
        New-ItemProperty -Path $RegPath -Name $Name -Value $SecurePassword -Force -ErrorAction Stop | Out-Null
    }


}

Set-PasswordEncrypted -Name 'KeePassPassword' -PlainPassword '123456789' 