%% Code Intro
%{
Author: Noah Stern
email: noahbstern@utexas.edu
Based on information and base code files provided by FUJIFILM/visualsonics to work with VEVO F2 and LAZR-X systems 

This code allows for importing and plotting single wavelength photoacoustic
data over time. To run it also requires Photostability_Read_Single_base.m,
VsiParseVarargin.m, and VsiParseXml.m. Versions of this code are used to
monitor photostability over time. 

%}



%% Load Data intro

close all;
clear all;

baseDir = '.';  % Directory of the data
frameList = -1;  % Vector of frames (-1 to load all frames)
outputFilesFlag = false; % Set to true to save the reconstructed images for the dataset
modeName = '.pamode'; % File type extension

baseFilename_1 = 'Depth Dependence_Jagg 890nm-2023-03-29-11-46-08'; % Filename (without the file type extensions)
PaMode_1 = Photostability_Single_Read(baseDir, baseFilename_1, frameList, modeName);


%% Sample Plotting 


figure;
imagesc(PaMode_1.Width, PaMode_1.Depth, PaMode_1.Data{10})
title('PAI Signal 890nm')
xlabel('Width (mm)');
ylabel('Depth (mm)');
axis image;
h_bar = colorbar;
colormap(jet);



%% Drawing ROIs
wavelengths = 680:5:970;
title('Background')
background = roipoly();
title('Draw Liposome ROI')
tube1 = roipoly();
title('Draw Free J-Aggs ROI')
tube2 = roipoly();
title('Draw Free IcG ROI')
tube3 = roipoly();


%% Calculate Mean Using ROI
all_data = [PaMode_1.Data];     % add in more data after PaMode_1.Data if multiple files are imported
length_data = length(all_data);
time_interval = 30/length_data;  % determine interval between points knowing 30minutes total elapsed time
time = [0:time_interval:(30-time_interval)]; % generate time points

background_allmeans = [];
tube1_allmeans = [];
tube2_allmeans = [];
tube3_allmeans = [];

% calculate mean 
    for t = 1:length_data
        data_temp = all_data{t};
        mean_background(t) = mean(data_temp(background(:)==1));
        mean_tube1(t) = mean(data_temp(tube1(:)==1));
        mean_tube2(t) = mean(data_temp(tube2(:)==1));
        mean_tube3(t) = mean(data_temp(tube3(:)==1));   
    end
    background_allmeans = [background_allmeans; mean_background];
    tube1_allmeans = [tube1_allmeans; mean_tube1];
    tube2_allmeans = [tube2_allmeans; mean_tube2];
    tube3_allmeans = [tube3_allmeans; mean_tube3];

% background subtract (not entirely necessary)
bs_tube1 = tube1_allmeans - background_allmeans;
bs_tube2 = tube2_allmeans - background_allmeans;
bs_tube3 = tube3_allmeans - background_allmeans;


%% Curve Fitting and Plotting 
figure;
hold on 
grid on 

% generate curves for tubes 1 and 3, add in 2 if desired 
p1 = polyfit(time, bs_tube1, 4);
p3 = polyfit(time, bs_tube3, 4);
v1 = polyval(p1, time);
v3 = polyval(p3, time);

% plot everything
plot(time,v1, 'b', 'LineWidth', 1.5)
plot(time,v3, 'g' , 'LineWidth', 1.5)
plot(time, bs_tube1, 'bo', 'MarkerSize', .2)
plot(time, bs_tube3, 'go', 'MarkerSize', .2)
title('Signal Intensity over 30 Minutes of 800nm Pulses')
ylim([0 400])
set(gca,'FontSize',12,'LineWidth',2)
ylabel('Intensity')
xlabel('Time (minutes)')
legend('Liposomal J-Aggs', 'Free IcG')

%% Normalize and Plot Again
% Normalize based on the maximum value for each tube
max_1 = max(max(bs_tube1));
max_2 = max(max(bs_tube2));
max_3 = max(max(bs_tube3));

norm_1 = bs_tube1/max_1;
norm_2 = bs_tube2/max_2;
norm_3 = bs_tube3/max_3;

figure;
hold on 
grid on 

pn1 = polyfit(time, norm_1, 3);
pn3 = polyfit(time, norm_3, 4);
vn1 = polyval(pn1, time);
vn3 = polyval(pn3, time);

plot(time,vn1, 'b', 'LineWidth', 1.5)
plot(time,vn3, 'g' , 'LineWidth', 1.5)
plot(time, norm_1, 'bo', 'MarkerSize', .2)
% plot(time, bs_tube2, 'c')
plot(time, norm_3, 'go', 'MarkerSize', .2)

title('Normalized Signal Intensity over 30 Minutes of 800nm Pulses')
set(gca,'FontSize',12,'LineWidth',2)
ylim([0 1])
ylabel('Intensity')
xlabel('Time (minutes)')
legend('Liposomal J-Aggs', 'Free IcG')
%% Average Matrix Calculations

avg_signal1 = zeros(size(PaMode_1.Data{1}));
    for a1 = 1:length(PaMode_1.Data)
        avg_signal1 = [avg_signal1+PaMode_1.Data{a1}];
    end
avg_signal1 = avg_signal1/length(PaMode_1.Data);


