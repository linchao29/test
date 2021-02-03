%**************************************************************************
%                                             Matlab STK���Ϸ���
%                                                      COM��ʽ
%                                                 ��������������
%
%**************************************************************************
clc
clear all
disp('��STK���򣬴���һ������');

%============================����STK����������==============================
try
    uiapp = actxGetRunningServer('STK11.application'); % ��ȡ�����е�STKʵ�����
    root = uiapp.Personality2;
    checkempty = root.Children.Count;
    if checkempty == 0
        % ���δ���ֳ������½�һ��
        uiapp.visible = 1;
        root.NewScenario('StarLink');
        % root.SaveScenarioAs('D:\SKT\SL\SL');
        sc = root.CurrentScenario;
    else
        % ������ִ��ŵĳ�����ѯ���Ƿ�ر��ؽ�
        rtn = questdlg({'Close the current scenario?',' ','(WARNING: If you have not saved your progress will be lost)'});
        if ~strcmp(rtn,'Yes')
            return
        else
            root.CurrentScenario.Unload
            uiapp.visible = 1;
            root.NewScenario('StarLink');
            sc = root.CurrentScenario;
        end
    end

catch
    uiapp = actxserver('STK11.application');% STKû���������½�ʵ����ȡ���
    root = uiapp.Personality2;
    uiapp.visible = 1;
    root.NewScenario('StarLink');
    % root.SaveScenarioAs('D:\SKT\SL\SL');
    sc = root.CurrentScenario;
end
%=============================������������==================================
disp('�趨����ʱ��');
StartTime = '13 Jan 2021 09:00:00.000';%��ʼʱ��
StopTime  = '14 Jan 2021 09:00:00.000';%����ʱ��
sc.SetTimePeriod(StartTime , StopTime);
sc.Epoch = StartTime;% �趨����������ʼʱ��
root.ExecuteCommand('Animate * Reset');% �趨����ʱ��ص���ʼ��(Connect����)

%=========================�½����Ƕ����������ǲ���=========================
disp('��������');
sat1 = sc.Children.New('esatellite','Sat1');
sat1.SetPropagatorType('ePropagatorJ4Perturbation');
sat2 = sc.Children.New('esatellite','Sat2');
sat2.SetPropagatorType('ePropagatorJ4Perturbation');

h = 1175;%���Ǹ߶�
a = 6378.137 + h;%�볤��
e = 0;%��Բ��
i = 86.5;%������
w = 0;%���յ����
Raan = 0;%������ྶ
M = 0;%ƽ�����
propagator1 = sat1.Propagator;
propagator2 = sat2.Propagator;
propagator1.StartTime = sc.StartTime;%��ֹʱ�䣬�볡��ʱ��һ��
propagator1.StopTime = sc.StopTime;
propagator1.Step = 60.0;%ʱ�䲽��
propagator1.InitialState.Representation.AssignClassical('eCoordinateSystemJ2000',a,e,i,w,Raan,M);%���ù��������
propagator2.InitialState.Representation.AssignClassical('eCoordinateSystemJ2000',a,e,i,w,Raan,M+30);%���ù��������
propagator1.Propagate;
propagator2.Propagate;

%=========================�½��������������ò���===========================
disp('����������');
sen1 = sat1.Children.New('eSensor','Sen1');
sen1.SetPatternType('eSnSimpleConic');%����������
sen1.CommonTasks.SetPatternSimpleConic(55,0.1);%������������׶��55������0.1

sen2 = sat2.Children.New('eSensor','Sen2');
sen2.SetPatternType('eSnSimpleConic');%����������
sen2.CommonTasks.SetPatternSimpleConic(55,0.1);%������������׶��55������0.1

%==========================����������������д�����==============================
constellation = root.CurrentScenario.Children.New('eConstellation','Const');%���������������ڴ�����д�����

%��Ӵ�����
constellation.Objects.AddObject(sen1);
constellation.Objects.AddObject(sen2);

%=============================��������վ==================================
disp('��������վ');
fac = sc.Children.New('eFacility','BJ');%���õ���վ����
fac.Position.AssignGeodetic(30,107,0);%����վ��γ�ȸ߶�

%����վԼ��
facConstraints = fac.AccessConstraints;
elevation = facConstraints.AddConstraint('eCstrElevationAngle');%����Լ��
elevation.EnableMin = 1;%����С����
elevation.Min = 10;%��С����
% elevation.EnableMax = 1;%���������
% elevation.Max = 80;%�������

%=========================����վ���������ӣ�Access��===========================
%%Access
access_facsat1 = sat1.GetAccessToObject(fac);
access_facsat1.Compute;

access_facsat2 = sat2.GetAccessToObject(fac);
access_facsat2.Compute;



%================================��������================================
%�ɼ��Ա������ɲ�����
disp('���ɱ���');
root.ExecuteCommand('ReportCreate */Satellite/Sat1 Type Save Style "Access" File "D:\stkdata\access1.txt" AccessObject */Facility/BJ');%ע��Sat��BJ����ͼ�����ֶ�Ӧ
root.ExecuteCommand('ReportCreate */Satellite/Sat2 Type Save Style "Access" File "D:\stkdata\access2.txt" AccessObject */Facility/BJ');%ע��Sat��BJ����ͼ�����ֶ�Ӧ

%AER�������ɲ�����
% root.ExecuteCommand('ReportCreate */Satellite/Sat Type Save Style "AER" File "D:\stkdata\AER.txt" AccessObject */Facility/BJ TimeStep 1');%ע�����
%AER�������ɲ���ʾ
% root.ExecuteCommand('ReportCreate */Satellite/Sat Type Display Style "AER" AccessObject */Facility/BJ TimeStep 1');











