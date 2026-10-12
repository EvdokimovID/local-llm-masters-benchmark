# Шаг 2. Технические метрики: скорость, время до первого токена, видеопамять, контекст без выгрузки.
# Результаты: results\tech_raw.csv, results\tech_summary.csv, results\context.csv
param([int]$Repeats = 3, [string]$Only = '')
. (Join-Path $PSScriptRoot 'common.ps1')
$res = Join-Path $Root 'results'; New-Item -ItemType Directory -Force -Path $res | Out-Null

$prompts = [ordered]@{
    'short' = Read-Text 'bench\short_prompt.txt'
    'long'  = (Read-Text 'bench\long_context.txt') + "`n`nСформулируй основную идею приведенного текста в 5 тезисах."
}
$opts = @{ temperature = 0; seed = 42; num_ctx = 8192; num_predict = 400 }

$raw = @(); $summary = @(); $ctxRows = @()
$sfx = if ($Only) { '_' + (Safe-Name $Only) } else { '' }
$models = Load-Models | Where-Object { -not $Only -or $_.name -like "*$Only*" }

foreach ($m in $models) {
    Write-Host "`n=== $($m.name)" -ForegroundColor Cyan
    Unload-All
    # Прогрев: первая загрузка модели в память (время загрузки фиксируется отдельно)
    $t0 = Get-Date
    $w = Ask $m 'Привет! Ответь одним словом.' @{ num_ctx = 8192; num_predict = 8 } -NoCache
    $loadSec = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)
    $w = Ask $m 'Привет! Ответь одним словом.' @{ num_ctx = 8192; num_predict = 8 } -NoCache  # второй прогрев: инициализация CUDA
    $ps = @(Get-Loaded) | Select-Object -First 1
    $sizeGB = if ($ps) { [math]::Round($ps.size / 1GB, 2) } else { $null }
    $vramGB = if ($ps) { [math]::Round($ps.size_vram / 1GB, 2) } else { $null }
    $gpuShare = if ($ps -and $ps.size) { [math]::Round(100 * $ps.size_vram / $ps.size, 0) } else { $null }
    Write-Host "  загрузка: $loadSec с; в памяти: $sizeGB ГБ, из них в видеопамяти: $vramGB ГБ ($gpuShare %)"

    $gpuFile = Join-Path $res ("gpu_" + (Safe-Name $m.name) + ".txt")
    $mon = Start-GpuMonitor $gpuFile
    foreach ($k in $prompts.Keys) {
        for ($i = 1; $i -le $Repeats; $i++) {
            $a = Ask $m $prompts[$k] $opts -NoCache
            $r = $a.Raw
            $gen = if ($r.eval_duration) { $r.eval_count / ($r.eval_duration / 1e9) } else { $null }
            $pp  = if ($r.prompt_eval_duration) { $r.prompt_eval_count / ($r.prompt_eval_duration / 1e9) } else { $null }
            $ttft = ($r.load_duration + $r.prompt_eval_duration) / 1e9
            $row = [pscustomobject]@{
                model = $m.name; prompt = $k; run = $i
                prompt_tokens = $r.prompt_eval_count; gen_tokens = $r.eval_count
                gen_tps = [math]::Round($gen, 1); pp_tps = [math]::Round($pp, 1); ttft_s = [math]::Round($ttft, 2)
                total_s = [math]::Round($r.total_duration / 1e9, 2)
            }
            $raw += $row
            Write-Host ("  {0,-5} #{1}: генерация {2} ток/с, обработка запроса {3} ток/с, до 1-го токена {4} с" -f $k, $i, $row.gen_tps, $row.pp_tps, $row.ttft_s)
        }
    }
    $peak = Stop-GpuMonitor $mon $gpuFile

    $summary += [pscustomobject]@{
        model = $m.name; tag = $m.tag; load_s = $loadSec; size_in_memory_GB = $sizeGB; size_in_vram_GB = $vramGB; gpu_share_pct = $gpuShare
        gpu_peak_total_GB = $peak
        gen_tps_short = Median ($raw | Where-Object { $_.model -eq $m.name -and $_.prompt -eq 'short' } | ForEach-Object { $_.gen_tps })
        gen_tps_long  = Median ($raw | Where-Object { $_.model -eq $m.name -and $_.prompt -eq 'long' }  | ForEach-Object { $_.gen_tps })
        pp_tps_long   = Median ($raw | Where-Object { $_.model -eq $m.name -and $_.prompt -eq 'long' }  | ForEach-Object { $_.pp_tps })
        ttft_s_short  = Median ($raw | Where-Object { $_.model -eq $m.name -and $_.prompt -eq 'short' } | ForEach-Object { $_.ttft_s })
        ttft_s_long   = Median ($raw | Where-Object { $_.model -eq $m.name -and $_.prompt -eq 'long' }  | ForEach-Object { $_.ttft_s })
    }

    # Максимальный контекст без выгрузки в ОЗУ
    $best = $null
    foreach ($ctx in 4096, 8192, 16384, 32768, 65536, 131072) {
        Unload-All
        try {
            Ask $m 'Ответь: OK' @{ num_ctx = $ctx; num_predict = 2 } -NoCache | Out-Null
            $p2 = @(Get-Loaded) | Select-Object -First 1
            $full = ($p2 -and $p2.size_vram -ge 0.99 * $p2.size)
            $ctxRows += [pscustomobject]@{ model = $m.name; num_ctx = $ctx; size_GB = [math]::Round($p2.size / 1GB, 2); vram_GB = [math]::Round($p2.size_vram / 1GB, 2); fully_on_gpu = $full }
            Write-Host "  контекст $ctx : полностью в видеопамяти = $full"
            if ($full) { $best = $ctx } else { break }
        } catch {
            Write-Host "  контекст $ctx : ошибка ($($_.Exception.Message))" -ForegroundColor Yellow; break
        }
    }
    $summary[-1] | Add-Member -NotePropertyName max_ctx_full_gpu -NotePropertyValue $best
    Unload-All

    $raw     | Export-Csv (Join-Path $res ('tech_raw' + $sfx + '.csv'))     -Delimiter ';' -Encoding UTF8 -NoTypeInformation
    $summary | Export-Csv (Join-Path $res ('tech_summary' + $sfx + '.csv')) -Delimiter ';' -Encoding UTF8 -NoTypeInformation
    $ctxRows | Export-Csv (Join-Path $res ('context' + $sfx + '.csv'))      -Delimiter ';' -Encoding UTF8 -NoTypeInformation
}
Write-Host ("`nГотово. Итоговая таблица: results\tech_summary" + $sfx + ".csv") -ForegroundColor Green
$summary | Format-Table model, size_in_vram_GB, gpu_share_pct, gen_tps_short, gen_tps_long, ttft_s_long, max_ctx_full_gpu -AutoSize
