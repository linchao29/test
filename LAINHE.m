%**************************************************************************
%                                             Matlab STK联合仿真
%                                                      COM方式
%                                                 两颗星试验星座
%
%**************************************************************************
clc
clear all
disp('打开STK程序，创建一个场景');

%============================建立STK场景并保存==============================
try
    uiapp = actxGetRunningServer('STK11.application'); % 获取运行中的STK实例句柄
    root = uiapp.Personality2;
    checkempty = root.Children.Count;
    if checkempty == 0
        % 如果未发现场景，新建一个
        uiapp.visible = 1;
        root.NewScenario('StarLink');
        % root.SaveScenarioAs('D:\SKT\SL\SL');
        sc = root.CurrentScenario;
    else
        % 如果发现打开着的场景，询问是否关闭重建
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
    uiapp = actxserver('STK11.application');% STK没有启动，新建实例获取句柄
    root = uiapp.Personality2;
    uiapp.visible = 1;
    root.NewScenario('StarLink');
    % root.SaveScenarioAs('D:\SKT\SL\SL');
    sc = root.CurrentScenario;
end
%=============================场景参数设置==================================
disp('设定场景时间');
StartTime = '13 Jan 2021 09:00:00.000';%开始时间
StopTime  = '14 Jan 2021 09:00:00.000';%结束时间
sc.SetTimePeriod(StartTime , StopTime);
sc.Epoch = StartTime;% 设定场景动画开始时间
root.ExecuteCommand('Animate * Reset');% 设定动画时间回到起始点(Connect命令)

%=========================新建卫星对象并设置卫星参数=========================
disp('创建卫星');
sat1 = sc.Children.New('esatellite','Sat1');
sat1.SetPropagatorType('ePropagatorJ4Perturbation');
sat2 = sc.Children.New('esatellite','Sat2');
sat2.SetPropagatorType('ePropagatorJ4Perturbation');

h = 1175;%卫星高度
a = 6378.137 + h;%半长轴
e = 0;%椭圆率
i = 86.5;%轨道倾角
w = 0;%近日点幅角
Raan = 0;%升交点赤径
M = 0;%平近点角
propagator1 = sat1.Propagator;
propagator2 = sat2.Propagator;
propagator1.StartTime = sc.StartTime;%起止时间，与场景时间一致
propagator1.StopTime = sc.StopTime;
propagator1.Step = 60.0;%时间步长
propagator1.InitialState.Representation.AssignClassical('eCoordinateSystemJ2000',a,e,i,w,Raan,M);%设置轨道六根数
propagator2.InitialState.Representation.AssignClassical('eCoordinateSystemJ2000',a,e,i,w,Raan,M+30);%设置轨道六根数
propagator1.Propagate;
propagator2.Propagate;

%=========================新建传感器对象并设置参数===========================
disp('创建传感器');
sen1 = sat1.Children.New('eSensor','Sen1');
sen1.SetPatternType('eSnSimpleConic');%传感器类型
sen1.CommonTasks.SetPatternSimpleConic(55,0.1);%传感器参数半锥角55，精度0.1

sen2 = sat2.Children.New('eSensor','Sen2');
sen2.SetPatternType('eSnSimpleConic');%传感器类型
sen2.CommonTasks.SetPatternSimpleConic(55,0.1);%传感器参数半锥角55，精度0.1

%==========================创建星座并添加所有传感器==============================
constellation = root.CurrentScenario.Children.New('eConstellation','Const');%创建星座集，用于存放所有传感器

%添加传感器
constellation.Objects.AddObject(sen1);
constellation.Objects.AddObject(sen2);

%=============================创建地面站==================================
disp('创建地面站');
fac = sc.Children.New('eFacility','BJ');%设置地球站名字
fac.Position.AssignGeodetic(30,107,0);%地球站经纬度高度

%地球站约束
facConstraints = fac.AccessConstraints;
elevation = facConstraints.AddConstraint('eCstrElevationAngle');%仰角约束
elevation.EnableMin = 1;%打开最小仰角
elevation.Min = 10;%最小仰角
% elevation.EnableMax = 1;%打开最大仰角
% elevation.Max = 80;%最大仰角

%=========================地面站与卫星连接（Access）===========================
%%Access
access_facsat1 = sat1.GetAccessToObject(fac);
access_facsat1.Compute;

access_facsat2 = sat2.GetAccessToObject(fac);
access_facsat2.Compute;



%================================报告生成================================
%可见性报告生成并保存
disp('生成报告');
root.ExecuteCommand('ReportCreate */Satellite/Sat1 Type Save Style "Access" File "D:\stkdata\access1.txt" AccessObject */Facility/BJ');%注意Sat和BJ是与图标名字对应
root.ExecuteCommand('ReportCreate */Satellite/Sat2 Type Save Style "Access" File "D:\stkdata\access2.txt" AccessObject */Facility/BJ');%注意Sat和BJ是与图标名字对应

%AER报告生成并保存
% root.ExecuteCommand('ReportCreate */Satellite/Sat Type Save Style "AER" File "D:\stkdata\AER.txt" AccessObject */Facility/BJ TimeStep 1');%注意符号
%AER报告生成并显示
% root.ExecuteCommand('ReportCreate */Satellite/Sat Type Display Style "AER" AccessObject */Facility/BJ TimeStep 1');











