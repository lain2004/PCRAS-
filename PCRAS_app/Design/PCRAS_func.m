function [I] = P_MRICRAS_func(x)
global inddis w dr lambda cons q_main ra2_ex firstlayer_c sigma_change

sigma0 = x(1);
sigmaK = x(2);
sigma_c = x(3);
b_FR   = x(4);
p_FR   = x(5);
q_A    = x(6);
q_B    = x(7);
obj_tn = x(8:end);

% 判断obj
if max(ra2_ex)-sum(obj_tn) > 0
    obj_tn = [obj_tn max(ra2_ex)-sum(obj_tn)];
else
    I = zeros(length(ra2_ex),1);
    return
end

%% PMRI
x1a=firstlayer_c;%x1a represent the concentration of first layer's element A
x2a=abs(1-firstlayer_c);%x2a represent the concentration of second layer's element A
x1b=x1a;%x1b represent the concentration of first layer's element B
x2b=x2a;%x2b represent the concentration of second layer's element B

layer=length(obj_tn);% laser mean the layers amount of multilayer thin films

% location of interface
z0=zeros(1,layer+1);%z0 represent the specific Coordinate values of each interface
for i=1:length(z0)
    if i==1
        z0(1,i)=0;
    else
        z0(1,i)=z0(1,i-1)+obj_tn(i-1);
    end
end
ra2_ex=0:inddis:z0(length(z0));%ra2_ex will be used for Gaussion function


tdr=q_B;
intenA=zeros(1,length(ra2_ex));
intenAt=zeros(1,length(ra2_ex));
SIG=zeros(1,2);
AddTh=zeros(1,length(tdr));% additional thickness for the mass conservation
for pp=1:1:length(tdr)
    % lambda=tdr(pp);
    % w=tdr(pp);
    % the rate can be changed accounding to the sputtering time
    rate_A=q_A;%the sputtering rate of low refracive index material A
    rate_B=tdr(pp);%the sputtering rate of high refractive index material B

    ra1t=zeros(1,length(ra2_ex));

    conA0=zeros(1,length(ra2_ex));% conA0 represent the abbreviation of concentration of element A
    intA=zeros(1,length(ra2_ex));% intA mean the Intensity of A
    intAc=zeros(1,length(ra2_ex));
    % conA0
    for i=1:1:layer
        len=(z0(i+1)-z0(i))/inddis;
        if mod(i,2)==1
            for k=1:1:len
                conA0(floor(z0(i)/inddis)+k)=x1a;
            end
        else
            for k=1:1:len
                conA0(floor(z0(i)/inddis)+k)=x2a;
            end
        end
    end
    % plot(ra2_ex,conA0);

    conAs=zeros(1,length(ra2_ex));
    % intA sigma
    for i=1:1:length(ra2_ex)
        sigma = sigma_change(sigma0, sigmaK, i, inddis, sigma_c);
        SIG(1,i)=sigma;
        aaa1=-cons*sigma+ra2_ex(i);
        aaa2=cons*sigma+ra2_ex(i);

        if aaa1<0
            aaa1=0;
        end

        if aaa2>z0(1,length(z0))
            aaa2=z0(1,length(z0));
        end
        zz1=aaa1:inddis:aaa2;

        gzz1=zeros(1,length(zz1));
        gzz2=zeros(1,length(zz1));
        for mn=1:1:length(zz1)
            gzz1(1,mn)=conA0(floor(aaa1/inddis)+mn)*exp(-((ra2_ex(i)-zz1(mn))^2)/(2*sigma^2))/(sigma*sqrt(2*pi));
            gzz2(1,mn)=(1-conA0(floor(aaa1/inddis)+mn))*exp(-((ra2_ex(i)-zz1(mn))^2)/(2*sigma^2))/(sigma*sqrt(2*pi));
        end
        conAs(i)=sum(gzz1)/(sum(gzz1)+sum(gzz2));
    end
    % plot(ra2_ex,conAs);
    % plot(ra2_ex,conA0,ra2_ex,conAs);

    % sigma+w
    intAS=zeros(1,length(ra2_ex));
    intA(1,1)=conAs(1,1);
    for i=1:1:length(ra2_ex)-2
        r1=rate_A/rate_B;
        if i==length(ra2_ex)-2
            gggg=1;
        end
        if ra2_ex(i)+w<z0(length(z0))
            intA(1,i+1)=intA(1,i)+inddis*(conAs(floor((ra2_ex(i+1)+w)/inddis))-r1*intA(1,i)/(intA(1,i)*(r1-1)+1))/w;
        else
            dl=z0(length(z0))-ra2_ex(i);
            cc=r1*intA(1,i)/(intA(1,i)*(r1-1)+1);
            intA(1,i+1)=(intA(1,i)*dl-cc*inddis)/(dl-inddis);
        end
        intAS(1,i+1)=intA(1,i+1)*rate_A/(intA(1,i+1)*rate_A+(1-intA(1,i+1))*rate_B);

    end

    % plot(ra2_ex,intA);

    % sigma + w+ lambda
    intAf=zeros(1,length(ra2_ex));
    for i=1:1:length(ra2_ex)

        gf=0;
        gf2=0;
        uu=floor(w/inddis);
        if ra2_ex(i)+w<z0(length(z0))
            mybb1=ra2_ex(i):inddis:ra2_ex(i)+w;
            for k=1:1:length(mybb1)
                gf=gf+inddis*(intA(1,i)*exp(-(k*inddis)/lambda)/lambda);
                gf2=gf2+inddis*((1-intA(1,i))*exp(-(k*inddis)/lambda)/lambda);
            end
            mybb2=ra2_ex(i)+w+inddis:inddis:z0(length(z0));
            for k=1:1:length(mybb2)
                gf=gf+inddis*(conAs(1,uu+i+k)*exp(-((uu+k)*inddis)/lambda)/lambda);
                gf2=gf2+inddis*((1-conAs(1,uu+i+k))*exp(-((uu+k)*inddis)/lambda)/lambda);
            end
        elseif ra2_ex(i)+w>=z0(length(z0))
            mybb1=ra2_ex(i):inddis:z0(length(z0));
            for k=1:1:length(mybb1)
                gf=gf+inddis*(intA(1,i)*exp(-(k*inddis)/lambda)/lambda);
                gf2=gf2+inddis*((1-intA(1,i))*exp(-(k*inddis)/lambda)/lambda);
            end
        end
        intAf(1,i)=gf/(gf+gf2);

    end

    % % integral of intAf over the depth
    % InintAf=zeros(1,length(ra2_ex));% In=Integral
    % for i=2:1:length(ra2_ex)
    %     InintAf(1,i)=InintAf(1,i-1)+intAf(1,i)*inddis;
    % end


    %ra2t
    tet=zeros(1,length(ra2_ex));
    for i=1:1:length(ra2_ex)
        %       tet(i)=inddis/(rate_A*conAw(fw/inddis+i)+rate_B*(1-conAw(fw/inddis+i)));
        tet(i)=inddis/(rate_A*intAf(i)+rate_B*(1-intAf(i)));
        if i==1
            ra1t(i)=tet(i);
        else
            ra1t(i)=ra1t(i-1)+tet(i);
        end
    end
    kjh=0;
    for i=1:1:length(ra2_ex)
        qt=intAf(1,i)*rate_A+(1-intAf(1,i))*rate_B;
        kjh=kjh+inddis*(intAf(1,i)*rate_A/qt-intAf(1,i));
    end

    %depth resolution
    DR=zeros(1,length(ra2_ex));
    mysig=zeros(1,length(ra2_ex));
    for i=1:1:length(ra2_ex)
        sigma = sigma_change(sigma0, sigmaK, i, inddis, sigma_c);
        mysig(1,i)=sigma;
        r1=rate_A/rate_B;
        DR(1,i)=sqrt((2*mysig(1,i))^2+(1.67*lambda)^2+(1.67*w/r1)^2);
    end

    AddTh(1,pp)=kjh;
    % hold on;
    % plot(ra1t,intAf);

    intenA(2*pp-1,:)=ra2_ex;
    intenAt(2*pp-1,:)=ra2_ex;
    % % % % intenA(2*pp,:)=intAS;
    % % % % intenAt(2*pp,:)=intA*rate_A;
    % intenA(2*pp,:)=DR;
    intenA(2*pp,:)=intAf;
    intenAt(2*pp,:)=intAf;
