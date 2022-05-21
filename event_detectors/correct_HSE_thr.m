figure; histogram(spkhist);
title(basename);
xlabel('zscore FR');
ylabel('count');
saveas(gcf,[basepath,'\rippleHSE\','rippleHSE.png'])


figure;
histogram(evtpeak);
xlabel('event peak');
ylabel('count');
title(basename);
saveas(gcf,[basepath,'\rippleHSE\','rippleHSE_peak.png']);