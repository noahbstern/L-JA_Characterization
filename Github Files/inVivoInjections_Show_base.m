%% Code Intro
%{
Author: Noah Stern
email: noahbstern@utexas.edu
Based on information and base code files provided by FUJIFILM/visualsonics to work with VEVO F2 and LAZR-X systems 

This code allows for importing, doing calculations, and plotting data from
from in vivo injections of contrast agents. To run it also requires 
Bmode_Read.m, VsiParse_BmodeXml.m, Photostability_Read_Single_base.m, 
VsiParseVarargin.m, and VsiParseXml.m. Versions of this code are used to 
show signal changes when contrast agents have been injected and to 
determine general circulation times. 

%}


%% Open Raw PaMode

close all;
clear all;

baseDir = '.';  % Directory of the data
frameList = -1;  % Vector of frames (-1 to load all frames)
outputFilesFlag = false; % Set to true to save the reconstructed images for the dataset
modeName = '.pamode'; % File type extension

baseFilename_baseline_oxy = 'lip_study3_Oxyhemo N3 0hr-2022-12-14-14-03-15'; % Filename (without the file type extensions)
PaMode_baseline_oxy = Photostability_Read_Single_base(baseDir, baseFilename_baseline_oxy, frameList, modeName);

% add in more oxyhemo files for other time points 

baseFilename_baseline_multi_unmixed = 'lip_study3_Multi N3 0hr unmixed-2022-12-14-14-06-06'; % Filename (without the file type extensions)
PaMode_baseline_multi_unmixed = Photostability_Read_Single_base(baseDir, baseFilename_baseline_multi_unmixed, frameList, modeName);

% add in more multi files for other time points 

% add in bmode data for determining kidney bounds
modeName = '.bmode'; % File type extension
BMode_baseline = Bmode_Read(baseDir, baseFilename_baseline_oxy, frameList, modeName); 


%% Show all baseline (repeat this section for additional time points if desired)
row = size(PaMode_baseline_oxy.Width,2);
col = size(PaMode_baseline_oxy.Depth,2);

figure('Position',[100 300 550 425]);
imagesc(BMode_baseline.Width, BMode_baseline.Depth, BMode_baseline.Data{10});

figure;
temp_Oxy = PaMode_baseline_oxy.Data{10};
temp_HbT = PaMode_baseline_oxy.DataHbT{10};

% threshold slighlty to get a cleaner image to draw ROIs (not necessary)
for el = 1:(row*col)
    if temp_HbT(el) < 10000
        temp_Oxy(el) = 0;
    end
end
imagesc(PaMode_baseline_oxy.Width, PaMode_baseline_oxy.Depth, temp_Oxy);
ylabel('Depth (mm)')
xlabel('Width (mm)')
colormap(jet)
title('Draw ROI Bounds 1')
ROI_baseline1 = roipoly();
title('Draw ROI Bounds 2')
ROI_baseline2 = roipoly();
title('Draw ROI Bounds 3')
ROI_baseline3 = roipoly();

so2_list_baseline1 = [];
so2_list_baseline2 = [];
so2_list_baseline3 = [];

for i = 1:130;
temp_Oxy = PaMode_baseline_oxy.Data{i};
temp_HbT = PaMode_baseline_oxy.DataHbT{i};


% removes low blood areas if desired 
% for el = 1:(row*col)
%     if temp_HbT(el) < 10000
%         temp_Oxy(el) = 0;
%     end
% end

data_temp1 = temp_Oxy(ROI_baseline1==1);
data_temp2 = temp_Oxy(ROI_baseline2==1);
data_temp3 = temp_Oxy(ROI_baseline3==1);
count_1 = 0;
sum_1 = 0;

for j = 1:length(data_temp1)
    if data_temp1(j) > 0
        count_1=count_1+1;
        sum_1=sum_1+data_temp1(j);
    end
end

count_2 = 0;
sum_2 = 0;
for j = 1:length(data_temp2)
    if data_temp2(j) > 0
        count_2=count_2+1;
        sum_2=sum_2+data_temp2(j);
    end
end

count_3 = 0;
sum_3 = 0;
for j = 1:length(data_temp3)
    if data_temp3(j) > 0
        count_3=count_3+1;
        sum_3=sum_3+data_temp3(j);
    end
end

sO2_1 = sum_1/count_1;
so2_list_baseline1 = [so2_list_baseline1, sO2_1];

sO2_2 = sum_2/count_2;
so2_list_baseline2 = [so2_list_baseline2, sO2_2];

sO2_3 = sum_3/count_3;
so2_list_baseline3 = [so2_list_baseline3, sO2_3];

so2_list_baseline = (so2_list_baseline1 + so2_list_baseline2 + so2_list_baseline3)/3;



imagesc(PaMode_baseline_oxy.Width, PaMode_baseline_oxy.Depth, temp_Oxy);
% imagesc(PaMode_1.Width, PaMode_1.Depth, avg_signal, 'AlphaData', .8)
title(sprintf('Baseline Frame #%d', PaMode_baseline_oxy.FrameNum(i)));
xlabel('Width (mm)');
ylabel('Depth (mm)');
axis image
colormap(jet)
pause(.01)
end

