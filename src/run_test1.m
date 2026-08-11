%RUN_TEST1 Thesis Test 1 with the OOP model: load ramp 100% -> 77.5%.
%   Reproduces Usoro (1977) Figure V.1 (pp. 65-70). Run with src/ on the
%   MATLAB path. See docs/model_oop.md for the architecture.

par = usoro.Parameters();
sim = usoro.Simulator(usoro.PowerPlant(par), ...
                      usoro.ControlSystem(par), ...
                      usoro.LoadProfile.test1());
res = sim.run(usoro.InitialConditions.at100(), 700);

L = res.log;
col = @(name) L(:, strcmp(res.logNames, name));
t = col('t');

figure % (1) thesis p.65: turbine speed, power, throttle pressure, steam flow
titles1 = {'ntr','mwo','psso','whp'};
for i = 1:4
    ax = subplot(2, 2, i);
    plot(ax, t, col(titles1{i}));
    title(ax, titles1{i});
end
figure % (2) p.66: boiler master, governor valve, fuel and air demands
titles2 = {'c3md','cacvd','cfld','card'};
for i = 1:4
    ax = subplot(2, 2, i);
    plot(ax, t, col(titles2{i}));
    title(ax, titles2{i});
end
figure % (3) p.67: drum/deaerator volumes, feedwater and condensate demands
titles3 = {'vdrw','vdew','cfwd','cdwd'};
for i = 1:4
    ax = subplot(2, 2, i);
    plot(ax, t, col(titles3{i}));
    title(ax, titles3{i});
end
figure % (4) p.68: superheat/reheat enthalpies, spray and tilt demands
titles4 = {'hsso','hrho','csyd','cxggd'};
for i = 1:4
    ax = subplot(2, 2, i);
    plot(ax, t, col(titles4{i}));
    title(ax, titles4{i});
end
figure % (5) p.69: feed pump speed, gas recirc, furnace pressure, waterwall metal
titles5 = {'nfp','cgrd','cfnd','twwm'};
for i = 1:4
    ax = subplot(2, 2, i);
    plot(ax, t, col(titles5{i}));
    title(ax, titles5{i});
end
figure % (6) p.70: fan and pump speeds
titles6 = {'nfd','nid','nrp','ncp'};
for i = 1:4
    ax = subplot(2, 2, i);
    plot(ax, t, col(titles6{i}));
    title(ax, titles6{i});
end
