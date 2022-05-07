function createnet

global W X NOTES
evalin('base','global W X NOTES');

%% NOTES
% W = Network weights
%   dim1 = presynaptic neuron
%   dim2 = postsynaptic neuron
% X = Network activity
%   1 element = 10 ms
% NOTES = Network parameters stored in "NOTES"

%% Key parameters for RRN
n=30^2;  %network size (must be perfect square)
p=0.1;   %connectivity (0.2 default)
g=2.5;   %synaptic strength (1.5 default)
l=2;     %constant for degree of spatial organization
ns=0; %noise
nwords=2;%number of stims
nletters=9; %number of components for stims

%% Network structure
%double feedforward RRN
%size
NOTES.netsize = [nwords n nletters n 2];
%connectivity
NOTES.sparsity(1,:)  =  [0 1 0 0 0];  %1>2
NOTES.sparsity(2,:)  =  [0 p 1 0 0];  %2>2 & 2>3
NOTES.sparsity(3,:)  =  [0 0 0 1 0];  %3>4
NOTES.sparsity(4,:)  =  [0 0 0 p 1];  %4>4 & 4>5
NOTES.sparsity(5,:)  =  [0 0 0 0 0];  %5>none
%input strength
g1=g*5; 
%RRN strength
g2=g/sqrt(p*n); 
%output1 strength
g3=1/sqrt(n);
%weight scaling factors for each layer > layer connection
NOTES.strength(1,:)  =  [0 g1 0  0  0];  %1>2
NOTES.strength(2,:)  =  [0 g2 g3/10 0  0];  %2>2 & 2>3
NOTES.strength(3,:)  =  [0 0  0  g1 0];  %3>4
NOTES.strength(4,:)  =  [0 0  0  g2 g3]; %4>4 & 4>5
NOTES.strength(5,:)  =  [0 0  0  0  0];  %5>none

%miscellaneous
NOTES.rrn = NOTES.netsize==n;
NOTES.imdisplay  = [sqrt(n) sqrt(n)];

%% Create network
%cycle through presynaptic layers
for i=1:length(NOTES.netsize)
    %cycle through postsynaptic layers
    for j=1:length(NOTES.netsize)
        sz=[NOTES.netsize(i),NOTES.netsize(j)];
        sparsity=NOTES.sparsity(i,j);
        strength=NOTES.strength(i,j);
        W{i,j} = netweights(sz,sparsity,strength,l);
    end
    W{i,i}(logical(eye(size(W{i,i})))) = 0; %remove self-synapses
end
% %patch to adjust layer 3 weights to match presyn inputs
% W{3,3}=W{3,3}.*NOTES.netsize(2);

%% Network dynamics
%firing rate model
NOTES.tau = 10.0;			% time constant of temporal integration
NOTES.dt = 1;               % time units (1 element = 1 ms)
NOTES.noise = ns;           % amplitude of noise
%transfer functions (z*(z>0) makes all positive)
NOTES.activationfx{1} = @(z) z>0.9;             % threshold and boom (anything below 0.9 =0, everything above =1)
NOTES.activationfx{2} = @(z) tanh(z);
NOTES.activationfx{3} = @(z) z;                 %need activity to be linear-ish for learning
NOTES.activationfx{4} = @(z) tanh(z);
NOTES.activationfx{5} = @(z) z;                 %need activity to be linear-ish for learning     
%run time parameters
NOTES.ntrials = 5;      % number of trials
NOTES.runtime = 1.5e3;    % duration of each trial
NOTES.plotskip = 5;
NOTES.plotdelay = 0;
%preallocate activity data
for i=1:length(NOTES.netsize)
    X{i}=zeros(NOTES.netsize(i),NOTES.runtime,NOTES.ntrials);
end

%% Training
%flags
NOTES.train(1:3)=false;
NOTES.teacher=true;
%proportion of plastic units
NOTES.plasticity = [0 0.6 1 0 1];  %no innate trajectory training for RRN#2
NOTES.traininterval = 10;
NOTES.alpha = 1;
%variables for training RRN#1 (innate trajectory)
NOTES.punits = 1:round(NOTES.plasticity(2)*NOTES.netsize(2));
for i = NOTES.punits
    NOTES.prepunits{i} = find(W{2,2}(:,NOTES.punits(i)));
    %preallocate P matrix (variable learning rates for each unit)
    NOTES.P1{i} = eye(length(NOTES.prepunits{i}));
end
%variables for training output neurons
for i = 1:NOTES.netsize(3)
    NOTES.P2{i} = eye(NOTES.netsize(2));
end
for i = 1:NOTES.netsize(5)
    NOTES.P3{i} = eye(NOTES.netsize(4));
end
%target outputs
%target1 (innate trajectory)
NOTES.target1{i}=[]; %get from sim
%target2 (letter sequences)
NOTES.letters = {'m' 'o' 'u' 's' 'e' 'r' 'h' 'a' 'b'};
mouse=1:5;
rehab=[6 5 7 8 9];
NOTES.target2{1}=zeros(NOTES.netsize(3),1.5e3);
NOTES.target2{2}=zeros(NOTES.netsize(3),1.5e3);
for j=1:5
    pk=(j-1)*250+100;
    bell=normpdf(1:NOTES.runtime,pk,10);
    %"mouse"
    k=mouse(j);    
    NOTES.target2{1}(k,:)=convertrange(bell,[0 1]);
    %"rehab"
    k=rehab(j);
    NOTES.target2{2}(k,:)=convertrange(bell,[0 1]);
end
for i=1:nletters
    %target3 (handwriting)
    NOTES.target3{i}=[]; %get from user
end
%current stim
NOTES.CurrentWord=1;
NOTES.CurrentLetter=1;

%% Miscellaneous
%save gif of running figure
NOTES.gif=false;
%stroke parts of network
for i=1:5
    NOTES.stroke{i}=false(1,NOTES.netsize(i));
end
%watch unit of network over time
NOTES.watch=[2 1]; %network 2, unit 1
