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

addParameter(p,'basepath',pwd,@isdir);
addParameter(p,'spikes',[],@isstruct);
addParameter(p,'numRep',500,@isnumeric);
addParameter(p,'binSize',0.001,@isnumeric);
addParameter(p,'winSize',1,@isnumeric);
addParameter(p,'rasterPlot',true,@islogical);
addParameter(p,'ratePlot',true,@islogical);
addParameter(p,'winSizePlot',[-.1 .5],@islogical);
addParameter(p,'saveMat',true,@islogical);
addParameter(p,'force',false,@islogical);

parse(p, varargin{:});

basepath = p.Results.basepath;
spikes = p.Results.spikes;
numRep = p.Results.numRep;
binSize = p.Results.binSize;
winSize = p.Results.winSize;
rasterPlot = p.Results.rasterPlot;
ratePlot = p.Results.rasterPlot;
winSizePlot = p.Results.winSizePlot;
saveMat = p.Results.saveMat;
force = p.Results.force;

%% Session Template
session = sessionTemplate(basepath,'showGUI',false);

%% Spikes
if isempty(spikes)
    spikes = loadSpikes();
end

%% Get cell response
psth = [];
% We can implement different conditions (if timestamps : mxn instead mx1)
disp('Computing responses...');
for i = 1:length(spikes.UID)
    fprintf(' **Pulses from unit %3.i/ %3.i \n',ii, size(spikes.UID,2));
    
end
end

