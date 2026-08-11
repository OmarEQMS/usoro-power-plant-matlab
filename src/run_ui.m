%RUN_UI Launch the interactive plant dashboard (PlantApp).
%   Schematic of the 600 MW plant with clickable components (each opens a
%   live chart window), scenario selection (thesis Tests 1-7 or a steady
%   hold), play/pause/reset and simulation-speed control. Tests 2-7 need
%   the trimmed operating points (src/tools/trim_operating_points.m).

app = PlantApp(); %#ok<NASGU>
