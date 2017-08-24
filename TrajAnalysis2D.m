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
    end
end

