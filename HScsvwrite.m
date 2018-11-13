function [] = HScsvwrite(fileName,M,strId,varargin)
    fid = fopen(fileName,'a');
    if isempty(strId)
        isStr = false;
    else
        isStr = true;
    end
    [R,L] = size(M);
    if ~isempty(varargin)
        header = varargin{1};
        fprintf(fid,[header,'\n']);
    end
    strLine = repStrline('%f,',L);
    if isStr
        idNum = size(strId,2);
        strFormat = repmat('%s,',idNum);
    end
    for m = 1:1:R
        if isStr
            fprintf(fid,strFormat,strId{m,:});
        end
        fprintf(fid,strLine,M(m,:));
    end
    fclose(fid);
end

function strline = repStrline(str,num)
    tmp = repmat(str,1,num);
    strline = [tmp(1:end-1),'\n'];
end

    

