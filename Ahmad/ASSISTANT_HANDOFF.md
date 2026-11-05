# Ahmad's FPGA project handoff

Updated November 4, 2026. Repository: https://github.com/BrandonK007/FPGA_Proj

## Start here: instructions for the next assistant

Help **Ahmad** build and understand his portion of this shared project. Ahmad and
Brandon are learning FPGA development. Explain unfamiliar terms briefly, make
progress in small working steps, and help Ahmad understand the decisions and debug
the results himself. Do not overwhelm him with the full roadmap at every step.

Read this file, the current repository, and any applicable AGENTS.md before
editing. Fetch the latest remote state; this snapshot will become outdated.
Preserve collaborators' work. The user wants practical implementation help, not
just suggested plans, but this handoff does not authorize purchases, messages to
other people, or changing account permissions.

**First session:** inspect Brandon's latest sources, help Ahmad create the signal
requirements note, and reproduce one existing simulation if a compatible simulator
is available. Record the actual command/result and choose the next small task.
Do not restart the entire project from a counter exercise if existing work can
already be reproduced and explained.

## What we are building

A low-frequency waveform and spectrum analyzer: capture a known low-voltage
electrical signal, plot its waveform, then analyze frequency content in software.

```text
Signal source -> input conditioning/filter -> SPI ADC on our KiCad PCB
    -> SPI controller in FPGA -> sample FIFO -> AXI4-Lite registers
    -> Arm-side C software -> computer plotting/analysis
```

Recommended host: an AMD Zynq-7020 development board. Zybo Z7-20 is a reference
example, not a confirmed purchase. The host already contains the FPGA/Arm device,
memory, and core support circuits. Our PCB is an expansion/interface board.
Software FFT comes after waveform capture; FPGA FFT is not a first-stage requirement.

## Actual status at handoff

Inspected remote `main` at **5506720** before adding this handoff. Brandon has
added RTL and testbenches since the original README was written:

| Existing path | What is there |
| --- | --- |
| `Brandon/Register_Map + Hardware_Rules (READ)` | Register offsets, interface choices, and expected command/error behavior |
| `Brandon/Vivado-Verilog/SPI_Test_Passes/spi_master.sv` | 16-bit, MSB-first, mode-0 SPI controller with programmable divider |
| `Brandon/Vivado-Verilog/SPI_Test_Passes/tb_spi_master.sv` | One all-ones (`16'hFFFF`) MOSI-to-MISO loopback test with timeout |
| `Brandon/Vivado-Verilog/FIFO_Test_Passes/rx_file.sv` | Module **rx_fifo**: 256 x 16-bit FIFO, registered reads, 9-bit count; filename really is `rx_file.sv` |
| `Brandon/Vivado-Verilog/FIFO_Test_Passes/tb_rx_fifo.sv` | Directed reset/order/full/overflow tests |
| `Brandon/Vivado-Verilog/Axi_SPI_R+W/axi_spi_regs.sv` | AXI4-Lite control/status and FIFO-read interface |
| `Brandon/Vivado-Verilog/Axi_SPI_R+W/tb_axi_spi_regs.sv` | AXI stimulus plus actual FIFO; testbench supplies SPI status and received words |

The AXI testbench does **not** instantiate a real Arm CPU or the SPI master. Its
simulation is not proof of an integrated CPU/FPGA/ADC system. Source inspection
was performed for this handoff; the tests were **not independently rerun** during
handoff creation. Directory names and PASS strings are not fresh test evidence.

KiCad files remain the starter scaffold. No completed ADC interface circuit,
board-specific constraints, Arm application, or physical measurements were found
in the inspected commit. Board ownership, exact ADC, lab access, and tool versions
need current confirmation. The older Lattice plan is archived, not the active design.

## Ahmad's ownership

| Area | Ahmad's deliverable | Coordination |
| --- | --- | --- |
| Signal requirements | `Ahmad/signal-requirements.md`: input range/offset, wanted bandwidth, source, sample-rate rationale, available equipment | Agree on requirements before selecting hardware |
| ADC and input circuit | `Ahmad/peripheral-plan.md`: compare two documented ADCs, reference/input circuit, filtering, package and SPI timing | Compare ADC frame/timing requirements with Brandon's 16-bit controller |
| Power and connector | `Ahmad/power-plan.md`: rail/current budget, connector pinout/orientation, logic levels and return paths | Confirm actual host revision and board limits with Brandon |
| Schematic | `sheets/power.kicad_sch`, `sheets/io.kicad_sch` | Brandon owns root hierarchy, host mapping in `fpga_core`, and `clock_config` |
| PCB layout | `FPGA_Proj.kicad_pcb` after schematic/interface review | Ahmad is initial sole layout editor; use layout handoff doc |
| Independent verification | `Ahmad/test-plan.md`, separate new tests under `tb/ahmad/`, runners/analysis under `scripts/ahmad/` | Import existing RTL; do not silently rewrite Brandon's modules |
| Data analysis | Python sample parsing, waveform plots, then software FFT | Agree on sample format and transport; label synthetic data |
| Evidence | `Ahmad/progress.md`: changes, rationale, commands, results, failures and next action | Distinguish Ahmad's contribution from Brandon's |

The proposed new deliverable paths above do not imply those files already exist.
Brandon remains primary owner of RTL, Zynq integration, constraints, and Arm C.
Ahmad should understand that interface and contribute meaningful independent tests.
The separate buck-converter and differential-pair projects are not implemented by
this repository; do not silently add them to the analyzer's hardware scope.

## Interface facts and questions

The current source/proposal uses a 32-bit AXI4-Lite interface, one internal clock,
active-low synchronous reset, mode-0 16-bit SPI, and a 256 x 16-bit receive FIFO.
The 50 MHz internal clock and 1 MHz SPI rate are targets/testbench assumptions,
not measured FPGA timing results. Divider 25 at 50 MHz gives a nominal 1 MHz SCLK
with the present controller (two divider intervals per SCLK period).

