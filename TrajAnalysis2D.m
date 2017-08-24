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
        
        function [alpha,D] = getTrajAlphaDByIds(obj,ids,maxLag)
            if isempty(ids)
                ids = obj.ids;
            end
            L = length(ids);
            alpha = zeros(L,1);
            D = zeros(L,1);
            for m = 1:1:L
                [~,I] = ismember(ids(m),obj.ids);
                if I > 0
                    if ~isfield(obj.calTmpCell{I},'alpha')
                        if ~isfield(obj.calTmpCell{I},'msd')
                            obj.calTmpCell{I}.msd = obj.getTrajMSDByIds(ids(m),maxLag);
                        end
                        t = (0:1:maxLag)*obj.deltaT; t(1) = eps; %better for fitting
                        [obj.calTmpCell{I}.alpha,obj.calTmpCell{I}.D] = ...
                            TrajAnalysis2D.fitMSDCurve(t,obj.calTmpCell{I}.msd,0);
                    end
                    alpha(m) = obj.calTmpCell{I}.alpha;
                    D(m) = obj.calTmpCell{I}.D;
                else
                    fprintf(1,'Cannot find particle ID: %d\n',ids(m));
                    alpha(m) = nan;
                    D(m) = nan;
                end
            end
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
        end
        
        function clearCalTmp(obj)
            for m = 1:1:obj.pd.particleNum
                obj.calTmpCell{m} = struct();
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
            diff = zeros(length(pd.ids),2);
            for m = 1:1:length(pd.ids)
                mat = pd.getRawMatById(pd.ids(m));
                vel = TrajAnalysis2D.xy2vel(mat(:,2:3),1,0);
                diff(m,:) = [pd.ids(m),(max(vel)-mean(vel))/std(vel)];
            end
            ids = diff(diff(:,2)>threshold,1);
            if isShow
                figure;scatter(diff(:,1),diff(:,2),'filled');
                figure; histogram(diff(:,2));  
                figure;pd.plotTrace(axes,ids,1);
            end
        end
        
        function fixedMat = fixOutlierVel(oriMat,threshold,tolerance,isShow)
            L = size(oriMat,1);
            vel = TrajAnalysis2D.xy2vel(oriMat(:,2:3),1,1);
            if (max(vel)-mean(vel))/std(vel) >= threshold
                [~,I] = max(vel);
                if I<L*tolerance
                    fixedMat = oriMat(I:end,:);
                elseif I>(1-tolerance)*L  
                    fixedMat = oriMat(1:(I-1),:);
                else
                    fixedMat = oriMat;
                end
            else
                fixedMat = oriMat;
            end
            if isShow
                figure;
                plot(subplot(2,2,1),oriMat(:,1),vel);
                xlim([oriMat(1,1),oriMat(end,1)]);
                plot(subplot(2,2,2),oriMat(:,2),oriMat(:,3));
                plot(subplot(2,2,3),fixedMat(:,1),TrajAnalysis2D.xy2vel(fixedMat(:,2:3),1,1));
                xlim([oriMat(1,1),oriMat(end,1)]);
                plot(subplot(2,2,4),fixedMat(:,2),fixedMat(:,3));
            end
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
    end
end

