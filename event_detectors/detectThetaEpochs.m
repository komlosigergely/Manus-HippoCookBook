
function [thetaEpochs] = detectThetaEpochs(varargin)
% Detect theta periods
% 
% INPUTS
% <optional>
% 'basepath'          Default pwd
% 'lfp'                 buzcode-formatted lfp structure (use bz_GetLFP)
%                           needs fields: lfp.data, lfp.timestamps, lfp.samplingRate.
%                           If empty or no exist, look for lfp in basePath folder
% 'saveSummary'         Default true
% 'saveMat'             Detault true
% 'force'               Default false
% 'bandpass'            Default [6 12]
% 'powerThreshold'      Default 1 SD
% 'channel'             Numeric [ex, 5]; by default calls
%                           getHippocampalLayers and uses oriens.
% 'updateSleepStates'  Default true
% 
% OUTPUT
% thetaEpochs         states structure with theta epochs intervals
%
% Manu Valero 2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse options
p = inputParser;
addParameter(p,'basepath',pwd,@isstruct);
addParameter(p,'lfp',[],@isstruct);
addParameter(p,'saveSummary',true,@islogical);
addParameter(p,'saveMat',true,@islogical);
addParameter(p,'force',false,@islogical);
addParameter(p,'bandpass',[6 12], @isnumeric);
addParameter(p,'powerThreshold',1, @isnumeric);
addParameter(p,'channel',[],@isnumeric);
addParameter(p,'plotting',true,@islogical);
addParameter(p,'updateSleepStates',true,@islogical);

parse(p,varargin{:})
basepath = p.Results.basepath;
lfp = p.Results.lfp;
saveMat = p.Results.saveMat;
saveSummary = p.Results.saveSummary;
force = p.Results.force;
theta_bandpass = p.Results.bandpass;
powerThresh = p.Results.powerThreshold;
channel = p.Results.channel;
plotting = p.Results.plotting;
updateSleepStates = p.Results.updateSleepStates;


% Deal with inputs
prevBasepath = pwd;
cd(basepath);

targetFile = dir('*.thetaEpochs.states.mat');
if ~isempty(targetFile) && ~force
    disp('Theta epochs already detected! Loading file.');
    load(targetFile.name);
    return
end

if isempty(channel)
    hippocampalLayers = getHippocampalLayers;
    channel = hippocampalLayers.bestShankLayers.slm;
end

% 
if isempty(lfp)
    lfpT = getLFP(channel,'noPrompts',true);
end
samplingRate = lfpT.samplingRate;
[wave,f,t,coh,wphases,raw,coi,scale,priod,scalef]=getWavelet(double(lfpT.data(:,1)),samplingRate,theta_bandpass(1),theta_bandpass(2),8,0);
[~,mIdx]=max(wave);%get index max power for each timepiont
pIdx=mIdx'+[0;size(f,2).*cumsum(ones(size(t,1)-1,1))];%converting to indices that will pick off single maxamp index from each of the freq-based phases at eacht timepoint
lfpphase=wphases(pIdx);%get phase of max amplitude wave at each timepoint
lfpphase = mod(lfpphase,2*pi);%covert to 0-2pi rather than -pi:pi
power = rms(abs(wave))';

% find high noise periods
M = movstd(double(lfpT.data),1 * lfpT.samplingRate);
sw_std.t = downsample(lfpT.timestamps,1250); 
sw_std.data = zscore(downsample(M,1250)); 
sw_std.ints = [sw_std.t sw_std.t+1];
        
intervals_below_threshold = sw_std.ints(find(sw_std.data<2),:);
clean_intervals = ConsolidateIntervals(intervals_below_threshold);
clean_samples = InIntervals(lfpT.timestamps, clean_intervals);
intervals = clean_intervals;

disp('finding intervals below power threshold...')
thresh = mean(power(clean_samples)) + std(power(clean_samples))*powerThresh;
minWidth = (samplingRate./theta_bandpass(2)) * 3; % set the minimum width to four cycles

below=find(power<thresh);
below_thresh = [];
if max(diff(diff(below))) == 0
    below_thresh = [below(1) below(end)];
elseif length(below)>0;
    ends=find(diff(below)~=1);
    ends(end+1)=length(below);
    ends=sort(ends);
    lengths=diff(ends);
    stops=below(ends)./samplingRate;
    starts=lengths./samplingRate;
    starts = [1; starts];
    below_thresh(:,2)=stops;
    below_thresh(:,1)=stops-starts;
