"""Integer reference for the 1 MHz, two-stage 5/4 radio.

Uses direct window sums instead of the RTL's running-sum arithmetic.
All returned values describe the circuit after a rising clock edge.
"""

QUARTER = [0, 12, 25, 37, 49, 60, 71, 81, 90, 98, 103, 109, 113, 117, 120, 123, 124]
HALF = QUARTER + QUARTER[-2:0:-1]
SINE = HALF + [-value for value in HALF]


def wrap25(value):
    return (value + (1 << 24)) % (1 << 25) - (1 << 24)


class RadioModel:
    def __init__(self):
        self.phase = 0
        self.input_reg = 0
        self.h1 = [0] * 11
        self.h2 = [0] * 11
        self.sum1 = self.fir = self.average = self.limited = 0
        self.counter = 0
        self.pending = self.active = 16

    @property
    def sine(self):
        return SINE[self.phase >> 18]

    def tick(self, adc):
        assert -128 <= adc <= 127
        # PWM samples the previous limited audio and duty registers.
        pwm = int(self.counter < self.active)
        if self.counter == 31:
            self.active = self.pending
        self.pending = self.limited // 32 + 16
        self.counter = (self.counter + 1) % 32

        # Average consumes the previous FIR output on this edge.
        error = wrap25(self.fir * 2048 - self.average)
        self.average = wrap25(self.average + error // 512)
        self.h2 = [self.sum1 // 16] + self.h2[:-1]
        self.h1 = [self.input_reg] + self.h1[:-1]
        self.sum1 = sum(self.h1)
        self.fir = sum(self.h2)
        self.input_reg = (adc * self.sine) // 32
        self.phase = (self.phase + 7633633) & 0xffffff
        audio = wrap25(self.fir * 2048 - self.average) // 2048
        self.limited = max(-512, min(511, audio // 4))
        return pwm
