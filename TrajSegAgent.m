classdef TrajSegAgent < handle
    %TrajSegAgent Trajectory Segment Agent
    
    properties(GetAccess = public, SetAccess = private)
        traj;
        aveVel;
        dir;
        msdCurve;
        alpha;
        D;
        aysm;
        Smss;
        gridPos;
        frame;
        deltaT;
        lag;
        maxP;
    end
    
    properties(Dependent)
        segLength;
    end
    
    methods
        function obj = TrajSegAgent(seg,frame,gridPos,deltaT,varargin)
            obj.traj = seg;
            obj.frame = frame;
            obj.gridPos = gridPos;
            obj.deltaT = deltaT;
            if isempty(varargin)
                obj.lag = min(20,floor(obj.segLength/2)); obj.maxP = 6;
            elseif nargin == 5
                obj.maxP = varargin{1}; obj.lag = min(20,floor(obj.segLength/3));
            elseif nargin == 6
                obj.maxP = varargin{1}; obj.lag = varargin{2};
            end
        end
        
        function sL = get.segLength(obj)
            sL = size(obj.traj,1);
        end
        
        function calSelf(obj)
            obj.aveVel = mean(TrajAnalysis2D.xy2vel(obj.traj,obj.deltaT,0));
            obj.dir = obj.traj(end,:) - obj.traj(1,:);
            if obj.segLength > 6           
                obj.msdCurve = [eps,TrajAnalysis2D.xy2msd(obj.traj,obj.lag,2)];
                t = [eps,(1:1:obj.lag)*obj.deltaT];
                [obj.alpha,obj.D] = TrajAnalysis2D.fitMSDCurve(t,obj.msdCurve,0);
                %obj.Smss = TrajAnalysis2D.xy2mss(seg,obj.lag,obj.maxP,0);  
            else
                obj.msdCurve = nan;
                obj.alpha = nan;
                obj.D = nan;
                obj.Smss = nan;
            end
            
            if obj.segLength > 3
                obj.aysm = TrajAnalysis2D.xy2asym(obj.traj);
            else
                obj.aysm = nan;
            end
        end
    end
    
end

