function createtarget(target)

global NOTES

t=target;

%duration of target (ms)
l=200;

%have user draw target
M=draw;

%resample to make exactly 1 sec long
sr=length(M)/l;
M=M(:,round(1:sr:end));

%clean up
M(isnan(M))=0.1; %remove NaNs

%save in NOTES
NOTES.target3{t}(:,1:length(M))=M;
    
    
    
    
