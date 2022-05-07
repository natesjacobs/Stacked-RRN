function netstroke(strokesize,layer)

global NOTES

if nargin<1
    strokesize=0.3;
end
if nargin<2
    layer=4;
end

n=NOTES.netsize(layer);

%index of neurons killed by infarct
x=round(sqrt(n)*strokesize);
stroke=false(sqrt(n));
stroke(1:x,1:x)=true;
NOTES.stroke{layer}=stroke(:);
