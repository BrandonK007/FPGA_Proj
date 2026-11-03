# FPGA signal analyzer: beginner reference sheet

[Back to the project README](../README.md)

**Read sections 1–3 first. Everything after that is a lookup sheet.** You do not
need to understand the entire system before starting. The first milestone needs
no purchased board and no PCB fabrication.

## 1. What are we actually making?

A small **waveform and spectrum analyzer**: feed in a low-voltage electrical
signal, record how its voltage changes, and display its waveform and frequency
content. Start with one known sine wave from a lab function generator.

We are **not manufacturing an FPGA chip**. We will configure the digital logic
inside an existing AMD FPGA on a development board. Separately, we will design a
small KiCad PCB that connects an analog-to-digital converter (ADC) to that board.

The recommended host is a Zynq-7020 board. Zynq contains both an Arm processor
that runs software and programmable logic where our custom digital circuits live.
See [AMD's Zynq reference](https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM).

**Current reality:** this repository contains a plan and empty KiCad sheets.
No host board or ADC is selected; no acquisition circuit or analyzer is working
yet. All numeric examples below are teaching examples, not project results.

## 2. Follow one signal through the finished system

```text
Lab function generator: produces a known changing voltage
        |
        v
OUR KiCad PCB
  Input conditioning/filter -> ADC: voltage becomes a sequence of numbers
        |
        | SPI: transfers those numbers over digital wires
        v
BOUGHT/BORROWED Zynq development board
  Our FPGA logic: SPI controller -> FIFO (temporary sample queue)
        |
        | AXI4-Lite registers: processor controls/reads our logic
        v
  Arm processor running our C program: collects and exports samples
        |
        v
Computer: Python plots voltage vs. time; later, FFT shows frequency content
```

**Example:** a 1 kHz sine wave repeats 1,000 times per second. A time plot shows
the wave shape; a spectrum shows a peak near 1 kHz. These are two views of the
same captured samples. Our first FFT will run in software, not inside the FPGA.

The FPGA's job here is predictable data capture, buffering, and communication.
A microcontroller could handle some low-frequency versions of this instrument;
we choose an FPGA to learn digital hardware design and verification too.

## 3. Your first work session: just these two deliverables

### Ahmad: describe the signal we want to capture

Create `Ahmad/signal-requirements.md` on your branch with this starter note:

```text
First demo: capture one low-voltage sine wave and plot it on a computer.
Signal source: lab function generator; access/model still to confirm.
Highest input frequency we want: TBD.
Minimum/maximum input voltage, including DC offset: TBD.
Lab equipment we can use: TBD (generator, oscilloscope, power supply).
Board budget or borrowing options: TBD.
ADC selection and sample rate: TBD after the signal requirements.
```

Find out what equipment you can borrow. Read the ADC introduction linked in
section 8 and explain in your own words what an ADC does. **Done means a short
note with known facts and honest TBDs.** You do not need to pick parts or route
a PCB in this session.

### Brandon: make a counter work in simulation

First learn a clock, reset, register, and testbench using the glossary below.
Then create a small SystemVerilog counter and testbench in `rtl/` and `tb/`.
Choose and record a simulator/tool version before writing its run instructions.

- Use an 8-bit counter for this exercise: values 0 through 255.
- On a rising clock edge: reset makes it 0; otherwise an enabled counter adds 1.
- When enable is 0, it holds its value. After 255, it wraps to 0.
- Have the testbench check reset, increment, hold, and wrap automatically.
- Save the command to run the test and the actual result in `Brandon/first-simulation.md`.

**Done means a repeatable passing simulation you can explain.** A screenshot of
code alone is not a passing test. This counter supplies fake sample numbers;
it is not an ADC or a working signal analyzer.

**Next session, together:** put a tiny 4-entry FIFO after the fake samples.
Write 10, 20, 30, 40; read them back in that order. Define full/empty behavior
before coding it, then test it. This small learning FIFO is separate from the
README's proposed 256-entry final buffer. AXI and the physical board come later.

## 4. The words you need now

| Term | Plain-English meaning | In our project |
| --- | --- | --- |
| FPGA | A chip containing configurable digital logic and connections. | We configure it to capture and move data. |
| Development board | A ready-made PCB carrying the chip, power circuitry, connectors, and other support parts. | Buy or borrow this instead of designing the Zynq host from scratch. |
| PCB / schematic / layout | PCB is the physical circuit board; schematic describes electrical connections; layout places parts and copper. | KiCad makes our ADC expansion board. |
| Bit / byte | A bit is 0 or 1; a byte is 8 bits. | An unsigned 8-bit number can represent 0–255. |
| Clock / rising edge | A repeating digital timing signal / its transition from low to high. | Registers can update on rising edges. |
| Register | A small piece of digital storage. | Holds a counter value or a control setting. |
| Reset / enable | Reset puts logic into a defined state; enable permits an operation. | Clear the counter; allow or pause counting. |
| RTL | Register-transfer level: describing stored values and the logic that updates/moves them. | Our FPGA design source. |
| Verilog / SystemVerilog | Hardware description languages; SystemVerilog extends Verilog. | We use a synthesizable subset for circuits and additional features for tests. |
| Testbench | Code that supplies inputs and checks a design. | Acts as the clock, reset, and checker in simulation. |
| Simulation | Running a model of the circuit on a computer. | Find logic bugs without owning a board. |
| FIFO | First in, first out: a queue with limited capacity. | Samples leave in the order they arrived. |

**RTL is different from ordinary software:** separate clocked hardware blocks
can operate at the same time. A counter and an SPI controller can both advance
on the same clock edge. Their source files do not imply one runs after the other.
Start with one clock and synchronous reset in the learning exercise.

## 5. The words you can look up later

| Term | Meaning and why we need it |
| --- | --- |
| ADC | Analog-to-digital converter: samples a voltage and represents it with a digital code. |
| Sample rate, S/s | Number of voltage samples captured per second; not the same as SPI clock frequency. |
| SPI | A serial link: controller supplies a clock (SCK), selects a peripheral (CS), and transfers bits on data wires. Follow the chosen ADC's timing and wiring. |
| PS / PL | Zynq's processing system (Arm CPU and supporting hardware) / programmable logic (our configurable circuits). |
| AXI4-Lite | An on-chip interface for reading/writing control and status registers. It stays inside the Zynq; it is not the connector wiring to our PCB. |
| Register map | A list of software-visible addresses and what reading/writing each one does. |
| Handshake / backpressure | A transfer happens when sender and receiver agree; a receiver can make the sender wait. |
| Overflow / underflow | Trying to add data to a full FIFO / remove data from an empty FIFO. We must define what happens. |
| Synthesis | Turns synthesizable RTL into a network of digital hardware resources. |
| Implementation / timing | Places and connects that network inside the FPGA, then checks whether signals arrive within required timing limits. Simulation alone does not prove timing. |
| Constraints / XDC | A file describing clocks, pin assignments, electrical standards, and timing requirements for the build tools. |
| Bitstream | Configuration data loaded into the FPGA to establish our hardware design. It is separate from the CPU's C program. |
| Vivado / Vitis | AMD tools for FPGA hardware design / embedded software development. Exact workflow depends on the selected versions. |
| FFT / spectrum | FFT computes frequency-bin information from samples; a spectrum plot displays frequency content. It does not create more measurement information than the samples contain. |
| ILA / oscilloscope | ILA observes selected internal digital signals; an oscilloscope measures physical voltage waveforms. |
| ERC / DRC | KiCad electrical-rule / design-rule checks. They catch certain mistakes, not all design errors. |

## 6. A few numbers that make the system easier to understand

**These examples are not selected specifications.** Record agreed real values
in [interfaces.md](interfaces.md) once we choose the signal range and parts.

| Example | Calculation | Meaning |
| --- | --- | --- |
| Sample a 1 kHz sine at 10 kS/s | 10,000 / 1,000 = 10 samples per cycle | Samples describe points along the wave. Actual accuracy also depends on the ADC and analog circuit. |
| Capture 1,000 samples at 10 kS/s | 1,000 / 10,000 = 0.1 s | Length of the captured record. |
| FFT of that record | 10,000 / 1,000 = 10 Hz bin spacing | Frequency-grid spacing, not a guarantee of resolving two nearby tones. Windowing and noise matter too. |
| Ideal 12-bit ADC spanning 3.3 V | 2^12 = 4,096 codes; 3.3 / 4,096 ≈ 0.806 mV per step | Quantization step, not guaranteed measurement accuracy or a selected ADC input range. |
| 1 MHz SPI, 16 clock bits per sample | 1,000,000 / 16 = 62,500 transfers/s maximum before overhead | Conversion time, gaps, commands, and the ADC datasheet can reduce actual sample rate. |

**Aliasing:** a signal changing too quickly for the sampling rate can appear
at a misleading lower frequency. For our baseband input, keep the wanted band
below half the sample rate and leave room for a real analog anti-alias filter.
That filter goes **before** the ADC; a later software filter cannot undo aliasing.
See [Analog Devices' sampling introduction](https://www.analog.com/en/resources/technical-articles/basics-of-bandlimited-sampling-and-aliasing.html).

**Voltage range:** a sine wave centered on 0 V goes negative. A single-supply
ADC may not accept that directly. Choose the input range, offset/conditioning,
reference voltage, and protection from the actual ADC datasheet before connecting
a generator. Digital I/O at 3.3 V does not establish the ADC's analog input range.

## 7. How the pieces become a working project

| Stage | Evidence that lets us move on |
| --- | --- |
| 1. Understand and simulate | Requirements note plus passing counter test. |
| 2. Buffer fake samples | FIFO tests check order, reset, full/empty, and rejected operations. |
| 3. Choose the hardware | Agreed host/ADC, signal range, sample rate, power/pin map, and budget. |
| 4. Transfer samples in simulation | SPI controller tested against a model of the selected ADC's behavior. |
| 5. Connect the Arm processor | Tested AXI registers, C software, constrained FPGA build, and timing review. |
| 6. Build and test the interface PCB | Reviewed schematic/layout, fabrication, bring-up, and actual voltage/transfer checks. |
| 7. Display a real waveform | Captured samples plotted with correct voltage/time scaling and compared with a known input. |
| 8. Add spectrum analysis | Software FFT with documented sampling, window/scaling choices, and comparison against the known signal. |

PCB work and RTL work can overlap after the interface is agreed. The stages are
checkpoints, not promises about how many days each part will take.

## 8. Resources: read only the part you need

| Person / when | Resource | What to get from it |
| --- | --- | --- |
| Both, now | [AMD FPGA architecture introduction](https://docs.amd.com/r/en-US/ug1291-viv/FPGA-Architecture) | Recognize logic, storage, and routing; skip advanced architecture detail. |
| Ahmad, now | [Analog Devices: analog-to-digital conversion](https://wiki.analog.com/university/courses/electronics/text/chapter-20) | Understand sampling and quantization; write down how an ADC converts a voltage into a number. |
| Brandon, first simulation | [AMD Vivado logic simulation guide, UG900](https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation) | Find the RTL behavioral simulation/testbench workflow for the installed version; start with the counter only. |
| Ahmad, schematic stage | [KiCad schematic manual](https://docs.kicad.org/10.0/en/eeschema/eeschema.html) | Symbols, connections, labels, footprints, and ERC. Layout can wait. |
| Both, board selection | [Digilent Zybo Z7 manual](https://digilent.com/reference/_media/reference/programmable-logic/zybo-z7/zybo-z7_rm.pdf) | Identify the host interfaces and power limits. This edition is revision B; match the actual board's revision. |
| Brandon, after small simulations | [Digilent Zybo Z7 examples](https://github.com/Digilent/Zybo-Z7) | Study a matching board/tool-version example; understand and credit any reused work. |
| Both, AXI stage | [AMD AXI overview](https://www.amd.com/en/products/adaptive-socs-and-fpgas/intellectual-property/axi.html) | Understand why the processor needs an interface to our logic. Detailed protocol references are in the README. |

You do not need to read a whole processor manual or the AXI specification today.
When stuck, record **what you expected, what happened, and the smallest example
that reproduces it**. That gives your teammate something concrete to help debug.

## 9. Working together without breaking each other's work

- **Clone:** your local copy of the repository. Each person has their own clone.
- **Branch:** your set of changes while you work on a task.
- **Commit:** a saved checkpoint in Git. **Push:** upload commits to GitHub.
- **Pull request (PR):** ask your teammate to review changes before merging into `main`.
- **Merge:** combine the reviewed work. It does not check electrical correctness.

Ahmad owns the first requirements note; Brandon owns the first counter/testbench.
Review each other's results and explain them aloud. Keep separate files while
working, and let only one person edit the shared PCB layout at a time. Follow
[CONTRIBUTING.md](../CONTRIBUTING.md) for the actual Git commands.

**Today's finish line: one requirements note and one working counter simulation.**
