classdef ParData2D < handle
    %ParData2D Summary of this class goes here
    %   particle data container
    %   raw data should be in standard format n-by-4 matrix
    %   |particle_id|frame|x|y|
    
    properties
        ids;
    end
    
    properties(GetAccess = public, SetAccess = private)
        parCell;
        xRange;
        yRange;
    end
    
    properties(Dependent)
        particleNum;
        minTraceLength;
        totalTraceLength;
        frameRange;
    end
    
    methods
        % constrctor
        function obj = ParData2D(raw,padding)
            if nargin == 0
                [fn,fp,index] = uigetfile('*.csv','please select data file...');
                if index
                    raw = importdata(strcat(fp,fn));
                    raw = raw.data;
                else
                    return
                end
            end
            obj.ids = unique(raw(:,1));
            obj.parCell = cell(obj.particleNum,1);
            obj.xRange = [inf,-inf];
            obj.yRange = [inf,-inf];
            h = waitbar(0,'fixing dis-contunue trace...');
            totalBugNum = 0;
            for m = 1:1:obj.particleNum
                parTrace = raw(raw(:,1)==obj.ids(m),2:4);
                
                obj.xRange = [min(obj.xRange(1),min(parTrace(:,2))),...
                              max(obj.xRange(2),max(parTrace(:,2)))];
                obj.yRange = [min(obj.yRange(1),min(parTrace(:,3))),...
                              max(obj.yRange(2),max(parTrace(:,3)))];
                          
%                 a = size(parTrace,1);
                [bugNum,parTrace] = ParData2D.fixFrameDisContinue(parTrace,0);
