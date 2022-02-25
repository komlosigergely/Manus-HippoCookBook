function [psth] = spikesPsth(timestamps,varargin)
% Computes Psth for timestamps entered as inputs.
% USAGE
%   [psth] = spikesPsth(timestamps,<options>)
%
% INPUTS
%   timestamps - mx1 matrix indicating timetamps (in seconds) over which to
%                   compute psth
%   
% <OPTIONALS>
%   basepath - default pwd
%   spikes - buzcode spikes structure
%   numRep - For bootstraping, default 500. If 0, no bootstraping
%   binSize - In seconds, default 0.001 (1 ms)
%   winSize - In seconds, default 0.5 (500 ms)
%   rasterPlot - Default true
%   ratePlot - Default true
%   saveMat - default true
%
% OUTPUTS
%   psth - struct
%
% Developed by Pablo Abad and Manuel Valero 2022.
%% Defaults and Params
p = inputParser;

addRequired(p,'timestamps',@isnumeric);
addParameter(p,'basepath',pwd,@isdir);
addParameter(p,'spikes',[],@isstruct);
addParameter(p,'numRep',500,@isnumeric);
addParameter(p,'binSize',0.001,@isnumeric);
addParameter(p,'winSize',1,@isnumeric);
addParameter(p,'rasterPlot',true,@islogical);
addParameter(p,'ratePlot',true,@islogical);
addParameter(p,'winSizePlot',[-.1 .5],@islogical);
addParameter(p,'saveMat',false,@islogical);
addParameter(p,'savePlot',false,@islogical);
addParameter(p,'force',false,@islogical);

parse(p, timestamps,varargin{:});

basepath = p.Results.basepath;
spikes = p.Results.spikes;
numRep = p.Results.numRep;
binSize = p.Results.binSize;
winSize = p.Results.winSize;
rasterPlot = p.Results.rasterPlot;
ratePlot = p.Results.rasterPlot;
winSizePlot = p.Results.winSizePlot;
saveMat = p.Results.saveMat;
savePlot = p.Results.savePlot;
force = p.Results.force;

%% Session Template
session = sessionTemplate(basepath,'showGUI',false);

%% Spikes
if isempty(spikes)
    spikes = loadSpikes();
end

%% Get cell response
psth = [];
timestamps_recording = timestamps(1):1/1250:timestamps(end);
nConditions = size(timestamps,2);
% We can implement different conditions (if timestamps : mxn instead mx1)
% TO DO ??
disp('Generating bootstrap template...');
nEvents = int32(size(timestamps,1));
randomEvents = [];
for i = 1:numRep
    randomEvents{i} = sort(randsample(timestamps_recording,nEvents))';
end

disp('Computing responses...');
for ii = 1:length(spikes.UID)
    fprintf(' **Pulses from unit %3.i/ %3.i \n',ii, size(spikes.UID,2));
    if numRep > 0
        [stccg, t] = CCG([spikes.times{ii} randomEvents],[],'binSize',binSize,'duration',winSize,'norm','rate');
        for jj = 1:nConditions
