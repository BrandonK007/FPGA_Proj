# Shared interface decisions — Zynq expansion-board plan

Status: proposed architecture, not a completed design. The recommended host is an
AMD Zynq-7020 development board; neither contributor owns a board yet. Exact board,
budget, connector, and peripheral are undecided. See the README for the active plan.

The previous Lattice UP5K candidate remains in Brandon's original research and
the archived Lattice plan. No bare FPGA device or DDR circuitry is planned on the
first custom expansion PCB.

| Decision | Proposed value / open item | Owner / evidence needed |
| --- | --- | --- |
| Target role | Arm hardware referral; exact team/role unknown | Both; ask contact |
| Host family | AMD Zynq-7000, Zynq-7020 recommended | Brandon; AMD UG585 |
| Reference example | Digilent Zybo Z7-20; not yet selected or purchased | Brandon; budget, borrowing, board revision/tool support |
| Hardware contribution | Custom low-voltage SPI expansion PCB | Ahmad |
| First complete demo | Arm C -> AXI4-Lite -> SPI -> loopback/peripheral -> readback | Both |
| Control bus | 32-bit AXI4-Lite | Brandon; register map and Arm IHI 0022 H.c |
| Logic clock | 50 MHz target; not achieved | Brandon; constraints and timing report |
| SPI | Mode 0, one select, 1 MHz initial target | Both; selected device datasheet |
| FIFO | 256 x 16-bit proposed, overflow/reset policy TBD | Brandon; test agreement with Ahmad |
| Connector | TBD; pinout, orientation, host bank, and current limit must be verified | Both |
| Signal voltage | 3.3 V target only if host and peripheral support it | Both; exact board/device specifications |
| Power source | Host connector versus separate supply: TBD; prevent back-powering | Ahmad; load budget and host limits |
| PCB stackup | Evaluate two-layer FR-4 for expansion board; not finalized | Ahmad; return-path review and fabricator |
| Peripheral part | TBD; compare two choices or loopback-first implementation | Ahmad with Brandon |
| Tool versions | KiCad 10.0.x; Vivado/Vitis/simulator versions TBD | Both |
| Hardware status | No board owned, no measurements | Both |

## Pin / signal contract

Fill one row per connector pin or cross-sheet signal after host/peripheral selection.
Include a source reference and distinguish host-board package pins from connector
pins. Do not assign an I/O standard from the label "Pmod" alone.

| Net | Connector/pin | Host FPGA pin/bank | Direction | Voltage | Timing/drive constraints | Source |
| --- | --- | --- | --- | --- | --- | --- |
| TBD | TBD | TBD | TBD | TBD | TBD | TBD |

## Register and test contract

Brandon writes `Brandon/register-map.md`; Ahmad reviews it before coding the
independent tests. Define reset values, byte-write behavior, access permissions,
FIFO semantics, invalid-address responses, independent AXI channels, and stalls.
Use a single internal logic clock initially where practical. Explicitly design
and verify any CDC introduced later.

Brandon consolidates changes here after both agree, to avoid editing this shared
file in parallel. No numeric target on this page is a simulated or measured result.
