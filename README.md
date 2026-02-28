# 🎹 FPGA Modular Synthesizer & FM Transmitter 📻

**Final Project – Digital Systems Laboratory** *Developed on an Intel FPGA (MAX10 family) using Verilog HDL.*

## 📌 Project Overview
This project presents a full hardware implementation of a modular digital synthesizer and a Digital Signal Processing (DSP) system on an FPGA. The system generates complex waveforms in real-time, processes them through a customizable effects chain (VCA, VCF, Delay), and finally modulates the digital audio signal via FM (Frequency Modulation) for wireless transmission, which can be received by any standard FM radio.

---

## 🏗️ System Architecture
The system was designed using a **"Divide and Conquer" modular architecture**, heavily inspired by analog Eurorack synthesizers. Each component acts as an independent black box, with a strict separation between combinational and sequential logic.

```mermaid
graph TD
    classDef control fill:#2b2b2b,stroke:#00ffcc,stroke-width:2px,color:#fff;
    classDef process fill:#1e1e1e,stroke:#ff0055,stroke-width:2px,color:#fff;
    classDef sound fill:#1e1e1e,stroke:#ffaa00,stroke-width:2px,color:#fff;

    Ctrl(Synth Controller) :::control
    Vib(LFO 1: Vibrato) :::control
    Trem(LFO 2: Tremolo) :::control
    Arp[Arpeggiator / Master Clock] :::process
    
    Osc[[VCO: Main Oscillator]] :::sound
    Vca[[VCA: Env & Amp]] :::sound
    Filt[[VCF: SVF Filter]] :::sound
    Del[[BRAM Tape Delay]] :::sound
    Fm((FM Transmitter)) :::process

    Ctrl -->|Base Pitch| Vib
    Vib -.->|Pitch Mod| Arp
    Arp -->|Notes| Osc
    Arp -.->|Pluck Trig| Vca
    Ctrl -->|Master Sync| Trem
    Osc -->|Audio| Vca
    Trem -.->|AM Mod| Vca
    Vca -->|Audio| Filt
    Filt -->|Audio| Del
    Del -->|Audio| Fm
    Fm -->|RF Signal| Antenna((Antenna))
```

### 🎛️ Key Modules:
* **LFO Module:** A generic Low-Frequency Oscillator (triangle wave) based on a Phase Accumulator and bitwise MSB logic. Used for both Vibrato (FM) and Tremolo (AM).
* **Arpeggiator:** Acts as the Master Clock of the system. Breaks base frequencies into major chord progressions.
* **VCO (Main Oscillator):** A DDS-based oscillator featuring a Sine wave (via ROM), Sawtooth, and Square waves, combined with a parallel Detune engine for a thicker sound.
* **VCA & Envelope:** Controls signal amplitude. Includes a "Pluck" decay envelope triggered dynamically by the Arpeggiator's note changes.
* **VCF (Chamberlin SVF):** An advanced digital filter (Low-Pass + Resonance) implemented using Fixed-Point Arithmetic (16-bit fractional math).
* **BRAM Delay:** A hardware memory-based delay/echo effect, featuring a Tape Glide mechanism and a clean feedback mixer.

---

## 🛠️ Engineering Challenges & DSP Solutions
During development, several classic DSP artifacts emerged, requiring creative hardware-level solutions:

### 1. Integer Overflow Clicks in the Delay Mixer
* **The Issue:** When summing the Dry and Wet (Feedback) signals in the delay mixer, low frequencies occasionally exceeded the 8-bit maximum boundary (127). This caused an integer wraparound into extreme negative values, resulting in aggressive, jarring audio "clicks."
* **The Solution (Saturation & Headroom):** We expanded the calculation registers to 10-bit and implemented a Saturation "defense wall" (Soft Clipping) that clamps out-of-bounds values at 127 or -128. Additionally, a clean headroom mixer was built using arithmetic division (bit shifting) to divide the dry and echo signals by 2 prior to summation.

### 2. Time Discontinuities (Audio Popping)
* **The Issue:** Changing the Delay Time parameter in real-time caused the BRAM read pointer to instantly teleport to a new address. Tearing the audio waveform this way created loud "pop" noises.
* **The Solution (Tape Glide):** We simulated the physical behavior of an analog Tape Echo machine. An intermediate slew-rate register was introduced. When the user changes the delay time, the memory pointer glides step-by-step toward the target value. The result is a smooth, musical pitch-bending effect instead of a digital pop.

### 3. Audio Distortion in Fixed-Point Math
* **The Issue:** The SVF filter initially output heavily distorted audio. The filter relies on bit shifting to simulate fractional multiplication/division. Without explicitly defining variables as `signed`, right shifts pushed logical zeros instead of the sign bit, completely destroying the negative half of the audio waveform.
* **The Solution:** A strict migration to `signed` variables across the entire DSP chain, ensuring Arithmetic Right Shifts (`>>>`) preserve waveform integrity.

### 4. Global Synchronization (Master Sync Subdivision)
* **The Issue:** How to sync the LFOs (Vibrato/Tremolo) to the exact BPM of the Arpeggiator without utilizing hardware-heavy Division modules?
* **The Solution:** A Master/Slave architecture. The Arpeggiator was designated as the Master Clock. When "Sync" is enabled, the independent LFOs bypass their own frequency counters and instead derive their speed directly from the Arpeggiator's step size using hardware bit-shifts (multiplying/dividing by 2). This achieved perfect musical subdivisions (1/4, 1/8, 1/16, 1/32 notes) with zero additional DSP cost.

---

## 🎮 Hardware Controls Interface
The system is physically controlled via the FPGA board's peripherals:
* **SW[1:0]:** Waveform selection (00=Sine, 01=Saw, 10=Square, 11=Mute).
* **SW[2]-SW[9]:** Effect toggles (Vibrato, Tremolo, Arp, LPF, Detune, Pluck, Sync, Delay).
* **KEY[0]:** Global Asynchronous Reset.
* **KEY[1] / KEY[2]:** UP/DOWN push buttons (Short press to change values, Long press to navigate edit screens).
* **7-Segment Display:** Visualizes the currently edited parameter (Hz, Subdivisions, or Milliseconds).
* **LEDR:** Status indicators – blinks during parameter editing, stays solid when an effect is active. A dedicated LED pulses constantly to indicate the Master Tempo.

---
*This project demonstrates a practical application of Digital Signal Processing theories on parallel hardware, achieving zero-latency audio generation and modulation.*