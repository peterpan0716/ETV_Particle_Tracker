%% ETV Project 
% This script loads ETV/CPC video and performes cluster analysis of floating
% particles and evaluates velocity of each particles in FOV.
% Written by Min Jae Kim (mkim@bwh.harvard.edu), Dept. of Neurology,
% Harvard Medical School
% Last Edited on: 02/12/2023
%% Overview 
% Important Variables: 
% (1) imstor: stores each video frames of loaded ETV/CPC vieo
% (2) cntrd_cell: stores cluster coordinates & centroid of clusters identified in each frame
% (3) ident_cell: stores cluster membership of frames between temporally
% adjacent time poiints
% (4) seed_cell: stores each clusters across different timepoints
%% Variable Set 
vid_tit='sample_vid.mp4'; %title of video
filt_Y=1; % Apply gaussian filter (Yes/No) | Default = Yes
gaus_filt=2; % Degree of gaussian filter applied | Default = 2
thr_diff=0.85; % Image intensity threshold for cluster detection | Default =  0.85
clust_size=100; % Minimum number of pixels in cluster | Default = 100 
auto_lag_thr=4.7; % Maximum distance between clusters across two adjacent timepoints | Default 
auto_corr=0.5;  % Minimum spatial correlation coefficient across two adjacent timepoints
pix2mm=0.0432; % Pixel-mm Convertion Factor (units = mm/pix) |(BE CAREFUL WITH THIS! DEPENDS ON RESOLUTION OF VIDEO)
%% Step 0: Loading Video
disp("Step 1: Loading Video Frames")
vid=VideoReader(vid_tit); %Load Video file
numFrames = vid.NumberOfFrames;
n=numFrames;
imstor=cell(1,n);
 for i = 1:n
 frames = read(vid,i);
 gI = rgb2gray(frames); 
 K = mat2gray(gI);
 if filt_Y==1
    K = imgaussfilt(K,gaus_filt); 
 end 
 imstor{1,i}=K;         %each element of imstor is frames of the video
 end
disp("Video frame loading complete. There are total "+string(n)+" frames to process")
%% Step 1: Temporal Difference Map 
cntrd_cell=cell(numFrames,2);
vali=1:numFrames;

disp("Step 2: Identifying Spatial Clusters in Video Frames")
for i=2:numFrames  %length(vali)
    tic
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
    %%
    [idxi_x,idxi_y]=find(val==1);
    
    if length(idxi_x)./(size(val,1)*size(val,2))*100 <=0.5 % Only chose frames below 0.5%
    euc_mat=[];
    for ii=1:length(idxi_x)
        coor=[idxi_x(ii),idxi_y(ii)];
        for jj=1:length(idxi_x)
            new_coor=[idxi_x(jj),idxi_y(jj)];
            euc=sqrt(sum((coor - new_coor) .^ 2));
            euc_mat(ii,jj)=euc;
        end 
    end
    %% Step 3: Hierchial Clustering
    Z = linkage(euc_mat);
   % dendrogram(Z)
    c = cluster(Z,'Cutoff',500,'Criterion','distance'); % Cluster Cutoff;
    max_clust=max(c);
    clust_cell=cell(max_clust,1);
    for hh=1:max_clust
        idxi=find(c==hh);
        sel_x=idxi_x(idxi);
        sel_y=idxi_y(idxi);
        sel_cor=[sel_x,sel_y];
        clust_cell{hh,1}=sel_cor;
    end 
    %% Step 4: Cluster Post-Processing
    del_idxi=[];
    for hh=1:max_clust
        mem_size=size(clust_cell{hh,1},1);
        if mem_size<clust_size
            del_idxi=[del_idxi;hh];
        end 
    end 
    clust_cell(del_idxi)=[];
    %% Step 5: Centroid Extraction
    max_clust=length(clust_cell); %revised cluster numbers
    cntrd_col=[];
    for hh=1:max_clust
        clust_idxi=clust_cell{hh,1};
        cntrd_val=[round(mean(clust_idxi(:,1))),round(mean(clust_idxi(:,2)))];
        cntrd_col=[cntrd_col;cntrd_val];
    end 
    cntrd_cell{i,1}=cntrd_col;
    cntrd_cell{i,2}=clust_cell;
    end 
    disp("Processed "+string(i)+" out of "+string(numFrames)+" Frames.");
    toc
