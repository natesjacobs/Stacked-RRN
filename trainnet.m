function trainnet(type)

global W X NOTES

%uses recursive least squares rule (RLS) which frontloads dW

%%Variables
t=NOTES.CurrentTime;
cw=NOTES.CurrentWord;
cl=NOTES.CurrentLetter;

%% Train innate trajectory (target 1)
if type == 1
    %check train interval
    NOTES.traininterval=10;
    if size(NOTES.target1{cw},2) < NOTES.runtime
        %check for target output
        NOTES.target1{cw}(:,t-50)=X{2}(:,2);
    else
        %train to repeat innate trajectory
        %error term
        err = X{2}(:,2) - NOTES.target1{cw}(:,t-50);
        %cycle through plastic postsynaptic units
        for i = NOTES.punits
            %activity of neurons presynaptic to plastic neurons
            x = double(X{2}(NOTES.prepunits{i},2));
            %P matrix (variable learning rates for each synapse)
            p_old = NOTES.P1{i};
            p_new = p_old*x;
            %calculate new values for P matrix & save for next step (wtf = from Buonomano, 2012, simplification of Sussilo & Abbot?)
            wtf = 1 + x'*p_new;
            NOTES.P1{i} = p_old - (p_new*p_new') / wtf;
            %update synaptic weights (layer 2, pre-plastic > neuron i)
            dW = -err(i) * (p_new' / wtf)';
            %multiply weight updates by learning constant
            dW = dW*NOTES.alpha;
            %update weights
            W{2,2}(NOTES.prepunits{i},i) = W{2,2}(NOTES.prepunits{i},i) + double(dW);
        end
    end
end

%% Train sequence (target 2)
if type == 2
    %check train interval
    NOTES.traininterval=7;
    %error term
    err = X{3}(:,2) - NOTES.target2{cw}(:,t-50);
    %activity of neurons presynaptic to plastic neurons
    x = double(X{2}(:,2));
    %cycle through plastic postsynaptic units
    for i = 1:NOTES.netsize(3)
        %P matrix (variable learning rates for each synapse)
        p_old = NOTES.P2{i};
        p_new = p_old*x;
        %calculate new values for P matrix & save for next step
        wtf = 1 + x'*p_new;
        NOTES.P2{i} = p_old - (p_new*p_new') / wtf;
        %update synaptic weights (all layer 2 > layer 3, neuron i)
        dW = -err(i) * (p_new' / wtf)';
        %multiply weight updates by learning constant
        dW = dW*NOTES.alpha;
        %update weights
        W{2,3}(:,i) = W{2,3}(:,i) + double(dW);
    end
end

%% Train handwrighting (target 3)
if type == 3
    %check train interval
    NOTES.traininterval=2;
    %check for target output
    if isempty(NOTES.target3{cl})
        createtarget(cl);
    end
    %error term
    err = X{5}(:,2) - NOTES.target3{cl}(:,t-50);
    %activity of neurons presynaptic to plastic neurons
    x = double(X{4}(:,2));
    %cycle through plastic postsynaptic units
    for i = 1:NOTES.netsize(5)
        %P matrix (variable learning rates for each synapse)
        p_old = NOTES.P3{i};
        p_new = p_old*x;
        %calculate new values for P matrix & save for next step
        wtf = 1 + x'*p_new;
        NOTES.P3{i} = p_old - (p_new*p_new') / wtf;
        %update synaptic weights (all layer 2 > layer 3, neuron i)
        dW = -err(i) * (p_new' / wtf)';
        %multiply weight updates by learning constant
        dW = dW*NOTES.alpha;
        %update weights
        W{4,5}(:,i) = W{4,5}(:,i) + double(dW);
    end
end

%% Restart sim
NOTES.runsim=true;
