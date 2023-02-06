seed_cell=cell(1,2);
cnt=1;
for i=2:length(ident_col)
    if ~isempty(ident_col{i,1}) || sum(cell2mat(ident_col{i,1}))~=0  %% skip over empty frames
        seed=ident_col{i,1};
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
                seed_cell{cnt,1}=seed_col(ia);
                seed_cell{cnt,2}=t_col(ia);
                %
                cnt=cnt+1;
            end
        end
        %%
    end         
end 