%% original

t0 = tic;
t_arr = [];
y_arr = [];
t_now = toc(t0);
while t_now < 5
    y_arr = [y_arr y_t(t_now)];
    t_arr = [t_arr t_now];
    t_now = toc(t0);
end
%
figure;
plot(t_arr, y_arr, 'linewidth', 2);
xlabel("$t$ (sec)", 'interpreter', 'latex');
ylabel("$y(t)$", 'interpreter', 'latex')
title("$y(t)={sin}(2\pi t)-{cos}(3\pi t)$",...
    'interpreter', 'latex');
set(gca,'FontSize',14);
set(gca,'LineWidth',2);
set(gcf, 'Renderer', 'painters');
grid on;

%% ANALYTICAL
t0 = tic;
tA_arr = [];
yA_arr = [];
t_now = toc(t0);
while t_now < 5
    yA_arr = [yA_arr y_t_dot(t_now)];
    tA_arr = [tA_arr t_now];
    t_now = toc(t0);
end
%
figure;
plot(tA_arr, yA_arr, 'linewidth', 2);
xlabel("$t$ (sec)", 'interpreter', 'latex');
ylabel("$\dot{y}(t)$", 'interpreter', 'latex')
title("$\dot{y}(t)=2\pi{cos}(2\pi t)+3\pi{sin}(3\pi t)$",...
    'interpreter', 'latex');
set(gca,'FontSize',14);
set(gca,'LineWidth',2);
set(gcf, 'Renderer', 'painters');
grid on;


%% NUMERICAL
t0 = tic;
tN_arr = [];
yNdot_ar = [];
y_now = 0;
y_prev = 0;
t_now = toc(t0);
t_prev = 0;
while t_now < 5
    t_now = toc(t0);
    y_now = y_t(t_now);
    y_dif = y_now - y_prev;
    t_dif = t_now - t_prev;

    if t_dif > 0
        yNdot = y_dif / t_dif;
        yNdot_ar = [yNdot_ar, yNdot];
        tN_arr = [tN_arr, t_now];
    end

    y_prev = y_now;
    t_prev = t_now;
end
yNdot_ar(1)=yNdot_ar(2);
%
figure;
plot(tN_arr, yNdot_ar, 'linewidth', 2);
hold on
plot(tA_arr, yA_arr, 'r:', 'linewidth', 1.5);
xlabel("$t$ (sec)", 'interpreter', 'latex');
ylabel("$\dot{y}(t)$", 'interpreter', 'latex')
xlim([0,5]);
title("Numerical vs Analytical",...
    'interpreter', 'latex');
legend("Numerical","Analytical");
set(gca,'FontSize',14);
set(gca,'LineWidth',2);
set(gcf, 'Renderer', 'painters');
grid on;


%% INTEGRATION (UNIFORM GRID) – LEFT & RIGHT
% Tujuan: bandingkan integral numerik Left & Right Riemann vs integral analitik
Tend = 5;
N    = 2000;                      % jumlah segmen (lebih besar -> lebih akurat)
tU   = linspace(0, Tend, N+1);    % grid seragam
h    = tU(2) - tU(1);
yU   = y_t(tU);

% Integral analitik (ground truth) pada grid yang sama
Y_exact = Y_analytic(tU);

% LEFT Riemann: gunakan tinggi pada ujung kiri tiap sub-interval
% Y_left(k) = sum_{i=0}^{k-1} y(t_i) * h, dengan Y_left(1)=0
Y_left = [0, cumsum(yU(1:end-1))*h];

% RIGHT Riemann: gunakan tinggi pada ujung kanan tiap sub-interval
% Y_right(k) = sum_{i=1}^{k} y(t_i) * h, dengan Y_right(1)=0
Y_right = [0, cumsum(yU(2:end))*h];

% Plot kurva integral
figure;
plot(tU, Y_exact, 'k-', 'LineWidth', 2); hold on;
plot(tU, Y_left,  'LineWidth', 1.4);
plot(tU, Y_right, 'LineWidth', 1.4);
grid on; xlim([0,Tend]);
xlabel("$t$ (sec)", 'interpreter','latex');
ylabel("$\int_0^t y(\tau)\,d\tau$", 'interpreter','latex');
title("Analytical vs Left & Right Riemann (Uniform Grid)", 'interpreter','latex');
legend("Analytical","Left Riemann","Right Riemann","Location","best");
set(gca,'FontSize',14); set(gca,'LineWidth',2); set(gcf,'Renderer','painters');

% Plot kurva error
figure;
plot(tU, Y_left  - Y_exact, 'LineWidth', 1.2); hold on;
plot(tU, Y_right - Y_exact, 'LineWidth', 1.2);
yline(0,'k:');
grid on; xlim([0,Tend]);
xlabel("$t$ (sec)", 'interpreter','latex');
ylabel("Error", 'interpreter','latex');
title("Error: Left & Right Riemann vs Analytical", 'interpreter','latex');
legend("Left - Analytical","Right - Analytical","Location","best");
set(gca,'FontSize',14); set(gca,'LineWidth',2); set(gcf,'Renderer','painters');

% Metrik ringkas
end_err_left  = abs(Y_left(end)  - Y_exact(end));
end_err_right = abs(Y_right(end) - Y_exact(end));
max_err_left  = max(abs(Y_left  - Y_exact));
max_err_right = max(abs(Y_right - Y_exact));

fprintf('\n== Uniform grid, LEFT vs RIGHT (N=%d, h=%.4g)\n', N, h);
fprintf('End-point abs error:\n');
fprintf('  Left  : %.3e\n', end_err_left);
fprintf('  Right : %.3e\n', end_err_right);
fprintf('Max abs error over time:\n');
fprintf('  Left  : %.3e\n', max_err_left);
fprintf('  Right : %.3e\n', max_err_right);


%% Function
function out = y_t(t)
    out = sin(2*pi*t)-cos(3*pi*t);
end

function out = y_t_dot(t)
    out = 2*pi*cos(2*pi*t)+3*pi*sin(3*pi*t);
end

function out = Y_analytic(t)
    % Integral analitik y(t) = sin(2πt) - cos(3πt)
    % ∫ y dt = -cos(2πt)/(2π) - sin(3πt)/(3π) + C, pilih C agar Y(0)=0
    out = -(cos(2*pi*t))/(2*pi) - (sin(3*pi*t))/(3*pi) + 1/(2*pi);
end