else
    below_thresh=[];
end
% now merge interval sets from input and power threshold
intervals = SubtractIntervals(intervals,below_thresh);  % subtract out low power intervals

thetaEpochs.lfpphase = lfpphase;
thetaEpochs.samplingRate = samplingRate;
thetaEpochs.power = power;
thetaEpochs.timestamps = t;
thetaEpochs.intervals = intervals;
thetaEpochs.powerThresh = powerThresh;
thetaEpochs.bandpass = theta_bandpass;
thetaEpochs.channel = channel;

% try separating RUN and REM
try SleepState = SleepScoreMaster(pwd,'noPrompts',true);
    [thetaEpochs.idx.idx,thetaEpochs.idx.timestamps] = bz_INTtoIDX({thetaEpochs.intervals},'sf',1);
    thetaRun_times = intersect(SleepState.idx.timestamps(SleepState.idx.states == 1),...
        thetaEpochs.idx.timestamps(thetaEpochs.idx.idx)); % 1 is WAKE
    thetaEpochs.thetaRun.idx = zeros(size(1:length(SleepState.idx.timestamps)));
    thetaEpochs.thetaRun.timestamps = SleepState.idx.timestamps;
    thetaEpochs.thetaRun.idx(thetaRun_times) = 1;
    thetaEpochs.thetaRun.ints = IDXtoINT(thetaEpochs.thetaRun.idx,thetaEpochs.thetaRun.timestamps);
    
    thetaEpochs.thetaREM.timestamps = SleepState.idx.timestamps;
    thetaEpochs.thetaREM.idx = double(SleepState.idx.states==5);
    thetaEpochs.thetaREM.ints = SleepState.ints.REMstate;
catch 
    warning('Separating Run and REM was not possible!');
end

if updateSleepStates
    load([basenameFromBasepath(pwd) '.SleepState.states.mat'])
    keyboard;
%     SleepState.ints.
%     thetaEpochs.thetaRun.idx
%     SleepState.detectorinfo
%     SleepState.ints.WAKEtheta2 = thetaEpochs.thetaRun
end

if saveMat
    disp('Saving...');
    filename = split(pwd,filesep); filename = filename{end};
    save([filename '.thetaEpochs.states.mat'],'thetaEpochs');
end

if plotting
    params.Fs = lfpT.samplingRate; params.fpass = [2 120]; params.tapers = [3 5]; params.pad = 1;
    [S,t,f] = mtspecgramc_fast(single(lfpT.data),[2 1],params); S(S==0) = NaN;
    S = log10(S); % in Db
    S_det= bsxfun(@minus,S,polyval(polyfit(f,nanmean(S,1),2),f)); % detrending

    figure;
    subplot(3,3,[1 2])
    imagesc(t,f,S_det',[-1.5 1.5]);
    set(gca,'TickDir','out'); ylabel('Freq [Hz]'); xlabel('Time [s]');

    subplot(3,3,[4 5])
    t_theta = sum(diff(thetaEpochs.intervals')) * diff(t);
    imagesc([0 t_theta],f,S_det(InIntervals(t,thetaEpochs.intervals),:)',[-1.5 1.5]);
    set(gca,'TickDir','out'); ylabel('Theta epochs [Freq, Hz]');
    colormap jet

    subplot(3,3,[7 8])
    imagesc([0 t_theta],f,S_det(~InIntervals(t,thetaEpochs.intervals),:)',[-1.5 1.5]);
    set(gca,'TickDir','out'); ylabel('Non-Theta epochs [Freq, Hz]');
    colormap jet
    
    subplot(2,3,[3 6])
    plotFill(f,S_det,'color', [.8 .8 .8],'lineStyle', '--'); xlim([1 30]);
    plotFill(f,S_det(InIntervals(t,thetaEpochs.intervals),:),'color', [.8 .2 .2],'lineStyle', '-'); xlim([1 30]);
    ax = axis;
    fill([theta_bandpass flip(theta_bandpass)],[ax([3 3 4 4])],[.8 .5 .5],'EdgeColor','none','FaceAlpha',.1);
    ylabel('Full recording [Freq, Hz]'); xlabel('Freq [Hz]');   
    
    if saveSummary
        mkdir('SummaryFigures'); % create folder
        saveas(gcf,'SummaryFigures\thetaEpochs.png');
    end
end


cd(prevBasepath);
end