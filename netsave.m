function netsave(string)

global W NOTES

NOTES.P={};

if nargin<1
    string = date;
end

save(['net_' string],'W','NOTES','-v7.3');