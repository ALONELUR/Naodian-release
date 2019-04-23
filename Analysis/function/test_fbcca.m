% /*============================
%     脑电典型相关性分析算�?(改写)
%     Author�? ALONELUR
%     Date: 25-3-19
% ===============================*/

function result = test_fbcca(data,y_ref,targ_fre,fs,fbs_num,chs_fre)
%test_fbcca - Description
%
% Syntax: result = test_fbcca(data,targ_fre,fs,harms_num,fbs_num,chs_fre)
%
% INPUT:    data: matrix(channels, samplenum) , che_fre：vector
% OUTPUT:   result: matrix(choosenChannels,targets)
    targ_num = size(targ_fre,2);
    fb_coefs = (1:fbs_num).^(-1.25)+0.25;

    r = zeros(fbs_num, targ_num);

    chs_num = size(chs_fre,2);
    
    result=zeros(chs_num,targ_num);
    for chs_i = 1:chs_num
        for fb_i = 1:fbs_num
            tempdata = filterbank(data(chs_i,:), fs, fb_i);
            for targ_i = 1:targ_num
                refdata = squeeze(y_ref(:,:,targ_i));
                [~,~,temp] = canoncorr(tempdata', refdata');
                r(fb_i,targ_i) = temp(1,1);
            end
        end
        result(chs_i,:) = fb_coefs * r;
    end

    
end