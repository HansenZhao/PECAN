classdef ModelViewer < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        currentStep;
    end

    properties(GetAccess = public, SetAccess = private)
        filePath;
        model;
        modelClass;
        pd;
        pa;
        hViewer
        plotSetting;
        playSetting;
        modelAgentFrames;
        subModel;
        valueCPs;
        currentMat;
    end

    properties(Dependent)
        frameRange;
        isPlayValid;
    end

    properties(Access = private)
        modelSetting;
        preprocessingSetting;
        sliceRegion;
    end

    methods
        function obj = ModelViewer(pd)
            obj.hViewer = viewer(obj);
            obj.preprocessingSetting = struct();
            obj.setInfoText('Welcome to model viewer');
            obj.sliceRegion = [];
            obj.plotSetting = struct();
            obj.playSetting = struct();
            obj.currentStep = [];
            obj.modelAgentFrames = [];
            obj.valueCPs = {ValueCP(obj.hViewer.plot_axes_1),ValueCP(obj.hViewer.plot_axes_2)};
            if nargin > 0
                obj.pd = pd;
            else
                obj.pd = [];
            end
        end

        function fr = get.frameRange(obj)
            fr = obj.model.pd.frameRange;
        end

        function b = get.isPlayValid(obj)
            b = length(fieldnames(obj.playSetting))==2;
        end

        function setInfoText(obj,str)
            obj.hViewer.txt_info.String = str;
            drawnow;
        end

        function boolRes = setModel(obj,modelName,varargin)
            if nargin == 2
                mannualSet = 1;
            else
                mannualSet = 0;
            end
            obj.modelClass = modelName;
            if strcmp(obj.modelClass,'Point Based Model')
                if mannualSet
                    prompt = {'delta t(s):','window half length:'};
                    dlg_title = 'PBM';
                    num_lines = 1;
                    defaultAns = {'0.1','5'};
                    obj.modelSetting = inputdlg(prompt,dlg_title,num_lines,defaultAns);
                else
                    obj.modelSetting = varargin;
                end
                if isempty(obj.modelSetting)
                    boolRes = 0;
                    return;
                end
            elseif strcmp(obj.modelClass,'Grid Based Model')
                if mannualSet
                    prompt = {'delta t(s):','resolution(um)','minSegLength:','segTolerance:'};
                    dlg_title = 'GBM';
                    num_lines = 1;
                    defaultAns = {'0.1','0.5','6','1'};
                    obj.modelSetting = inputdlg(prompt,dlg_title,num_lines,defaultAns);
                else
                    obj.modelSetting = varargin;
                end
                if isempty(obj.modelSetting)
                    boolRes = 0;
                    return;
                end
            end
            boolRes = 1;
            if ~isempty(obj.pd)
                obj.pd.plotTrace(obj.hViewer.main_axes,obj.pd.ids,0);
                if strcmp(obj.modelClass,'Point Based Model')
                    obj.model = PointBasedModel(obj.pd,str2double(obj.modelSetting{1}),...
                        str2double(obj.modelSetting{2}));
                elseif strcmp(obj.modelClass,'Grid Based Model')
                    obj.model = GridBasedModel(obj.pd,str2double(obj.modelSetting{1}),...
                        str2double(obj.modelSetting{2}),...
                        str2double(obj.modelSetting{3}),...
                        str2double(obj.modelSetting{4}));
                end
                obj.hViewer.btn_clear.Enable = 'on';
                obj.hViewer.edt_region.Enable = 'on';
                obj.hViewer.btn_slice.Enable = 'on';
                obj.hViewer.btn_confirm.Enable = 'on';
                obj.hViewer.btn_polygen.Enable = 'on';
            end
        end

        function boolRes = onLoad(obj,isDefault,varargin)
            if nargin == 1
                isDefault = 0;
            end
            if isempty(varargin)
                [fn,fp,index] = uigetfile('*.csv','please select data file...');
                if index
                    obj.filePath = strcat(fp,fn);
                end
            else
                obj.filePath = varargin{1};
            end
            obj.setInfoText(sprintf('Reading: %s...',obj.filePath));
            raw = importdata(obj.filePath);
            if isstruct(raw)
                raw = raw.data;
            end
            try
                if isDefault
                    obj.preprocessingSetting.padding = 0;
                else
                    inAns = inputdlg('Padding(um):','Loading...',1,{'0'});
                    obj.preprocessingSetting.padding = str2double(inAns{1});
                end
                obj.setInfoText('Parsing data...');
                obj.pd = ParData2D(raw,obj.preprocessingSetting.padding);
                obj.pa = TrajAnalysis2D(obj.pd,str2double(obj.modelSetting{1}));
                
                if isDefault
                    obj.preprocessingSetting.zerosThres = 0.7;
                else
                    inAns = inputdlg('tolerance:','Zero filter',1,{'0.7'});
                    obj.preprocessingSetting.zerosThres = str2double(inAns{1});
                end
                obj.setInfoText('Filter out zero velocity...');
                obj.pa.filterZeroVel(obj.preprocessingSetting.zerosThres);
                
                if isDefault
                    obj.preprocessingSetting.outlierThres = 8.5;
                    obj.preprocessingSetting.outlierToler = 0.5;
                    obj.preprocessingSetting.outlierIter = 20;
                else
                    inAns = inputdlg({'threshold:','tolerance:','iterTime:'},...
                        'Outlier filter',1,{'9','0.5','20'});
                    obj.preprocessingSetting.outlierThres = str2double(inAns{1});
                    obj.preprocessingSetting.outlierToler = str2double(inAns{2});
                    obj.preprocessingSetting.outlierIter = str2double(inAns{3});
                end
                obj.setInfoText('Filter out outlier velocity...');
                obj.pa.filterOutlierVel(obj.preprocessingSetting.outlierThres,...
                    obj.preprocessingSetting.outlierToler,...
                    0,obj.preprocessingSetting.outlierIter);
                
                obj.setInfoText('Load Done!');
                
                obj.hViewer.txt_frame.String = sprintf('%d : %d',...
                    obj.pd.frameRange(1),...
                    obj.pd.frameRange(2));
                
                obj.setInfoText('Paring to model...');
                if strcmp(obj.modelClass,'Point Based Model')
                    obj.model = PointBasedModel(obj.pd,str2double(obj.modelSetting{1}),...
                        str2double(obj.modelSetting{2}));
                elseif strcmp(obj.modelClass,'Grid Based Model')
                    obj.model = GridBasedModel(obj.pd,str2double(obj.modelSetting{1}),...
                        str2double(obj.modelSetting{2}),...
                        str2double(obj.modelSetting{3}),...
                        str2double(obj.modelSetting{4}));
                end
                
                obj.setInfoText('Drawing Overview...');
                obj.pd.plotTrace(obj.hViewer.main_axes,obj.pd.ids,0);
                boolRes = 1;
                return;
            catch e
                throw(e);
            end
            boolRes = 0;
        end

        function onClear(obj)
            obj.preprocessingSetting = struct();
            obj.modelSetting = struct();
            obj.pd = [];
            obj.pd = [];
            obj.model = [];
            obj.modelClass = [];
            for m = 1:1:length(obj.valueCPs)
                obj.valueCPs{m}.clear;
            end
        end

        function boolRes = onSliceEdit(obj,str)
            try
                number = strsplit(str,' ');
                obj.sliceRegion = [str2double(number{1}),str2double(number{2}),...
                                   str2double(number{3}),str2double(number{4})];
                boolRes = 1;
            catch
                boolRes = 0;
            end
        end

        function boolRes = onPolygonSlice(obj,inStruct)
            xR = xlim(obj.hViewer.main_axes);
            yR = ylim(obj.hViewer.main_axes);
            if nargin == 2 && isstruct(inStruct)
                [x,y,xi,yi] = deal(inStruct.x,inStruct.y,inStruct.xi,inStruct.yi);
            else
                im = getframe(obj.hViewer.main_axes);
                hf = figure;
                [x,y,~,xi,yi] = roipoly(im.cdata);
                try
                    close(hf);
                catch
                    boolRes = 0;
                    return;
                end
            end          
            yi = sum(y) - yi; %axis direction
            xi = xR(1)+range(xR)*(xi - x(1))./range(x);
            yi = yR(1)+range(yR)*(yi-y(1))./range(y);
            obj.sliceRegion = [min([xi,yi]),max([xi,yi])];
            try
                if nargin == 2
                    outAns = {'10000'};
                else
                    outAns = inputdlg('estimate capacity:','Model Parse',1,{'1000'});
                end
                obj.pd = obj.pd.copy(obj.pd.selectByPolygan(xi,yi));
                obj.updatePAModel();
                obj.onRefresh();
                obj.model.parse(str2double(outAns{1}));
                obj.subModel = obj.model.childModel();
                boolRes = 1;
            catch e
                throw(e);
            end
        end

        function onSlice(obj)
            if isempty(obj.sliceRegion)
                return;
            end
            xlim(obj.hViewer.main_axes,obj.sliceRegion([1,3]));
            ylim(obj.hViewer.main_axes,obj.sliceRegion([2,4]));
        end

        function boolRes = onFieldNameSet(obj,str)
            try
                if isfield(obj.plotSetting,'fieldName')
                    obj.plotSetting.fieldName = str;
                    obj.onRefresh();
                else
                    obj.plotSetting.fieldName = str;
                end
                boolRes = 1;
            catch
                boolRes = 0;
            end
        end

        function boolRes = onMethodSet(obj,str)
            if strcmp(str,'None')
                try
                    obj.plotSetting = rmfield(obj.plotSetting,'method');
                    return;
                catch
                end
            end
            try
                if isfield(obj.plotSetting,'method')
                    obj.plotSetting.method = str;
                    obj.onRefresh();
                else
                    obj.plotSetting.method = str;
                end
                boolRes = 1;
            catch
                boolRes = 0;
            end
        end

        function boolRes = onStepNumberSet(obj,num)
            tmp = str2double(num);
            if isnan(tmp)
                boolRes = 0;
                obj.hViewer.btn_save.Enable = 'off';
                obj.hViewer.rd_isImages.Enable = 'off';
                obj.hViewer.rd_isAVI.Enable = 'off';
                obj.hViewer.rd_raw.Enable = 'off';
                obj.hViewer.rb_qRaw.Enable = 'off';
                return;
            end
            obj.playSetting.stepNum = tmp;
            if obj.isPlayValid
                obj.hViewer.btn_save.Enable = 'on';
                obj.hViewer.rd_isImages.Enable = 'on';
                obj.hViewer.rd_isAVI.Enable = 'on';
                obj.hViewer.rd_raw.Enable = 'on';
                obj.hViewer.rb_qRaw.Enable = 'on';
            end
            boolRes = 1;
        end

        function boolRes = onInterval(obj,str)
            tmp = str2double(str);
            if isnan(tmp)
                boolRes = 0;
                obj.hViewer.btn_save.Enable = 'off';
                obj.hViewer.rd_isImages.Enable = 'off';
                obj.hViewer.rd_isAVI.Enable = 'off';
                obj.hViewer.rd_raw.Enable = 'off';
                obj.hViewer.rb_qRaw.Enable = 'off';
                return;
            end
            if obj.isPlayValid
                obj.hViewer.btn_save.Enable = 'on';
                obj.hViewer.rd_isImages.Enable = 'on';
                obj.hViewer.rd_isAVI.Enable = 'on';
                obj.hViewer.rd_raw.Enable = 'on';
                obj.hViewer.rb_qRaw.Enable = 'on';
            end
            obj.playSetting.interval = tmp;
            boolRes = 1;
        end

        function boolRes = onClimSet(obj,clim)
          str = strsplit(clim,' ');
          try
              if isfield(obj.plotSetting,'clim')
                  obj.plotSetting.clim = [str2double(str{1}),str2double(str{2})];
                  obj.onRefresh;
              else
                  obj.plotSetting.clim = [str2double(str{1}),str2double(str{2})];
              end
              boolRes = 1;
          catch
              boolRes = 0;
          end
        end

        function boolRes = onInterpSet(obj,interp)
          try
              if isfield(obj.plotSetting,'interp')
                  obj.plotSetting.interp = str2double(interp);
                  obj.onRefresh();
              else
                  obj.plotSetting.interp = str2double(interp);
              end
              boolRes = 1;
          catch
              boolRes = 0;
          end
        end

        function imMat = onRefresh(obj)
            L = length(fieldnames(obj.plotSetting));
            obj.setInfoText('Begin Drawing...');
            if strcmp(obj.modelClass,'Point Based Model')
                if L==5
                    imMat = obj.subModel.spatialPlot(obj.hViewer.main_axes,obj.plotSetting.resolution,...
                        obj.plotSetting.fieldName,obj.plotSetting.method,obj.plotSetting.interp,...
                        obj.plotSetting.clim);
                else
                    imMat = [];
                    obj.pd.plotTrace(obj.hViewer.main_axes,obj.pd.ids);
                end
            elseif strcmp(obj.modelClass,'Grid Based Model')
                if L==4
                    imMat = obj.subModel.spatialPlot(obj.hViewer.main_axes,obj.plotSetting.fieldName,...
                        obj.plotSetting.method,obj.plotSetting.interp,obj.plotSetting.clim);
                else
                    imMat = [];
                    obj.pd.plotTrace(obj.hViewer.main_axes,obj.pd.ids);
                end
            end
            obj.currentMat = imMat;
            obj.hViewer.txt_info.String = 'Drawing done';
        end

        function boolRes = onResSet(obj,res)
          try
              if isfield(obj.plotSetting,'resolution')
                  obj.plotSetting.resolution = str2double(res);
                  obj.onRefresh();
              else
                  obj.plotSetting.resolution = str2double(res);
              end
              boolRes = 1;
          catch
            boolRes = 0;
          end
        end

        function updatePAModel(obj)
          obj.pa = TrajAnalysis2D(obj.pd,str2double(obj.modelSetting{1}));
          if strcmp(obj.modelClass,'Point Based Model')
              obj.model = PointBasedModel(obj.pd,str2double(obj.modelSetting{1}),...
                                                 str2double(obj.modelSetting{2}));
          elseif strcmp(obj.modelClass,'Grid Based Model')
              obj.model = GridBasedModel(obj.pd,str2double(obj.modelSetting{1}),...
                                                str2double(obj.modelSetting{2}),...
                                                str2double(obj.modelSetting{3}),...
                                                str2double(obj.modelSetting{4}));
          end
        end

        function boolRes = onConfirm(obj,varargin)
            try
                if nargin == 1
                    outAns = inputdlg('estimate capacity:','Model Parse',1,{'1000'});
                else
                    outAns = varargin;
                end
                if ~isempty(obj.sliceRegion)
                    obj.pd = obj.pd.copy(obj.pd.selectByRegion(obj.sliceRegion));
                    obj.updatePAModel();
                end
                obj.onRefresh();
                obj.model.parse(str2double(outAns{1}));
                obj.subModel = obj.model.childModel();
                boolRes = 1;
            catch e
                throw(e);
            end
        end

        function onNext(obj,isRefresh)
            if nargin == 1
                isRefresh = 1;
            end
            if obj.isPlayValid
                if isempty(obj.currentStep)
                    obj.currentStep = [obj.frameRange(1),obj.frameRange(1)+obj.playSetting.stepNum];
                else
                    if range(obj.currentStep) ~= obj.playSetting.stepNum
                        obj.currentStep = [obj.currentStep(1),obj.currentStep(1)+obj.playSetting.stepNum];
                    else
                        obj.currentStep = obj.currentStep + obj.playSetting.interval;
                    end
                end
                if obj.currentStep(2) > obj.frameRange(2)
                    obj.currentStep = [obj.frameRange(1),obj.frameRange(1)+obj.playSetting.stepNum];
                    try
                        obj.valueCPs{1}.clear();
                        obj.valueCPs{2}.clear();
                    catch
                    end
                end
                obj.hViewer.txt_current.String = sprintf('%d to %d',obj.currentStep(:));
                obj.updateSubModel();
                if isRefresh
                    obj.onRefresh();
                end
            end
        end

        function onLast(obj)
            if obj.isPlayValid
                if isempty(obj.currentStep)
                    obj.currentStep = [obj.frameRange(1),obj.frameRange(1)+obj.playSetting.stepNum];
                else
                    if range(obj.currentStep) ~= obj.playSetting.stepNum
                        obj.currentStep = [obj.currentStep(1),obj.currentStep(1)+obj.playSetting.stepNum];
                    else
                        obj.currentStep = obj.currentStep - obj.playSetting.interval;
                    end
                end
                if obj.currentStep(1) < obj.frameRange(1)
                    obj.currentStep = [obj.frameRange(2)-obj.playSetting.stepNum,obj.frameRange(2)];
                    try
                        obj.valueCPs{1}.clear();
                        obj.valueCPs{2}.clear();
                    catch
                    end
                end
                obj.hViewer.txt_current.String = sprintf('%d to %d',obj.currentStep(:));
                obj.updateSubModel();
                obj.onRefresh();
            end
        end

        function onPlot(obj,id,bCommand)
            obj.valueCPs{id}.enable = bCommand;
        end

        function boolRes = onJump(obj,str,isRefresh)
            if nargin == 2
                isRefresh = 1;
            end
            try
                n = str2double(str);
                tmp = obj.currentStep;
                obj.currentStep = [n,n+obj.playSetting.stepNum];
                if n < obj.frameRange(1) || obj.currentStep(2) > obj.frameRange(2)
                    obj.currentStep = tmp;
                    boolRes = 0;
                    return;
                else
                    obj.hViewer.txt_current.String = sprintf('%d to %d',obj.currentStep(:));
                    for m = 1:1:length(obj.valueCPs)
                        obj.valueCPs{m}.clear(n);
                    end
                    obj.updateSubModel();
                    if isRefresh
                        obj.onRefresh();
                    end
                end
                boolRes = 1;
            catch
                boolRes = 0;
            end
        end

        function onPopName(obj,id,str)
            obj.valueCPs{id}.vName = str;
            if obj.valueCPs{id}.isValid
                obj.valueCPs{id}.vPlot();
            end
        end

        function onPopStyle(obj,id,str)
            obj.valueCPs{id}.setStyle(str);
            if obj.valueCPs{id}.isValid
                obj.valueCPs{id}.vPlot();
            end
        end

        function onSave(obj,varargin)
            tic
            frames = obj.frameRange(1):obj.playSetting.interval:(obj.frameRange(2)-obj.playSetting.stepNum);
            if obj.hViewer.rd_isImages.Value && obj.isPlayValid
                if isempty(obj.currentStep)
                    obj.currentStep = [frames(1),frames(1)+obj.playSetting.stepNum];
                end
                if nargin == 1
                    [fn,fp,index] = uiputfile('*.tif');
                    fn = strsplit(fn,'.');
                    fn = fn{1};
                else
                    fp = varargin{1};
                    fn = varargin{2};
                    index = 1;
                end
                if index
                    obj.onJump(num2str(obj.frameRange(1)));
                    for m = frames
                        obj.hViewer.txt_info.String = sprintf('%d/%d',m,frames(end));
                        fig = getframe(obj.hViewer.figure1);
                        imwrite(fig.cdata,GlobalConfig.cmap,sprintf('%s%s%04d.tif',fp,fn,m));
                        obj.onNext();
                    end
                    obj.hViewer.txt_info.String = 'Saving Done';
                else
                    return;
                end
            elseif obj.hViewer.rd_isAVI.Value && obj.isPlayValid
                if isempty(obj.currentStep)
                    obj.currentStep = [frames(1),frames(1)+obj.playSetting.stepNum];
                end
                if nargin == 1
                    [fn,fp,index] = uiputfile('*.avi');
                else
                    fp = varargin{1};
                    fn = varargin{2};
                    index = 1;
                end
                if index
                    if nargin == 1
                        Ans = inputdlg({'frame rate:','quality:'},'AVI setting',1,{'30','100'});
                    else
                        Ans = {'30','100'};
                    end
                    aviObj = VideoWriter(strcat(fp,fn));
                    aviObj.FrameRate = str2double(Ans{1});
                    aviObj.Quality = str2double(Ans{2});
                    open(aviObj);
                    obj.onJump(num2str(obj.frameRange(1)));
                    for m = frames
                        obj.hViewer.txt_info.String = sprintf('%d/%d',m,frames(end));
                        writeVideo(aviObj,getframe(obj.hViewer.figure1));
                        obj.onNext();
                    end
                    close(aviObj);
                    obj.hViewer.txt_info.String = 'Saving Done';
                else
                    return;
                end
            elseif (obj.hViewer.rd_raw.Value || obj.hViewer.rb_qRaw.Value) && obj.isPlayValid        
                if isempty(obj.currentStep)
                    obj.currentStep = [frames(1),frames(1)+obj.playSetting.stepNum];
                end
                fNames = {'frame','count','aveVel','D','alpha','asym','mean_dir_change','x','y','dir_x','dir_y','n_dir_x','n_dir_y'};
                propID = [AgentProp.AVE_VEL,AgentProp.D,AgentProp.ALPHA,AgentProp.ASYM,AgentProp.MEAN_DIR_C,AgentProp.X,AgentProp.Y,...
                    AgentProp.DIR_X,AgentProp.DIR_Y,AgentProp.N_DIR_X,AgentProp.N_DIR_Y];
                stasticMat = zeros(length(frames),length(fNames));
                
                if nargin == 1
                    [fn,fp,index] = uiputfile();
                else
                    fp = varargin{1};
                    fn = varargin{2};
                    index = 1;
                end
                  
                if index
                    fn = strsplit(fn,'.');
                    fn = fn{1};
                    if nargin == 1
                        funcAns = inputdlg({'input func','out format'},'save',1,{'@(x)mean(x,''omitnan'')','image'});
                    else
                        funcAns = {'@(x)mean(x,''omitnan'')','txt'};
                    end
                    func = str2func(funcAns{1});
                    if strcmp(funcAns{2},'txt')
                        isTxt = 1;
                    else
                        isTxt = 0;
                    end
                    obj.onJump(num2str(obj.frameRange(1)),obj.hViewer.rd_raw.Value);
                    I = 1;
                    if obj.hViewer.rd_raw.Value || isTxt
                        rawImgMat = zeros(length(frames),length(obj.currentMat(:)));
                    end
                    for m = frames
                        if obj.hViewer.rd_raw.Value
                            if isTxt
                                rawImgMat(I,:) = obj.currentMat(:)';
                            else
                                fig = getframe(obj.hViewer.main_axes);
                                imwrite(fig.cdata,GlobalConfig.cmap,sprintf('%s%s%04d.tif',fp,fn,m));
                            end
                        end
                        obj.setInfoText(sprintf('%d/%d',m,frames(end)));
                        stasticMat(I,1) = m; stasticMat(I,2) = length(obj.subModel.getProp(AgentProp.FRAME));
                        if stasticMat(I,2) > 0
                            for k = 3:length(fNames)
                                vec = obj.subModel.getProp(propID(k-2));
                                stasticMat(I,k) = func(vec);
                            end
                        end
                        I = I + 1;
                        obj.onNext(obj.hViewer.rd_raw.Value);
                    end
                    
                    headerFormat = repmat('%s,',1,length(fNames));
                    headerFormat(end) = [];
                    header = sprintf(headerFormat,fNames{:});
                    HScsvwrite(sprintf('%s%s.csv',fp,fn),stasticMat,header);
                    
                    if isTxt
                        csvwrite(sprintf('%s%s-rawImg.csv',fp,fn),rawImgMat);
                    end
                    
                    obj.hViewer.txt_info.String = 'Saving Done';
                end
            end
            obj.saveConfig(sprintf('%s%s.pecan',fp,fn));
            obj.hViewer.txt_info.String = sprintf('Process done with %.2f seconds',toc);
        end

        function hf = onCopyMain(obj,varargin)
            hf = figure;
            if nargin > 1
                hf.Position = varargin{1};
            end
            element = obj.hViewer.main_axes.Children;
            L = length(element);
            if L > 1
                ha = axes; hold on; box on;
                xr = xlim(obj.hViewer.main_axes);
                yr = ylim(obj.hViewer.main_axes);
                for m = 1:1:L
                    plot(ha,element(m).XData,element(m).YData);
                end
                xlim(ha,xr); ylim(ha,yr);
            else
                ha = axes;
                imagesc(ha,element.CData,'AlphaData',element.AlphaData); colormap(GlobalConfig.cmap);
                ha.CLim = obj.hViewer.main_axes.CLim;
                colorbar;
                ha.YDir = 'normal';
                axis off;
            end
        end

        function hf = onCopy1(obj,varargin)
            hf = figure;
            if nargin > 1
                hf.Position = varargin{1};
            end
            element = obj.hViewer.plot_axes_1.Children;
            if length(element) == 1
                plot(element.XData,element.YData);
            end
        end

        function hf = onCopy2(obj,varargin)
            hf = figure;
            if nargin > 1
                hf.Position = varargin{1};
            end
            element = obj.hViewer.plot_axes_2.Children;
            if length(element) == 1
                plot(element.XData,element.YData);
            end
        end
    end

    methods(Access = private)
        function updateSubModel(obj)
            if isempty(obj.modelAgentFrames)
              obj.modelAgentFrames = obj.model.getProp(AgentProp.FRAME);
            end
            ids = 1:1:obj.model.agentNum;
            ids = ids(and(obj.modelAgentFrames>=obj.currentStep(1),...
                          obj.modelAgentFrames<=obj.currentStep(2)));
            obj.subModel = obj.model.childModel(ids);
            for m = 1:1:length(obj.valueCPs)
                if obj.valueCPs{m}.isValid
                    obj.valueCPs{m}.addValue(obj.currentStep(1),obj.subModel.getProp(obj.valueCPs{m}.vName));
                    obj.valueCPs{m}.vPlot();
                end
            end
        end

        function saveConfig(obj,fileName)
            fid = fopen(fileName,'a');
            fprintf(fid,'%s\n',obj.filePath);
            fprintf(fid,'==========Model Setting==========\n');
            fprintf(fid,'Model: %s\n',obj.modelClass);
            fprintf(fid,'Delta Time: %s\n',obj.modelSetting{1});
            if strcmp(obj.modelClass,'Point Based Model')
                fprintf(fid,'Half Window Length: %s\n',obj.modelSetting{2});
            elseif strcmp(obj.modelClass,'Grid Based Model')
                fprintf(fid,'Resolution: %s\n',obj.ModelSetting{2});
                fprintf(fid,'Min Segment Length: %s\n',obj.modelSetting{3});
                fprintf(fid,'Segment Tolerance: %s\n',obj.modelSetting{4});
            end
            fprintf(fid,'==========plot Setting==========\n');
            fprintf(fid,'Field Name: %s\n',obj.plotSetting.fieldName);
            fprintf(fid,'Method: %s\n',obj.plotSetting.method);
            if strcmp(obj.modelClass,'Point Based Model')
                fprintf(fid,'Resolution: %.2f\n',obj.plotSetting.resolution);
            end
            fprintf(fid,'Interp: %d\n',obj.plotSetting.interp);
            fprintf(fid,'clim: [%.2f,%.2f]\n',obj.plotSetting.clim(:));
            fprintf(fid,'Slice Region: [%.2f,%.2f,%.2f,%.2f]\n',obj.sliceRegion(:));
            fprintf(fid,'==========play Setting==========\n');
            fprintf(fid,'Step Number: %d\n',obj.playSetting.stepNum);
            fprintf(fid,'Interval: %d\n',obj.playSetting.interval);
            fclose(fid);
        end
    end

end