%             t_duringPulse = t > 0 & t < conditions(jj,1);
            t_duringPulse = t > 0 & t < 0.1;
            randomRatesDuringPulse = nanmean(stccg(t_duringPulse,2:size(randomEvents,2)+1,1),1);
            psth.bootsTrapRate(ii,jj) = mean(randomRatesDuringPulse);
            psth.bootsTrapRateStd(ii,jj) = std(randomRatesDuringPulse);
            pd = fitdist(randomRatesDuringPulse','normal');
            psth.bootsTrapCI(ii,jj,:) = pd.icdf([.001 0.999]);
        end
    else
        psth.bootsTrapRate(ii,1:nConditions) = NaN;
        psth.bootsTrapRateStd(ii,1:nConditions) = NaN;
        psth.bootsTrapCI(ii,1:nConditions,:) = nan(nConditions,2);
    end
    for jj = 1:nConditions
        nPulses = length(timestamps);
        if nPulses > 100
            [stccg, t] = CCG({spikes.times{ii}, timestamps},[],'binSize',binSize,'duration',winSize,'norm','rate');
            psth.responsecurve(ii,jj,:) = stccg(:,2,1);
            psth.responsecurveSmooth(ii,jj,:) = smooth(stccg(:,2,1));
            t_duringPulse = t > 0 & t < 0.1; 
            t_beforePulse = t > -0.1 & t < 0; 
            psth.responsecurveZ(ii,jj,:) = (stccg(:,2,1) - mean(stccg(t < 0,2,1)))/std(stccg(t < 0,2,1));
            psth.responsecurveZSmooth(ii,jj,:) = smooth((stccg(:,2,1) - mean(stccg(t < 0,2,1)))/std(stccg(t < 0,2,1)));
            psth.rateDuringPulse(ii,jj,1) = mean(stccg(t_duringPulse,2,1));
            psth.rateBeforePulse(ii,jj,1) = mean(stccg(t_beforePulse,2,1));
            psth.rateZDuringPulse(ii,jj,1) = mean(squeeze(psth.responsecurveZ(ii,jj,t_duringPulse)));
            [h, psth.modulationSignificanceLevel(ii,jj,1)] = kstest2(stccg(t_duringPulse,2,1),stccg(t_beforePulse,2,1));
            ci = squeeze(psth.bootsTrapCI(ii,jj,:));
            
            % Boostrap test
            if psth.rateDuringPulse(ii,jj,1) > ci(2)
                test = 1;
            elseif psth.rateDuringPulse(ii,jj,1) < ci(1)
                test = -1;
            else
                test = 0;
            end
            psth.bootsTrapTest(ii,jj,1) = test;
            
            % z-score change test
            if mean(psth.responsecurveZ(ii,jj,t_duringPulse)) > 1.96
                test = 1;
            elseif mean(psth.responsecurveZ(ii,jj,t_duringPulse)) < -1.96
                test = -1;
            else
                test = 0;
            end
            psth.zscoreTest(ii,jj,1) = test;
            
            % 3 ways test. If not boostrap, it would be 2 ways.
            if (psth.rateDuringPulse(ii,jj,1) > ci(2) || isnan(ci(2))) && psth.modulationSignificanceLevel(ii,jj,1)<0.01...
                    && mean(psth.responsecurveZ(ii,jj,t_duringPulse)) > 1.96
                test = 1;
            elseif (psth.rateDuringPulse(ii,jj,1) < ci(1) || isnan(ci(1))) && psth.modulationSignificanceLevel(ii,jj,1)<0.01 ...
                    && mean(psth.responsecurveZ(ii,jj,t_duringPulse)) < -1.96
                test = -1;
            else
                test = 0;
            end
            psth.threeWaysTest(ii,jj,1) = test;
        else
            psth.responsecurve(ii,jj,:) = nan(duration/binSize + 1,1);
            psth.responsecurveZ(ii,jj,:) = nan(duration/binSize + 1,1);
            psth.modulationSignificanceLevel(ii,jj,1) = NaN;
            psth.rateDuringPulse(ii,jj,1) = NaN;
            psth.rateBeforePulse(ii,jj,1) = NaN;
            psth.rateZDuringPulse(ii,jj,1) = NaN;
            psth.bootsTrapTest(ii,jj,1) = NaN;
            psth.zscoreTest(ii,jj,1) = NaN;
            psth.threeWaysTest(ii,jj,1) = NaN;
        end
    end
    psth.timestamps = t;
end

% Some metrics reponses
responseMetrics = [];
t = psth.timestamps;
for ii = 1:length(spikes.UID)
    for jj = 1:nConditions
        t_duringPulse = t > 0 & t < 0.1; 
        responseMetrics.maxResponse(ii,jj) = max(squeeze(psth.responsecurve(ii,jj,t_duringPulse)));
        responseMetrics.minResponse(ii,jj) = min(squeeze(psth.responsecurve(ii,jj,t_duringPulse)));
        responseMetrics.maxResponseZ(ii,jj) = max(squeeze(psth.responsecurveZ(ii,jj,t_duringPulse)));
        responseMetrics.minResponseZ(ii,jj) = min(squeeze(psth.responsecurveZ(ii,jj,t_duringPulse)));
        
        responseCurveZ = squeeze(psth.responsecurveZSmooth(ii,jj,:));
        responseCurveZ(t<0) = 0;
        
        targetSD = -2;
        temp = [t(find(diff(responseCurveZ<targetSD) == 1)+1); NaN]; responseMetrics.latencyNeg2SD(ii,jj) = temp(1);
        temp = [t(find(diff(responseCurveZ<targetSD) == -1)+1); NaN]; responseMetrics.recoveryNeg2SD(ii,jj) = temp(1) - 0.1;
        responseMetrics.responseDurationNeg2SD(ii,jj) = temp(1) - responseMetrics.latencyNeg2SD(ii,jj);
        
        targetSD = -1.5;
        temp = [t(find(diff(responseCurveZ<targetSD) == 1)+1); NaN]; responseMetrics.latencyNeg1_5SD(ii,jj) = temp(1);
        temp = [t(find(diff(responseCurveZ<targetSD) == -1)+1); NaN]; responseMetrics.recoveryNeg1_5SD(ii,jj) = temp(1) - 0.1;
        responseMetrics.responseDurationNeg1_5SD(ii,jj) = temp(1) - responseMetrics.latencyNeg1_5SD(ii,jj);
        
        targetSD = -1;
        temp = [t(find(diff(responseCurveZ<targetSD) == 1)+1); NaN]; responseMetrics.latencyNeg1SD(ii,jj) = temp(1);
        temp = [t(find(diff(responseCurveZ<targetSD) == -1)+1); NaN]; responseMetrics.recoveryNeg1SD(ii,jj) = temp(1) - 0.1;
        responseMetrics.responseDurationNeg1SD(ii,jj) = temp(1) - responseMetrics.latencyNeg1SD(ii,jj);
        
        targetSD = -.5;
        temp = [t(find(diff(responseCurveZ<targetSD) == 1)+1); NaN]; responseMetrics.latencyNeg_5SD(ii,jj) = temp(1);
        temp = [t(find(diff(responseCurveZ<targetSD) == -1)+1); NaN]; responseMetrics.recoveryNeg_5SD(ii,jj) = temp(1) - 0.1;
        responseMetrics.responseDurationNeg_5SD(ii,jj) = temp(1) - responseMetrics.latencyNeg_5SD(ii,jj);
    end
end

psth.responseMetrics = responseMetrics;

if saveMat
    disp('Saving results...');
    save([session.general.name '.psth.cellinfo.mat'],'psth');
end

% PLOTS
% 1. Rasters plot
if rasterPlot
    t = psth.timestamps;
    st = timestamps;
    if length(st) > 5000 % if more than 5000
        st = randsample(st, 5000);
        st = sort(st);
    end
    disp('   Plotting spikes raster and psth...');
    % [stccg, t] = CCG([spikes.times st],[],'binSize',0.005,'duration',1);
    figure;
    set(gcf,'Position',[200 -500 2500 1200]);
    for jj = 1:size(spikes.UID,2)
        fprintf(' **Pulses from unit %3.i/ %3.i \n',jj, size(spikes.UID,2)); %\n
        rast_x = []; rast_y = [];
        for kk = 1:length(st)
            temp_rast = spikes.times{jj} - st(kk);
            temp_rast = temp_rast(temp_rast>winSizePlot(1) & temp_rast<winSizePlot(2));
            rast_x = [rast_x temp_rast'];
            rast_y = [rast_y kk*ones(size(temp_rast))'];
        end

        % spikeResponse = [spikeResponse; zscore(squeeze(stccg(:,end,jj)))'];
        resp = squeeze(psth.responsecurveSmooth(jj,1,:));
        subplot(7,ceil(size(spikes.UID,2)/7),jj); % autocorrelogram
        plot(rast_x, rast_y,'.','MarkerSize',1)
        hold on
        plot(t(t>winSizePlot(1) & t<winSizePlot(2)), resp(t>winSizePlot(1) & t<winSizePlot(2)) * kk/max(resp)/2,'k','LineWidth',2);
        xlim([winSizePlot(1) winSizePlot(2)]); ylim([0 kk]);
        title(num2str(jj),'FontWeight','normal','FontSize',10);

        if jj == 1
            ylabel('Trial');
        elseif jj == size(spikes.UID,2)
            xlabel('Time (s)');
        else
            set(gca,'YTick',[],'XTick',[]);
        end
    end
    if savePlot
        saveas(gcf,['SummaryFigures\spikesPsthRaster_ch',num2str(channels(ii)) ,'ch.png']); 
    end
end
% 2. Rate plot
if ratePlot
    t = psth.timestamps;
    figure
    for ii = 1:nConditions;
        subplot(nConditions,2,1 + ii * 2 - 2)
        imagesc([t(1) t(end)],[1 size(psth.responsecurve,1)],...
            squeeze(psth.responsecurveSmooth(:,ii,:))); caxis([0 10]); colormap(jet);
        set(gca,'TickDir','out'); xlim([winSizePlot(1) winSizePlot(2)]);
        if ii == 1
            title('Rate [0 to 10 Hz]','FontWeight','normal','FontSize',10);
            ylabel('Cells');
        end
        if ii == nConditions
            xlabel('Time');
        else
            set(gca,'XTick',[]);
        end

        subplot(nConditions,2,2 + ii * 2 - 2)
        imagesc([t(1) t(end)],[1 size(psth.responsecurve,1)],...
            squeeze(psth.responsecurveZSmooth(:,ii,:))); caxis([-3 3]); colormap(jet);
        set(gca,'TickDir','out'); xlim([winSizePlot(1) winSizePlot(2)]);
        if ii == 1
           title('Z Rate [-3 to 3 SD]','FontWeight','normal','FontSize',10);
           ylabel('Cells');
        end
        if ii == nConditions
            xlabel('Time');
        else
            set(gca,'XTick',[]);
        end
    end
end          
if savePlot
    saveas(gcf,['SummaryFigures\spikesPsthRate.png']); 
end

end
