%% sessionBatchScript

%1% Transfer files and organize session's folder
updateExpFolder({'V:\data\fCck1'},'E:\data\fCck1');

%2%  Preprocessing
preprocessSession('basepath','E:\data\fCck1\fCck1_220210_sess9','analogCh',1);
preprocessSession('basepath','E:\data\fCck1\fCck1_220211_sess10','analogCh',1);
preprocessSession('basepath','E:\data\fCck1\fCck1_220214_sess11','analogCh',1);

preprocessSession('basepath','D:\Dropbox\DATA\sharedRecordings\NewXmlAnimal\190222\rec1_220219_sess1');
computeSessionSummary('basepath','D:\Dropbox\DATA\sharedRecordings\NewXmlAnimal\190222\rec1_220219_sess1','getWaveformsFromDat',true);

%3% compute summary
 
%% others
editDatFile(pwd,[0.001 1],'option','zeroes');   % remove zeroes
