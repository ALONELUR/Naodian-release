% Filename = "..\23-Apr-2019";
% Personname = "HMZ";
% Groupname = ["down1","left1",...
%     "right1","up1","horn1","stop1","downspeed1","upspeed1","random"];

Filename = "..\03-Apr-2019";
Personname = "WZT";
Groupname = ["down1","down2","left1",...
    "left2","right1","right2","up1","up2","random"];

% Filename = "..\01-May-2019";
% Personname = "YWH";
% Groupname = ["单目标","多目标（不带相位）","多目标（带相位）"];



COUNT = 1;
% ====================<Read Data>================================
for iP = 1:length(Personname)
    PersonReading = Filename + "\" +Personname(iP);
    for iG = 1:length(Groupname)
        GroupnReading = PersonReading + "\" + Groupname(iG) + "\";
        DataList = dir(GroupnReading + "*.mat");
        Label = zeros(1,length(Groupname)-1);
        if iG ~=length(Groupname)
            Label(iG) = 1;
        end
        for iN = 1:length(DataList)
            temp = load(string(DataList(iN).folder)+"\"+string(DataList(iN).name));
            DATA{COUNT}.group = Groupname(iG);
            DATA{COUNT}.label = Label;
            DATA{COUNT}.timedata = temp.timedata2';
            DATA{COUNT}.target = temp.data(1,:);
            DATA{COUNT}.predict = temp.data(2,:);
            COUNT = COUNT + 1;
        end
    end
end
% ====================<Read Data_END>============================