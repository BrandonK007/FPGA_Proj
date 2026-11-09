param(
    [string]$IcarusBin = '',
    [switch]$Waveform,
    [switch]$CheckFaultDetection
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$spi = Join-Path $repo 'Brandon/Vivado-Verilog/SPI_Test_Passes'
$iverilog = 'iverilog'
$vvp = 'vvp'
if ($IcarusBin) {
    $iverilog = Join-Path $IcarusBin 'iverilog.exe'
    $vvp = Join-Path $IcarusBin 'vvp.exe'
}
$sim = Join-Path ([System.IO.Path]::GetTempPath()) ("fpga-spi-" + [guid]::NewGuid() + ".vvp")
$faultSource = "$sim.sv"
$source = Join-Path $spi 'spi_master.sv'
$testbench = Join-Path $repo 'tb/ahmad/tb_spi_independent.sv'

try {
    & $iverilog -g2012 -s tb_spi_independent -o $sim $source $testbench
    if ($LASTEXITCODE -ne 0) { throw "Compilation failed ($LASTEXITCODE)." }
    $simArgs = @($sim)
    if ($Waveform) {
        $waveDir = Join-Path $repo 'build/ahmad'
        New-Item -ItemType Directory -Path $waveDir -Force | Out-Null
        $waveFile = Join-Path $waveDir 'spi.vcd'
        $simArgs += "+waveform=$($waveFile.Replace('\', '/'))"
    }
    & $vvp @simArgs
    if ($LASTEXITCODE -ne 0) { throw "Simulation failed ($LASTEXITCODE)." }
    if ($Waveform) { Write-Output "Waveform saved to $waveFile" }

    if ($CheckFaultDetection) {
        # Each deliberate fault is applied to a temporary copy of Brandon's RTL.
        # A compile error or timeout does not count as detecting the intended fault.
        $originalSource = Get-Content -LiteralPath $source -Raw
        $faults = @(
            @{
                Name = 'Skipped transmit bit'
                Find = 'mosi <= tx_shift[14];'
                Replace = 'mosi <= tx_shift[13];'
                Expected = 'TX 96e1 bit 13: MOSI=1, expected 0'
            },
            @{
                Name = 'Inverted receive bits'
                Find = 'rx_shift <= {rx_shift[14:0], miso};'
                Replace = 'rx_shift <= {rx_shift[14:0], ~miso};'
                Expected = 'Frame completion: RX=b4d2, expected 4b2d'
            }
        )
        foreach ($fault in $faults) {
            $matches = [regex]::Matches($originalSource, [regex]::Escape($fault.Find))
            if ($matches.Count -ne 1) {
                throw "Expected one source location for '$($fault.Name)'. Review the RTL before updating this demonstration."
            }
            $modifiedSource = $originalSource.Replace($fault.Find, $fault.Replace)
            [System.IO.File]::WriteAllText($faultSource, $modifiedSource)
            & $iverilog -g2012 -s tb_spi_independent -o $sim $faultSource $testbench
            if ($LASTEXITCODE -ne 0) { throw "Fault demonstration compilation failed ($LASTEXITCODE)." }
            $output = & $vvp $sim
            $simulationExitCode = $LASTEXITCODE
            $failure = $output | Select-String -SimpleMatch $fault.Expected
            if ($simulationExitCode -eq 0 -or -not $failure) {
                $output | Write-Output
                throw "'$($fault.Name)' did not produce the expected test failure."
            }
            Write-Output "DETECTED: $($fault.Name)"
            $failure | ForEach-Object { Write-Output $_.Line }
        }
    }
} finally {
    if (Test-Path -LiteralPath $sim) { Remove-Item -LiteralPath $sim }
    if (Test-Path -LiteralPath $faultSource) { Remove-Item -LiteralPath $faultSource }
}
