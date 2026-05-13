# Codemod Wave 2: thay AppColors.X -> context.palette.X
# và đổi import color_constants -> app_palette.
# Chạy: powershell -File tool/migrate_appcolors.ps1
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$skip = @(
  'lib\app\core\theme\app_palette.dart',
  'lib\app\core\constants\color_constants.dart',
  'lib\app\providers\theme_provider.dart'
)

$files = Get-ChildItem -Path lib -Recurse -Filter *.dart |
  Where-Object { $skip -notcontains ($_.FullName.Substring((Get-Location).Path.Length + 1)) }

$totalEdits = 0
$touchedFiles = 0
foreach ($f in $files) {
  $original = Get-Content -Raw -Path $f.FullName
  if (-not ($original -match 'AppColors\.')) {
    continue
  }
  $new = $original

  # Đổi import color_constants -> app_palette.
  $new = $new -replace "import 'package:hanziilearnapp/app/core/constants/color_constants.dart';", "import 'package:hanziilearnapp/app/core/theme/app_palette.dart';"

  # Codemod chính: AppColors.X -> context.palette.X
  $new = [regex]::Replace($new, 'AppColors\.(\w+)', 'context.palette.$1')

  if ($new -ne $original) {
    $editCount = ([regex]::Matches($original, 'AppColors\.\w+')).Count
    $totalEdits += $editCount
    $touchedFiles++
    Set-Content -Path $f.FullName -Value $new -Encoding UTF8 -NoNewline
    Write-Host ("{0,4} edits in {1}" -f $editCount, $f.FullName.Substring((Get-Location).Path.Length + 1))
  }
}

Write-Host ""
Write-Host ("Done. Total edits: {0} in {1} files." -f $totalEdits, $touchedFiles)
