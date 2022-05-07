function net

global W X V NOTES

if isempty(W)
    createnet;
end

%% Initialize variables
%run sim on
NOTES.runsim=true;
%Preallocate network activity variable
for k=1:5
    X{k} = zeros(NOTES.netsize(k),2);
end
%initial voltages of hidden layer
for i=1:5
    V{i} = 0.1*(2*randn(NOTES.netsize(i),1)-1);
end
%time
NOTES.CurrentTrial=1;
t=5e3;
%stim
stimnet=[];
stimloc=[];
NOTES.watchx=[];

%% Figures & axes - network activity
%figure
set(gcf,'Color','k','toolbar','none','units','normalized');
clf;

%axes
w1=0.03;
sp1=0.01;
sp2=0.002;
w2=(1-(w1*3)-(sp1*2+sp2*4))/2;
ha(1) = axes('position',[(sp1+sp2*0+w1*0+w2*0) 0.4 w1 0.57]); %input
ha(2) = axes('position',[(sp1+sp2*1+w1*1+w2*0) 0.4 w2 0.57]); %RRN1
ha(3) = axes('position',[(sp1+sp2*2+w1*1+w2*1) 0.4 w1 0.57]); %transfer
ha(4) = axes('position',[(sp1+sp2*3+w1*2+w2*1) 0.4 w2 0.57]); %RRN2
ha(5) = axes('position',[(sp1+sp2*4+w1*2+w2*2) 0.4 w1 0.57]); %output
ha(6) = axes('position',[0 0 0.5 0.4]);
ha(7) = axes('position',[0.5 0 0.5 0.4]);

%axes labels
for i=1:5
    pos=get(ha(i),'position');
    annotation(gcf,'textbox','string',num2str(i),'linestyle','none','Color','w','horizontalalignment','center','verticalalignment','middle','fontsize',12,'fontweight','bold','position',[pos(1) 0.967 pos(3) 0.03]);
end

%network activity plots
axes(ha(1));
im(1)=imagesc(randn(NOTES.netsize(1),1));
axes(ha(2));
im(2)=imagesc(randn(NOTES.imdisplay));
axes(ha(3));
im(3)=imagesc(randn(NOTES.netsize(3),1));
axes(ha(4));
im(4)=imagesc(randn(NOTES.imdisplay));
axes(ha(5));
im(5)=imagesc(randn(NOTES.netsize(5),1));
%output plot #1 (letters, axis 6)
for i=1:length(NOTES.letters)
    an(i)=annotation(gcf,'textbox','string',NOTES.letters{i},'linestyle','none','Color','w','horizontalalignment','center','verticalalignment','middle','fontsize',100,'FaceAlpha',0,'visible','off','position',[0 0 0.5 0.4]);
end

%output plot #2 (xy coordinates, axis 7)
axes(ha(7));
l=200; %length of tail (in ms)
p=plot(nan(1,l/NOTES.plotskip),nan(1,l/NOTES.plotskip),'color','w','Linewidth',3);
hold on;
sc=scatter(0,0,'MarkerEdgeColor','w','MarkerFaceColor','w','SizeData',50);
hold off;

%set axis limits and turn off
for i=1:5
    caxis(ha(i),[-1 1]);
end
set(ha(7),'XLim',[-2 2],'YLim',[-1.5 1.5]);
set(ha(:),'visible','off');

%% user interaction with figure
%keypress > run/stop simulation
set(gcf,'WindowKeyPressFcn',@runsimstatus);
%mouse click stimulates/strokes network
set(gcf,'WindowButtonDownFcn',@(obj,evt) stim(obj,evt));
%message board to track training progress
%msg=annotation(gcf,'textbox','string',NOTES.letters{i},'linestyle','none','Color','w','backgroundcolor','k','horizontalalignment','center','verticalalignment','middle','fontsize',100,'FaceAlpha',0.2,'visible','off','position',[0 0 1 0.4]);

%% start sim
runsim;

