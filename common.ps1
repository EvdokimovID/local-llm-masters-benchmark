# Общие функции комплекта. Подключается из других скриптов: . .\common.ps1
$ErrorActionPreference = 'Stop'
$Base = 'http://localhost:11434'
$Root = $PSScriptRoot
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Invoke-Ollama([string]$Path, $Body) {
    $json  = $Body | ConvertTo-Json -Depth 10 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $r = Invoke-WebRequest -Uri ($Base + $Path) -Method Post -Body $bytes `
         -ContentType 'application/json; charset=utf-8' -UseBasicParsing -TimeoutSec 7200
    $txt = [System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
    return ($txt | ConvertFrom-Json)
}

function Get-Loaded {
    $r = Invoke-WebRequest -Uri ($Base + '/api/ps') -UseBasicParsing
    $txt = [System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
    return ($txt | ConvertFrom-Json).models
}

function Unload-All {
    foreach ($m in @(Get-Loaded)) {
        if ($m) { Invoke-Ollama '/api/generate' @{ model = $m.name; keep_alive = 0 } | Out-Null }
    }
    Start-Sleep -Seconds 3
}

function Load-Models {
    return Import-Csv -Path (Join-Path $Root 'models.csv') -Delimiter ';' -Encoding UTF8
}

function Read-Text([string]$RelPath) {
    return [System.IO.File]::ReadAllText((Join-Path $Root $RelPath), [System.Text.Encoding]::UTF8).Trim()
}

# Один запрос к модели. Для YandexGPT используется собственный формат диалога (raw).
function Ask($Model, [string]$Prompt, $Options, [switch]$NoCache) {
    # NoCache: уникальный идентификатор в самом начале запроса, чтобы Ollama не взяла обработанный префикс из кэша
    $sys = 'Ты — помощник магистранта. Отвечай на русском языке.'
    if ($NoCache) { $sys = "Идентификатор запроса: $([guid]::NewGuid().ToString('N')). " + $sys }
    if ($Model.template -eq 'yandex') {
        $body = @{ model = $Model.tag; prompt = " Пользователь: $sys`n$Prompt`n`n Ассистент:[SEP]"; raw = $true; stream = $false; options = $Options; keep_alive = '30m' }
        $r = Invoke-Ollama '/api/generate' $body
        $text = $r.response; $think = ''
    } elseif ($Model.template -eq 'chatml') {
        # Формат ChatML вручную: встроенный шаблон GGUF у T-Lite в Ollama работает некорректно
        $o = @{}; foreach ($k in $Options.Keys) { $o[$k] = $Options[$k] }; $o['stop'] = @('<|im_end|>', '<|im_start|>')
        $p = "<|im_start|>system`n$sys<|im_end|>`n<|im_start|>user`n$Prompt<|im_end|>`n<|im_start|>assistant`n"
        $body = @{ model = $Model.tag; prompt = $p; raw = $true; stream = $false; options = $o; keep_alive = '30m' }
        $r = Invoke-Ollama '/api/generate' $body
        $text = $r.response; $think = ''
    } else {
        $body = @{ model = $Model.tag; messages = @(@{ role = 'system'; content = $sys }, @{ role = 'user'; content = $Prompt }); stream = $false; options = $Options; keep_alive = '30m' }
        $r = Invoke-Ollama '/api/chat' $body
        $text = $r.message.content; $think = $r.message.thinking
    }
    return [pscustomobject]@{ Raw = $r; Text = $text; Thinking = $think }
}

function Start-GpuMonitor([string]$File) {
    if (Test-Path $File) { Remove-Item $File }
    return Start-Process -FilePath 'nvidia-smi' -ArgumentList '--query-gpu=memory.used', '--format=csv,noheader,nounits', '-lms', '250' `
           -RedirectStandardOutput $File -NoNewWindow -PassThru
}
function Stop-GpuMonitor($Proc, [string]$File) {
    Stop-Process -Id $Proc.Id -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    $vals = Get-Content $File | Where-Object { $_ -match '^\s*\d+' } | ForEach-Object { [double]($_.Trim()) }
    if ($vals) { return [math]::Round((($vals | Measure-Object -Maximum).Maximum) / 1024, 2) } else { return $null }
}

function Median([double[]]$x) {
    $s = $x | Sort-Object; $n = $s.Count
    if ($n -eq 0) { return $null }
    if ($n % 2) { return $s[[int][math]::Floor($n / 2)] } else { return ($s[$n / 2 - 1] + $s[$n / 2]) / 2 }
}

function Safe-Name([string]$s) { return ($s -replace '[^\w\.\-]+', '_') }
