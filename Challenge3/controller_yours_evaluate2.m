clc
clearvars
close all

% tau - torques applied to joints
% th - positions of the joints (angles)
% th_d - velocities of the joints (angular velocity)
% th_dd - acceleration of the joints
% _des - desired values (reference)
% _curr - current values (measured)
% ff_ - feedforward
% fb_ - feedback

rp = define_robot_parameters();
sim_time = 10; % simualtion time in seconds
dt = 0.03; % time difference in seconds
t = 0:dt:sim_time;

%% DESIRED TRAJECTORY DATA
d2r  = pi/180;             % degrees to radians
tp.w = 72*d2r;            % rotational velocity rad/s
tp.rx = 1.75; tp.ry = 1.25; % ellipse radii
tp.ell_an = 45*d2r;       % angle of inclination of ellipse
tp.x0 = 0.4;  tp.y0 = 0.4;  % center of ellipse  

rot_vel = 70:0.5:80;
RMSE_yours.x = zeros(1,length(rot_vel));
RMSE_yours.th = zeros(1,length(rot_vel));

Kp = [500; 500];
Kd = [50; 50];

% Your Code
folder = fileparts(which(mfilename));
addpath(genpath(folder));
load ANN/net.mat


%% SIMULATE ROBOT

for iter = 1:length(rot_vel)
    tp.w = rot_vel(iter)*d2r;

    % Calculate desired trajectory in task space and in joint space
    des = calculate_trajectory(t, tp, rp);

    initial_offset = [randi([-30,30]); randi([-30,30])];
    
    th_0 = des.th(:,1) - initial_offset;
    th_d_0 = des.th_d(:,1);

    %% SIMULATE ROBOT
    curr = simulate_robot(t, dt, th_0, th_d_0, des, rp, ...
        @(th_curr, th_d_curr, th_des, th_d_des, th_dd_des) ff_yours(th_curr, th_d_curr, th_des, th_d_des, th_dd_des, net), ...
        @(th_curr, th_d_curr, th_des, th_d_des) fb_pd(th_curr, th_d_curr, th_des, th_d_des, Kp, Kd));

    %robot_animation(t, curr, des);
    [RMSE_yours.x(iter), RMSE_yours.th(iter)] = analyze_performance(t, curr, des, false);
    
    curr2 = simulate_robot(t, dt, th_0, th_d_0, des, rp, ...
        @(th_curr, th_d_curr, th_des, th_d_des, th_dd_des) ff_dyn_model_2(th_curr, th_d_curr, th_des, th_d_des, th_dd_des, rp), ...
        @(th_curr, th_d_curr, th_des, th_d_des) fb_pd(th_curr, th_d_curr, th_des, th_d_des, Kp, Kd));

    %robot_animation(t, curr, des);
    [RMSE_DYN2.x(iter), RMSE_DYN2.th(iter)] = analyze_performance(t, curr2, des, false);
end

load RMSE_PD.mat;


f = figure('visible', 'on');
subplot(2,1,1);
plot(rot_vel,[RMSE_yours.x' RMSE_DYN2.x'],'LineWidth',1.5);
ylabel('RMSE x');
legend('yours','PD','DYN1','DYN2');
grid on

subplot(2,1,2);
plot(rot_vel,[RMSE_yours.th' RMSE_DYN2.th'],'LineWidth',1.5);
ylabel('RMSE th');
legend('yours','PD','DYN1','DYN2');
xlabel('rot vel [rad/s]');
grid on

set(findall(gcf,'-property','FontSize'),'FontSize',15)
saveas(f,'evaluation','epsc');

fprintf('mean RMSE x\n');
fprintf('yours %f\n', mean(RMSE_yours.x));
fprintf('DYN2 %f\n', mean(RMSE_DYN2.x));

 
% f = figure('visible', 'on');
% subplot(2,1,1);
% plot(rot_vel,[RMSE_yours.x' RMSE_PD.x' RMSE_DYN1.x' RMSE_DYN2.x'],'LineWidth',1.5);
% ylabel('RMSE x');
% legend('yours','PD','DYN1','DYN2');
% grid on
% 
% subplot(2,1,2);
% plot(rot_vel,[RMSE_yours.th' RMSE_PD.th' RMSE_DYN1.th' RMSE_DYN2.th'],'LineWidth',1.5);
% ylabel('RMSE th');
% legend('yours','PD','DYN1','DYN2');
% xlabel('rot vel [rad/s]');
% grid on
% 
% set(findall(gcf,'-property','FontSize'),'FontSize',15)
% saveas(f,'evaluation','epsc');
% 
% fprintf('mean RMSE x\n');
% fprintf('yours %f\n', mean(RMSE_yours.x));
% fprintf('PD %f\n', mean(RMSE_PD.x));
% fprintf('DYN1 %f\n', mean(RMSE_DYN1.x));
% fprintf('DYN2 %f\n', mean(RMSE_DYN2.x));