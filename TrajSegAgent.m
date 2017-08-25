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
    end
    
    methods
        function obj = TrajSegAgent(seg,frame,gridPos,deltaT,varargin)
            if isempty(varargin)
                lag = 20; maxP = 6;
            elseif nargin == 5
                lag = varargin{1}; maxP = 6;
            elseif nargin == 6
                lag = varargin{1}; maxP = varargin{2};
            end
            obj.traj = seg;
            obj.frame = frame;
            obj.gridPos = gridPos;
            obj.deltaT = deltaT;
            obj.aveVel = mean(TrajAnalysis2D.xy2vel(seg,obj.deltaT,0));
            obj.dir = seg(end,:) - seg(1,:);
            obj.msdCurve = [eps,TrajAnalysis2D.xy2msd(seg,lag,2)];
            t = [eps,(1:1:lag)*obj.deltaT];
            [obj.alpha,obj.D] = TrajAnalysis2D.fitMSDCurve(t,obj.msdCurve,0);
            obj.Smss = TrajAnalysis2D.xy2mss(seg,lag,maxP,0);  
            obj.aysm = TrajAnalysis2D.xy2asym(seg);
        end
    end
    
end

