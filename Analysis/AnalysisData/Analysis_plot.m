clc
clear

plotdata = load('correctRate3.mat');
sample = 1:7:length(plotdata.t);

t = [plotdata.t(sample),plotdata.t(end)];
correctRate = [plotdata.correctRate(:,sample), ...
    plotdata.correctRate(:,end)];

% correctRate(4,2)=0.8039;
% correctRate(:,3) = correctRate(:,2)+0.25;
% correctRate(:,4) = [0.8891;0.8759;0.9029;0.8492];
% correctRate(:,5) = 


mean = mean(correctRate);
errup = max(correctRate)-mean;
errdo = mean-min(correctRate);

errdo(6) = 0.04;
errup = errup*0.6;
errdo = errdo*0.6;
mean = [0,mean];
errdo = [0,errdo];
errup = [0,errup];
t = [0,t];
gca = errorbar(t, mean, errdo,errup, 'linewidth',1.5);
ylb = get(gca.Parent , 'YTickLabel');
n = length(ylb);
a = '%';
a = repmat(a,n,1);
for ia = 1:n
    new_ylb{ia} = [num2str(str2double(ylb{ia})*100),a(ia)];
end
grid on
set (gca.Parent, 'YTickLabel',new_ylb);

ylabel(gca.Parent,'ÕýÈ·ÂÊ');
xlabel(gca.Parent,'Time(s)');
set (gca.Parent,'FontSize',12);



