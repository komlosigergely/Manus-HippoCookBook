%% BatchScript_analysis_example
% place your code to run an analysis across all sessions for a given
% project

clear; close all
targetProject= 'All';

HCB_directory = what('HippoCookBook'); 

sessionsTable = readtable([HCB_directory.path filesep 'indexedSessions.csv']); % the variable is called allSessions

for ii = 1:length(sessionsTable.SessionName)
    if strcmpi(sessionsTable.Project{ii}, targetProject) || strcmpi('all', targetProject)
        fprintf(' > %3.i/%3.i session \n',ii, length(sessionsTable.SessionName)); %\n
        cd([database_path filesep sessionsTable.Path{ii}]);
        try

            %%% your code goes here...
            clear session brainRegions
            session = loadSession;
            fn = fieldnames(session.brainRegions);
            brainRegions = cell(0);
            for jj = 1:length(fn)
                brainRegions{1,length(brainRegions)+1} = fn{jj};
                brainRegions{1,length(brainRegions)+1} = ' ';
            end    
            brainRegions(end) = [];
            
            sessionsTable.brainRegions{ii} = [brainRegions{:}];
            
            %%%
            
            close all;
        catch
            warning('Analysis was not possible!');
        end
    end
end