end

intenA=intenA';
intenAt=intenAt';
% W =@(r)1./(r+1);
% FR=@(r)(b_FR+2).*(1+(p_FR-1).*r)/ (b_FR+2.*p_FR);
q_ave=intenA(:,2).*q_A+((-1).*intenA(:,2)+1)*q_B;
z_cra=intenA(:,1);
%% CRAs
%构造每层的crater
radius = 0:dr:1; % 生成 r 的取值
FR = zeros(1, length(radius)); % 预分配数组
W = zeros(1, length(radius));
for j = 1:length(radius)
    r = radius(j);   % 取实际的 r 值
    FR(j) = (b_FR + 2) .* (1 + (p_FR - 1) .* r.^b_FR) / (b_FR + 2 .* p_FR);
    W(j) = 1 ./ (r + 1);
end
% x=radius;
% y=FR;
% plot(x,y)
%
z_module=zeros(1, length(radius));
q_module = zeros(1, length(radius));
I_module = zeros;  %每个module深度对应的I_ABMRI
I_module2=zeros; %耦合了crater后的每个module的信号I
I_modules3=zeros;%对I_module2归一化后的信号
I_norm= zeros; %  每个module的归一化因子
I=zeros;
for  i=2:1:length(z_cra)
    %calculate crater shape
    z_main=z_cra(i); % target layer, r=0
    %Add up all modules
 for k=1:1:length(radius)
        z_module(k)=z_main.*FR(k);
        if 1 <=round(z_module(k) /inddis)   &&  round(z_module(k) /inddis) <=  length(z_cra)
            q_module(k)=q_ave(round(z_module(k)./inddis));
            I_module(k)= intenA(round(z_module(k)./inddis),2);
        else
            q_module(k)=0;
            I_module(k)= 0; 
        end
        I_module2(k)= W(k).*radius(k).*q_module(k).*FR(k).*I_module(k).*dr;
        I_norm(k)= W(k).*radius(k).*q_module(k).*FR(k).*dr;

        if  I_norm(k)>0
            I_modules3(k)= I_module2(k)./I_norm(k);
        else
           I_modules3(k)=0;
        end
        I(i)=sum(I_modules3)./length(radius); %对I_m3求和并除以modules数
    end
end

I = I';

end