end 
clearvars -except cntrd_cell imstor numFrames clust_size K vid_tit auto_lag_thr auto_corr vid pix2mm vid_tit
%% Step 6: Time-Variant Cluster Membership Confirmation
%% N.B!!: index (ii) of ident_col is from cluster membership from ii <-- ii-1
% E.g: cluster membership of 3 of indent_col is from timepoint 2 -->
% timepoint 3
ident_col=cell(length(cntrd_cell),1);
for i=1:size(cntrd_cell,1)-1 %% CHANGE MADE 01/03/2022
    if ~isempty(cntrd_cell{i,2}) && ~isempty(cntrd_cell{i+1,1})
    val_1=cntrd_cell{i,2};
    ident_cell=cell(size(val_1,1),1);
    
    r_vec_col=[];
    for ii=1:size(val_1,1)
        vec=val_1{ii};
        temp_1=zeros(size(K));
        temp_1(vec(:,1),vec(:,2))=1;
        %ii=
        val_2=cntrd_cell{i+1,2};
        %
        r_vec=[];
        dist_vec=[];
        ident_vec=[];
        %
        for jj=1:size(val_2,1)
            vec_2=val_2{jj};
            temp_2=zeros(size(K));
            temp_2(vec_2(:,1),vec_2(:,2))=1;
            
            [r,lags] = xcorr(temp_1(:),temp_2(:),'normalized');
            
            r_max=max(r);
            lag=abs(median(lags(find(r==r_max))));
            % cluster t=0 is equal to cluster t=1 under spatial constraint
            % correlation of cluster volumes under auto-correlation 
             if lag./max(lags)*100 <= auto_lag_thr && r_max >= auto_corr
                 ident_vec=[ident_vec;1]; 
                 r_vec=[r_vec;r_max];
                 dist_vec=[dist_vec;lag];
             else 
                 ident_vec=[ident_vec;0];  
                 r_vec=[r_vec;r_max];
                 dist_vec=[dist_vec;lag];
             end 
             
             r_vec_col=[r_vec_col;r_vec];
        end 
        %% Imposing Constraints
        % Case 1: When one cluster at t=0 divides into 2 (or more) at t=1
        % Forces one cluster to produce one cluster (no multiple cluster) 
        if length(find(ident_vec==1))>1 % [1,1] repeat
            idxi_r=min(find(r_vec==max(r_max)));
            ident_vec(ident_vec~=idxi_r)=0;            
        end 
        
        %% 
     
        ident_cell{ii,1}=ident_vec;
    end 
    
    % Case 2: When multiple cluster at t=0 converges into one 
    if  length(ident_cell{1,1})==1 && sum(cell2mat(ident_cell)==1)>1
        idxi_r=find(r_vec_col~=max(r_vec_col));
        for hhh=1:length(idxi_r)
            ident_cell{idxi_r(hhh),1}=0;
        end 
    end 
    
    ident_col{i+1,1}=ident_cell;
    end 
    i
end 
clear ident_cell ident_vec;
% N.B: Index Organization of ident_col & cntrd_cell
% 1. size of cell in ident_col{i} = number of clusters in i-1 (i.e number
% of clusters in cntrd_cell{i-1}
% 2. size of array in EACH cell in in ident_col{i} = number of clusters in i (i.e number
% of clusters in cntrd_cell{i}
%% Step 7: Cluster Membership Streamline: Follow the One!
%%
seed_cell=cell(1,2);
cnt=1;
for i=2:length(ident_col)-1
    if sum(cell2mat(ident_col{i,1}))~=0  %% skip over empty frames
        seed=ident_col{i,1};
        if sum(cell2mat(seed))>1 
            seed={seed{1,1}}; % If two simultaneous clusters, just choose first one
        end 
        %
        if sum(cell2mat(seed))==1 && sum(cell2mat(ident_col{i-1,1}))==0 %finding cluster & previous one is zero
            t_col=[];
            seed_col=[]; %% open new seed_col
            [seed_col]=[seed_col;clust_connect(seed,i,cntrd_cell)];
            t_col=[t_col;i-1;i];
        elseif sum(cell2mat(seed))==1 && sum(cell2mat(ident_col{i-1,1}))==1 %finding cluster & previous one also cluster
            if sum(cell2mat(ident_col{i+1,1}))==1 || ~isempty(ident_col{i+1,1})
                [seed_col]=[seed_col;clust_connect(seed,i,cntrd_cell)];
                 t_col=[t_col;i-1;i];
            elseif sum(cell2mat(ident_col{i+1,1}))==0 || isempty(ident_col{i+1,1})
                [seed_col]=[seed_col;clust_connect(seed,i,cntrd_cell)];
                 t_col=[t_col;i-1;i];
                % Post Processing: Deleting Repeats 
                [~,ia,~] = unique(t_col);
                seed_cell{cnt,1}=seed_col(ia,:);
                seed_cell{cnt,2}=t_col(ia);
                %
                cnt=cnt+1;
            end
        end
        %%
    end         
end 
%% Calculating Velocity Intra-Cluster
dt=round(1./vid.FrameRate,4); %sec
v_col=[];
for i=1:length(seed_cell)
    clust=seed_cell{i,1};
    for j=2:length(clust)
        d_pix = norm(clust(j,:)-clust(j-1,:));
        d_mm=d_pix*pix2mm;
        v_mm=d_mm./dt; %mm/sec
        v_col=[v_col;v_mm];
    end 
end 
%% Plotting & Saving Variables
tit=erase(vid_tit,'.mp4'); 
ETV.title=tit; %saving title
ETV.cntrd_cell=cntrd_cell; %saving each frame
ETV.seed_cell=seed_cell;
ETV.dt=dt; 
ETV.velocity=v_col;
ETV.vid_height=vid.Height;
ETV.vid_width=vid.Width;
save(tit+".mat",'ETV');
clear all

%{
for i=1:length(seed_cell)
RGB=[rand,rand,rand];
vec=seed_cell{i,1};
Y=vec(:,1);
X=vec(:,2);
Y=vid.Height-Y;
Spatio=[X,Y]; %swiw
for jjj=1:length(X)
    vec=Spatio(jjj,:);
    plot(vec(1),vec(2),'--o','MarkerSize',10,'MarkerEdgeColor',RGB,'MarkerFaceColor',RGB);
    axis([1 vid.Width 1 vid.Height])
    xlabel('X-Pixels of Scope');
    ylabel('Y-Pixels of Scope');
    fig_tit="Spatial Location of Particle Trajectory | dt = "+string(dt)+"sec";
    title(fig_tit);
    hold on
    pause(0.5)
end
hold off
end 

%clear all


ts=seed_cell{9,2};
 for j = 1:length(ts)
 K=imstor{1,ts(j)}; 
 heatmap(K)
 colormap jet
 grid off
 pause(0.5);
 end

 %}
 