close all


%% Mean and STDs Calculation
% repeat for other time points if desired
m_b = mean(so2_list_baseline);
s_b = std(so2_list_baseline);


close all

%% Plotting baseline vs post injection with moving average calculation

figure;
hold on
plot(1:130, so2_list_baseline, 'Color' ,[0 0 0])
title('Average sO2 in region')
ylim([40 100])

mean_base_moving = movmean(so2_list_baseline, 10);


figure;
hold on
plot(1:130, mean_base_moving,'Color' , [0 0 0])
title('Average sO2 in kidney running average')
ylim([40 100])



%% Seperate each in to Individual Image Stacks from multi original file

% 2 is oxy, 1 is deoxy, 0 is jagg

jagg_injection_baseline = {};
deoxy_injection_baseline = {};
oxy_injection_baseline = {};

% repeat with other files 


a = 1;
while a < 60
    if (PaMode_baseline_multi_unmixed.Wavelength(a) == 0)
        jagg_injection_baseline{end+1} = PaMode_baseline_multi_unmixed.Data{a};
        
    elseif (PaMode_baseline_multi_unmixed.Wavelength(a) == 1)
        deoxy_injection_baseline{end+1} = PaMode_baseline_multi_unmixed.Data{a};
        
    elseif (PaMode_baseline_multi_unmixed.Wavelength(a) == 2)
        oxy_injection_baseline{end+1} = PaMode_baseline_multi_unmixed.Data{a};
       
    else
end
a = a+1;
end

%% Tiled Layout Over Time from unmixed images multi average

jagg_baseline_mean = zeros(size(jagg_injection_baseline{1}));
deoxy_baseline_mean = zeros(size(jagg_injection_baseline{1}));
oxy_baseline_mean = zeros(size(jagg_injection_baseline{1}));

c = 1;

while c < 20
bj_temp = jagg_injection_baseline{c};
bd_temp = deoxy_injection_baseline{c};
bo_temp = oxy_injection_baseline{c};

jagg_baseline_mean = jagg_baseline_mean + bj_temp;
deoxy_baseline_mean = deoxy_baseline_mean + bd_temp;
oxy_baseline_mean = oxy_baseline_mean + bo_temp;

c = c+1;
end

jagg_baseline_mean = jagg_baseline_mean/20;
deoxy_baseline_mean = deoxy_baseline_mean/20;
oxy_baseline_mean = oxy_baseline_mean/20;

%% Seperating out oxy images using drawn ROIs

oxy_b_roi1 = PaMode_baseline_oxy.Data{10}.*ROI_baseline1;
size_b = nnz(oxy_b_roi1);

oxy_b_roi2 = PaMode_baseline_oxy.Data{10}.*ROI_baseline2;
size_b = nnz(oxy_b_roi2);

oxy_b_roi3 = PaMode_baseline_oxy.Data{10}.*ROI_baseline3;
size_b = nnz(oxy_b_roi3);

% Manual so2 average (already done above with low values removed)
% oxy_b = sum(sum(oxy_b_roi))/size_b

figure;
hold on
tlo = tiledlayout(1,1, 'TileSpacing','Compact');

h(1) = nexttile(tlo);
imagesc(h(1), oxy_b_roi1 + oxy_b_roi2 + oxy_b_roi3)
%axis square
title('Oxy Baseline')
set(gca,'xtick',[])
set(gca,'ytick',[])


set(h, 'Colormap', turbo, 'CLim', [0 100]);
set(tlo, 'TileSpacing', 'Compact');
% assign color bar to one tile 
cbh = colorbar(h(end)); 
% To position the colorbar as a global colorbar representing
% all tiles, 
cbh.Layout.Tile = 'east';
hold off


%% Seperating out multi images using drawn ROIs

jb_roi1 = jagg_baseline_mean.*ROI_baseline1; jb_roi2 = jagg_baseline_mean.*ROI_baseline2; jb_roi3 = jagg_baseline_mean.*ROI_baseline3;
size_b1 = nnz(jb_roi1); size_b2 = nnz(jb_roi2); size_b3 = nnz(jb_roi3);
jb_m1 = sum(sum(jb_roi1))/size_b1; jb_m2 = sum(sum(jb_roi2))/size_b2; jb_m3 = sum(sum(jb_roi3))/size_b3;
jb_m = (jb_m1 + jb_m2 + jb_m3) / 3
jb_s1 = std(std(jb_roi1)); jb_s2 = std(std(jb_roi2)); jb_s3 = std(std(jb_roi3));

figure;
hold on
tlo2 = tiledlayout(1,1);

m(1) = nexttile(tlo2);
imagesc(m(1), jb_roi1 + jb_roi2+ jb_roi3)
%axis square
title('J-Agg Baseline')
set(gca,'xtick',[])
set(gca,'ytick',[])


set(m, 'Colormap', jet, 'CLim', [0 150]);
% assign color bar to one tile 
cbh2 = colorbar(m(end)); 
% To position the colorbar as a global colorbar representing
% all tiles, 
cbh2.Layout.Tile = 'east';
set(tlo2, 'TileSpacing', 'Compact');
hold off
