function [] = HScsvwrite(fileName,M,varargin)
    fid = fopen(fileName,'a');
    [R,L] = size(M);
    if ~isempty(varargin)
        header = varargin{1};
        fprintf(fid,[header,'\n']);
    end
    strLine = repStrline('%f,',L);
    for m = 1:1:R
        fprintf(fid,strLine,M(m,:));
    end
    fclose(fid);
end

function strline = repStrline(str,num)
    tmp = repmat(str,1,num);
    strline = [tmp(1:end-1),'\n'];
end

    

