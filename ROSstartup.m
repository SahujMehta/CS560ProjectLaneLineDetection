%% Start Up Script
% Start CarlaUE4.exe to start the CARLA server.

% Launch the virtual machine.

% Run this command with the URI you get from the VM
rosinit('http://192.168.150.128:11311')

rostopic list
open_system('Lateral Controls MPC/Model');



%% At end run this in prompt
%rosshutdown

