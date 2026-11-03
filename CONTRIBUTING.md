# Working together

## One-time GitHub setup

Brandon owns `BrandonK007/FPGA_Proj`; Ahmad's account is `AhmadH05`. Both need write
access. If the repository plan supports rulesets, protect the default branch:
require a pull request and one approval, dismiss stale approvals, and block force
pushes/deletion. If unavailable, follow the same review process manually.
CODEOWNERS requests reviewers where supported; it does not grant permissions or
lock files. No protection setting is enabled by this scaffold.

## Each work session

Close KiCad before switching branches or pulling/merging. Start with a clean
working tree. Examples below assume the shared default branch is `main`; use its
actual name if different.

```sh
git switch main
git pull --ff-only
git switch -c ahmad/power-input
```

Brandon can independently use `brandon/fpga-core`. Use one short-lived branch per
task, not a permanent personal copy of the entire project.

Edit only the agreed files. Save and close KiCad, inspect the diff, and stage
explicit paths rather than blindly adding every modified file:

```sh
git status --short
git diff --stat
git add sheets/power.kicad_sch
git commit -m "Add input power circuit"
git push -u origin ahmad/power-input
```

Open a PR into the shared default branch and request the other person's review.
Attach schematic/PCB screenshots and state what ERC/DRC was run. After review,
squash merge on GitHub, then both pull the updated default branch. Start the next
task on a fresh branch. Do not force-push another person's branch.

## Avoiding KiCad conflicts

- Own separate child sheets. Root sheet pins, global labels, reference annotation,
  project settings, and library tables are shared changes: coordinate them first.
- Agree on net names, voltages, directions, and pin mapping in `docs/interfaces.md`.
- Reserve reference numbers per sheet when annotating: power 100-199, FPGA core
  200-299, clock/config 300-399, I/O 400-499 (per prefix). Check uniqueness globally.
  These ranges are a convention, not an automatically configured annotation rule.
- Do not reannotate the whole project while someone is editing another sheet.
- Use project-relative `${KIPRJMOD}` paths for custom libraries and models.
- Review `.kicad_pro` diffs: shared design rules matter; UI-only churn does not.
- Pull merged schematic updates before updating the PCB from the schematic.
- One PCB editor at a time; use `docs/layout-handoff.md` and a message to agree.

If two branches change the same CAD file, stop and choose one as the integration
base. Reapply the other change in KiCad, then inspect and run checks. Do not delete
conflict markers or accept all of "ours/theirs" without reviewing what is lost.
Even a conflict-free merge of different sheets needs electrical review.

## Before a hardware PR is merged

Open the full hierarchy and inspect the changed block and its interfaces. Run ERC.
After board edits, refill zones and run DRC with schematic parity. Record remaining
findings and exclusions; never present an empty starter design as verified hardware.

From the repository root (make `kicad-cli` available on PATH):

```sh
mkdir build
kicad-cli sch erc --severity-all --exit-code-violations -o build/erc.rpt FPGA_Proj.kicad_sch
kicad-cli pcb drc --refill-zones --schematic-parity --severity-all --exit-code-violations -o build/drc.rpt FPGA_Proj.kicad_pcb
```

On Windows, if KiCad is not on PATH, use PowerShell's call operator with the full
path: `& 'C:/Program Files/KiCad/10.0/bin/kicad-cli.exe' sch erc ...`.
An unrouted or empty board will have expected DRC findings; document them instead
of suppressing checks. Gerbers and fabrication approval come after joint review.
