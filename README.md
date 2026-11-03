# FPGA board project

Collaborative KiCad board design by Ahmad and Brandon. This is a project scaffold,
not a completed circuit. Brandon's existing research names the Lattice
iCE40UP5K-SG48 as a candidate; the exact orderable part and design requirements
still need confirmation. Empty ERC results do not validate hardware.

The original `Ahmad/` and `Brandon/` folders are preserved for individual notes.
Use one shared hardware project and branches to combine work; do not maintain two
independent copies of the PCB. Git/GitHub tracks versions; KiCad edits the design.

## Start here

1. Both use KiCad **10.0.x**; the scaffold was checked with 10.0.7.
2. Clone this repository into a separate local folder on each computer:
   `git clone https://github.com/BrandonK007/FPGA_Proj.git`.
   Ahmad starts on `ahmad/power-io`; Brandon starts on `brandon/fpga-core`.
3. Open `FPGA_Proj.kicad_pro` and the root schematic. The four child sheets are
   already linked; enter your assigned sheet through the hierarchy navigator.
4. Agree on the device/package and fill in `docs/interfaces.md` before connecting
   blocks. Do not assume every FPGA bank accepts 3.3 V.
5. Follow `CONTRIBUTING.md` for branches, pull requests, and layout handoffs.

## Starting work split

| Area | Primary editor | Reviewer |
| --- | --- | --- |
| `sheets/power.kicad_sch` | Ahmad | Brandon |
| `sheets/io.kicad_sch` | Ahmad | Brandon |
| `sheets/fpga_core.kicad_sch` | Brandon | Ahmad |
| `sheets/clock_config.kicad_sch` | Brandon | Ahmad |
| Root hierarchy and project settings | Brandon, after agreement | Ahmad |
| `FPGA_Proj.kicad_pcb` | Ahmad initially; explicit handoff required | Brandon |

After cloning, select your starting branch in GitHub Desktop's **Current branch**
menu, or run `git switch ahmad/power-io` / `git switch brandon/fpga-core`.
After the first PR is merged, create a fresh task branch from updated `main`.

You can work on separate schematic files at the same time. Only one person edits
the PCB file at a time. A Git branch is not a file lock.

## First milestone: a board we can power and program

Proposed initial demonstration: load a simple FPGA design that blinks an LED and
reads a pushbutton. Agree on that scope before adding more interfaces. The first
deliverable is a reviewed schematic, not a routed board or fabrication order.

**Start today:** Brandon does **B1** while Ahmad starts **A1**. Spend the last
20-30 minutes together agreeing on the rail and interface table. If a requirement
is unresolved, record the question and source instead of guessing a value.

### Ahmad — power, external I/O, and PCB planning

Work on `ahmad/power-io`. Keep your calculations and component comparisons in
`Ahmad/power-plan.md` (create this file). Estimate, calculate, and measure are
different statuses: label each value accordingly.

| Task | What to do | Deliverable / done when | Read first |
| --- | --- | --- | --- |
| **A1. Define the power budget** | Propose an input connector and supply range. List every load: FPGA rails, flash, oscillator if used, LEDs, and external I/O. Start the worksheet now; fill in required rail voltages and sequencing with Brandon after B1. | `Ahmad/power-plan.md` has columns for rail, allowed voltage range, estimated current, assumption/source, and design margin. Unknown dynamic FPGA current is explicitly unresolved, not replaced with a typical static-current figure. | **A-R1**, **A-R2** |
| **A2. Compare regulator options** | After the rail requirements are agreed, compare two available regulator options for each required rail. Check input range, dropout/duty-cycle limits, startup, output tolerance, current headroom, capacitor requirements, and package. Estimate LDO dissipation using `(Vin - Vout) × Iout`; use the candidate datasheet for switching-regulator calculations. | Add a comparison table and provisional BOM with exact part numbers, datasheet links, package/footprint, estimated dissipation, and selection rationale. Identify what still needs simulation or measurement. | **A-R1**, **A-R2**, then each candidate regulator's manufacturer datasheet |
| **A3. Draw the power sheet** | Implement input power, selected rails, enable/power-good behavior where needed, bulk filtering, and rail/ground test points in `sheets/power.kicad_sch`. Coordinate device-local decoupling with Brandon so capacitors are neither omitted nor duplicated. | All component values and footprints are assigned; each rail has an agreed name. Attach a schematic PDF/screenshot and ERC report to a draft PR; explain remaining findings. | **A-R2**, **A-R3** |
| **A4. Draw the external I/O sheet** | Implement the agreed LED, pushbutton, and any initial GPIO connector in `sheets/io.kicad_sch`. Calculate LED resistance from supply voltage, LED forward voltage, and chosen current; verify FPGA drive limits. Agree pull-ups/pull-downs, connector orientation, and voltage labels with Brandon's pin map. | I/O schematic and a connector pin table; no pin is assigned to a bank whose voltage is incompatible with its attached device. The programming connector stays on Brandon's clock/configuration sheet. | **A-R1**, **A-R3** |
| **A5. Prepare the layout proposal** | After both schematic halves are reviewed, compare practical layer counts and write a placement sketch for FPGA, regulators, decoupling, clock, and connectors. Check a prospective fabricator's stackup, spacing, drill, and assembly limits before choosing rules. | `Ahmad/layout-plan.md` records the proposed stackup and supplier source, return-path strategy, critical placement constraints, and package assembly concerns. Get Brandon's review before starting routing. | **A-R2**, **A-R4** |

