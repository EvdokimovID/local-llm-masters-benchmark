# Шаг 3. Ответы моделей на 5 типовых задач магистранта -> answers\<модель>\
param([string]$Only = '', [int[]]$Tasks = @(1, 2, 3, 4, 5))
. (Join-Path $PSScriptRoot 'common.ps1')
# Лимит 12288 токенов: моделям с рассуждением 4096 не хватало, ответ обрывался внутри рассуждения
$opts = @{ temperature = 0.3; seed = 42; num_ctx = 20480; num_predict = 12288 }
$models = Load-Models | Where-Object { -not $Only -or $_.name -like "*$Only*" }
foreach ($m in $models) {
    Write-Host "`n=== $($m.name)" -ForegroundColor Cyan
    Unload-All
    $dir = Join-Path $Root ('answers\' + (Safe-Name $m.name)); New-Item -ItemType Directory -Force -Path $dir | Out-Null
    foreach ($n in $Tasks) {
        $prompt = Read-Text "tasks\task$n.txt"
        $t0 = Get-Date
        $a = Ask $m $prompt $opts
        $sec = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)
        $md = "## Задача $n`r`n`r`n$($a.Text)`r`n"
        if ($a.Thinking) { $md += "`r`n<details><summary>Рассуждение модели</summary>`r`n`r`n$($a.Thinking)`r`n</details>`r`n" }
        [System.IO.File]::WriteAllText((Join-Path $dir "task$n.md"), $md, (New-Object System.Text.UTF8Encoding $true))
        $warn = if (-not $a.Text) { '  <-- ПУСТОЙ ОТВЕТ' } else { '' }
        Write-Host "  задача $n : $sec с, $($a.Text.Length) символов$warn"
    }
    # ALL.md собирается из всех имеющихся task*.md (в том числе от прошлых запусков)
    $all = "# $($m.name)`r`n`r`n"
    foreach ($n in 1..5) { $f = Join-Path $dir "task$n.md"; if (Test-Path $f) { $all += [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8) + "`r`n" } }
    [System.IO.File]::WriteAllText((Join-Path $dir 'ALL.md'), $all, (New-Object System.Text.UTF8Encoding $true))
}
Unload-All
Write-Host "`nГотово. Ответы в папке answers. Оцените их по критериям (KRITERII_OCENKI.md) в файле results_template.xlsx." -ForegroundColor Green
