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
