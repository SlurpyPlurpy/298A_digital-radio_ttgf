# Updated Design Proposal & Timeline

---

### 1. Statement of Purpose

Digital Radio Backend: The purpose of this project is to design a digital radio backend that implements the final demodulating and filtering stages of an AM radio. It operates on a clean, pre-filtered digital AM input that is at 455 kHz IF and utilizes a synchronous multiplier to demodulate the signal down to baseband and a FIR decimation filter to extract a clean audio output.

### 2. System Diagram

![proposal-system-diagram.png](img/proposal-system-diagram.png)

### 3. I/O Pin Assignments

| **I/O Pin** | **Usage** |
| --- | --- |
| ui_in[7:0] | Dedicated input: digital 8-bit IF input |
| ui_out [0] | Dedicated output: PWM output signal |
| ui_out [1] | Dedicated output: NCO debug output |
| clk | Clock |
| rst_n | Active-low system reset |

### 4. Proposed specification

| **Specification** | **Value** | **Notes** |
| --- | --- | --- |
| Input Carrier Frequency | 455kHz | Industry standard frequency for IF |
| Input bit width | 8-bits | Contains amplitude information of the incoming AM signal |
| Clock Speed | 1MHz | This is roughly twice the input carrier frequency to ensure we can accurately reproduce the message signal |
| Message frequency to preserve (FIR Filter) | 0 - 5kHz | |

**To be determined:** Other FIR filter specs like the number of taps & coefficient values will need to be determined through testing.

### 5. Timeline of completion / Who Does What?

| Date | Description of Tasks |
| --- | --- |
| Week 9 <br>(Nov 5 - Nov 12) | Get a first draft of the Verilog code finished:<br>• Multiplier [ Angela ]<br>• PWM Output [ Angela ]<br>• FIR Filter Implementation [ Ethan ]<br>&nbsp;&nbsp;&nbsp;&nbsp;◦ Initial draft of parameters/taps<br>&nbsp;&nbsp;&nbsp;&nbsp;◦ Basic first tests to verify parameters |
| Week 10 <br>(Nov 12 - Nov 19) | Testing (CocoTB):<br>• Full set of unit tests for each module<br>&nbsp;&nbsp;&nbsp;&nbsp;◦ Multiplier & PWM tests [ Angela ]<br>&nbsp;&nbsp;&nbsp;&nbsp;◦ Verify parameters set for FIR [ Ethan ]<br>• Set of end-to-end tests [ Both ]<br><br>Evaluate the size of the project, make sure it fits. |
| Week 11 <br>(Nov 19 - Nov 26) | Review / Testing [ Both ]:<br>• Work on any areas that require attention:<br>&nbsp;&nbsp;&nbsp;&nbsp;◦ Continue with creating tests<br>&nbsp;&nbsp;&nbsp;&nbsp;◦ Verify FIR parameters<br>&nbsp;&nbsp;&nbsp;&nbsp;◦ Work on reducing size of project |
| Week 12 <br>(Nov 26 - Dec 3) | Review / Documentation [ Both ]:<br>• Update all documentation on GitHub (`/docs` folder)<br>• Final preparations for Final Submission<br>• Wrap up anything that remains to be completed. |