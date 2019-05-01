axe1=plot(fre,cca(1,:),fre,cca(2,:),'LineWidth',1.5);
grid on
legend('干电极','湿电极')
xlabel('标准信号频率(Hz)')
ylabel('标准信号频率(Hz)')
ylabel('FBCCA相关系数')
set(axe1(1).Parent,'FontSize',12)
