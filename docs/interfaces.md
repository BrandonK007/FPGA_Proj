# Shared electrical decisions

Status: UNDECIDED. Both designers agree on this page before wiring between sheets.
No rail voltage, bank voltage, oscillator frequency, impedance, or pin assignment
is established by the starter files.

| Decision | Agreed value | Owner / evidence |
| --- | --- | --- |
| FPGA exact part and package | Candidate: Lattice iCE40UP5K-SG48; confirm orderable suffix and package | Brandon's `Brandon/Background_Research`; verify against manufacturer documentation |
| Project function / demonstration | TBD | Both |
| Input connector and input voltage range | TBD | Ahmad |
| Core, auxiliary, and I/O rails / current budget | TBD | Both; FPGA datasheet |
| Rail sequencing and power-good/reset behavior | TBD | Both |
| Clock source, frequency, and electrical levels | TBD | Brandon |
| Configuration / programming interface | TBD | Brandon |
| External I/O standards and connector pinouts | TBD | Both |
| Layer count, stackup, and manufacturer limits | TBD | Ahmad |
| KiCad exact shared version | 10.0.x (scaffold checked in 10.0.7) | Both |

## Sheet interfaces

Fill one row per rail, signal, or bus. Use matching hierarchical labels and sheet
pins. Treat global power labels as shared interfaces too.

| Net / bus | Source sheet | Destination sheet | Direction | Voltage / I/O standard | Timing / impedance requirement | FPGA bank / pin | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |

Changes to rail voltage, bank assignments, reset polarity, connectors, or clocks
require the other designer's review before implementing dependent circuitry.
