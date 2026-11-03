# PCB editing handoff

Initial designated editor: **Ahmad**. Current state: blank board; layout not started.
This record coordinates people; it is not a technical lock. Do not create a second
PCB-editing branch while someone else is routing.

To transfer editing to Brandon (or back):

1. Current editor saves/closes KiCad, commits, pushes, and opens a PR.
2. Other designer reviews the layout and DRC report; merge the PR.
3. Agree explicitly on the next editor and update this record in the handoff PR.
4. Next editor pulls the shared default branch and starts a new layout branch.
5. Previous editor works on separate schematic/documentation files until handoff.

At each handoff record the merged commit, next editor, incomplete routes, open DRC
findings, and pending schematic changes. Never edit one shared cloud-sync checkout
from two computers; each person uses a local Git clone.
