# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import random

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_fir_wrapper(dut):
    """Pin-only reference test, usable for RTL and gate-level simulation."""
    h1 = [0] * 11
    h2 = [0] * 11
    previous_sum1 = 0
    dut.clk.value = 0
    dut.rst_n.value = 1
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(10, unit="ns")

    async def check_output(expected, upper_input):
        # Switch pages between clocks; allow gate-level propagation to settle.
        dut.uio_in.value = upper_input
        await Timer(100, unit="ns")
        assert int(dut.uo_out.value) == (expected & 0xff)
        dut.uio_in.value = upper_input | 0x10
        await Timer(100, unit="ns")
        assert int(dut.uo_out.value) == ((expected >> 8) & 0xff)
        assert int(dut.uio_oe.value) == 0
        assert int(dut.uio_out.value) == 0

    async def reset():
        nonlocal h1, h2, previous_sum1
        dut.clk.value = 0
        dut.rst_n.value = 0
        dut.ui_in.value = 0
        dut.uio_in.value = 0
        await check_output(0, 0)  # Asynchronous reset, without a rising clock.
        await Timer(800, unit="ns")
        dut.rst_n.value = 1
        h1, h2 = [0] * 11, [0] * 11
        previous_sum1 = 0

    async def sample(product):
        nonlocal h1, h2, previous_sum1
        q = product // 16
        assert -1016 <= q <= 1024
        bits = q & 0xfff
        upper_input = ((bits >> 8) & 0xf) | 0xa0  # Also exercise unused pins.
        dut.clk.value = 0
        dut.ui_in.value = bits & 0xff
        dut.uio_in.value = upper_input
        await Timer(500, unit="ns")
        h2 = [previous_sum1 // 16] + h2[:10]
        h1 = [q] + h1[:10]
        previous_sum1 = sum(h1)
        expected = sum(h2)
        dut.clk.value = 1
        await check_output(expected, upper_input)
        await Timer(300, unit="ns")
        return expected

    await reset()
    for _ in range(30):
        assert await sample(0) == 0
    impulse = [await sample(256)]
    for _ in range(23):
        impulse.append(await sample(0))
    assert impulse == [0] + list(range(1, 12)) + list(range(10, 0, -1)) + [0, 0]

    for product, settled in [(16384, 7744), (-16256, -7689), (-17, -22)]:
        for _ in range(40):
            result = await sample(product)
        assert result == settled

    rng = random.Random(298)
    for i in range(1000):
        if i == 500:
            await reset()
        await sample(rng.randrange(-128, 128) * rng.randrange(-128, 128))
    await reset()
    for _ in range(25):
        assert await sample(0) == 0
