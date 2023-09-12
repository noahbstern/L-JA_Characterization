%% Code Intro
%{
Author: Noah Stern
email: noahbstern@utexas.edu
Based on information and base code files provided by FUJIFILM/visualsonics to work with VEVO F2 and LAZR-X systems 

This code allows for importing and plotting spectral profiles of photoacoustic
data over time. To run it also requires Photostability_Read_Spectro_base.m,
VsiParseVarargin.m, and VsiParseXml.m. Versions of this code are used to
monitor photostability over time. 

%}


%% Import Data
close all;
clear all;

baseDir = '.';  % Directory of the data
frameList = -1;  % Vector of frames (-1 to load all frames)
outputFilesFlag = false; % Set to true to save the reconstructed images for the dataset
modeName = '.pamode'; % File type extension

baseFilename_pre = 'Depth Dependence_Jagg Depth Spectro-2023-03-29-11-39-25'; % Filename (without the file type extensions)
PaMode_pre = Photostability_Read_Spectro_base(baseDir, baseFilename_pre, frameList, modeName);


%% Plot First Bit of Data

figure;

colormap(jet);
a = 1;
while a < 59
    imagesc(PaMode_pre.Width, PaMode_pre.Depth, log10(PaMode_pre.Data{a}))
    h_bar = colorbar;
    title((a*5)+680)
    xlabel('Width (mm)');
    ylabel('Depth (mm)');
    axis image;
    a = a+1;
    pause(.1)
end



%% Acquire ROIs
wavelength = 23;

figure;
colormap(jet);
imagesc(PaMode_pre.Width, PaMode_pre.Depth, log10(PaMode_pre.Data{23}))
h_bar = colorbar;
title((23*5)+680)
xlabel('Width (mm)');
ylabel('Depth (mm)');
axis image;

wavelengths = 680:5:970;
title('Draw Background')
background = roipoly();
title('Draw Liposome ROI')
tube1 = roipoly();
title('Draw Free J-Aggs ROI')
tube2 = roipoly();
title('Draw Free IcG ROI')
tube3 = roipoly();


%% Calculate Means Using ROI
PA_Group = [PaMode_pre.Data]'; % add in more data after PaMode_1.Data if multiple files are imported
background_allmeans = [];
tube1_allmeans = [];
tube2_allmeans = [];
tube3_allmeans = [];

data_temp = PA_Group{1,1};
allnorm_background = [];
allnorm_tube1 = [];
allnorm_tube2 = [];
allnorm_tube3 = [];


for t = 1:59
    % 3d Grab the t-th image
    data_temp = PA_Group{1,t};
    % 3e Calculate mean
    mean_background(t) = mean(data_temp(background(:)==1));
    mean_tube1(t) = mean(data_temp(tube1(:)==1));
    mean_tube2(t) = mean(data_temp(tube2(:)==1));
    mean_tube3(t) = mean(data_temp(tube3(:)==1));

    norm_back = mean_background/max(mean_background);
    norm1 = mean_tube1/max(mean_tube1);
    norm2 = mean_tube2/max(mean_tube2);
    norm3 = mean_tube3/max(mean_tube3);


    % 3f Calculate 95% CI
    ci_background(t) = 1.96*std(data_temp(background(:)==1))/sqrt(sum(background(:)));
    ci_tube1(t) = 1.96*std(data_temp(tube1(:)==1))/sqrt(sum(tube1(:)));
    ci_tube2(t) = 1.96*std(data_temp(tube2(:)==1))/sqrt(sum(tube2(:)));
    ci_tube3(t) = 1.96*std(data_temp(tube3(:)==1))/sqrt(sum(tube3(:)));

end

background_allmeans = [background_allmeans; mean_background];
tube1_allmeans = [tube1_allmeans; mean_tube1];
tube2_allmeans = [tube2_allmeans; mean_tube2];
tube3_allmeans = [tube3_allmeans; mean_tube3];

% normalize based on max

max_back = max(max(background_allmeans));
max_1 = max(max(tube1_allmeans));
max_2 = max(max(tube2_allmeans));
max_3 = max(max(tube3_allmeans));


norm_back = background_allmeans(1,:) / max_back;
norm1 = tube1_allmeans(1,:) / max_1;
norm2 = tube2_allmeans(1,:) / max_2;
norm3 = tube3_allmeans(1,:) / max_3;
allnorm_background = [allnorm_background; norm_back];
allnorm_tube1 = [allnorm_tube1; norm1];
allnorm_tube2 = [allnorm_tube2; norm2];
allnorm_tube3 = [allnorm_tube3; norm3];

%% Plot one Figure
Z = [1:59];

figure;
hold on
plot(wavelengths, mean_background, 'k', 'LineWidth', 1.5);
plot(wavelengths, mean_tube1, 'b','LineWidth', 1.5);
plot(wavelengths, mean_tube2, 'r','LineWidth', 1.5);
plot(wavelengths, mean_tube3, 'm','LineWidth', 1.5);
legend('Background', 'Liposomal J-Aggs','Free J-Aggs','Free IcG', 'Location', 'northwest')
grid on
xlabel('Wavelength (nm)');
ylabel('PA Intensity');
set(gca,'FontSize',14,'LineWidth',2)
title('Signal Intensity')
axis square;

figure;
hold on
plot(wavelengths, norm1, 'b','LineWidth', 1.5);
plot(wavelengths, norm2, 'r','LineWidth', 1.5);
plot(wavelengths, norm3, 'm','LineWidth', 1.5);
legend('Liposomal J-Aggs','Free J-Aggs','Free IcG', 'Location', 'southwest')
grid on
xlabel('Wavelength (nm)');
ylabel('PA Intensity');
set(gca,'FontSize',14,'LineWidth',2)
title('Normalized Signal Intensity')
axis square;

