"""Pin-only radio test: run on both RTL and synthesized gate-level netlists.

Never reads user_project hierarchy or internal nets. This is a functional
simulation at 1 MHz; static timing analysis checks physical path delays.
"""
import math
import random

import cocotb
from cocotb.triggers import Timer
from radio_model import RadioModel


@cocotb.test()
async def test_radio_pins(dut):
    model = RadioModel()
    cycles = 0
    active_duties = set()
    clipped = set()

    def check_pins(expected):
        assert int(dut.uo_out.value) == expected, f"PWM mismatch at cycle {cycles}"
        assert int(dut.uio_out.value) == 0, "Unused bidirectional outputs changed"
        assert int(dut.uio_oe.value) == 0, "Bidirectional outputs enabled"

    async def reset(held_clocks=0):
        nonlocal model
        dut.clk.value = 0
        dut.rst_n.value = 1
        dut.ena.value = 1
        dut.ui_in.value = 0
        dut.uio_in.value = 0
        await Timer(500, unit="ns")
        dut.rst_n.value = 0
        await Timer(500, unit="ns")
        check_pins(0)  # Asynchronous reset, before a clock edge.
        for _ in range(held_clocks):
            dut.ui_in.value = 127
            dut.clk.value = 1
            await Timer(500, unit="ns")
            check_pins(0)
            dut.clk.value = 0
            await Timer(500, unit="ns")
        dut.rst_n.value = 1
        model = RadioModel()

    async def tick(adc):
        nonlocal cycles
        dut.clk.value = 0
        dut.ui_in.value = adc & 0xff
        dut.uio_in.value = cycles & 0xff
        # The current top-level does not gate operation with ena.
        dut.ena.value = cycles & 1
        await Timer(500, unit="ns")
        expected = model.tick(adc)
        dut.clk.value = 1
        await Timer(500, unit="ns")
        check_pins(expected)
        active_duties.add(model.active)
        clipped.add(model.limited)
        dut.clk.value = 0
        cycles += 1
        return expected

    await reset()
    highs = 0
    for _ in range(128):
        highs += await tick(0)
    assert highs == 64, "Silence must produce 50% duty after reset"

    # Streaming signed extremes, impulses, and deterministic random input.
    for adc in [127, -128, -1, 1]:
        for _ in range(64):
            await tick(adc)
    await tick(127)
    for _ in range(64):
        await tick(0)
    rng = random.Random(29854)
    for i in range(2048):
        if i == 997:
            await reset(held_clocks=3)
        await tick(rng.randrange(-128, 128))

    # AM at the project's supported 10% and 50% modulation levels.
    for depth in [0.1, 0.5]:
        await reset()
        for n in range(6000):
            adc = round(80 * (1 + depth * math.cos(2*math.pi*1000*n/1e6))
                        * math.sin(2*math.pi*455000*n/1e6))
            await tick(adc)

    # Full-scale aligned/opposite carriers exercise limiting and DC steps.
    await reset()
    for sign in [1, -1, 1, -1]:
        for _ in range(256):
            await tick(sign * (127 if model.sine >= 0 else -127))
    assert {-512, 511} <= clipped, "Stimulus must exercise both limiter bounds"
    assert len(active_duties) >= 8, "Stimulus must exercise multiple PWM duties"

    # Reset near FIR fill and PWM frame boundaries, with stale history present.
    for length in [1, 10, 11, 12, 31, 32, 33]:
        await reset(held_clocks=2)
        for _ in range(length):
            await tick(rng.randrange(-128, 128))
    await reset()
    for _ in range(128):
        await tick(0)
    dut._log.info("Checked %d clock cycles using external pins only", cycles)