**Ahmad's resources — read the relevant sections, not every page:**

- **A-R1 — [iCE40 UltraPlus Family Data Sheet](https://www.latticesemi.com/view_document?document_id=51968):** use *Recommended Operating Conditions*, *Power Supply Ramp Rates*, *Power-up Supply Sequence*, *Supply Current*, and *Power Supply Pins* to build the rail worksheet. Use the I/O electrical specifications for LEDs and connectors.
- **A-R2 — [iCE40 Hardware Checklist](https://www.latticesemi.com/-/media/LatticeSemi/Documents/ApplicationNotes/IK/FPGA-TN-02006-2-4-iCE40-Hardware-Checklist.ashx?document_id=47779):** use the UltraPlus-specific power, decoupling, and configuration guidance as a review checklist. It covers several device families; do not copy another family's requirements.
- **A-R3 — [KiCad 10 Schematic Editor](https://docs.kicad.org/10.0/en/eeschema/eeschema.html):** focus on electrical connections between sheets, assigning footprints, and electrical rules checking.
- **A-R4 — [KiCad 10 PCB Editor](https://docs.kicad.org/10.0/en/pcbnew/pcbnew.html):** focus on board stackup, design rules, zones, placement/routing, and DRC. Manufacturer fabrication limits must come from the board supplier you actually choose.

**First Ahmad PR:** power-budget worksheet and input-supply proposal. You do not
need to finish the power schematic before asking Brandon to review the assumptions.

### Brandon — FPGA core, pin mapping, clock, and programming

Work on `brandon/fpga-core`. Keep device decisions in `Brandon/device-plan.md` and
the pin map in `Brandon/pin-map.csv` (create these files). Preserve your existing
`Brandon/Background_Research` note.

| Task | What to do | Deliverable / done when | Read first |
| --- | --- | --- | --- |
| **B1. Confirm the FPGA and pin map** | Confirm the full orderable iCE40UP5K part and SG48 package against manufacturer documents. Check the KiCad symbol and footprint pin-by-pin, including the exposed pad. Identify all supply pins, I/O banks, configuration pins, and candidate LED/button pins. | A pin-map CSV with physical pin/pad, function, bank, rail requirement, proposed net, and source reference. Send Ahmad the rail/sequence requirements so A1 can be completed. | **B-R1**, **B-R2** |
| **B2. Choose how the board boots and gets programmed** | Select a supported configuration route and the exact programmer/adapter available to you. Decide whether external SPI flash is needed for the intended boot behavior. Define flash/programmer connections, reset/DONE handling, voltage levels, and how bus contention is avoided. | `Brandon/device-plan.md` has a small connection diagram, proposed programmer and flash parts if applicable, and the intended programming steps. Do not assume a generic JTAG header is the correct interface for this device. | **B-R3**, **B-R5** |
| **B3. Draw the FPGA core** | Place the verified FPGA symbol in `sheets/fpga_core.kicad_sch`; connect every required supply and ground pin, add device-local decoupling, and expose agreed signals to the other sheets. Assign the verified footprint. | Core schematic agrees with the pin map. Every power pin and exposed-pad connection has been checked; unused pins are handled according to the device guidance. Share an ERC report and a schematic export. | **B-R1**, **B-R2**, **A-R2**, **A-R3** |
| **B4. Draw clock and configuration circuits** | Choose internal versus external clocking for the first demo and document the reason. Add the chosen clock circuit if needed, configuration/reset circuitry, flash if chosen, and programmer connector to `sheets/clock_config.kicad_sch`. | Every clock/configuration net has an agreed name and voltage. The programming connector pinout can be compared directly with the actual adapter. Ahmad reviews the power and I/O connections. | **B-R3**, **B-R4**, **B-R5** |
| **B5. Demonstrate a usable programming workflow** | Choose a toolchain that supports the exact device. Create a minimal LED/button design and build a bitstream with matching pin constraints. If hardware is not available yet, stop at the build and document the future programming command and expected behavior. | A reproducible build note with tool versions, constraints tied to the pin map, and build output. Record programming or hardware tests only after they actually happen. | **B-R3**, **B-R6** |

**Brandon's resources:**

- **B-R1 — [iCE40 UltraPlus Family Data Sheet](https://www.latticesemi.com/view_document?document_id=51968):** focus on *Pinout Information*, *Ordering Part Numbers*, power requirements, and configuration signal descriptions.
- **B-R2 — [Official UP5K pinout spreadsheet](https://www.latticesemi.com/view_document?document_id=51971):** select the **SG48** package column when constructing the pin map. For the mechanical drawing, open **Package Diagrams** from the [UltraPlus documentation page](https://www.latticesemi.com/Products/FPGAandCPLD/iCE40UltraPlus?ActiveTab=Key+Documents). Match the exact package rather than relying only on a footprint name.
- **B-R3 — [iCE40 Programming and Configuration](https://www.latticesemi.com/view_document?document_id=46502):** determine the configuration mode, signal connections, reset timing, and programming sequence before choosing the header or flash circuit.
- **B-R4 — [iCE40 Oscillator User Guide](https://www.latticesemi.com/view_document?document_id=50670):** compare the available on-chip clock options with the first demo's needs. An external oscillator is a design decision, not an automatic requirement.
- **B-R5 — [iCE40 UltraPlus Breakout Board User Guide](https://media.latticesemi.com/-/media/LatticeSemi/Documents/UserManuals/EI/FPGA-UG-02001-1-2-iCE40-UltraPlus-Breakout-Board.ashx?document_id=51987):** inspect the schematic and programming connection examples. Cross-check copied circuits against current device documentation and the hardware checklist; the reference board is not a substitute for your own pin/power review.
- **B-R6 — [Lattice Radiant Software Tutorial](https://www.latticesemi.com/view_document?document_id=52521) and [Radiant documentation/downloads](https://www.latticesemi.com/Products/DesignSoftwareAndIP/FPGAandLDS/Radiant?ActiveTab=Help):** one manufacturer-supported starting route for the build workflow. Check device support, operating-system requirements, and licensing for the version you choose; use your own board's pin constraints rather than the tutorial board's assignments.

**First Brandon PR:** confirmed device/package, pin map, rail requirements, and
programming-route proposal. This unblocks Ahmad's regulator selection.

### Shared checkpoints and merge order

1. **Requirements:** review B1 and A1 together. Brandon makes the agreed updates to
   [docs/interfaces.md](docs/interfaces.md), so both of you do not edit that shared
   file simultaneously. Record exact device, rail names/voltages, I/O levels,
   programmer, and first-demo scope. Merge the research PRs.
2. **Independent schematics:** Ahmad completes A2-A4 while Brandon completes B2-B4.
   Each person opens a PR for their own sheets. Review each other's source
   references, component choices, and pin mapping before merging.
3. **Integration:** Brandon updates the root sheet pins/connections after the child
   sheets are merged. Both inspect the whole hierarchy and ERC report. Resolve
   errors and justify warnings/exclusions; assign all footprints. Do not treat a
   clean ERC result alone as proof that the circuit will work.
4. **Layout:** after schematic review, Ahmad owns placement/routing; Brandon
   reviews it and can continue B5 independently. Follow the
   [PCB handoff procedure](docs/layout-handoff.md) before changing layout editor.
5. **Pre-fabrication:** both check pin mapping, power/boot behavior, footprints,
   board rules, schematic parity, filled-zone DRC, BOM, and fabrication outputs.
   Agree on a current-limited bring-up and programming procedure before ordering.

Keep PRs small and record what is still incomplete. This is an ordered work plan,
not a claim that the design or any hardware testing has already been completed.

### Get the latest task plan onto your branch

Save and close KiCad, commit any work you want to keep, then run:

```sh
git fetch origin
git switch ahmad/power-io
git merge origin/main
```

Brandon substitutes `brandon/fpga-core` for the branch name. In GitHub Desktop, use
**Fetch origin**, select your branch, then merge `origin/main` into the current
branch. If a conflict appears, follow [CONTRIBUTING.md](CONTRIBUTING.md) rather than
overwriting the other person's changes.

## Repository contents

- Root `.kicad_pro`, `.kicad_sch`, `.kicad_pcb`: shared project and board.
- `sheets/`: independent schematic blocks.
- `libraries/`: project-local symbols, footprints, and 3D models when needed.
- `docs/interfaces.md`: electrical contracts and device decisions.
- `docs/layout-handoff.md`: current PCB editor and handoff procedure.
- `.github/`: pull-request checklist and file reviewers.
- `build/`: ignored local exports and rule-check reports.

The ignore rules exclude machine-local state and generated files. CAD files are
text-diffable but automatic merging of competing edits to the same CAD file is
disabled. GitHub branch protection is a separate repository setting; these files
do not enable it.
