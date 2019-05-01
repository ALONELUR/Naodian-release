Filename = "..\03-Apr-2019";
Personname = "WZT";
Groupname = ["down1","down2","left1",...
    "left2","right1","right2","up1","up2"];


COUNT = 1;
% ====================<Read Data>================================
for iP = 1:length(Personname)
    PersonReading = Filename + "\" +Personname(iP);
    for iG = 1:length(Groupname)
        GroupnReading = PersonReading + "\" + Groupname(iG) + "\";
        DataList = dir(GroupnReading + "*.mat");
        temp = char(Groupname(iG));
        temp2 = length(temp);
        if temp2 == 3
            Label = [1,0,0,0];
        elseif temp2 == 6
            Label = [0,1,0,0];
        elseif strcmp('down',temp(1:4))
            Label = [0,0,1,0];
        elseif strcmp('left',temp(1:4))
            Label = [0,0,0,1];
        end
        for iN = 1:length(DataList)
            temp = load(string(DataList(iN).folder)+"\"+string(DataList(iN).name));
            DATA{COUNT}.label = Label;
            DATA{COUNT}.timedata = temp.timedata2';
            DATA{COUNT}.target = temp.data(1,:);
            DATA{COUNT}.predict = temp.data(2,:);
            COUNT = COUNT + 1;
        end
    end
end
% ====================<Read Data_END>============================