| Offset | Register |
| --- | --- |
| 0x00 | CONTROL: start, flush, clear flags |
| 0x04 | STATUS |
| 0x08 | CLK_DIV |
| 0x0C | TX_DATA |
| 0x10 | RX_DATA |
| 0x14 | FIFO_COUNT |
| 0x18 | CONFIG |

Read the actual source and Brandon's rules for bit definitions and behavior.
Resolve disagreements between code and documentation explicitly. Brandon's rules
include sticky errors for rejected starts, SLVERR for empty reads/invalid access,
byte-write strobes, and stable responses during AXI stalls. Flush/completion/reset
priority and integration edge cases require review rather than assumptions.

Only ask Ahmad the missing essentials after checking new repository notes:

1. Is a specific host board now available, and what is the budget/borrowing option?
2. What generator, scope, supply, or other NYU lab equipment can he access?
3. What signal voltage range (including offset) and frequency band should the first demo capture?

Propose a modest initial signal range if undecided, mark it provisional, and show
how it affects ADC selection. Do not select a PCB pin map or analog input range
from the word "Pmod" or a digital 3.3 V label. SPI clock rate is not ADC sample
rate; account for conversion time, frame bits, and gaps. A bipolar signal may need
offset/attenuation before a single-supply ADC. Document the actual analog limits.

## Practical work sequence

1. **Refresh and reproduce:** inspect current branches/files and installed tools.
   Run an existing test without changing its RTL. Explain stimulus, expected result,
   and what the test does not cover. Record tool version and command.
2. **Requirements and interface:** create Ahmad's short signal note, ADC comparison,
   and power worksheet. Source component facts from manufacturer documentation.
   Review frame format, voltage, timing, and sample representation with Brandon.
3. **Independent tests:** extend beyond the existing all-ones SPI loopback with
   distinct and alternating patterns, an independently driven MISO model, and
   checks for bit order, clock edges, chip select, and transfer completion.
   Exercise FIFO boundary/simultaneous operations, AXI stalls/partial writes,
   and reset/flush cases. Derive expectations from the agreed behavior, not a copy
   of the RTL algorithm. Report actual cases and outcomes without invented coverage.
4. **Schematic:** implement selected parts, footprints, decoupling/filter/reference
   circuitry, connector and test points; export a readable schematic and run ERC.
   Finalize shared nets with Brandon before merging.
5. **Integration and layout:** coordinate a top-level integration test using the
   real modules and an ADC model; then review/place/route the expansion board.
   Check footprint orientation, return paths, filled-zone DRC and schematic parity.
6. **Hardware and analysis:** after board access/fabrication, bring up power first,
   verify digital transfers, capture a known waveform, compare with instruments,
   then add FFT analysis. Do not require hardware to start the earlier tasks.

A focused first week should aim for reproducible simulations, useful independent
tests, and an ADC/power proposal or schematic. It is not a promise of fabricated,
fully working hardware in seven days. Update the plan according to observed progress.

## Git and collaboration

Read [CONTRIBUTING](../CONTRIBUTING.md) and [layout ownership](../docs/layout-handoff.md).
Use a fresh short-lived Ahmad branch from current main for implementation; the old
`ahmad/power-io` branch may lag. Example, only when local work is clean:

```sh
git status --short
git fetch origin
git switch main
git pull --ff-only
git switch -c ahmad/adc-interface
```

Do not discard/stash/reset unexplained user changes. Stage explicit files, review
the diff, push the task branch, and prepare a PR for Brandon's review. Preserve
his existing source paths and comments. Put proposed RTL fixes in a reviewable
branch rather than rewriting his work directly on main. Generated simulator files,
waveforms and tool caches should not swamp source control; preserve useful evidence
with a reproducible runner and concise report. Never force-push collaborators' work.

## Tools and reading

Known local clone on Ahmad's machine:
`C:/Users/Ahmad/Documents/Codex/2026-10-20/are/FPGA_Proj`.
KiCad 10.0.7 was previously available at `C:/Program Files/KiCad/10.0/bin/kicad-cli.exe`.
Recheck installed Vivado/Icarus/Python versions instead of assuming their presence.
The next assistant may run elsewhere; local paths are convenience references.

- [Beginner reference](../docs/beginner-reference.md): vocabulary and signal path.
- [README](../README.md): overall scope, team responsibilities, official resources.
- [Shared interfaces](../docs/interfaces.md): earlier proposal; reconcile with Brandon's newer rules.
- [Brandon's register and hardware rules](../Brandon/Register_Map%20%2B%20Hardware_Rules%20%28READ%29): read before new tests.
- [KiCad schematic manual](https://docs.kicad.org/10.0/en/eeschema/eeschema.html).
- [Zybo reference manual](https://digilent.com/reference/_media/reference/programmable-logic/zybo-z7/zybo-z7_rm.pdf): revision B example; match the selected hardware.
- [Vivado simulation guide](https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation).

## How to teach and report progress

For each step: explain what it does, implement a small change, run the relevant
check, show the result, and explain one decision or failure. Make Ahmad able to
trace a sample from the ADC to software and explain his own circuit/test choices.

Maintain a simple evidence record: **target / implemented / simulated / measured**,
with source file, tool/command, conditions, and actual result. A target clock is
not achieved timing; zero DRC errors is not an electrically proven board; simulated
AXI stimulus is not an Arm application. Future resume bullets should summarize
completed milestones and identify ongoing work accurately.

End each session with changed files, tests/results, remaining uncertainty, and the
single next action. Keep this handoff/progress note current as decisions change.