%% Functions 
    %run simulation
    function runsimstatus(obj,evt)
        if NOTES.runsim
            NOTES.runsim=false;
        else
            NOTES.runsim=true;
            runsim;
        end
        %if button is letter 's' than apply stroke
        %...
    end
    function runsim
        while NOTES.runsim
            %update time
            t=t+1;
            NOTES.CurrentTime=t;
            set(gcf,'name',[num2str(round(t/10)/100) ' sec']);
            %flush out queued callbacks
            drawnow;
            %Shift "current activity" (element 2) to "previous timestep" (element 1)
            for k=1:5
                X{k}(:,1)=X{k}(:,2);
            end
            %cycle through postsyn layers (k)
            for k=1:5
                %reset synaptic current
                I = zeros(NOTES.netsize(k),1);
                %I from synaptic activity
                for m=1:5
                    %I from presyn layer m
                    I = I + ( W{m,k}' * X{m}(:,1) ); %add new activity
                end
                %I from noise
                I = I + NOTES.noise * randn(NOTES.netsize(k),1) * sqrt(NOTES.dt);
                %I block from  stroke (silences all activity at stroke sites)
                I(NOTES.stroke{k}(:))=0;
                %get new voltage (buffer RRN by time constant)
                if any(k==[2 4])
                    V{k} = V{k} + ((I - V{k})./NOTES.tau)*NOTES.dt;
                else
                    V{k} = I;
                end
                %apply activation function
                X{k}(:,2) = NOTES.activationfx{k}( V{k} );
                %add stimulation (bypasses temporal filter and activation function)
                if t<100 && k==stimnet
                    %expand stim area if large network
                    if NOTES.netsize(k)>1e3 && length(stimloc)==1
                        stimloc=NOTES.d(stimloc,:)<5;
                    end
                    mx=normpdf(50,50,10);
                    X{k}(stimloc,2) = normpdf(t,50,10)/mx;
                end
            end
            %teacher (periodic stim + trial counter)
            if NOTES.teacher
                if NOTES.CurrentTime>NOTES.runtime+500
                    stimnet=1;
                    stimloc=1;
                    t=1;
                end
            end
            %training
            if rem(t,NOTES.traininterval)==0
                if NOTES.train(1) && NOTES.CurrentTime<=NOTES.runtime+50 && NOTES.CurrentTime>50 && stimnet==1
                    trainnet(1);
                elseif NOTES.train(2) && NOTES.CurrentTime<=NOTES.runtime+50 && NOTES.CurrentTime>50 && stimnet==1
                    trainnet(2);
                elseif NOTES.train(3) && NOTES.CurrentTime<=250 && NOTES.CurrentTime>50 && stimnet==3
                    NOTES.stroke{2}(:)=true;
                    trainnet(3);                    
                end
            end
            %update plot
            if rem(t,NOTES.plotskip) == 0
                plotdata;
            end
            %save GIF
            if rem(t,10)==0 && NOTES.gif
                figgif('RMN',0.1);
            end         
            %save activity of unit being "watched"
            if t==50
                NOTES.watchx(1,end+1)=X{NOTES.watch(1)}(NOTES.watch(2));
            elseif t>50 && t<NOTES.runtime*2
                NOTES.watchx(t-49,end)=X{NOTES.watch(1)}(NOTES.watch(2));
            end
                
        end
    end
        
    %plot data
    function plotdata
        %plot network activity
        for ii = [1 3 5]
            im(ii).CData = X{ii}(:,2);
        end
        for ii = [2 4]
            im(ii).CData = reshape(X{ii}(:,2),NOTES.imdisplay);
        end
        %plot output activity (letters)
        letteron = X{3}(:,2)>0.8;
        set(an(letteron),'visible','on');
        set(an(~letteron),'visible','off');
        %plot output activity (line segments)
        p.XData = [p.XData(2:end) X{5}(1,2)];
        p.YData = [p.YData(2:end) X{5}(2,2)];
        sc.XData = X{5}(1,2);
        sc.YData = X{5}(2,2);
        %pause
        if isnan(NOTES.plotdelay)
            pause;
        else
            pause(NOTES.plotdelay);
        end
    end
    
    %stimulate network
    function stim(obj,evt)
        %identify location of click (axis/network)
        stimnet = find(gca == ha);
        if any(stimnet==[1:5])
            %identify location of click (xy coord/neuron)
            stimloc = get (gca, 'CurrentPoint');
            stimloc=round(stimloc(1,1:2));
            if any(stimnet==[2 4])
                stimloc=sub2ind(size(im(stimnet).CData),stimloc(2),stimloc(1));
            else
                stimloc=stimloc(2);
            end
            if stimnet==1
                NOTES.CurrentWord=stimloc;
            end
            if stimnet==3
                NOTES.CurrentLetter=stimloc;
            end
            %reset time stamp
            t=0;
            drawnow;
        end
    end
end
