% /*============================
%     脑电典型相关性分析算�?(改写)
%     Author�? ALONELUR
%     Date: 25-3-19
% ===============================*/

function result = test_fbcca_YWH(data,y_ref,targ_fre,fs,fbs_num)
%test_fbcca_YWH - Description
%
% Syntax: result = test_fbcca_YWH(data,targ_fre,fs,harms_num,fbs_num)
%
% INPUT:    data: matrix(channels, samplenum)
% OUTPUT:   result:   vector(targets)
    targ_num = size(targ_fre,2);
    fb_coefs = (1:fbs_num).^(-1.25)+0.25;
    r = zeros(fbs_num, targ_num);

    for fb_i = 1:fbs_num
%         tempdata = filterbank(data, fs, fb_i);
        tempdata = data;
        for targ_i = 1:targ_num
            refdata = squeeze(y_ref(:,:,targ_i));
            [~,~,temp] = canoncorr(tempdata', refdata');
            r(fb_i,targ_i) = temp(1,1);
        end
    end

    result = fb_coefs * r;
end



