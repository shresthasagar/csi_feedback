clear all;close all;clc

%% Settings 
bs_ant = 32; % M= 64 BS Antennas
pilot_l = 8; % Pilots length is 8
snr  = 0; % SNR = 0 dB
num_subcarriers = 45;

%% Generate channel dataset H

%------Ray-tracing scenario
params.scenario='O1_3p5';                % The adopted ray tracing scenarios [check the available scenarios at www.aalkhateeb.net/DeepMIMO.html]


filename = [params.scenario,'_',num2str(bs_ant),'ant_',num2str(num_subcarriers),'subcarriers_'];


%------parameters set
%Active base stations 
params.active_BS=18;          % Includes the numbers of the active BSs (values from 1-18 for 'O1')

% Active users
params.active_user_first=1;       % The first row of the considered receivers section (check the scenario description for the receiver row map)
params.active_user_last=11;        % The last row of the considered receivers section (check the scenario description for the receiver row map)

% Number of BS Antenna 
params.num_ant_x=1;                  % Number of the UPA antenna array on the x-axis 
params.num_ant_y=1;                 % Number of the UPA antenna array on the y-axis 
params.num_ant_z=32;                  % Number of the UPA antenna array on the z-axis
                                     % Note: The axes of the antennas match the axes of the ray-tracing scenario
                              
% Antenna spacing
params.ant_spacing=.5;               % ratio of the wavelnegth; for half wavelength enter .5        

% System bandwidth
params.bandwidth=0.01;                % The bandiwdth in GHz 

% OFDM parameters
params.num_OFDM=num_subcarriers;                % Number of OFDM subcarriers
params.OFDM_sampling_factor=1;   % The constructed channels will be calculated only at the sampled subcarriers (to reduce the size of the dataset)
params.OFDM_limit=params.num_OFDM;                % Only the first params.OFDM_limit subcarriers will be considered when constructing the channels

% Number of paths
params.num_paths=10;                  % Maximum number of paths to be considered (a value between 1 and 25), e.g., choose 1 if you are only interested in the strongest path

params.saveDataset=0;
 
% -------------------------- Dataset Generation -----------------%
[DeepMIMO_dataset,params]=DeepMIMO_generator(params); % Get H (i.e.,DeepMIMO_dataset )

%% Genrate Quantized Siganl Y with Noise
channels = zeros(length(DeepMIMO_dataset{1}.user),bs_ant,num_subcarriers);

%% Stack the real and imaginary parts of the two channels
channels_stacked = zeros(length(DeepMIMO_dataset{1}.user),2,bs_ant,num_subcarriers);

for i = 1:length(DeepMIMO_dataset{1}.user)
    channels(i,:,:) = normalize(DeepMIMO_dataset{1}.user{i}.channel,'scale');%%
end

%% Convert complex data to two-channel data
channels_stacked(:,1,:,:) = real(channels); % real part of Y
channels_stacked(:,2,:,:) = imag(channels); % imag papt of Y

% Shuffle data 
shuff = randi([1,length(DeepMIMO_dataset{1}.user)],length(DeepMIMO_dataset{1}.user),1);
channels_stacked = channels_stacked(shuff,:,:,:);

%% Split data for training
numOfSamples = length(DeepMIMO_dataset{1}.user);
trRatio = 0.7;
numTrSamples = floor( trRatio*numOfSamples);
numValSamples = numOfSamples - numTrSamples;

channels_train = channels_stacked(1:numTrSamples,:,:,:);
channels_test = channels_stacked(numTrSamples+1:end,:,:,:);


%% Visualization of Y and H
figure
contourf(squeeze(channels_train(1,1,:,:)), 100,'linecolor', 'None');
title('Visualization of channel')

%% Save data
save(['Gan_Data/Gan_',filename],'channels_train', 'channels_test');



