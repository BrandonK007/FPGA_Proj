# Ahmad's progress

## November 4, 2026

Started with simulation. Oscilloscope and DAD3 available for later bench work.

Icarus Verilog 12.0 (devel), build s20150603-1539-g2693dd32b.
From the repository root, reproduce Brandon's existing loopback with:

```powershell
$spi = 'Brandon/Vivado-Verilog/SPI_Test_Passes'
$sim = Join-Path $env:TEMP ('fpga-' + [guid]::NewGuid() + '.vvp')
& C:/iverilog/bin/iverilog.exe -g2012 -s tb_spi_master -o $sim "$spi/spi_master.sv" "$spi/tb_spi_master.sv"
if ($LASTEXITCODE -eq 0) { & C:/iverilog/bin/vvp.exe $sim }
if (Test-Path -LiteralPath $sim) { Remove-Item -LiteralPath $sim }
```

Observed: `PASS: Received ffff`.

Run Ahmad's independent SPI test with:

```powershell
./scripts/ahmad/run-spi.ps1 -IcarusBin C:/iverilog/bin
```

Observed: `PASS: TX=96e1 RX=4b2d divider=25` and
`PASS: TX=aaaa RX=5555 divider=2`. The simulated peripheral drives its own
reply, and the test checks the transmit bits, clock edge spacing, chip select
at frame edges, received word, and completion pulse. This verifies the
standalone controller in simulation.

Next: trace a simulated received word through the FIFO and AXI RX_DATA register.

## November 8, 2026

Prepared the first SPI verification milestone with Codex. Ahmad's walkthrough
and review are the next step. The tested RTL is Brandon's existing
`Brandon/Vivado-Verilog/SPI_Test_Passes/spi_master.sv` from main at `b5c8adf`.

### Checks and results

The independent peripheral model supplies MISO from a separate reply word.
For each frame the test checks all 16 MOSI bits, rising and falling SCLK edge
spacing, selection/busy/completion states at those edges, the received word,
and three idle system clocks after completion. Reset is checked before the
first transfer. The expected half-periods below are explicit test inputs.

| TX word | Peripheral reply | Divider | Expected SCLK half-period | Purpose | Result |
| --- | --- | --- | --- | --- | --- |
| `96E1` | `4B2D` | 25 | 500 ns | Different mixed patterns in each direction | PASS |
| `AAAA` | `5555` | 2 | 40 ns | Alternating bits | PASS |
| `0000` | `FFFF` | 25 | 500 ns | Opposite constant levels | PASS |
| `FFFF` | `0000` | 25 | 500 ns | Reverse constant levels | PASS |
| `8000` | `0001` | 1 | 20 ns | Isolated first TX bit and last RX bit | PASS |
| `0001` | `8000` | 1 | 20 ns | Isolated last TX bit and first RX bit | PASS |
| `1A2B` | `C3D4` | 50 | 1,000 ns | Slower clock with distinct data | PASS |

The test also requires `done` to clear on the next system clock and the received
word to remain available during the checked idle clocks. A 200 microsecond
watchdog catches stalled simulations. All seven frames completed at 83.191
microseconds with Icarus Verilog 12.0 (devel), build
`s20150603-1539-g2693dd32b`.

### Reproduce and inspect

From the repository root in PowerShell, run the seven cases, save a waveform,
and demonstrate detection of two deliberately introduced faults with

```powershell
./scripts/ahmad/run-spi.ps1 -IcarusBin C:/iverilog/bin -Waveform -CheckFaultDetection
```

The original command without the switches still runs the seven passing cases.
`-Waveform` writes `build/ahmad/spi.vcd`, which is excluded from Git. Open that
file for study with

```powershell
& C:/iverilog/gtkwave/bin/gtkwave.exe ./build/ahmad/spi.vcd
```

In GTKWave, select `tb_spi_independent` and add `clk`, `start`, `cs_n`, `sclk`,
`mosi`, `miso`, `busy`, `done`, `tx_data`, and `rx_data`. The first frame has
500 ns between SCLK transitions and 16 microseconds between CS assertion and
release. At completion, `rx_data` becomes `4B2D` and `done` lasts one 20 ns
system-clock period.

### Fault detection evidence

`-CheckFaultDetection` compiles temporary copies of the RTL with one deliberate
fault at a time. Each copy must compile successfully and fail with its expected
data mismatch. Compilation failures and watchdog timeouts count as failures of
the demonstration. The temporary source and executable are removed afterward.

| Deliberate fault in temporary copy | Observed checker failure |
| --- | --- |
| Change the next MOSI source from `tx_shift[14]` to `tx_shift[13]`, skipping a bit | `TX 96e1 bit 13: MOSI=1, expected 0` |
| Invert MISO before shifting it into the receive register | `Frame completion: RX=b4d2, expected 4b2d` |

These are injected faults used to evaluate the tests. Both were detected in the
November 8 run. The baseline source passed all seven frames.

### Study checkpoints and remaining work

Explain how 50 MHz divided by twice the divider gives SCLK frequency, why the
first bit must be present before the first rising edge, why different TX/RX words
exercise both data directions, and which assertion caught each injected fault.
Trace the first frame in the waveform before claiming independent understanding.

Evidence covers directed standalone simulation. Reset during a frame, a new start
while busy, divider zero and its full range, and pin timing against a selected ADC
datasheet remain open test work. The FIFO/AXI integration milestone and physical
hardware validation remain pending.
