clc
clear
% close all
warning off
set(0,'defaultfigurecolor','w')

% 全局变量
global inddis w dr lambda cons q_main startpoint endpoint ra2_ex firstlayer_c

%% 导入参数
% Cr = readtable("C:\Users\Gewel\Desktop\实验数据-PMRICRAS-GDMS\深度浓度-清洁版数据.xlsx", 'Sheet', "原始卷积");%如果excel有多个sheet
Cr = readtable("深度浓度-清洁版数据.xlsx");%如果excel只有一个sheet
z_zhou=1;                         % 此为z轴
I_zhou=2;                         % 此为I轴

lb_cons=0.8;
ub_cons=1.2;


% 溅射速率
q_A=8.83 ;
q_B=6.98 ;

inddis=1;%千万要注意择优MRI的inddis不能比w或者lamuda任意一个大，不然就跑的结果出问题然后优化不出来了

firstlayer_c=1;%一定每组数据记得检查这个，如果第一层是0浓度层这边就是0，否则是1

%大概的膜层厚度，即使不知道也要把层数调的一样，不然优化的层数就会出bug
obj_tn = 30*ones(1,15);
% obj_tn = [30 8 16 25 40 20 32 15];
% obj_tn = [42.9 4.4 13.2 7.15 22 13.7 40.7 28 93.5 63.8];%拟合结果
%有时候实验数据的开头和结尾不稳定，选取中间部分的实验数据进行误差判断，所以有个star和end
startpoint=1;
endpoint_daoshuduoshaozhihoubuyao=0;

% 算法的参数
Npop = 60;                        % 种群数量
Max_it = 1200;                     % 迭代次数

% % hwn实验专辑
% lb = [0.1,  0,    0.01,   0,   q_A,   q_B, 20 0.2 2.7 2.9 12.1   10.9 25.2 17.5 79.1 56.5];  % 要优化的参数的下界
% ub = [10,   1,    160,   10,   q_A,   q_B, 40 5.2 13.7 13.9 23.1 20.9 45.2 37.5 99.1 76.5];  % 要优化的参数的上界

% 百分比相对 设置上下界
lb = [0.1,  0,    0.01,   0,   lb_cons*q_A,   lb_cons*q_B, lb_cons*obj_tn];  % 要优化的参数的下界
ub = [10,   1,    10,   10,   ub_cons*q_A,  ub_cons*q_B, ub_cons*obj_tn];  % 要优化的参数的上界

% 绝对值相对 设置上下界
% lb = [0.1,  0,    0.01,   0,   q_A,   q_B, obj_tn-lb_cons];  % 要优化的参数的下界
% ub = [10,   1,    10,   10,   q_A,   q_B, obj_tn+ub_cons];  % 要优化的参数的上界

% 绝对值 设置上下界
% lb = [0.1,  0,    0.01,   0,   q_A,   q_B, zeros(1, length(obj_tn))];  % 要优化的参数的下界
% ub = [10,   1,    10,   10,   q_A,   q_B, 50*ones(1, length(obj_tn))];  % 要优化的参数的上界

%% 手动调参数据，可以不输入，如果手动调出来过就可以当做一种参考值作为对比
%MRI
w = 1;
dr = 1/1000; %参数优化的时候可以1/100，一般情况卷积用1000比较精准
lambda = 1;
sigema_0= 3;
sigema_k= 0;
sigema_c= 0;
cons=5;
%CRA
b_FR=5;
p_FR=1.5;


% q_main=45;
%------------------------------------------------------------------------------------------------------------------------
%卷积参数
noiselevel=0e-2;                  %噪声范围
%构造参考膜层结构

%% sigma
%线性
sigma_change=@(sigema_0,sigema_k,i,inddis,sigema_c)sigema_0+sigema_k*(i*inddis);

%常数
% sigma_change=@(sigema_0,sigema_k,i,inddis,sigema_c)0.1;
%开根号
% sigma_change=@(sigema_0,sigema_k,i,inddis,sigema_c)sqrt(sigema_0+sigema_k*(i*inddis)^2);
%指数
% sigma_change=@(sigema_0,sigema_k,i,inddis,sigema_c)sigema_k*sigema_0^(sigema_c*(i*inddis));
%------------------------------------------------------------------------------------------------------------------------
%%  导入数据
ra2_ex = Cr{:, z_zhou}; % 深度
data = Cr{:, I_zhou}; % 信号强度
% data = data/100;%信号强度归一化
ra2_ex = ra2_ex';
data = data';
wide_ex=max(ra2_ex);
% % %------------------------------------------------------------------------------------------------------------------------
%去除奇异值
ra2_ex = ra2_ex(isfinite(ra2_ex));%去除奇异值
data = data(isfinite(data));
% data=smooth(data,'rloess');%光滑之后可能会报错
%一维插值
x1_ex=ra2_ex;
y1_ex=data;
ra2_ex=0:inddis:max(ra2_ex);
data=interp1(x1_ex,y1_ex,ra2_ex,'spline');
data(data>1)=1;                   %简化版的判断语句
data(data<0)=0;
data=data';