%                 if bugNum > 1
%                     fprintf(1,'ID: %d - %d bugs - from %d to %d\n',obj.ids(m),bugNum,a,size(parTrace,1));
%                 end
                totalBugNum = totalBugNum + bugNum;
                waitbar(m/obj.particleNum,h,sprintf('fix %d bugs',totalBugNum));
                obj.parCell{m} = parTrace;             
            end
            close(h);
            
            if nargin ~= 2
                padding = 0;
            end
            
            fieldWidth = max(range(obj.xRange),range(obj.yRange)) + padding * 2;
            if range(obj.xRange) < fieldWidth
                tmp = mean(obj.xRange) - fieldWidth/2;
                obj.xRange = [tmp,tmp+fieldWidth];
            end
            if range(obj.yRange) < fieldWidth
                tmp = mean(obj.yRange) - fieldWidth/2;
                obj.yRange = [tmp,tmp+fieldWidth];
            end
        end
        
        function parNum = get.particleNum(obj)
            parNum = length(obj.ids);
        end
        
        function minTL = get.minTraceLength(obj)
            minTL = inf;
            for m = 1:1:obj.particleNum
                minTL = min(size(obj.parCell{m},1),minTL);
            end
        end
        
        function totTL = get.totalTraceLength(obj)
            totTL = 0;
            for m = 1:1:obj.particleNum
                totTL = totTL + size(obj.parCell{m},1);
            end
        end
        
        function mF = get.frameRange(obj)
            mF = [inf,-inf];
            for m = 1:1:obj.particleNum
                frames = obj.parCell{m}(:,1);
                mF = [min(mF(1),min(frames)),max(mF(2),max(frames))];
            end
        end
        
        function parMat = getRawMatById(obj,id,varargin)
            if isempty(varargin)
                colIndex = 1:1:3;
            else
                colIndex = varargin{1};
            end
            [~,I] = ismember(id,obj.ids);
            if I > 0
                parMat = obj.parCell{I}(:,colIndex);
            else
                fprintf(1,'Cannot find id: %d\n',id);
                parMat = [];
            end
        end
        
        function setDataById(obj,id,dataMat)
            [~,I] = ismember(id,obj.ids);
            if I > 0
                obj.parCell{I} = dataMat;
            else
                fprintf(1,'Cannot find id: %s\n',id);
            end
        end
        
        function plotTrace(obj,hAxes,ids,isLabel)
            labelOffset = 0.5;
            
            if nargin < 4
                isLabel = false;
            end
            
            if nargin < 3
                ids = obj.ids;
            end
            
            if nargin < 2
                hAxes = axes;
            end
            
            L = length(ids);
            
            for m = 1:1:L
                [~,I] = ismember(ids(m),obj.ids);
                if I > 0
                    xy = obj.parCell{I}(:,2:3);
                    h = plot(hAxes,xy(:,1),xy(:,2));
                    if isLabel
                        text(xy(1,1)+labelOffset,xy(1,2)+labelOffset,num2str(ids(m)),...
                            'Color',h.Color,'FontSize',8);
                    end
                    hAxes.NextPlot = 'add';
                else
                    fprintf(1,'Can not find particle ID: %d',ids(m));
                end
            end
            xlabel(hAxes,'X coord./\mum');ylabel(hAxes,'Y coord./\mum');
            title(hAxes,'Particle Trace');
            hAxes.NextPlot = 'replace'; box on;
            xlim(hAxes,[obj.xRange]);ylim([obj.yRange]);
        end
        
        function mat = getFixedMat(obj)
            mat = zeros(obj.totalTraceLength,4);
            pointer = 1;
            for m = 1:1:obj.particleNum
                id = obj.ids(m);
                data = obj.getRawMatById(id);
                L = size(data,1);
                mat(pointer:(pointer+L-1),:) = [ones(L,1)*id,data];
                pointer = pointer + L;
            end
        end
        
        function instance = copy(obj,ids,padding)
            raw = obj.getFixedMat();
            if ~isempty(ids)
                raw = raw(ismember(raw(:,1),ids),:);
            end
            if nargin < 3
                padding = 0;
            end
            instance = ParData2D(raw,padding);                
        end
        
        function delParticleById(obj,IDs)
            L = length(IDs);
            for m = 1:1:L
                [~,I] = ismember(IDs(m),obj.ids);
                if I > 0
                    obj.ids(I) = [];
                    obj.parCell(I) = [];
                else
                    fprintf(1,'Can not find particle ID: %d',IDs(m));
                end
            end
        end
        
        function indices = filterMatByFunc(obj,func,x)
            indices = nan(obj.particleNum,1);
            pointer = 1;
            for m = 1:1:obj.particleNum
                xy = obj.getRawMatById(obj.ids(m));
                if func(xy,x)
                    indices(pointer) = obj.ids(m);
                    pointer = pointer + 1;
                end
            end
            indices = indices(1:(pointer-1));
        end
        
        %region:[x_start,y_start,x_end,y_end]
        function indices = selectByRegion(obj,region)
            func = @(xy,region)ParData2D.isTrajInside(xy,region);
            indices = obj.filterMatByFunc(func,region);
        end
        
        function indices = selectByPolygan(obj,vx,vy)
            func = @(xy,v)all(inpolygon(xy(:,2),xy(:,3),v(:,1),v(:,2)));
            indices = obj.filterMatByFunc(func,[vx,vy]);
        end
    end
    
    methods(Access = private)
    end
    methods(Static)
        %|frame|x|y|
        function index = checkFrame(dataMat)
            [nRow,nCol] = size(dataMat);
            if nCol ~= 3
                disp('dataMat should in |frame|X|Y|');
            end
            index = 1:1:(nRow-1);
            index = index(dataMat(2:end,1) - dataMat(1:(end-1),1) ~= 1);
        end
        
        function [bugNum,fixedMat] = fixFrameDisContinue(dataMat,isDebug)
            bugIndices = ParData2D.checkFrame(dataMat);
            bugNum = length(bugIndices);
            while(~isempty(bugIndices))
                bugIndex = bugIndices(1);
                if bugIndex > 1
                    dataMat = [dataMat(1:(bugIndex-1),:);...
                               ParData2D.interpMat(dataMat(bugIndex:(bugIndex+1),:),isDebug);...
                               dataMat((bugIndex+2):end,:)];
                else
                    dataMat = [ParData2D.interpMat(dataMat(1:2,:),isDebug);...
                               dataMat(3:end,:)];
                end
                bugIndices = ParData2D.checkFrame(dataMat);
            end
            fixedMat = dataMat;
        end
        
        function res = interpMat(oriMat,isDebug)
            if isDebug
                disp('fix segment:');
                disp(oriMat);
            end
            startFrame = oriMat(1,1);
            endFrame = oriMat(2,1);
            interpMat = [(startFrame:1:endFrame)',zeros(endFrame-startFrame+1,2)];
            interpMat(:,2) = interp1(oriMat(:,1),oriMat(:,2),interpMat(:,1),'linear');
            interpMat(:,3) = interp1(oriMat(:,1),oriMat(:,3),interpMat(:,1),'linear');
            if isDebug       
                disp('to');
                disp(interpMat);
            end
            res = interpMat;
        end
        
        % region:[x_start,y_start,x_end,y_end]
        function boolRes = isTrajInside(mat,region)
            boolRes = and(all(min(mat(:,2:3))>=region(1:2)),all(max(mat(:,2:3))<=region(3:4)));
        end
    end 
end

