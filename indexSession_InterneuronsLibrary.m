function [] = indexSession_InterneuronsLibrary(varargin)

%       [] = indexSession_InterneuronsLibrary(varargin)

% This function runs all the preAnalysis needed for the Interneurons
% Project.
% Based on index_session_script_InterneuronsLibrary by MV 2020
% 1. Runs sessionTemplate
% 2. remove previous cellinfo.spikes.mat and computes spikes again (
%       manual clustered)
% 3. remove previous opto pulses file (pulses.events.mat) and re-runs opto
%       pulses analysis
% 4. Runs and Check SleepScore
% 5. Power Profiles
% 6. check UD events
% 7. Ripples analysis
% 8. Cell Metrics and CellExplorer
% 9. Spikes features
% 10. Saving index path

%% Pablo Abad 2022

%% Defaults and Params
p = inputParser;

addParameter(p,'basepath',pwd,@isdir);
addParameter(p,'theta_bandpass',[6 12], @isnumeric);
addParameter(p,'hfo_bandpass',[100 500], @isnumeric);
addParameter(p,'analogCh',64,@isnumeric); % 0-index
addParameter(p,'rejectChannels',[],@isnumeric); % 0-index

parse(p,varargin{:})

basepath = p.Results.basepath;
theta_bandpass = p.Results.theta_bandpass;
hfo_bandpass = p.Results.hfo_bandpass;
analogCh = p.Results.analogCh;
rejectChannels = p.Results.rejectChannels;


%% 1. Runs sessionTemplate
session = sessionTemplate(basepath,'showGUI',true);
% Parsing rejectChannels from session.mat file in case rejectChannels is empty
if isempty(rejectChannels)
    rejectChannels = session.channelTags.Bad.channels; % 1-index
end
% Creating a field in session.mat called channels (1-index)
session.channels = 1:session.extracellular.nChannels;
save([basepath filesep session.general.name,'.session.mat'],'session','-v7.3');

%% 2. Remove previous cellinfo.spikes.mat and computes spikes again (manual clustered)

if ~isempty(dir([basepath filesep session.general.name ,'.spikes.cellinfo.mat']))
    disp('Loading and deleting old spikes.cellinfo.mat file ...');
    file = dir([basepath filesep session.general.name ,'.spikes.cellinfo.mat']);
    delete(file.name);
else
    ('spikes.cellinfo.mat does not exist !');
end

disp('Loading Spikes...')
spikes = loadSpikes;


%% 3. Remove previous opto pulses file (pulses.events.mat) and re-runs opto

if ~isempty(dir([basepath filesep session.general.name ,'.pulses.events.mat']))
    disp('Loading and deleting old opto pulses.events.mat file ...')
    file = dir([basepath filesep session.general.name ,'.pulses.events.mat']);
    delete(file.name)
else
    disp('Opto pulses.events.mat does not exist !')
end

disp('Getting Opto Analog Pulses...')
pulses = bz_getAnalogPulses('analogCh',analogCh,'manualThr',false); % 0-index

%% 4. Check Sleep Score
% SleepScoreMaster(pwd,'noPrompts',true,'ignoretime',pulses.intsPeriods, 'overwrite', true,'rejectChannels',rejectChannels); % 0-index
% MODIFIED BY PABLO
SleepScoreMaster(pwd,'noPrompts',true,'ignoretime',pulses.intsPeriods, 'overwrite', true);
TheStateEditor;

%% 5. Power Profiles
% powerProfile_theta = bz_PowerSpectrumProfile(theta_bandpass,'showfig',true,'channels',[0:63],'forceDetect',true); % [0:63] 0-index
% powerProfile_HFOs = bz_PowerSpectrumProfile(hfo_bandpass,'showfig',true,'channels',0:63); % [0:63] 0-index

% Trying changes in bz_PowerSpectrumProfile_temp
% MODIFIED BY PABLO
powerProfile_theta = bz_PowerSpectrumProfile_temp(theta_bandpass,'showfig',true,'forceDetect',true);
powerProfile_hfo = bz_PowerSpectrumProfile_temp(hfo_bandpass,'showfig',true,'forceDetect',true);

%% 6. Check Brain Events
% Trying changes in detecUD_temp
% UDStates = detectUD('plotOpt', true,'forceDetect',true','NREMInts','all'); % ,'skipCluster',26,'spikeThreshold',.5,'deltaWaveThreshold',[],'ch',18);
UDStates = detectUD_temp('plotOpt', true,'forceDetect',true','NREMInts','all'); % ,'skipCluster',26,'spikeThreshold',.5,'deltaWaveThreshold',[],'ch',18);

%% 7. Ripple Master Detector (to be done)
rippleChannels = computeRippleChannel('discardShanks', 6);
rippleChannels.Ripple_Channel = 17; rippleChannels.Noise_Channel = 50; % I dont know if 0-index or 1-index (I think 0-index)
% ripples = bz_DetectSWR([rippleChannels.Ripple_Channel, rippleChannels.Sharpwave_Channel],'saveMat',true,'forceDetect',true,'useSPW',true,'thresSDrip',[.5 1.5]);
ripples = bz_FindRipples(pwd, rippleChannels.Ripple_Channel,'thresholds', [1 2], 'passband', [80 240],...
    'EMGThresh', 1, 'durations', [20 150],'saveMat',true,'noise',rippleChannels.Noise_Channel); % [.2 .4]
ripples = removeArtifactsFromEvents(ripples);
ripples = eventSpikingTreshold(ripples,[],'spikingThreshold',2); % .8
EventExplorer(pwd,ripples);
% spikes = loadSpikes;
% spkEventTimes = bz_getSpikesRank('events',ripples, 'spikes',spikes);
% [rankStats] = bz_RankOrder('spkEventTimes',spkEventTimes,'numRep',100);
% rippleChannels = computeRippleChannel('saveMat',false,'force',false);
% xml = LoadParameters;
% clear deepSup
% deepSup.channel = []; deepSup.reversalPosition = [];
% for ii = 1:size(xml.AnatGrps,2)
%     deepSup.channel = [deepSup.channel; xml.AnatGrps(ii).Channels'];
%     deepSup.reversalPosition = [deepSup.reversalPosition; rippleChannels.Deep_Sup{ii}];
% end
% [~,idx] = sort(deepSup.channel);
% deepSup.channel = deepSup.channel(idx);
% deepSup.reversalPosition = deepSup.reversalPosition(idx);
% deepSup.identity = deepSup.reversalPosition<1; % sup is 1, deep is 0, just like in the old times
% ripples.deepSup = deepSup;
targetFile = dir('*ripples.events*'); save(targetFile.name,'ripples');

%% 8. TO DO: Theta detection

%% 9. Cell metrics
cell_metrics = ProcessCellMetrics('session', session,'excludeMetrics',{'deepSuperficial'});
cell_metrics = CellExplorer('metrics',cell_metrics);

%% 10. Spike Features
spikeFeatures()
% pulses.analogChannel = analogCh;
% save([session.general.name,'.pulses.events.mat'],'pulses');
optogeneticResponses = getOptogeneticResponse('numRep',100);
end
