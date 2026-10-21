# Instala ou atualiza o Conciliador Stone (Bar do Sabao) neste computador.
# Uso no PowerShell:
#   irm https://raw.githubusercontent.com/FilipeNsdev/conciliador-stone-app/main/install.ps1 | iex
# Nao precisa de administrador. Instala em %LOCALAPPDATA%\Programs\Conciliador Stone e cria atalhos.
# Mantenha este arquivo em ASCII.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
$base = 'https://raw.githubusercontent.com/FilipeNsdev/conciliador-stone-app/main'
$dir = Join-Path $env:LOCALAPPDATA 'Programs\Conciliador Stone'
$exe = Join-Path $dir 'Conciliador Stone.exe'

Write-Host ''
Write-Host '  Conciliador Stone - Bar do Sabao' -ForegroundColor White
Write-Host '  Baixando a versao mais nova...' -ForegroundColor DarkGray
$info = Invoke-RestMethod "$base/version.json?t=$([DateTime]::UtcNow.Ticks)" -Headers @{ 'Cache-Control' = 'no-cache' }
New-Item -ItemType Directory -Force $dir | Out-Null
$tmp = "$exe.download"
Invoke-WebRequest "$base/ConciliadorStone.exe?v=$($info.version)" -OutFile $tmp -UseBasicParsing
$hash = (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower()
if ($hash -ne $info.sha256.ToLower()) {
  Remove-Item $tmp -Force
  throw 'O arquivo baixado nao confere (pode ser cache do GitHub). Espere 5 minutos e rode o comando de novo.'
}

# Fecha o programa se estiver aberto e troca o arquivo
$running = Get-Process -Name 'Conciliador Stone' -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }
if ($running) { $running | ForEach-Object { $_.CloseMainWindow() | Out-Null }; Start-Sleep -Seconds 2; $running | Stop-Process -Force -ErrorAction SilentlyContinue }
Move-Item -Force $tmp $exe
Unblock-File $exe

# Atalhos na area de trabalho e no menu Iniciar
$shell = New-Object -ComObject WScript.Shell
$links = @(
  (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Conciliador Stone.lnk'),
  (Join-Path ([Environment]::GetFolderPath('Programs')) 'Conciliador Stone.lnk')
)
foreach ($path in $links) {
  $lnk = $shell.CreateShortcut($path)
  $lnk.TargetPath = $exe
  $lnk.WorkingDirectory = $dir
  $lnk.IconLocation = "$exe,0"
  $lnk.Description = 'Conciliador Stone - Bar do Sabao'
  $lnk.Save()
}

Write-Host "  Pronto: versao $($info.version) instalada." -ForegroundColor Green
Write-Host '  Atalho criado na area de trabalho e no menu Iniciar. O programa se atualiza sozinho.' -ForegroundColor DarkGray
Write-Host ''
Start-Process $exe
