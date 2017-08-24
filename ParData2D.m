classdef ParData2D < handle
    %ParData2D Summary of this class goes here
    %   particle data container
    %   raw data should be in standard format n-by-4 matrix
    %   |particle_id|frame|x|y|
    
    properties
        ids;
    end
    
    properties(Access = private)
        parCell;
        xRange;
        yRange;
    end
    
    properties(Dependent)
        particleNum;
        minTraceLength;
        totalTraceLength;
    end
    
    methods
        % constrctor
        function obj = ParData2D(raw)
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
            obj.xRange = 0;
            obj.yRange = 0;
            h = waitbar(0,'fixing dis-contunue trace...');
            totalBugNum = 0;
            for m = 1:1:obj.particleNum
                parTrace = raw(raw(:,1)==obj.ids(m),2:4);
                
                obj.xRange = max(obj.xRange,max(parTrace(:,2)));
                obj.yRange = max(obj.yRange,max(parTrace(:,3)));
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
            obj.xRange = max(obj.xRange,obj.yRange);
            obj.yRange = obj.xRange;
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
                fprintf(1,'Cannot find id: %s\n',id);
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
            
            hAxes.NextPlot = 'add';
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
                end
            end
            xlabel('X coord./\mum');ylabel('Y coord./\mum');
            title('Particle Trace');
            hold off; box on;
            xlim([0,obj.xRange]);ylim([0,obj.yRange]);
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
        
        function instance = copy(obj)
            raw = obj.getFixedMat();
            instance = ParData2D(raw);
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
    end
    
end

