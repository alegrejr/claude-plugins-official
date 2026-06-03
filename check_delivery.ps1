param(
    [Parameter(Mandatory=$true)]
    [string]$DeliveryPath
)

if (-not (Test-Path $DeliveryPath)) {
    Write-Host "Folder not found: $DeliveryPath"
    Read-Host "Press Enter to exit"
    exit 1
}

$batDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ts = Get-Date -Format "yyyyMMdd_HHmm"
$reportPath = Join-Path $batDir "delivery_report_$ts.txt"
$lines = [System.Collections.Generic.List[string]]::new()

function Log($msg) {
    Write-Host $msg
    $lines.Add($msg)
}

$template = @(
    @{ Name="Control Survey";              Keyword="CONTROL";    Exts=@("pdf","dgn") }
    @{ Name="RW Map";                      Keyword="RW MAP";     Exts=@("pdf","dgn") }
    @{ Name="Monumentation Map";           Keyword="MONUMENT";   Exts=@("pdf","dgn") }
    @{ Name="GPK";                         Keyword="GPK";        Exts=@("gpk") }
    @{ Name="QAQC";                        Keyword="QAQC";       Exts=@("*") }
    @{ Name="Research";                    Keyword="RESEARCH";   Exts=@("pdf") }
    @{ Name="Aerials";                     Keyword="AERIAL";     Exts=@("sdw","sid","xml") }
    @{ Name="Surveyor's Report";           Keyword="SURVEYOR";   Exts=@("pdf") }
    @{ Name="Roadway";                     Keyword="ROADWAY";    Exts=@("dgn","pdf") }
    @{ Name="Field Data";                  Keyword="FIELD";      Exts=@("txt","pdf") }
    @{ Name="CCR";                         Keyword="CCR";        Exts=@("pdf") }
    @{ Name="XYZ Printout";               Keyword="XYZ";        Exts=@("txt","xls","xlsx") }
    @{ Name="Baseline Report";             Keyword="BASELINE";   Exts=@("txt") }
    @{ Name="Plats";                       Keyword="PLAT";       Exts=@("pdf") }
    @{ Name="Tentative Sec. Maps";         Keyword="TENTATIVE";  Exts=@("pdf") }
    @{ Name="Deeds";                       Keyword="DEED";       Exts=@("pdf") }
    @{ Name="Fieldbook & Survey Database"; Keyword="FIELDBOOK";  Exts=@("txt","pdf") }
    @{ Name="Worksheets";                  Keyword="WORKSHEET";  Exts=@("dgn","pdf") }
)

$present  = 0
$empty    = 0
$missing  = 0
$alerts   = 0
$total    = $template.Count

Log "========================================"
Log "  DELIVERY CHECK REPORT"
Log "  Project: $DeliveryPath"
Log "  Date:    $(Get-Date -Format 'ddd MM/dd/yyyy HH:mm')"
Log "========================================"
Log ""
Log "[ FOLDER ANALYSIS ]"
Log ""

$subfolders = Get-ChildItem -Path $DeliveryPath -Directory

foreach ($cat in $template) {
    $match = $subfolders | Where-Object { $_.Name -imatch $cat.Keyword } | Select-Object -First 1

    if (-not $match) {
        Log ("  [MISSING]      " + $cat.Name)
        $missing++
        continue
    }

    $allFiles = Get-ChildItem -Path $match.FullName -Recurse -File
    $totalCount = $allFiles.Count

    if ($totalCount -eq 0) {
        Log ("  [EMPTY]        " + $cat.Name + " - folder found but no files inside")
        $empty++
        continue
    }

    $anyExt = $cat.Exts -contains "*"

    if ($anyExt) {
        $foundExts = ($allFiles | ForEach-Object { $_.Extension.TrimStart(".").ToLower() } | Sort-Object -Unique) -join " ."
        Log ("  [OK]           " + $cat.Name + " ($totalCount files | .$foundExts)")
        $present++
    } else {
        $okFiles   = $allFiles | Where-Object { $cat.Exts -icontains $_.Extension.TrimStart(".") }
        $diffFiles = $allFiles | Where-Object { $cat.Exts -inotcontains $_.Extension.TrimStart(".") }

        $okExts   = ($okFiles   | ForEach-Object { $_.Extension.TrimStart(".").ToLower() } | Sort-Object -Unique) -join " ."
        $diffExts = ($diffFiles | ForEach-Object { $_.Extension.TrimStart(".").ToLower() } | Sort-Object -Unique) -join " ."

        if ($okFiles.Count -gt 0 -and $diffFiles.Count -gt 0) {
            Log ("  [OK+ALERT]     " + $cat.Name + " ($totalCount files | expected: .$okExts | also found: .$diffExts)")
            $present++
        } elseif ($okFiles.Count -gt 0) {
            Log ("  [OK]           " + $cat.Name + " ($totalCount files | .$okExts)")
            $present++
        } else {
            Log ("  [ALERT]        " + $cat.Name + " - $totalCount files, none match expected ($($cat.Exts -join ',')) | found: .$diffExts")
            $alerts++
        }
    }
}

$score = [math]::Round($present * 100 / $total)

$status = switch ($true) {
    ($score -eq 100) { "DELIVERY COMPLETE" }
    ($score -ge 80)  { "ALMOST COMPLETE" }
    ($score -ge 50)  { "PARTIAL DELIVERY" }
    default          { "INCOMPLETE DELIVERY" }
}

Log ""
Log "========================================"
Log "  SUMMARY"
Log "========================================"
Log "  Folders with correct content : $present/$total"
Log "  Folders empty                : $empty"
Log "  Folders missing              : $missing"
Log "  Folders with unexpected files: $alerts"
Log ""
Log "  COMPLETION: $score%"
Log ""
Log "  STATUS: $status"
Log "========================================"
Log ""
Log "  Report saved to: $reportPath"

$lines | Set-Content -Path $reportPath -Encoding UTF8

Write-Host ""
Write-Host "Report saved to: $reportPath"
Read-Host "Press Enter to exit"
