function w = netweights(sz,sparsity,strength,l)

global NOTES

%sz = two element vector, [#presyn #postsyn]
%sparsity = scalar bw 0 and 1, probability of two neurons being connected
%strength = scalar, scaling factor for synaptic weights

if nargin<4
    l=2; %constant for degree of spatial organization
end

if sparsity>0 && strength~=0
    %create fully connected network
    w = randn(sz(1),sz(2)); %creates +/- weights bw 0 and 1
    
    %make mask for sparse network
    mask = rand(sz(1),sz(2));
    mask(mask <= sparsity) = 1;
    mask(mask < 1) = 0;
    
    %calculate distance between neurons (assuming square network)
    nn=NOTES.netsize(2); %number of neurons in RRN
    NOTES.d=nan(nn);
    for i=1:nn
        %length of plotted square
        plotsz = [sqrt(nn) sqrt(nn)];
        %get distances of each pixel from neuron i
        [y,x]=ind2sub(plotsz,1:nn);
        NOTES.d(i,:) = abs(x-x(i)) + abs(y-y(i));
    end
    
    %parameters for large RRN
    if min(sz(:))>50 && sz(1)==sz(2)
        %force each neuron to be excitatory or inhibitory
        %determine whether more + or - weights for each neuron
        type = sum(w,2);
        type = type > 0;
        %excitatory neurons
        w(type,:) = abs(w(type,:));
        %inhibitory neurons
        w(~type,:) = -abs(w(~type,:));
        %apply distance filter to weights/mask
        d=NOTES.d;
        d = d./max(d(:)); %normalize
        d = 1 - d; %inverse
        d = d - mean(d(:)) + 1; %set mean to 1
        %apply distance filter to weights
        w = w .* d.^l;
        %redo mask with spatial filter
        mask = rand(sz(1),sz(2)) ./ d.^l;
        mask(mask <= quantile(mask(:),1-sparsity)) = NaN;
        mask = ~isnan(mask);
    end
    
    %apply sparsity mask
    w = w.*mask;
    
    %adjust all weights by scaling factor
    if strength==-1
        w(:) = -1;
    else
        w = w .* strength;
    end
    
    %remove self-synapses
    self = logical(eye(sz(1),sz(2)));
    w(self) = 0;
    
    %convert weight matrix to sparse class
    w = sparse(w);
else
    w=zeros(sz);
end


