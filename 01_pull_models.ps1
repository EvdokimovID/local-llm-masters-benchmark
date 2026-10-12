# Шаг 1. Загрузка моделей в Ollama (нужен интернет, суммарно ~60 ГБ).
. (Join-Path $PSScriptRoot 'common.ps1')
foreach ($m in Load-Models) {
    Write-Host "=== Загрузка: $($m.name) [$($m.tag)]" -ForegroundColor Cyan
    & ollama pull $m.tag
    if ($LASTEXITCODE -ne 0) { Write-Host "  Не удалось загрузить $($m.tag). См. раздел «Если что-то пошло не так» в инструкции." -ForegroundColor Red }
}
& ollama list
