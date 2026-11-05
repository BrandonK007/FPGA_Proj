# AMD Zynq + Arm waveform and spectrum analyzer

**New to FPGAs? Start with the [beginner reference sheet](docs/beginner-reference.md).**
Read sections 1–3 first: they explain the project and give each person one small
starting task. The detailed roadmap below is for later stages.

**Continuing Ahmad's portion with an assistant?** Read the
[Ahmad assistant handoff](Ahmad/ASSISTANT_HANDOFF.md) for ownership, current RTL,
first-session steps, and verification deliverables.

**Recommended direction:** an **AMD/Xilinx Zynq-7020 development board** running
our own AXI4-Lite peripheral, connected to a custom KiCad SPI expansion PCB.
This combines PCB/power/interface work with RTL verification and Arm-side software.

**Current status (November 4, 2026):** Brandon has added SPI, FIFO, and AXI register
RTL plus testbenches under `Brandon/Vivado-Verilog/`; see the handoff for their
scope and remaining integration work. KiCad remains an empty scaffold. Hardware
access has not been confirmed. The exact board, budget, peripheral component, and connector
are unselected; no hardware purchase or implementation is implied. A documented
**Digilent Zybo Z7-20** is the reference example, not a purchase commitment.
Ask the Arm contact which team/role they can refer into before buying hardware.
No specific job posting has been supplied.

## Why this direction for AMD and Arm?