fit=data; 
DataLength = length(fit);         % 记录输入的实验数据数组的大小
% plot(ra2,fit);

endpoint=max(ra2_ex)/inddis-endpoint_daoshuduoshaozhihoubuyao;


nD = length(lb);                           % 维度（要优化的参数的数量）

fobj =  @P_MRICRAS_func;           % 目标函数

%% 调用SFOA算法函数
[x_best_solution, error,used_time,AA,Curve] = SFOA(Npop,Max_it,lb,ub,nD,fobj,fit);
Curve=Curve';
writematrix(Curve, 'AA迭代误差线.xlsx');
disp('数据已保存为 AA迭代误差线.xlsx');
optimized_sigema_0 = x_best_solution(1);
optimized_sigema_k = x_best_solution(2);
optimized_b_FR     = x_best_solution(3);
optimized_p_FR     = x_best_solution(4);
optimized_q_A      = x_best_solution(5);
optimized_q_B      = x_best_solution(6);
optimized_obj_tn   = x_best_solution(7:end);

obj_tn = [obj_tn max(ra2_ex)-sum(obj_tn)]; %衬底在读取数据后自动计算，以满足数据长度和卷积长度相同
optimized_obj_tn = [optimized_obj_tn max(ra2_ex)-sum(optimized_obj_tn)]; %衬底在读取数据后自动计算，以满足数据长度和卷积长度相同

%% 结果输出
disp(['Original sigema_0 = ' num2str(sigema_0) ', Optimized sigema_0 = ' num2str(optimized_sigema_0)]);
disp(['Original sigema_k = ' num2str(sigema_k) ', Optimized sigema_k = ' num2str(optimized_sigema_k)]);
disp(['Original b_FR = ' num2str(b_FR) ', Optimized b_FR = ' num2str(optimized_b_FR)]);
disp(['Original p_FR = ' num2str(p_FR) ', Optimized p_FR = ' num2str(optimized_p_FR)]);
disp(['Original q_A = ' num2str(q_A) ', Optimized q_A = ' num2str(optimized_q_A)]);
disp(['Original q_B = ' num2str(q_B) ', Optimized q_B = ' num2str(optimized_q_B)]);
disp(['Original obj_tn = ' num2str(obj_tn) ', Optimized obj_tn = ' num2str(optimized_obj_tn)]);
disp(['Error = ' num2str(error)]);
% AA=[           '优化后'              '给定数据'           '实际膜层结构'     '膜层误差'      '误差%'       '耗时'       '迭代收敛情况'
%     'sigema_0' optimized_sigema_0    sigema_0                                              100*error    used_time                  
%     'sigema_k' optimized_sigema_k    sigema_k          
%     'b' ]
% AA=[ ''           '优化后'              '给定数据'           '实际膜层结构'     '膜层误差'      '误差%'       '耗时'       '迭代收敛情况'
%     'sigema_0' optimized_sigema_0      sigema_0             ''                ''              100*error    1            ''     
%     'sigema_k' optimized_sigema_k      sigema_k             ''                ''              ''           ''           ''          
%     'b' optimized_b_FR b_FR '' '' '' '' ''
%     'p' optimized_p_FR p_FR '' '' '' '' '' 
%     'obj_tn（±20%）' optimized_obj_tn' obj_tn' obj_tn' optimized_obj_tn'-obj_tn' '' '' '' ]
% 
% 
% 
% 
% 
% 
% AA = { 
%     ' '           '优化后'              '给定数据'           '实际膜层结构'     '膜层误差'      '误差%'       '耗时'       '迭代收敛情况'
%     'sigema_0'   optimized_sigema_0    sigema_0             ' '                ' '              100*error     1            ''     
%     'sigema_k'   optimized_sigema_k    sigema_k             ' '                ' '              ' '            ' '           ' '          
% };