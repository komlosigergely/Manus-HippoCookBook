

%% look at some ripples by eye and check their normalized square signal 
good_ripple_timestamps = [19230.632,19230.682; 
    19239.418,19239.528;
    22608.438,22608.538; 
    22614.282,22614.372;
    24368.016,24368.078;
    11678.133,11678.188;
    11666.209,11666.292;
    4566.262,4566.345;
    3041.180,3041.279];
good_index = InIntervals(timestamps,good_ripple_timestamps);

good_squareSignal = normalizedSquaredSignal(good_index);



peak_good_squareSignal = zeros(length(good_ripple_timestamps),1);
min_good_suqareSignal = zeros(length(good_ripple_timestamps),1);

for rr = 1:length(good_ripple_timestamps)
    good_index = InIntervals(timestamps,good_ripple_timestamps(rr,:));
    good_squareSignal_n = normalizedSquaredSignal(good_index);

    peak_good_squareSignal(rr) = max(good_squareSignal_n);
    min_good_suqareSignal(rr) = min(good_squareSignal_n);
end

%%
figure; 
histogram(good_squareSignal);
title('goodRipples')




%% save for Neuroscope2
goodRipples = {};
% for i=1:length(digitalChannels)
%   eval(sprintf('digitalIn%d = {}', i))
% end
num_events = length(good_ripple_timestamps);

for cc = 1: length(good_ripple_timestamps)
%     goodRipples.timestamps = zeros(num_events,2);
    goodRipples.timestamps(cc,:) = good_ripple_timestamps(cc,:);
    goodRipples.timestamps(cc,:) = good_ripple_timestamps(cc,:);
   
    goodRipples.duration = good_ripple_timestamps(2,:)-good_ripple_timestamps(1,:);
    %goodRipples.eventIDlabels = digitalChannels(cc); % label represent the digital in channel number
    %save([basepath,'\', basename, '.digitalIn',num2str(cc),'.events.mat'], ['digitalIn',num2str(cc)]);

end
goodRipples.eventID = 1:num_events;
save([basepath,'\', basename, '.goodRipples','.events.mat'], 'goodRipples');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
figure; histogram(normalizedSquaredSignal);
xlim([-0.1 0.4]);
xlabel('normalized Squre signal');
ylabel('count')
saveas(gcf,[basepath,'\SummaryFigures\ripplePowerDist.fig'])



%% plot distribution of normalizedSquareSignal 
figure; histogram(normalizedSquaredSignal);
xlim([-0.5 2]);
xlabel('normalized Squre signal');
ylabel('count')
saveas(gcf,[basepath,'\SummaryFigures\ripplePowerDist.fig'])



figure; histogram(normalizedSquaredSignal_new);
xlim([-0.5 2]);
xlabel('normalized Squre signal');
ylabel('count')
%saveas(gcf,[basepath,'\SummaryFigures\ripplePowerDist.fig'])


%%
figure; histogram(squaredSignal);
%xlim([0 9*10^4]);
xlabel(' Square signal');
ylabel('count')
title(basename)



%% save to visualize in Neuroscope2 after find fripples
findRipples('passband',[120 200],'SWpassband',[2 10],'EMGThresh',1,'thresholds',[0.13 0.5],'duration', [30 100]);


%% save for Neuroscope2
basename = basenameFromBasepath(basepath)
findRipples = {};
% for i=1:length(digitalChannels)
%   eval(sprintf('digitalIn%d = {}', i))
% end
num_events = length(ripples.timestamps);

%     goodRipples.timestamps = zeros(num_events,2);
findRipples.timestamps = ripples.timestamps;

findRipples.duration = ripples.timestamps(:,2)-ripples.timestamps(:,1);

findRipples.eventID = 1:num_events;
save([basepath,'\', basename, '.findRipples','.events.mat'], 'findRipples');