Zynq-7020 combines an Arm Cortex-A9 processing system with AMD programmable logic.
It provides a practical way to demonstrate software controlling custom RTL over
AXI. See [AMD's Zynq technical reference](https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/Overview?contentId=GZC3RgWLSxY_qtPqsSEw_A).

Our recommendation is based on the overlap in skills, not a claim that one chip
guarantees an interview or that every team uses the same hardware:

| Company / area | Relevant platforms and skills | Implication for this project |
| --- | --- | --- |
| **AMD FPGA / SoC prototyping** | AMD/Xilinx platforms; Vivado/Vitis, Verilog/SystemVerilog, timing closure, and SoC interfaces appear in an [AMD prototyping posting](https://careers.amd.com/careers-home/jobs/91940?lang=en-us). It is an experienced role, used here as a skills reference. | Zynq with implemented, constrained RTL and a reproducible build is directly relevant. A blink-only demo is an initial check, not the finished project. |
| **Arm hardware / System IP** | Arm's [graduate System IP role](https://careers.arm.com/job/budapest/graduate-engineer-system-ip-engineering/33099/101386258416) emphasizes RTL design/verification, SystemVerilog, scripting, and AMBA familiarity. Arm relevance is about IP and system behavior, not a particular FPGA brand. | Build and verify an AXI peripheral. Explain transactions, reset, buffering, errors, and CPU interaction. Running code on an Arm CPU is not equivalent to designing an Arm CPU. |
| **Intel / Altera ecosystem** | [Altera's Quartus support tables](https://www.altera.com/developers/software/device-support) cover Agilex, Stratix, Arria, Cyclone, and MAX families. Intel [IP validation roles](https://intel.wd1.myworkdayjobs.com/en-US/External/job/IP-Design-Verification-Engineer_JR0285537) can emphasize FPGA/emulation and protocol validation without prescribing one board. | The RTL/test methodology transfers; a later Quartus port would demonstrate another tool flow. Do not assume every Intel role requires an Altera board. |
| **Marvell** | A [Marvell FPGA/silicon-prototyping research internship](https://marvell.wd1.myworkdayjobs.com/en-US/MarvellCareers/job/Research-Intern--PhD----FPGA---Silicon-Prototyping_2604254) asks for HDL, verification, synthesis/timing, architecture, and C/Python. It is a research-degree role, not a matching undergraduate opening. | Protocol engines, buffering, verification, and hardware/software debug transfer. The specific FPGA vendor depends on the team; this source does not establish one required family. |

Sources checked November 2, 2026; openings may change. Altera is no longer wholly
owned by Intel: its [2025 announcement](https://www.altera.com/newsroom/altera-silver-lake)
describes Silver Lake's 51% interest and Intel's retained 49%.

For a **PCB/board** referral, emphasize Ahmad's schematic, power budget, layout,
ERC/DRC, and eventual measurements. For an **Arm RTL/verification** referral, each
applicant needs substantive RTL or verification contributions they can explain.
A PCB-only contribution is less aligned with the cited System IP role.

## Platform choice and project boundaries

- **Preferred family:** Zynq-7000, initially Zynq-7020. It is an established learning
  platform, not the newest Arm CPU or AMD flagship FPGA.
- **First implementation:** documented development board + our own SPI expansion
  PCB. The host board supplies the Zynq device, DDR, boot circuitry, and core rails.
  We are not designing those circuits in this phase.
- **Reference host:** Zybo Z7-20, subject to budget, available stock, board revision,
  complete documentation, and compatible Vivado/Vitis support. Check borrowing
  through NYU before purchasing. Equivalent documented Zynq boards can work, but
  connector pinouts, constraints, power limits, and boot steps must be rechecked.
- **Custom PCB:** a low-voltage ADC interface board, with input conditioning/filtering,
  connector, selected ADC footprint, local power filtering, and test points.
  Choose the actual ADC after defining the input range and comparing datasheets.
- **Later extension:** a custom carrier for a documented Zynq module if a board
  design role justifies it. A bare Zynq BGA plus custom DDR board is a separate,
  substantially larger project.
- **Alternative:** Lattice UP5K remains useful for a compact custom FPGA board.
  The original plan is preserved in [the Lattice alternative](docs/lattice-starting-plan.md),
  along with Brandon's original research. It is not the active AMD/Arm plan.

## The project we will build

**Low-frequency waveform capture first; software spectrum analysis afterward.**

Capture a known lab signal through an ADC, buffer its samples in FPGA logic,
read them from Arm software, and plot them on a computer. Add a software FFT
after waveform capture works. The ADC, analog input range, bandwidth, and sample
rate remain undecided. Loopback and synthetic samples are intermediate tests.

```text
Arm Cortex-A9 C application on the host board
        | memory-mapped AXI
        v
Our AXI4-Lite register block -> SPI controller -> custom KiCad expansion PCB
        |                         |
        +---- status / receive FIFO / error flags ----+
```

Proposed starting targets, to confirm in the shared interface document:

| Item | Initial target / scope |
| --- | --- |
| Control interface | 32-bit AXI4-Lite register interface |
| Programmable-logic clock | 50 MHz implementation target; prove with timing reports |
| SPI | Mode 0, one peripheral select, 1 MHz initial serial clock |
| Buffer | 256 entries x 16 bits; document sample format and overflow policy |
| PCB | Start by evaluating two-layer FR-4 for the low-speed expansion board; finalize after layout/return-path review |
| Signal voltage | Target 3.3 V only if the selected host connector and peripheral both support it |
| Validation | Self-checking simulation first; hardware programming and measurements after hardware is available |

These are design goals, not results. AXI is an on-chip interface here: it is not
routed across the external SPI connector. No PCIe/DDR/high-speed-SI claims follow
from this peripheral project. A future FIFO clock-domain crossing requires a
proper CDC design; start with a single internal logic clock where practical.

## Defined starting tasks

**First session, without buying hardware:** Ahmad writes the signal-requirements
note; Brandon simulates a simple counter. Follow [the first-session checklist](docs/beginner-reference.md#3-your-first-work-session-just-these-two-deliverables).
The A/B tasks below follow those beginner exercises. Then agree on the register
map, connector, signal levels, and test behavior.
Brandon consolidates decisions in [docs/interfaces.md](docs/interfaces.md).

### Ahmad — expansion PCB, power/interface checks, and verification

Branch: `ahmad/power-io`. Create the named deliverable files as each task starts.

| Task | Work | Done when | Resources |
| --- | --- | --- | --- |
| **A1. Host-interface and power worksheet** | Read the reference host's connector pinout, I/O voltage, and available power. Compare a powered-from-host design with any separate supply option; avoid back-powering the host. List the peripheral, LEDs, and other loads. | `Ahmad/power-plan.md` records source revision, connector orientation, voltage/current limits, estimated load, margin, and unresolved items. Budget only our expansion board, not the host's Zynq core rails. | A-R1 |
| **A2. Pick the peripheral and write its tests** | Compare two accessible SPI devices or a simple loopback-first path. Record operating voltage, SPI mode, frame length, maximum clock, package, and source. Define expected data and error behavior with Brandon. | `Ahmad/peripheral-plan.md` contains the comparison; `Ahmad/test-plan.md` lists normal transfers, reset, empty/full FIFO, overflow, and AXI read/write stalls. No arbitrary coverage percentage. | A-R1, B-R2, selected device manufacturer datasheets |
| **A3. Draw power and I/O sheets** | Implement connector power/filtering, peripheral circuit, optional LED/loopback points, and ground/test points in `sheets/power.kicad_sch` and `sheets/io.kicad_sch`. Calculate LED resistance and any regulator dissipation if used. | Exact parts/footprints, agreed net labels, schematic export, ERC report, and explanations for unresolved findings. | A-R2, peripheral/regulator datasheets |
| **A4. Build independent verification** | Implement a Python scoreboard or self-checking SystemVerilog tests against the agreed register map; compare received data/order with expected transactions, including backpressure and reset. Cross-review Brandon's RTL rather than duplicating it. | Reproducible tests in planned `tb/` and `scripts/` paths, documented seeds/cases, and saved failure examples or debug notes. Use a simulator supported by the chosen tool versions. | B-R2, B-R3 |
| **A5. Layout and later bench validation** | After schematic review, place/rout the expansion PCB with a continuous return path, local decoupling, access to SPI/rail test points, and verified connector orientation. | Layout review, filled-zone DRC and schematic parity, BOM, and bring-up checklist. After fabrication, record actual rail and SPI measurements with instrument/setup details. | A-R1, A-R2, fabricator's published rules |

**Ahmad's first PR:** `Ahmad/signal-requirements.md` from the beginner guide.
Follow with the A1 worksheet and A2 ADC/test proposal.

**Resources for Ahmad**

- **A-R1:** [Digilent Zybo Z7 reference manual](https://digilent.com/reference/_media/reference/programmable-logic/zybo-z7/zybo-z7_rm.pdf). This linked edition applies to revision B: match the manual/schematic to the hardware actually selected. Focus on power, Pmod connector wiring, and I/O-bank voltage. Do not infer connector current capacity from pin voltage alone.
- **A-R2:** [KiCad schematic editor](https://docs.kicad.org/10.0/en/eeschema/eeschema.html) and [PCB editor](https://docs.kicad.org/10.0/en/pcbnew/pcbnew.html). Read hierarchical connections, footprint assignment, board setup, zones, and ERC/DRC. Use actual fabricator rules once the supplier is selected.

### Brandon — SoC integration, AXI/SPI RTL, and Arm software

Branch: `brandon/fpga-core`. The name stays the same, but this phase integrates
the existing host FPGA rather than placing a bare UP5K or Zynq device on our PCB.

| Task | Work | Done when | Resources |
| --- | --- | --- | --- |
| **B1. Confirm the reference platform and tool flow** | Compare documented Zynq-7020 boards against budget/borrowing options. Check device/package, board revision, exposed connector, programming method, and Vivado/Vitis support. | `Brandon/platform-plan.md` records the proposed board, current price/source if shopping, tools, board files, connector pin map, and what Ahmad can safely connect. No purchase required for this decision note. | B-R1, B-R3, A-R1 |
| **B2. Specify the peripheral before coding** | Define CONTROL, STATUS, clock divider, receive DATA, FIFO count, and error/clear semantics. Specify address alignment, byte enables, reset values, full/empty behavior, and invalid-address responses. | `Brandon/register-map.md` and a block diagram reviewed by Ahmad; all behavior needed for A2/A4 is explicit. | B-R2 |
| **B3. Implement and verify small RTL blocks** | Build the SPI controller, FIFO, and register interface, first in simulation. Handle AXI address/data channels independently and preserve response/data while stalled. | Planned `rtl/` and `tb/` sources with self-checking tests, assertions where supported, reset/stall/full/empty cases, and documented limitations. Passing directed tests does not establish complete protocol compliance. | B-R2, B-R3 |
| **B4. Integrate the processing system and close timing** | Connect the peripheral to the Zynq processing system in Vivado, configure clock/reset, assign the chosen connector pins, and write appropriate XDC constraints. Start at the proposed 50 MHz internal clock. | Repeatable build/Tcl instructions, exact tool/part versions, utilization, timing reports, reviewed unconstrained paths and any CDC findings. Exclude generated tool caches from Git. | B-R1, B-R3, B-R4 |
| **B5. Write the Arm-side demonstration** | Use a small bare-metal C application first: configure the peripheral, start transfers, read results/status, and log pass/fail plus counts. Add interrupts only after polling works. | Planned `software/` sources and a reproducible build. After hardware access, include programming instructions, logs, and ILA/bench observations where applicable. Distinguish a build from a hardware test. | B-R1, B-R3 |

**Brandon's first PR:** counter, self-checking testbench, and reproduction note
from the beginner guide. Follow with the platform comparison and register map.
Device/connector pins become final only after the actual host board is chosen.

**Resources for Brandon**

- **B-R1:** [AMD Zynq-7000 Technical Reference Manual, UG585](https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM). Focus on processing-system/programmable-logic interfaces, memory mapping, clocks/resets, and interrupts. This is system integration, not Arm CPU microarchitecture implementation.
- **B-R2:** [Arm AMBA AXI and ACE specification, IHI 0022 H.c](https://support.arm.com/documentation/ihi0022/hc/) and [AMD AXI4 overview](https://www.amd.com/en/products/adaptive-socs-and-fpgas/intellectual-property/axi.html). Use the AXI4-Lite definition and channel-handshake rules. H.c is intentionally linked because newer reorganized AXI editions may omit the older AXI4-Lite material.
- **B-R3:** [Digilent's Zybo Z7 example projects](https://github.com/Digilent/Zybo-Z7). Use a release matching the tool version and board variant; adapt pin constraints to our selected connector. Keep our RTL/tests/software identifiable and credit reused examples.
- **B-R4:** [Vivado constraints, UG903](https://docs.amd.com/r/en-US/ug903-vivado-using-constraints) and [design analysis/timing closure, UG906](https://docs.amd.com/r/en-US/ug906-vivado-design-analysis). Read clock/I/O constraints, timing reports, and CDC analysis. Do not mask real timing problems with broad false paths.

## Shared milestones and interview evidence

1. **Specification:** merge the platform/interface decision and register map after
   mutual review. Agree on budget before buying a board.
2. **Simulation:** reproduce normal transfers and adverse cases with a scoreboard;
   record bugs found and fixed. Keep functional requirements separate from test counts.
3. **Implementation:** build for the selected AMD device and document timing,
   resource use, constraints, and tool versions. Hardware is not needed to start this.
4. **PCB:** review the complete expansion schematic before layout; check footprints,
   rail/interface limits, return paths, filled-zone DRC, and schematic parity.
5. **Hardware, when available:** demonstrate Arm C -> AXI -> SPI -> peripheral ->
   readback. Compare logic-analyzer/ILA traces with expected transactions and record
   actual throughput/latency and power measurements where measured.
6. **Analyzer demonstration:** plot captured ADC data with voltage/time scaling,
   then add a software FFT. Compare against a known generator signal and document
   sample rate, record length, filtering, and measurement limitations.

For interviews, each person should explain a design decision, a bug, a test that
caught it, and their own contribution. A referral helps reach a team; the project
must supply evidence of the skills that team's actual role needs. Ask the contact
whether to emphasize board validation, RTL design, verification, or embedded systems.

## KiCad file ownership and Git workflow

The five-sheet KiCad project is still an empty scaffold. Keep it as the **expansion
board** project. Before drawing, Brandon updates root sheet labels/interfaces to
match the new scope; do not populate old bare-FPGA power/configuration circuits.

| Area | Primary editor | Reviewer |
| --- | --- | --- |
| Power and external I/O sheets | Ahmad | Brandon |
| Existing `fpga_core` sheet: host connector/interface mapping | Brandon | Ahmad |
| Existing `clock_config` sheet: peripheral reset/control, only if needed | Brandon | Ahmad |
| Root hierarchy and shared interface document | Brandon, after agreement | Ahmad |
| PCB file / layout | Ahmad initially; explicit handoff required | Brandon |
| RTL and embedded C (planned directories) | Brandon | Ahmad |
| Independent tests / scoreboard (planned directories) | Ahmad | Brandon |

Both use KiCad 10.0.x (scaffold checked with 10.0.7). Open
`FPGA_Proj.kicad_pro`; each person uses their own local clone.
Original `Ahmad/` and `Brandon/` notes remain preserved.

Before starting, save/close KiCad, commit local work, then bring the new plan into
your branch:

```sh
git fetch origin
git switch ahmad/power-io
git merge origin/main
```

Brandon substitutes `brandon/fpga-core`. Work in separate files, push your task
branch, open a PR into `main`, and have the other person review. After a merge,
start the next task on a fresh branch from updated `main`.
See [CONTRIBUTING.md](CONTRIBUTING.md) and [layout handoffs](docs/layout-handoff.md).
Only one editor changes the PCB file at a time; branches are not locks.
CODEOWNERS requests reviews where supported; branch protection still requires
Brandon's admin settings.

## Existing repository files

- Root KiCad project and `sheets/`: empty hardware scaffold to adapt as above.
- [docs/interfaces.md](docs/interfaces.md): active Zynq/expansion-board decisions.
- [docs/lattice-starting-plan.md](docs/lattice-starting-plan.md): superseded UP5K alternative.
- `libraries/`: project-local libraries using relative paths.
- `.github/`: review checklist and ownership; `build/`: ignored generated output.
- `Brandon/Vivado-Verilog/`: existing RTL and directed testbenches; not a completed analyzer.
- `Ahmad/ASSISTANT_HANDOFF.md`: starting context for Ahmad's assistant.
- Root `rtl/`, `tb/`, `software/`, `scripts/`: planned additions; preserve Brandon's existing source paths.
