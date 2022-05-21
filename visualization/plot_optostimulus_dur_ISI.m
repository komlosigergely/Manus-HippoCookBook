
function plot_optostimulus_dur_ISI(varargin)
p = inputParser;
addParameter(p,'basepath',pwd);


parse(p,varargin{:});
basepath = p.Results.basepath;


% durations = [0.005, 0.01,0.02,0.05,0.1,0.2,0.3,0.5,0.8]
% ms_inds = {};
% ms_num = zeros(length(durations),1);
% for dd = 1:length(durations)
% 
%     ms_5 = find(abs(optoPulses.duration-durations(dd))<0.005);
%     
%     
%     ms_ind = optoPulses.duration(ms_5);
%     ms_num(dd) = length(ms_ind);
%     ms_inds{dd} = ms_ind;
%     unique(optoPulses.duration(ms_5))
%     
%     %channel_block = intersect(find(optoPulses.digitalChannelsListannel==1), find(optoPulses.duration==0.05));
% 
% end
%%
basename = basenameFromBasepath(basepath);
load([basepath,'\',basename,'.session.mat']);
load([basepath,'\',basename,'.DigitalIn.events.mat'])
%%
digital_optogenetic_channels = session.analysisTags.digital_optogenetic_channels;
savefolder = [basepath,'\Pulses\'];
for cc = 1:length(digital_optogenetic_channels)
%     %% bar graph count stimulation of each duration
%     
%     figure; 
%     name = {'0.005','0.01','0.02','0.05','0.1','0.2','0.3','0.5','0.8'};
%     bar(ms_num)
%     set(gca,'xticklabel',name)
%     xlabel('duration')
%     ylabel('count')
    
    %% plot stimulus duration 
    
    %bb = find(diff(digitalIn.dur{1,1})>0.001)
    
    channel = digital_optogenetic_channels(cc);
    interval = digitalIn.timestampsOn{1,channel}(2:end) -digitalIn.timestampsOff{1,channel}(1:end-1);



    figure; 
    subplot(1,2,1)
    scatter(digitalIn.timestampsOn{1,channel},digitalIn.dur{1,channel}); hold on;
    %scatter(digitalIn.timestampsOn{1,channel}(2:end),interval,'*');

    ylim([0,0.8])
    ylabel('duration')
    xlabel('time')
    title(num2str(channel))
    %saveas(savefolder,'digitalIn_duration_',channel,'.pdf');
    
    %% plot inter stimulus interval
    
     subplot(1,2,2)
     scatter(digitalIn.timestampsOn{1,channel}(2:end),interval);
     ylim([0,5]);
     xlabel('time');
     ylabel('ISI');
     title(num2str(channel));
     saveas(gcf,[savefolder,'digitalIn_ISI_duration_',num2str(channel),'.pdf']);
end



