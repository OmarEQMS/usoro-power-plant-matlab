---
description: Learn the mathematics, the machinery and the MATLAB behind a 600 MW drum boiler-turbine power plant model.
---

# A power plant you can read

This site teaches one specific thing, thoroughly: the 47th-order dynamic
model of a 600 MW drum boiler–turbine power plant from P. B. Usoro's 1977
MIT thesis, and the MATLAB implementation that lives in this repository.
By the end you should be able to open any model file and recognize every
equation in it — where it comes from, what it assumes, and why it is
written the way it is.

<div class="row row-cols-1 row-cols-md-3 g-4 my-2">
  <div class="col">
    <div class="card h-100">
      <div class="card-body">
        <h2 class="card-title h5">1 · Basic Knowledge</h2>
        <p class="card-text">The math and physics toolkit: units, balances,
        steam properties, flow networks, machines, feedback control and
        numerical integration. Assumes algebra and a first exposure to
        differential equations — everything else is built here.</p>
      </div>
      <div class="card-footer bg-transparent border-0 pb-3">
        <a class="btn btn-primary btn-sm" href="basics/units.html">Start with units</a>
      </div>
    </div>
  </div>
  <div class="col">
    <div class="card h-100">
      <div class="card-body">
        <h2 class="card-title h5">2 · Power Plant</h2>
        <p class="card-text">A guided walk through the unit, component by
        component — furnace to generator — with each component's purpose,
        design metrics, governing equations and dynamics.</p>
      </div>
      <div class="card-footer bg-transparent border-0 pb-3">
        <a class="btn btn-primary btn-sm" href="plant/overview.html">Tour the plant</a>
      </div>
    </div>
  </div>
  <div class="col">
    <div class="card h-100">
      <div class="card-body">
        <h2 class="card-title h5">3 · Code</h2>
        <p class="card-text">File by file through <code>src/+model</code>:
        what each class does, what every variable tracks, and how the plant
        equations become MATLAB — ending with three full
        equation-to-code walkthroughs.</p>
      </div>
      <div class="card-footer bg-transparent border-0 pb-3">
        <a class="btn btn-primary btn-sm" href="code/tour.html">Read the code</a>
      </div>
    </div>
  </div>
</div>

## How to read this site

The three sections are ordered: **Basic Knowledge** pages only use earlier
pages, **Power Plant** pages link back to the math they rely on, and
**Code** pages link back to the components they implement. Reading straight
through works; jumping in anywhere works too, because every page links to
its prerequisites.

Abbreviations are spelled out on first use and always carry a tooltip —
hover over one, like HP or RK4, to see its long name.

## The source

> P. B. Usoro, *Modeling and Simulation of a Drum Boiler-Turbine Power
> Plant Under Emergency State Control*, M.S. thesis, MIT Department of
> Mechanical Engineering, May 1977.

The model is **47th order**: 23 states describe the physical plant and 24
describe its analog control system. It runs in English engineering units
throughout — the first Basic Knowledge page, [Units](@basics/units),
explains exactly what that means and why it matters more than it sounds.
