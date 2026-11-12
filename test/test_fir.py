# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import random
import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_fir_wrapper(dut):
    """RTL-only reference test of the FIR driven by the connected mixer."""
    h1 = [0] * 11
    h2 = [0] * 11
    previous_sum1 = 0
    dut.clk.value = 0
    dut.rst_n.value = 1
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(10, unit="ns")
    dut.rst_n.value = 0
    await Timer(100, unit="ns")
    dut.rst_n.value = 1

    async def check_output(expected):
        raw = int(dut.user_project.fir_sum.value)
        actual = raw - 16384 if raw & 8192 else raw
        assert actual == expected, f"FIR: got {actual}, expected {expected}"
        assert int(dut.uio_oe.value) == 0
        assert int(dut.uio_out.value) == 0

    async def reset():
        nonlocal h1, h2, previous_sum1
        dut.clk.value = 0
        dut.rst_n.value = 0
        dut.ui_in.value = 0
        dut.uio_in.value = 0
        await Timer(100, unit="ns")
        await check_output(0)
        dut.rst_n.value = 1
        h1, h2 = [0] * 11, [0] * 11
        previous_sum1 = 0

    async def sample(adc_sample):
        nonlocal h1, h2, previous_sum1
        dut.clk.value = 0
        dut.ui_in.value = adc_sample & 0xff
        await Timer(500, unit="ns")
        # The FIR sees the mixer value BEFORE this rising edge.
        raw = int(dut.user_project.mixer_sample.value)
        product = raw - 65536 if raw & 32768 else raw
        h2 = [previous_sum1 // 16] + h2[:10]
        h1 = [product // 16] + h1[:10]
        previous_sum1 = sum(h1)
        expected = sum(h2)
        dut.clk.value = 1
        await Timer(500, unit="ns")
        await check_output(expected)
        return expected

    await reset()
    for _ in range(30):
        assert await sample(0) == 0
    # A one-sample ADC impulse followed by a full filter flush.
    await sample(127)
    for _ in range(24):
        result = await sample(0)
    assert result == 0

    # The NCO keeps running: constant ADC samples do not mean constant products.
    for adc_sample in [127, -128, -1]:
        for _ in range(40):
            await sample(adc_sample)

    rng = random.Random(298)
    for i in range(1000):
        if i == 500:
            await reset()
        await sample(rng.randrange(-128, 128))
    await reset()
    for _ in range(25):
        assert await sample(0) == 0
