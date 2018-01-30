classdef TrajAnalysis2D < handle
    %TrajAnalysis2D Basic Statistical Analysis in trajectory level
    %   obj = ParAnalysis2D(pd,deltaT)
    
    properties
        pd;
    end
    
    properties(GetAccess = public, SetAccess = public)
        deltaT;
    end
    
    properties(Access=private)
        calTmpCell;
    end
    
    properties(Dependent)
        ids;
    end
    
    methods
        function obj = TrajAnalysis2D(pd,deltaT)
            obj.pd = pd;
            obj.deltaT = deltaT;
            obj.calTmpCell = cell(obj.pd.particleNum,1);
            for m = 1:1:obj.pd.particleNum
                obj.calTmpCell{m} = struct();
            end
        end
        
        function ids = get.ids(obj)
            ids = obj.pd.ids;
        end
        
        function vel = getAveVelByIds(obj,ids)
            if nargin == 1
                ids = obj.ids;
            end
            L = length(ids);
            vel = zeros(L,1);
            for m = 1:1:L
                [~,I] = ismember(ids(m),obj.ids);
                if I > 0
                    if ~isfield(obj.calTmpCell{I},'vel')
                        xy = obj.pd.getRawMatById(ids(m),[2,3]);
                        obj.calTmpCell{I}.vel = TrajAnalysis2D.xy2vel(xy,obj.deltaT,0);
                    end
                    vel(m) = mean(obj.calTmpCell{I}.vel);
                else
                    fprintf(1,'Cannot find particle ID: %d\n',ids(m));
                    vel(m) = nan;
                end
            end
        end
        
        function [msd,lag] = getTrajMSDByIds(obj,ids,maxLag)
            if isempty(ids)
                ids = obj.ids;
            end
            L = length(ids);
            msd = zeros(L,maxLag+1);
            for m = 1:1:L
                [~,I] = ismember(ids(m),obj.ids);
                if I > 0
                    if ~isfield(obj.calTmpCell{I},'msd')
                        xy = obj.pd.getRawMatById(ids(m),[2,3]);
                        msdVec = TrajAnalysis2D.xy2msd(xy,maxLag);
                        obj.calTmpCell{I}.msd = [eps,msdVec];%better for power fitting
                    end
                    msd(m,:) = obj.calTmpCell{I}.msd;
                else
                    fprintf(1,'Cannot find particle ID: %d\n',ids(m));
                end
            end
            lag = (0:1:maxLag)*obj.deltaT;
        end
        
        function [alpha,D] = getTrajAlphaDByIds(obj,indices,maxLag)
            if isempty(indices)
                indices = obj.ids;
            end
            L = length(indices);
            alpha = zeros(L,1);
            D = zeros(L,1);
            h = waitbar(0,'please wait...');
            for m = 1:1:L
                [~,I] = ismember(indices(m),obj.ids);
                if I > 0
                    if ~isfield(obj.calTmpCell{I},'alpha')
                        if ~isfield(obj.calTmpCell{I},'msd')
                            obj.calTmpCell{I}.msd = obj.getTrajMSDByIds(indices(m),maxLag);
                        end
                        t = (0:1:maxLag)*obj.deltaT; t(1) = eps; %better for fitting
                        if any(isnan(obj.calTmpCell{I}.msd))
                            obj.calTmpCell{I}.alpha(m) = nan;
                            obj.calTmpCell{I}.D(m) = nan;
                        else
                            [obj.calTmpCell{I}.alpha,obj.calTmpCell{I}.D] = ...
                            TrajAnalysis2D.fitMSDCurve(t,obj.calTmpCell{I}.msd,0);
                        end
                    end
                    alpha(m) = obj.calTmpCell{I}.alpha;
                    D(m) = obj.calTmpCell{I}.D;
                else
                    fprintf(1,'Cannot find particle ID: %d\n',indices(m));
                    alpha(m) = nan;
                    D(m) = nan;
                end
                waitbar(m/L,h,sprintf('please wait: %.2f%%',100*m/L));
            end
            close(h);
        end
        
        function Smss = getTrajSmssByIds(obj,ids,lag,maxP)
            if isempty(ids)
                ids = obj.ids;
            end
            L = length(ids);
            Smss = zeros(L,1);
            for m = 1:1:L
                [~,I] = ismember(ids(m),obj.ids);
                if I > 0
                    if ~isfield(obj.calTmpCell{I},'mss')
                        obj.calTmpCell{I}.mss = TrajAnalysis2D.xy2mss(obj.pd.getRawMatById(ids(m),[2,3]),lag,maxP,0);
                    end
                    Smss(m) = obj.calTmpCell{I}.mss;
                else
                    fprintf(1,'Cannot find particle ID: %d\n',ids(m));
                    Smss(m) = nan;
                end
            end
        end
        
        function asym = getTrajAsymByIds(obj,ids)
            if isempty(ids)
                ids = obj.ids;
            end
            L = length(ids);
            asym = zeros(L,1);
            for m = 1:1:L
                [~,I] = ismember(ids(m),obj.ids);
                if I > 0
                    if ~isfield(obj.calTmpCell{I},'asym')
                        obj.calTmpCell{I}.asym = TrajAnalysis2D.xy2asym(obj.pd.getRawMatById(ids(m),[2,3]));
                    end
                    asym(m) = obj.calTmpCell{I}.asym;
                else
                    fprintf(1,'Cannot find particle ID: %d\n',ids(m));
                    asym(m) = nan;
                end
            end
        end
        
        function filterOutlierVel(obj,threshold,tolerance,isShow,iterTime)
            for reps = 1:1:iterTime
                outerID = TrajAnalysis2D.findVelOutlier(obj.pd,threshold,0);
                num = length(outerID);
                fprintf(1,'Find %d outliers in iteration: %d\n',num,reps);
                if num == 0
                    disp('no outliers, stop iteration');
                    break;
                end
                for m = 1:1:num
                    mat = obj.pd.getRawMatById(outerID(m));
                    newMat = TrajAnalysis2D.fixOutlierVel(mat,threshold,tolerance,isShow);
                    obj.pd.setDataById(outerID(m),newMat);
                end
                if isShow
                    pause;
                    close all;
                end
            end
            obj.clearCalTmp();
        end
        
        function num = filterZeroVel(obj,tolerance)
            num = 0;
            delID = [];
            for m = 1:1:obj.pd.particleNum
                id = obj.ids(m);
                [mat,~] = TrajAnalysis2D.fixZeroVel(obj.pd.getRawMatById(id),tolerance,0);
                if isempty(mat)
                    delID(end+1) = id;
                    num = num + 1;
                else
                    obj.pd.setDataById(id,mat);
                end
            end
            if num > 0
                obj.pd.delParticleById(delID);
            end
        end
        
        function clearCalTmp(obj)
            for m = 1:1:obj.pd.particleNum
                obj.calTmpCell{m} = struct();
            end
        end
        
        function plotCurveWithTag(obj,hAxes,ids,tags,isLabel)
            offset = 0.3;
            if isempty(hAxes)
                figure; hAxes = axes;
            end
            if isempty(ids)
                ids = obj.ids;
            end
            if nargin == 4
                isLabel = false;
            end
            if length(ids) == length(tags)
                hAxes.NextPlot = 'add';
                category = unique(tags); L = length(category);
                legendGroup = zeros(L,1); legendName = cell(L,1);
                cmap = lines;
                for m = 1:1:L
                    subgroup = ids(tags==category(m)); nMember = length(subgroup);
                    for n = 1:1:nMember
                        xy = obj.pd.getRawMatById(subgroup(n),[2,3]);
                        h = plot(hAxes,xy(:,1),xy(:,2),'Color',cmap(m,:));
                        if n == 1
                            legendGroup(m) = h; legendName{m} = num2str(category(m));
                        end
                        if isLabel
                            text(xy(1,1)+offset,xy(1,2)+offset,num2str(subgroup(n)),...
                                'Color',cmap(m,:),'FontSize',5);
                        end
                    end
                end
                legend(legendGroup,legendName(:));
                legend show;
                xlabel('x/\mum'); ylabel('y/\mum');
                xlim([obj.pd.xRange]); ylim([obj.pd.yRange]);
                box on;
            else
                disp('The length of ids and tags should be equal!');
            end
        end
    end
    
    methods(Access = private)
        
    end
    
    methods(Static)
        function vel = xy2vel(xy,deltaT,isAlignLength)
            deltaPos = xy(2:end,:) - xy(1:(end-1),:);
            vel = sqrt(sum(deltaPos.^2,2))./deltaT;
            if isAlignLength
                vel = [0;vel];
            end
        end
        
        function ids = findVelOutlier(pd,threshold,isShow)
            if pd.minTraceLength < 5
                disp('min length smaller than 5, del func processed');
                pd.delParticleById(pd.filterMatByFunc(@(umat,x)size(umat,1)<x,5));
            end
            diff = zeros(length(pd.ids),2);
            boolRes = false(length(pd.ids),1);
            for m = 1:1:length(pd.ids)
                mat = pd.getRawMatById(pd.ids(m));
                vel = TrajAnalysis2D.xy2vel(mat(:,2:3),1,0);
                diff(m,:) = [pd.ids(m),(max(vel)-mean(vel))/std(vel)];
                [boolRes(m),I,v] = TrajAnalysis2D.isOutlier(vel,threshold);
                if isShow && boolRes(m)
                    figure; plot(subplot(1,2,1),mat(:,2),mat(:,3)); hold on;
                    scatter(mat(I,2),mat(I,3),30,'filled'); title(sprintf('ID:%d, value: %.3f',pd.ids(m),v));
                    plot(subplot(1,2,2),vel); hold on;
                    scatter(I,vel(I),30,'filled');
                end
            end
            %ids = diff(diff(:,2)>threshold,1);
            ids = diff(logical(boolRes),1);
            if isShow
                figure;scatter(diff(:,1),diff(:,2),'filled');
                figure; histogram(diff(:,2));  
                figure;pd.plotTrace(axes,ids,1);
            end
        end
        
        function fixedMat = fixOutlierVel(oriMat,threshold,tolerance,isShow)
            L = size(oriMat,1);
            vel = TrajAnalysis2D.xy2vel(oriMat(:,2:3),1,0);
            [b,I,v] = TrajAnalysis2D.isOutlier(vel,threshold);
            if b
                if I<=L*tolerance
                    fixedMat = oriMat((I+1):end,:);
                elseif I>=(1-tolerance)*L  
                    fixedMat = oriMat(1:(I-1),:);
                else
                    fixedMat = oriMat;
                end
            else
                fixedMat = oriMat;
            end
            if isShow
                figure;
                plot(subplot(2,2,1),oriMat(2:end,1),vel);
                xlim([oriMat(1,1),oriMat(end,1)]); title(num2str(v));
                plot(subplot(2,2,2),oriMat(:,2),oriMat(:,3));
                plot(subplot(2,2,3),fixedMat(:,1),TrajAnalysis2D.xy2vel(fixedMat(:,2:3),1,1));
                xlim([oriMat(1,1),oriMat(end,1)]);
                plot(subplot(2,2,4),fixedMat(:,2),fixedMat(:,3));
            end
        end
        
        function [fixedMat,errorLength] = fixZeroVel(oriMat,tolerance,isShow)
            L = size(oriMat,1);
            xVel = TrajAnalysis2D.xy2vel([ones(L,1),oriMat(:,2)],1,0);
            yVel = TrajAnalysis2D.xy2vel([ones(L,1),oriMat(:,3)],1,0);
            zeroLogic = or(xVel==0,yVel==0);
            errorLength = sum(zeroLogic);
            if errorLength > 1 %need to be fixed
                index = 2:1:L; I = index(zeroLogic);
                if errorLength/L > tolerance %del the record
                    fixedMat = [];
                    fixMethod = 'delete';
                elseif max(I)/L < tolerance
                    fixedMat = oriMat((max(I)+1):end,:);
                    fixMethod = 'cut off';
                elseif min(I)/L > (1-tolerance)
                    fixedMat = oriMat(1:(min(I)-1),:);
                    fixMethod = 'cut off';
                else
                    [maxGap,gapPos] = max(I(2:end)-I(1:(end-1)));
                    if maxGap > 150
                        filter = ones(L,1);
                        filter(1:I(gapPos)) = 0;
                        filter(I(gapPos+1):end) = 0;
                        fixedMat = oriMat(logical(filter),:);
                        fixMethod = 'inner cut';
                    else
                        fixedMat = [];
                        fixMethod = 'delete';
                    end
                    %figure;  plot(oriMat(:,2),oriMat(:,3));
                    %title(sprintf('eRatio:%.2f,length:%d,maxGapRatio:%.2f',errorLength/L,L,maxGap/L));
                    %fixMethod = 'preserve';
                end
                
                if isShow
                    fprintf(1,'Find %d, deal with %s\n',errorLength,fixMethod);
                    figure; 
                    plot(subplot(2,2,1),oriMat(:,2),oriMat(:,3));  title(fixMethod);
                    plot(subplot(2,2,3),TrajAnalysis2D.xy2vel(oriMat(:,2:3),1,0));
                    if ~strcmp(fixMethod,'delete')
                        plot(subplot(2,2,2),fixedMat(:,2),fixedMat(:,3));
                        plot(subplot(2,2,4),TrajAnalysis2D.xy2vel(fixedMat(:,2:3),1,0));
                    end
                    pause;
                end
            else
                fixedMat = oriMat;
            end
            return;
        end
        
        function indices = filterTraceByFunc(pd,func,param)
            L = pd.particleNum;
            isHit = zeros(L,1);
            for m = 1:1:L
                mat = pd.getRawMatById(pd.ids(m));
                isHit(m) = func(mat,param);
            end
            indices = pd.ids(logical(isHit));
        end
        
        function msdCurve = xy2msd(vec,maxLag,p)
            if nargin == 2
                p = 2;
            end
            [nr,~] = size(vec);
            if nr <= maxLag
                warning('vec length should higher than lag!');
                msdCurve = nan(1,maxLag);
                return;
            end
            msdCurve = zeros(1,maxLag);
            gIndexM = @(calLength,tau)bsxfun(@plus,(1:1:calLength)',[0,tau]);
            for m = 1:1:maxLag
                calLength = nr - m; %calculate length with tau = m;
                vecIndex = gIndexM(calLength,m);
                tmpM_L = vec(vecIndex(:,1),:);
                tmpM_H = vec(vecIndex(:,2),:);
                msdCurve(m) = mean(sum((abs(tmpM_H - tmpM_L)).^p,2));
            end
        end
        
        function [alpha,D] = fitMSDCurve(t,curve,isShow)
            fobject = fit(t(:),curve(:),'power1'); %max sure in column vector
            if isShow
                figure; plot(fobject,t,curve);
            end
            D = fobject.a/4;
            alpha = fobject.b;
        end
        
        function [Smss,moment,curve] = xy2mss(xy,lag,maxP,isShow)
            curve = zeros(maxP,lag+1);
            curve(:,1) = eps;
            moment = zeros(maxP,1);
            for m = 1:1:maxP
                curve(m,2:end) = TrajAnalysis2D.xy2msd(xy,lag,m);
                moment(m) = TrajAnalysis2D.fitMSDCurve([eps;(1:1:lag)'],curve(m,:),0);
            end
            fobject = fit((1:1:maxP)',moment,'poly1');
            Smss = fobject.p1;
            if isShow
                figure; plot(fobject,(1:1:maxP),moment);
                xlabel('\nu');ylabel('\gamma_\nu');
            end
        end
        
        function asym = xy2asym(xy)
        % reference: Wagner T et,al. PLoS One 2017.
        %            Saxton MJ.Biophys J. 1993.
        %            Helmuth JA, Journal of Structural Biology. 2007.
        %            Huet S, Biophysical Journal 2006, 91(9): 3542.
            tensorMat = zeros(2); % for 2D trajectory
            for m = 1:1:2
                for n = 1:1:2
                    tensorMat(m,n) = mean(xy(:,m).*xy(:,n)) - mean(xy(:,m))*mean(xy(:,n));%<xi*xj>-<xi><xj>
                end
            end
            eigValue = eig(tensorMat);
            asym = -log10(1-0.5*(range(eigValue)/sum(eigValue))^2);         
        end
        
        function [boolRes,I,value] = isOutlier(vec,threshold)
            winLen = 50;
            [v,I] = max(vec);
            compareIndex = max(1,I-winLen):min(length(vec),I+winLen);
            win = vec(compareIndex);
            compareIndex = compareIndex(win<(0.5*v));
            win = win(win<(0.5*v));
            value = (v - mean(win))/std(win);
            boolRes =  value > threshold;        
%             if boolRes
%                 figure; plot(vec); hold on;
%                 scatter(compareIndex,win,'filled');
%                 title(num2str(v));
%                 pause;
%             end
        end
    end
end

