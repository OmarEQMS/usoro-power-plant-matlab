---
description: The 600 MW drum boiler-turbine unit at a glance — the steam cycle, the control philosophy, and the map for the component-by-component tour.
---

# The 600 MW unit at a glance

This section walks through the plant the way the water goes through it:
into the boiler as feedwater, out of the turbines as electricity. Every
component page follows the same shape — *why it exists, how it works, its
design numbers, its equations, and which of the model's 47 states live in
it*.

::: why
A power plant is a loop, and loops are hard to learn linearly: every
component's input is another's output. The tour therefore follows the
water/steam path first (boiler → turbines → condenser → back to the
boiler), then the air/gas path that heats it, then the electrical
machines, and finally the control system that coordinates all of it.
:::

::: metrics Design point (100% load)
| Quantity | Value |
|---|---|
| Power output | 600 MW |
| Main steam flow | 1109 lbm/s |
| Throttle pressure | 2415 psia |
| Main steam / reheat temperature | 1000 °F / 1000 °F |
| Fuel flow (oil) | 80 lbm/s |
| Air flow | 1230 lbm/s |
| Grid frequency | 60 Hz (377 rad/s) |
:::

The unit is a **drum boiler** (steam and water separate in a large
horizontal drum) feeding a **tandem turbine train** — HP, IP and LP
stages with a reheat pass between HP and IP — and it operates
**boiler-following**: the turbine valves take the load, and the boiler's
job is to keep throttle pressure at its 2415 psia set point by adjusting
firing.

::: caution
The model reproduces the thesis' transient behavior quantitatively on most
tests, but it needs about 10% more fuel and air than the thesis' published
steady states — an open investigation documented in the repository. Pages
in this section quote design values with that caveat where it matters.
:::

The remaining pages of this section are being written; their scope is
fixed in the site plan. Continue with the [furnace](@plant/furnace), or
jump to the [Code section](@code/tour) to see how the plant becomes
MATLAB.
