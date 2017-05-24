
function varargout = KAAIP(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @KAAIP_OpeningFcn, ...
                   'gui_OutputFcn',  @KAAIP_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
function varargout = KAAIP_OutputFcn(~, ~, handles) 
varargout{1} = handles.output;
function KAAIP_CloseRequestFcn(hObject, ~, ~)

global format;

warning('off','all');
delete(['TempImage.' format]);

clear global format;
clear global Original;
clear global Filtered;
clear global Noised;
clear global FilteredAsOriginal;
clear global Parametrs;           % ��������� ������������ (���� � �������)
clear global Noises;              % ������ ���������� ����������
clear global Filters;             % ������ ���������� ����������
delete(hObject);


% ������� ����� ��������� ����������
function KAAIP_OpeningFcn(hObject, ~, handles, varargin)

global StatAndMLT;
global CV;

handles.output = hObject;
guidata(hObject, handles);
scr_res = get(0, 'ScreenSize');     % �������� ���������� ������
fig = get(handles.KAAIP,'Position');  % �������� ���������� ����

% �������������� ����
set(handles.KAAIP,'Position',[(scr_res(3)-fig(3))/2 (scr_res(4)-fig(4))/2 fig(3) fig(4)]);

toolboxes = ver();      % ��������� ������� ���������
warning('off','all');
matlab_version = toolboxes(1).Release;
matlab_version = str2double(matlab_version(3:6));


if matlab_version < 2015    
    message_str = { '���� ������ Matlab ���� ������ R2015a';...
                    '�������� ������ � ������������ ��������� ���������'};
end

StatAndMLT = false;         % �������� ���������� Statistics and Machine Learning Toolbox
for i = 1:size(toolboxes,2) % ���������� �� ������� ��������

    if strcmp('Statistics and Machine Learning Toolbox',toolboxes(i).Name) == 1
        StatAndMLT = true;
    end
end    

CV = false;     % �������� ���������� Computer Vision System Toolbox
for i = 1:size(toolboxes,2) % ���������� �� �������

    if strcmp('Computer Vision System Toolbox',toolboxes(i).Name) == 1
        CV = true;
    end
end

if ~ StatAndMLT     % ��� ���������� - ��������� ���� ������
    message_str = [ message_str;...
                    '����������� ���������� "Statistics and Machine Learning Toolbox":';...
                    '� ������ ��������� ���������������� ��� � ��� ����� ����������'];
end

if ~ CV 
    message_str = [ message_str;...
                    '����������� ���������� "Computer Vision System Toolbox":';...
                    '� ������ ��������� ��������� �������� ����� ����������'];
end

                        
if ~isempty(message_str)    % ����� ���������
    questdlg(message_str,'KAAIP','OK','modal');
end 


%%%%%%%%%%%%%%%%%%%%%% ���� ��������� ����������� %%%%%%%%%%%%%%%%%%%%%%%%%


% ���� "�������"
function Open_Callback(hObject, eventdata, handles)

global Original;                        % �������� �����������
global format;
global Filtered;

%%%%%%%%%%%%% ��������

if isempty(handles)            % ������ ������� ������� �������� fig ������ m  
    
    ok = questdlg({'�� ��������� ���� � ����������� *.fig ������ ���������� *.m.';...
        '������� "OK", � ��� ����� ������'},...
        'KAAIP','OK','modal');
    
    % ���� ������ � ����� ������, ���� �����, ����� ��������� ������
    if ~isempty(ok) || isempty(ok)      
        close(gcf);
        run('KAAIP.m');
        return;
    end
end

toolboxes = ver();          % ��������� ������� ���������
good = false;
for i = 1:size(toolboxes,2) % ���������� �� �������
    
    if strcmp('Image Processing Toolbox',toolboxes(i).Name) == 1
        good = true;
        break;      % ���� ����� ������� ����, �� ��� ��        
    end 
end

if ~good
    ok = questdlg({ '���� ������ Matlab �� �������� ������������ ���������� "Image Processing Toolbox", �� �� ��������� �����';...
                    '���������� ����� �������. ��� ����� �������, �������� ���������� � ��������.';
                    '� ���������� ���������� ��� ����� ������!'},'KAAIP','OK','modal');
    
    if ~isempty(ok) || isempty(ok)
        close(gcf);
        return;
    end
end

warning('on','all');

%%%%%%%%% ����� ��� �������� �������

if ~isempty(Filtered)            % ���� ������ ��� ����, ������� ������-����
    answer = questdlg(...
        '�������� ����������� �������� � ������ ���������� ������. ����������?',...
        '�������� �����������','��','���','���');
    if ~strcmp(answer,'��')             % ���� ����� "��", ����� �� ������ � ����
        return;                         % � ������� �� ����� �������
    end
end

[FileName, PathName] = uigetfile({'*.jpg';'*.tif';'*.bmp';'*.png'},...
                                    '�������� ���� ��������� �����������',...
                                    [cd '\Test Images']);    % ����� ������� 
if ~FileName                                 % ��������, ��� �� ������ ����
    return;
end

DotPositions = strfind(FileName,'.');            % ��������� ����� � ��������
format = FileName(DotPositions(end)+1:end);      % ������� ������ ����� ����� ��������� �����

try             % �������� ������� ��������
    [Temp,colors] = imread([PathName FileName]);         % ��������� ��
catch           % ���� ���� �� ���� ���� �������� :'(
    h = errordlg('� ������ ���-�� �� ���. �������� ������','KAAIP');
    set(h, 'WindowStyle', 'modal');
    return;
end

% ���� �������� ��������������� - ��������� � 256 ��������
if ~isempty(colors)      
    Temp = 255*ind2rgb(Temp,colors);
end

Original = [];
Original = Temp;
Original = uint8(Original);                     % ��������� � 256 ��������
set(handles.ChannelSlider,'Max',size(Original,3));    % ��������� ��������
set(handles.ChannelSlider,'SliderStep',[1/size(Original,3) 1/size(Original,3)]);

% ������ ��� ������� � ���������� ���������

% � ������� FiltAgain ���� ���������� ����, ������� �� ������� � ��������
set(handles.FiltAgain,'Enable','off'); 
set(handles.ContinueProcessing,'Enable','off');
set([   handles.Filtered;...
        handles.Noised;...
        handles.NoiseFilterListMenu],'Enable','off');
    
cla(handles.NoiseAxes,'reset');
cla(handles.FiltAxes,'reset');
cla(handles.Diagram,'reset');

set([   handles.NoiseAxes;...
        handles.NoisePanel;...
        handles.Diagram;...
        handles.FiltAxes;...
        handles.FiltPanel;...
        handles.GraphSlider;...
        handles.AssessMenu;...
        handles.NoiseFilterList;...
        handles.ViewNoisedCheck;...
        handles.ViewFilteredCheck;...
        handles.GraphSlider;...
        handles.AssessMenu],'Visible','off');    

% ������ ���������� ����������
clear global Noised;
clear global Filtered;
setappdata(handles.NoiseAxes,'Image',[]);
setappdata(handles.FiltAxes,'Image',[]);

if size(Original,3) > 1     % ���� ������� �����������
    
    set(handles.RGBpanel,'Visible','on');
    set([   handles.Red;...
            handles.Green;...
            handles.Blue;...
            handles.ChannelSlider;...
            handles.ShowButton],'Enable','on');
        
    set(handles.ChannelSlider,'Value',0);
    set(handles.ChannelString,'String','RGB');
    
    str = cell(size(Original,3),1);         % ������� ������ � ��������� ��� ����
    for i = 1:size(Original,3)
        str{i} = ['����� � ' num2str(i)];
    end
    
    set(handles.Red,'String',str,'Value',1);
    set(handles.Green,'String',str,'Value',2);
    set(handles.Blue,'String',str,'Value',3);
    
    set(handles.ShowMenu,'String',{'�����������';'����������� ���������';'����������� HSV'},'Value',1);
    
else                        % ���� �/� �����������
    
    set(handles.RGBpanel,'Visible','on');
    set(handles.ChannelSlider,'Value',1,'Enable','off');
    
    set([handles.Red;...
    	handles.Green;...
    	handles.Blue;...
    	handles.ShowButton],'Enable','off');
    
    set(handles.ShowMenu,'String',{'�����������';'����������� ���������'},'Value',1);
end

set(handles.OriginalPanel,'Visible','on');      % ���������� ������
set(handles.RunImageAnalyzer,'Enable','on');
set(handles.CopyOriginalImage,'Enable','on');
set(handles.FiltrationMenu,'Enable','on');              % �������������� ���� ����������
set(handles.View_Original,'Enable','on');               % �������������� �������� �������

ShowMenu_Callback(hObject, eventdata, handles);    % ��������� ������� �����������


% ���� "��������" ��������� �����������
function View_Original_Callback(hObject, ~, handles)

if hObject == handles.View_Filtered(1) || hObject == handles.View_Filtered(2)       % ���� ���������� ������� ���� "�������� ���������������"
    Im = getappdata(handles.FiltAxes,'Image');
    Image(:,:,1) = Im(:,:,get(handles.Red,'Value'),get(handles.FilteredMenu,'Value'));
    Image(:,:,2) = Im(:,:,get(handles.Green,'Value'),get(handles.FilteredMenu,'Value'));
    Image(:,:,3) = Im(:,:,get(handles.Blue,'Value'),get(handles.FilteredMenu,'Value'));

elseif hObject == handles.View_Noised(1)  || hObject == handles.View_Noised(2)     % ���� ����������  ������� ���� "�������� �����������"
    Im = getappdata(handles.NoiseAxes,'Image');
    Image(:,:,1) = Im(:,:,get(handles.Red,'Value'),get(handles.NoisedMenu,'Value'));
    Image(:,:,2) = Im(:,:,get(handles.Green,'Value'),get(handles.NoisedMenu,'Value'));
    Image(:,:,3) = Im(:,:,get(handles.Blue,'Value'),get(handles.NoisedMenu,'Value'));

else                                        % ���� ����������  ������� ���� "�������� ��������"
    Im = getappdata(handles.OriginalAxes,'Image');
    Image(:,:,1) = Im(:,:,get(handles.Red,'Value'));
    Image(:,:,2) = Im(:,:,get(handles.Green,'Value'));
    Image(:,:,3) = Im(:,:,get(handles.Blue,'Value'));
end

try
    imtool(Image);
catch
    OpenImageOutside(Image);
end


% ���� "����������" �������� ����������� � �����
function CopyOriginalImage_Callback(hObject, ~, handles)
        
if hObject == handles.CopyFiltered(1) || hObject == handles.CopyFiltered(2)       % ���� ���������� ������� ���� "�������� ���������������"
    Im = getappdata(handles.FiltAxes,'Image');
    Image(:,:,1) = Im(:,:,get(handles.Red,'Value'),get(handles.FilteredMenu,'Value'));
    Image(:,:,2) = Im(:,:,get(handles.Green,'Value'),get(handles.FilteredMenu,'Value'));
    Image(:,:,3) = Im(:,:,get(handles.Blue,'Value'),get(handles.FilteredMenu,'Value'));
    
elseif hObject == handles.CopyNoised(1)  || hObject == handles.CopyNoised(2)     % ���� ����������  ������� ���� "�������� �����������"
    Im = getappdata(handles.NoiseAxes,'Image');
    Image(:,:,1) = Im(:,:,get(handles.Red,'Value'),get(handles.NoisedMenu,'Value'));
    Image(:,:,2) = Im(:,:,get(handles.Green,'Value'),get(handles.NoisedMenu,'Value'));
    Image(:,:,3) = Im(:,:,get(handles.Blue,'Value'),get(handles.NoisedMenu,'Value'));
    
else
    Im = getappdata(handles.OriginalAxes,'Image');
    Image(:,:,1) = Im(:,:,get(handles.Red,'Value'));
    Image(:,:,2) = Im(:,:,get(handles.Green,'Value'));
    Image(:,:,3) = Im(:,:,get(handles.Blue,'Value'));
end

ClipboardCopyImage(Image);


% ���� "��������� �����������" ��������� �����������
function SaveOriginalHist_Callback(hObject, ~, handles)

if any(hObject == handles.SaveFilteredHist)     % ���� ������� � ��������
    AH = handles.FiltAxes;    % �������� ����������� ���
    
elseif any(hObject == handles.SaveNoisedHist)
    AH = handles.NoiseAxes;     % �����-�����������
    
elseif any(hObject == handles.SaveOriginalHist)
    AH = handles.OriginalAxes;  % ����� ��������
end

[FileName, PathName] = uiputfile({'*.jpg';'*.bmp';'*.tif';'*.png';'*.xlsx'},'��������� �����������');

if FileName~=0    
    
    DotPositions = strfind(FileName,'.');            % ��������� ����� � ��������
    format = FileName(DotPositions(end)+1:end);      % ������� ������ ����� ����� ��������� �����

    if strcmp(format,'xlsx')        
        SaveHistAsXLSX(AH,[PathName FileName]);        
    else        
        SaveObjectAsImage(AH,[PathName FileName]);
    end
end


% ���� "���������� �����������" ��������� �����������
function CopyOriginalHist_Callback(hObject, ~, handles)
    
if hObject == handles.CopyFilteredHist     % ���� ������� � ��������
    AH = handles.FiltAxes;    % �������� ����������� ���
    
elseif hObject == handles.CopyNoisedHist
    AH = handles.NoiseAxes;     % �����-�����������
    
else
    AH = handles.OriginalAxes;  % ����� ��������
end
    
ClipboardCopyObject(AH,0); 


%%%%%%%%%%%%%%%%%%%%%% ���� ������������ ����������� %%%%%%%%%%%%%%%%%%%%%%


% ���� "��������" ������������ �����������
function View_Noised_Callback(hObject, ~, handles)

View_Original_Callback(hObject,0,handles);


% ���� "����������" ����������� ����������� � �����
function CopyNoised_Callback(hObject, ~, handles)

CopyOriginalImage_Callback(hObject,0,handles);


% ���� "��������� ����������� �����������"
function SaveNoised_Callback(~, ~, handles)

global Noised;                           % ����������� �������
global format;
    
[FileName, PathName] = uiputfile(['*.' format],'��������� ���������� �����������');
if FileName~=0
    imwrite(Noised(:,:,:,get(handles.NoisedMenu,'Value')),[PathName FileName],format);
end


% ���� "��������� ��� ���������� �����������"
function SaveAllNoised_Callback(~, ~, ~)

global Noised;                           % ����������� �������
global format;

[FileName, PathName] = uiputfile(['*.' format],'��������� ��� ���������� �����������');
if FileName~=0
    for i = 1:size(Noised,4)
        imwrite(Noised(:,:,:,i),[PathName '(' num2str(i) ') ' FileName],format);
    end
end


% ���� "��������� �����������" ������������ �����������
function SaveNoisedHist_Callback(hObject, ~, handles)

SaveOriginalHist_Callback(hObject, 0, handles);


% ���� "���������� �����������" ������������ �����������
function CopyNoisedHist_Callback(hObject, eventdata, handles)

CopyOriginalHist_Callback(hObject, eventdata, handles);


%%%%%%%%%%%%%%%%%%% ���� ���������������� ����������� %%%%%%%%%%%%%%%%%%%%%


% ���� "��������" ���������
function View_Filtered_Callback(hObject, ~, handles)

View_Original_Callback(hObject,0,handles);


% ���� "����������" ��������������� ����������� � �����
function CopyFiltered_Callback(hObject, ~, handles)

CopyOriginalImage_Callback(hObject,0,handles);


% ���� "��������� ��������������� �����������"
function SaveFiltered_Callback(~, ~, handles)

global Filtered;                           % ����������� �������
global format;
    
[FileName, PathName] = uiputfile(['*.' format],'��������� ������������ �����������');
if FileName~=0
    imwrite(Filtered(:,:,:,get(handles.FilteredMenu,'Value')),[PathName FileName],format);
end


% ���� "��������� ��� ����������� �����������"
function SaveAllFiltered_Callback(~, ~, ~)

global Filtered;                           % ����������� �������
global format;
    
[FileName, PathName] = uiputfile(['*.' format],'��������� ��� ������������ �����������');
if FileName~=0
    for i = 1:size(Filtered,4)
        imwrite(Filtered(:,:,:,i),[PathName '(' num2str(i) ') ' FileName],format);
    end
end


% ���� "��������� �����������" ���������������� �����������
function SaveFilteredHist_Callback(hObject, ~, handles)

SaveOriginalHist_Callback(hObject, 0, handles);


% ���� "���������� �����������" ���������������� �����������
function CopyFilteredHist_Callback(hObject, eventdata, handles)

CopyOriginalHist_Callback(hObject, eventdata, handles);


%%%%%%%%%%%%%%%%%% ���� "������ "���������-���������"" %%%%%%%%%%%%%%%%%%%%


% ���� "�������� ����� ���������"
function ShowFilterMask_Callback(hObject,eventdata,handles)

List = handles.NoiseFilterList.String;          % ������
FiltStr = List{handles.NoiseFilterList.Value};  % ������ ������
                       
where = strfind(FiltStr,'%%');                  % ���� ��� � ������

if ~isempty(where)                              % ���� �� ����
    hash = FiltStr(where(1)+2:where(2)-1);      % ��������� ������ ���
    Data = zeros(size(hash,2));                 % ������ �����
    hash = double(hash) - 500;                  % ��������� ��� � 10�� �������
    
    for y = 1:size(hash,2)                      % ������ ������ ���� 
        bin_str = dec2bin(hash(y));             % ������������ � ������
        for x = 1:size(bin_str,2)               % ������ �������� �����
            Data(y,x) = str2double(bin_str(x)); % ������ � ������ �������
        end
    end
    
    try
        imtool(Data);
    catch
        OpenImageOutside(Data);
    end
    
else    
    h = errordlg('� ��������� ������ ����������� ���','KAAIP');
    set(h, 'WindowStyle', 'modal');    
end


% ���� "���-"������": "��������� ��� �����"
function SaveNFListAsText_Callback(~, ~, handles)

S = get(handles.NoiseFilterList,'String');  % ��������� ������

for x = 1:size(S,1)        % ��� ������ ������ ������
                
    S(x) = regexprep(S(x),char(963),'sigma');   % ������� � ������� �������
    S(x) = regexprep(S(x),char(955),'lambda');
    S(x) = regexprep(S(x),char(945),'alpha');
    S(x) = regexprep(S(x),char(178),'^(2)');
    S(x) = regexprep(S(x),char(186),' ��.');
    S(x) = regexprep(S(x),char(8734),'inf');
    S(x) = regexprep(S(x),char(8594),'-->');
    S(x) = regexprep(S(x),char(946),'beta');  
    
end

    % ���������� ���� ���������
[FileName, PathName] = uiputfile(['*.' 'txt'],'��������� ������ "���-������"');
if FileName~=0
    file_txt = fopen([PathName FileName],'wt');     % ������� ��������� ����
    
    for i = 1:size(S,1)                     % ��������� ������ � ���� ������
        fprintf(file_txt,'%s\r\n',S{i});
    end
    fclose(file_txt);                       % ��������� ����
    
end


% ���� "����������" ������ "���-���������"
function CopyNoiseFilterList_Callback(~, ~, handles)

ClipboardCopyObject(handles.NoiseFilterList,0);


% ���� "���������� ������ PSNR"
function CopyPSNR_Callback(~, ~, handles)

ClipboardCopyObject(handles.Diagram,150);


% ���� "��������� ������ PSNR"
function SavePSNR_Callback(~, ~, handles)

global Assessment_N;        % ������ ������ ���������� �����������
global Assessment_F;        % ������ ������ ������������ �����������

[FileName, PathName] = uiputfile({'*.jpg';'*.bmp';'*.tif';'*.png';'*.xlsx'},'��������� ������');
if FileName~=0   
    
    DotPositions = strfind(FileName,'.');            % ��������� ����� � ��������
    format = FileName(DotPositions(end)+1:end);      % ������� ������ ����� ����� ��������� �����

    if strcmp(format,'xlsx') 
        
        Data_N = zeros(7,size(Assessment_N,2));
        Data_F = zeros(7,size(Assessment_N,2));
        RowTitles = char('MAE','NAE','MSE','NMSE','SNR','PSNR','SSIM');
        ColTitles = cell(1,size(Assessment_N,2));
        
        for x = 1:size(Assessment_N,2)
            Data_N(1,x) = Assessment_N(x).MAE(1);
            Data_N(2,x) = Assessment_N(x).NAE(1);
            Data_N(3,x) = Assessment_N(x).MSE(1);
            Data_N(4,x) = Assessment_N(x).NMSE(1);
            Data_N(5,x) = Assessment_N(x).SNR(1);
            Data_N(6,x) = Assessment_N(x).PSNR(1);
            Data_N(7,x) = Assessment_N(x).SSIM(1);
            
            Data_F(1,x) = Assessment_F(x).MAE(1);
            Data_F(2,x) = Assessment_F(x).NAE(1);
            Data_F(3,x) = Assessment_F(x).MSE(1);
            Data_F(4,x) = Assessment_F(x).NMSE(1);
            Data_F(5,x) = Assessment_F(x).SNR(1);
            Data_F(6,x) = Assessment_F(x).PSNR(1);
            Data_F(7,x) = Assessment_F(x).SSIM(1);
            
            ColTitles{x} = ['� ' num2str(x)];
        end        
        
        xlswrite([PathName FileName],{'������\���������� �����������'},1,'A1');
        xlswrite([PathName FileName],cellstr(RowTitles),1,'A2');
        xlswrite([PathName FileName],ColTitles,1,'B1');
        xlswrite([PathName FileName],Data_N,1,'B2');
        
        
        xlswrite([PathName FileName],{'������\������������ �����������'},1,'A10');
        xlswrite([PathName FileName],cellstr(RowTitles),1,'A11');
        xlswrite([PathName FileName],ColTitles,1,'B10');
        xlswrite([PathName FileName],Data_F,1,'B11');
        
    else
        SaveObjectAsImage(handles.Diagram,[PathName FileName]);
    end
end


% ���� "�������� �����������"
function AddImageToList_Callback(hObject, eventdata, handles)

global Original;                  % �������� �����������
global Noised;              % ����������� �������
global Filtered;            % ��������������� �����������
global Assessment_N;              % ������ ����������� �����������
global Assessment_F;              % ������ ��������������� �����������

[FileName, PathName] = uigetfile({'*.jpg';'*.tif';'*.bmp';'*.png'},...
                                    '�������� ���� ��������� �����������',...
                                    [cd '\Test Images']);    % ����� ������� 
if ~FileName                                 % ��������, ��� �� ������ ����
    return;
end

DotPositions = strfind(FileName,'.');            % ��������� ����� � ��������
format = FileName(DotPositions(end)+1:end);      % ������� ������ ����� ����� ��������� �����

if strcmp(format,'gif')                  % !����� �� ������
    h = errordlg('gif ������ �� ��������������','KAAIP');
    set(h, 'WindowStyle', 'modal');
    return;
end

try             % �������� ������� ��������
    Temp = imread([PathName FileName]);         % ��������� ��
catch           % ���� ���� �� ���� ���� �������� :'(
    h = errordlg('� ������ ���-�� �� ���. �������� ������','KAAIP');
    set(h, 'WindowStyle', 'modal');
    return;
end

if length(size(Original)) ~= length(size(Temp)) || ~all(size(Original) == size(Temp))   % ���� ����������� �� ������� - ������
    h = errordlg('����������� ���������� ����������� � ��������� �� ���������. �������� ������ �����������','KAAIP');
    set(h, 'WindowStyle', 'modal');
    return;
end

Noised(:,:,:,end+1) = Original;
Filtered(:,:,:,end+1) = Temp;

str = cell(size(Noised,4),1);
for p = 1:size(Filtered,4)
    str{p} = ['����������� � ' num2str(p)];
end

set(handles.NoisedMenu,'String',str,'Value',1,'Enable','on');
set(handles.FilteredMenu,'String',str,'Value',1,'Enable','on');

% ���� ����� ���������� ����� 10, �������� �������
if size(Noised,4) > 10
    set(handles.GraphSlider,'Min',1,...
        'Max',size(Noised,4)-9,...
        'Enable','on',...
        'SliderStep',[1/(size(Noised,4)-10) 10/(size(Noised,4)-10)]);
end

% ������ ������ "���������-���������"
new_str = [ num2str(p) ...
            ') �������� ����������� ' char(8594) ...
            ' ��������� ����������� ' char(8594) ...
            ' ���������������� �����������'];
        
NewList = vertcat(get(handles.NoiseFilterList,'String'),new_str);
set(handles.NoiseFilterList,'String',NewList);

if size(Noised,4) > 1       % ���� � ������ ����� 1� ���������, ����� ����� ���-�� �������
    set(handles.DeleteListPosition,'Enable','on');
end

if isnan(Assessment_F(end).SSIM(1))
    SSIM = 0;
else
    SSIM = 2;
end

Assessment = GetAssessment(Original,Temp,SSIM);
Assessment_F(end+1) = Assessment;
Assessment = GetAssessment(Original,Original,SSIM);
Assessment_N(end+1) = Assessment;

% ������� ����������, ������� �������� ������� � �������� ��������
ShowMenu_Callback(hObject, eventdata, handles);
AssessMenu_Callback(hObject, eventdata, handles);


% ���� "������� ��������� �������"
function DeleteListPosition_Callback(hObject, eventdata, handles)

global Noised;              % ����������� �������
global Filtered;            % ��������������� �����������
global Assessment_N;              % ������ ����������� �����������
global Assessment_F;              % ������ ��������������� �����������

answer = questdlg(...
        '������ �������� ������. ������� �������?',...
        '�������� �������','��','���','���');
if ~strcmp(answer,'��')             % ���� ����� "��", ����� �� ������ � ����
    return;                         % � ������� �� ����� �������
end

DeletePos = get(handles.NoiseFilterList,'Value');
List = get(handles.NoiseFilterList,'String');

Noised(:,:,:,DeletePos) = [];
Filtered(:,:,:,DeletePos) = [];
Assessment_N(DeletePos) = [];
Assessment_F(DeletePos) = [];

List(DeletePos) = [];
for i = DeletePos : size(Noised,4)    % �� ���� ��������� ������� �������� ���������� �����
    List(i) = regexprep(List(i),num2str(i + 1),num2str(i),'once');
end

str = cell(size(Noised,4),1);       % ���������� ������ ������
for p = 1:size(Filtered,4)
    str{p} = ['����������� � ' num2str(p)];
end

set(handles.NoisedMenu,'String',str,'Value',1,'Enable','on');
set(handles.FilteredMenu,'String',str,'Value',1,'Enable','on');
set(handles.NoiseFilterList,'String',List,'Value',1);

% ���� ����� ��������� ����� 10, �������� �������
if size(Noised,4) > 10
    set(handles.GraphSlider,'Min',1,...
        'Value',1,...
        'Max',size(Noised,4)-9,...
        'Enable','on',...
        'SliderStep',[1/(size(Noised,4)-10) 10/(size(Noised,4)-10)]);
    
else    % ����� ������� �����������
    set(handles.GraphSlider,'Enable','off');
end

% ������� ����������, ������� �������� ������� � �������� ��������
ShowMenu_Callback(hObject, eventdata, handles);
AssessMenu_Callback(hObject, eventdata, handles);

if size(Noised,4) == 1       % ���� � ������ ������ 1� ���������, ����� ������ �������
    set(handles.DeleteListPosition,'Enable','off');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%% �������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ������� �������
function ChannelSlider_Callback(hObject, ~, handles)

global Assessment_N;              % ������� �/� ������������ �����������
global Assessment_F;              % ������� �/� ���������������� �����������

ch = get(handles.ChannelSlider,'Value');
string = get(handles.AssessMenu,'String');              
Assess =  char(string(get(handles.AssessMenu,'Value')));
MenuString = get(handles.ShowMenu,'String');
WhatToShow = MenuString(get(handles.ShowMenu,'Value'));
NMV = handles.NoisedMenu.Value;
FMV = handles.FilteredMenu.Value;

if hObject ~= handles.ShowButton
    
    if ch == 0          % ���� �� ����������� �����������
        
        handles.Red.Value = 1;
        handles.Green.Value = 2;
        handles.Blue.Value = 3;
    else
        handles.Red.Value = ch;
        handles.Green.Value = ch;
        handles.Blue.Value = ch;
    end
end

channel(1) = handles.Red.Value;
channel(2) = handles.Green.Value;
channel(3) = handles.Blue.Value;

if handles.AssessMenu.Value == 5 || handles.AssessMenu.Value == 6
    dB = ' ��';
else
    dB = '';
end

switch char(WhatToShow)       % �������, ��� ����� ��������
    
    case {'�����������','SSIM-�����������'}   
        
        if ch == 0
            handles.ChannelString.String = 'RGB';
        else
            handles.ChannelString.String = ['����� � ' num2str(ch)];
        end
       
        Im = getappdata(handles.OriginalAxes,'Image');
        Im = Im(:,:,channel);
        ImObject = findobj('Parent',handles.OriginalAxes,'Tag','ImObject');
        ImObject.CData = Im;     

        Im = getappdata(handles.NoiseAxes,'Image');        

        if ~isempty(Im)
            
            Im = Im(:,:,channel,handles.NoisedMenu.Value);
            ImObject = findobj('Parent',handles.NoiseAxes,'Tag','ImObject');
            ImObject.CData = Im;
            
            if strcmp(char(WhatToShow),'�����������')   % ��� SSIM ������ �� �������
                
                if getfield(Assessment_N,{NMV},Assess,{ch+1}) == inf
                    val = char(8734);
                elseif isnan(getfield(Assessment_N,{NMV},Assess,{ch+1})) == 1
                    val = char(8709);
                else
                    val = num2str(getfield(Assessment_N,{NMV},Assess,{ch+1}));
                end
                
                title(handles.NoiseAxes,[Assess ' = ' num2str(val) dB],'FontSize',10);
            end
            
            Im = getappdata(handles.FiltAxes,'Image');
            Im = Im(:,:,channel,handles.FilteredMenu.Value);
            ImObject = findobj('Parent',handles.FiltAxes,'Tag','ImObject');
            ImObject.CData = Im;
            
            if strcmp(char(WhatToShow),'�����������')   % ��� SSIM ������ �� �������
                if getfield(Assessment_F,{FMV},Assess,{ch+1}) == inf
                    val = char(8734);
                elseif isnan(getfield(Assessment_F,{FMV},Assess,{ch+1})) == 1
                    val = char(8709);
                else
                    val = num2str(getfield(Assessment_F,{FMV},Assess,{ch+1}));
                end
                
                title(handles.FiltAxes,[Assess ' = ' num2str(val) dB],'FontSize',10);
            end
        end

    case {'����������� ���������','����������� HSV'}
        
        if ch == 0 && strcmp(char(WhatToShow),'����������� ���������')
            handles.ChannelString.String = 'RGB';
        elseif ch == 0 && strcmp(char(WhatToShow),'����������� HSV')            
            handles.ChannelString.String = 'HSV';
        else
            handles.ChannelString.String = ['����� � ' num2str(ch)];
        end       
        
        Im = getappdata(handles.OriginalAxes,'Image');
        HistObject = findobj('Parent',handles.OriginalAxes,'Tag','Hist');
        
        for x = 1:size(Im,3)
            HistObject(x).Data = Im(:,:,channel(x));            
        end
        
        Im = getappdata(handles.NoiseAxes,'Image');    
        
        if ~isempty(Im)
            
            HistObject = findobj('Parent',handles.NoiseAxes,'Tag','Hist');
            
            for x = 1:size(Im,3)
                HistObject(x).Data = Im(:,:,channel(x));
            end
            
            Im = getappdata(handles.FiltAxes,'Image');
            HistObject = findobj('Parent',handles.FiltAxes,'Tag','Hist');
            
            for x = 1:size(Im,3)
                HistObject(x).Data = Im(:,:,channel(x));
            end            
        end      
        
    otherwise        
        assert(0,'������ ���� "����������" ��������� �� ���������');        
end       

  
% ������� ��������
function GraphSlider_Callback(hObject, ~, handles)

global Assessment_N;        % ������ ������ ���������� �����������

% ������ ��������� 10 ��������, � ������ ������ ���� ������ ������� ����

if hObject == handles.NoiseFilterList      % ���� �� ������, �� ��� ��������� ������������� ������ ���� "���-���������"        
    BarMin = get(handles.NoiseFilterList,'Value');
else
    BarMin = round(get(handles.GraphSlider,'Value'));  % ��������� �������� ��������
end
 
BarMax = BarMin + 9;                    % ����� ��������� ������������ �������

if BarMax >= size(Assessment_N,2)       % ���� �� ������, ��� ������ ������� ������
    BarMax = size(Assessment_N,2);      % ������ ��� �������
    BarMin = size(Assessment_N,2) - 9;
end

if BarMin < 1
    BarMin = 1;
end

set(handles.GraphSlider,'Value',BarMin);
ylim(handles.Diagram,[BarMin-0.5 BarMax+0.5]);   % ������������� ������ �� ��� �
 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ������ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ������ "����������"
function ShowButton_Callback(hObject, eventdata, handles)

set(handles.ChannelSlider,'Value',0);             % ������ �������� ��������
ChannelSlider_Callback(hObject, eventdata, handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ������  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ���������� ������ �� ������ ����������� �����������
function NoisedMenu_Callback(hObject, eventdata, handles)

set(handles.FiltAgainNoised,'Label',...
    ['���������� ���������� ����������� � ' num2str(get(handles.NoisedMenu,'Value'))]);
ChannelSlider_Callback(hObject, eventdata, handles);


% ���������� ������ �� ������ ��������������� �����������
function FilteredMenu_Callback(hObject, eventdata, handles)

set(handles.FiltAgain,'Label',...
    ['���������� ����� ������������  ����������� � ' num2str(get(handles.FilteredMenu,'Value'))]);
ChannelSlider_Callback(hObject, eventdata, handles);


% ���������� ������ "����� ��������������"
function AssessMenu_Callback(hObject, eventdata, handles)

global Assessment_N;        % ������ ������ ���������� �����������
global Assessment_F;        % ������ ������ ������������ �����������

AssessType = get(handles.AssessMenu,'Value');   % ��� ������ ��� �����������
AssessStr = get(handles.AssessMenu,'String');   % ������ � ���������� ������

% ���� ������������ ������� ��� ����, ������ 1 �����������
if handles.ViewNoisedCheck.Value == 0 && handles.ViewFilteredCheck.Value == 0      
    set(hObject,'Value',1);
end
NoiseCheck = handles.ViewNoisedCheck.Value;     % ���� 1, �� ���������� ������ ���������
FilterCheck = handles.ViewFilteredCheck.Value;  % ���� 1, �� ���������� ������ ���������


Y = zeros(size(Assessment_N,2),2);      % ������ ��������
Ticks = cell(size(Assessment_N,2),1);   % ������� �������� �� ���

for i = 1:size(Assessment_N,2)
                
    % ������� ������ �������� ��� barh
    Y(i,:) = [  getfield(Assessment_N,{i},char(AssessStr(AssessType)),{1})...
                getfield(Assessment_F,{i},char(AssessStr(AssessType)),{1})];
        
    if NoiseCheck == 1 && FilterCheck == 1       
        
        Ticks(i) = {['\bf' num2str(i) '\rm: ' num2str(Y(i,1),'%10.3E') ...
                                        ' / ' num2str(Y(i,2),'%10.3E')]};
        
    elseif NoiseCheck == 1 && FilterCheck == 0 
        
        Ticks(i) = {['\bf' num2str(i) '\rm: ' num2str(Y(i,1),'%10.3E')]};

    elseif NoiseCheck == 0 && FilterCheck == 1  
        
        Ticks(i) = {['\bf' num2str(i) '\rm: ' num2str(Y(i,1),'%10.3E')]};
    end
end

if size(Assessment_N,2) == 1    % ���� ��������� ��������� ������ ����� ���������
    Y(end+1,:) = Y;             % ������� ������ ������ ��� ���������� ������ barh
end
    
NB = barh(handles.Diagram,1:length(Y),Y,'hist');
set(NB(1),'FaceColor',[205/255 92/255 92/255]);
set(NB(2),'FaceColor',[255/255 127/255 80/255]);

if NoiseCheck == 1 && FilterCheck == 0
    set(NB(1),'Visible','on');
    set(NB(2),'Visible','off');
elseif NoiseCheck == 0 && FilterCheck == 1
    set(NB(2),'Visible','on');
    set(NB(1),'Visible','off');
end

set(NB,'UIContextMenu',handles.DiagramContextMenu);
set(handles.Diagram,'YTick',1:length(Y),...
                    'YTickLabel',Ticks,...
                    'YDir','reverse',...
                    'FontSize',8);
                
if AssessType == 5 || AssessType == 6
    title(handles.Diagram,strcat(AssessStr(AssessType),', ��'),'FontSize',10);
else
    title(handles.Diagram,AssessStr(AssessType),'FontSize',10);
end
    
GraphSlider_Callback(hObject,eventdata,handles);
ChannelSlider_Callback(hObject, eventdata, handles);


% ������ "���������-���������"
function NoiseFilterList_Callback(hObject, eventdata, handles)

ChosenOne = get(handles.NoiseFilterList,'Value');       % ����� ������� ������ ������

set(handles.NoisedMenu,'Value',ChosenOne);              % ��������� ��������
set(handles.FilteredMenu,'Value',ChosenOne);
FilteredMenu_Callback(hObject, eventdata, handles);     % ����� 

if strcmp(get(handles.GraphSlider,'Enable'),'on') == 1
    GraphSlider_Callback(hObject, ChosenOne, handles)       % ����� ������ ������
end


% ���������� ������ "��������"
function ShowMenu_Callback(hObject, eventdata, handles)

global Original;            % �������� �����������
global Noised;              % ����������� �������
global Filtered;            % ��������������� �����������
global Assessment_N;              % ������� �/� ������������ �����������
global Assessment_F;              % ������� �/� ���������������� �����������

% ��������� ����������� �������� � ��������� ������ ����������� � ���������
% ��� UserData, ����� ������� ������� ������ �����/����������� � ��.

MenuString = get(handles.ShowMenu,'String');
WhatToShow = MenuString(get(handles.ShowMenu,'Value'));

if size(Original,3) ~= 1            % ���� �� ����������� �����������
    ch(1) = handles.Red.Value;
    ch(2) = handles.Green.Value;
    ch(3) = handles.Blue.Value;
else
    ch = 1;
end

switch char(WhatToShow)       % �������, ��� ����� ��������
    
    case '�����������'
        
        setappdata(handles.OriginalAxes,'Image',Original);        
        handles.uipanel8.Visible = 'on';
        
        OI = imshow(Original(:,:,ch),'Parent',handles.OriginalAxes);  
        set(OI,'UIContextMenu',handles.OriginalImageContextMenu,'Tag','ImObject');   
        set(handles.OriginalAxes,'Position',[20 50 300 300]);       % ������ ��� �� �����, ����� ����������
                       
        if ~isempty(Noised)
            setappdata(handles.NoiseAxes,'Image',Noised);
            ON = imshow(Noised(:,:,ch,handles.NoisedMenu.Value),'Parent',handles.NoiseAxes); 
            set(ON,'UIContextMenu',handles.NoisedImageContextMenu,'Tag','ImObject');
            set(handles.NoiseAxes,'Position',[20 50 300 300]);      % ������ ��� �� �����, ����� ����������
            
            setappdata(handles.FiltAxes,'Image',Filtered);
            OF = imshow(Filtered(:,:,ch,handles.FilteredMenu.Value),'Parent',handles.FiltAxes);
            set(OF,'UIContextMenu',handles.FilteredImageContextMenu,'Tag','ImObject');
            set(handles.FiltAxes,'Position',[20 50 300 300]);
        end
        
    case {'����������� ���������','����������� HSV'}
        
        if strcmp('����������� ���������',char(WhatToShow))
            
            Im_O = Original;        % ������������� ����������� ��� ����������
                
            if ~isempty(Noised)                        
                Im_N = Noised;
                Im_F = Filtered;
            end
            
        else            
            Im_O = uint8(255*rgb2hsv(Original));
            
            if ~isempty(Noised)
                
                Im_N = zeros(size(Noised));
                Im_F = zeros(size(Noised));
                
                for x = 1:size(Noised,4)
                    Im_N(:,:,:,x) = uint8(255*rgb2hsv(Noised(:,:,:,x)));
                    Im_F(:,:,:,x) = uint8(255*rgb2hsv(Filtered(:,:,:,x)));
                end
            end
        end        
        
        setappdata(handles.OriginalAxes,'Image',Im_O);
        Hist = BuildHist(handles.OriginalAxes,Im_O,'');
        set(Hist,'UIContextMenu',handles.OriginalHistContextMenu,'Tag','Hist');
        set(handles.OriginalAxes,'UIContextMenu',handles.OriginalHistContextMenu);
        
        handles.uipanel8.Visible = 'off';
        set(handles.OriginalAxes,'Position',[75 70 250 280]);
        
        set([   handles.SaveNoisedHist;...
                handles.SaveFilteredHist;...
                handles.SaveOriginalHist;...
                handles.CopyOriginalHist;...
                handles.CopyNoisedHist;...
                handles.CopyFilteredHist],'Enable','on');
                
        if ~isempty(Noised)
            
            setappdata(handles.NoiseAxes,'Image',Im_N);
            set(handles.NoiseAxes,'Position',[75 70 250 280]);
            set(handles.NoiseAxes,'UIContextMenu',handles.NoisedHistContextMenu);
            NHist = BuildHist(handles.NoiseAxes,Im_N(:,:,ch,handles.NoisedMenu.Value),'');
            set(NHist,'UIContextMenu',handles.NoisedHistContextMenu,'Tag','Hist');            
            
            setappdata(handles.FiltAxes,'Image',Im_F);
            set(handles.FiltAxes,'Position',[75 70 250 280]);
            set(handles.FiltAxes,'UIContextMenu',handles.FilteredHistContextMenu);
            FHist = BuildHist(handles.FiltAxes,Im_F(:,:,ch,handles.FilteredMenu.Value),'');
            set(FHist,'UIContextMenu',handles.FilteredHistContextMenu,'Tag','Hist');            
            
        end
        
    case 'SSIM-�����������'
        
        setappdata(handles.OriginalAxes,'Image',Original);   
        Im_N = zeros(size(Original,1),size(Original,2),size(Original,3),size(Assessment_N,2),'uint8');
        Im_F = zeros(size(Im_N),'uint8');
        
        for x = 1:size(Assessment_N,2)
            Im_N(:,:,:,x) = Assessment_N(x).SSIM_Image;
            Im_F(:,:,:,x) = Assessment_F(x).SSIM_Image;
        end           
        
        handles.uipanel8.Visible = 'on';
        
        OI = imshow(Original(:,:,ch),'Parent',handles.OriginalAxes);  
        set(OI,'UIContextMenu',handles.OriginalImageContextMenu,'Tag','ImObject');   % ����������� ����������� ����
        set(handles.OriginalAxes,'Position',[20 50 300 300]);       % ������ ��� �� �����, ����� ����������
        
        setappdata(handles.NoiseAxes,'Image',Im_N); 
        ON = imshow(Im_N(:,:,ch,handles.NoisedMenu.Value),'Parent',handles.NoiseAxes);
        set(ON,'UIContextMenu',handles.NoisedImageContextMenu,'Tag','ImObject'); % ������������ ����������� ���� � ���
        set(handles.NoiseAxes,'Position',[20 50 300 300]);      % ������ ��� �� �����, ����� ����������
        
        setappdata(handles.FiltAxes,'Image',Im_F); 
        OF = imshow(Im_F(:,:,ch,handles.FilteredMenu.Value),'Parent',handles.FiltAxes);
        set(OF,'UIContextMenu',handles.FilteredImageContextMenu,'Tag','ImObject');
        set(handles.FiltAxes,'Position',[20 50 300 300]);
        
    otherwise
        
        assert(0,'������ ���� "����������" ��������� �� ���������');        
end

ChannelSlider_Callback(hObject, eventdata, handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ���� ���������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ���� "������� ���� ������"
function Filtration_Callback(hObject, eventdata, handles)

global Parametrs;           % ��������� ������������ (���� � �������)
global Noises;              % ������ ���������� ����������
global Filters;             % ������ ���������� ����������
global Noised;              % ����������� �������
global Filtered;            % ��������������� �����������
global FilteredAsOriginal;  % ����� ������������ �����������
global ContinueProcessing;  % ��� ���������� ����, ��� ����� ���������� ���������, �� ������ ��������� ����������
global StatAndMLT;
global CV
global Original;

Noises(:,:) = [];       
Filters = struct([]);  
Parametrs = cell(1);        
        
Menu = open('menu.fig');
menu_handles = guihandles(Menu);

scr_res = get(0, 'ScreenSize');             % ��������� ���������� ������ � ����
fig = get(Menu,'Position');         % ������ ������� ����
set(Menu,   'Position',[(scr_res(3)-fig(3))/2 (scr_res(4)-fig(4))/2 fig(3) fig(4)],...
            'CloseRequestFcn','delete(gcf);'); 
        
% � ����� ����� ���������� ��������� - ���������� ��� ����
if hObject == handles.ContinueProcessing
    ContinueProcessing = true;
else
    ContinueProcessing = false;
end
      
        
% ���� ��������� �� ���� "������������ ��������������� ����������� �"
if hObject == handles.FiltAgain(1) || hObject == handles.FiltAgain(2)      
    
    FilteredAsOriginal = Filtered(:,:,:,get(handles.FilteredMenu,'Value'));
    
elseif hObject == handles.FiltAgainNoised(1) || hObject == handles.FiltAgainNoised(2)    
    
    FilteredAsOriginal = Noised(:,:,:,get(handles.NoisedMenu,'Value'));
else        
    FilteredAsOriginal = [];
end

set(menu_handles.ProcessingOrderString,'String',...
    ['��������� ����������� ' char(8594) ' ��������� ' char(8594) ' ���������']);
    
% ����������� � �������� ������� ��������
set(menu_handles.NoiseType,'Callback',{@NoiseType_Callback,menu_handles});
set(menu_handles.FilterType,'Callback',{@FilterType_Callback,menu_handles});
set(menu_handles.NoiseFilterString,'Callback',{@NoiseFilterString_Callback,menu_handles});

set(menu_handles.Aslider,'Callback',{@Aslider_Callback,menu_handles});
set(menu_handles.Bslider,'Callback',{@Bslider_Callback,menu_handles});
set(menu_handles.DeleteSlider,'Callback',{@DeleteSlider_Callback,menu_handles});
set(menu_handles.AlphaSlider,'Callback',{@AlphaSlider_Callback,menu_handles});
set(menu_handles.BetaSlider,'Callback',{@BetaSlider_Callback,menu_handles});
set(menu_handles.GammaSlider,'Callback',{@GammaSlider_Callback,menu_handles});
set(menu_handles.DeltaSlider,'Callback',{@DeltaSlider_Callback,menu_handles});
set(menu_handles.EpsilonSlider,'Callback',{@EpsilonSlider_Callback,menu_handles});
set(menu_handles.ZetaSlider,'Callback',{@ZetaSlider_Callback,menu_handles});
set(menu_handles.EtaSlider,'Callback',{@EtaSlider_Callback,menu_handles});
set(menu_handles.TetaSlider,'Callback',{@TetaSlider_Callback,menu_handles});

set(menu_handles.PreviewButton,'Callback',{@PreviewButton_Callback,menu_handles});
set(menu_handles.HistButton,'Callback',{@HistButton_Callback,menu_handles});
set(menu_handles.AddButton,'Callback',{@AddButton_Callback,menu_handles});
set(menu_handles.DeleteButton,'Callback',{@DeleteButton_Callback,menu_handles});
set(menu_handles.CancelButton,'Callback',{@CancelButton_Callback,menu_handles});
set(menu_handles.FiltParButton1,'Callback',{@FiltParButton1_Callback,menu_handles});
set(menu_handles.FiltParButton2,'Callback',{@FiltParButton2_Callback,menu_handles});
set(menu_handles.ApplyButton,'Callback',{@ApplyButton_Callback,menu_handles,handles});
set(menu_handles.NoisedImageHistButton,'Callback',{@NoisedImageHistButton_Callback,menu_handles});
set(menu_handles.ImageHistButton,'Callback',{@ImageHistButton_Callback,menu_handles});

set(menu_handles.FiltParMenu1,'Callback',{@FiltParMenu1_Callback,menu_handles});
set(menu_handles.FiltParMenu2,'Callback',{@FiltParMenu2_Callback,menu_handles});
set(menu_handles.FiltParMenu3,'Callback',{@FiltParMenu3_Callback,menu_handles});

set(menu_handles.MaskTable,'CellSelectionCallback',{@MaskTable_CellSelectionCallback,menu_handles});
set(menu_handles.MaskTable1,'CellSelectionCallback',{@MaskTable1_CellSelectionCallback,menu_handles});
set([menu_handles.MaskTable menu_handles.MaskTable1],'Data',ones(3));

set(menu_handles.CopyMask,'Callback',{@CopyMask_Callback,menu_handles});
set(menu_handles.SaveMask,'Callback',{@SaveMask_Callback,menu_handles});
set(menu_handles.SaveMaskXLSX,'Callback',{@SaveMaskXLSX_Callback,menu_handles});

NoiseType_Callback(hObject, eventdata, menu_handles);
FilterType_Callback(hObject, eventdata, menu_handles);
Menu.Visible = 'on';


if ~StatAndMLT
    str = menu_handles.NoiseType.String;
    str = str(1:end-2,:); 
    menu_handles.NoiseType.String = str;    
end

if ~CV
    str = menu_handles.FilterType.String;
    str = str(1:end-1,:); 
    menu_handles.FilterType.String = str;    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% ������� ���� "MENU" %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ������ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ������ �����
function NoiseType_Callback(~, ~, menu_handles)

global Original;            % �������� �����������


NoiseType = get(menu_handles.NoiseType,'Value');     % ��������� ����� ���������� ����

NoiseWithHist = [2 4 5 11 12];            % ������ �����, ��� ���. ������ �����������
NoiseWith_A = [6 7 8 9 10];           % ----//-----, � ���������� �
NoiseWith_B = [2 4 5 10];            % ----//-----, � ���������� �

% ������ �������� � ������
set([menu_handles.A;...
    menu_handles.Aslider;...
    menu_handles.text13;...
    menu_handles.text12;...
    menu_handles.B;...
    menu_handles.Bslider;...
    menu_handles.HistButton],'Visible','off');    

set(menu_handles.NoisedImageHistButton,'Visible','on'); % ����� ��� ������� ������, ����� ���������� ����

if  any(NoiseWith_A == NoiseType)                       % ���� ������� ����, ������� ����� ������� �
    set([menu_handles.A menu_handles.Aslider],'Visible','on');    % ���������� ������ � �������
    set(menu_handles.text12,'Visible','on');                 
end

if  any(NoiseWithHist == NoiseType)                     % ������� ����, ��� ������� �������� �����������
    set([menu_handles.A menu_handles.Aslider],'Visible','on');    % ���������� ������ � �������
    set(menu_handles.text12,'Visible','on');                  
    set(menu_handles.HistButton,'Visible','on');    
end

if  any(NoiseWith_B == NoiseType)                       % ���� ������ ����, ������� ����� ������� �
    set([menu_handles.A menu_handles.Aslider],'Visible','on');    % ���������� ������ � �������
    set([menu_handles.text12 menu_handles.text13],'Visible','on');                  
    set([menu_handles.B menu_handles.Bslider],'Visible','on');    % ���������� �������
end

switch  get(menu_handles.NoiseType,'Value')
    case 1          % ����������� ���   
        
        set(menu_handles.NoisedImageHistButton,'Visible','off');        
            
    case 2          % ���������� ���
        set(menu_handles.A,'String',[char(963) ' = ']);       % ������ ��������� ��������
        set(menu_handles.text12,'String','80');
        set(menu_handles.Aslider,'Value',80,'Max',255,'Min',1,'SliderStep',[1/254 10/254]);  
        set(menu_handles.B,'String',[char(956) ' = ']);                      % ������ ��������� ��������
        set(menu_handles.text13,'String','0');
        set(menu_handles.Bslider,'Value',0,'Max',255,'Min',-255,'SliderStep',[1/510 10/510]);  
        
    case 3          % ��� ��������
          
    case 4          %  ������� ���
        set(menu_handles.A,'String',[char(945) ' = ']);       % ������ ��������� ��������
        set(menu_handles.text12,'String','1');
        set(menu_handles.Aslider,'Value',1,'Max',40,'Min',1,'SliderStep',[1/39 10/39]);
        set(menu_handles.B,'String',[char(956) ' = ']);                      % ������ ��������� ��������
        set(menu_handles.text13,'String','0');
        set(menu_handles.Bslider,'Value',0,'Max',255,'Min',-255,'SliderStep',[1/510 10/510]);
        
    case 5         % ����������� ���  
        set(menu_handles.A,'String','A =');                      % ������ ��������� ��������
        set(menu_handles.text12,'String','0');
        set(menu_handles.Aslider,'Value',0,'Max',254,'Min',-255,'SliderStep',[1/509 10/509]);
        set(menu_handles.B,'String','B =');                      % ������ ��������� ��������
        set(menu_handles.text13,'String','100');
        set(menu_handles.Bslider,'Value',100,'Max',255,'Min',-254,'SliderStep',[1/509 10/509]);         
        
    case 6          % �����-��� 
        set(menu_handles.A,'String',[char(963) char(178) ' = ']);       % ������ ��������� ��������
        set(menu_handles.text12,'String','80');
        set(menu_handles.Aslider,'Value',80,'Max',255,'Min',1,'SliderStep',[1/254 10/254]);
        
    case {7,8,9}          % ����-����� ���, ���� ���, ����� ���  
        set(menu_handles.A,'String','���������,%:');
        set(menu_handles.text12,'String','10');
        set(menu_handles.Aslider,'Value',10,'Max',100,'Min',1,'SliderStep',[1/99 10/99]);
        
    case 10         % �������� ���        
        set(menu_handles.A,'String','����� �����: ');
        set(menu_handles.text12,'String','10');
        set(menu_handles.Aslider,'Value',10,'Max',max(size(Original)),'Min',1,...
            'SliderStep',[1/(max(size(Original))-1) 10/(max(size(Original))-1)]); 
        set(menu_handles.B,'String',['����,' char(186) ': ']);                      % ������ ��������� ��������
        set(menu_handles.text13,'String','0');
        set(menu_handles.Bslider,'Value',0,'Max',360,'Min',0,'SliderStep',[1/360 10/360]);    
        
    case 11          % ����� ��� 
        set(menu_handles.A,'String',[char(963) ' = ']);       % ������ ��������� ��������
        set(menu_handles.text12,'String','0.5');
        set(menu_handles.Aslider,'Value',0.5,'Max',1,'Min',0.01,'SliderStep',[0.01/0.99 0.1/0.99]);  
        
    case 12          % ���������������� ���    
        set(menu_handles.A,'String',[char(955) ' = ']);       % ������ ��������� ��������
        set(menu_handles.text12,'String','1');
        set(menu_handles.Aslider,'Value',1,'Max',40,'Min',1,'SliderStep',[1/39 10/39]);
end


% ������ ��������
function FilterType_Callback(~,~,menu_handles)

global Original;        % ����������� �������

FilterType = get(menu_handles.FilterType,'Value');   %��������� �������� ���������� �������

FilterWithMaskTable = [2 5 11 28];                         % ������ ��������, ������� ����� 1� �������
FilterWithMaskTable1 = 5;                         % ������ ��������, ������� ����� 2� �������
FilterWithMenu1 = [2 6 8 9 11 13:14 19 22 24:28];
FilterWithMenu2 = [2:6 7 9 10 11 14 25:26 28:30 34:35];                       % ������ ��������, ������� ����� 2� ����
FilterWithMenu3 = [4 9 15 17 18 25 29:31 34];        % ������ ��������, ������� ����� 3� ����

                                                % ������ ��������, ������� ����� ��������  
FilterWith_FirstSlider = [3 5:9 10:12 13 15:18 20:23 24:27 29 31:33 35];        
FilterWith_SecondSlider = [4 5:9 10:12 16 29 32:35];      
FilterWith_ThirdSlider = [5 7:11 16 33 34];
FilterWith_FourthSlider = [4 5 7:10 29 33:35];
FilterWith_FifthSlider = [8 9 33];
FilterWith_SixthSlider = 9;
FilterWith_SeventhSlider = [9 29 34];
FilterWith_EigthSlider = 9;

FilterWith_Exp_alpha_Button = [5 6 8 11 33];    % ������� � ��������
FilterWith_Exp_beta_Button = [4:6 32];        
        
FilterWithIndends = [2 6 8 11 13:14 19:27];  % ������� � ������� ���� ���������� ������

% ������, ������������� � 1 � ���������� ��� ��������, � ����� ��������� ��, ��� �����
ItemsToHide = get(menu_handles.uipanel3,'Children');
set(ItemsToHide,'Visible','off','Enable','on');
set(menu_handles.FilterType,'Visible','on');
set(menu_handles.IndentMenu,'String',{'����������','����','��������','�����'});
set(menu_handles.MaskText,'String','');
set([...
    menu_handles.IndentMenu;...
    menu_handles.FiltParMenu1;...
    menu_handles.FiltParMenu2;...
    menu_handles.FiltParMenu3;...
    ],'Value',1);

%%%% �������, ����� �������� ����� ��������
if any(FilterWithIndends == FilterType)       % ���� ���������� ������� ����� ���� ���������� ������
   set([menu_handles.IndentMenu; menu_handles.IndentText],'Visible','on');
end

if any(FilterWithMenu1 == FilterType)       % ���� ���������� ������� ����� 1� ����
   set([menu_handles.FiltParMenu1; menu_handles.FiltParText1],'Visible','on');
end

if any(FilterWithMenu2 == FilterType)       % ���� ���������� ������� ����� 2� ����
    set([menu_handles.FiltParMenu2; menu_handles.FiltParText2],'Visible','on');
end

if any(FilterWithMenu3 == FilterType)       % ���� ���������� ������� ����� 3� ����
    set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on');
end

if any(FilterWithMaskTable == FilterType)    % ���� ���������� ������� ����� ���� �����
    set([menu_handles.MaskText menu_handles.MaskTable],'Visible','on');
end

if any(FilterWithMaskTable1 == FilterType)    % ���� ���������� ������� ����� ���� �����
    set([menu_handles.MaskText menu_handles.MaskTable1],'Visible','on');
end

if any(FilterWith_FirstSlider == FilterType)       % ���� ���������� ������� ����� 1� �������
    set([menu_handles.AlphaText;...
        menu_handles.AlphaSlider;...
        menu_handles.AlphaValText],'Visible','on');
end

if  any(FilterWith_SecondSlider == FilterType)       % ���� ���������� ������� ����� 2� �������
    set([menu_handles.BetaText;
        menu_handles.BetaSlider;...
        menu_handles.BetaValText],'Visible','on');
end

if  any(FilterWith_ThirdSlider == FilterType)       % ���� ���������� ������� ����� 3� �������
    set([menu_handles.GammaText;
        menu_handles.GammaSlider;...
        menu_handles.GammaValText],'Visible','on');
end

if  any(FilterWith_FourthSlider == FilterType)       % ���� ���������� ������� ����� 4� �������
    set([menu_handles.DeltaText;
        menu_handles.DeltaSlider;...
        menu_handles.DeltaValText],'Visible','on');
end

if  any(FilterWith_FifthSlider == FilterType)       % ���� ���������� ������� ����� 5� �������
    set([menu_handles.EpsilonText;
        menu_handles.EpsilonSlider;...
        menu_handles.EpsilonValText],'Visible','on');
end

if  any(FilterWith_SixthSlider == FilterType)       % ���� ���������� ������� ����� 6� �������
    set([menu_handles.ZetaText;
        menu_handles.ZetaSlider;...
        menu_handles.ZetaValText],'Visible','on');
end

if  any(FilterWith_SeventhSlider == FilterType)       % ���� ���������� ������� ����� 7� �������
    set(menu_handles.EtaSlider,'Visible','on');
end

if  any(FilterWith_EigthSlider == FilterType)       % ���� ���������� ������� ����� 8� �������
    set([menu_handles.TetaText;
        menu_handles.TetaSlider;...
        menu_handles.TetaValText],'Visible','on');
end

if  any(FilterWith_Exp_alpha_Button == FilterType)       % ���� ���������� ������� ����� ������ ���������� ��������
    set(menu_handles.FiltParButton1,'Visible','on');
end

if  any(FilterWith_Exp_beta_Button == FilterType)       % ���� ���������� ������� ����� ������ ���������� ��������
    set(menu_handles.FiltParButton2,'Visible','on');
end

% ��������� ���������� � ����������� �� �������
switch FilterType
    case 1       % ��� ���������
        
    case 2       % ���������
        set(menu_handles.FiltParText1,'String','������ �����');
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9'});
        set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',34,...
            'Position',[400 5 182 182],...
            'ColumnWidth',{60 60 60});
        set(menu_handles.MaskText,'String','����� �������','Position',[400 200 182 18]);
        
        set(menu_handles.FiltParText2,'String','����� �������');
        set(menu_handles.FiltParMenu2,'String',{'������������','���. ��������','����������','N-������'}); 
        
        set(menu_handles.FiltParText3,'String','������� N');
        set(menu_handles.FiltParMenu3,'String',{'1';'2';'3';char(8734)});
        
        set(menu_handles.IndentMenu,'String',{'����������','����'});
        
    case 3          % �����������
        
        set(menu_handles.FiltParText1,'String','������ �����');    
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9','11x11','13x13','15x15','17x17','19x19',...
            '21x21','23x23','25x25','27x27','29x29','31x31','33x33','35x35','37x37','39x39','41x41','43x43','45x45',});
            
        set(menu_handles.FiltParText2,'String','���');
        set(menu_handles.FiltParMenu2,'String',{'� ���������� �������','���',...
                                                '������-����','�������','���������',...
                                                '��������','�������','C ���������� �������'});          
        
        set(menu_handles.AlphaText,'String','�����: ');
        set(menu_handles.AlphaSlider,'Min',1,'Max',255,'Value',100,'SliderStep',[1/254 10/254]);
        set(menu_handles.AlphaValText,'String','100');
        
        set(menu_handles.BetaText,'String','k: ');
        set(menu_handles.BetaSlider,'Min',-1,'Max',1,'Value',0.5,'SliderStep',[0.01/2 0.1/2]);
        set(menu_handles.BetaValText,'String','0.5');        
        
        set(menu_handles.GammaText,'String','R: ');
        set(menu_handles.GammaSlider,'Min',1,'Max',255,'Value',50,'SliderStep',[1/254 1/254]);
        set(menu_handles.GammaValText,'String','50');         
        
        
        set(menu_handles.DeltaText,'String','������ ���������: ');        
        set(menu_handles.DeltaSlider,'Min',1,'Max',size(Original,1),'Value',1,...
                                    'SliderStep',[1/(size(Original,1)-1) 10/(size(Original,1)-1)]);
        set(menu_handles.DeltaValText,'String','1x1');
        
        set(menu_handles.EtaSlider,'Min',1,'Max',size(Original,2),'Value',1,...
                                    'SliderStep',[1/(size(Original,2)-1) 10/(size(Original,2)-1)]); 
        
    case 4      % ��������������� ��������� (�/�)     
        
        set(menu_handles.FiltParButton2,'String','��������');            
        
        set(menu_handles.FiltParText2,'String','��������');
        set(menu_handles.FiltParMenu2,'String',{'���������',...
                                                '������',...
                                                '����������',...
                                                '���������',...
                                                '��� �����',...
                                                '���� �����',...
                                                '���������� ���������',...
                                                '������� ������',...
                                                '��������� ���������',...
                                                '�������� ������',...
                                                '�����/�������',...
                                                '����������',...
                                                '������ ������������� ��������',...
                                                '������������ ����������',...
                                                '�-���������',...
                                                '�� ���� �� �������� ����',...
                                                '�������� ��������� ��������',...
                                                '������ �� �����/������',...
                                                '�����',...
                                                '�������� ���������',...
                                                '���������',...
                                                '���������'});      
        
        set(menu_handles.FiltParText3,'String','��������');   
        set(menu_handles.FiltParMenu3,'String',{'����',...
                                                '����',...
                                                '�����',...
                                                '��������������',...
                                                '���� �����',...
                                                '�������������',...
                                                '����������������'});  
        
        Max = floor(min(size(Original,1),size(Original,1))/2)-1;
        set(menu_handles.BetaSlider,'Min',1,'Max',Max,...
                        'Value',1,'SliderStep',[1/(Max-1) 10/(Max-1)]);
        set(menu_handles.BetaText,'String','R = ');
        set(menu_handles.BetaValText,'String','1');       
        
        set(menu_handles.DeltaSlider,'Min',0,'Max',1000,'Value',1,'SliderStep',[1/1000 10/1000]);
        set(menu_handles.DeltaText,'String','���-�� ��������:');
        set(menu_handles.DeltaValText,'String','1');
        
    case 5      % ����������� ��������������� ���������
        
        set(menu_handles.FiltParText2,'String','��������');
        set(menu_handles.FiltParMenu2,'String',{'���������',...
                                                '������',...
                                                '����������',...
                                                '���������',...
                                                '��� �����',...
                                                '���� �����',...
                                                '���������� ���������',...
                                                '������� ������',...
                                                '��������� ���������',...
                                                '�������� ������',...
                                                '����������� �������',...
                                                '����������� ��������',...
                                                '�-�������',...
                                                '�-��������',...
                                                '��������� �������',...
                                                '��������� ��������'});
                                            
        set(menu_handles.FiltParText3,'String','���-�� ������');
        
        switch size(Original,3)
            case 1
                conn = {'4','8'};
            case 3
                conn = {'6','18','26'};                
            otherwise                
                conn = {'�����������','������������'};    
        end
        
        set(menu_handles.FiltParMenu3,'String',conn); 
                                            
        set(menu_handles.FiltParButton1,'String','������');
        set(menu_handles.FiltParButton2,'String','��������');
        
        set(menu_handles.AlphaText,'String','�������: ');
        set(menu_handles.AlphaSlider,'Min',0,'Max',255,'Value',100,'SliderStep',[1/255 10/255]);
        set(menu_handles.AlphaValText,'String','100');
        
        set(menu_handles.BetaText,'String','������: ');
        set(menu_handles.BetaSlider,'Min',1,'Max',7,'Value',1,'SliderStep',[1/6 1/6]);
        set(menu_handles.BetaValText,'String','1');        
        
        set(menu_handles.GammaText,'String','�������:');
        set(menu_handles.GammaSlider,'Min',1,'Max',7,'Value',1,'SliderStep',[1/6 1/6]);
        set(menu_handles.GammaValText,'String','1'); 
        
        set(menu_handles.DeltaText,'String','���-�� ��������:');
        set(menu_handles.DeltaSlider,'Min',0,'Max',1000,'Value',1,'SliderStep',[1/1000 10/1000]);
        set(menu_handles.DeltaValText,'String','1');
        
        m = zeros(7);
        m(4,4) = 1;
        
        set(menu_handles.MaskText,'String','���-��������� �����','Position',[400 256 182 18]);        
        set(menu_handles.MaskTable, 'Data',m,'FontSize',8,...
            'Position',[405 130 170 128],...
            'ColumnWidth',{24 24 24 24 24 24 24});        
        
        set(menu_handles.MaskTable1, 'Data',100*m,'FontSize',8,...
            'Position',[405 1 170 128],...
            'ColumnWidth',{24 24 24 24 24 24 24});
        
    case 6      % ������������� 
        
        set(menu_handles.FiltParText1,'String','������ �����');   
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9'}); 
        set(menu_handles.FiltParText3,'String','�������');    
        set(menu_handles.FiltParMenu3,'String',{'1';'2';'3';char(8734)});
        set(menu_handles.FiltParText2,'String','������� �������');
        set(menu_handles.FiltParMenu2,'String',{'��������','�������','��. ��������������','���. ��������','���������� �������','N-������ �������'});
        
        set(menu_handles.AlphaSlider,'Min',0.01,'Max',3,'Value',0.01,'SliderStep',[0.01/2.99 0.1/2.99]);
        set(menu_handles.AlphaText,'String',[char(945) ' = ']);
        set(menu_handles.AlphaValText,'String','0.01');
        
        set(menu_handles.BetaSlider,'Min',0.01,'Max',3,'Value',0.01,'SliderStep',[0.01/2.99 0.1/2.99]);
        set(menu_handles.BetaText,'String',[char(946) ' = ']);
        set(menu_handles.BetaValText,'String','0.01');
        
        set(menu_handles.FiltParButton1,'String','exp(alpha)');
        set(menu_handles.FiltParButton2,'String','exp(beta)');
               
    case 7      % ������ �������� �������
         
        set(menu_handles.FiltParText2,'String','�����');
        set(menu_handles.FiltParMenu2,'String',{'��� ������� "������"','������� "������"'});
        
        NumOfRows = floor(size(Original,1) / 2);       % ���������� ���-�� ����� ��� PSF
        NumOfCols = floor(size(Original,2) / 2);       % ���������� ���-�� �������� ��� PSF
        
        set(menu_handles.AlphaSlider,'Min',1,'Max',NumOfRows,'Value',10,'SliderStep',[1/(NumOfRows-2) 10/(NumOfRows-2)]);
        set(menu_handles.AlphaText,'String','���-�� �����:');
        set(menu_handles.AlphaValText,'String','10');
        
        set(menu_handles.BetaSlider,'Min',1,'Max',NumOfCols,'Value',10,'SliderStep',[1/(NumOfCols-2) 10/(NumOfCols-2)]);
        set(menu_handles.BetaText,'String','���-�� ��������:');
        set(menu_handles.BetaValText,'String','10'); 
        
        set(menu_handles.GammaSlider,'Min',1,'Max',100,'Value',10,'SliderStep',[1/99 10/99]);
        set(menu_handles.GammaText,'String','���-�� ��������:');
        set(menu_handles.GammaValText,'String','10');
        
        set(menu_handles.DeltaSlider,'Min',0,'Max',255,'Value',0,'SliderStep',[1/255 10/255]);
        set(menu_handles.DeltaText,'String','�����:');
        set(menu_handles.DeltaValText,'String','0');  
        
    case 8      % ������ ������
        
        set(menu_handles.FiltParButton1,'String','�����');
        
        set(menu_handles.FiltParText1,'String','������ �����');    
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9','11x11','13x13','15x15','17x17','19x19',...
            '21x21','23x23','25x25','27x27','29x29','31x31','33x33','35x35','37x37','39x39','41x41','43x43','45x45',});        
        
        set(menu_handles.AlphaText,'String',[char(963) '_x = ']);
        set(menu_handles.AlphaSlider,'Min',0.01,'Max',10,'Value',1,'SliderStep',[0.01/9.99 0.1/9.99]);
        set(menu_handles.AlphaValText,'String','1');              
        
        set(menu_handles.BetaText,'String',[char(963) '_y = ']);
        set(menu_handles.BetaSlider,'Min',0.01,'Max',10,'Value',1,'SliderStep',[0.01/9.99 0.1/9.99]);
        set(menu_handles.BetaValText,'String','1'); 
        
        set(menu_handles.GammaText,'String',[char(955) ' = ']);
        set(menu_handles.GammaSlider,'Min',2,'Max',100,'Value',10,'SliderStep',[1/98 10/98]);
        set(menu_handles.GammaValText,'String','10');        
        
        set(menu_handles.DeltaText,'String',[char(968) ', ��.:']);
        set(menu_handles.DeltaSlider,'Min',0,'Max',360,'Value',0,'SliderStep',[1/360 10/360]);
        set(menu_handles.DeltaValText,'String','0');    
                        
        set(menu_handles.EpsilonText,'String',[char(952) ', ��.:']);
        set(menu_handles.EpsilonSlider,'Min',0,'Max',360,'Value',0,'SliderStep',[1/360 10/360]);
        set(menu_handles.EpsilonValText,'String','0'); 
        
    case 9      % �������������� ����
        
        set(menu_handles.FiltParText1,'String','���������');
        set(menu_handles.FiltParMenu1,'String',{'�����������','����������� � SHT'});
        
        set(menu_handles.FiltParText2,'String',char(916,920,',',186,': ')');   % ����������
        set(menu_handles.FiltParMenu2,'String',{'0.1','0.2','0.5','1','2','5','10','12','15','20','45','60'});
        set(menu_handles.FiltParMenu2,'Value',3);
        
        set(menu_handles.FiltParText3,'String','�����, % �� max: ');
        set(menu_handles.FiltParMenu3,'String',{'1','5','10','20','25','40','50','60','70','75','80','85',...
                                                '90','91','92','93','94','95','96','97','98','99','100'});
        set(menu_handles.FiltParMenu3,'Value',9);
        
        BW = Original(:,:,1);                   % 2D ����������� 
        [MinMask,MaxMask] = SuppressMaskRecount(BW,-90,89,1,1);
        
        set(menu_handles.AlphaText,'String',[char(920) '���.,' char(186) ': ']); % ����
        set(menu_handles.AlphaSlider,'Min',-90,'Max',88,'Value',-90,'SliderStep',[1/178 10/178]);
        set(menu_handles.AlphaValText,'String','-90');
        
        set(menu_handles.BetaText,'String',[char(920) '����. ' char(186) ': ']); % ����
        set(menu_handles.BetaSlider,'Min',-89,'Max',89,'Value',89,'SliderStep',[1/178 10/178]);
        set(menu_handles.BetaValText,'String','89'); 
        
        set(menu_handles.GammaText,'String',char(916,961,': ')'); % ��������
        set(menu_handles.GammaSlider,'Min',0.1,'Max',floor(norm(size(BW))*9)/10,'Value',1,...
                                    'SliderStep',[0.1/(floor(norm(size(BW))*9)/10) 1/(floor(norm(size(BW))*9)/10)]);
        set(menu_handles.GammaValText,'String','1');
        
        set(menu_handles.DeltaText,'String','����� ����������: ');        
        set(menu_handles.DeltaSlider,'Min',MinMask(1),'Max',MaxMask(1),'Value',MinMask(1),...
                                    'SliderStep',[2/(MaxMask(1)-MinMask(1)) 10/(MaxMask(1)-MinMask(1))]);
        set(menu_handles.DeltaValText,'String',[num2str(MinMask(1)) 'x' num2str(MinMask(2))]);
        
        set(menu_handles.EtaSlider,'Min',MinMask(2),'Max',MaxMask(2),'Value',MinMask(2),...
                                    'SliderStep',[2/(MaxMask(2)-MinMask(2)) 10/(MaxMask(2)-MinMask(2))]);        
                        
        set(menu_handles.EpsilonText,'String','���. ����� �����: ');
        set(menu_handles.EpsilonSlider,'Min',2,'Max',norm(size(BW)),'Value',5,...
                                    'SliderStep',[1/(norm(size(BW))-2) 10/(norm(size(BW))-2)]);
        set(menu_handles.EpsilonValText,'String','5');        
        
        set(menu_handles.ZetaText,'String','����. ������: ');
        set(menu_handles.ZetaSlider,'Min',1,'Max',norm(size(BW)),'Value',3,...
                                    'SliderStep',[1/(norm(size(BW))-1) 10/(norm(size(BW))-1)]);
        set(menu_handles.ZetaValText,'String','3');        
                        
        set(menu_handles.TetaText,'String','���-�� �����: ');
        set(menu_handles.TetaSlider,'Min',1,'Max',1000,'Value',5,'SliderStep',[1/999 10/999]);
        set(menu_handles.TetaValText,'String','5')
        
    case 10     % ���������������� ����������        
        
        set(menu_handles.FiltParText2,'String','���');
        set(menu_handles.FiltParMenu2,'String',{'��� ����������������','� �����������������'}); 
        
        
        set(menu_handles.AlphaText,'String','X0: ');
        set(menu_handles.AlphaSlider,'Min',1,'Max',size(Original,2)-1,'Value',1,...
                                    'SliderStep',[1/(size(Original,2)-2) 10/(size(Original,2)-2)]);
        set(menu_handles.AlphaValText,'String','1');
        
        set(menu_handles.BetaText,'String','X1: ');
        set(menu_handles.BetaSlider,'Min',2,'Max',size(Original,2),'Value',size(Original,2),...
                                    'SliderStep',[1/(size(Original,2)-2) 10/(size(Original,2)-2)]);
        set(menu_handles.BetaValText,'String',num2str(size(Original,2))); 
        
        set(menu_handles.GammaText,'String','Y0: ');
        set(menu_handles.GammaSlider,'Min',1,'Max',size(Original,1)-1,'Value',1,...
                                    'SliderStep',[1/(size(Original,1)-2) 10/(size(Original,1)-2)]);
        set(menu_handles.GammaValText,'String','1');
        
        set(menu_handles.DeltaText,'String','Y1: ');
        set(menu_handles.DeltaSlider,'Min',2,'Max',size(Original,1),'Value',size(Original,1),...
                                    'SliderStep',[1/(size(Original,1)-2) 10/(size(Original,1)-2)]);
        set(menu_handles.DeltaValText,'String',num2str(size(Original,1)));        
                        
        set(menu_handles.EpsilonText,'String','������ �����: ');
        set(menu_handles.EpsilonSlider,'Min',0,'Max',254,'Value',0,'SliderStep',[1/254 10/254]);
        set(menu_handles.EpsilonValText,'String','0');        
        
        set(menu_handles.ZetaText,'String','������� �����: ');
        set(menu_handles.ZetaSlider,'Min',1,'Max',255,'Value',255,'SliderStep',[1/254 10/254]);
        set(menu_handles.ZetaValText,'String','255');
        
    case 11                 % ������������ ������(��������������)
          
        set(menu_handles.MaskText,'String','����� �������','Position',[400 200 182 18]);
        set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',30,...
            'Position',[400 5 182 164],...
            'ColumnWidth',{60 60 60});
        
        set(menu_handles.FiltParText1,'String','������ �����');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9'});
        
        set(menu_handles.FiltParText2,'String','��������� ���������');
        set(menu_handles.FiltParMenu2,'String',{'�� ��������','��������'}); 
        
        set(menu_handles.FiltParButton1,'String','������');
        
        set(menu_handles.AlphaSlider,'Min',-99,'Max',99,'Value',1,'SliderStep',[1/198 10/198]);
        set(menu_handles.AlphaText,'String','��������: ');
        set(menu_handles.AlphaValText,'String','1');              
        
        set(menu_handles.BetaText,'String','������:');
        set(menu_handles.BetaSlider,'Min',1,'Max',3,'Value',1,'SliderStep',[1/2 1/2]);
        set(menu_handles.BetaValText,'String','1'); 
        
        set(menu_handles.GammaText,'String','�������:');
        set(menu_handles.GammaSlider,'Min',1,'Max',3,'Value',1,'SliderStep',[1/2 1/2]);
        set(menu_handles.GammaValText,'String','1');
        
        
    case 12                 % ������ �������
        set(menu_handles.AlphaSlider,'Min',1,'Max',size(Original,2),'Value',5,'SliderStep',[1/(size(Original,2)-1) 10/(size(Original,2)-1)]);
        set(menu_handles.AlphaText,'String','����� �������: ');
        set(menu_handles.AlphaValText,'String','5');
        
        set(menu_handles.BetaText,'String','������ �������: ');
        set(menu_handles.BetaSlider,'Min',1,'Max',size(Original,1),'Value',5,'SliderStep',[1/(size(Original,1)-1) 10/(size(Original,1)-1)]);
        set(menu_handles.BetaValText,'String','5'); 
        
        
    case {13,22}      % ������ ������ ������, ������+�������
        
        set(menu_handles.FiltParText1,'String','������ �����');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9'});
        
        set(menu_handles.AlphaSlider,'Min',0.01,'Max',5,'Value',0.5,'SliderStep',[0.01/4.99 0.1/4.99]);
        set(menu_handles.AlphaText,'String',[char(963) ' = ']);
        set(menu_handles.AlphaValText,'String','0.5');
                
    case 14                 % �����������
        
        set(menu_handles.FiltParText1,'String','������ �����');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9'});
        
        set(menu_handles.FiltParText2,'String','���:');
        set(menu_handles.FiltParMenu2,'String',{'������� ��������������',...
                                                '������� ��������������',...
                                                '������������� �������',...
                                                '������������������ �������',...
                                                '��������',...
                                                '�������',...
                                                '������� �����',...
                                                '������� ���������'}); 
                
    case 15            % ������
        
        set(menu_handles.AlphaSlider,'Min',0,'Max',255,'Value',50,'SliderStep',[1/255 10/255]);
        set(menu_handles.AlphaText,'String','�����: ');
        set(menu_handles.AlphaValText,'String','50');
        
        set(menu_handles.FiltParText3,'String','�����������');
        set(menu_handles.FiltParMenu3,'Value',1,'String',{  '�����. (���������)';...
                                                            '�����. (��� ���������)';...
                                                            '����. (���������)';...
                                                            '����. (��� ���������)';...
                                                            '��� (���������)';...
                                                            '��� (��� ���������)'});
        
    case 16                 % ������ �����    
        
        set(menu_handles.AlphaSlider,'Min',-1,'Max',149,'Value',50,'SliderStep',[1/150 10/150]);
        set(menu_handles.AlphaText,'String','������ �����: ');
        set(menu_handles.AlphaValText,'String','50');
        
        set(menu_handles.BetaText,'String','������� �����: ');
        set(menu_handles.BetaSlider,'Min',51,'Max',256,'Value',150,'SliderStep',[1/205 10/205]);
        set(menu_handles.BetaValText,'String','150'); 
        
        set(menu_handles.GammaText,'String',[char(963) ' = ']);
        set(menu_handles.GammaSlider,'Min',0.01,'Max',3,'Value',0.5,'SliderStep',[0.01/2.99 0.1/2.99]);
        set(menu_handles.GammaValText,'String','0.5');
        
    case 17                 % ��������
        set(menu_handles.AlphaSlider,'Min',0,'Max',255,'Value',50,'SliderStep',[1/255 10/255]);
        set(menu_handles.AlphaText,'String','�����: ');
        set(menu_handles.AlphaValText,'String','50');
        
        set(menu_handles.FiltParText3,'String','�����������');
        set(menu_handles.FiltParMenu3,'Value',1,'String',{   '��������������';...
                                                            '������������';...
                                                            '���'});
                                                        
    case 18                 % ������ ��������
        
        set(menu_handles.AlphaSlider,'Min',0,'Max',255,'Value',50,'SliderStep',[1/255 10/255]);
        set(menu_handles.AlphaText,'String','�����: ');
        set(menu_handles.AlphaValText,'String','50');
        
        set(menu_handles.FiltParText3,'String','�����');
        set(menu_handles.FiltParMenu3,'Value',1,'String',{'���������';'��� ���������'});
        
    case 19                 % ��������     
        
        set(menu_handles.FiltParText1,'String','������ �����');      
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9','11x11','13x13','15x15','17x17','19x19'});
        
    case 20                 % ������ ������� ��� 
        
        set(menu_handles.AlphaSlider,'Min',0.01,'Max',1,'Value',0.2,'SliderStep',[0.01/0.99 0.1/0.99]);
        set(menu_handles.AlphaText,'String','��� = ');
        set(menu_handles.AlphaValText,'String','0.2');
                
    case 21                 % ��������� ��������
        
        set(menu_handles.AlphaSlider,'Min',0,'Max',1,'Value',0.1,'SliderStep',[0.01 0.1]);
        set(menu_handles.AlphaText,'String','a = ');
        set(menu_handles.AlphaValText,'String','0.1'); 
                        
    case 23                 % ���������� ���������
        
        set(menu_handles.FiltParMenu1,'String',{'3x3'});
        set(menu_handles.IndentMenu,'String',{'����������','����'});
        M = min(size(Original,1),size(Original,2));
        M = M - 1 + mod(M,2);             % ������ ��������        
        
        set(menu_handles.AlphaSlider,'Min',3,'Max',M,'Value',5,'SliderStep',[2/(M-3) 10/(M-3)]);
        set(menu_handles.AlphaText,'String','Smax = ');
        set(menu_handles.AlphaValText,'String','5');
        
    case 24             % ����� - ������
        
        set(menu_handles.FiltParText1,'String','������ �����');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9','11�11'});
        
        set(menu_handles.AlphaText,'String','����� �������: ');
        set(menu_handles.AlphaSlider,'Min',1,'Max',25,'Value',1,'SliderStep',[1/24 10/24]);
        set(menu_handles.AlphaValText,'String','1'); 
        
    case 25             % ������� ��
        
        set(menu_handles.FiltParText1,'String','������ �����');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9','11�11'});
        
        set(menu_handles.FiltParText2,'String','��� �������');
        set(menu_handles.FiltParMenu2,'String',{'������������','����������'}); 
        
        set(menu_handles.FiltParText3,'String','������ ������');
        set(menu_handles.FiltParMenu3,'String',{'����������','�����������������','���������� + �����������������'});
              
       
        set(menu_handles.AlphaText,'String',[char(963) char(178) ' ���. ������: ']);
        set(menu_handles.AlphaSlider,'Min',1,'Max',255,'Value',50,'SliderStep',[1/254 10/254]);
        set(menu_handles.AlphaValText,'String','50'); 
        
        set(menu_handles.BetaText,'String',[char(956) ' ���. ������: ']);
        set(menu_handles.BetaSlider,'Min',-255,'Max',255,'Value',0,'SliderStep',[1/510 10/510]);
        set(menu_handles.BetaValText,'String','0'); 
        
        set(menu_handles.GammaText,'String',[char(963) char(178) ' �����. ������: ']);
        set(menu_handles.GammaSlider,'Min',1,'Max',255,'Value',50,'SliderStep',[1/254 10/254]);
        set(menu_handles.GammaValText,'String','50');
        
        set(menu_handles.DeltaText,'String',[char(956) ' �����. ������: ']);
        set(menu_handles.DeltaSlider,'Min',-255,'Max',255,'Value',0,'SliderStep',[1/510 10/510]);
        set(menu_handles.DeltaValText,'String','0');        
                        
        set(menu_handles.EpsilonText,'String','����� �������: ');
        set(menu_handles.EpsilonSlider,'Min',1,'Max',25,'Value',1,'SliderStep',[1/24 10/24]);
        set(menu_handles.EpsilonValText,'String','1');   
        
        set(menu_handles.ZetaText,'String','�����. ���������: ');
        set(menu_handles.ZetaSlider,'Min',0.01,'Max',5,'Value',1,'SliderStep',[0.01/4.99 0.1/4.99]);
        set(menu_handles.ZetaValText,'String','1');   
        
    case 26                 % ������       
                        
        set(menu_handles.FiltParText1,'String','������ �����');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9','11�11'});
        
        set(menu_handles.FiltParText2,'String','��� �������');
        set(menu_handles.FiltParMenu2,'String',{'������������','����������'}); 
        
        
        set(menu_handles.AlphaText,'String','�����. ���������: ');
        set(menu_handles.AlphaSlider,'Min',0.01,'Max',5,'Value',1,'SliderStep',[0.01/4.99 0.1/4.99]);
        set(menu_handles.AlphaValText,'String','1'); 
        
        set(menu_handles.BetaText,'String','����� �������: ');
        set(menu_handles.BetaSlider,'Min',1,'Max',25,'Value',1,'SliderStep',[1/24 10/24]);
        set(menu_handles.BetaValText,'String','1');   
                
    case 27                 % ����� 
        
        set(menu_handles.FiltParText1,'String','������ �����');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9','11�11'});
        
        set(menu_handles.AlphaText,'String','����� �������: ');
        set(menu_handles.AlphaSlider,'Min',1,'Max',25,'Value',1,'SliderStep',[1/24 10/24]);
        set(menu_handles.AlphaValText,'String','1'); 
         
    case 28                 % ������ ��������� ���������        
        
        set(menu_handles.FiltParText1,'String','������ �����');      
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9'});
        
        set(menu_handles.FiltParText2,'String','���:');
        set(menu_handles.FiltParMenu2,'String',{'����������',...
                                                '�����������',...
                                                '���'});       
        
        set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',34,...
            'Position',[400 5 182 182],...
            'ColumnWidth',{60 60 60});
        
    case 29                 % ��������� ���������
        
        set(menu_handles.FiltParText3,'String','���������');   
        set(menu_handles.FiltParMenu3,'String',{'�����������','����������'});
        
        if size(Original,3) == 3
            str = {'RGB';'HSV'};
        else
            str = {'RGB'};
        end
        
        set(menu_handles.FiltParText2,'String','�������� ������');    
        set(menu_handles.FiltParMenu2,'String',str);
        
        
        set(menu_handles.AlphaText,'String','�������� ���������: ');
        set(menu_handles.AlphaSlider,'Min',0,'Max',255,'Value',1,'SliderStep',[1/255 10/255]);
        set(menu_handles.AlphaValText,'String','0'); 
        
        set(menu_handles.BetaText,'String','����� ������:');
        set(menu_handles.BetaValText,'String','1'); 
        
        if size(Original,3) == 1
            set(menu_handles.BetaSlider,'Enable','off');
        else
            set(menu_handles.BetaSlider,'Min',1,'Max',size(Original,3),...
                'Value',1,'SliderStep',[1/(size(Original,3)-1) 1/(size(Original,3)-1)]);
        end
        
        set(menu_handles.DeltaText,'String','������: ');        
        set(menu_handles.DeltaSlider,'Min',0,'Max',254,'Value',0,...
                                    'SliderStep',[1/254 10/254]);
        set(menu_handles.DeltaValText,'String',['0 ' char(8804) ' I ' char(8804) ' 255']);
        
        set(menu_handles.EtaSlider,'Min',1,'Max',255,'Value',255,'SliderStep',[1/254 10/254]);                        
        
    case 30                 % ��������        
        
        set(menu_handles.FiltParText2,'String','���������');
        set(menu_handles.FiltParMenu2,'String',{'��������� ���������',...
                                                '����������� ���������',...
                                                '������������ �������� �� ��',...
                                                '������������ �������� �� �y'}); 
        
        set(menu_handles.FiltParText3,'String','�����');
        set(menu_handles.FiltParMenu3,'String',{'������','��������','����������� ��������','������� ��������','��������'});         
        
    case 31                 % ����������� �����������
        
        set(menu_handles.AlphaSlider,'Min',1,'Max',255,'Value',64,'SliderStep',[1/254 10/254]);
        set(menu_handles.AlphaValText,'String','64'); 
        set(menu_handles.AlphaText,'String','����� �������:');
        
        set(menu_handles.FiltParText3,'String','�������� ������');        
        if size(Original,3) == 3
            set(menu_handles.FiltParMenu3,'Value',1,'String',{'RGB';'HSV'});
        else
            set([menu_handles.FiltParMenu3 menu_handles.FiltParText3],'Visible','off');
        end
        
    case 32             % �����������        
        
        set(menu_handles.AlphaSlider,'Min',1,'Max',7,'Value',4,'SliderStep',[1/6 1/6]);
        set(menu_handles.AlphaValText,'String','4'); 
        set(menu_handles.AlphaText,'String','���/�������: ');      
        
        set(menu_handles.FiltParButton2,'String','I���(I��)');
                
        set(menu_handles.BetaText,'String','����������� ������������: ');
        set(menu_handles.BetaSlider,'Min',0.01,'Max',20,'Value',1,'SliderStep',[0.01/19.99 0.1/19.99]);
        set(menu_handles.BetaValText,'String','1');         
        
    case 33             % ���������������� C �����-����������
        
        set(menu_handles.AlphaText,'String','�����: ');
        set(menu_handles.AlphaSlider,'Min',0.01,'Max',20,'Value',1,'SliderStep',[0.01/19.99 0.1/19.99]);
        set(menu_handles.AlphaValText,'String','1');
        
        set(menu_handles.BetaText,'String','������� �����: ');
        set(menu_handles.BetaSlider,'Min',0,'Max',254,'Value',0,'SliderStep',[1/254 10/254]);
        set(menu_handles.BetaValText,'String','0'); 
        
        set(menu_handles.GammaText,'String','������ �����: ');
        set(menu_handles.GammaSlider,'Min',1,'Max',255,'Value',255,'SliderStep',[1/254 10/254]);
        set(menu_handles.GammaValText,'String','255');
        
        set(menu_handles.DeltaText,'String','������ �����: ');
        set(menu_handles.DeltaSlider,'Min',0,'Max',254,'Value',0,'SliderStep',[1/254 10/254]);
        set(menu_handles.DeltaValText,'String','0');
        
        set(menu_handles.EpsilonText,'String','������� �����: ');
        set(menu_handles.EpsilonSlider,'Min',1,'Max',255,'Value',255,'SliderStep',[1/254 10/254]);
        set(menu_handles.EpsilonValText,'String','255');
        
        set(menu_handles.FiltParButton1,'String','I���(I��)');
        
    case 34         % �������� �����������        
        
        set(menu_handles.FiltParText2,'String','��������');
        set(menu_handles.FiltParMenu2,'Value',1,'String',{'����';'�������� � ���������'});
        
        set(menu_handles.FiltParText3,'String','����');
        set(menu_handles.FiltParMenu3,'Value',1,'String',{'������ ����';'������� ����'});
        
        set(menu_handles.BetaText,'String','����������������: ');
        set(menu_handles.BetaSlider,'Min',0.01,'Max',1,'Value',0.5,'SliderStep',[0.01/0.99 0.1/0.99]);
        set(menu_handles.BetaValText,'String','0.5'); 
        
        set(menu_handles.GammaText,'String','����������� �����: ');
        set(menu_handles.GammaSlider,'Min',1,'Max',255,'Value',100,'SliderStep',[1/254 10/254]);
        set(menu_handles.GammaValText,'String','100');
        
        MS = floor(min(size(Original,2),size(Original,1))/2);
        if MS <= 10
           MS = 11; 
        end
        
        set(menu_handles.DeltaText,'String','������� ������: ');        
        set(menu_handles.DeltaSlider,'Min',10,'Max',MS,'Value',10,...
                                    'SliderStep',[1/(MS-10) 10/(MS-10)]);
        set(menu_handles.DeltaValText,'String',['10' char(8804) 'R' char(8804) '11']);
        
        set(menu_handles.EtaSlider,'Min',10,'Max',MS,'Value',11,...
                                    'SliderStep',[1/(MS-10) 10/(MS-10)]); 
                                
    case 35     % �������� �������� �����
        
        set(menu_handles.FiltParText2,'String','��������');
        set(menu_handles.FiltParMenu2,'String',{'BRISK',...
                                                '����� (FAST)',...
                                                '����� (�������)',...
                                                '����� (���. ������. ��������)',...
                                                'SURF'});
       
        set(menu_handles.AlphaText,'String','���. ��������: ');
        set(menu_handles.AlphaSlider,'Min',0,'Max',1,'Value',0.1,'SliderStep',[0.01/1 0.1/1]);
        set(menu_handles.AlphaValText,'String','0.1');
        
        set(menu_handles.BetaText,'String','���. ��������: ');
        set(menu_handles.BetaSlider,'Min',0.01,'Max',0.99,'Value',0.1,'SliderStep',[0.01/0.98 0.1/0.98]);
        set(menu_handles.BetaValText,'String','0.1'); 
        
        set(menu_handles.DeltaText,'String','����� �����: ');
        set(menu_handles.DeltaSlider,'Min',0,'Max',6,'Value',2,'SliderStep',[1/6 1/6]);
        set(menu_handles.DeltaValText,'String','2');
        
        set(menu_handles.GammaText,'String','������ �������: ');
        
        set(menu_handles.EpsilonText,'String','������� ��������: ');
        set(menu_handles.EpsilonSlider,'Min',3,'Max',10,'Value',3,'SliderStep',[1/7 10/7]);
        set(menu_handles.EpsilonValText,'String','3');
        
        set(menu_handles.ZetaText,'String','�����: ');
        set(menu_handles.ZetaSlider,'Min',1,'Max',20000,'Value',500,'SliderStep',[1/19999 10/19999]);
        set(menu_handles.ZetaValText,'String','500'); 
end


% ������ "���������-���������"
function NoiseFilterString_Callback(~, ~, menu_handles)

% ������ �������� �������� �������� � ��������� ������
Value = get(menu_handles.NoiseFilterString,'Value');
set(menu_handles.DeleteSlider,'Value',Value);
set(menu_handles.DeleteNumber,'String',num2str(Value));


% ������ ������
function FiltParMenu1_Callback(~, ~, menu_handles)

% ��������� ������� �����

NumOfRows = get(menu_handles.FiltParMenu1,'Value');

switch get(menu_handles.FilterType,'Value')     % ��� ���������
    
    case {2,28}      % ��������� ������
        
        switch NumOfRows       % ��������� �������� �����
            
            case 1          % ����� 3�3
                
                set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',34,...
                    'Position',[400 5 182 182],...
                    'ColumnWidth',{60 60 60});
                
            case 2          % ����� 5�5
                set(menu_handles.MaskTable,'Data',ones(5),'FontSize',19,...
                    'Position',[405 5 177 177],...
                    'ColumnWidth',{35 35 35 35 35});
            case 3          % ����� 7�7
                
                set(menu_handles.MaskTable, 'Data',ones(7),'FontSize',12,...
                    'Position',[405 5 177 163],...
                    'ColumnWidth',{25 25 25 25 25 25 25});
            case 4          % ����� 9�9
                set(menu_handles.MaskTable, 'Data',ones(9),'FontSize',10,...
                    'Position',[400 5 182 182],...
                    'ColumnWidth',{20 20 20 20 20 20 20 20 20});
        end
        
    case 11     % ������������ ������
        
        switch NumOfRows       % ��������� �������� �����
            
            case 1 
                set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',30,...
                    'Position',[400 5 182 164],...
                    'ColumnWidth',{60 60 60});
                
            case 2          % ����� 5�5
                set(menu_handles.MaskTable,'Data',ones(5),'FontSize',16,...
                    'Position',[405 5 177 152],...
                    'ColumnWidth',{35 35 35 35 35});
            case 3          % ����� 7�7
                
                set(menu_handles.MaskTable, 'Data',ones(7),'FontSize',11,...
                    'Position',[405 5 177 156],...
                    'ColumnWidth',{25 25 25 25 25 25 25});
            case 4          % ����� 9�9
                set(menu_handles.MaskTable, 'Data',ones(9),'FontSize',8,...
                    'Position',[400 5 182 164],...
                    'ColumnWidth',{20 20 20 20 20 20 20 20 20});            
        end
        
        
        set(menu_handles.BetaSlider,'Min',1,'Max',2*NumOfRows+1,'Value',1,'SliderStep',[1/(2*NumOfRows) 1/(2*NumOfRows)]);
        set(menu_handles.BetaValText,'String','1');
        
        set(menu_handles.GammaSlider,'Min',1,'Max',2*NumOfRows+1,'Value',1,'SliderStep',[1/(2*NumOfRows) 1/(2*NumOfRows)]);
        set(menu_handles.GammaValText,'String','1');
        
    case 14         % ����������� �������
        
        if get(menu_handles.FiltParMenu2,'Value') == 8
            
            MaskSize = 2*get(menu_handles.FiltParMenu1,'Value')+1;
            
            set(menu_handles.AlphaSlider,'Min',2,'Max',MaskSize^2-3,'Value',2,...
                'SliderStep',[2/(MaskSize^2-5) 10/(MaskSize^2-5)]);
            
            set(menu_handles.AlphaValText,'String','2');
        end
        
end


% ������ ������
function FiltParMenu2_Callback(~,~,menu_handles)

global Original;

switch get(menu_handles.FilterType,'Value')     % ��� ���������
    
    case 2                                      % ��������� ������
        if get(menu_handles.FiltParMenu2,'Value') == 1
            set(menu_handles.IndentMenu,'String',{'����������','����'}); 
            set([menu_handles.MaskTable menu_handles.MaskText],'Visible','on');
        else
            set(menu_handles.IndentMenu,'String',{'����������','����','��������','�����'}); 
            set([menu_handles.MaskTable menu_handles.MaskText],'Visible','off');
            
        end        
        
        if get(menu_handles.FiltParMenu2,'Value') == 4
            set([menu_handles.FiltParMenu3 menu_handles.FiltParText3],'Visible','on');
        else
            set([menu_handles.FiltParMenu3 menu_handles.FiltParText3],'Visible','off');
        end
        
    case 3          % �����������
        
        switch get(menu_handles.FiltParMenu2,'Value') 
            
            case 1  % ���������                
                
                set([menu_handles.FiltParText1 menu_handles.FiltParMenu1],'Visible','off');                 
                set([ ...  
                    menu_handles.AlphaSlider;...
                    menu_handles.AlphaText;...
                    menu_handles.AlphaValText...
                    ],'Visible','on');
                
                set([   ...
                    menu_handles.BetaSlider;...
                    menu_handles.GammaSlider;...
                    menu_handles.BetaText;...
                    menu_handles.GammaText;...
                    menu_handles.BetaValText;...
                    menu_handles.GammaValText;...
                    menu_handles.DeltaSlider;...
                    menu_handles.EtaSlider;...
                    menu_handles.DeltaText;...
                    menu_handles.DeltaValText...
                    ],'Visible','off');                
                
            case 2  % ���
                
                set([menu_handles.FiltParText1 menu_handles.FiltParMenu1],'Visible','off');                 
                set([   ...
                    menu_handles.AlphaSlider;...
                    menu_handles.BetaSlider;...
                    menu_handles.GammaSlider;...
                    menu_handles.AlphaText;...
                    menu_handles.BetaText;...
                    menu_handles.GammaText;...
                    menu_handles.AlphaValText;...
                    menu_handles.BetaValText;...
                    menu_handles.GammaValText;...
                    menu_handles.DeltaSlider;...
                    menu_handles.EtaSlider;...
                    menu_handles.DeltaText;...
                    menu_handles.DeltaValText...
                    ],'Visible','off');
                
            case {3,4,5}  % ������-����, �������, ���������
                
                set([menu_handles.FiltParText1 menu_handles.FiltParMenu1],'Visible','on');                                 
                set([   ...
                    menu_handles.BetaSlider;...
                    menu_handles.BetaText;...
                    menu_handles.BetaValText;...
                    ],'Visible','on');
                
                set([   ...
                    menu_handles.AlphaSlider;...
                    menu_handles.GammaSlider;...
                    menu_handles.AlphaText;...
                    menu_handles.GammaText;...
                    menu_handles.AlphaValText;...
                    menu_handles.GammaValText;...
                    menu_handles.DeltaSlider;...
                    menu_handles.EtaSlider;...
                    menu_handles.DeltaText;...
                    menu_handles.DeltaValText...
                    ],'Visible','off');                                
                
            case 6  % ��������
                
                set([menu_handles.FiltParText1 menu_handles.FiltParMenu1],'Visible','on'); 
                set([   ...
                    menu_handles.AlphaSlider;...
                    menu_handles.BetaSlider;...
                    menu_handles.GammaSlider;...
                    menu_handles.AlphaText;...
                    menu_handles.BetaText;...
                    menu_handles.GammaText;...
                    menu_handles.AlphaValText;...
                    menu_handles.BetaValText;...
                    menu_handles.GammaValText;...
                    menu_handles.DeltaSlider;...
                    menu_handles.EtaSlider;...
                    menu_handles.DeltaText;...
                    menu_handles.DeltaValText...
                    ],'Visible','off');                
                
            case 7  % �������
                
                set([menu_handles.FiltParText1 menu_handles.FiltParMenu1],'Visible','on');                  
                set([ ...  
                    menu_handles.AlphaSlider;...
                    menu_handles.AlphaText;...
                    menu_handles.AlphaValText;...
                    menu_handles.DeltaSlider;...
                    menu_handles.EtaSlider;...
                    menu_handles.DeltaText;...
                    menu_handles.DeltaValText...
                    ],'Visible','off');
                
                set([   ...
                    menu_handles.BetaSlider;...
                    menu_handles.GammaSlider;...
                    menu_handles.BetaText;...
                    menu_handles.GammaText;...
                    menu_handles.BetaValText;...
                    menu_handles.GammaValText...
                    ],'Visible','on');
                
            case 8  % � ���������� �������
                
                set([menu_handles.FiltParText1 menu_handles.FiltParMenu1],'Visible','off');                 
                set([   ...
                    menu_handles.BetaSlider;...
                    menu_handles.GammaSlider;...
                    menu_handles.AlphaText;...
                    menu_handles.BetaText;...
                    menu_handles.GammaText;...
                    menu_handles.AlphaValText;...
                    menu_handles.BetaValText;...
                    menu_handles.GammaValText...
                    ],'Visible','off');                
                
                set([   ...
                    menu_handles.AlphaSlider;...
                    menu_handles.DeltaSlider;...
                    menu_handles.EtaSlider;...
                    menu_handles.AlphaText;...
                    menu_handles.DeltaText;...
                    menu_handles.AlphaValText;...
                    menu_handles.DeltaValText...
                    ],'Visible','on');
                
        end
        
    case 4          % ��������������� ���������
        
        set([   menu_handles.BetaSlider;...
                menu_handles.GammaSlider;...
                menu_handles.EpsilonSlider;...
                menu_handles.ZetaSlider;...
                menu_handles.BetaText;...
                menu_handles.GammaText;...
                menu_handles.ZetaText;...
                menu_handles.EpsilonText;...
                menu_handles.BetaValText;...
                menu_handles.GammaValText;...  
                menu_handles.ZetaValText;...
                menu_handles.EpsilonValText;...      
                menu_handles.MaskTable;...
                menu_handles.MaskText;...
                menu_handles.FiltParText3;...
                menu_handles.FiltParMenu3;...
                menu_handles.FiltParButton2],'Visible','off');
        
        switch get(menu_handles.FiltParMenu2,'Value')
            
            case {1,2,3,4,5,6}  % ���������, ������, ����������, ... ���� �����
                               
                set(menu_handles.FiltParButton2,'Visible','on','String','��������');  
                set(menu_handles.FiltParMenu3,'Value',1);
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on'); 
            
                set(menu_handles.FiltParText3,'String','����. ���������');   
                set(menu_handles.FiltParMenu3,'String',{'����',...
                                                        '����',...
                                                        '�����',...
                                                        '��������������',...
                                                        '���� �����',...
                                                        '�������������',...
                                                        '����������������'}); 
                                                    
                Max = floor(min(size(Original,1),size(Original,1))/2)-1;
                set(menu_handles.BetaSlider,'Min',1,'Max',Max,...
                    'Value',1,'SliderStep',[1/(Max-1) 10/(Max-1)]);
                set(menu_handles.BetaText,'String','R = ');
                set(menu_handles.BetaValText,'String','1');
                
                set([   menu_handles.BetaSlider;...
                        menu_handles.BetaText;...
                        menu_handles.BetaValText],...
                        'Visible','on');
                    
                            
                                                    
            case {7,8,9}   % ����������, ������, ��������   
                
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on');
                set(menu_handles.FiltParMenu3,'Value',1);
                set(menu_handles.FiltParText3,'String','���-�� ������');
                set(menu_handles.FiltParMenu3,'String',{'4','8'});   
                
            case 10     % �������� ������
                
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on');
                set(menu_handles.FiltParMenu3,'Value',1);
                set(menu_handles.FiltParText3,'String','���������');
                set(menu_handles.FiltParMenu3,'String',{'��������� (4-��.)',...
                                                        '��������� (8-��.)',...
                                                        '��������� ������� (4-��.)',...
                                                        '��������� ������� (8-��.)',...
                                                        '��������� ����� (4-��.)',...
                                                        '��������� ����� (8-��.)',...
                                                        '�����-��������� (4-��.)',...
                                                        '�����-��������� (8-��.)'});
            
            
                
            case 11     % �����/�������
                
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','off');
                set(menu_handles.FiltParButton2,'Visible','on','String','������');                              
                
                set(menu_handles.BetaSlider,'Min',-1,'Max',1,...
                    'Value',0,'SliderStep',[1/2 1/2]);
                set(menu_handles.BetaText,'String','��������:');
                set(menu_handles.BetaValText,'String','0');  
                
                set(menu_handles.GammaSlider,'Min',1,'Max',4,...
                    'Value',1,'SliderStep',[1/3 1/3]);
                set(menu_handles.GammaText,'String','������ �������:');
                set(menu_handles.GammaValText,'String','3�3');               
                
                set(menu_handles.EpsilonSlider,'Min',1,'Max',3,...
                    'Value',1,'SliderStep',[1/2 1/2]);
                set(menu_handles.EpsilonText,'String','������:');
                set(menu_handles.EpsilonValText,'String','1');                 
                
                set(menu_handles.ZetaSlider,'Min',1,'Max',3,...
                    'Value',1,'SliderStep',[1/2 1/2]);
                set(menu_handles.ZetaText,'String','�������:');
                set(menu_handles.ZetaValText,'String','1');  
                        
                set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',34,...
                    'Position',[400 5 182 182],...
                    'ColumnWidth',{60 60 60});   
                                                    
                set([   menu_handles.BetaSlider;...
                        menu_handles.BetaText;...
                        menu_handles.BetaValText],...
                        'Visible','on');
                    
                set([   menu_handles.MaskTable;...
                    menu_handles.MaskText],...
                    'Visible','on');            
                
                set([   menu_handles.GammaSlider;...
                    menu_handles.GammaText;...
                    menu_handles.GammaValText],...
                    'Visible','on');
                
                set([   menu_handles.ZetaSlider;...
                    menu_handles.ZetaText;...
                    menu_handles.ZetaValText],...
                    'Visible','on');
                
                set([   menu_handles.EpsilonSlider;...
                    menu_handles.EpsilonText;...
                    menu_handles.EpsilonValText],...
                    'Visible','on');
                
            case {12,13,14,15,16,17,18,19,20,21,22}    % bwmorph                
                
        end
        
    case 5          % ����������� ����������
        
        % ��� ��������, ������ ��������� � ������
        set([   menu_handles.AlphaSlider;...
                menu_handles.BetaSlider;...
                menu_handles.GammaSlider;...
                menu_handles.AlphaText;...
                menu_handles.BetaText;...
                menu_handles.GammaText;....
                menu_handles.AlphaValText;...
                menu_handles.BetaValText;...
                menu_handles.GammaValText;...       
                menu_handles.MaskTable;...     
                menu_handles.MaskTable1;...
                menu_handles.MaskText;...
                menu_handles.FiltParText3;...
                menu_handles.FiltParMenu3;...
                menu_handles.FiltParButton1],'Visible','off');
            
        set(menu_handles.FiltParMenu3,'Value',1);
            
        % �������� �������� ���� �� ���������, � case 10 ��� ��������    
        set(menu_handles.FiltParText3,'String','���-�� ������');
        switch size(Original,3)
            case 1
                conn = {'4','8'};
            case 3
                conn = {'6','18','26'};
            otherwise
                conn = {'�����������','������������'};
        end

        set(menu_handles.FiltParMenu3,'String',conn);
            
        
        switch get(menu_handles.FiltParMenu2,'Value')
            case {1,2,3,4,5,6}  % ���������...���� �����                   
                
                set([   menu_handles.AlphaSlider;...
                        menu_handles.AlphaText;...
                        menu_handles.AlphaValText],...
                        'Visible','on');
                    
                set([   menu_handles.BetaSlider;...
                        menu_handles.BetaText;...
                        menu_handles.BetaValText],...
                        'Visible','on');
                    
                set([   menu_handles.GammaSlider;...
                        menu_handles.GammaText;...
                        menu_handles.GammaValText],...
                        'Visible','on');
                                        
                set([   menu_handles.MaskTable;...
                        menu_handles.MaskTable1;...
                        menu_handles.MaskText],...
                        'Visible','on');                    
                    
                set(menu_handles.FiltParButton1,'Visible','on','String','������');   
                
            case 7    % ���������� ���������                
                
            case {8,9,15,16}    % ������� ������, ��������� ��������� ���. �������, ��� ����.
                
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on');  
                
            case 10             % �������� ������
                
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on');
                
                switch size(Original,3)
                    case 1
                        conn = {'��������� (4-��.)',...
                                '��������� (8-��.)',...
                                '��������� ������� (4-��.)',...
                                '��������� ������� (8-��.)',...
                                '��������� ����� (4-��.)',...
                                '��������� ����� (8-��.)',...
                                '�����-��������� (4-��.)',...
                                '�����-��������� (8-��.)'};
                    case 3
                        conn = {'��������� (6-��.)',...
                                '��������� (18-��.)',...
                                '��������� (26-��.)',...                                
                                '��������� ������� (6-��.)',...
                                '��������� ������� (18-��.)',...
                                '��������� ������� (26-��.)',...                                
                                '��������� ����� (6-��.)',...
                                '��������� ����� (18-��.)',...
                                '��������� ����� (26-��.)',...                                
                                '�����-��������� (6-��.)',...
                                '�����-��������� (18-��.)',...
                                '�����-��������� (26-��.)'};
                    otherwise
                        conn = {'��������� (���-��.)',...
                                '��������� (����-��.)',...
                                '��������� ������� (���-��.)',...
                                '��������� ������� (����-��.)',...
                                '��������� ����� (���-��.)',...
                                '��������� ����� (����-��.)',...
                                '�����-��������� (���-��.)',...
                                '�����-��������� (����-��.)'};
                end

                set(menu_handles.FiltParMenu3,'String',conn);
                
            case {11,12,13,14}  % ����. ���/����, H-���/����
                
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on');                
                
                set([   menu_handles.AlphaSlider;...
                        menu_handles.AlphaText;...
                        menu_handles.AlphaValText],...
                        'Visible','on');
        end
        
        
    case 6          % ������������� ������
        
        if get(menu_handles.FiltParMenu2,'Value') == 6
            set([menu_handles.FiltParMenu3 menu_handles.FiltParText3],'Visible','on');
        else
            set([menu_handles.FiltParMenu3 menu_handles.FiltParText3],'Visible','off');
        end
        
    case 9          % �������������� ����
        
        % � ��������� �������� ���� ����� �������� ������� ����� ����������
        A = get(menu_handles.AlphaSlider,'Value');          % ������� ������ �� ����
        B = get(menu_handles.BetaSlider,'Value');           % ������� ������ �� ����
        RhoStep = get(menu_handles.GammaSlider,'Value');    % ��� �� ��
        STR = get(menu_handles.FiltParMenu2,'String');      % �������� ��� �� ����
        num = get(menu_handles.FiltParMenu2,'Value');
        ThetaStep = str2double(STR(num));
        BW = Original(:,:,1);                               % 2D �����������
        [MinMask,MaxMask] = SuppressMaskRecount(BW,A,B,ThetaStep,RhoStep);
        
        set(menu_handles.DeltaSlider,'Min',MinMask(1),'Max',MaxMask(1),'Value',MinMask(1),...
                                    'SliderStep',[2/(MaxMask(1)-MinMask(1)) 10/(MaxMask(1)-MinMask(1))]);
        set(menu_handles.DeltaValText,'String',[num2str(MinMask(1)) 'x' num2str(MinMask(2))]);
        
        set(menu_handles.EtaSlider,'Min',MinMask(2),'Max',MaxMask(2),'Value',MinMask(2),...
                                    'SliderStep',[2/(MaxMask(2)-MinMask(2)) 10/(MaxMask(2)-MinMask(2))]);
        
    case 10         % ���������������� ����������
        
        switch get(menu_handles.FiltParMenu2,'Value')
            
            case 1
                set([menu_handles.EpsilonSlider;...
                    menu_handles.ZetaSlider;...
                    menu_handles.EpsilonText;...
                    menu_handles.ZetaText;...
                    menu_handles.EpsilonValText;...
                    menu_handles.ZetaValText],...
                    'Visible','off');
            case 2
                set([menu_handles.EpsilonSlider;...
                    menu_handles.ZetaSlider;...
                    menu_handles.EpsilonText;...
                    menu_handles.ZetaText;...
                    menu_handles.EpsilonValText;...
                    menu_handles.ZetaValText],...
                    'Visible','on');
        end
        
    case 14         % ����������� �������
        
        switch get(menu_handles.FiltParMenu2,'Value')
            
            case 4      % ������������������ �������
                set(menu_handles.AlphaSlider,'Min',-5,'Max',5,'Value',1.5,...
                                'Visible','on','SliderStep',[0.01/10 0.1/10]);
                set(menu_handles.AlphaText,'String','�������: ','Visible','on');
                set(menu_handles.AlphaValText,'String','1.5','Visible','on');
                
            case 8      % ������� ���������
                
                MaskSize = 2*get(menu_handles.FiltParMenu1,'Value')+1;
                
                set(menu_handles.AlphaSlider,'Min',2,'Max',MaskSize^2-3,'Value',2,...
                    'Visible','on','SliderStep',[2/(MaskSize^2-5) 10/(MaskSize^2-5)]);
                
                set(menu_handles.AlphaText,'String','�����: ','Visible','on');
                set(menu_handles.AlphaValText,'String','2','Visible','on');
                
            otherwise
                
                set([menu_handles.AlphaSlider;...
                    menu_handles.AlphaText;...
                    menu_handles.AlphaValText],...
                    'Visible','off');                
        end
        
    case 25     % ������� ��
        
        switch get(menu_handles.FiltParMenu2,'Value')
            
            case 1      % ������������
                
                set(menu_handles.FiltParMenu3,'Value',1,'Visible','on');
                
                set([...   
                        menu_handles.ZetaSlider;...
                        menu_handles.ZetaText;...
                        menu_handles.ZetaValText;...
                        menu_handles.EpsilonSlider;...
                        menu_handles.EpsilonText;...
                        menu_handles.EpsilonValText...
                        ],'Visible','off');
                    
                FiltParMenu3_Callback(0,0,menu_handles);
                
            case 2      % ����������
                
                set([...   
                        menu_handles.EpsilonSlider;...
                        menu_handles.ZetaSlider;...
                        menu_handles.EpsilonText;...
                        menu_handles.ZetaText;...
                        menu_handles.EpsilonValText;...
                        menu_handles.ZetaValText...
                        ],'Visible','on');
                    
                set([  ... 
                        menu_handles.AlphaSlider;...
                        menu_handles.BetaSlider;...
                        menu_handles.GammaSlider;...
                        menu_handles.DeltaSlider;...
                        menu_handles.AlphaText;...
                        menu_handles.BetaText;...
                        menu_handles.GammaText;....
                        menu_handles.DeltaText;...
                        menu_handles.AlphaValText;...
                        menu_handles.BetaValText;...
                        menu_handles.GammaValText;...
                        menu_handles.DeltaValText;...
                        menu_handles.FiltParText3;...
                        menu_handles.FiltParMenu3...
                        ],'Visible','off');
        end
        
    case 26     % ������ ������
        
        switch get(menu_handles.FiltParMenu2,'Value')
            
            case 1      % ������������
                
                set([  ...
                    menu_handles.BetaSlider;...
                    menu_handles.BetaText;...
                    menu_handles.BetaValText;...
                    ],'Visible','off');
                
            case 2      % ����������
                
                set([  ...
                    menu_handles.BetaSlider;...
                    menu_handles.BetaText;...
                    menu_handles.BetaValText;...
                    ],'Visible','on');
        end        
        
    case 30        % ��������
        
        switch get(menu_handles.FiltParMenu2,'Value')
            case {1,2}
                set(menu_handles.FiltParMenu3,'String',{'������','��������',...
                    '����������� ��������','������� ��������','��������'});
                
            case {3,4}
                set(menu_handles.FiltParMenu3,'String',{'������','��������',...
                    '����������� ��������','������� ��������'});
        end
        
    case 34     % �������� �����������
        
        switch get(menu_handles.FiltParMenu2,'Value')
            case 1      % �������� ����
                
                set([  ...
                    menu_handles.BetaSlider;...
                    menu_handles.BetaText;...
                    menu_handles.BetaValText;...
                    ],'Visible','on');
            case 2
                set([  ...
                    menu_handles.BetaSlider;...
                    menu_handles.BetaText;...
                    menu_handles.BetaValText;...
                    ],'Visible','off');
                
        end
        
    case 35     % �������� �������� �����
        
        s = size(Original);
        maxH = min(s(1),s(2));
        maxMEV = max(s(1),s(2));
                
        % ������ ���, ����� ����� ��������� ���������
        set([  ...
            menu_handles.AlphaSlider;...
            menu_handles.BetaSlider;...
            menu_handles.GammaSlider;...
            menu_handles.DeltaSlider;...
            menu_handles.AlphaText;...
            menu_handles.BetaText;...
            menu_handles.GammaText;....
            menu_handles.DeltaText;...
            menu_handles.AlphaValText;...
            menu_handles.BetaValText;...
            menu_handles.GammaValText;...
            menu_handles.DeltaValText;...
            menu_handles.EpsilonSlider;...
            menu_handles.EpsilonText;...
            menu_handles.EpsilonValText;...
            menu_handles.ZetaSlider;...
            menu_handles.ZetaText;...
            menu_handles.ZetaValText;...
            ],'Visible','off');
        
        switch get(menu_handles.FiltParMenu2,'Value')
            
            case 1      % BRISK
                set([  ...
                    menu_handles.AlphaSlider;...
                    menu_handles.BetaSlider;...
                    menu_handles.DeltaSlider;...
                    menu_handles.AlphaText;...
                    menu_handles.BetaText;...
                    menu_handles.DeltaText;...
                    menu_handles.AlphaValText;...
                    menu_handles.BetaValText;...
                    menu_handles.DeltaValText...
                    ],'Visible','on');
                
                set(menu_handles.DeltaSlider,'Min',0,'Max',6,'Value',2,'SliderStep',[1/6 1/6]);
                set(menu_handles.DeltaValText,'String','2');
        
            case 2      % FAST
                set([  ...
                    menu_handles.AlphaSlider;...
                    menu_handles.BetaSlider;...
                    menu_handles.AlphaText;...
                    menu_handles.BetaText;...
                    menu_handles.AlphaValText;...
                    menu_handles.BetaValText...
                    ],'Visible','on');
                
            case 3      % HARRIS
                set([  ...
                    menu_handles.AlphaSlider;...
                    menu_handles.AlphaText;...
                    menu_handles.AlphaValText;...
                    menu_handles.GammaSlider;...
                    menu_handles.GammaText;...
                    menu_handles.GammaValText;...
                    ],'Visible','on');
                
                set(menu_handles.GammaSlider,'Min',3,'Max',maxH,'Value',3,...
                                            'SliderStep',[2/maxH 10/maxH]);
                set(menu_handles.GammaValText,'String','3');
                
            case 4      % MinEugenVals
                set([  ...
                    menu_handles.AlphaSlider;...
                    menu_handles.AlphaText;...
                    menu_handles.AlphaValText;...
                    menu_handles.GammaSlider;...
                    menu_handles.GammaText;...
                    menu_handles.GammaValText;...
                    ],'Visible','on');
                
                set(menu_handles.GammaSlider,'Min',3,'Max',maxMEV,'Value',3,...
                                        'SliderStep',[2/maxMEV 10/maxMEV]);
                set(menu_handles.GammaValText,'String','3');
                
            case 5      % SURF
                set([  ...
                    menu_handles.DeltaSlider;...
                    menu_handles.DeltaText;...
                    menu_handles.DeltaValText;...
                    menu_handles.EpsilonSlider;...
                    menu_handles.EpsilonText;...
                    menu_handles.EpsilonValText;...
                    menu_handles.ZetaSlider;...
                    menu_handles.ZetaText;...
                    menu_handles.ZetaValText...
                    ],'Visible','on');
                
                set(menu_handles.DeltaSlider,'Min',1,'Max',6,'Value',2,'SliderStep',[1/5 1/5]);
                set(menu_handles.DeltaValText,'String','2');
                
        end
end


% ������ ������
function FiltParMenu3_Callback(~,~,menu_handles)

global Original;

switch get(menu_handles.FilterType,'Value')     % ��� ���������
        
    case 4                  % ��������������� ���������
        
        if get(menu_handles.FiltParMenu2,'Value') < 7
            Max = floor(min(size(Original,1),size(Original,1))/2)-1;            
            set(menu_handles.FiltParButton2,'Visible','on');
                
            switch get(menu_handles.FiltParMenu3,'Value')
                
                case 1      % ����
                    
                    set(menu_handles.BetaSlider,'Min',1,'Max',Max,...
                        'Value',1,'SliderStep',[1/(Max-1) 10/(Max-1)]);
                    set(menu_handles.BetaText,'String','R = ');
                    set(menu_handles.BetaValText,'String','1');
                    
                    set([   menu_handles.GammaSlider;...
                        menu_handles.GammaText;...
                        menu_handles.GammaValText],...
                        'Visible','off');
                    
                    set([   menu_handles.MaskTable;...
                        menu_handles.MaskText],...
                        'Visible','off');
                    
                case 2      % ����
                    
                    set(menu_handles.BetaSlider,'Min',1,'Max',Max,...
                        'Value',1,'SliderStep',[1/(Max-1) 10/(Max-1)]);
                    set(menu_handles.BetaText,'String','R = ');
                    set(menu_handles.BetaValText,'String','1');
                    
                    set([   menu_handles.GammaSlider;...
                        menu_handles.GammaText;...
                        menu_handles.GammaValText],...
                        'Visible','off');
                    
                    set([   menu_handles.MaskTable;...
                        menu_handles.MaskText],...
                        'Visible','off');
                    
                case 3      % �����
                    
                    set(menu_handles.BetaSlider,'Min',3,'Max',Max,...
                        'Value',3,'SliderStep',[1/(Max-3) 10/(Max-3)]);
                    set(menu_handles.BetaText,'String','�����:');
                    set(menu_handles.BetaValText,'String','3');
                    
                    set(menu_handles.GammaSlider,'Min',0,'Max',360,...
                        'Value',0,'SliderStep',[1/360 10/360]);
                    set(menu_handles.GammaText,'String','����, ��.:');
                    set(menu_handles.GammaValText,'String','0');
                    
                    set([   menu_handles.GammaSlider;...
                        menu_handles.GammaText;...
                        menu_handles.GammaValText],...
                        'Visible','on');
                    
                    set([   menu_handles.MaskTable;...
                        menu_handles.MaskText],...
                        'Visible','off');
                    
                case 4      % 8-��������
                    
                    Max = Max - mod(Max,3);
                    set(menu_handles.BetaSlider,'Min',3,'Max',Max,...
                        'Value',3,'SliderStep',[3/(Max-3) 3/(Max-3)]);
                    set(menu_handles.BetaText,'String','R = ');
                    set(menu_handles.BetaValText,'String','1');
                    
                    set([   menu_handles.GammaSlider;...
                        menu_handles.GammaText;...
                        menu_handles.GammaValText],...
                        'Visible','off');
                    
                    set([   menu_handles.MaskTable;...
                        menu_handles.MaskText],...
                        'Visible','off');
                    
                case 5      % ���� �����
                    
                    set(menu_handles.BetaSlider,'Min',1,'Max',floor(size(Original,1)/2),...
                        'Value',1,'SliderStep',[1/(floor(size(Original,1)/2)-1) 10/(floor(size(Original,1)/2)-1)]);
                    set(menu_handles.BetaText,'String','���. �����:');
                    set(menu_handles.BetaValText,'String','1');
                    
                    set(menu_handles.GammaSlider,'Min',1,'Max',floor(size(Original,2)/2),...
                        'Value',1,'SliderStep',[1/(floor(size(Original,2)/2)-1) 10/(floor(size(Original,2)/2)-1)]);
                    set(menu_handles.GammaText,'String','�����. �����:');
                    set(menu_handles.GammaValText,'String','1');
                    
                    set([   menu_handles.GammaSlider;...
                        menu_handles.GammaText;...
                        menu_handles.GammaValText],...
                        'Visible','on');
                    
                    set([   menu_handles.MaskTable;...
                        menu_handles.MaskText],...
                        'Visible','off');
                    
                case 6      % �������������
                    
                    set(menu_handles.BetaSlider,'Min',1,'Max',floor(size(Original,1)/2),...
                        'Value',1,'SliderStep',[1/(floor(size(Original,1)/2)-1) 10/(floor(size(Original,1)/2)-1)]);
                    set(menu_handles.BetaText,'String','���-�� �����:');
                    set(menu_handles.BetaValText,'String','1');
                    
                    set(menu_handles.GammaSlider,'Min',1,'Max',floor(size(Original,2)/2),...
                        'Value',1,'SliderStep',[1/(floor(size(Original,2)/2)-1) 10/(floor(size(Original,2)/2)-1)]);
                    set(menu_handles.GammaText,'String','���-�� ��������:');
                    set(menu_handles.GammaValText,'String','1');
                    
                    set([   menu_handles.GammaSlider;...
                        menu_handles.GammaText;...
                        menu_handles.GammaValText],...
                        'Visible','on');
                    
                    set([   menu_handles.MaskTable;...
                        menu_handles.MaskText],...
                        'Visible','off');
                    
                    
                    
                case 7      % ����������������
                             
                    set(menu_handles.FiltParButton2,'Visible','off');
                
                    set(menu_handles.BetaSlider,'Min',1,'Max',4,...
                        'Value',1,'SliderStep',[1/3 1/3]);
                    set(menu_handles.BetaText,'String','������ �������:');
                    set(menu_handles.BetaValText,'String','3�3');
                    
                    set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',34,...
                        'Position',[400 5 182 182],...
                        'ColumnWidth',{60 60 60});
                    
                    set([   menu_handles.MaskTable;...
                        menu_handles.MaskText],...
                        'Visible','on');
                    
                    set([   menu_handles.GammaSlider;...
                        menu_handles.GammaText;...
                        menu_handles.GammaValText],...
                        'Visible','off');
                    
            end
        end
        
    case 25         % ������� ��
        
        switch get(menu_handles.FiltParMenu3,'Value')
            
            case 1      % ���������� ������
                
                set([  ... 
                        menu_handles.AlphaSlider;...
                        menu_handles.AlphaText;...
                        menu_handles.AlphaValText;...
                        ],'Visible','on');
                    
                
                set([  ... 
                        menu_handles.BetaSlider;...
                        menu_handles.GammaSlider;...
                        menu_handles.BetaText;...
                        menu_handles.DeltaSlider;...
                        menu_handles.GammaText;....
                        menu_handles.DeltaText;...
                        menu_handles.BetaValText;...
                        menu_handles.GammaValText;...
                        menu_handles.DeltaValText;...
                        ],'Visible','off');
                
            case 2      % ����������������� ������
                
                set([  ... 
                        menu_handles.GammaSlider;...
                        menu_handles.DeltaSlider;...
                        menu_handles.GammaText;....
                        menu_handles.DeltaText;...
                        menu_handles.GammaValText;...
                        menu_handles.DeltaValText;...
                        ],'Visible','on');
                    
                set([  ... 
                        menu_handles.AlphaSlider;...
                        menu_handles.BetaSlider;...
                        menu_handles.AlphaText;...
                        menu_handles.BetaText;...
                        menu_handles.AlphaValText;...
                        menu_handles.BetaValText;...
                        ],'Visible','off');
                    
            case 3      % ���������� + ����������������� ������
                
                set([  ... 
                        menu_handles.AlphaSlider;...
                        menu_handles.BetaSlider;...
                        menu_handles.GammaSlider;...
                        menu_handles.DeltaSlider;...
                        menu_handles.AlphaText;...
                        menu_handles.BetaText;...
                        menu_handles.GammaText;....
                        menu_handles.DeltaText;...
                        menu_handles.AlphaValText;...
                        menu_handles.BetaValText;...
                        menu_handles.GammaValText;...
                        menu_handles.DeltaValText;...
                        ],'Visible','on');
        end        
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% �������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ������� "�" ���������� ����
function Aslider_Callback(~, ~, menu_handles)

A = get(menu_handles.Aslider,'Value');          % �������� �������� ��������
        
switch get(menu_handles.NoiseType,'Value');     % ��������� ����� ���������� ����  
    
    case {2,4,6,7,8,9,10,12}          % ����������,����������������,�������,�����,�������� ���
        A = round(A);
        
    case 11                      % ����� ���
        A = round(A*100)/100;
        
    case 5         % ����������� ���
        
        A = round(get(menu_handles.Aslider,'Value'));
        set(menu_handles.Aslider,'Value',A);
        B_max = get(menu_handles.Bslider,'Max');
        
        if  B_max == A+1
            set(menu_handles.Bslider,'Enable','off');
        else
            set(menu_handles.Bslider,'Enable','on')
            set(menu_handles.Bslider,'Min',A+1,'SliderStep',[1/(B_max-A-1) 10/(B_max-A-1)]);
        end        
        
end

set(menu_handles.Aslider,'Value',A);
set(menu_handles.text12,'String',num2str(A));


% ������� "�" ���������� ����
function Bslider_Callback(~, ~, menu_handles)

B = get(menu_handles.Bslider,'Value');          % ��������� �������� ��������

switch get(menu_handles.NoiseType,'Value');     % ��������� ����� ���������� ����  
    
    case {2,4,10}           % ����������,�������,�������� ���  
        B = round(B);
        
    case 5                 % ����������� ���
        
        B = round(get(menu_handles.Bslider,'Value'));
        set(menu_handles.Bslider,'Value',B);
        A_min = get(menu_handles.Aslider,'Min');
        
        if     A_min == B-1
            set(menu_handles.Aslider,'Enable','off');
        else
            set(menu_handles.Aslider,'Enable','on');
            set(menu_handles.Aslider,'Max',B-1,'SliderStep',[1/(B-A_min-1) 10/(B-A_min-1)]);
        end
        
end

set(menu_handles.Bslider,'Value',B);
set(menu_handles.text13,'String',num2str(B));


% ������� ������ �������� �������
function DeleteSlider_Callback(~, ~, menu_handles)

D = get(menu_handles.DeleteSlider,'Value');  % ��������� �������� ��������

set(menu_handles.NoiseFilterString,'Value',D);           
set(menu_handles.DeleteSlider,'Value',D);                % ������ �������� ��������
set(menu_handles.DeleteNumber,'String',num2str(D));      % ������ ����� �������


% ������� ��������� "�����"
function AlphaSlider_Callback(~, ~, menu_handles)

global Original;

A = get(menu_handles.AlphaSlider,'Value');
RewriteTextString = 0;                  % �� ���� ������������ ��������� ������

switch get(menu_handles.FilterType,'Value')
             
    case {3,4,5,7,12,24,27,29,31,32}         % ���������
        A = round(A);
        
    case {6,8,13,20,21,22,33,35}    % �������������, ������, ������ ������ ������, ������+�������, 
               
        A = round(A*100)/100;
        
    case 9      % �������������� ����        

        A = round(A);
        if A == 88
            set(menu_handles.BetaSlider,'Enable','off');     % ��������� �������
        else
            set(menu_handles.BetaSlider,'Enable','on');      % ����� ������ ������� ������� ��������
            set(menu_handles.BetaSlider,'Min',A+1,...
                'SliderStep',[1/(89-1-A) 10/(89-1-A)]);
        end
        
        % � ��������� �������� ���� ����� �������� ������� ����� ����������
        B = get(menu_handles.BetaSlider,'Value');           % ������� ������ �� ����
        RhoStep = get(menu_handles.GammaSlider,'Value');    % ��� �� ��
        STR = get(menu_handles.FiltParMenu2,'String');      % �������� ��� �� ����
        num = get(menu_handles.FiltParMenu2,'Value');
        ThetaStep = str2double(STR(num));
        BW = Original(:,:,1);                               % 2D �����������
        [MinMask,MaxMask] = SuppressMaskRecount(BW,A,B,ThetaStep,RhoStep);
        
        set(menu_handles.DeltaSlider,'Min',MinMask(1),'Max',MaxMask(1),'Value',MinMask(1),...
                                    'SliderStep',[2/(MaxMask(1)-MinMask(1)) 10/(MaxMask(1)-MinMask(1))]);
        set(menu_handles.DeltaValText,'String',[num2str(MinMask(1)) 'x' num2str(MinMask(2))]);
        
        set(menu_handles.EtaSlider,'Min',MinMask(2),'Max',MaxMask(2),'Value',MinMask(2),...
                                    'SliderStep',[2/(MaxMask(2)-MinMask(2)) 10/(MaxMask(2)-MinMask(2))]);

    
    case 10     % ���������������� ����������
        
        A = round(A);
        
        if A == size(Original,2)-1
            set(menu_handles.BetaSlider,'Enable','off');     % ��������� �������
        else
            set(menu_handles.BetaSlider,'Enable','on');      % ����� ������ ������� ������� ��������
            set(menu_handles.BetaSlider,'Min',A+1,...
                'SliderStep',[1/(size(Original,2)-1-A) 10/(size(Original,2)-1-A)]);
        end
        
    case {11,25}
        A = round(A);
                        
    case 14                 % ����������� ������
        
        if get(menu_handles.FiltParMenu2,'Value') == 4            
            A = round(A*100)/100;       % ��������� �� ������   
            
        elseif get(menu_handles.FiltParMenu2,'Value') == 8  % ���� ������ ��������� 
            
            A = round(A);       % ��������� �� ������
            A = A - mod(A,2);                           % ������� ������
        end
                
    case {15,17,18}
        
        A = round(A);
        
        if A == 0
           A = '����';
        end        
        
    case 16         %      
        A = round(A);
        
        if  A == 254
            set(menu_handles.BetaSlider,'Enable','off');
        else
            set(menu_handles.BetaSlider,'Enable','on');
            set(menu_handles.BetaSlider,'Min',A+1,'SliderStep',[1/(256-A-1) 10/(256-A-1)]);
        end
        
        if A == -1              % � ������ ������� ����� ����� ���� ���������� �����.����������� ������
            set(menu_handles.AlphaValText,'String','����');
            set(menu_handles.BetaValText,'String','����');
            set(menu_handles.BetaSlider,'Enable','off');
            RewriteTextString = 1;   % � ���� ������ �� ������������ ������
        else            
            set(menu_handles.BetaValText,'String',num2str(get(menu_handles.BetaSlider,'Value')));
            RewriteTextString = 0;
        end 
        
    case 23  %  ���������� ���������
        
        A = round(A);        
        A = A - 1 + mod(A,2);             % ������ �������� 
        
    case 26    % ������
        A = round(A*100)/100;     
        
        
    case 30         % ��������� ��������� 
        
        A = round(A);
        
        if  A == 254
            set(menu_handles.BetaSlider,'Enable','off');
        else
            set(menu_handles.BetaSlider,'Enable','on');
            set(menu_handles.BetaSlider,'Min',A+1,'SliderStep',[1/(255-A-1) 10/(255-A-1)]);
        end
end

if RewriteTextString == 0            % ���� �� ����� ������������
    if isnumeric(A) == 1            
        set(menu_handles.AlphaSlider,'Value',A);
        set(menu_handles.AlphaValText,'String',num2str(A));
    else
        set(menu_handles.AlphaValText,'String',A);
    end
end


% ������� ��������� "����"
function BetaSlider_Callback(~, ~, menu_handles)

global Original;

B = get(menu_handles.BetaSlider,'Value');
RewriteTextString = 0;                  % �� ���� ������������ ��������� ������

switch get(menu_handles.FilterType,'Value')
    
    case {3,6,8,32,34,35}       % �����������, �������������
        
        B = round(B*100)/100;           % ���������
    
    case 4      % ��������������� ��������� (�/�)
        
        switch get(menu_handles.FiltParMenu2,'Value')       % ��� ���������
            
            case {1,2,3,4,5,6}
                B = round(B);
                    
                if get(menu_handles.FiltParMenu3,'Value') == 4   % ��������������
                    
                    B = B - mod(B,3);
                
                elseif get(menu_handles.FiltParMenu3,'Value') == 7
                    
                    set(menu_handles.BetaSlider,'Value',B);
                    
                    switch B       % ��������� �������� �����
                        
                        case 1          % ����� 3�3
                            
                            set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',34,...
                                'Position',[400 5 182 182],...
                                'ColumnWidth',{60 60 60});
                            
                        case 2          % ����� 5�5
                            set(menu_handles.MaskTable,'Data',ones(5),'FontSize',19,...
                                'Position',[405 5 177 177],...
                                'ColumnWidth',{35 35 35 35 35});
                        case 3          % ����� 7�7
                            
                            set(menu_handles.MaskTable, 'Data',ones(7),'FontSize',12,...
                                'Position',[405 5 177 163],...
                                'ColumnWidth',{25 25 25 25 25 25 25});
                        case 4          % ����� 9�9
                            set(menu_handles.MaskTable, 'Data',ones(9),'FontSize',10,...
                                'Position',[400 5 182 182],...
                                'ColumnWidth',{20 20 20 20 20 20 20 20 20});
                    end                    
                    
                    B = [num2str(2*B+1) 'x' num2str(2*B+1)];
                    
                end
                
            case 11
                B = round(B); 
        end                    
        
    case {5,7,11,12,25,26,29}
        B = round(B);
                
    case 9      % �������������� ����
        
        B = round(B);
        if B == -89
            set(menu_handles.AlphaSlider,'Enable','off');
        else
            set(menu_handles.AlphaSlider,'Enable','on');
            set(menu_handles.AlphaSlider,'Max',B-1,'SliderStep',[1/(B-1+90) 10/(B-1+90)]);
        end
        
        
        % � ��������� �������� ���� ����� �������� ������� ����� ����������
        A = get(menu_handles.AlphaSlider,'Value');          % ������� ������ �� ����
        RhoStep = get(menu_handles.GammaSlider,'Value');    % ��� �� ��
        STR = get(menu_handles.FiltParMenu2,'String');      % �������� ��� �� ����
        num = get(menu_handles.FiltParMenu2,'Value');
        ThetaStep = str2double(STR(num));
        BW = Original(:,:,1);                               % 2D �����������
        [MinMask,MaxMask] = SuppressMaskRecount(BW,A,B,ThetaStep,RhoStep);
        
        set(menu_handles.DeltaSlider,'Min',MinMask(1),'Max',MaxMask(1),'Value',MinMask(1),...
                                    'SliderStep',[2/(MaxMask(1)-MinMask(1)) 10/(MaxMask(1)-MinMask(1))]);
        set(menu_handles.DeltaValText,'String',[num2str(MinMask(1)) 'x' num2str(MinMask(2))]);
        
        set(menu_handles.EtaSlider,'Min',MinMask(2),'Max',MaxMask(2),'Value',MinMask(2),...
                                    'SliderStep',[2/(MaxMask(2)-MinMask(2)) 10/(MaxMask(2)-MinMask(2))]);
        
    case 10        % ���������������� ����������
        
        B = round(B);
        if B == 2
            set(menu_handles.AlphaSlider,'Enable','off');
        else
            set(menu_handles.AlphaSlider,'Enable','on');
            set(menu_handles.AlphaSlider,'Max',B-1,'SliderStep',[1/(B-2) 10/(B-2)]);
        end       

    case 16             %  
        B = round(B);  
        
        if B == 1
            set(menu_handles.AlphaSlider,'Enable','off');
        else
            set(menu_handles.AlphaSlider,'Enable','on');
            set(menu_handles.AlphaSlider,'Max',B-1,'SliderStep',[1/B 10/B]);
        end
        
        if B == 256              % � ������ ������� ����� ����� ���� ���������� �����.����������� ������
            set(menu_handles.AlphaValText,'String','����');
            set(menu_handles.BetaValText,'String','����');
            set(menu_handles.AlphaSlider,'Enable','off');
            RewriteTextString = 1;   % � ���� ������ �� ������������ ������
        else            
            set(menu_handles.AlphaValText,'String',num2str(get(menu_handles.AlphaSlider,'Value')));
            RewriteTextString = 0;
        end
        
   case 30            % ��������� ���������   
        B = round(B);  
        
        if B == 1
            set(menu_handles.AlphaSlider,'Enable','off');
        else
            set(menu_handles.AlphaSlider,'Enable','on');
            set(menu_handles.AlphaSlider,'Max',B-1,'SliderStep',[1/(B-1) 10/(B-1)]);
        end          
        
    case 33
        
        B = round(B);           % ���������
        
        if B == 254                                     % ���� ������ � ������� 
            set(menu_handles.GammaSlider,'Enable','off');     % ��������� �������
        else
            set(menu_handles.GammaSlider,'Enable','on');      % ����� ������ ������� ������� ��������
            set(menu_handles.GammaSlider,'Min',B+1,'SliderStep',[1/(255-B-1) 10/(255-B-1)]);
        end        
        
end

if RewriteTextString == 0            % ���� �� ����� ������������
    if isnumeric(B) == 1  
        set(menu_handles.BetaSlider,'Value',B);
        set(menu_handles.BetaValText,'String',num2str(B));
    else
        set(menu_handles.BetaValText,'String',B);
    end
end


% ������� ��������� "�����"
function GammaSlider_Callback(~, ~, menu_handles)

global Original;

G = get(menu_handles.GammaSlider,'Value');

switch get(menu_handles.FilterType,'Value')         
        
    case {3,5,7,8,11,25,34}      % ������ �������� �������    
         G = round(G);
         
    case 4
        G = round(G);
        set(menu_handles.GammaSlider,'Value',G);
        
        if get(menu_handles.FiltParMenu2,'Value') == 11     % �����/�������
            
            
            switch G       % ��������� �������� �����
                
                case 1          % ����� 3�3
                    
                    set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',34,...
                        'Position',[400 5 182 182],...
                        'ColumnWidth',{60 60 60});
                    
                case 2          % ����� 5�5
                    set(menu_handles.MaskTable,'Data',ones(5),'FontSize',19,...
                        'Position',[405 5 177 177],...
                        'ColumnWidth',{35 35 35 35 35});
                case 3          % ����� 7�7
                    
                    set(menu_handles.MaskTable, 'Data',ones(7),'FontSize',12,...
                        'Position',[405 5 177 163],...
                        'ColumnWidth',{25 25 25 25 25 25 25});
                case 4          % ����� 9�9
                    set(menu_handles.MaskTable, 'Data',ones(9),'FontSize',10,...
                        'Position',[400 5 182 182],...
                        'ColumnWidth',{20 20 20 20 20 20 20 20 20});
            end           
                        
            set(menu_handles.EpsilonSlider,'Min',1,'Max',2*G+1,...
                'Value',1,'SliderStep',[1/(2*G) 1/(2*G)]);
            set(menu_handles.EpsilonText,'String','������:');
            set(menu_handles.EpsilonValText,'String','1');
            
            set(menu_handles.ZetaSlider,'Min',1,'Max',2*G+1,...
                'Value',1,'SliderStep',[1/(2*G) 1/(2*G)]);
            set(menu_handles.ZetaText,'String','�������:');
            set(menu_handles.ZetaValText,'String','1');
            
            G = [num2str(2*G+1) 'x' num2str(2*G+1)];
        end
                 
    case 9      % �������������� ����
        
        G = round(G*10)/10;
        
        % � ��������� �������� ���� ����� �������� ������� ����� ����������
        A = get(menu_handles.AlphaSlider,'Value');          % ������� ������ �� ����
        B = get(menu_handles.BetaSlider,'Value');           % ������� ������ �� ����
        STR = get(menu_handles.FiltParMenu2,'String');      % �������� ��� �� ����
        num = get(menu_handles.FiltParMenu2,'Value');
        ThetaStep = str2double(STR(num));
        BW = Original(:,:,1);                               % 2D �����������
        [MinMask,MaxMask] = SuppressMaskRecount(BW,A,B,ThetaStep,G);
        
        set(menu_handles.DeltaSlider,'Min',MinMask(1),'Max',MaxMask(1),'Value',MinMask(1),...
                                    'SliderStep',[2/(MaxMask(1)-MinMask(1)) 10/(MaxMask(1)-MinMask(1))]);
        set(menu_handles.DeltaValText,'String',[num2str(MinMask(1)) 'x' num2str(MinMask(2))]);
        
        set(menu_handles.EtaSlider,'Min',MinMask(2),'Max',MaxMask(2),'Value',MinMask(2),...
                                    'SliderStep',[2/(MaxMask(2)-MinMask(2)) 10/(MaxMask(2)-MinMask(2))]);
        
        
        
    case 10     % ���������������� ����������
        
         G = round(G);
         
         if G == size(Original,1)-1
             set(menu_handles.DeltaSlider,'Enable','off');     % ��������� �������
         else
             set(menu_handles.DeltaSlider,'Enable','on');      % ����� ������ ������� ������� ��������
             set(menu_handles.DeltaSlider,'Min',G+1,...
             'SliderStep',[1/(size(Original,1)-1-G) 10/(size(Original,1)-1-G)]);
         end  
         
         
    case 16
        G = round(G*100)/100;               % ������ �����
        
    case 33
        
        G = round(G);
        
        if G == 1
            set(menu_handles.BetaSlider,'Enable','off');
        else
            set(menu_handles.BetaSlider,'Enable','on');
            set(menu_handles.BetaSlider,'Max',G-1,'SliderStep',[1/(G-1) 10/(G-1)]);
        end
        
    case 35         % ���������
        
        G = round(G);
        G = G - 1 + mod(G,2);    % ��������� � ������� ��������        
        
end

if isnumeric(G) == 1
    set(menu_handles.GammaSlider,'Value',G);
    set(menu_handles.GammaValText,'String',num2str(G));
else
    set(menu_handles.GammaValText,'String',G);
end
    

% ������� ��������� "������"
function DeltaSlider_Callback(~, ~, menu_handles)

D = get(menu_handles.DeltaSlider,'Value');

switch get(menu_handles.FilterType,'Value') 
    
    case 3      % �����������
            
         D = round(D);
         Et = get(menu_handles.EtaSlider,'Value');
         Et = round(Et);
        
         set(menu_handles.DeltaSlider,'Value',D);
         set(menu_handles.DeltaValText,'String',[num2str(D) 'x' num2str(Et)]);
         
         return;
       
    case {4,5}      % ��������������� ���������        
          
         D = round(D);
         if D == 0
             D = char(8734);
         end
        
    case {7,8,25,35}      % ������ �������� �������    
         D = round(D);                 
        
    case 9          % �������������� ����   
         D = round(D);
         D = D + mod(D,2) - 1;          
         
         Et = get(menu_handles.EtaSlider,'Value');
         Et = round(Et);
         Et = Et + mod(Et,2) - 1;
         
         set(menu_handles.DeltaSlider,'Value',D);
         set(menu_handles.DeltaValText,'String',[num2str(D) 'x' num2str(Et)]);
         
         return;         
         
    case 10        % ���������������� ����������
        
        D = round(D);
        if D == 2
            set(menu_handles.GammaSlider,'Enable','off');
        else
            set(menu_handles.GammaSlider,'Enable','on');
            set(menu_handles.GammaSlider,'Max',D-1,'SliderStep',[1/(D-2) 10/(D-2)]);
        end
        
        
    case 33
        D = round(D);           % ���������
        
        if D == 254                                     % ���� ������ � ������� 
            set(menu_handles.EpsilonSlider,'Enable','off');     % ��������� �������
        else
            set(menu_handles.EpsilonSlider,'Enable','on');      % ����� ������ ������� ������� ��������
            set(menu_handles.EpsilonSlider,'Min',D+1,'SliderStep',[1/(255-D-1) 10/(255-D-1)]);
        end
        
    case 29
        D = round(D);           % ��������� 
        Et = get(menu_handles.EtaSlider,'Value');
        if D >= Et
            D = Et;
        end
        
        set(menu_handles.DeltaSlider,'Value',D);
        set(menu_handles.DeltaValText,'String',[num2str(D) ' ' char(8804) ' I ' char(8804) ' ' num2str(Et)]);
        return;
        
    case 34
        D = round(D);           % ��������� 
        Et = get(menu_handles.EtaSlider,'Value');
        if D >= Et
            D = Et;
        end
        
        set(menu_handles.DeltaSlider,'Value',D);
        set(menu_handles.DeltaValText,'String',[num2str(D) char(8804) 'R' char(8804) num2str(Et)]);
        return;
end

if isnumeric(D) == 1
    set(menu_handles.DeltaSlider,'Value',D);
    set(menu_handles.DeltaValText,'String',num2str(D));
else
    set(menu_handles.DeltaValText,'String',D);    
end


% ������� ��������� "�������"
function EpsilonSlider_Callback(~, ~, menu_handles)

E = get(menu_handles.EpsilonSlider,'Value');

switch get(menu_handles.FilterType,'Value')
    
    case {4,8,9,25,35}                  % ����� ����-�� (�/�) 
        E = round(E);        
     
    case 10                 % ���������������� ����������
        E = round(E);
        
        if  E == 254
            set(menu_handles.ZetaSlider,'Enable','off');
        else
            set(menu_handles.ZetaSlider,'Enable','on');
            set(menu_handles.ZetaSlider,'Min',E+1,'SliderStep',[1/(255-E-1) 10/(255-E-1)]);
        end
        
        
    case 33
        
        E = round(E);
        
        if E == 1
            set(menu_handles.DeltaSlider,'Enable','off');
        else
            set(menu_handles.DeltaSlider,'Enable','on');
            set(menu_handles.DeltaSlider,'Max',E-1,'SliderStep',[1/(E-1) 10/(E-1)]);
        end
        
end

set(menu_handles.EpsilonSlider,'Value',E);
set(menu_handles.EpsilonValText,'String',num2str(E));


% ������� ��������� "�����"
function ZetaSlider_Callback(~,~,menu_handles)

Z = get(menu_handles.ZetaSlider,'Value');

switch get(menu_handles.FilterType,'Value')
    
    case {4,9,35}                  % ����� ����-�� (�/�) 
        Z = round(Z);
        
    case 10        % ���������������� ����������
        Z = round(Z);
        
        if Z == 1
            set(menu_handles.EpsilonSlider,'Enable','off');
        else
            set(menu_handles.EpsilonSlider,'Enable','on');
            set(menu_handles.EpsilonSlider,'Max',Z-1,'SliderStep',[1/(Z-1) 10/(Z-1)]);
        end
        
    case 25     % ������� ��
        
        Z = round(Z*100)/100;
        
end

set(menu_handles.ZetaSlider,'Value',Z);
set(menu_handles.ZetaValText,'String',num2str(Z));


% ������� ��������� "���"
function EtaSlider_Callback(~,~,menu_handles)

Et = get(menu_handles.EtaSlider,'Value');

switch get(menu_handles.FilterType,'Value')
    
    case 3          % �����������
        
         Et = round(Et);
         D = get(menu_handles.DeltaSlider,'Value');
         D = round(D);
         
         set(menu_handles.EtaSlider,'Value',Et);
         set(menu_handles.DeltaValText,'String',[num2str(D) 'x' num2str(Et)]);
         
         return;
    
    case 9          % �������������� ����        
        
         Et = round(Et);
         Et = Et + mod(Et,2) - 1;
        
         D = get(menu_handles.DeltaSlider,'Value');
         D = round(D);
         D = D + mod(D,2) - 1;    
         
         set(menu_handles.EtaSlider,'Value',Et);
         set(menu_handles.DeltaValText,'String',[num2str(D) 'x' num2str(Et)]);
         return;
         
    case 29         % �������� �����������
        
         Et = round(Et);   
         D = get(menu_handles.DeltaSlider,'Value'); 
         
         if Et <= D
             Et = D;
         end
         
         set(menu_handles.EtaSlider,'Value',Et);
         set(menu_handles.DeltaValText,'String',[num2str(D) ' ' char(8804) ' I ' char(8804) ' ' num2str(Et)]);
         return;
         
    case 34         % �������� �����������
        
         Et = round(Et);   
         D = get(menu_handles.DeltaSlider,'Value'); 
         
         if Et <= D
             Et = D;
         end
         
         set(menu_handles.EtaSlider,'Value',Et);
         set(menu_handles.DeltaValText,'String',[num2str(D) char(8804) 'R' char(8804) num2str(Et)]);
         return;
end

set(menu_handles.EtaSlider,'Value',Et);


% ������� ��������� "����"
function TetaSlider_Callback(~,~,menu_handles)

Teta = get(menu_handles.TetaSlider,'Value');

switch get(menu_handles.FilterType,'Value')
    
    case 9          % �������������� ����        
        
         Teta = round(Teta);   
end

set(menu_handles.TetaSlider,'Value',Teta);
set(menu_handles.TetaValText,'String',num2str(Teta));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ������ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ������ "��������������� ��������"
function PreviewButton_Callback(~, ~, menu_handles)

global Original;
global FilteredAsOriginal;

% ���� ��������� �������� �� �������� �����������
if isempty(FilteredAsOriginal)
    I = Original;
else
    I = FilteredAsOriginal;
end    
    
I = Noising(I,...
            get(menu_handles.NoiseType,'Value'),...
            get(menu_handles.Aslider,'Value'),...
            get(menu_handles.Bslider,'Value'));           
    
if size(I,3) > 3
    Image = I(:,:,1:3);
else
    Image = I(:,:,:);
end

try     
    imtool(Image); 
catch
    OpenImageOutside(Image); 
end


% ������ "����������� �����������"
function ImageHistButton_Callback(~, ~, ~)

global Original;
global FilteredAsOriginal;      % ����� ������������ �����������

if isempty(FilteredAsOriginal)  % ������, ����� ����������� ������ ������������
    Image = Original;
else
    Image = FilteredAsOriginal;
end

BuildHist(NewFigureWihAxes(),Image,'����������� ���������� �����������');


% ������ "����������� ����"
function HistButton_Callback(~, ~, menu_handles)

global Original;

Image = Noising(zeros(size(Original)),...
                get(menu_handles.NoiseType,'Value'),...
                get(menu_handles.Aslider,'Value'),....
                get(menu_handles.Bslider,'Value'));
    
BuildHist(NewFigureWihAxes(),Image(:,:,1),'����������� ����');
    

% ������ "����������� � �����"
function NoisedImageHistButton_Callback(~, ~, menu_handles)

global Original;
global FilteredAsOriginal;      % ����� ������������ �����������

if isempty(FilteredAsOriginal)  % ������, ����� ����������� ������ ������������
    Image = Original;
else
    Image = FilteredAsOriginal;
end

Image = Noising(Image,get(menu_handles.NoiseType,'Value'),...
        get(menu_handles.Aslider,'Value'),get(menu_handles.Bslider,'Value'));    

BuildHist(NewFigureWihAxes(),Image,'����������� ����������� ���������� �����������');
    

% ������ "��������"
function AddButton_Callback(~, ~, menu_handles)

global Original;
global Noises;              % ������ ���������� ����������
global Filters;             % ������ ���������� ����������
global Parametrs;           % ��������� ������������ (���� � �������)


Current = size(Noises,1) + 1;        % ����� ������, � ������� ������� ����� ��������

% ��������� �������� ��������� � ������� "���������" � "���������"

set([   menu_handles.DeleteNumber;...
        menu_handles.DeleteButton;...
        menu_handles.ApplyButton],...
        'Enable','on');

Noises(Current,1) = get(menu_handles.NoiseType,'Value');            % ��������� ��� ���� (1 �������)
Noises(Current,2) = get(menu_handles.Aslider,'Value');              % �������� � (2 �������)
Noises(Current,3) = get(menu_handles.Bslider,'Value');              % ��������� � �������� (3 �������)
Noises(Current,4) = get(menu_handles.UsePreviousFiltImage,'Value'); % ��������� ������� "���. ����������� �����."

Filters(Current).FilterType = get(menu_handles.FilterType,'Value');           % ��������� ��� �������
Filters(Current).Indent = get(menu_handles.IndentMenu,'Value');           % ��������� �������� ���� ��������� �����
Filters(Current).FPM1 = get(menu_handles.FiltParMenu1,'Value');       % � ������ �����
Filters(Current).FPM2 = get(menu_handles.FiltParMenu2,'Value');          % ��������� �������� ������� ����
Filters(Current).FPM3 = get(menu_handles.FiltParMenu3,'Value');          % ��������� �������

Filters(Current).Alpha = get(menu_handles.AlphaSlider,'Value');          % ��������� �������� �����
Filters(Current).Beta = get(menu_handles.BetaSlider,'Value');           % ��������� �������� ����
Filters(Current).Gamma = get(menu_handles.GammaSlider,'Value');          % ��������� �������� �������� �����
Filters(Current).Delta = get(menu_handles.DeltaSlider,'Value');           % ��������� �������� ������
Filters(Current).Epsilon = get(menu_handles.EpsilonSlider,'Value');          % ��������� �������� �������� �������
Filters(Current).Zeta = get(menu_handles.ZetaSlider,'Value');          % ��������� �������� �������� �����
Filters(Current).Eta = get(menu_handles.EtaSlider,'Value');          % ��������� �������� �������� ���
Filters(Current).Theta = get(menu_handles.TetaSlider,'Value');          % ��������� �������� �������� ����

Filters(Current).mask = get(menu_handles.MaskTable,'Data');            % �������� �����
Filters(Current).mask1 = get(menu_handles.MaskTable1,'Data');            % �������� �����1

F(Current,1) = Filters(Current).FilterType;           % ��������� ��� ������� (1 �������)
F(Current,2) = 2*Filters(Current).FPM1 + 1;       % � ������ �����  (2 �������)
F(Current,10) = Filters(Current).FPM2;          % ��������� �������� ������� ����
F(Current,4) = Filters(Current).FPM3;          % ��������� ������� (4 �������)

F(Current,3) = Filters(Current).Alpha;          % ��������� �������� ����� (3 �������)
F(Current,5) = Filters(Current).Indent;           % ��������� �������� ���� ��������� �����
F(Current,6) = Filters(Current).Beta;           % ��������� �������� ���� (6 �������)
F(Current,7) = Filters(Current).Gamma;          % ��������� �������� �������� �����
F(Current,8) = Filters(Current).Delta;           % ��������� �������� ������
F(Current,9) = Filters(Current).Epsilon;          % ��������� �������� �������� �������
F(Current,11) = Filters(Current).Zeta;          % ��������� �������� �������� �����
F(Current,12) = Filters(Current).Eta;          % ��������� �������� �������� ���
F(Current,13) = Filters(Current).Theta;          % ��������� �������� �������� ����

if size(F,1) > 1
    set(menu_handles.DeleteSlider,'Enable','on');
    set(menu_handles.DeleteSlider,  'Max',size(F,1),...
        'SliderStep',[1/(size(F,1)-1) 1/(size(F,1)-1)]);
end

% ��������� ������ "���������-���������"
                            
NoiseType = get(menu_handles.NoiseType,'String');        % ��������� ������ �����
FilterType = get(menu_handles.FilterType,'String');      % ��������� ������ ��������
IndentStr = {'����������','����','��������','�����'};    % ������ ��������� ����� �����������


% �������� ����������� � ���������� ������

Parametrs(Current) = strcat(num2str(Current),{')'});    % ����������� � ������ ���������� �����

if Noises(Current,4) == 1                       % ���� ����� � ����������� ����� - �����������    
    Parametrs(Current) = strcat(Parametrs(Current),' ���������� ������������ �����������',[' ' char(8594)]);
end

Parametrs(Current) = strcat(Parametrs(Current),{' '},NoiseType(Noises(Current,1)));      % ��������� ����������� ������ ��� ���������

switch Noises(Current,1)     % ���� ���:
    case 1             % ��� ��������� - ������ �� ���������
        
    case 2              % ����������
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' char(963) ' = ' num2str(Noises(Current,2))],[', ' char(956) ' = ' num2str(Noises(Current,3))]);
    case 3              % ����������������
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' char(955) ' = ' num2str(Noises(Current,2))]);
    case 4              % �������
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' char(945) ' = ' num2str(Noises(Current,2))],[', ' char(956) ' = ' num2str(Noises(Current,3))]);
    case 5              % �����
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' char(963) ' = ' num2str(Noises(Current,2))]);
    case 6              % �����
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' char(963) char(178) ' = ' num2str(Noises(Current,2))]);
    case 7              % ����-�����
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' num2str(Noises(Current,2)) ' %']);
    case 8              % ����
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' num2str(Noises(Current,2)) ' %']);
    case 9              % �����
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' num2str(Noises(Current,2)) ' %']);
    case 10             % �������� ���
        Parametrs(Current) = strcat(Parametrs(Current),[', ����.: ' num2str(Noises(Current,2))],...
            [', ����.: ' num2str(Noises(Current,3)) char(186) ' ']);
    case 11              % �����������
        Parametrs(Current) = strcat(Parametrs(Current),[' A = ' num2str(Noises(Current,2))],...
            [', B = ' num2str(Noises(Current,3))]);
    case 12             % ��� �������� - ������ �� ���������
        
end

%%%%%
% ������ ������
% �������, ������� ����� ���������� ������
IndentNeeded = [2 6 8 11 13 14 19:27];
%%%%%%%%

if any(IndentNeeded == F(Current,1))    % ����������� ������� ��������� �����
    Parametrs(Current) = strcat(Parametrs(Current),[' ' char(8594) ' [' IndentStr{F(Current,5)} ']']);
end

s = char(FilterType(F(Current,1)));             % �������, ����� ������ � ���� ��������� �������

Parametrs(Current) = strcat(Parametrs(Current),[' ' char(8594)],[' ' s]);         % ������ ��������� ������ � ����������

% ��������� ��� �����
if F(Current,1) ~= 4 && F(Current,10) ~= 11     % ��� ���� �����/������� �� �������
    
    filtmask = get(menu_handles.MaskTable,'Data');  % ������� �����
    c = zeros(1,size(filtmask,1));                      % ���� ������� 10���� ���
    
    for x = 1:size(filtmask,1)          % ��� ������ ������
        a = num2str(filtmask(x,:));     % ��������� ��
        c(x) = bin2dec(a) + 500;        % ��������� � 10�� � �������� � ��������� ���������
    end
    
    % ������� � �����
    hash = [': %%' char(c) '%%'];
end

% ������ ����� � �� ���
mask = [' ' num2str(F(Current,2)) 'x' num2str(F(Current,2))];                  

switch F(Current,1)     % ���� ������
    
    case 1              % ��� ���������
        
    case 2              % ���������
        
        switch F(Current,10)          % ����� ��� ���������� ������� ������
            case 1
                type = '������������';
                Ord = '';
            case 2
                type = '���. ��������';
                Ord = '';
            case 3
                type = '����������';
                Ord = '';
            case 4
                type = 'N-������';
                if F(Current,4) == 4
                    Ord = [', ������� �������: ' char(8734)];
                else
                    Ord = [', ������� �������: ' num2str(F(Current,4))];
                end
                
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),[' (' type '),' mask hash Ord]);
        
    case 3              % �����������
        
        switch F(Current,10)          % ����� ��� ������
            case 1
                type = [' (� ���������� �������: ' num2str(F(Current,3)) ')'];
            case 2
                type = ' (���)';
            case 3
                type = [' (������-����: k = ' num2str(F(Current,6)) '),' mask ', ����.'];
            case 4
                type = [' (�������: k = ' num2str(F(Current,6)) '),' mask ', ����.'];
            case 5
                type = [' (���������: k = ' num2str(F(Current,6)) '),' mask ', ����.'];
            case 6
                type = [' (��������),' mask ', ����.'];
            case 7
                type = [' (�������: k = ' num2str(F(Current,6)) ', R = ' num2str(F(Current,7)) '),' mask ', ����.'];
            case 8
                 type = [' (� ���������� �������: �������� '...
                     num2str(F(Current,8)) 'x' num2str(F(Current,12)) ' � ������� ' num2str(F(Current,3)) ')'];
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type);
        
    case 4              % ��������������� ���������
        
        if F(Current,10) < 6           % ��� ���������...���� �������� �����
            switch F(Current,4)
                case 1
                    subtype = [' ���� (R = ' num2str(F(Current,6)) '),'];
                case 2
                    subtype = [' ���� (R = ' num2str(F(Current,6)) '),'];
                case 3
                    subtype = [' ����� (�����: ' num2str(F(Current,6)) ', ����. ' num2str(F(Current,7)) ' ��.),'];
                case 4
                    subtype = [' �������������� (R = ' num2str(F(Current,6)) '),'];
                case 5
                    subtype = [' ���� ����� (���./�����. ����� = ' num2str(F(Current,6)) '/' num2str(F(Current,7)) '),'];
                case 6
                    subtype = [' ������������� (' num2str(F(Current,6)) 'x' num2str(F(Current,7)) '),'];
                case 7
                    subtype = [' ���������������� �����,' num2str(F(Current,6)) 'x' num2str(F(Current,6)) hash];
            end
        elseif F(Current,10) > 6 && F(Current,10) < 10  % ��� ������������� � �.�.
            
            if F(Current,4) == 1
                subtype = '4-����.,';
            else
                subtype = '8-����.,';
            end
            
        elseif F(Current,10) == 10      % �������� ������
            
            switch F(Current,4)
                case 1
                    subtype = ' (��������� (4-�������)),';
                case 2
                    subtype = ' (��������� (8-�������)),';
                case 3
                    subtype = ' (��������� ������� (4-�������)),';
                case 4
                    subtype = ' (��������� ������� (8-�������)),';
                case 5
                    subtype = ' (��������� ����� (4-�������)),';
                case 6
                    subtype = ' (��������� ����� (8-�������)),';
                case 7
                    subtype = ' (�����-��������� (4-�������)),';
                case 8
                    subtype = ' (�����-��������� (8-�������)),';
            end            
            
        elseif F(Current,10) == 11
            subtype = [' ���������������� �����, ' num2str(1+2*F(Current,7)) 'x' num2str(1+2*F(Current,7)) ','];
            
            
        else    % ���� ��������� �� ����� ���. ���������
            subtype = '';
            
        end
        
        switch F(Current,10)
            case 1
                type = ' ���������:';
            case 2
                type = ' ������:';
            case 3
                type = ' ����������:';
            case 4
                type = ' ���������:';
            case 5
                type = ' ��� �����: ';
            case 6
                type = ' ���� �����: ';
            case 7
                type = ' ���������� ���������: ';
            case 8
                type = ' ������� ������: ';
            case 9
                type = ' ��������� ���������: ';
            case 10
                type = ' ��������������������� ������: ';
            case 11
                type = ' �����/�������: ';
            case 12
                type = ' ����������: ';
            case 13
                type = ' ������� ������������� ��������: ';
            case 14
                type = ' ������������ ����������: ';
            case 15
                type = ' �-���������: ';
            case 16
                type = ' �� ���� �� �������� ����: ';
            case 17
                type = ' �������� ���������� ��������: ';
            case 18
                type = ' ������ �� �����/������: ';
            case 19
                type = ' �����: ';
            case 20
                type = ' �������� ���������: ';
            case 21
                type = ' ���������: ';
            case 22
                type = ' ���������: ';
        end
        
        if F(Current,8) == 0
            it_num = ' �� ������������';
        else
            it_num = num2str(F(Current,8));
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),':',type,subtype,' ���-�� ��������:',it_num);
        
    case 5              % ����������� ����������
        
        switch F(Current,10)
            case {1,2,3,4,5,6}
                subtype = ' ���������������� �����,';
                
            case 7
                subtype = '';
                
            case {8,9,15,16}
                
                switch size(Original,3)
                    case 1
                        conn = {'4','8'};
                    case 3
                        conn = {'6','18','26'};
                    otherwise
                        conn = {'�����������','������������'};
                end
                
                subtype = [' ���-�� ������: ' conn{F(Current,4)} ','];
                
            case 10
                switch size(Original,3)
                    case 1
                        conn = {'��������� (4-��.)',...
                            '��������� (8-��.)',...
                            '��������� ������� (4-��.)',...
                            '��������� ������� (8-��.)',...
                            '��������� ����� (4-��.)',...
                            '��������� ����� (8-��.)',...
                            '�����-��������� (4-��.)',...
                            '�����-��������� (8-��.)'};
                    case 3
                        conn = {'��������� (6-��.)',...
                            '��������� (18-��.)',...
                            '��������� (26-��.)',...
                            '��������� ������� (6-��.)',...
                            '��������� ������� (18-��.)',...
                            '��������� ������� (26-��.)',...
                            '��������� ����� (6-��.)',...
                            '��������� ����� (18-��.)',...
                            '��������� ����� (26-��.)',...
                            '�����-��������� (6-��.)',...
                            '�����-��������� (18-��.)',...
                            '�����-��������� (26-��.)'};
                    otherwise
                        conn = {'��������� (���-��.)',...
                            '��������� (����-��.)',...
                            '��������� ������� (���-��.)',...
                            '��������� ������� (����-��.)',...
                            '��������� ����� (���-��.)',...
                            '��������� ����� (����-��.)',...
                            '�����-��������� (���-��.)',...
                            '�����-��������� (����-��.)'};
                end
                
                subtype = [' ' conn{F(Current,4)}];
                
            case {11,12,13,14}
                
                switch size(Original,3)
                    case 1
                        conn = {'4','8'};
                    case 3
                        conn = {'6','18','26'};
                    otherwise
                        conn = {'�����������','������������'};
                end
                
                subtype = [' ���-�� ������: ' conn{F(Current,4)} ', H = ' num2str(F(Current,3)) ','];
        end
        
        
        switch F(Current,10)
            case 1
                type = '���������:';
            case 2
                type = '������:';
            case 3
                type = '����������:';
            case 4
                type = '���������:';
            case 5
                type = '��� �����: ';
            case 6
                type = '���� �����: ';
            case 7
                type = '���������� ���������: ';
            case 8
                type = '������� ������: ';
            case 9
                type = '��������� ���������: ';
            case 10
                type = '�������� ������: ';
            case 11
                type = '����������� �������: ';
            case 12
                type = '����������� ��������: ';
            case 13
                type = '�-��������: ';
            case 14
                type = '�-��������: ';
            case 15
                type = '��������� �������: ';
            case 16
                type = '��������� ��������: ';
        end
        
        if F(Current,8) == 0
            it_num = ' �� ������������';
        else
            it_num = num2str(F(Current,8));
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),' (',type,subtype,' ���-�� ��������:',{' '},it_num,')');
        
    case 6              % �������������
        
        switch F(Current,10)          % ����� ������ ������� ������
            case 1
                type = '��������';
                Ord = '';
            case 2
                type = '�������';
                Ord = '';
            case 3
                type = '��. ��������������';
                Ord = '';
            case 4
                type = '���. ��������';
                Ord = '';
            case 5
                type = '���������� �������';
                Ord = '';
            case 6
                type = 'N-������ �������';
                if F(Current,4) == 4
                    Ord = ['������� �������: ' char(8734) ', '];
                else
                    Ord = ['������� �������: ' num2str(F(Current,4)) ', '];
                end
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),[' (' type '), ' mask ', ' Ord char(945) ' = ' num2str(F(Current,3))...
            ', ' char(946) ' = ' num2str(F(Current,6))]);
        
        
        
    case 7              % ������ ��������� �������
        switch F(Current,10)          % ����� ��� ������
            case 1
                type = ' (��� ������� "������"), ';
            case 2
                type = ' (������� "������"),';
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type,...
            [' ����������� PSF: ' num2str(F(Current,3)) 'x' num2str(F(Current,6)) ', ����� ��������: ' num2str(F(Current,7)) ', ����� ����������: ' num2str(F(Current,8))]);
        
    case 8              % ������ ������
        
        type = [[' ' char(963) '_x = '] num2str(F(Current,3)) [', ' char(963) '_y = '] num2str(F(Current,6))...
            ', ' char(955) ' = ' num2str(F(Current,7)) ', ' char(968) ' = '  num2str(F(Current,8)) char(186) ...
            ', ' char(952) ' = '  num2str(F(Current,9)) char(186)];
        Parametrs(Current) = strcat(Parametrs(Current),',',type, ', ', mask);
        
    case 9              % ������������� ����
        
        str2 = get(menu_handles.FiltParMenu2,'String');
        str3 = get(menu_handles.FiltParMenu3,'String');
        
        theta = str2(F(Current,10));
        thresh = str3(F(Current,4));
        
        Filters(Current).FPM2 = str2double(theta);
        Filters(Current).FPM3 = str2double(thresh);
        
        Parametrs(Current) = strcat(Parametrs(Current),...
            [char('(',920,' ','=',' ')' num2str(F(Current,3)) ':' char(theta) ':' num2str(F(Current,6))...
             char(186,',',916,961,' ','=',' ')' num2str(F(Current,7)) '); ����� �����: ' num2str(F(Current,13))],...
            [', ����� ����: ' char(thresh) '% �� max, ������ ����� ����������: ' num2str(F(Current,8)) 'x' num2str(F(Current,12)) ','],...
            [' min ����� �����: ' num2str(F(Current,9)) ' � �������� �� ' num2str(F(Current,11)) ' ����.']);
        
    case 10             % ���������������� ����������
        
        switch F(Current,10)          % ����� ��� ������
            case 1
                type = ', ��� ����������������';
            case 2
                type = [', ����������������: ' num2str(F(Current,9)) ' | ' num2str(F(Current,11))];
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),...
            [' (' num2str(F(Current,3)) ':' num2str(F(Current,6)) ';' num2str(F(Current,7)) ':' num2str(F(Current,8)) ')'],type);
        
    case 11             %  ������������ ������
        
        switch F(Current,10)          % ����� ��� ������
            case 1
                type = ', ��� ���������';
            case 2
                type = ', � ����������';
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type, ', ', mask,hash);
        
    case 12         % ������ �������
        
        Parametrs(Current) = strcat(Parametrs(Current),[', ' num2str(F(Current,3)) 'x' num2str(F(Current,6))]);
        
    case {13,22}  % �����������
        
        Parametrs(Current) = strcat(Parametrs(Current),[', ' mask hash ', ��� = ' num2str(F(Current,3))]);
        
    case 14         % ����������� ������
        
        switch F(Current,10)          % ����� ��� ������
            case 1
                type = ' (������� ��������������';
            case 2
                type = ' (������� ��������������';
            case 3
                type = ' (������������� �������';
            case 4
                type = [' (������������������ �������, �������: ' num2str(F(Current,3))];
            case 5
                type = ' (��������';
            case 6
                type = ' (�������';
            case 7
                type = ' (������� �����';
            case 8
                type = [' (������� ���������, ����� ��������� ���������: ' num2str(F(Current,3))];
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type,['), ' mask]);
        
    case 15       % ������ ������
        
        switch F(Current,4)
            case 1
                dir = '�����. (���������)';
            case 2
                dir = '�����. (��� ���������)';
            case 3
                dir = '����. (���������)';
            case 4
                dir = '����. (��� ���������)';
            case 5
                dir = '���. (���������)';
            case  6
                dir = '���. (��� ���������)';
        end
        
        if F(Current,3) == 0
            Parametrs(Current) = strcat(Parametrs(Current),[', �����: ����, ' dir]);
        else
            Parametrs(Current) = strcat(Parametrs(Current),[', �����: ' num2str(F(Current,3)) ', ' dir]);
        end
        
    case 16       % ������ �����
        
        if F(Current,6) == 256 || F(Current,3) == -1
            Parametrs(Current) = strcat(Parametrs(Current),',',' ���� | ����',[', ��� = ' num2str(F(Current,7))]);
        else
            Parametrs(Current) = strcat(Parametrs(Current),[', ' num2str(F(Current,3)) ' | ' num2str(F(Current,6)) ', ��� = ' num2str(F(Current,7))]);
        end
        
    case 17         % ������ ��������
        
        if F(Current,4)== 1
            dir = '�����.';
        elseif F(Current,4)== 2
            dir = '����.';
        elseif F(Current,4)== 3
            dir = '���';
        end
        
        if F(Current,3) == 0
            Parametrs(Current) = strcat(Parametrs(Current),[', �����: ����, ' dir]);
        else
            Parametrs(Current) = strcat(Parametrs(Current),[', �����: ' num2str(F(Current,3)) ', ' dir]);
        end
        
    case 18       % ������ ��������
        
        if F(Current,4)== 1
            dir = '���������';
        elseif F(Current,4)== 2
            dir = '��� ���������';
        end
        
        if F(Current,3) == 0
            Parametrs(Current) = strcat(Parametrs(Current),[', �����: ����, ' dir]);
        else
            Parametrs(Current) = strcat(Parametrs(Current),[', �����: ' num2str(F(Current,3)) ', ' dir]);
        end
        
    case 19     % �������� ������
        Parametrs(Current) = strcat(Parametrs(Current),[', ' mask]);
        
    case 20         % ������� ���
        
        Parametrs(Current) = strcat(Parametrs(Current),[', ��� = ' num2str(F(Current,3))]);
        
    case 21  % �����������
        
        Parametrs(Current) = strcat(Parametrs(Current),[', ' mask ', a = ' num2str(F(Current,3))]);
        
    case 23  % ���������� ���������
        
        Parametrs(Current) = strcat(Parametrs(Current),[', ��' mask ' �� ' num2str(F(Current,3)) 'x' num2str(F(Current,3))]);
        
    case 24     % �����-������
        
        type = [',' mask ', ' ...
                '����� ������� = ' num2str(F(Current,3))];
        
        Parametrs(Current) = strcat(Parametrs(Current),type);
        
    case 25     % ������� ��
        
        switch Filters(Current).FPM2
            
            case 1      % ������������ ������
                
                switch Filters(Current).FPM3
                    
                    case 1      % ���������� ������
                        
                        type = [' (������������, ���������� ������ ������): '...
                                mask ', ' ...
                                char(963) char(178) ' = ' num2str(F(Current,3)) ', '...
                                char(956) ' = ' num2str(F(Current,6))];
                        
                    case 2      % ����������������� ������
                        
                        type = [' (������������, ����������������� ������ ������): '...
                                mask ', ' ...
                                char(963) char(178) ' = ' num2str(F(Current,7)) ', '...
                                char(956) ' = ' num2str(F(Current,8)) ', '...
                                '����� ������� = ' num2str(F(Current,9))];
                        
                    case 3      % ���. + �������.                        
                        
                        type = [' (������������, ���.+�����. ������ ������): '...
                                mask ', ' ...
                                char(963) char(178) ' ���.����� = ' num2str(F(Current,3)) ', '...
                                char(956) ' ���.����� = ' num2str(F(Current,6)) ', ' ...
                                char(963) char(178) ' �����.����� = ' num2str(F(Current,7)) ', '...
                                char(956) ' �����.����� = ' num2str(F(Current,8)) ', '...
                                '����� ������� = ' num2str(F(Current,9))];
                end
                
            case 2      % ���������� ������
                
                type = [' (����������): ' ...
                        mask ', ' ...
                        '�����. ��������� = ' num2str(F(Current,11)) ', '...
                        '����� ������� = ' num2str(F(Current,9))];
                
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type);
        
    case 26     % ������ ������
        switch Filters(Current).FPM2
            
            case 1      % ������������ ������
                
                type = [' (������������): ' ...
                        mask ', ' ...
                        '�����. ��������� = ' num2str(F(Current,3))];
                
            case 2      % ���������� ������
                
                type = [' (����������): ' ...
                        mask ', ' ...
                        '�����. ��������� = ' num2str(F(Current,3)) ', '...
                        '����� ������� = ' num2str(F(Current,6))];
                
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type);
        
    case 27     % ������ �����
        
        type = [',' mask ', ' ...
                '����� ������� = ' num2str(F(Current,3))];
        
        Parametrs(Current) = strcat(Parametrs(Current),type);        
        
    case 28     % ������ ��������� ���������
        
        switch F(Current,10)
            case 1
                type = ' (����������),';
            case 2
                type = ' (�����������),';                
            case 3
                type = ' (���),';                
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type,mask); 
        
    case 29     % ��������� ���������
        
        if F(Current,4) == 1
            type = [' (����������� -> ' num2str(F(Current,3)) '):'];
        elseif F(Current,4) == 2
            type = [' (���������� -> ' num2str(F(Current,3)) '):'];
        end
        
        if F(Current,10 )== 1
            RGBHSV = ' RGB';
        elseif F(Current,10) == 2
            RGBHSV = ' HSV';
        end
        
        range = [', ' num2str(F(Current,8)) ' ' char(8804) ' I ' char(8804) ' ' num2str(F(Current,12))];
        
        Parametrs(Current) = strcat(Parametrs(Current),type,RGBHSV,[', ����� � ' num2str(F(Current,6))],range);
        
    case 30     % ��������        
        
        switch F(Current,10)
            case 1
                type = '��������� ���������';
            case 2
                type = '����������� ���������';                
            case 3
                type = '������������ �������� �� ��';                     
            case 4
                type = '������������ �������� �� �y';               
        end
        
        switch F(Current,4)
            case 1
                method = ' ������';
            case 2
                method = ' ��������';          
            case 3
                method = ' ����������� ��������';                
            case 4
                method = ' ������� ��������';           
            case 5
                method = ' ��������';                
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),' (',type,method,')');        
        
    case 31     % �����������
        
        if F(Current,4)== 1
            typ = '�������� ������������: RGB';
        elseif F(Current,4)== 2
            typ = '�������� ������������: HSV';
        end
        Parametrs(Current) = strcat(Parametrs(Current),[' (' num2str(typ) '), ' '����� �������: ' num2str(F(Current,3))]);
        
    case 32     % �����������
        
       Parametrs(Current) = strcat(Parametrs(Current),[': ���/�������: ' num2str(F(Current,3)) ', k = ' num2str(F(Current,6))]);
        
    case 33     % ���������������� � �����-����������
        
        Parametrs(Current) = strcat(Parametrs(Current),...
            [', ' char(947) ' = ' num2str(F(Current,3)) ' (' num2str(F(Current,6)) ' | ' num2str(F(Current,7)) ' :: ' num2str(F(Current,8)) ' | ' num2str(F(Current,9)) ')']);
    
    case 34     % �������� �����������
        
        if F(Current,10) == 1
            type = ['(����): ������-��: ' num2str(F(Current,6)) ','];
        elseif F(Current,10) == 2
            type = '(�������� � ���������):';            
        end
        
        if F(Current,4) == 1
            targets = ' ���� ������ ����,';
        elseif F(Current,4) == 2
            targets = ' ���� ������� ����,';            
        end        
        
        Parametrs(Current) = strcat(Parametrs(Current),...
            [type targets ' �����: ' num2str(F(Current,7)) ', '...
            num2str(F(Current,8)) char(8804) 'R' char(8804) num2str(F(Current,12))]);
        
    case 35     % �������� �������� �����
        
        switch F(Current,10)    
            case 1      % BRISK
                Parametrs(Current) = strcat(Parametrs(Current),...
                    [' (BRISK), ���. ��������: ' num2str(F(Current,3))...
                    ', ���. ��������: ' num2str(F(Current,6)) ...
                    ', ����� �����: ' num2str(F(Current,8))]);
                
            case 2      % FAST
                Parametrs(Current) = strcat(Parametrs(Current),...  
                    [' (����� FAST), ���. ��������: ' num2str(F(Current,3))...
                    ', ���. ��������: ' num2str(F(Current,6))]);     
            
            case 3      % HARRIS
                Parametrs(Current) = strcat(Parametrs(Current),...
                    [' (����� �������), ���. ��������: ' num2str(F(Current,3))...
                    ', ������ ����: ' num2str(F(Current,7)) 'x' num2str(F(Current,7))]);    
            
            case 4      % MinEagenVals
                Parametrs(Current) = strcat(Parametrs(Current),... 
                    [' (����� (���. �����. ����.)), ���. ��������: ' num2str(F(Current,3))...
                    ', ������ ����: ' num2str(F(Current,7)) 'x' num2str(F(Current,7))]);
            
            case 5      % SURF
               Parametrs(Current) = strcat(Parametrs(Current),... 
                    [' (SURF), �����: ' num2str(F(Current,11))...
                    ', ����� ������� �������: ' num2str(F(Current,9)) ...
                    ', ����� �����: ' num2str(F(Current,8))]);
        end
        
end

set(menu_handles.UsePreviousFiltImage,'Enable','on');   % ������������ �������
set(menu_handles.NoiseFilterString,'String',Parametrs,'FontSize',10); 


% ������ "������� �������"
function DeleteButton_Callback(~, ~, menu_handles)

global Noises;              % ������ ���������� ����������
global Filters;             % ������ ���������� ����������
global Parametrs;           % ��������� ������������ 

Nums2del = get(menu_handles.DeleteSlider,'Value');    % ��������� ����� ������� ��� ��������

% ���������� �������� ��������� �� ����������� ����������� ��������
if Nums2del(1) ~= size(Noises,1)              % ���� ������ �� ��������� ����� ������
    for x = Nums2del(1)+1:size(Noises,1)      % ������� �� ����������, ���������
        
        if Noises(x,4) == 1           % ���� �� ������� �� �����������
            Nums2del(end+1) = x;             %#ok<AGROW>
        else
            break;                  % ����� ������� ������
        end
    end
end

Noises(Nums2del,:) = [];          % ������� ������� �� ���� ��������
Filters(Nums2del) = [];      
Parametrs(Nums2del) = [];

for i = Nums2del(1) : size(Noises,1)    % �� ���� ��������� ������� �������� ���������� �����
    Parametrs(i) = regexprep(Parametrs(i),num2str(i + size(Nums2del,2) ),num2str(i),'once');
end


if isempty(Noises)                              % ���� ������ ���� ������
    
    set(menu_handles.DeleteSlider,'Value',1);        % ������ �������� ��������
    set(menu_handles.DeleteNumber,'String','1');     % ������ ����� �������
    set(menu_handles.NoiseFilterString,'Value',1,'String','');
    set([   menu_handles.DeleteSlider;...
            menu_handles.DeleteNumber;...
            menu_handles.DeleteButton;...
            menu_handles.UsePreviousFiltImage;...
            menu_handles.ApplyButton],...            
            'Enable','off');
        
elseif size(Noises,1) == 1          % ���� �������� ������ ���� ������
    
    set(menu_handles.NoiseFilterString,'Value',1);
    set(menu_handles.DeleteSlider,'Value',1);        % ������ �������� ��������
    set(menu_handles.DeleteNumber,'String','1');     % ������ ����� �������
    set([   menu_handles.DeleteSlider;...
            menu_handles.DeleteNumber],...            
            'Enable','off');
        
    set(menu_handles.NoiseFilterString,'String',Parametrs);
    
else
    
    if Nums2del(1) == 1              % ���������� ����� �������� ���������� ������ � ������
        ListNewPos = 1;
        
    elseif Nums2del(1) > size(Noises,1)
        ListNewPos = size(Noises,1);
        
    else
        ListNewPos = Nums2del(1);
    end
    
    set(menu_handles.NoiseFilterString,'Value',ListNewPos);
    set(menu_handles.DeleteNumber,'String',num2str(ListNewPos));
    set(menu_handles.DeleteSlider,  'Value',ListNewPos,...
                                    'Max',size(Noises,1),...
                                    'SliderStep',[1/(size(Noises,1)-1) 1/(size(Noises,1)-1)]);
                                
    set(menu_handles.NoiseFilterString,'String',Parametrs);
end


% ������ "������"
function CancelButton_Callback(~, ~, menu_handles)

global Noises;              % ������ ���������� ����������
global Filters;             % ������ ���������� ����������

Noises(:,:) = [];       % ��� �������� ��������
Filters(:,:) = [];
delete(menu_handles.menu);


% ������ "EXP(ALPHA)"
function FiltParButton1_Callback(~, ~, menu_handles)

scr_res = get(0, 'ScreenSize');
alpha = get(menu_handles.AlphaSlider,'Value');

switch get(menu_handles.FilterType,'Value') 
    
    case 5                      % ����������� ����������
        
        Data = get(menu_handles.MaskTable1,'Data');      % ������� �������������
        beta = get(menu_handles.BetaSlider,'Value');     % ������� ������
        gamma = get(menu_handles.GammaSlider,'Value');  % ������� �������
        
        Data(beta,gamma) = alpha;                       % ��������
        set(menu_handles.MaskTable1,'Data',Data);        % �������� �����
        return;
        
    case 6                     % ������������� ������

        x = 0:255;
        graph = exp(-alpha*(abs(x)));
        GraphTitle = { '����������� ������������ ������� �� ������ �������� ������� ��������';...
                'K(\DeltaI) = exp(-\alpha|\DeltaI|),';...
                ['��� \alpha = ' num2str(alpha)]};     
            
    case 8                  % ������ ������
        
        X = 2*get(menu_handles.FiltParMenu1,'Value')+1;
        sigma_x = get(menu_handles.AlphaSlider,'Value');
        sigma_y = get(menu_handles.BetaSlider,'Value');
        lambda = get(menu_handles.GammaSlider,'Value');
        psi = get(menu_handles.DeltaSlider,'Value');
        theta = get(menu_handles.EpsilonSlider,'Value');        
        
        [x,y] = meshgrid(-fix(X/2):fix(X/2),-fix(X/2):fix(X/2));
        
        % �������
        x_theta = x*cos(theta) + y*sin(theta);
        y_theta = -x*sin(theta) + y*cos(theta);
        
        graph = exp(-0.5*(x_theta.^2/sigma_x^2 + y_theta.^2/sigma_y^2))* cos(2*pi*x_theta./lambda + psi);        
        
        figure('Color',[1 1 1],'Position',[(scr_res(3)-800)/2 (scr_res(4)-600)/2 800 600],'NumberTitle','off');
        surf(graph);
        GraphTitle = {'����� ������� ������';...
                        ['\sigma_x = ' num2str(sigma_x) ', \sigma_y = ' num2str(sigma_y)...
                        ', \lambda = ' num2str(lambda) ', \theta = '  num2str(theta) ', \psi = '  num2str(psi)]};
        title(GraphTitle,'FontName','Times New Roman');
        set(gca,'FontSize',12);
        set(gca,'XTick',1:2:X,'XLim',[1 X],'YTick',1:2:X,'YLim',[1 X]);
        
        return;
        
            
    case 11             % ������������ ������
        
        Data = get(menu_handles.MaskTable,'Data');      % ������� �������������
        beta = get(menu_handles.BetaSlider,'Value');     % ������� ������
        gamma = get(menu_handles.GammaSlider,'Value');  % ������� �������
        
        Data(beta,gamma) = alpha;                       % ��������
        set(menu_handles.MaskTable,'Data',Data);        % �������� �����
        return;
        
    case 33                     % ���������������� � �����-����������
        
        x = 0:0.0001:1;
        graph = 255*(x.^alpha);
        x = x*255;
        GraphTitle = { '������ �����-���������';...
                ['I(���) = I(��)^{\gamma}, ��� \gamma = ' num2str(alpha)]};
        

end

figure('Color',[1 1 1],'Position',[(scr_res(3)-800)/2 (scr_res(4)-600)/2 800 600],'NumberTitle','off'); 
plot(x,graph,'LineWidth',3);
title(GraphTitle,'FontName','Times New Roman');
set(gca,'XTick',0:20:260,'XLim',[0 260]);   
set(gca,'FontSize',12);


% ������ "EXP(BETA)"
function FiltParButton2_Callback(~, ~, menu_handles)

scr_res = get(0, 'ScreenSize');
beta = get(menu_handles.BetaSlider,'Value');
gamma = get(menu_handles.GammaSlider,'Value');

switch get(menu_handles.FilterType,'Value') 
    
    case 4              % ��������������� ���������
        
        switch get(menu_handles.FiltParMenu2,'Value')
            
            case {1,2,3,4,5,6}      % ��������� ...�����
                
                switch get(menu_handles.FiltParMenu3,'Value')
                    
                    case 1          % ����             
                        structure = strel('diamond',beta);
                    case 2          % ����
                        structure = strel('disk',beta);
                    case 3          % �����
                        structure = strel('line',beta,gamma);
                    case 4          % ��������������
                        structure = strel('octagon',beta);
                    case 5          % ���� �����
                        structure = strel('pair',[beta gamma]);
                    case 6          % �������������
                        structure = strel('rectangle',[beta gamma]);
                end
                
                object = getnhood(structure);
                
                try
                    imtool(object);
                catch
                    OpenImageOutside(object);
                end
                
                return;
                
            case 11     % �����/�������
        
                Data = get(menu_handles.MaskTable,'Data');      % ������� �������������
                epsilon = get(menu_handles.EpsilonSlider,'Value');     % ������� ������
                zeta = get(menu_handles.ZetaSlider,'Value');  % ������� �������
                
                Data(epsilon,zeta) = beta;                       % ��������
                set(menu_handles.MaskTable,'Data',Data);        % �������� �����
                return;
        end
        
    case 5      % ����������� ����������
        
        Data = menu_handles.MaskTable1.Data;
        LogicData = menu_handles.MaskTable.Data;        
        object = Data.*LogicData/255;        
        
        try
            imtool(object);
        catch
            OpenImageOutside(object);
        end
        
        return;
        
    case 6                     % ������������� �������
        
        xmax = 2*get(menu_handles.FiltParMenu1,'Value');        
        x = 0:0.1:xmax;
        graph = exp(-beta*(x));        
        Xlimits = 0:1:xmax;
        GraphTitle = {'����������� ������������ ������� �� ����� ������� �������� �������� ��������';...
            'K(i,j) = exp(-\beta(|i-i_{0}|+|j-j_{0}|)),';...
            ['��� \beta = ' num2str(beta)]};
        Ylimits = inf;
        
    case 32             % �����������
        
        x = 0:0.001:1;
        graph = (2^get(menu_handles.AlphaSlider,'Value')-1)*(x.^beta);
        x = x*255;
        GraphTitle = {  '�������������� �����������';
                        ['I(���) = I(��)^{k}, ��� k = ' num2str(beta)]}; 
        Xlimits = 0:30:270;
        if get(menu_handles.AlphaSlider,'Value') < 6
            Ylimits = [0 1 3 7 15 31];
        else
            Ylimits = [0 3 7 15 31 63 127]; % ��� ������ ��������� � 4 � 0, �������
        end
end

figure('Color',[1 1 1],'Position',[(scr_res(3)-800)/2 (scr_res(4)-600)/2 800 600],'NumberTitle','off'); 
plot(x,graph,'LineWidth',3);
title(GraphTitle,'FontName','Times New Roman');
if Ylimits ~= inf
    set(gca,'XTick',Xlimits,'YTick',Ylimits);
else
    set(gca,'XTick',Xlimits);
end
set(gca,'FontSize',10); 

if get(menu_handles.FilterType,'Value') == 31       % ��� ����������� �������� ������ �����������
    hold(gca,'on');
    y = 1;
    pre_z = 1;
    
    for z = 1:size(x,2) 
        if graph(z) > y            
            plot([x(1,pre_z) x(1,z)],[y y],'Color','r');
            plot([x(1,z) x(1,z)],[0 y+1],'Color','r','LineStyle','--');
            pre_z = z;
            y = y + 1;
        end
    end
    plot([x(1,pre_z) x(1,z)],[y y],'Color','r');
    plot([x(1,z) x(1,z)],[0 y],'Color','r','LineStyle','--');
        
end


% ������ "���������"
function ApplyButton_Callback(hObject, eventdata, menu_handles, handles)

global Original;            % �������� �����������
global Noised;              % ����������� �������
global Filtered;            % ��������������� �����������
global Noises;              % ������ ���������� ����������
global Filters;             % ������ ���������� ����������
global Parametrs;           % ��������� ������������ (���� � �������)
global Assessment_N;        % ������ ������ ���������� �����������
global Assessment_F;        % ������ ������ ������������ �����������
global FilteredAsOriginal;    % ����������, ������� ����������, ��� ���������
global ContinueProcessing;  % ��� ���������� ����, ��� ����� ���������� ���������, �� ������ ��������� ����������


if ContinueProcessing          % ���� ���������� ���������, �� ��������� � ����� �������
    start = size(Noised,4) + 1; 
else
    start = 1;
end

% ��������� �������, ����� �� ������� ������ ������ � ������ ������
Temp_Filtered = zeros(size(Original,1),size(Original,2),size(Original,3),size(Noises,1),'uint8');
Temp_Noised = zeros(size(Original,1),size(Original,2),size(Original,3),size(Noises,1),'uint8');
str = cell(size(Noises,1),1);

%%%%%%%%%%%%%%%%%  ���������� ���������� � ���������� %%%%%%%%%%%%%%%%%%%%%
set(gcf,'Visible','off');
Wait = waitbar(0,'��������� ����������� � 1',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(Wait,'canceling',0);
Wait.WindowStyle = 'modal';

for k = 1:size(Noises,1)
    
    %     set(Wait, 'WindowStyle','modal');
    waitbar(k/(size(Noises,1)+1),Wait,['��������� ����������� � ' num2str(k)]);
    
    %%%%%%%%%%% ���������  
    try
        % ���� ���������� ���������� ��������������� �����������   
        if Noises(k,4) == 1            
            Im = Temp_Filtered(:,:,:,k-1);            
        else
            Im = Original;
        end
        
        % ���� �� ������������ �������� ��������. ��� �����������
        if isempty(FilteredAsOriginal)
            
            Temp_Noised(:,:,:,k) = Noising( Im,...
                Noises(k,1),...
                Noises(k,2),...
                Noises(k,3));  % ��������
            
        else                  % ���. ��������������� ��� �����������
            Temp_Noised(:,:,:,k) = Noising( FilteredAsOriginal,...
                Noises(k,1),...
                Noises(k,2),...
                Noises(k,3));  % ��������
        end
        
    catch ME
        delete(Wait);
        delete(menu_handles.menu);      % ��������� ����-����
        errordlg({['��������� ����������� ��������� ������� � ������ � ' num2str(ME.stack(1).line)]; ME.message},'KAAIP','modal');
        return;
    end
    
    %%%%%%%%%%%%%%%%%% ���������
    
    try
        Temp_Filtered(:,:,:,k) = Filtration(Temp_Noised(:,:,:,k),Filters(k));
    catch ME
        delete(Wait);
        delete(menu_handles.menu);      % ��������� ����-����
        errordlg({['��������� ����������� ��������� ������� � ������ � ' num2str(ME.stack(1).line)];...
                ME.message},'KAAIP','modal');
        return;
    end
    
    drawnow;         % ��������� �������� ������ ������, ����� ��� �������� �����
    
    if getappdata(Wait,'canceling') == 1          % ���� ������ ������ ������ - ������� �� �����
        delete(Wait);
        delete(menu_handles.menu);      % ��������� ����-����
        return;
    end
    
end

if ContinueProcessing          % ���� ���������� ���������, �� ��������� � ����� �������
    
    % �������� ���������� ����� ��������� (������ ������, ���� start > 1)
    for i = 1:size(Noises,1)     % �� ���� ��������� ������� �������� ���������� �����
        Parametrs(i) = regexprep(Parametrs(i),num2str(i),num2str(i+start-1),'once');
    end
    
    Parametrs = vertcat(get(handles.NoiseFilterList,'String'),Parametrs');
    Filtered(:,:,:,start:start+size(Noises,1)-1) = Temp_Filtered;
    Noised(:,:,:,start:start+size(Noises,1)-1) = Temp_Noised;
    Filtered = uint8(Filtered);
    Noised = uint8(Noised);
else
    Noised = zeros(size(Temp_Noised),'uint8');
    Filtered = zeros(size(Temp_Filtered),'uint8'); %#ok<PREALL>
    Noised = Temp_Noised;
    Filtered = Temp_Filtered;
end

set(findobj('Parent',Wait,'Style','pushbutton'),'Enable','off');    % ����� ������������ ������� ������ �� ����

for p = 1:size(Filtered,4)
    str{p} = ['����������� � ' num2str(p)];
end

waitbar(k/(size(Noises,1)+1),Wait,'������ ��������� ������');

% ����� �� ������ SSIM-�������������
if menu_handles.SSIM_check.Value == 1
    SSIM = 2;
else
    SSIM = 0;
end

% �������� ������ ���������� ����������� � �������� �� �� �����
Assessment_N = [];
Assessment_F = [];
Assessment_N = GetAssessment(Original,Noised,SSIM);
Assessment_F = GetAssessment(Original,Filtered,SSIM);

% ��������� ��������� ����
set(handles.NoisedMenu,'String',str,'Value',1,'Enable','on');
set(handles.FilteredMenu,'String',str,'Value',1,'Enable','on');
handles.AssessMenu.Value = 1;
set(handles.Noised,'Enable','on');
set(handles.Filtered,'Enable','on');

ShowMenuString = handles.ShowMenu.String;
if ~strcmp(ShowMenuString{end},'SSIM-�����������');
    ShowMenuString{end+1} = 'SSIM-�����������';
end
handles.ShowMenu.String = ShowMenuString;

% ���� ����� ���������� ����� 10, �������� �������
if size(Noised,4) > 10
    set(handles.GraphSlider,'Min',1,...
        'Value',1,...
        'Max',size(Noised,4)-9,...
        'Enable','on',...
        'SliderStep',[1/(size(Noised,4)-10) 10/(size(Noised,4)-10)]);
    
else    % ����� ������� �����������
    set(handles.GraphSlider,'Enable','off');
end

% ������� ����������, ������� �������� ������� � �������� ��������
ShowMenu_Callback(hObject, eventdata, handles);
AssessMenu_Callback(hObject, eventdata, handles);

% ���������� ��������� �������� � ������ �������� �������
set(handles.FiltAgain,'Label','���������� ����� ������������ ����������� � 1');
set(handles.FiltAgainNoised,'Label','���������� ���������� ����������� � 1');

set(handles.NoiseFilterList,'String',Parametrs,'Value',1);
set(handles.GraphSlider,'Value',1);

set([   handles.NoisePanel;...
    handles.FiltPanel;...
    handles.GraphSlider;...
    handles.AssessMenu;...
    handles.ViewNoisedCheck;...
    handles.ViewFilteredCheck;...
    handles.NoiseFilterList;...
    handles.Diagram],'Visible','on');

set(handles.NoiseFilterListMenu,'Enable','on');
set(handles.FiltAgain,'Enable','on');
set(handles.FiltAgainNoised,'Enable','on');
set(handles.ContinueProcessing,'Enable','on');

if size(Noised,4) > 1       % ���� � ������ ����� 1� ���������, ����� ����� ���-�� �������
    set(handles.DeleteListPosition,'Enable','on');
end

delete(menu_handles.menu);          % ��������� ����-����
delete(Wait);                       % ��������� ���� ���������, � ������������ �� ������ ����������
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ������ ��������� �������� �������
function MaskTable_CellSelectionCallback(~, eventdata, menu_handles)

% ������ �� ���� ������� ������ � ������, ������ ������ ��� �������� �������,
% ������� ����� ������� � ��������� �� �� �������� (?0)

switch get(menu_handles.FilterType,'Value')
    
    case {2,5,28}      % ��������� ������ � ������������ ����������
        
        if size(eventdata.Indices,1) > 0
            Data = get(menu_handles.MaskTable,'Data');
            Data(eventdata.Indices(1),eventdata.Indices(2)) = abs(Data(eventdata.Indices(1),eventdata.Indices(2)) - 1);
            set(menu_handles.MaskTable,'Data',Data);
            
            if any(any(Data)) == 0          % ���� ������������ ������� ��� ������� - ����������, ������� �� ������ �������
                Data((size(Data,1)+1)/2,(size(Data,1)+1)/2) = 1;
                set(menu_handles.MaskTable,'Data',Data);
            end
        end
        
    case 4      % ��������������� ��������� 
            
        if size(eventdata.Indices,1) > 0
            Data = get(menu_handles.MaskTable,'Data');            
                
            if get(menu_handles.FiltParMenu2,'Value') == 11     % �����/�������
                if size(eventdata.Indices,1) > 0
                    set(menu_handles.EpsilonSlider,'Value',eventdata.Indices(1));
                    set(menu_handles.EpsilonValText,'String',num2str(eventdata.Indices(1)));
                    set(menu_handles.ZetaSlider,'Value',eventdata.Indices(2));
                    set(menu_handles.ZetaValText,'String',num2str(eventdata.Indices(2)));
                end                
            end
            
            if get(menu_handles.FiltParMenu2,'Value') < 7
                
                Data(eventdata.Indices(1),eventdata.Indices(2)) = ...
                    abs(Data(eventdata.Indices(1),eventdata.Indices(2)) - 1);
                
                set(menu_handles.MaskTable,'Data',Data);
                
                if any(any(Data)) == 0          % ���� ������������ ������� ��� ������� - ����������, ������� �� ������ �������
                    Data((size(Data,1)+1)/2,(size(Data,1)+1)/2) = 1;
                    set(menu_handles.MaskTable,'Data',Data);
                end
            end
        end
            
            
    case 11     % ������������ ������
        
        if size(eventdata.Indices,1) > 0
            set(menu_handles.BetaSlider,'Value',eventdata.Indices(1));
            set(menu_handles.BetaValText,'String',num2str(eventdata.Indices(1)));
            set(menu_handles.GammaSlider,'Value',eventdata.Indices(2));
            set(menu_handles.GammaValText,'String',num2str(eventdata.Indices(2)));            
        end
                
                
end


% ������ ��������� �������� ������� 1
function MaskTable1_CellSelectionCallback(~, eventdata, menu_handles)

switch get(menu_handles.FilterType,'Value')
    case 5
        if size(eventdata.Indices,1) > 0
            set(menu_handles.BetaSlider,'Value',eventdata.Indices(1));
            set(menu_handles.BetaValText,'String',num2str(eventdata.Indices(1)));
            set(menu_handles.GammaSlider,'Value',eventdata.Indices(2));
            set(menu_handles.GammaValText,'String',num2str(eventdata.Indices(2)));
        end
end


% ���������� ���� "���������� ����� ��� �����������"
function CopyMask_Callback(~, ~, menu_handles)
    
if gco == menu_handles.MaskTable
    ClipboardCopyObject(menu_handles.MaskTable,0);
    
elseif gco == menu_handles.MaskTable1
    ClipboardCopyObject(menu_handles.MaskTable1,0);
end


% ���������� ���� "��������� ����� ��� �����������"
function SaveMask_Callback(~, ~, ~)    
    
[FileName, PathName] = uiputfile({'*.jpg';'*.bmp';'*.tif';'*.png'},'��������� �����');

if FileName~=0 
    SaveObjectAsImage(gco,[PathName FileName]);
end

    
% ���������� ���� "��������� ����� ��� �������"
function SaveMaskXLSX_Callback(~, ~, ~)

Data = get(gco,'Data');

[FileName, PathName] = uiputfile('*.xlsx','��������� �����');

if FileName~=0 
    xlswrite([PathName FileName],Data);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% �������  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ������� ����������� ���������� � ����������� �� ���������� ���� ����
function Noised = Noising(Image,NoiseType,A,B)
% Noised - �������� ����������� �����������, ������ �������� ��������� �
%   �������
% Image - ������� �����������, ���-�� ������� �� ����������
% NoiseType - ��� ����
% A - �������� ���� ��� ������� �������������
% � - ������ �������� ���� ������ ��� ������������ �������������

Noised = double(Image);  

for CH = 1:size(Noised,3)                % ��� ������� ������ ����� 
    
    switch NoiseType                                              

        case 2                                  % ���������� �������������
            
            N = B/255 + (A/255).*randn(size(Noised,1),size(Noised,2));       % ���.��������+���������(������� �������)    
            N = round(N*255);
            Noised(:,:,CH) = Noised(:,:,CH) + N;
                               
        case 3                             % ��� ��������
            
            Noised = imnoise(Image,'poisson');

        case 4                                  % ������� �������������
            
            N = rand(size(Noised,1),size(Noised,2));        % ��������� ����������� �������        
            
            for j = 1:size(Noised,1)                          % � ������ �������
                for i = 1:size(Noised,2)                      % � ������ ������
                    if N(j,i) <= 0.5                        % �� �� ������ ������������� ����������
                            N(j,i) = 0.5 + log(2*N(j,i))/A;  
                    else                                    % ����� ������� �� ���� ����������
                            N(j,i) = 0.5 - log(2*(1-N(j,i)))/A;
                    end
                end
            end
            
            N = N - 0.5 + B/255;
            N = round(N*255);            
            Noised(:,:,CH) = Noised(:,:,CH) + N;

        case 5                         % ����������� �������������
            
            N = rand(size(Noised,1),size(Noised,2));        % ��������� ������� �������
            N = round(N*(B-A)+A);        % � 256 ��������
            Noised(:,:,CH) = Noised(:,:,CH) + N;
            
        case 6                                  % �����-���
            
            Noised = imnoise(Image,'speckle',A/255);
            
        case 7                                  % ����-����� ���
            
            Noised = imnoise(Image,'salt & pepper',A*0.01);
            
        case 8                                  % ����-���
            
            for i = 1:size(Noised,1)*size(Noised,2)*A*0.01      % ��� ��������� ���������� ��������
                x = fix(rand(1)*(size(Noised,2)-1))+1;       % ������ ����. ���������� �� �
                y = fix(rand(1)*(size(Noised,1)-1))+1;       % ������ ����. ���������� �� Y
                Noised(y,x,CH) = 255;                        % ������ �������� ��������� ������� �� �����
            end
            
        case 9                                  % �����-���
            
            for i = 1:size(Noised,1)*size(Noised,2)*A*0.01      % ��� ��������� ���������� ��������
                x = fix(rand(1)*(size(Noised,2)-1))+1;       % ������ ����. ���������� �� �
                y = fix(rand(1)*(size(Noised,1)-1))+1;       % ������ ����. ���������� �� Y
                Noised(y,x,CH) = 0;                          % ������ �������� ��������� ������� �� �����
            end
            
        case 10                                 % �������� ���
            
            filtemask = fspecial('motion', A, B);
            Noised(:,:,CH) = imfilter(Noised(:,:,CH),filtemask,'circular');
            
        case 11                                  % ����� �������������
            
            N = raylrnd(A,size(Noised,1),size(Noised,2));
            N = round(N*255);
            Noised(:,:,CH) = Noised(:,:,CH) + N; 
            
        case 12                                  % ���������������� �������������
            
            N = exprnd(1/A,size(Noised,1),size(Noised,2));            
            N = round(N*255);
            Noised(:,:,CH) = Noised(:,:,CH) + N; 
    end    
end

if ~isfloat(Image) 
    Noised = uint8(Noised);
end


% ������� ���������� 
function Filtered = Filtration(Image,Filters)

% Filtered - �������� �����������, ������ �������� ��������� � �������
% Image - ������� �����������, �������� � ��������������

FilterType = Filters.FilterType;   % ��������� ��� �������
IndentNumber = Filters.Indent;     % ��������� �������� ���� ��������� �����
FPM1 = Filters.FPM1;               % � ������ �����
FPM2 = Filters.FPM2;               % ��������� �������� ������� ����
FPM3 = Filters.FPM3;               % ��������� �������

alpha = Filters.Alpha;             % ��������� �������� �����
beta =  Filters.Beta;              % ��������� �������� ����
gamma = Filters.Gamma;             % ��������� �������� �������� �����
delta = Filters.Delta;             % ��������� �������� ������
epsilon = Filters.Epsilon;         % ��������� �������� �������� �������
zeta = Filters.Zeta;               % ��������� �������� �������� �����
eta =   Filters.Eta;               % ��������� �������� �������� ���
theta = Filters.Theta;             % ��������� �������� �������� ����

Mask = Filters.mask;               % �������� �����
Mask1 = Filters.mask1;             % �������� �����1

if FilterType == 1                  % ���� �� ����� ��������� - �������� � ������
    Filtered = Image;
    return;
end

MaskSize = 2*FPM1 + 1;
MaskElements = MaskSize^2;          % ���������� ��������� � �����
Filtered = zeros(size(Image));      % �������� ������
Image = im2double(Image);           % ������ ����������� �� 0 �� 1 !!!!

switch IndentNumber                 % �������� ��� ��������� ����� �����������
    case 1
        IndentType = 'symmetric';   % ��� ���� ���������� ��������
        IndentTypeMed = 'symmetric';% ��� ���������� ������� (������ ������� � ��� �������)
    case 2
        IndentType = 0;
        IndentTypeMed = 'zeros';
    case 3
        IndentType = 'circular';
        IndentTypeMed = 'circular';
    case 4
        IndentType = 'replicate';
        IndentTypeMed = 'replicate';
end

% �������� ������ � ���� ����

for CH = 1:size(Image,3)        % ��� ������� ������ ����� 
    
    switch FilterType
        case 1                  % ��� ���������            
            
        case 2                  % ��������� ������
            
            switch FPM2
                case 1          % ������������
                    CenterElement = round((size(find(Mask == 1),1)+1)/2);           % ������ �����. �������
                    Filtered(:,:,CH) = ordfilt2(Image(:,:,CH),CenterElement,Mask,IndentTypeMed);  % ���������
                    
                case 2          % ���. ��������
                    
                    ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);      % �������� �������-�������
                    Col = zeros(size(Image,1)*size(Image,2),1);         % �������� ����������� ���� �������                  
                    Ro = zeros(MaskElements,1);                         % ������� ��� �������� ����������
                    
                    for x = 1:size(ImCol,2)         % ��� ������ �����
                        
                        for y = 1:MaskElements
                            Ro(y) = abs(ImCol(y,x)*MaskElements - sum(ImCol(:,x))); % ������ ���������� ����� ���������
                        end
                        [~,I] = min(Ro);        % �������� ����� ������������ ����������
                        Col(x) = ImCol(I,x);    % ����������� �������-������� ����� ��������
                    end
                    
                    Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH)); % ���������� ������� � �����������
                    
                case 3          % ����������
                    
                    ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);
                    Col = zeros(size(Image,1)*size(Image,2),1);
                    central = (MaskElements+1)/2;             % ����� �������� ������� �����
                    
                    for x = 1:size(ImCol,2)                                 % ��� ������� �������
                        ImCol(:,x) = round(255*sort(ImCol(:,x),'ascend'));  % ��������� �� �����������, ��� � ��������� ����������
                        
                        if ImCol(central+1,x)-ImCol(central-1,x) ~= 0       % ���� ��������� �� ������ ������� ���������� �� �������
                            
                            Intermediate = (ImCol(central-1,x):ImCol(central+1,x))';    % ������ ��� �������� ��������
                            
                            R = zeros(size(Intermediate));      % ������ ��� ������� ���������� ����� ���������� �������    
                            for y = 1:size(Intermediate,1)      % ��� ������� �������� ���� ����� ����������
                                R(y) = abs(Intermediate(y)*size(Intermediate,1) - sum(Intermediate(:)));
                            end
                            
                            [~,I] = min(R);                     % �������� ����� ������������ ����������
                            Col(x) = Intermediate(I)/255;       % ����������� �������-������� ����� ��������
                        else
                            Col(x) = ImCol(central,x)/255;      % �����, ������ �������
                        end
                    end
                    
                    Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));  % ���������� ������� � �����������
                    
                case 4          % N-������
                    
                    for RGB = 1:size(Image,3)
                        ImCol(:,:,RGB) = image2col(Image(:,:,RGB),MaskSize,IndentType);
                    end
                    
                    Col = zeros(size(Image,1)*size(Image,2),1,size(Image,3));   % RGB-������ ������-������� � ��������� ���������
                    
                    for x = 1:size(ImCol,2)                             % ��� ������� �������
                        K = double(ImCol(:,x,:));                       % ��������� �� �������
                        Ro = zeros(MaskElements);                       % �������� ������ ��� �������� ����������
                        
                        for y = 1:MaskElements
                            for z = 1:MaskElements
                                if FPM3 ~= 4                           % ���� ������� ������� �� "������������"
                                    for RGB = 1:size(Image,3)
                                        Ro(y,z) = Ro(y,z) + (abs(K(y,1,RGB) - K(z,1,RGB)))^FPM3;   % ������ ����� ��������� ����������
                                    end
                                    Ro(y,z) = Ro(y,z)^(1/FPM3);        % ���� ����� ��� ������
                                else
                                    Ro(y) = Ro(y) + max(abs(K(y,1,1:size(Image,3)) - K(z,1,1:size(Image,3))));
                                end
                            end
                        end
                        
                        [~,I] = min(sum(Ro,2));     % �������� ����� ������������ ����������
                        Col(x,:,:) = K(I,:,:);      % ����������� �������-������� ����� ��������
                    end
                    
                    for RGB = 1:size(Image,3)       % ����������� �������� �����������
                        Filtered(:,:,RGB) = Col2Filtered(Col(:,:,RGB),Image(:,:,RGB));
                    end
                    
                    Filtered = uint8(Filtered*255);
                    return;
            end
            
        case 3                  % �����������
            
            switch FPM2
                
                case 1  % ���������
                    
                    if size(Image,3) > 3            % ��� �������������� �����������
                        for ch = 1:size(Image,3)    % ������������ ������ ����� ��� �����������
                            Filtered(:,:,ch) = im2bw(Image(:,:,ch),alpha/255);
                        end
                    else
                        
                        Filtered(:,:,1) = im2bw(Image,alpha/255);
                        for x = 2:size(Image,3)
                            Filtered(:,:,x) = Filtered(:,:,1);
                        end
                    end
                    
                case 2  % ���
                    
                    if size(Image,3) > 3            % ��� �������������� �����������
                        for ch = 1:size(Image,3)    % ������������ ������ ����� ��� �����������                            
                            Filtered(:,:,ch) = im2bw(Image(:,:,ch),graythresh(Image(:,:,ch)));
                        end
                    else                            % ��� ����������� � RGB
                        Filtered(:,:,1) = im2bw(Image,graythresh(Image));
                        for x = 2:size(Image,3)
                            Filtered(:,:,x) = Filtered(:,:,1);
                        end
                    end
                    
                case {3,4,5,6,7,8}      % ��� ������-���������� ������
                    
                    if size(Image,3) == 3           % ��� RGB
                        Image = rgb2gray(Image);    % �������� �����������
                    end
                    
                    for ch = 1:size(Image,3)    % ������������ ������ ����� ��� �����������
                        
                        Im = Image(:,:,ch);
                        ImCol = image2col(Im,MaskSize,'symmetric');   % �������-������� �����
                        Col = ImCol((MaskElements+1)/2,:)';                        
                        
                        switch FPM2
                            
                            case 3      % ������-����
                                
                                Mu = mean(ImCol,1)';
                                Col(Col >= Mu*(1+beta)) = 1;
                                Col(Col < Mu*(1+beta)) = 0;
                                
                            case 4      % �������
                                
                                Mu = mean(ImCol,1)';
                                D = (std(ImCol,1).^2)';
                                T = Mu + D*beta;
                                Col(Col >= T) = 1;
                                Col(Col < T) = 0;
                                
                                
                            case 5      % ���������
                                
                                Mu = mean(ImCol,1)';
                                D = (std(ImCol,1).^2)';
                                M = min(Im(:));
                                R = max(D);
                                T = Mu - beta.*(1-D./R).*(Mu-M);
                                Col(Col >= T) = 1;
                                Col(Col < T) = 0;
                                
                            case 6      % ��������
                                
                                T = ((max(ImCol,[],1) - min(ImCol,[],1)) / 2)';
                                Col(Col >= T) = 1;
                                Col(Col < T) = 0;
                                
                            case 7      % �������
                                
                                Mu = mean(ImCol,1)';
                                D = (std(ImCol,1).^2)';
                                T = Mu.*(1 - beta.*(1-D./gamma));
                                Col(Col >= T) = 1;
                                Col(Col < T) = 0;
                                
                            case 8      % � ���������� �������                                
                                
                                T0 = graythresh(Image);     % ���������� �����
                                primitive = strel('arbitrary',ones(delta,eta),alpha/255*ones(delta,eta));   % ��������
                                f0 = imopen(Image,primitive);   % ����������, ������� ������ ��� 
                                
                                Col = ImCol((MaskElements+1)/2,:);
                                
                                f0Cols = image2col(f0,3,'symmetric');
                                f0Col = f0Cols(5,:)+T0;
                                
                                Col(Col >= f0Col) = 1;
                                Col(Col < f0Col) = 0;                        
                        end
                        
                        Filtered(:,:,ch) = Col2Filtered(Col,Im);
                    end
                    
            end          
            
            if size(Image,3) ~= size(Filtered,3)      % ���� RGB, ����� ��������� ������
                for x = 2:size(Filtered,3)
                    Filtered(:,:,x) = Filtered(:,:,1);
                end
            end
            
            Filtered = uint8(Filtered*255);
            return;
            
        case 4                  % ��������������� ��������� (�/�)
                                   
            BW_Image = getBW(Image);          % BW - ���������� ����������� 
            
            % ���������� ��������� ���������
            if FPM2 < 7               % ��� ���������...����
                
                switch FPM3
                    case 1
                        structure = strel('diamond',beta);
                    case 2
                        structure = strel('disk',beta);
                    case 3
                        structure = strel('line',beta,gamma);
                    case 4
                        structure = strel('octagon',beta);
                    case 5
                        structure = strel('pair',[beta gamma]);
                    case 6
                        structure = strel('rectangle',[beta gamma]);
                    case 7
                        structure = strel('arbitrary',Mask);
                end
                
            elseif FPM2 > 6 && FPM2 < 10   % �� �������
                
                structure = FPM3*4;                
                
            elseif FPM2 == 10    % �������� ������
                
                switch FPM3
                    case 1
                        structure = 4;
                        add = 'euclidean';
                    case 2
                        structure = 8;
                        add = 'euclidean';
                    case 3
                        structure = 4;
                        add = 'cityblock';
                    case 4
                        structure = 8;
                        add = 'cityblock';
                    case 5
                        structure = 4;
                        add = 'chessboard';
                    case 6
                        structure = 8;
                        add = 'chessboard';
                    case 7
                        structure = 4;
                        add = 'quasi-euclidean';
                    case 8
                        structure = 8;
                        add = 'quasi-euclidean';
                end
                
            elseif FPM2 == 11                     % �����/������
                structure = Mask;
            end
            
            if delta == 0
                delta = inf;        % ����� �������� �� ������������
            end
            
            for ch = 1:size(BW_Image,3)            % �� �������� �� ���������
                
                BW_Im = BW_Image(:,:,ch);
                
                if FPM2 < 12      % ��� �������� �� �� bwmorph
                    
                    n = 1;
                    
                    while delta >= n   
                        
                        Im_gauge = BW_Im;
                        
                        switch FPM2
                            case 1              % ���������
                                BW_Im = imdilate(BW_Im,structure);
                                
                            case 2              % ������
                                BW_Im = imerode(BW_Im,structure);
                                
                            case 3              % ����������
                                BW_Im = imopen(BW_Im,structure);
                                
                            case 4              % ���������
                                BW_Im = imclose(BW_Im,structure);
                                
                            case 5              % ��� �����
                                BW_Im = imbothat(BW_Im,structure);
                                
                            case 6              % ���� �����
                                BW_Im = imtophat(BW_Im,structure);
                                
                            case 7              % ���������� ���������
                                BW_Im = imfill(BW_Im,structure,'holes');
                                
                            case 8              % ������� ������
                                BW_Im = imclearborder(BW_Im,structure);
                                
                            case 9              % ��������� ���������
                                BW_Im = bwperim(BW_Im,structure);
                                
                            case 10              % �������������
                                BW_Im = bwulterode(BW_Im,add,structure);
                                
                            case 11              % �����/�������
                                BW_Im = bwhitmiss(BW_Im,structure);
                        end                        
                        
                        if BW_Im == Im_gauge        % ���� ����������� �� ����������, ������� �� �����
                            break;
                        end
                        
                        n = n + 1;
                        
                    end
                    
                else            % ��� bwmorph, ������� ��� ����������� �� �������������
                    
                    switch FPM2
                        case 12              % ����������
                            BW_Im = bwmorph(BW_Im,'bridge',delta);
                            
                        case 13              % ������� ������������� ��������
                            BW_Im = bwmorph(BW_Im,'clean',delta);
                            
                        case 14              % ������������ ����������
                            BW_Im = bwmorph(BW_Im,'diag',delta);
                            
                        case 15              % �-���������
                            BW_Im = bwmorph(BW_Im,'hbreak',delta);
                            
                        case 16              % �� ���� �� �������� ����
                            BW_Im = bwmorph(BW_Im,'majority',delta);
                            
                        case 17              % �������� ���������� ��������
                            BW_Im = bwmorph(BW_Im,'remove',delta);
                            
                        case 18              % ������ �� �����/������
                            BW_Im = bwmorph(BW_Im,'shrink',delta);
                            
                        case 19              % �����
                            BW_Im = bwmorph(BW_Im,'skel',delta);
                            
                        case 20              % �������� ���������
                            BW_Im = bwmorph(BW_Im,'spur',delta);
                            
                        case 21              % ���������
                            BW_Im = bwmorph(BW_Im,'thicken',delta);
                            
                        case 22              % ���������
                            BW_Im = bwmorph(BW_Im,'thin',delta);
                            
                    end
                end
                
                BW_Image(:,:,ch) = BW_Im;
                
            end
            
            Filtered = uint8(double(BW_Image)*255); % ��������� � 256 ��������
            
            if size(Image,3) ~= size(BW_Image,3)  % ���� ����� ������� �� � ��� ����������� �� ������
                for x = 2:size(Image,3)
                    Filtered(:,:,x) = Filtered(:,:,1);
                end
            end
            
            return;
            
        case 5                  % ����������� ��������������� ���������
            
            if FPM2 < 7               % ��� ���������...����
               
                structure = strel('arbitrary',Mask,Mask1/255);
                
                % ��� �������� �� �������
            elseif  (FPM2 > 7 && FPM2 < 10) ||...
                    (FPM2 > 10 && FPM2 < 17)
                
                switch size(Image,3)        % ������� ������� ������� 
                    case 1
                        structure = 4*FPM3;
                        
                    case 3
                        if FPM3 == 1
                            structure = 6;
                        elseif FPM3 == 2
                            structure = 18;
                        elseif FPM3 == 3 
                            structure = 26;
                        end     
                        
                    otherwise
                        if FPM3 == 1                            
                            structure = conndef(size(Image,3),'minimal');
                        elseif FPM3 == 2                            
                            structure = conndef(size(Image,3),'maximal');
                        end
                end
                
            elseif FPM2 == 10    % �������� ������
                
                if size(Image,3) ~= 3       % ��� ������������ � ���������������� �����������
                    switch FPM3
                        case {1,2}
                            add = 'euclidean';
                        case {3,4}
                            add = 'cityblock';
                        case {5,6}
                            add = 'chessboard';
                        case {7,8}
                            add = 'quasi-euclidean';
                    end
                    
                    if mod(FPM3,2) == 1            % ��������� ��������
                        if size(Image,3) == 1       % ��� ������������
                            structure = 4;
                        else
                            structure = conndef(size(Image,3),'minimal');
                        end
                    else
                        if size(Image,3) == 1
                            structure = 4;
                        else
                            structure = conndef(size(Image,3),'maximal');
                        end
                    end
                    
                else        % ��� 3-D                    
                    switch FPM3
                        case {1,2,3}
                            add = 'euclidean';
                        case {4,5,6}
                            add = 'cityblock';
                        case {7,8,9}
                            add = 'chessboard';
                        case {10,11,12}
                            add = 'quasi-euclidean';
                    end                    
                    
                    if mod(FPM3,2) == 1            % ��������� ��������� 3�
                        structure = 6;
                        
                    elseif mod(FPM3,2) == 2
                        structure = 18;
                        
                    elseif mod(FPM3,2) == 0
                        structure = 26;
                        
                    end             
                end
            end
            
            if delta == 0
                delta = inf;        % ����� �������� �� ������������
            end
            n = 1;                          % �������� ����            
            Grey_Im = Image;   % ������ ������
            
            % ���� ����� �������� ������ delta �� ���������� 
            % ��� ����������� �� ����������������� ��������� ����
            while delta >= n
                
                Im_gauge = Grey_Im;        % ���� ��� ������������, ��������� ������������
                
                switch FPM2                    
                    case 1
                        Grey_Im = imdilate(Grey_Im,structure);
                    case 2
                        Grey_Im = imerode(Grey_Im,structure);                        
                    case 3
                        Grey_Im = imopen(Grey_Im,structure);
                    case 4
                        Grey_Im = imclose(Grey_Im,structure);
                    case 5
                        Grey_Im = imbothat(Grey_Im,structure);
                    case 6
                        Grey_Im = imtophat(Grey_Im,structure);
                    case 7
                        Grey_Im = imfill(Grey_Im);
                    case 8
                        Grey_Im = imclearborder(Grey_Im,structure);
                    case 9
                        Grey_Im = bwperim(Grey_Im,structure);
                    case 10 
                        Grey_Im = bwulterode(Grey_Im,add,structure);
                    case 11
                        Grey_Im = imextendedmin(Grey_Im,alpha/255,structure);
                    case 12
                        Grey_Im = imextendedmax(Grey_Im,alpha/255,structure);
                    case 13
                        Grey_Im = imhmin(Grey_Im,alpha/255,structure);
                    case 14
                        Grey_Im = imhmax(Grey_Im,alpha/255,structure);
                    case 15
                        Grey_Im = imregionalmin(Grey_Im,structure);
                    case 16
                        Grey_Im = imregionalmax(Grey_Im,structure);
                end
                
                if Grey_Im == Im_gauge     % �������� ���������                  
                    break;
                end
                
                n = n + 1;              % ����������� �������   
                
            end
            
            Filtered = uint8(Grey_Im*255);
            return;
               
        case 6                  % ������������� ������   
            
            indent = (MaskSize - 1)/2;                              % ������� ���������� �������
            central = (MaskSize + 1)/2;                             % ������� ������� �����                                            % ������� ���������� �������
            N = padarray(Image(:,:,CH),[indent indent],IndentType,'both'); % ��������� �������
            
            switch FPM2
                
                case 1         % ������������� ������                    

                    ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);   % �������-������� �����
                    Col = zeros(size(Image,1)*size(Image,2),1);             % ������-������� �������� ��������
                    
                    Beta = SpacialWeightCount(MaskSize);                    % �������� ���������������� ����� � �����
                    [~,BetaWeight] = meshgrid(1:size(ImCol,2),Beta);       % ������ �� ��������, � �� �������
                    [ImColCenters,~] = meshgrid(ImCol((MaskSize^2+1)/2,:),1:size(ImCol,1));
                    
                    AlphaWeight = alpha*255*abs(ImColCenters - ImCol);         % �������� ��������� �����
                    Weights = exp(-AlphaWeight - beta*BetaWeight);             % �������� ���������������� �����
                    Col = sum(Weights.*ImCol,1)./sum(Weights,1);            % �������� ��������
                    
                    Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));
            
                case 2                  % ������������� ������ (�������)                    

                    ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);   % �������-������� �����
                    Col = zeros(size(Image,1)*size(Image,2),1);             % ������-������� �������� ��������
                    
                    Beta = SpacialWeightCount(MaskSize);                    % �������� ���������������� ����� � �����
                    [~,BetaWeight] = meshgrid(1:size(ImCol,2),Beta);
                    med = sort(ImCol,1);
                    ImCol((MaskSize^2 + 1)/2,:) = med((MaskSize^2 + 1)/2,:);          % ����������� ������� ����� ����� �������
                    [ImColCenters,~] = meshgrid(ImCol((MaskSize^2 + 1)/2,:),1:size(ImCol,1));
                    
                    AlphaWeight = (alpha*255)*abs(ImColCenters - ImCol);          % �������� ��������� �����
                    Weights = exp(-AlphaWeight - beta*BetaWeight);          % �������� �������� �����
                    Col = sum(Weights.*ImCol,1)./sum(Weights,1);    
                    Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));
            
                case 3                    % ������������� ������ (������� ��������������)
                                         
                    ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);   % �������-������� �����
                    Col = zeros(size(Image,1)*size(Image,2),1);             % ������-������� �������� ��������
                    
                    Beta = SpacialWeightCount(MaskSize);                    % �������� ���������������� ����� � �����
                    [~,BetaWeight] = meshgrid(1:size(ImCol,2),Beta);
                    ImCol((MaskSize^2 + 1)/2,:) = sum(ImCol,1)./MaskElements;          % ����������� ������� ����� ����� �������
                    [ImColCenters,~] = meshgrid(ImCol((MaskSize^2 + 1)/2,:),1:size(ImCol,1));
                    
                    AlphaWeight = (alpha*255)*abs(ImColCenters - ImCol);          % �������� ��������� �����
                    Weights = exp(-AlphaWeight - beta*BetaWeight);          % �������� �������� �����
                    Col = sum(Weights.*ImCol,1)./sum(Weights,1);    
                    Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));
                    
                case 4                        % ������������� ������ (����������� ��������)
                    
                    for j = 1:size(Image,1)                                 % ��� ������� �������
                        for i = 1:size(Image,2)                             % ��� ������ ������
                            w = zeros(MaskSize);                            % ������ ������� ������������� 3�3
                            S = N(j:j+MaskSize-1,i:i+MaskSize-1);           % ��������� ������� 3�3
                            
                            str = double(sort(S(:)));                       % ����� ����������� ��������
                            Ro = zeros(MaskElements,1);                     % �������� ������� ��� �������� ����������
                            
                            for y = 1:MaskElements
                                Ro(y) = abs(str(y)*MaskElements - sum(str(:))); % ����� ����� ����������
                            end

                            [~,I] = min(Ro);                            % �������� ����� ������������ ����������                             
                            S(central,central) = str(I);                % ����������� �������-������� ����� ��������                            
                            
                            for l = 1:MaskSize                              % ��� ������� ������� ���� �������
                                for k = 1:MaskSize                          % ��� ������ ������ ���� ������� ��������� �����������
                                    w(l,k) = exp(-alpha*255*abs(S(central,central)-S(l,k)) - beta*(abs(central-k)+abs(central-l)));
                                end
                            end
                            
                            S = S.*w;       % ����������� ������������ ����������� �� ���������� ��������
                            Filtered(j,i,CH) = sum(S(:))/sum(w(:));    % ���������� ��������������� �������� 
                        end
                    end
                    
                    
                case 5                  % ������������� ������ (����������)
                    
                    leftLim = (MaskElements-1)/2;                           % ������� ���������� �������
                    rightLim = (MaskElements+3)/2;
                                       
                    for j = 1:size(Image,1)                                 % ��� ������� �������                        
                        for i = 1:size(Image,2)                             % ��� ������ ������
                            
                            w = zeros(MaskSize);                            % ������ ������� �������������
                            S = N(j:j+MaskSize-1,i:i+MaskSize-1);           % ��������� �������
                            
                            str = round(255*sort(S(:),'ascend'));           % ��������� �������� �����
                            
                            if str(rightLim) - str(leftLim) ~= 0
                                Intermediate = str(leftLim):str(rightLim);  % ������ ��� ��������
                                
                                Ro = zeros(size(Intermediate));
                                for y = 1:size(Intermediate,1)
                                    Ro(y) = abs(Intermediate(y)*size(Intermediate,1) - sum(Intermediate(:)));
                                end
                                
                                [~,I] = min(Ro);                            % �������� ����� ������������ ����������
                                S(central,central) = Intermediate(I)/255;       % ����������� �������-������� ����� ��������
                            end
                            
                            for l = 1:MaskSize                              % ��� ������� ������� ���� �������
                                for k = 1:MaskSize                          % ��� ������ ������ ���� ������� ��������� �����������
                                    w(l,k) = exp(-alpha*255*abs(S(central,central)-S(l,k)) -  beta*(abs(central-k)+abs(central-l)));
                                end
                            end
                            
                            S = S.*w;       % ����������� ������������ ����������� �� ���������� ��������
                            Filtered(j,i,CH) = sum(S(:))/sum(w(:));    % ���������� ��������������� �������� 
                        end
                    end                    
                    
                case 6                  % ������������� ������ (N-������)
                    
                    central = (MaskSize + 1)/2;
                    
                    for RGB = 1:size(Image,3)
                        ImCol(:,:,RGB) = image2col(Image(:,:,RGB),MaskSize,IndentType);
                    end
                    
                    Col = zeros(size(Image,1)*size(Image,2),1,size(Image,3));                % RGB-������ ������-�������
                    
                    for x = 1:size(ImCol,2)                     % ��� ������� �������
                        w = zeros(MaskSize^2,1);                    % �������� ������� ������������� 3�3
                        S = ImCol(:,x,:);                       % ��������� ������� � ����� ������� ������� � RGB �������
                        Ro = zeros(MaskElements);               % �������� ������ ��� �������� ����������
                        
                        if FPM3 ~= 4                           % ���� �� ����������� ������� ������� ������
                            for y = 1:MaskElements
                                for z = 1:MaskElements
                                    for RGB = 1:size(Image,3)
                                        Ro(y,z) = Ro(y,z) + (abs(S(y,1,RGB) - S(z,1,RGB)))^FPM3;
                                    end
                                    Ro(y,z) = Ro(y,z)^(1/FPM3);    % ((�-�)^p+(y-y)^p+(z-z)^p)^(1/p)
                                end
                            end
                        else                                        % ������� ���-���� �����������...
                            for y = 1:MaskElements
                                for z = 1:MaskElements
                                    Ro(y) = Ro(y) + max(abs(S(y,1,1:size(Image,3)) - S(z,1,1:size(Image,3))));
                                end
                            end
                        end
                        
                        [~,I] = min(sum(Ro,2));                         % �������� ����� ������������ ����������
                        S(central,1,:) = S(I,1,:);              % ����������� ��� ����������� �������
                        
                        %%%%%%%%%%%%%%%%%%% ����� ������������� ����� ������� %%%%%%%%%
                        
                        for l = 1:MaskElements                  % ��� ������� ������� ���� �������
                            w(l) = exp(-alpha*255*(Ro(I,l)));       % ��������� �����������
                        end
                        
                        w_beta = zeros(size(w));
                        p = 1;
                        for l = 1:MaskSize                              % ��� ������� ������� ���� �������
                            for k = 1:MaskSize                          % ��� ������ ������ ���� �������
                                w_beta(p) = exp(-beta*(abs(I-k)+abs(I-l)));    % ��������� �����������
                                p = p + 1;
                            end
                        end
                        
                        for RGB = 1:size(Image,3)            % ��� ������� ������
                            summ = zeros(1);
                            S(:,:,RGB) = S(:,:,RGB).*w.*w_beta;       % ����������� ������������ ����������� �� ���������� ��������
                            
                            for t = 1:size(S,1)
                                Col(x,RGB) = Col(x,RGB) + S(t,1,RGB);
                                summ = summ + w(t)*w_beta(t);
                            end
                            
                            Col(x,RGB) = Col(x,RGB)/summ;
                        end
                        
                    end
                    
                    for RGB = 1:size(Image,3)
                        Filtered(:,:,RGB) = Col2Filtered(Col(:,:,RGB),Image(:,:,RGB));
                    end                    
                    
                    Filtered = uint8(Filtered*255);
                    return;
            end
            
        case 7                  % ������ �������� �������
            
            % �������� ������� PSF � ������������ ��� ������ �����������
            [PreFiltered, PSF] = deconvblind(Image,ones(alpha,beta),gamma,delta);
            if FPM2 == 2       % ���� ���� ������ ������� 
                
                Filtered = edgetaper(Image,PSF);        % �������� �� � ���������� PSF
                
                % ��������� ����������� ���������� �������� ������� ��
                % ������ ����-����������
                Filtered = deconvlucy(Filtered,PSF,gamma,delta);
                
            else                
                Filtered = PreFiltered; 
            end            
            
            Filtered = uint8(Filtered*255);
            return;
            
        case 8                  % ������ ������
            
            [x,y] = meshgrid(-fix(MaskSize/2):fix(MaskSize/2),-fix(MaskSize/2):fix(MaskSize/2));
            
            % �������
            x_theta = x*cos(epsilon) + y*sin(epsilon);
            y_theta = -x*sin(epsilon) + y*cos(epsilon);
            
            filtemask = exp(-0.5*(x_theta.^2/alpha^2 + y_theta.^2/beta^2))*cos(2*pi*x_theta./gamma + delta);
            Filtered(:,:,CH) = imfilter(Image(:,:,CH),filtemask,IndentType);
            
            
        case 9                  % �������������� ����
            
            BW = getBW(Image);          % BW - ���������� ����������� 
                            
            for ch = 1:size(BW,3)
                [H,Theta,Rho] = hough(BW(:,:,ch),'RhoResolution',gamma,'Theta',alpha:FPM2:beta);
                Threshold = max(H(:))*FPM3/100;
                peaks = houghpeaks(H,theta,'Threshold',Threshold,'NHoodSize',[delta eta]);
                lines = houghlines(BW(:,:,ch),Theta,Rho,peaks,'FillGap',zeta,'MinLength',epsilon);
                
                for x = 1:length(lines)
                    
                    xi = lines(x).point1(1):lines(x).point2(1);     % ������� ��������
                    X = [lines(x).point1(1) lines(x).point2(1)];    % ��������� �����
                    Y = [lines(x).point1(2) lines(x).point2(2)];
                    
                    if lines(x).point1(1) == lines(x).point2(1)
                        yi = lines(x).point1(2):lines(x).point2(2);
                        xi = ones(1,size(yi,2));
                    else
                        yi = round(interp1(X,Y,xi));
                    end
                    
                    for i = 1:size(yi,2)
                        Filtered(yi(i),xi(i),ch) = 1;
                    end
                end
                
                if FPM1 == 2      % ���� ����� ������� STM
                    
                    try
                        imtool(H/max(H(:)));
                    catch
                        OpenImageOutside(H/max(H(:)));
                    end
                end
            end
            
            Filtered = uint8(Filtered*255); % ��������� � 256 ��������
            
            if size(Image,3) ~= size(BW,3)  % ���� ����� ������� �� � ��� ����������� �� ������
                for x = 2:size(Image,3)
                    Filtered(:,:,x) = Filtered(:,:,1);
                end
            end
            
            return;
            
            
        case 10                 % ���������������� ����������
            
            % ��������� ������� ��������
            x = 1;      
            row = zeros(1,(beta-alpha+1)*(delta-gamma+1));
            col = zeros(1,(beta-alpha+1)*(delta-gamma+1));
            
            for c = alpha:beta
                for r = gamma:delta
                    row(x) = r;
                    col(x) = c;
                    x = x+1;
                end
            end
            
            switch FPM2                
                
                case 1          % ��� ����������������
                   Filtered = decorrstretch(Image,'SampleSubs',{row, col}); 
                    
                case 2          % � �����������������
                   Filtered = decorrstretch(Image,'SampleSubs',{row, col},'Tol',[epsilon/255 zeta/255]);                    
            end
            
            Filtered = uint8(Filtered*256);
            return;
            
            
        case 11                 % ������������ ������        
            
            Filtered(:,:,CH) = imfilter(Image(:,:,CH),Mask,IndentType);            
            
            if FPM2 == 2          % � ����������                
                Filtered(:,:,CH) = Image(:,:,CH) - Filtered(:,:,CH);
            end            
            
            
        case 12                 % ������ �������
            
            Filtered(:,:,CH) = wiener2(Image(:,:,CH),[alpha beta]);
            
        case 13                  % ������ ������ ������   
                        
            filtemask = fspecial('gaussian',MaskSize,alpha);
            Filtered(:,:,CH) = imfilter(Image(:,:,CH),filtemask,IndentType); 
            
        case 14                  % ����������� ������
            
            switch FPM2
                case 1              % ��. �������
                    filtemask = fspecial('average',MaskSize);  
                    Filtered(:,:,CH) = imfilter(Image(:,:,CH),filtemask,IndentType);
                    
                case 2              % ��. ���������
                    Filtered(:,:,CH) = exp(imfilter(log(Image(:,:,CH)),ones(MaskSize),IndentType)).^(1/MaskSize/MaskSize);                    
                    
                case 3              % ������. ��
                    Filtered(:,:,CH) = MaskSize^2 ./ imfilter(1./(Image(:,:,CH)+eps),ones(MaskSize),IndentType);
                    
                case 4              % �����. ���������. ��.
                    Filtered(:,:,CH) = imfilter(Image(:,:,CH).^(alpha+1),ones(MaskSize),IndentType);
                    Filtered(:,:,CH) = Filtered(:,:,CH) ./ (imfilter(Image(:,:,CH).^(alpha),ones(MaskSize),IndentType)+eps);
                        
                case 5              % ��������
                    Filtered(:,:,CH) = ordfilt2(Image(:,:,CH),MaskSize^2,ones(MaskSize),IndentType);
                    
                case 6              % �������
                    Filtered(:,:,CH) = ordfilt2(Image(:,:,CH),1,ones(MaskSize),IndentType);
                    
                case 7              % ������� �����
                    F1 = ordfilt2(Image(:,:,CH),MaskSize^2,ones(MaskSize),IndentType);
                    F2 = ordfilt2(Image(:,:,CH),1,ones(MaskSize),IndentType);
                    Filtered(:,:,CH) = imlincomb(0.5,F1,0.5,F2);                    
                    
                case 8              % ������� ���������
                    Filtered(:,:,CH) = imfilter(Image(:,:,CH),ones(MaskSize),IndentType);
                    for k = 1:alpha/2
                        Filtered(:,:,CH) = imsubtract(Filtered(:,:,CH),ordfilt2(Image(:,:,CH),k,ones(MaskSize),IndentType));
                    end
                    
                    for k = (MaskSize^2 - (alpha/2) + 1):MaskSize^2
                        Filtered(:,:,CH) = imsubtract(Filtered(:,:,CH),ordfilt2(Image(:,:,CH),k,ones(MaskSize),IndentType));                        
                    end
                    
                    Filtered(:,:,CH) = Filtered(:,:,CH) / (MaskSize^2 - alpha);    
            end
            
            
        case 15                  % ������
            
            if alpha == 0       % ���� 0, ����� ����� �������������� ����� ������
                alpha = [];
            else
                alpha = alpha/255;
            end
            
            switch FPM3        % �� ������ ������������ �������� �����
                case 1
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'sobel',alpha,'horizontal','thinning');
                case 2
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'sobel',alpha,'horizontal','nothinning');
                case 3
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'sobel',alpha,'vertical','thinning');
                case 4
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'sobel',alpha,'vertical','nothinning');
                case 5
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'sobel',alpha,'both','thinning');
                case 6
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'sobel',alpha,'both','nothinning');
            end
            
        case 16                  % �����
            
            if alpha == 0  || beta == 256     % ���� 0, ����� ����� �������������� ����� ������
                thresh = [];
            else
                thresh = [alpha/255 beta/255];
            end
            
            Filtered(:,:,CH) = edge(Image(:,:,CH),'canny',thresh,gamma);           
            
            
        case 17                  % ��������
            
            if alpha == 0       % ���� 0, ����� ����� �������������� ����� ������
                alpha = [];
            else
                alpha = alpha/255;
            end
            
            switch FPM3        % �� ������ ������������ �������� �����
                case 1
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'prewitt',alpha,'horizontal');
                case 2
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'prewitt',alpha,'horizontal');
                case 3
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'prewitt',alpha,'vertical');
            end
            
        case 18                  % ��������
            
            if alpha == 0       % ���� 0, ����� ����� �������������� ����� ������
                alpha = [];
            else
                alpha = alpha/255;
            end
            
            switch FPM3        % �� ������ ������������ �������� �����
                case 1
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'sobel',alpha,'thinning');
                case 2
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'sobel',alpha,'nothinning');
            end
            
        case 19                  % ��������    
            
            filtemask = fspecial('disk', 0.5*(MaskSize-1));
            Filtered(:,:,CH) = imfilter(Image(:,:,CH),filtemask,IndentType); 
            
        case 20                  % ������� ������ �������  
            
            filtemask = fspecial('laplacian',alpha);
            Filtered(:,:,CH) = Image(:,:,CH) - imfilter(Image(:,:,CH),filtemask,IndentType); 
            
        case 21                  % ��������� �������� 
            
            filtemask = fspecial('unsharp',alpha);
            Filtered(:,:,CH) = imfilter(Image(:,:,CH),filtemask,IndentType); 
            
        case 22                  % ������ + �������
            
            filtemask = fspecial('log',MaskSize,alpha);
            Filtered(:,:,CH) = Image(:,:,CH) - imfilter(Image(:,:,CH),filtemask,IndentType); 
            
                                % ������ ���� �� ����� ���������, ������
        case 23                  % ���������� ���������             
            
            g = Image(:,:,CH);
            f = g;
            f(:) = 0;
            alreadyProcessed = false(size(g));
            
            for k = 3:2:alpha
                zmin = ordfilt2(g,1,ones(k,k),IndentType);
                zmax = ordfilt2(g,k*k,ones(k,k),IndentType);
                zmed = medfilt2(g,[k k],IndentType);
                proccessUsingLevelB = (zmed > zmin) & (zmax > zmed) & ...
                    ~alreadyProcessed;
                zB = (g > zmin) & (zmax > g);
                outputZxy = proccessUsingLevelB & zB;
                outputZmed = proccessUsingLevelB & ~zB;
                f(outputZxy) = g(outputZxy);
                f(outputZmed) = zmed(outputZmed);
                alreadyProcessed = alreadyProcessed | proccessUsingLevelB;
                if all(alreadyProcessed(:))
                    break;
                end
            end
            f(~alreadyProcessed) = zmed(~alreadyProcessed);
            Filtered(:,:,CH) = f;    
        
        
        case 24     % �����-������
            
            ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);             % �������-������� �����
            Col = zeros(size(Image,1)*size(Image,2),1);           % ������-������� �������� �������� 
            
            Pc = ImCol((MaskSize^2 + 1)/2,:);       % �������� ������������ �������
            Lm = mean(ImCol,1);                     % ������� ������� �����      
            SD = std(ImCol,1);              % C�� �����
            
            Ci = SD./Lm;
            Cu = 1/(beta)^0.5;
            Cmax = 2^0.5 * Cu;
            
            Col(Ci <= Cu) = Lm(Ci <= Cu);
            Col(Ci >= Cmax) = Pc(Ci >= Cmax);
            
            A = (1 + Cu^2) ./ ( Ci.^2 - Cu^2);
            B = A - alpha - 1;
            D = Lm.^2 .* B.^2 + 4.*A*alpha.*Lm.*Pc; 
            Rf = (B.*Lm + D.^0.5)./(2.*A); 
            Col(Ci > Cu & Ci < Cmax) =  Rf(Ci > Cu & Ci < Cmax);
            
            Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));
            
        % ������ �� ������ � ���������: 
        % http://desktop.arcgis.com/ru/arcmap/10.3/manage-data/raster-and-images/speckle-function.htm
        % http://www.pcigeomatics.com/geomatica-help/concepts/orthoengine_c/chapter_823.html
        % http://www.pcigeomatics.com/geomatica-help/concepts/orthoengine_c/chapter_824.html
        % http://www.pcigeomatics.com/geomatica-help/concepts/orthoengine_c/chapter_822.html
        case 25                 % ������ ��      
            
            ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);             % �������-������� �����
            Col = zeros(size(Image,1)*size(Image,2),1);           % ������-������� �������� �������� 
            
            Pc = ImCol((MaskSize^2 + 1)/2,:);       % �������� ������������ �������
            Lv = std(ImCol,1).^2;                   % ��������� ���������
            Lm = mean(ImCol,1);                     % ������� ������� �����
            
            switch FPM2                
                case 1      % ������������ ������   
                    
                    AV = alpha/255;                 % ������������ �� �������� 0...1 ���������
                    A = beta/255;                   % ������� ��������
                    Mv = gamma/255;
                    M = delta/255;                            
                    
                    switch FPM3                        
                        case 1      % ���������� ������                            
                            
                            K = Lv./(Lv + AV);
                            Col = Lm + K.*(Pc - Lm); 
                            
                        case 2      % ����������������� ������
                            
                            K = M.*Lv ./ ( (Lm.^2.*Mv) + (M.^2.*Lv));
                            Col = Lm + K.*(Pc - M.*Lm);   
                            
                        case 3      % ���. + �������.
                            
                            K = M.*Lv ./ ( (Lm.^2.*Mv) + (M.^2.*Lv) + AV);
                            Col = Lm + K.*(Pc - M.*Lm - A);                           
                            
                    end
                    
                case 2      % ���������� ������
                    
                    D = zeta;                       % ����������� ���������
                    Cu = 1 / epsilon^0.5;           % ����� �������
                    Cmax = (1 + 2/epsilon)^0.5;     % ������������ ����������� ��������� �����
                    SD = std(ImCol,1);              % C�� �����
                    Ci = SD./Lm;                    % ���������� ��������� ����������
                    
                    Col(Ci <= Cu) = Lm(Ci <= Cu);
                    Col(Ci >= Cmax) = Pc(Ci >= Cmax);                   
                    
                    K(Ci > Cu & Ci < Cmax) = exp( -D.*(Ci(Ci > Cu & Ci < Cmax) - Cu) ./ (Cmax - Ci(Ci > Cu & Ci < Cmax)) );
                    
                    Col(Ci > Cu & Ci < Cmax) =  Lm(Ci > Cu & Ci < Cmax) .* ...
                                                K(Ci > Cu & Ci < Cmax) + Pc(Ci > Cu & Ci < Cmax) ...
                                                .* (1 - K(Ci > Cu & Ci < Cmax)); 
                    
            end
            
            Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));
            
        case 26                 % ������ ������
            
            ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);             % �������-������� �����
            Col = zeros(size(Image,1)*size(Image,2),1);           % ������-������� �������� �������� 
            
            Lm = mean(ImCol,1);                     % ������� ������� �����
            SWC = SpacialWeightCount(MaskSize);     % �������� ���������������� ����� � �����
            
            switch FPM2                
                case 1      % ������������ ������ 
                    
                    Lv = std(ImCol,1).^2;                   % ��������� ���������
                    B = alpha .* (Lv ./ Lm.^2);
                    K = exp(-SWC*B);
                    Col = sum((ImCol .* K ),1)./sum(K,1);
                
                case 2      % ���������� ������
                
                    Pc = ImCol((MaskSize^2 + 1)/2,:);       % �������� ������������ �������
                    SD = std(ImCol,1);              % C�� �����
                    Ci = SD./Lm;
                    Cmax = (1 + 2/beta)^0.5;
                    Cu = 1/(beta)^0.5;
                    
                    Col(Ci <= Cu) = Lm(Ci <= Cu);
                    Col(Ci >= Cmax) = Pc(Ci >= Cmax);  
                    
                    K = alpha.*(Ci - Cu) ./ (Cmax - Ci);
                    M = exp(-SWC * K);
                    
                    C = sum((ImCol .* M ),1)./sum(M,1);
                    Col(Ci > Cu & Ci < Cmax) = C(Ci > Cu & Ci < Cmax);
                    
            end
            
            Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));
            
        case 27             % ������ �����
            
            ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);             % �������-������� �����
            Col = zeros(size(Image,1)*size(Image,2),1);           % ������-������� �������� �������� 
            
            Pc = ImCol((MaskSize^2 + 1)/2,:);       % �������� ������������ �������
            Lm = mean(ImCol,1);                     % ������� ������� �����                      
            SD = std(ImCol,1);              % C�� �����
                    
            Cu = 1/(alpha)^0.5;
            Ci = SD./Lm;
            
            K = (1 - (Cu ./ Ci)) / (1 + Cu);
            Col = Pc.*K + Lm.*(1 - K);
                        
            Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));
            
        case 28             % ������ ��������� ����������
            
            switch FPM2
                case 1
                    Filtered = rangefilt(Image,Mask);
                case 2
                    Filtered = entropyfilt(Image,Mask);
                case 3
                    Filtered = stdfilt(Image,Mask);
            end
            
            Filtered = uint8(Filtered*255);
            return;
            
        case 29             % ��������� ������    
            
           if FPM2 == 2     % HSV
                Image = rgb2hsv(Image);
           end               
           
           WorkChannel = Image(:,:,beta);
           
           switch FPM3
               case 1       % �����������
                   WorkChannel(delta/255 <= WorkChannel | WorkChannel >= eta/255) = alpha/255;
               case 2       % ����������
                   WorkChannel(delta/255 >= WorkChannel | WorkChannel <= eta/255) = alpha/255;                   
           end
           
           Image(:,:,beta) = WorkChannel;
           
           if FPM3 == 2     % HSV
               Image = hsv2rgb(Image);
           end
           
           Filtered = Image;
           Filtered = uint8(Filtered*255);
           return;
           
            
        case 30         % ��������
            
            switch FPM3
                case 1
                    method = 'Sobel';
                case 2
                    method = 'Prewitt';
                case 3
                    method = 'CentralDifference';
                case 4
                    method = 'IntermediateDifference';
                case 5
                    method = 'Roberts';
            end
            
            switch FPM2
                case 1
                    [Filtered(:,:,CH),~] = imgradient(Image(:,:,CH),method);
                    Filtered(:,:,CH) = Filtered(:,:,CH)/max(max(Filtered(:,:,CH)));
                case 2
                    [~,Filtered(:,:,CH)] = imgradient(Image(:,:,CH),method);
                    Filtered(:,:,CH) = Filtered(:,:,CH)/360;
                case 3
                    [Filtered(:,:,CH),~] = imgradientxy(Image(:,:,CH),method);
                    Filtered(:,:,CH) = Filtered(:,:,CH)/max(max(Filtered(:,:,CH)));
                case 4
                    [~,Filtered(:,:,CH)] = imgradientxy(Image(:,:,CH),method);
                    Filtered(:,:,CH) = Filtered(:,:,CH)/max(max(Filtered(:,:,CH)));
            end
                
        case 31         % ���������� �����������
            
           switch FPM3
               case 1       % RGB
                    Filtered(:,:,CH) = histeq(Image(:,:,CH),alpha);
               case 2       % HSV
                   if CH == 1
                       
                      Filtered_HSV = rgb2hsv(Image); 
                      Filtered_HSV(:,:,3) = histeq(Image(:,:,3),alpha);
                      Filtered = hsv2rgb(Filtered_HSV);
                      
                   end                   
           end   
           
        case 32         % �����������
                                
            quants = zeros(1,2^alpha-1);            
            x = 0:0.001:1;
            graph = (2^alpha-1)*(x.^beta);  % ��������� ������ ����������� �����������
            y = 1;                          % ������ �������
            quants(1,1) = 0;                % ������� ��������
            
            for z = 1:size(x,2)
                if graph(z) > y             % ���� ��������� ������� �������
                    quants(1,y+1) = x(z);        % ���������� ��������,
                    y = y + 1;              % � �������� �������� ���������� � ��������� �����
                end
            end
            
            % ��������� ������ �������� ��� ������� ������
            levels = 0:1/(2^alpha-1):1;
            
            % �� �������� �������� ��������            
            for x = 1:size(Image,1)
                [~,Filtered(x,:,CH)] = quantiz(Image(x,:,CH),quants,levels);
            end            
            
        case 33         % ���������������� � �����-����������
            
            Filtered(:,:,CH) = imadjust(Image(:,:,CH),[beta/255 gamma/255],[delta/255 epsilon/255],alpha);
            
        case 34         % �������� �����������
            
            switch FPM2
                case 1
                    method = 'TwoStage';
                case 2
                    method = 'PhaseCode';
            end
            
            switch FPM3
                case 1
                    OP = 'dark';
                case 2
                    OP = 'bright';
            end
            
            switch size(Image,3)        % ������� ������� �������   
                
                case 3                  % ��������
                     
                    warning('off','all');                    
                    if FPM2 == 1
                        [centers, rads] = imfindcircles(Image,[delta eta],...
                                            'ObjectPolarity',OP,'Method',method,...
                                            'Sensitivity',beta,'EdgeThreshold',gamma/255);  
                    else
                        [centers, rads] = imfindcircles(Image,[delta eta],...
                                            'ObjectPolarity',OP,'Method',method,...
                                            'EdgeThreshold',gamma/255);                          
                    end
                    warning('on','all');    
                    
                    for x = 1:length(rads)
                        points = GetCirclePoints(centers(x,1),centers(x,2),rads(x),Filtered(:,:,CH));                        
                        for y = 1:size(points,1)
                            Filtered(points(y,2),points(y,1),1) = 1;
                        end
                    end
                    
                    for x = 2:size(Image,3)
                        Filtered(:,:,x) = Filtered(:,:,1);
                    end
                    
                    Filtered = uint8(Filtered*255);
                    return;
                    
                otherwise               % ���������������                    
                    
                    warning('off','all');                 
                    if FPM2 == 1
                        [centers, rads] = imfindcircles(Image(:,:,CH),[delta eta],...
                                            'ObjectPolarity',OP,'Method',method,...
                                            'Sensitivity',beta,'EdgeThreshold',gamma/255);  
                    else
                        [centers, rads] = imfindcircles(Image(:,:,CH),[delta eta],...
                                            'ObjectPolarity',OP,'Method',method,...
                                            'EdgeThreshold',gamma/255);                          
                    end                                       
                    warning('on','all');      
                    
                    for x = 1:length(rads)
                        points = GetCirclePoints(centers(x,1),centers(x,2),rads(x),Filtered(:,:,CH));
                        
                        for y = 1:size(points,1)
                            Filtered(points(y,2),points(y,1),CH) = 1;
                        end
                    end
            end
            
        case 35     % �������� �������� �����/�����
            
            % ��������� � �����������
            if size(Image,3) > 2       
               Image = rgb2gray(Image(:,:,1:3)); 
            end
            
            switch FPM2
                
                case 1      % BRISK
                    points = detectBRISKFeatures(Image,'MinQuality',alpha,...
                                                'MinContrast',beta,...
                                                'NumOctaves',delta);                    
                    
                case 2      % FAST
                    points = detectFASTFeatures(Image,'MinQuality',alpha,...
                                                'MinContrast',beta);
                    
                case 3      % HARRIS
                    points = detectHarrisFeatures(Image,'MinQuality',alpha,...
                                                'FilterSize',gamma);
                    
                case 4      % MinEagenVals
                    points = detectMinEigenFeatures(Image,'MinQuality',alpha,...
                                                'FilterSize',gamma);
                    
                case 5      % SURF
                    points = detectSURFFeatures(Image,'NumScaleLevels',epsilon,...
                                                'MetricThreshold',zeta,...
                                                'NumOctaves',delta); 
            end
            
            coords = double(round(points.Location));    % ���������� ���������
            init_coords = coords;                       % ������ �����
            M = size(coords,1);
            i = 1;
            
            for x = -2:2        % �������� ��� ��������
                coords(i*M+1:i*M+M,:) = [init_coords(:,1)+x init_coords(:,2)-x];
                i = i + 1;
            end
            
            for x = 2:-1:-2        % �������� ��� ��������
                coords(i*M+1:i*M+M,:) = [init_coords(:,1)+x init_coords(:,2)+x];
                i = i + 1;
            end
            
            % ���� ���� ����� �� ������� ����������� - ������ ����������
            coords(coords(:,1) > size(Image,2)) = size(Image,2);
            coords(coords(:,2) > size(Image,1)) = size(Image,1);
            
            coords(end+1,1) = size(Image,2);             % ��������� ������ ������
            coords(end,2) = size(Image,1);               % ����� ��� ������. ������� 
            
            % ���������� ���������� �� ������ ������� � ��� �������   
            for CH = 1:size(Filtered,3)                
                M = logical(full(sparse(coords(:,2),coords(:,1),ones(size(coords,1),1))));
                Image(M) = 1;
                Filtered(:,:,CH) = Image;
            end 
            
            Filtered = uint8(Filtered*255);
            return;
    end    
end

Filtered = uint8(Filtered*255);
    

% ������� �������� �������� �����
function ImCol = image2col(Image,MaskSize,IndentType)
% ������� im2col
% ImCol - �������� ������, ��� ������ ������� - �������� ����� �������� �������
%   �������� �� �����������
% 
% | 1 | 2 | 3 |   |       |   | 1 | 2 | 3 |  
% | 4 | 5 | 6 |   |   ->  |   | 4 | 5 | 6 |
% | 7 | 8 | 9 |   |       |   | 7 | 8 | 9 |
% |   |   |   |   |       |   |   |   |   |

% Image - ������� �����������, ������ � ����� �������
% MaskSize - ������ �����: "3" - 3�3, "5" - 5�5, "7" - 7�7, "9" - 9�9

indent = (MaskSize - 1)/2;                                  % ������� ���������� �������
N = padarray(Image,[indent indent],IndentType,'both');      % ��������� �������
ImCol = zeros(MaskSize^2,size(Image,1)*size(Image,2));      % ������ ������ ������� � ��������� �����
z = 1;        

for j = indent+1 : size(N,1) - indent               % � �������� ��������� ��������� 
    for i = indent+1 : size(N,2) - indent           % ������ �������� �����������                
        V = N(-indent+j:j+indent,-indent+i:i+indent);   % ��������� �����
        ImCol(:,z) = V(:);            % ��������� � ������ �������� �����
        z = z + 1;
    end
end


% ������� ������������ ��������� ����������� �� �������-�������
function Filtered = Col2Filtered(Col,Image)
% Filtered - �������� �����������, ������ �������� ����� ������� Image
% Col - ������ �������
% Image - ������� ����������� 

k = 1;
Filtered = zeros(size(Image));

for y = 1:size(Image,1)
    for x = 1:size(Image,2)
        Filtered (y,x) = Col(k);         % ����������� ������������ ���������������
        k = k + 1;                       % ����������� � �������� ������
    end
end


% ������� ������ ��������� � ������������� �����������
function Assessment = GetAssessment(Orig_Im,Im,SSIM)

% Orig_Im - �������� �����������
% Im - ����� ��������������� �����������
% Assessment - ��������� � ����������� ������
% ���� SSIM == 0 - ��� �� ����� ������� ������
% ���� SSIM == 1 - ����� ��� 2D ����������� � �����������
% ���� SSIM == 2 - ������� ��

assert( size(Im,1) == size(Orig_Im,1) &&...
        size(Im,2) == size(Orig_Im,2) &&...
        size(Im,3) == size(Orig_Im,3),...
        '����������� ����������� ��� ��������� �� �����');
assert(~isempty( Orig_Im < 0) ,'������ ������ �� �������� ������������ (���� �����. ��������)');
assert(~isempty( Im < 0) ,'������ ������ �� �������� ������������ (���� �����. ��������)');

Orig_Im = double(Orig_Im);          % ��������� � �����-������, ����� ������ ���������� �����
Im = double(Im);

% ��������� ������: ���� � (RGB+1) x N_�����. ���������� ������ ��� ������� �� ������������; 
%  MAE,NAE,MSE,NMSE,SNR,PSNR,SSIM:
% |                     | chan sum  | 1-st chan | ...   | N-th chan     
% |     (1-st image)    | 0.25      | 0.11      |       | 0.33  
% |     (2-st image)    | 0.5       | 0.13      |       | 0.33  
% | 	(3-st image)    | 0.2       | 0.14      |       | 0.33  
% |     (4-st image)    | 0.245     | 0.15      |       | 0.33
% 
% SSIM_Image: ����������� ������������ � ��������

Assessment = struct(...
                    'MAE',zeros(size(Im,3)+1,1),...
                    'MSE',zeros(size(Im,3)+1,1),...
                    'NAE',zeros(size(Im,3)+1,1),...
                    'NMSE',zeros(size(Im,3)+1,1),...
                    'SNR',zeros(size(Im,3)+1,1),...
                    'PSNR',zeros(size(Im,3)+1,1),...
                    'SSIM',zeros(size(Im,3)+1,1),...
                    'SSIM_Image',zeros(size(Im,1),size(Im,2),size(Im,3))...
                    );       
                
Square = size(Im,1)*size(Im,2);         % ����� � ������ = �������

% ������ ������� ��������
AE = zeros(size(Im,3),1);         % ������� ���������� ������
SE = zeros(size(Im,3),1);         % ������� ������������ ������
MAE = zeros(size(Im,3),1);         % ������� ���������� ������
MSE = zeros(size(Im,3),1);         % ������� ������������ ������
NAE = zeros(size(Im,3),1);         % ������������� ���������� ������
NMSE = zeros(size(Im,3),1);        % ������������� �������������������� ������
SNR = zeros(size(Im,3),1);         % ��������� ������/���
PSNR = zeros(size(Im,3),1);        % ������� ��������� ������/���

ORIG_SQR = zeros(size(Im,3),1);     % ����� ��������� ���� �������� ������� �����������
ORIG_SUM = zeros(size(Im,3),1);     % ����� ���� �������� ������� �����������

for X = 1:size(Im,4)        % ��� ���� ���������������/����������� �����������  
    for RGB = 1:size(Im,3)      
        
        A = Orig_Im(:,:,RGB);           % ���������� ����������� � �������-�������
        B = Im(:,:,RGB,X);              % ��� ���������� �������� �������
        A = A(:);
        B = B(:);
        
        SE(RGB) = sum( (A - B).^2 );   % ����� �������������� ������
        AE(RGB) = sum( abs(A - B) );   % ����� ���������� ������
        ORIG_SQR(RGB) = sum( A.^2 );   % ����� ��������� �������� ���. ����-�
        ORIG_SUM(RGB) = sum(A);        % ����� �������� ���. ����-�

        NMSE(RGB) = SE(RGB) / ORIG_SQR(RGB);
        
        NAE(RGB) = AE(RGB) / ORIG_SUM(RGB);
        SNR(RGB) = 10*log10(ORIG_SUM(RGB)^2/SE(RGB));
        MAE(RGB) = AE(RGB) / Square;
        MSE(RGB) = SE(RGB) / Square;
        PSNR(RGB) = 10*log10( 255^2 / MSE(RGB) );
        
        Assessment(X).MAE(1+RGB) = MAE(RGB);
        Assessment(X).NAE(1+RGB) = NAE(RGB);
        Assessment(X).MSE(1+RGB) = MSE(RGB);
        Assessment(X).NMSE(1+RGB) = NMSE(RGB);
        Assessment(X).SNR(1+RGB) = SNR(RGB);
        Assessment(X).PSNR(1+RGB) = PSNR(RGB);
        if SSIM ~= 0
            Assessment(X).SSIM(1+RGB) = ssim(Orig_Im(:,:,RGB),Im(:,:,RGB,X));
        else
            Assessment(X).SSIM(1+RGB) = NaN;
        end
        
    end
    
    if SSIM == 1         % ���� ������ ����������, �� �������
        return;
    end
    
    Assessment(X).MAE(1) = sum(MAE)/size(Im,3);      % ��������� ��������� ��������
    Assessment(X).NAE(1) = sum(NAE)/size(Im,3);
    Assessment(X).MSE(1) = sum(MSE)/size(Im,3);
    Assessment(X).NMSE(1) = sum(NMSE)/size(Im,3);
    Assessment(X).SNR(1) = sum(SNR)/size(Im,3);
    Assessment(X).PSNR(1) = sum(PSNR)/size(Im,3);  
    
    if SSIM == 2
        [Assessment(X).SSIM(1), Assessment(X).SSIM_Image] = ssim(Orig_Im,Im(:,:,:,X));
        Assessment(X).SSIM_Image = uint8(127.5*Assessment(X).SSIM_Image + 127.5);
    elseif SSIM == 0
        Assessment(X).SSIM(1) = NaN;
        Assessment(X).SSIM_Image = zeros(size(Im,1),size(Im,2),size(Im,3));
    end
    
end


% ������� ������ ������������ ��������
function phi = invmoments(F)
    
if ( ~ismatrix(F) || issparse(F) || ~isreal(F) || ~(isnumeric(F)) || islogical(F) )
    error('����������� �� ��������!');
end

F = double(F);
phi = compute_phi(compute_eta(compute_m(F)));


% ���������� ��� ������� ������������ ��������
function m = compute_m(F)
    
[M, N] = size(F);
[x, y] = meshgrid(1:N,1:M);

x = x(:);
y = y(:);
F = F(:);

m.m00 = sum(F);

if (m.m00 == 0)     % ������ �� ������� �� ����
    m.m00 = eps;
end

% ����������� �������
m.m10 = sum(x .* F);
m.m01 = sum(y .* F);
m.m11 = sum(x .* y .* F);
m.m20 = sum(x.^2 .* F);
m.m02 = sum(y.^2 .* F);
m.m30 = sum(x.^3 .* F);
m.m03 = sum(y.^3 .* F);
m.m12 = sum(x .* y.^2 .*F);
m.m21 = sum(x.^2 .* y .* F);


% ���������� ��� ������� ������������ ��������
function e = compute_eta(m)

xbar = m.m10 / m.m00;
ybar = m.m01 / m.m00;

e.eta11 = (m.m11 - ybar*m.m10) / m.m00^2;
e.eta20 = (m.m20 - xbar*m.m10) / m.m00^2;
e.eta02 = (m.m02 - ybar*m.m01) / m.m00^2;
e.eta30 = (m.m30 - 3*xbar*m.m20 + 2*xbar^2 * m.m10) / m.m00^2.5 ;
e.eta03 = (m.m03 - 3*ybar*m.m02 + 2*ybar^2 * m.m01) / m.m00^2.5 ;
e.eta21 = (m.m21 - 2*xbar*m.m11 - ybar*m.m20 + 2*xbar^2 * m.m01) / m.m00^2.5;
e.eta12 = (m.m12 - 2*ybar*m.m11 - xbar*m.m02 + 2*ybar^2 * m.m10) / m.m00^2.5;


% ���������� ��� ������� ������������ ��������
function phi = compute_phi(e)

phi(1) = e.eta20 + e.eta02;
phi(2) = (e.eta20 - e.eta02)^2 + 4*e.eta11^2;
phi(3) = (e.eta30 - 3*e.eta12)^2 + (3*e.eta21 - e.eta03)^2;
phi(4) = (e.eta30 + e.eta12)^2 + (e.eta21 + e.eta03)^2;

phi(5) =    (e.eta30 - 3*e.eta12)*(e.eta30 + e.eta12)*...   
            ( (e.eta30 + e.eta12)^2 - 3*(e.eta21 + e.eta03)^2 ) + ...
            (3*e.eta21 - e.eta03)*(e.eta21 + e.eta03)*...
            (3*(e.eta30 + e.eta12)^2 - (e.eta21 + e.eta03)^2);

phi(6) =    (e.eta20 - e.eta02)*...
            ( (e.eta30 + e.eta12)^2 - (e.eta21 + e.eta03)^2 ) + ...
            4*e.eta11*(e.eta30 + e.eta12)*(e.eta21 + e.eta03);

phi(7) =    (3*e.eta21 - e.eta03)*(e.eta30 + e.eta12)*...
            ( (e.eta30 + e.eta12)^2 - 3*(e.eta21 + e.eta03)^2) + ...
            (3*e.eta12 - e.eta30)*(e.eta21 + e.eta03)*...
            ( 3*(e.eta30 + e.eta12)^2 - (e.eta21 + e.eta03)^2);
    

% ������� ������� ������, ��������� �� "number" �����
function NumbersOfImages = createSTR (number,ImageOrNot)

NumbersOfImages = cell(1,number);

for k = 1:number
    
    if ImageOrNot == 1
        NumbersOfImages{k} = ['����������� � ' num2str(k)];
    else
        NumbersOfImages{k} = ['����� � ' num2str(k)];
    end
        
end


% ������� �������� ����������� � �����
function ClipboardCopyImage(Image)
    
    % ���� 1920�1080 �� ���� ��� ����� �� ����� ���� ������ ����������,
    % ����� ������ 22 ������� ������ (����� � �� ����� ��)

res = get(0, 'ScreenSize');         % ��������� ���������� ������
w = size(Image,2);                  % ������ ��������
h = size(Image,1);                  % � �� ������
res(4) = res(4) - 22;           % ������� ������
M = w/res(3);                   % ������, ��������� ����� ������� �����������
N = h/res(4);                   % ������, ��������� ����� ���� �����������

if floor(M) == 0 && floor(N) == 0     % ����� ������� � ���� ��������
    new_w = w;
    new_h = h;
    
else    % ����� ���� ���� �� ������ ��� ��� ������, ��� ������� ������
        % �������, ��� ������, � ��������� ��� ���
        
    if M > N               % ������ ������ ��� �����  
        new_h = round(h/(w/res(3)));   %     
        new_w = res(3);
        
    elseif N > M            % ���� ��� ������
        new_h = res(4);
        new_w = round(w/(h/res(4)));   %   
      
    elseif N == M 
        new_w = w;
        new_h = h;        
    end
end

% ����������� ������� ��� ����
H = figure('Position',[1 1 new_w new_h],'Menubar','none','Toolbar','none','Visible','off');
H_axes = axes('Position',[0 0 1 1]);     % ��� �� ��� ����
imshow(Image,'Border','tight','Parent',H_axes);
hgexport(H,'-clipboard');  
close(H);


% ������� �������� ������ � ����� ��� �����������
function ClipboardCopyObject(ObjHandle,X_indent)

% ������� ������
ObjPos = get(ObjHandle,'Position');

switch get(ObjHandle,'type')
    
    case 'axes'         % ��� ���� ���� �������� ������� ����� � ����� ��� �������
                 
        ObjPos(1) = 50 + X_indent;
        ObjPos(2) = 50; 
        FigPos(3) = ObjPos(3) + 80 + X_indent;
        FigPos(4) = ObjPos(4) + 100;
        
    case 'uicontrol'    % ���� �������� ����������
        
        switch  get(ObjHandle,'style')
            case 'listbox'  % � ������
                
                str = get(ObjHandle,'String');
                Width = length(str{1});         % �������� ������ �������� ������
                
                for x = 1:size(str,1)
                    if length(str{x}) > Width
                        Width = length(str{x});
                    end
                end
                
                ObjPos(4) = 16 * size(str,1);    % ��������� ������ ������/������
                ObjPos(3) = 8 * Width;
                
                FigPos(1) = 1;      % ������ ������� ����
                FigPos(2) = 1;
                FigPos(3) = ObjPos(3);
                FigPos(4) = ObjPos(4);
                
                H = figure('Visible','on','Position',[50 50 FigPos(3) FigPos(4)]);
                
                text(1,1,str,'FontName','Courier New');
                set(gca,'XLim',[1 ObjPos(3)],...
                        'YLim',[-ObjPos(4)/2 ObjPos(4)/2],...
                        'Units','pixels',...
                        'Position',[1 1 ObjPos(3) ObjPos(4)],...
                        'XColor',[1 1 1],...
                        'YColor',[1 1 1]);
                
                hgexport(H,'-clipboard');                     % �������� ������ � �����
                close(H);
                
                return;
                
        end 
        
    case 'uitable'       % ��� ������
        
        ObjPos(1) = 1;
        ObjPos(2) = 1;    
        FigPos = ObjPos;
end

% ���� ����� �������, ����� ������� �� ��������� ��� !!!!
H = figure('Visible','on','Position',[50 50 FigPos(3) FigPos(4)],'Menubar','none','Toolbar','none');  

Object = copyobj(ObjHandle,H);            % �������� ������ � ����� ����

set(Object,'Position',ObjPos)  % ������ ����� ��������� ���� � ����� ����
hgexport(H,'-clipboard');                     % �������� ������ � �����
close(H);


% ������� ��������� ������
function SaveObjectAsImage(ObjHandle,FileName)
    
switch get(ObjHandle,'type')    % �� ���� ����������� � ���� ������� ���������� �������
    
    case 'axes'                 % ��� ���� 
        
        H = figure('Visible','off','Position',[0 0 500 300]);    % ������� ����, ������� �������� ��� ��������
        
        set(H,  'PaperUnits','points',...               % ���������� ������� ��� ������
                'PaperPosition',[0 0 500 300]);         % ������ ������� �� ������
            
        ObjPosition = [50 20 430 250];
        
    case 'uitable'              % ��� ������ 
        
        ObjPosition = get(ObjHandle,'Position');        % ������ �������
        ObjPosition (1) = 1;
        ObjPosition (2) = 1; 
        
        % ������� ����, ������� �������� ��� ��������
        H = figure('Visible','on','Position',ObjPosition);    

        set(H,  'PaperUnits','points',...                           % ���������� ������� ��� ������
                'PaperPosition',[0 0 ObjPosition(3)*0.75 ObjPosition(4)*0.75]);   % ������ ������� �� ������       
end

Obj = copyobj(ObjHandle,H); 
set(Obj,'Position',ObjPosition);        % ������ ������� ���� � ��������

saveas(H,FileName);            % ��������� ��� ��������
close(H);    
    

% ������� ���������� ����������� ����������� �����
function Value = PointResolution(row,point,ResLevel)
    
assert(point < length(row) || point >= 1,...
    ['����� (point = ' num2str(point) ') �� ����������� ������ row']);
assert(isnumeric(row),'row ����� �� �������');
assert(isnumeric([point ResLevel]),'point � ResLevel - �� �����');

Value = 0;                          % ���������� �� = 0

% ����  ������ � ������� ����� ��� ������ ������
if  point == 1 ||...        
    point == length(row) ||...
    row(point) <= row(point-1) ||...
    row(point) <= row(point+1)
                
    return;         % ������ ������ ���������� ��
end

for up = point+1:length(row)        % ���� ����� �� �����
    
    if row(up) < ResLevel           % ���� ���� ������
        break;                      % �������
    else
        Value = Value+1;            % ����� +1 � ��
    end
end

for down = point-1:-1:1             % ���� ����
    if row(down) < ResLevel         % ���� ���� ������
        break;                      % �������
    else
        Value = Value+1;            % ����� +1 � ��
    end
end

% ���� ����� �� ������/����� ������, ����� ������ ���������� ��
if down == 1 || up == length(row)          
    Value = 0;
    return;
end

Value = Value+1;    % ���� ����� ��������� �������� ��
    

% ������� ���������� ������������ ��� ��� �����������/�����������
function NewPosition = ChangeAxesPosition(Position,whatfor)
    
assert( size(Position,1) == 1 && size(Position,2) == 4,...
        '������� ������ ���������� ������������ ���� "Position"');

switch whatfor
    case 'ForHist'
        
        NewPosition(1) = Position(1) + 40;
        NewPosition(2) = Position(2) + 20;
        NewPosition(3) = Position(3) - 50;
        NewPosition(4) = Position(4) - 60;
        
    case 'ForImage'
        
        NewPosition(1) = Position(1) - 40;
        NewPosition(2) = Position(2) - 20;
        NewPosition(3) = Position(3) + 50;
        NewPosition(4) = Position(4) + 60;
        
    otherwise        
        
        assert(0,'����� ������� ��������� ������� � ������������� "whatfor"');
end


% �������, ������� ������ ����� ���� � ���� �� ������ ������
function Ax = NewFigureWihAxes()

scr_res = get(0, 'ScreenSize');                 % ��������� ���������� ������
figure( 'Color',[1 1 1],'NumberTitle','off',...
        'Position',[(scr_res(3)-700)/2 (scr_res(4)-400)/2 700 400]);

Ax = axes('Units','pixels','Position',[50 30 620 320]);


% �������, ������� ������ ����������� � �������� ����
function ObjectHandle = BuildHist(ax,Image,title_str)

% ��������� ������� ������� � �����������
% � ��������� ���� ��� ������� ������ 

assert(size(Image,3) ~= 2 && size(Image,4) == 1,'Image �� �������� ������������');

switch size(Image,3)
    case 1      % �����
        color = [0 0 0];
        
    case 3      % RGB
        color = [1 0 0; 0 1 0; 0 0 1];
        
    otherwise   % �������������� �����������
        color = colormap(gcf,hsv(size(Image,3))); 
end

if any(Image(:) < 0)        % ���� ���� ������������� �������� (��� ���������� ����)
    nbins = 511;
    binlims = [-255 255];
else
    nbins = 256;
    binlims = [0 255];
end

for ch = 1:size(Image,3)
    ObjectHandle(ch) = histogram(   ax,...
                                    Image(:,:,ch),...
                                    'DisplayStyle','stairs',...
                                    'NumBins',nbins,...
                                    'BinLimits',binlims,...
                                    'EdgeColor',color(ch,1:3)); 
    hold(ax,'on');
end

if any(Image(:) < 0)        % ���� ���� ������������� ��������
    xlim(ax,[-270 270]); 
else
    xlim(ax,[-10 270]);
end

hold(ax,'off');
title(ax,title_str);


% �������, ����������� ����������� �������������� �������� �����������
function texture = statxture(Image,scale)
% texture - ������� �� 6 ���������: �������� ��������, ���, ���������,
% �������� �������, ������������ � ��������
% ��������, ����: �. 610-611

if nargin == 1
    scale = ones(1,6);
else
    assert(length(scale(:)) == 6,'Scale ������� �� �� 6 ���������');
    scale = scale(:)';
end

p = imhist(Image);
p = p./numel(Image);
L = length(p);

[~, mu] = statmoments(p,3);
texture(1) = mu(1);
texture(2) = mu(2).^0.5;

varn = mu(2)/(L-1)^2;

texture(3) = 1 - 1/(1 + varn);
texture(4) = mu(3)/(L - 1)^2;
texture(5) = sum(p.^2);
texture(6) = -sum(p.*(log2(p + eps)));
texture = texture.*scale;


% �������, ����������� n ����. ����������� �������� ����������� p �����������
function [v, unv] = statmoments(p,n)
% ��������, ����: �. 609-610

if length(p) ~= 256
    error('p ������ �������� 256 ���������');
end

G = length(p)-1;
p = p/sum(p);
p = p(:);

z = 0:G;
z = z./G;
m = z*p;
z = z - m;
v = zeros(1,n);
v(1) = m;
for j = 2:n
    v(j) = (z.^j)*p;
end

if nargout > 1
    unv = zeros(1,n);
    unv(1) = m.*G;
    for j = 2:n
        unv(j) = ((z*G).^j)*p;
    end
end


% �������, ������������� ���. � ����. ������� ����� ���������� � �������������� ����
function [MinMask,MaxMask] = SuppressMaskRecount(BW,Theta0,Theta1,ThetaStep,RhoStep)

assert(size(BW,3) == 1,'�� ���� ������ �� ����������� �����������');
assert(size(BW,4) == 1,'�� ���� ������ �� �����������');
assert(isnumeric([Theta0 Theta1 ThetaStep RhoStep]),'�� ���� ������ �� �����');

Rho = -norm(size(BW)):RhoStep:norm(size(BW));
Theta = Theta0:ThetaStep:Theta1;

MinMask(1) = 1;     % ���. �������� ������� ����� ����������
MinMask(2) = 1;     % ���. �������� ������� ����� ����������

MaxMask(1) = round(length(Rho)/2);
MaxMask(2) = round(length(Theta)/2);
MaxMask(1) = MaxMask(1) - mod(MaxMask(1),2) - 1;  % ������������ ������ ����� ���������� ��������
MaxMask(2) = MaxMask(2) - mod(MaxMask(2),2) - 1;  % ������������ ������ ����� ���������� ��������

MaxMask(MaxMask < 2) = 3;


% �������, �������� �� ������ 2D �������� �����������
function BW = getBW(Image)

% ���� Image �������� �������� (������ 0 � ����. ��������), ����� ������
% ����������� ��� � ���� 0 � 1; ����� �������� ����������� ���;
% ���� ��� ������ Image ���������, ����� ����������� BW ����� 2D, �����
% ����� ��������� size(Image,3)-������ ������ ���������� �����������

Image(Image == max(Image(:))) = 1;

if any(Image(:) ~= 0 & Image(:) ~= 1)        % ���� ��� �� ���������� ������, �������� ����������� �� ���
    
    if size(Image,3) > 3            % ��� �������������� �����������
        
        BW = zeros(size(Image));
        for ch = 1:size(Image,3)    % ������������ ������ ����� ��� �����������
            BW(:,:,ch) = im2bw(Image(:,:,ch),graythresh(Image(:,:,ch)));
        end
        
    else                            % ��� ����������� � RGB
        BW(:,:) = im2bw(Image,graythresh(Image));
    end
    
else                        % ���� ��� ����� ���������� ������
    
    if size(Image,3) == 1   % � ���� ��� 2D ���������� ������
        BW = Image;     	% ������ �������� ���
    else                    % ����� ���������� ������ ����� �����
        
        equal = true;       % ������� �� ���������� �������
        for ch = 1:size(Image,3)-1
            if ~isequal(Image(:,:,ch),Image(:,:,ch+1))
                equal = false;  % ��� ������ ����� ��������
                break;
            end            
        end
        
        if equal
            BW = Image(:,:,1);  % ������ �������� ������ �����
        else
            BW = Image;     	% ������ �������� ��� ������
        end
    end
end


% �������, ������������� ���������������� ���� �����
function SWC = SpacialWeightCount(MaskSize)

SWC = zeros(MaskSize^2,1);      % ������-������� �� ���������� �����
center = (MaskSize + 1)/2;
z = 1;

for x = 1:MaskSize
    for y = 1:MaskSize
        SWC(z) = abs(center - x) + abs(center - y);
        z = z + 1;
    end
end


% �������, ����������� ����������� � ������� XLSX
function SaveHistAsXLSX(ax,FileName)

Hist_Data = get(findobj('Parent',ax,'DisplayStyle','stairs'));

assert(~isempty(Hist_Data),'�� ����� � �������� ���� ������ ���������� �� ��������� ����������� ���������');

Data = zeros(size(Hist_Data,1)+1,Hist_Data(1).NumBins);
Ticks = cell(size(Hist_Data,1)+1,1);

for x = 1:size(Hist_Data,1)
    Data(x,:) = Hist_Data(x).Values;
    Ticks{x,1} = ['����� � ' num2str(x)];
end

Data(end,:) = Hist_Data(x).BinLimits(1):Hist_Data(x).BinLimits(2);
Ticks{end} = '�������� �������';

xlswrite(FileName,Ticks,1);
xlswrite(FileName,Data,1,'B1');


% �������, �������� ���������� ����� ����������
function points = GetCirclePoints(center_x,center_y,R,Image)

phi = 1:180/(2*R*pi):360;           % ������� ����������
points_x = center_x + R*cosd(phi);
points_y = center_y + R*sind(phi);

points_x = round(points_x);     % ���������
points_y = round(points_y);

% �������� �� ����� �� ������� �����������. �� ������ ������� x � y!!!! 
points_y( points_x > size(Image,2) | points_x < 1 ) = [];      
points_x( points_x > size(Image,2) | points_x < 1 ) = [];

points_x( points_y > size(Image,1) | points_y < 1 ) = [];
points_y( points_y > size(Image,1) | points_y < 1 ) = [];

% �������� � ���� ������
points(:,1) = points_x;
points(:,2) = points_y;

% ������� ������������� ����
points = unique(points,'rows');


% �������, ����������� �������� ����������� �����
function OpenImageOutside(Image)

global format;

% ��������� �������� � ����� � ��������� �� ������ �������������
% ����� ��������� ������� ����
imwrite(Image,['TempImage.' format]);
winopen(['TempImage.' format]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% ������� "IMAGE ANALYZER" %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ���� ������� ���� "IMAGE ANALYZER"
function RunImageAnalyzer_Callback(hObject, eventdata, ~) %#ok<DEFNU>

global Original;
global Noised;

ImageAnalyzer = openfig('ImageAnalyzer.fig');       % ��������� ����
analyzer_handles = guihandles(ImageAnalyzer);       % ��������� ��������� �� ��� �������

scr_res = get(0, 'ScreenSize');             % ��������� ���������� ������ � ����
fig = get(ImageAnalyzer,'Position');        % ������ ������� ����

set(ImageAnalyzer,'Position',[(scr_res(3)-fig(3))/2 (scr_res(4)-fig(4))/2 fig(3) fig(4)]);    
set(ImageAnalyzer,'CloseRequestFcn','delete(gcf);');

% ��������� ������� � ������
set(analyzer_handles.ImageMenu,'Callback',{@ImageMenu_Callback,analyzer_handles});
set(analyzer_handles.NumderImageMenu,'Callback',{@ImageMenu_Callback,analyzer_handles});
set(analyzer_handles.ChannelImageMenu,'Callback',{@ImageMenu_Callback,analyzer_handles});

set(analyzer_handles.X1_Slider,'Callback',{@X1_Slider_Callback,analyzer_handles});
set(analyzer_handles.X0_Slider,'Callback',{@X0_Slider_Callback,analyzer_handles});
set(analyzer_handles.Y1_Slider,'Callback',{@Y1_Slider_Callback,analyzer_handles});
set(analyzer_handles.Y0_Slider,'Callback',{@Y0_Slider_Callback,analyzer_handles});

set(analyzer_handles.RowSlider,'Callback',{@ImageMenu_Callback,analyzer_handles});
set(analyzer_handles.StringSlider,'Callback',{@ImageMenu_Callback,analyzer_handles});

set(analyzer_handles.ResLevelSlider,'Callback',{@ResLevelSlider_Callback,analyzer_handles});

set(analyzer_handles.X0,'Callback',{@XY_Callback,analyzer_handles});
set(analyzer_handles.X1,'Callback',{@XY_Callback,analyzer_handles});
set(analyzer_handles.Y0,'Callback',{@XY_Callback,analyzer_handles});
set(analyzer_handles.Y1,'Callback',{@XY_Callback,analyzer_handles});
set(analyzer_handles.RowNumberText,'Callback',{@XY_Callback,analyzer_handles});
set(analyzer_handles.StringNumberText,'Callback',{@XY_Callback,analyzer_handles});

set(analyzer_handles.CopyAreaMenu,'Callback',{@CopyAreaMenu_Callback,analyzer_handles});
set(analyzer_handles.SaveAreaMenu,'Callback',{@SaveAreaMenu_Callback,analyzer_handles});
set(analyzer_handles.SaveAreaRGBMenu,'Callback',{@SaveAreaRGBMenu_Callback,analyzer_handles});
set(analyzer_handles.ViewAreaRGBMenu,'Callback',{@ViewAreaRGBMenu_Callback,analyzer_handles});
set(analyzer_handles.ViewAreaMonoMenu,'Callback',{@ViewAreaMonoMenu_Callback,analyzer_handles});

set(analyzer_handles.ROIRadioButton,'Callback',{@ROIorSpectre_Callback,analyzer_handles});
set(analyzer_handles.SpectreRadioButton,'Callback',{@ROIorSpectre_Callback,analyzer_handles});

set(analyzer_handles.CopyHist,'Callback',{@CopyHist_Callback,analyzer_handles});
set(analyzer_handles.SaveHist,'Callback',{@SaveHist_Callback,analyzer_handles});
set(analyzer_handles.SaveAssessmentTXT,'Callback',{@SaveAssessmentTXT_Callback,analyzer_handles});
set(analyzer_handles.SaveAssessmentXLSX,'Callback',{@SaveAssessmentXLSX_Callback,analyzer_handles});

% ���� �������� ����������� �������� ������ ���� �����, ���������
% ����������� ����

if size(Original,3) == 1
    set(analyzer_handles.SaveAreaRGBMenu,'Enable','off');
    set(analyzer_handles.ViewAreaRGBMenu,'Enable','off');
else
    set(analyzer_handles.SaveAreaRGBMenu,'Enable','on');
    set(analyzer_handles.ViewAreaRGBMenu,'Enable','on');    
end

% ������������� ����, �������� � ��������� 

if isempty(Noised) == 1
    set(analyzer_handles.ImageMenu,'String','�������� �����������');
else
    set(analyzer_handles.ImageMenu,'String',...
    {'�������� �����������';'����������� �����������';'��������������� �����������'});
end

set(analyzer_handles.ImageMenu,'Value',1);
set(analyzer_handles.NumderImageMenu,'Value',1,'String','����������� � 1');
set(analyzer_handles.ChannelImageMenu,'Value',1,'String',createSTR(size(Original,3),0));

set(analyzer_handles.X0_Slider,'Min',1,'Max',size(Original,2),...
    'Value',1,'SliderStep',[1/(size(Original,2)-1) 10/(size(Original,2)-1)]);

set(analyzer_handles.X1_Slider,'Min',1,'Max',size(Original,2),...
    'Value',size(Original,2),'SliderStep',[1/(size(Original,2)-1) 10/(size(Original,2)-1)]);

set(analyzer_handles.RowSlider,'Min',1,'Max',size(Original,2),...
   'Value',1,'SliderStep',[1/(size(Original,2)-1) 10/(size(Original,2)-1)]);

% �������� ������� �� ������ "-" ��� �������� ������, ����� ����� ��������
% �� ����������� � ���������
set(analyzer_handles.Y0_Slider,'Max',-1,'Min',-size(Original,1),...
                'Value',-1,'SliderStep',[1/(size(Original,1)-1) 10/(size(Original,1)-1)]);

set(analyzer_handles.Y1_Slider,'Max',-1,'Min',-size(Original,1),...
    'Value',-size(Original,1),'SliderStep',[1/(size(Original,1)-1) 10/(size(Original,1)-1)]);

set(analyzer_handles.StringSlider,'Max',-1,'Min',-size(Original,1),...
               'Value',-1,'SliderStep',[1/(size(Original,1)-1) 10/(size(Original,1)-1)]);
           

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

Image = Original(:,:,1);

% ��������� ���������� ����� (Y-�� � ���������)
Y0 = -(round(get(analyzer_handles.Y0_Slider,'Value')));
Y1 = -(round(get(analyzer_handles.Y1_Slider,'Value')));
X0 = round(get(analyzer_handles.X0_Slider,'Value'));
X1 = round(get(analyzer_handles.X1_Slider,'Value'));
Xrow = round(get(analyzer_handles.RowSlider,'Value'));
Ystring = -round(get(analyzer_handles.StringSlider,'Value'));
    

% ������� ��� ������� �����, � �������-��������� ����� �� ������ ���������
Area = imshow(Original(:,:,1),'Parent',analyzer_handles.AreaAxes);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Hist = BuildHist(analyzer_handles.AreaAxesHist,Image(Y0:Y1,X0:X1),'�����������');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
ResLevel = double(Image(Ystring,Xrow)*get(analyzer_handles.ResLevelSlider,'Value'));

    
line(0:X1-X0+2,ones(1,X1-X0+3)*(Ystring-Y0+1),'Color','g','LineStyle','--','LineWidth',1.5,'Parent',analyzer_handles.AreaAxes);
line(ones(1,Y1-Y0+3)*(Xrow-X0+1),0:Y1-Y0+2,'Color','m','LineStyle','--','LineWidth',1.5,'Parent',analyzer_handles.AreaAxes);
 
bar(X0:X1,Original(Ystring,X0:X1,1),0.4,'Parent',analyzer_handles.RowAxes);
xlim(analyzer_handles.RowAxes,[X0-1 X1+1]);
ylim(analyzer_handles.RowAxes,[0 260]);

line(X0-1:X1+1,ones(1,X1-X0+3)*ResLevel,'Color','r','LineWidth',1.5,'Parent',analyzer_handles.RowAxes);
line(ones(1,256)*Xrow,1:256,'Color','m','LineWidth',1.5,'LineStyle','--','Parent',analyzer_handles.RowAxes);
title(analyzer_handles.RowAxes,['�������� ������� �������� � ������ � ' num2str(Ystring)],'FontSize',12);

% ������ ������ �������
bar(Y0:Y1,Original(Y0:Y1,Xrow,1),0.4,'Parent',analyzer_handles.ColAxes);
xlim(analyzer_handles.ColAxes,[Y0-1 Y1+1]);
ylim(analyzer_handles.ColAxes,[0 260]);

line(Y0-1:Y1+1,ones(1,Y1-Y0+3)*ResLevel,'Color','r','LineWidth',1.5,'Parent',analyzer_handles.ColAxes);
line(ones(1,256)*Ystring,1:256,'Color','g','LineWidth',1.5,'LineStyle','--','Parent',analyzer_handles.ColAxes);
title(analyzer_handles.ColAxes,['�������� ������� �������� � ������� � ' num2str(Xrow)]);
    
% ������ ����������� ����
set(Area,'UIContextMenu',analyzer_handles.AreaContextMenu);  
set(Hist,'UIContextMenu',analyzer_handles.HistContextMenu);   

% title(analyzer_handles.AreaAxesHist,{'����������� ������� ��������';''});
xlim(analyzer_handles.AreaAxesHist,[0 260]);          

% ������ ���������
ImageMenu_Callback(hObject, eventdata, analyzer_handles);

% ������ ���� ���������
set(ImageAnalyzer,'Visible','on','WindowStyle','modal');


% �������-���������, �� ������� ��������� ��� ���������
function ImageMenu_Callback(hObject, ~, analyzer_handles)

global Original;            % �������� �����������
global Noised;              % ����������� �������
global Filtered;            % ��������������� �����������

try     % ��� ������ �������� � �������� - �������� ��������� �� �������, � ���� �� �����

    % ���� ������� � ����
    Area = findobj('Parent',analyzer_handles.AreaAxes,'-not','LineWidth',1.5);
    RowOnArea = findobj('Parent',analyzer_handles.AreaAxes,'Color','g');
    ColOnArea = findobj('Parent',analyzer_handles.AreaAxes,'Color','m');

    RowGraph = findobj('Parent',analyzer_handles.RowAxes,'BarWidth',0.4);
    RowGraphFirstLine = findobj('Parent',analyzer_handles.RowAxes,'Color','r');
    RowGraphSecondLine = findobj('Parent',analyzer_handles.RowAxes,'Color','m');

    ColGraph = findobj('Parent',analyzer_handles.ColAxes,'BarWidth',0.4);
    ColGraphFirstLine = findobj('Parent',analyzer_handles.ColAxes,'Color','r');
    ColGraphSecondLine = findobj('Parent',analyzer_handles.ColAxes,'Color','g');

    Hist = findobj('Parent',analyzer_handles.AreaAxesHist,'EdgeColor','k');


    switch get(analyzer_handles.ImageMenu,'Value')

        case 1  % �������� �����������

            set(analyzer_handles.NumderImageMenu,'String','����������� � 1','Value',1);
            Image = Original(:,:,get(analyzer_handles.ChannelImageMenu,'Value'));

        case 2  % ����������� �����������

            set(analyzer_handles.NumderImageMenu,'String',createSTR(size(Noised,4),1));
            Image = Noised(:,:,get(analyzer_handles.ChannelImageMenu,'Value'),...
                get(analyzer_handles.NumderImageMenu,'Value'));

        case 3  % ��������������� �����������

            set(analyzer_handles.NumderImageMenu,'String',createSTR(size(Filtered,4),1));
            Image = Filtered(:,:,get(analyzer_handles.ChannelImageMenu,'Value'),...
                get(analyzer_handles.NumderImageMenu,'Value'));
    end

    % ��������� �������� ����������� ���������
    Y0 = -(round(get(analyzer_handles.Y0_Slider,'Value')));  % ��������� ���������� ����� (Y-�� � ���������)
    Y1 = -(round(get(analyzer_handles.Y1_Slider,'Value')));
    X0 = round(get(analyzer_handles.X0_Slider,'Value'));
    X1 = round(get(analyzer_handles.X1_Slider,'Value'));
    Xrow = round(get(analyzer_handles.RowSlider,'Value'));
    Ystring = -round(get(analyzer_handles.StringSlider,'Value'));
    ResLevel = double(round(Image(Ystring,Xrow)*get(analyzer_handles.ResLevelSlider,'Value')));
    set(analyzer_handles.text7,'String',[num2str(get(analyzer_handles.ResLevelSlider,'Value')) ' ('  num2str(ResLevel) ')']);

    % ����� ����� � ������
    set(analyzer_handles.X0,'String',num2str(X0));
    set(analyzer_handles.Y0,'String',num2str(Y0));
    set(analyzer_handles.X1,'String',num2str(X1));
    set(analyzer_handles.Y1,'String',num2str(Y1));


    % ���� �� ��� ������� �������, ����� ���������� ����������� -
    % �� ��������� �������, ��� �� ���� ������ ��������
    if hObject ~= analyzer_handles.StringSlider &&...
            hObject ~= analyzer_handles.RowSlider &&...
            hObject ~= analyzer_handles.ResLevelSlider

        % �� ��������� �����������
        switch get(analyzer_handles.ROIRadioButton,'Value')     % ������ ������� ��������
            case 1
                set(Area,'CData',Image(Y0:Y1,X0:X1));

            case 0
                Spectre = fft2(Image(Y0:Y1,X0:X1));     % ������� ������ ������� ��������
                Spectre = fftshift(Spectre);            % �����������
                Spectre = abs(Spectre);                 % ������� ������
                SpectreImage = log(1 + Spectre);        % ������� � ��������. �����, ����� ���� �����
                SpectreImage = uint8(SpectreImage*255/max(SpectreImage(:))); % ������� � 8 ��� � ����������

                set(Area,'CData',SpectreImage);                             % �������� � ��� ������
                setappdata(analyzer_handles.AreaAxes,'Spectre',Spectre);    % ��������� ��
        end
    end


    % ����������� ������� �����/�������� �� ��������� �����������
    switch get(analyzer_handles.ROIRadioButton,'Value')

        case 1      % ��� ������� ��������

            % ���� ����� ������������� ������� ������� � ������
            if hObject ~= analyzer_handles.ResLevelSlider

                % ����������� ��������� ������
                set(analyzer_handles.RowNumberText,'String',num2str(Xrow));
                set(analyzer_handles.StringNumberText,'String',num2str(Ystring));

                % ������ ������ ������
                set(RowGraph,'XData',X0:X1,'YData',Image(Ystring,X0:X1));
                xlim(analyzer_handles.RowAxes,[X0-1 X1+1]);
                set(RowGraphSecondLine,'XData',ones(1,256)*Xrow);
                ylim(analyzer_handles.RowAxes,[0 260]);
                title(analyzer_handles.RowAxes,['�������� ������� �������� � ������ � ' num2str(Ystring)]);

                % ������ ������ �������
                set(ColGraph,'XData',Y0:Y1,'YData',Image(Y0:Y1,Xrow));
                xlim(analyzer_handles.ColAxes,[Y0-1 Y1+1]);
                set(ColGraphSecondLine,'XData',ones(1,256)*Ystring);
                ylim(analyzer_handles.ColAxes,[0 260]);
                title(analyzer_handles.ColAxes,['�������� ������� �������� � ������� � ' num2str(Xrow)]);

            end

            % ����� �������� ������ ������. �����������
            set(ColGraphFirstLine,'XData',Y0-1:Y1+1,'YData',ones(1,Y1-Y0+3)*ResLevel,'Visible','on');
            set(RowGraphFirstLine,'XData',X0-1:X1+1,'YData',ones(1,X1-X0+3)*ResLevel,'Visible','on');


        case 0        % ��� �� �������

            Spectre = getappdata(analyzer_handles.AreaAxes,'Spectre');

            % ����������� ��������� ������
            set(analyzer_handles.RowNumberText,'String',num2str(Xrow-X0+1));
            set(analyzer_handles.StringNumberText,'String',num2str(Ystring-Y0+1));

            % ������ ������ ������
            set(RowGraph,'XData',1:size(Spectre,2),'YData',Spectre(Ystring-Y0+1,:));
            xlim(analyzer_handles.RowAxes,[1 size(Spectre,2)]);
            ylim(analyzer_handles.RowAxes,[0 max(Spectre(Ystring-Y0+1,:))]);
            title(analyzer_handles.RowAxes,['������ �������� ������� � ������ � ' num2str(Ystring-Y0+1)]);

            % ������ ������ �������
            set(ColGraph,'XData',1:size(Spectre,1),'YData',Spectre(:,Xrow-X0+1));
            xlim(analyzer_handles.ColAxes,[1 size(Spectre,1)]);
            ylim(analyzer_handles.ColAxes,[0 max(Spectre(:,Xrow-X0+1))]);
            title(analyzer_handles.ColAxes,['������ �������� ������� � ������� � ' num2str(Xrow-X0+1)]);

            % ����� �������� ������ ������. �����������
            set(ColGraphFirstLine,'Visible','off');
            set(RowGraphFirstLine,'Visible','off');
    end

    % ������ ��� �����, ��������������� ��������� ������ � �������
    set(RowOnArea,'XData',0:X1-X0+2,'YData',ones(1,X1-X0+3)*(Ystring-Y0+1));
    set(ColOnArea,'XData',ones(1,Y1-Y0+3)*(Xrow-X0+1),'YData',0:Y1-Y0+2);

    % ������ ������� ����, ���������� ������� ��������, ����� �������������
    % ����������� � ���
    xlim(analyzer_handles.AreaAxes,[1 X1-X0+1.01]);
    ylim(analyzer_handles.AreaAxes,[1 Y1-Y0+1.01]);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ������ ����������� ������� ��������
    set(Hist,'Data',Image(Y0:Y1,X0:X1));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % ��������� ���������
    drawnow();

    if get(analyzer_handles.SpectreRadioButton,'Value')    % ���� ������� ������

        % �� ����������� ������ ������ ��� ������ ������������ � �������
        set([analyzer_handles.AssesmentText analyzer_handles.AssesmentValueText],'String','');
        set(analyzer_handles.text10,'Visible','off');
        return;
    end

    PixBr = Image(Ystring,Xrow);        % ������� �������

    if X0 == X1         % ���� ������ ���� �������, �� � �� �������� ��
        RowRes = 0;
    else                % ������. ����������� � ������
        RowRes = PointResolution(Image(Ystring,X0:X1),Xrow-X0+1,ResLevel);
    end

    if Y0 == Y1         % ���� ������ ������� �������, �� � �� �������� ��
        ColRes = 0;
    else                % ������ ����������� � �������
        ColRes = PointResolution(Image(Y0:Y1,Xrow),Ystring-Y0+1,ResLevel);
    end

    % ��� ���������� �������� ��������, ������� ����� ������ ������
    % ���������

    if      hObject ~= analyzer_handles.StringSlider &&...
            hObject ~= analyzer_handles.RowSlider &&...
            hObject ~= analyzer_handles.ResLevelSlider

        % ����� ������������ ��� ��������������
        Texture = statxture(Image(Y0:Y1,X0:X1));    % �������������� ��������
        InvMoments = abs(log(invmoments(Image(Y0:Y1,X0:X1))));      % ������ ������������ ��������

        % �������� - ��������� ��
        setappdata(analyzer_handles.ImageAnalyzer,'Texture',Texture);
        setappdata(analyzer_handles.ImageAnalyzer,'InvMoments',InvMoments);

    else        % ��� ��������� �������� - ������ ����� � ������ ������� ��������

        % �������� ����� ������������
        Texture = getappdata(analyzer_handles.ImageAnalyzer,'Texture');
        InvMoments = getappdata(analyzer_handles.ImageAnalyzer,'InvMoments');

    end

    if get(analyzer_handles.ImageMenu,'Value') == 1     % ���� �������� �����������
        % ����������� ������ � ��������� � ��������� ����
        asses_str = ...
            [ {'�������������� ��������: '};...
            {'�������������������� ����������: '};...
            {'���������: '};...
            {'������ ������: '};...
            {'������������: '};...
            {'��������: '};...
            {'����������� ��������: '};...
            {' '};...
            {'1-� ������������ ������: '};...
            {'2-� ������������ ������: '};...
            {'3-� ������������ ������: '};...
            {'4-� ������������ ������: '};...
            {'5-� ������������ ������: '};...
            {'6-� ������������ ������: '};...
            {'7-� ������������ ������: '};...
            {' '};...
            {'������� ���������� �������: '};...
            {'����������� ����������� � ������: '};...
            {'����������� ����������� � �������: '}];

        asses_val_str = ...
            [{num2str(Texture(1))};...
            {num2str(Texture(2))};...
            {num2str(Texture(3))};...
            {num2str(Texture(4))};...
            {num2str(Texture(5))};...
            {num2str(Texture(6))};...
            {num2str(Texture(2)/Texture(1))};...
            {' '};...
            {num2str(InvMoments(1))};...
            {num2str(InvMoments(2))};...
            {num2str(InvMoments(3))};...
            {num2str(InvMoments(4))};...
            {num2str(InvMoments(5))};...
            {num2str(InvMoments(6))};...
            {num2str(InvMoments(7))};...
            {' '};...
            {num2str(PixBr)};...
            {num2str(RowRes)};...
            {num2str(ColRes)}];

    else        % ���� ������� ����������� ��� ��������������� �����������

        Im = double(Image(Y0:Y1,X0:X1));     % �������� � ����� �������� � �������� �����������
        Orig_Im = double(Original(:,:,get(analyzer_handles.ChannelImageMenu,'Value')));

        Assessment = GetAssessment(Orig_Im(Y0:Y1,X0:X1),Im,1);

        asses_str = ...
            [ {'�������������� ��������: '};...
            {'�������������������� ����������: '};...
            {'���������: '};...
            {'������ ������: '};...
            {'������������: '};...
            {'��������: '};...
            {'����������� ��������: '};...
            {' '};...
            {'MAE: '};...
            {'NAE: '};...
            {'MSE: '};...
            {'NMSE: '};...
            {'SNR, ��: '};...
            {'PSNR, ��: '};...
            {'SSIM: '};...
            {' '};...
            {'1-� ������������ ������: '};...
            {'2-� ������������ ������: '};...
            {'3-� ������������ ������: '};...
            {'4-� ������������ ������: '};...
            {'5-� ������������ ������: '};...
            {'6-� ������������ ������: '};...
            {'7-� ������������ ������: '};...
            {' '};...
            {'������� ���������� �������: '};...
            {'����������� ����������� � ������: '};...
            {'����������� ����������� � �������: '}];

        asses_val_str = ...
            [{num2str(Texture(1))};...
            {num2str(Texture(2))};...
            {num2str(Texture(3))};...
            {num2str(Texture(4))};...
            {num2str(Texture(5))};...
            {num2str(Texture(6))};...
            {num2str(Texture(2)/Texture(1))};...
            {' '};...
            {num2str(Assessment.MAE(2))};...
            {num2str(Assessment.NAE(2))};...
            {num2str(Assessment.MSE(2))};...
            {num2str(Assessment.NMSE(2))};...
            {num2str(Assessment.SNR(2))};...
            {num2str(Assessment.PSNR(2))};...
            {num2str(Assessment.SSIM(2))};...
            {' '};...
            {num2str(InvMoments(1))};...
            {num2str(InvMoments(2))};...
            {num2str(InvMoments(3))};...
            {num2str(InvMoments(4))};...
            {num2str(InvMoments(5))};...
            {num2str(InvMoments(6))};...
            {num2str(InvMoments(7))};...
            {' '};...
            {num2str(PixBr)};...
            {num2str(RowRes)};...
            {num2str(ColRes)}];
    end

    % ����������� ������ ��� ������ ������������
    set(analyzer_handles.text10,'Visible','on');        % ��������� �������������
    set(analyzer_handles.AssesmentText,'String',asses_str,'FontSize',9);
    set(analyzer_handles.AssesmentValueText,'String',asses_val_str,'FontSize',9);

catch    
end


% ������� �0
function X0_Slider_Callback(hObject, eventdata, analyzer_handles)

X0 = round(get(analyzer_handles.X0_Slider,'Value'));    % ����� ����� �� ��������
X1 = round(get(analyzer_handles.X1_Slider,'Value'));    % ��������� ��������-������

if X0 >= X1                                             % ���� ������������ ������ ������ ���������
    set(analyzer_handles.X0_Slider,'Value',X1);         % ������ �������� ������
    set(analyzer_handles.RowSlider,'Enable','off');     % ��������� ������� ������ ������
    
    set(analyzer_handles.RowNumberText,'Enable','off'); % ��������� edit ������
    set(analyzer_handles.RowNumberText,'String',num2str(X1));    % ��������� ������������� ��������
else    
    set(analyzer_handles.X0_Slider,'Value',X0);         % ���� �������� � ��������
    
    set(analyzer_handles.RowSlider,'Enable','on');      % ���������� ������� � edit
    set(analyzer_handles.RowSlider,'Min',X0,'Max',X1,...    % ������������� ����� �������� �������� � edit
               'Value',X0,'SliderStep',[1/(X1-X0) 10/(X1-X0)]);
           
    set(analyzer_handles.RowNumberText,'Enable','on');  % ��������� edit ������
    set(analyzer_handles.RowNumberText,'String',num2str(X0));  % ��������� ��������
end

ImageMenu_Callback(hObject, eventdata, analyzer_handles);


% ������� �1
function X1_Slider_Callback(hObject, eventdata, analyzer_handles)

X0 = round(get(analyzer_handles.X0_Slider,'Value'));
X1 = round(get(analyzer_handles.X1_Slider,'Value'));

if X1 <= X0  
    set(analyzer_handles.X1_Slider,'Value',X0);
    set(analyzer_handles.RowSlider,'Enable','off');
    set(analyzer_handles.RowNumberText,'Enable','off');
    set(analyzer_handles.RowNumberText,'String',num2str(X0));    
else    
    set(analyzer_handles.X1_Slider,'Value',X1);
    set(analyzer_handles.RowSlider,'Enable','on');
    set(analyzer_handles.RowSlider,'Min',X0,'Max',X1,...
               'Value',X0,'SliderStep',[1/(X1-X0) 10/(X1-X0)]);
           
    set(analyzer_handles.RowNumberText,'Enable','on');  % ��������� edit ������
    set(analyzer_handles.RowNumberText,'String',num2str(X1));  % ��������� edit ������
end
           
ImageMenu_Callback(hObject, eventdata, analyzer_handles);


% ������� Y0
function Y0_Slider_Callback(hObject, eventdata, analyzer_handles)

Y0 = -(round(get(analyzer_handles.Y0_Slider,'Value')));
Y1 = -(round(get(analyzer_handles.Y1_Slider,'Value')));

if Y0 >= Y1  
    set(analyzer_handles.Y0_Slider,'Value',-Y1);
    set(analyzer_handles.StringSlider,'Enable','off');
    set(analyzer_handles.StringNumberText,'Enable','off'); % ��������� edit ������
    set(analyzer_handles.StringNumberText,'String',num2str(Y1));    % ��������� ������������� ��������
    
else   
    set(analyzer_handles.Y0_Slider,'Value',-Y0);
    set(analyzer_handles.StringSlider,'Enable','on');
    set(analyzer_handles.StringSlider,'Max',-Y0,'Min',-Y1,...
               'Value',-Y0,'SliderStep',[1/(Y1-Y0) 10/(Y1-Y0)]);
    set(analyzer_handles.StringNumberText,'Enable','on'); % ��������� edit ������
    set(analyzer_handles.StringNumberText,'String',num2str(Y0));    % ��������� ������������� ��������
end
           
ImageMenu_Callback(hObject, eventdata, analyzer_handles);


% ������� Y1
function Y1_Slider_Callback(hObject, eventdata, analyzer_handles)

Y0 = -(round(get(analyzer_handles.Y0_Slider,'Value')));
Y1 = -(round(get(analyzer_handles.Y1_Slider,'Value')));

if Y1 <= Y0  
    set(analyzer_handles.Y1_Slider,'Value',-Y0);
    set(analyzer_handles.StringSlider,'Enable','off');
    set(analyzer_handles.StringNumberText,'Enable','off'); % ��������� edit ������
    set(analyzer_handles.StringNumberText,'String',num2str(Y0));    % ��������� ������������� ��������
else    
    set(analyzer_handles.Y1_Slider,'Value',-Y1);
    set(analyzer_handles.StringSlider,'Enable','on');
    set(analyzer_handles.StringSlider,'Max',-Y0,'Min',-Y1,...
               'Value',-Y0,'SliderStep',[1/(Y1-Y0) 10/(Y1-Y0)]);
           
    set(analyzer_handles.StringNumberText,'Enable','on'); % ��������� edit ������
    set(analyzer_handles.StringNumberText,'String',num2str(Y1));    % ��������� ������������� ��������
end

ImageMenu_Callback(hObject, eventdata, analyzer_handles);


% ������� ������ ��� ����������� ����������� �����������
function ResLevelSlider_Callback(hObject, eventdata, analyzer_handles)

set(analyzer_handles.text7,'String',num2str(get(analyzer_handles.ResLevelSlider,'Value')));
% ������� ���������
ImageMenu_Callback(hObject, eventdata, analyzer_handles);


% ����������� ���� "�������� � ���������" 
function ViewAreaMonoMenu_Callback(hObject, eventdata, analyzer_handles)

% �������� ������� ���� ��� ��������
ViewAreaRGBMenu_Callback(hObject, eventdata, analyzer_handles);


% ����������� ���� "�������� ������������" 
function ViewAreaRGBMenu_Callback(hObject, ~, analyzer_handles)

global Original;            % �������� �����������
global Noised;              % ����������� �������
global Filtered;            % ��������������� �����������

% ������� ���������� ���������
Y0 = -(round(get(analyzer_handles.Y0_Slider,'Value')));
Y1 = -(round(get(analyzer_handles.Y1_Slider,'Value')));
X0 = round(get(analyzer_handles.X0_Slider,'Value'));
X1 = round(get(analyzer_handles.X1_Slider,'Value'));

% ���� ������� � ������ �������, �� ���������� �������� ������ ���� �����
if hObject == analyzer_handles.ViewAreaMonoMenu
    RGB = 1;
else
    RGB = 1:3;
end

% �������� �����������
switch get(analyzer_handles.ImageMenu,'Value')
    
    case 1  % �������� �����������
        
        Image = Original(:,:,RGB);           % ����������, ����� ������������ �����������
        
    case 2  % ����������� �����������
        
        Image = Noised(:,:,RGB,get(analyzer_handles.NumderImageMenu,'Value'));
        
    case 3  % ��������������� �����������
        
        Image = Filtered(:,:,RGB,get(analyzer_handles.NumderImageMenu,'Value'));
end

Image = Image(Y0:Y1,X0:X1,:);  % �������� ��������

try     
    imtool(Image); 
catch
    OpenImageOutside(Image); 
end


% ����������� ���� "����������" 
function CopyAreaMenu_Callback(~, ~, analyzer_handles)

% ���� ������ � ��������� � ���� � ������� ���������� ����
I = findobj('Parent',analyzer_handles.AreaAxes,'UIContextMenu',analyzer_handles.AreaContextMenu);
Image = get(I,'CData');

ClipboardCopyImage(Image);


% ����������� ���� "��������� � ���������"
function SaveAreaMenu_Callback(~, ~, analyzer_handles)

global format;

% ���� ������ � ��������� � ���� � ������� ������c���� ����
I = findobj('Parent',analyzer_handles.AreaAxes,'UIContextMenu',analyzer_handles.AreaContextMenu);
Image = get(I,'CData');

[FileName, PathName] = uiputfile(['*.' format],'��������� ����������� �������� �����������');
if FileName~=0
    imwrite(Image,[PathName FileName],format);
end


% ����������� ���� "��������� ������������"
function SaveAreaRGBMenu_Callback(~, ~, analyzer_handles)

global Original;            % �������� �����������
global Noised;              % ����������� �������
global Filtered;            % ��������������� �����������
global format;

% ������ ����� �������� � ����� �����
[FileName, PathName] = uiputfile(['*.' format],'��������� ������������ �������� �����������');

if FileName ~= 0          % ��� � ���� ����
    switch get(analyzer_handles.ImageMenu,'Value')
        
        case 1  % �������� �����������
            
            Image = Original;           % ����������, ����� ������������ �����������
            
        case 2  % ����������� �����������
            
            Image = Noised(:,:,:,get(analyzer_handles.NumderImageMenu,'Value'));
            
        case 3  % ��������������� �����������
            
            Image = Filtered(:,:,:,get(analyzer_handles.NumderImageMenu,'Value'));
    end
    
    % ������� ���������� ���������
    Y0 = -(round(get(analyzer_handles.Y0_Slider,'Value')));
    Y1 = -(round(get(analyzer_handles.Y1_Slider,'Value')));
    X0 = round(get(analyzer_handles.X0_Slider,'Value'));
    X1 = round(get(analyzer_handles.X1_Slider,'Value'));
    
    
    I = Image(Y0:Y1,X0:X1,:,:);                 % �������� ��������
    
    imwrite(I,[PathName FileName],format);      % ���������
end


% ����������� ���� "���������� �����������" 
function CopyHist_Callback(~, ~, analyzer_handles)

ClipboardCopyObject(analyzer_handles.AreaAxesHist,0); 


% ����������� ���� "��������� �����������"
function SaveHist_Callback(~, ~, analyzer_handles)

[FileName, PathName] = uiputfile({'*.jpg';'*.bmp';'*.tif';'*.png';'*.xlsx'},'��������� �����������');

if FileName~=0    
    
    DotPositions = strfind(FileName,'.');            % ��������� ����� � ��������
    format = FileName(DotPositions(end)+1:end);      % ������� ������ ����� ����� ��������� �����

    if strcmp(format,'xlsx')                
        SaveHistAsXLSX(analyzer_handles.AreaAxesHist,[PathName FileName]);
    else        
        SaveObjectAsImage(analyzer_handles.AreaAxesHist,[PathName FileName]);
    end
end


% ������� ��� ���� ����������� "������� ��������/������"
function ROIorSpectre_Callback(hObject, eventdata, analyzer_handles)
        
if ~get(hObject,'Value')        % ����� �� ������ �� ���������� ��� ������ � "0"
    set(hObject,'Value',1);
    return;
end

ImageMenu_Callback(hObject, eventdata, analyzer_handles);


% ������ edit �����/�������� 
function XY_Callback (hObject, ~, analyzer_handles)
    
H = str2double(get(hObject,'String'));     % ������ �������� ����������� ���� 

if isnan(H)                            % ���� �� ����� - ������
    errordlg('������� � ������ �������� ��������','KAAIP');
    set(gcf,'WindowStyle', 'modal');
    return;
end

switch hObject                  % ��� ������� edit ���������� �������
    case analyzer_handles.X0        
        
        SliderObject = analyzer_handles.X0_Slider;  % ����� ��������
        Slider = 'X0_Slider';                       % ������ ����� �� ����� �������
                
    case analyzer_handles.X1 
        
        SliderObject = analyzer_handles.X1_Slider;
        Slider = 'X1_Slider';          
        
    case analyzer_handles.Y0                
        
        SliderObject = analyzer_handles.Y0_Slider;  % ����� ��������
        Slider = 'Y0_Slider';
        H = -H;
        
    case analyzer_handles.Y1        
        
        SliderObject = analyzer_handles.Y1_Slider;
        Slider = 'Y1_Slider';  
        H = -H;
                
    case analyzer_handles.RowNumberText
        
        SliderObject = analyzer_handles.RowSlider;
        Slider = 'ImageMenu';  
        
    case analyzer_handles.StringNumberText        
        
        SliderObject = analyzer_handles.StringSlider;
        Slider = 'ImageMenu';   
        H = -H; 
        
    otherwise 
        warning('����� �������, ������� �� �������� edit');
        return;
end

H = round(H);               % ��������
Min = get(SliderObject,'Min');
Max = get(SliderObject,'Max');

if H < Min     % ��� ������ �� ������� ����������� ���������� ��������
    H = Min;
elseif H > Max
    H = Max;
end

set(SliderObject,'Value',H);     % ������������� �������� � �������
feval([Slider '_Callback'],hObject,H,analyzer_handles);    % �������� ������    


% ����������� ���� "��������� ������ ������ ��� TXT"
function SaveAssessmentTXT_Callback (~, ~, analyzer_handles)

[FileName, PathName] = uiputfile(['*.' 'txt'],'��������� �������������� ������� ��������');

if FileName ~= 0
    
    AssesmentName = get(analyzer_handles.AssesmentText,'String');
    AssesmentVal = get(analyzer_handles.AssesmentValueText,'String');
    Assess = strcat(AssesmentName,{' '},AssesmentVal);
    
    file_txt = fopen([PathName FileName],'wt');     % ������� ��������� ����
    
    for i = 1:size(Assess,1)                     % ��������� ������ � ���� ������
        fprintf(file_txt,'%s\r\n',Assess{i});
    end
    fclose(file_txt);                       % ��������� ����   
    
end


% ����������� ���� "��������� ������ ������ ��� XLSX"
function SaveAssessmentXLSX_Callback (~, ~, analyzer_handles)

[FileName, PathName] = uiputfile('*.xlsx','��������� �������� ������');

if FileName ~= 0
    
    DotPositions = strfind(FileName,'.');            % ��������� ����� � ��������
    format = FileName(DotPositions(end)+1:end);
    
    if strcmp(format,'xlsx')
        AssesmentName = get(analyzer_handles.AssesmentText,'String');
        AssesmentVal = get(analyzer_handles.AssesmentValueText,'String');
        xlswrite([PathName FileName],AssesmentName,1);
        xlswrite([PathName FileName],AssesmentVal,1,'B1');
    else
        errordlg('�������� ������ .xlsx','������ ���������� �������� ������');
        return;
    end
end

