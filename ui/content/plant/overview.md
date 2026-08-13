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

## The plant, on one page

::: figure Steam in red, feedwater in blue, air/flue gas in gray, extraction steam dashed. Every component is clickable — it opens that component's page.
<svg class="plant-schematic" viewBox="0 0 960 570" role="img" aria-label="Schematic of the 600 MW drum boiler-turbine unit">
<defs>
<marker id="mR" markerWidth="7" markerHeight="7" refX="5.5" refY="3" orient="auto"><path d="M0,0 L6,3 L0,6 z" fill="#c0392b"/></marker>
<marker id="mB" markerWidth="7" markerHeight="7" refX="5.5" refY="3" orient="auto"><path d="M0,0 L6,3 L0,6 z" fill="#2471a3"/></marker>
<marker id="mG" markerWidth="7" markerHeight="7" refX="5.5" refY="3" orient="auto"><path d="M0,0 L6,3 L0,6 z" fill="#7f8c8d"/></marker>
</defs>
<path d="M105,120 V108 H612" stroke="#b3b6b7" stroke-width="8" fill="none" opacity="0.7"/>
<a href="air-gas-path.html"><title>Fans and the air/gas path</title>
<g>
<rect class="comp" x="612" y="44" width="22" height="72" fill="#d5d8dc" stroke="#7f8c8d" stroke-width="1.5"/>
<path d="M623,44 V26" stroke="#7f8c8d" stroke-width="2" marker-end="url(#mG)" fill="none"/>
<circle class="comp" cx="570" cy="108" r="13" fill="#eaecee" stroke="#616a6b" stroke-width="1.5"/>
<text x="570" y="112" text-anchor="middle" font-size="9" fill="#424949">ID</text>
<circle class="comp" cx="75" cy="430" r="13" fill="#fef9e7" stroke="#ca6f1e" stroke-width="1.5"/>
<text x="75" y="434" text-anchor="middle" font-size="9" fill="#873600">FD</text>
<path d="M75,417 V364" stroke="#e67e22" stroke-width="2.2" marker-end="url(#mG)" fill="none"/>
<text x="86" y="394" font-size="9" fill="#873600">air</text>
<path d="M462,132 V252 H164" stroke="#7f8c8d" stroke-width="1.8" stroke-dasharray="5,4" marker-end="url(#mG)" fill="none"/>
<text x="468" y="200" font-size="9" fill="#7f8c8d">gas recirc</text>
</g></a>
<a href="furnace.html"><title>Furnace and burners</title>
<g>
<rect class="comp" x="50" y="120" width="110" height="240" rx="6" fill="#fdebd0" stroke="#ca6f1e" stroke-width="1.5"/>
<text x="105" y="240" text-anchor="middle" font-size="11" fill="#873600">FURNACE</text>
<path d="M58,306 l16,6 -16,6 z" fill="#e67e22"/>
<path d="M58,326 l16,6 -16,6 z" fill="#e67e22"/>
<path d="M58,346 l16,6 -16,6 z" fill="#e67e22"/>
<text x="88" y="366" font-size="8.5" fill="#935116">tilting burners</text>
</g></a>
<a href="superheaters.html"><title>Superheaters and spray</title>
<g>
<rect class="comp" x="170" y="86" width="58" height="44" fill="#ebf5fb" stroke="#2874a6" stroke-width="1.5"/>
<text x="199" y="112" text-anchor="middle" font-size="9.5" fill="#1b4f72">PSH</text>
<rect class="comp" x="246" y="86" width="58" height="44" fill="#ebf5fb" stroke="#2874a6" stroke-width="1.5"/>
<text x="275" y="112" text-anchor="middle" font-size="9.5" fill="#1b4f72">SSH</text>
<path d="M214,130 V152 H262 V134" stroke="#c0392b" stroke-width="2.5" fill="none"/>
<path d="M250,172 V156" stroke="#2471a3" stroke-width="1.8" marker-end="url(#mB)" fill="none"/>
<text x="250" y="184" text-anchor="middle" font-size="8.5" fill="#2471a3">spray</text>
</g></a>
<a href="reheater.html"><title>Reheater</title>
<g>
<rect class="comp" x="322" y="86" width="58" height="44" fill="#ebf5fb" stroke="#2874a6" stroke-width="1.5"/>
<text x="351" y="112" text-anchor="middle" font-size="9.5" fill="#1b4f72">RHTR</text>
</g></a>
<a href="economizer-airheater.html"><title>Economizer and air heater</title>
<g>
<rect class="comp" x="398" y="86" width="58" height="44" fill="#ebf5fb" stroke="#2471a3" stroke-width="1.5"/>
<text x="427" y="112" text-anchor="middle" font-size="9.5" fill="#1a5276">ECON</text>
<rect class="comp" x="474" y="86" width="60" height="44" fill="#fef9e7" stroke="#ca6f1e" stroke-width="1.5"/>
<text x="504" y="112" text-anchor="middle" font-size="8.5" fill="#873600">AIR HTR</text>
</g></a>
<a href="waterwalls-drum.html"><title>Waterwalls, drum and circulation</title>
<g>
<rect class="comp" x="185" y="168" width="105" height="34" rx="17" fill="#f9ebea" stroke="#943126" stroke-width="1.5"/>
<text x="237" y="190" text-anchor="middle" font-size="10.5" fill="#78281f">DRUM</text>
<path d="M160,185 H181" stroke="#b03a2e" stroke-width="2.5" marker-end="url(#mR)" fill="none"/>
<path d="M237,202 V236" stroke="#2471a3" stroke-width="2.2" fill="none"/>
<circle class="comp" cx="237" cy="248" r="11" fill="#eaf2f8" stroke="#2471a3" stroke-width="1.5"/>
<text x="237" y="252" text-anchor="middle" font-size="8" fill="#1a5276">RP</text>
<path d="M237,259 V300 H164" stroke="#2471a3" stroke-width="2.2" marker-end="url(#mB)" fill="none"/>
</g></a>
<path d="M205,168 V134" stroke="#c0392b" stroke-width="2.5" marker-end="url(#mR)" fill="none"/>
<a href="turbine-train.html"><title>The turbine train</title>
<g>
<path d="M275,130 V315 H426" stroke="#c0392b" stroke-width="2.5" marker-end="url(#mR)" fill="none"/>
<path d="M341,306 L359,324 M341,324 L359,306" stroke="#c0392b" stroke-width="2" fill="none"/>
<text x="350" y="298" text-anchor="middle" font-size="8.5" fill="#922b21">governor valves</text>
<polygon class="comp" points="430,308 472,300 472,354 430,346" fill="#f4f6f7" stroke="#283747" stroke-width="1.5"/>
<text x="451" y="331" text-anchor="middle" font-size="10" fill="#212f3c">HP</text>
<polygon class="comp" points="518,302 560,296 560,358 518,352" fill="#f4f6f7" stroke="#283747" stroke-width="1.5"/>
<text x="539" y="331" text-anchor="middle" font-size="10" fill="#212f3c">IP</text>
<polygon class="comp" points="606,296 648,290 648,364 606,358" fill="#f4f6f7" stroke="#283747" stroke-width="1.5"/>
<text x="627" y="331" text-anchor="middle" font-size="10" fill="#212f3c">LP</text>
<path d="M472,327 H518 M560,327 H606 M648,327 H701" stroke="#283747" stroke-width="3" fill="none"/>
<path d="M472,310 H492 V155 H356 V134" stroke="#c0392b" stroke-width="2" fill="none" marker-end="url(#mR)"/>
<text x="470" y="149" text-anchor="end" font-size="8.5" fill="#922b21">cold reheat</text>
<path d="M336,130 V175 H504 V310 H514" stroke="#c0392b" stroke-width="2" fill="none" marker-end="url(#mR)"/>
<text x="380" y="190" font-size="8.5" fill="#922b21">hot reheat 1000&#176;F</text>
<path d="M560,320 H602" stroke="#c0392b" stroke-width="2.5" marker-end="url(#mR)" fill="none"/>
<text x="581" y="312" text-anchor="middle" font-size="8" fill="#922b21">x-over</text>
</g></a>
<a href="generator.html"><title>Generator and grid</title>
<g>
<circle class="comp" cx="730" cy="327" r="25" fill="#fef5e7" stroke="#b7950b" stroke-width="1.5"/>
<text x="730" y="331" text-anchor="middle" font-size="10" fill="#7d6608">GEN</text>
<path d="M755,327 H798" stroke="#7d6608" stroke-width="2.5" fill="none"/>
<path d="M800,307 V347 M808,313 V341 M816,319 V335" stroke="#7d6608" stroke-width="2.5" fill="none"/>
<text x="808" y="298" text-anchor="middle" font-size="9" fill="#7d6608">&#8734; grid, 60 Hz</text>
</g></a>
<a href="condenser.html"><title>Condenser</title>
<g>
<path d="M627,364 V416" stroke="#c0392b" stroke-width="2.5" marker-end="url(#mR)" fill="none"/>
<rect class="comp" x="580" y="420" width="104" height="46" fill="#ebf5fb" stroke="#2471a3" stroke-width="1.5"/>
<text x="632" y="440" text-anchor="middle" font-size="9.5" fill="#1a5276">CONDENSER</text>
<path d="M590,452 q8,-8 16,0 t16,0 t16,0 t16,0 t16,0" stroke="#5dade2" stroke-width="1.5" fill="none"/>
</g></a>
<a href="feedwater-train.html"><title>The feedwater train</title>
<g>
<path d="M580,455 H560" stroke="#2471a3" stroke-width="2.2" fill="none"/>
<circle class="comp" cx="545" cy="455" r="11" fill="#eaf2f8" stroke="#2471a3" stroke-width="1.5"/>
<text x="545" y="459" text-anchor="middle" font-size="8" fill="#1a5276">CP</text>
<path d="M534,455 H484" stroke="#2471a3" stroke-width="2.2" marker-end="url(#mB)" fill="none"/>
<rect class="comp" x="402" y="436" width="78" height="38" fill="#eaf2f8" stroke="#2471a3" stroke-width="1.5"/>
<text x="441" y="459" text-anchor="middle" font-size="9" fill="#1a5276">LP HTRS</text>
<path d="M402,455 H364" stroke="#2471a3" stroke-width="2.2" marker-end="url(#mB)" fill="none"/>
<rect class="comp" x="282" y="434" width="78" height="42" rx="12" fill="#eaf2f8" stroke="#2471a3" stroke-width="1.5"/>
<text x="321" y="459" text-anchor="middle" font-size="8.5" fill="#1a5276">DEAERATOR</text>
<path d="M282,455 H243" stroke="#2471a3" stroke-width="2.2" marker-end="url(#mB)" fill="none"/>
<circle class="comp" cx="227" cy="455" r="12" fill="#eaf2f8" stroke="#2471a3" stroke-width="1.5"/>
<text x="227" y="459" text-anchor="middle" font-size="8" fill="#1a5276">FP</text>
<text x="227" y="480" text-anchor="middle" font-size="8" fill="#922b21">steam-driven</text>
<path d="M215,455 H156" stroke="#2471a3" stroke-width="2.2" marker-end="url(#mB)" fill="none"/>
<rect class="comp" x="74" y="436" width="78" height="38" fill="#eaf2f8" stroke="#2471a3" stroke-width="1.5"/>
<text x="113" y="459" text-anchor="middle" font-size="9" fill="#1a5276">HP HTRS</text>
<path d="M74,455 H40 V70 H423" stroke="#2471a3" stroke-width="2.2" fill="none"/>
<path d="M423,70 427,70 427,82" stroke="#2471a3" stroke-width="2.2" marker-end="url(#mB)" fill="none"/>
<text transform="rotate(-90 33 280)" x="33" y="280" text-anchor="middle" font-size="9" fill="#2471a3">feedwater</text>
<path d="M410,130 V186 H294" stroke="#2471a3" stroke-width="2.2" marker-end="url(#mB)" fill="none"/>
</g></a>
<path d="M451,348 V408 H113 V432" stroke="#c0392b" stroke-width="1.4" stroke-dasharray="4,3" marker-end="url(#mR)" fill="none"/>
<path d="M539,352 V418 H321 V430" stroke="#c0392b" stroke-width="1.4" stroke-dasharray="4,3" marker-end="url(#mR)" fill="none"/>
<path d="M617,360 V400 H441 V432" stroke="#c0392b" stroke-width="1.4" stroke-dasharray="4,3" marker-end="url(#mR)" fill="none"/>
<rect x="735" y="468" width="200" height="88" rx="6" fill="#fbfcfc" stroke="#d5d8dc"/>
<path d="M745,484 H775" stroke="#c0392b" stroke-width="2.5"/>
<text x="782" y="488" font-size="9" fill="#424949">steam</text>
<path d="M745,502 H775" stroke="#2471a3" stroke-width="2.2"/>
<text x="782" y="506" font-size="9" fill="#424949">feedwater / condensate</text>
<path d="M745,520 H775" stroke="#7f8c8d" stroke-width="2.5"/>
<text x="782" y="524" font-size="9" fill="#424949">air / flue gas</text>
<path d="M745,538 H775" stroke="#c0392b" stroke-width="1.4" stroke-dasharray="4,3"/>
<text x="782" y="542" font-size="9" fill="#424949">extraction steam</text>
</svg>
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
The model reproduces the thesis' transient behavior quantitatively, and
its trimmed operating points sit on the thesis' published steady-state
tables. One documented residual: the printed deck's air path has zero
margin at rated load, so the two maximum-capability tests (4 and 6)
hunt or settle slightly under their figures. Pages in this section
quote design values as published; the corrections it took to get here
are recorded in the [model changelog](@plant/changelog).
:::

The remaining pages of this section are being written; their scope is
fixed in the site plan. Continue with the [furnace](@plant/furnace), or
jump to the [Code section](@code/tour) to see how the plant becomes
MATLAB.
