%% Raw Video (2 Slides)
t=round(1./vid.FrameRate,3);
cnt=0;
for i=104:112
    IMG=imstor{1,i};
    imshow(IMG,[],Colormap=jet)
    colormap(jet)
    fig_tit="Raw Endoscope Image | Time = "+string(cnt)+" Seconds";
    title(fig_tit)
    ax = gca;
    ax.FontSize = 13;
    cnt=cnt+t;
    pause(0.5)
end 
%% Thresholed & Smoothed Images
vali=1:numFrames;
thr_diff=0.85; % Threshold for diff image 
gaus_filt=2; % Degree of filter (this smoothes frame image)

cnt=0;
for i=104:111  %length(vali)
   % figure
    val=imstor{1,vali(i)}-imstor{1,vali(i)-1};
    val = imgaussfilt(val,gaus_filt); 
    % Imposing Threshold
    maxi=max(val(:));
    mini=min(val(:));
    thr_val=mini+(abs(maxi-mini).*thr_diff);
    val(val<thr_val)=0;
    %% Step 2: Binarizaton of Difference Map 
    val(val>0)=1;
    imshow(val)
    fig_tit="Thresholded & Smoothed Image | Time = "+string(cnt)+" Seconds";
    title(fig_tit);
    ax = gca;
    ax.FontSize = 13;
    cnt=cnt+t;
    pause(0.5)
end 
%% Centroid
i=3;
vec=seed_cell{i,1};
Y=vec(:,1).*pix2mm;
X=vec(:,2)*pix2mm;
Y=(vid.Height*pix2mm)-Y;
Spatio=[X,Y]; %swiw
  
cnt=0;
for jjj=1:length(X)
    vec=Spatio(jjj,:);
    plot(vec(1),vec(2),':o','MarkerSize',15,'MarkerFaceColor',"#D95319",'MarkerEdgeColor',"w",'LineWidth',3);
    axis([1 vid.Width.*pix2mm 1 vid.Height*pix2mm])
    %xlabel('X-Pixels of Scope');
    %ylabel('Y-Pixels of Scope');
    fig_tit="Centroid of Particle Trajectory | Time = "+string(cnt)+" Seconds";
    title(fig_tit);
    ax = gca;
    ax.FontSize = 13;
    set(gca,'XTick',[])
    set(gca,'YTick',[])
    cnt=cnt+t;
    hold on
    xlabel('mm');
    ylabel('mm');
    pause(0.5)
end
hold off
%% Full Trajectory
i=3;
vec=seed_cell{i,1};
Y=vec(:,1).*pix2mm;
X=vec(:,2)*pix2mm;
Y=(vid.Height*pix2mm)-Y;
Spatio=[X,Y]; %swiw
  
plot(Spatio(:,1),Spatio(:,2),':o','MarkerSize',15,'MarkerFaceColor',"#D95319",'MarkerEdgeColor',"w",'LineWidth',3);
axis([1 vid.Width.*pix2mm 1 vid.Height*pix2mm])
%set(gca,'XTick',[])
%set(gca,'YTick',[])
ax = gca;
ax.FontSize = 13;
xlabel('mm');
ylabel('mm');
fig_tit="Full Spatial Trajectory of Particle";
title(fig_tit);
