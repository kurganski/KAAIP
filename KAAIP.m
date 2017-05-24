
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
clear global Parametrs;           % параметры эксперимента (шумы и фильтры)
clear global Noises;              % список параметров зашумления
clear global Filters;             % список параметров фильтрации
delete(hObject);


% ФУНКЦИЯ ПЕРЕД ОТКРЫТИЕМ ПРИЛОЖЕНИЯ
function KAAIP_OpeningFcn(hObject, ~, handles, varargin)

global StatAndMLT;
global CV;

handles.output = hObject;
guidata(hObject, handles);
scr_res = get(0, 'ScreenSize');     % получили разрешение экрана
fig = get(handles.KAAIP,'Position');  % получили координаты окна

% отцентрировали окно
set(handles.KAAIP,'Position',[(scr_res(3)-fig(3))/2 (scr_res(4)-fig(4))/2 fig(3) fig(4)]);

toolboxes = ver();      % считываем наличие тулбоксов
warning('off','all');
matlab_version = toolboxes(1).Release;
matlab_version = str2double(matlab_version(3:6));


if matlab_version < 2015    
    message_str = { 'Ваша версия Matlab ниже версии R2015a';...
                    'Возможны ошибки и некорректное поведение программы'};
end

StatAndMLT = false;         % проверка расширения Statistics and Machine Learning Toolbox
for i = 1:size(toolboxes,2) % проходимся по каждому тулбоксу

    if strcmp('Statistics and Machine Learning Toolbox',toolboxes(i).Name) == 1
        StatAndMLT = true;
    end
end    

CV = false;     % проверка расширения Computer Vision System Toolbox
for i = 1:size(toolboxes,2) % проходимся по каждому

    if strcmp('Computer Vision System Toolbox',toolboxes(i).Name) == 1
        CV = true;
    end
end

if ~ StatAndMLT     % нет расширения - дополняем инфо строку
    message_str = [ message_str;...
                    'Отсутствует расширение "Statistics and Machine Learning Toolbox":';...
                    'В списке искажений экспоненциальный шум и шум Рэлея недоступны'];
end

if ~ CV 
    message_str = [ message_str;...
                    'Отсутствует расширение "Computer Vision System Toolbox":';...
                    'В списке обработок детекторы ключевых точек недоступны'];
end

                        
if ~isempty(message_str)    % вывод сообщения
    questdlg(message_str,'KAAIP','OK','modal');
end 


%%%%%%%%%%%%%%%%%%%%%% МЕНЮ ИСХОДНОГО ИЗОБРАЖЕНИЯ %%%%%%%%%%%%%%%%%%%%%%%%%


% МЕНЮ "ОТКРЫТЬ"
function Open_Callback(hObject, eventdata, handles)

global Original;                        % оригинал изображения
global format;
global Filtered;

%%%%%%%%%%%%% ПРОВЕРКИ

if isempty(handles)            % значит неумный человек запустил fig вместо m  
    
    ok = questdlg({'Вы запустили файл с расширением *.fig вместо расширения *.m.';...
        'Нажмите "OK", и все будет хорошо'},...
        'KAAIP','OK','modal');
    
    % сюда зайдет в любом случае, цикл нужен, чтобы дождаться ответа
    if ~isempty(ok) || isempty(ok)      
        close(gcf);
        run('KAAIP.m');
        return;
    end
end

toolboxes = ver();          % считываем наличие тулбоксов
good = false;
for i = 1:size(toolboxes,2) % проходимся по каждому
    
    if strcmp('Image Processing Toolbox',toolboxes(i).Name) == 1
        good = true;
        break;      % если такой тулбокс есть, то все ок        
    end 
end

if ~good
    ok = questdlg({ 'Ваша версия Matlab не содержит необходимого расширения "Image Processing Toolbox", но вы держитесь здесь';...
                    'Приложение будет закрыто. Вам всего доброго, хорошего настроения и здоровья.';
                    'С установкой расширения все будет хорошо!'},'KAAIP','OK','modal');
    
    if ~isempty(ok) || isempty(ok)
        close(gcf);
        return;
    end
end

warning('on','all');

%%%%%%%%% ЗДЕСЬ УЖЕ ПЫТАЕМСЯ ОТКРЫТЬ

if ~isempty(Filtered)            % если данные уже есть, создаем вопрос-окно
    answer = questdlg(...
        'Открытие изображения приведет к потере полученных данных. Продолжить?',...
        'Открытие изображения','Да','Нет','Нет');
    if ~strcmp(answer,'Да')             % если ответ "Да", тогда не войдет в цикл
        return;                         % с выходом из всего отклика
    end
end

[FileName, PathName] = uigetfile({'*.jpg';'*.tif';'*.bmp';'*.png'},...
                                    'Выберите файл исходного изображения',...
                                    [cd '\Test Images']);    % вызов диалога 
if ~FileName                                 % Проверка, был ли выбран файл
    return;
end

DotPositions = strfind(FileName,'.');            % считываем точки в названии
format = FileName(DotPositions(end)+1:end);      % считали формат файла после последней точки

try             % пытаемся открыть картинку
    [Temp,colors] = imread([PathName FileName]);         % загружаем ее
catch           % если файл не смог быть открытым :'(
    h = errordlg('С файлом что-то не так. Откройте другой','KAAIP');
    set(h, 'WindowStyle', 'modal');
    return;
end

% если картинка индексированная - переводим в 256 оттенков
if ~isempty(colors)      
    Temp = 255*ind2rgb(Temp,colors);
end

Original = [];
Original = Temp;
Original = uint8(Original);                     % переводим в 256 оттенков
set(handles.ChannelSlider,'Max',size(Original,3));    % установки слайдера
set(handles.ChannelSlider,'SliderStep',[1/size(Original,3) 1/size(Original,3)]);

% прячем все объекты с предыдущей обработки

% у данного FiltAgain есть контектное меню, поэтому он двойной и отдельно
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

% чистим глобальные переменные
clear global Noised;
clear global Filtered;
setappdata(handles.NoiseAxes,'Image',[]);
setappdata(handles.FiltAxes,'Image',[]);

if size(Original,3) > 1     % ЕСЛИ ЦВЕТНОЕ ИЗОБРАЖЕНИЕ
    
    set(handles.RGBpanel,'Visible','on');
    set([   handles.Red;...
            handles.Green;...
            handles.Blue;...
            handles.ChannelSlider;...
            handles.ShowButton],'Enable','on');
        
    set(handles.ChannelSlider,'Value',0);
    set(handles.ChannelString,'String','RGB');
    
    str = cell(size(Original,3),1);         % считаем каналы и заполняем ими меню
    for i = 1:size(Original,3)
        str{i} = ['канал № ' num2str(i)];
    end
    
    set(handles.Red,'String',str,'Value',1);
    set(handles.Green,'String',str,'Value',2);
    set(handles.Blue,'String',str,'Value',3);
    
    set(handles.ShowMenu,'String',{'Изображения';'Гистограммы полутонов';'Гистограммы HSV'},'Value',1);
    
else                        % ЕСЛИ Ч/Б ИЗОБРАЖЕНИЕ
    
    set(handles.RGBpanel,'Visible','on');
    set(handles.ChannelSlider,'Value',1,'Enable','off');
    
    set([handles.Red;...
    	handles.Green;...
    	handles.Blue;...
    	handles.ShowButton],'Enable','off');
    
    set(handles.ShowMenu,'String',{'Изображения';'Гистограммы полутонов'},'Value',1);
end

set(handles.OriginalPanel,'Visible','on');      % отобразили панель
set(handles.RunImageAnalyzer,'Enable','on');
set(handles.CopyOriginalImage,'Enable','on');
set(handles.FiltrationMenu,'Enable','on');              % разблокировали меню фильтрации
set(handles.View_Original,'Enable','on');               % разблокировали исходный масштаб

ShowMenu_Callback(hObject, eventdata, handles);    % выполняем функцию отображения


% МЕНЮ "ПРОСМОТР" ИСХОДНОГО ИЗОБРАЖЕНИЯ
function View_Original_Callback(hObject, ~, handles)

if hObject == handles.View_Filtered(1) || hObject == handles.View_Filtered(2)       % если вызывающая функция была "показать отфильтрованное"
    Im = getappdata(handles.FiltAxes,'Image');
    Image(:,:,1) = Im(:,:,get(handles.Red,'Value'),get(handles.FilteredMenu,'Value'));
    Image(:,:,2) = Im(:,:,get(handles.Green,'Value'),get(handles.FilteredMenu,'Value'));
    Image(:,:,3) = Im(:,:,get(handles.Blue,'Value'),get(handles.FilteredMenu,'Value'));

elseif hObject == handles.View_Noised(1)  || hObject == handles.View_Noised(2)     % если вызывающая  функция была "показать зашумленное"
    Im = getappdata(handles.NoiseAxes,'Image');
    Image(:,:,1) = Im(:,:,get(handles.Red,'Value'),get(handles.NoisedMenu,'Value'));
    Image(:,:,2) = Im(:,:,get(handles.Green,'Value'),get(handles.NoisedMenu,'Value'));
    Image(:,:,3) = Im(:,:,get(handles.Blue,'Value'),get(handles.NoisedMenu,'Value'));

else                                        % если вызывающая  функция была "показать оригинал"
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


% МЕНЮ "КОПИРОВАТЬ" ИСХОДНОЕ ИЗОБРАЖЕНИЕ В БУФЕР
function CopyOriginalImage_Callback(hObject, ~, handles)
        
if hObject == handles.CopyFiltered(1) || hObject == handles.CopyFiltered(2)       % если вызывающая функция была "показать отфильтрованное"
    Im = getappdata(handles.FiltAxes,'Image');
    Image(:,:,1) = Im(:,:,get(handles.Red,'Value'),get(handles.FilteredMenu,'Value'));
    Image(:,:,2) = Im(:,:,get(handles.Green,'Value'),get(handles.FilteredMenu,'Value'));
    Image(:,:,3) = Im(:,:,get(handles.Blue,'Value'),get(handles.FilteredMenu,'Value'));
    
elseif hObject == handles.CopyNoised(1)  || hObject == handles.CopyNoised(2)     % если вызывающая  функция была "показать зашумленное"
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


% МЕНЮ "СОХРАНИТЬ ГИСТОГРАММУ" ИСХОДНОГО ИЗОБРАЖЕНИЯ
function SaveOriginalHist_Callback(hObject, ~, handles)

if any(hObject == handles.SaveFilteredHist)     % если вызвано с фильтров
    AH = handles.FiltAxes;    % копируем фильтроваую ось
    
elseif any(hObject == handles.SaveNoisedHist)
    AH = handles.NoiseAxes;     % иначе-зашумленную
    
elseif any(hObject == handles.SaveOriginalHist)
    AH = handles.OriginalAxes;  % иначе исходную
end

[FileName, PathName] = uiputfile({'*.jpg';'*.bmp';'*.tif';'*.png';'*.xlsx'},'Сохранить гистограмму');

if FileName~=0    
    
    DotPositions = strfind(FileName,'.');            % считываем точки в названии
    format = FileName(DotPositions(end)+1:end);      % считали формат файла после последней точки

    if strcmp(format,'xlsx')        
        SaveHistAsXLSX(AH,[PathName FileName]);        
    else        
        SaveObjectAsImage(AH,[PathName FileName]);
    end
end


% МЕНЮ "КОПИРОВАТЬ ГИСТОГРАММУ" ИСХОДНОГО ИЗОБРАЖЕНИЯ
function CopyOriginalHist_Callback(hObject, ~, handles)
    
if hObject == handles.CopyFilteredHist     % если вызвано с фильтров
    AH = handles.FiltAxes;    % копируем фильтроваую ось
    
elseif hObject == handles.CopyNoisedHist
    AH = handles.NoiseAxes;     % иначе-зашумленную
    
else
    AH = handles.OriginalAxes;  % иначе исходную
end
    
ClipboardCopyObject(AH,0); 


%%%%%%%%%%%%%%%%%%%%%% МЕНЮ ЗАШУМЛЕННОГО ИЗОБРАЖЕНИЯ %%%%%%%%%%%%%%%%%%%%%%


% МЕНЮ "ПРОСМОТР" ЗАШУМЛЕННОГО ИЗОБРАЖЕНИЯ
function View_Noised_Callback(hObject, ~, handles)

View_Original_Callback(hObject,0,handles);


% МЕНЮ "КОПИРОВАТЬ" ЗАШУМЛЕННОЕ ИЗОБРАЖЕНИЕ В БУФЕР
function CopyNoised_Callback(hObject, ~, handles)

CopyOriginalImage_Callback(hObject,0,handles);


% МЕНЮ "СОХРАНИТЬ ЗАШУМЛЕННОЕ ИЗОБРАЖЕНИЕ"
function SaveNoised_Callback(~, ~, handles)

global Noised;                           % зашумленный вариант
global format;
    
[FileName, PathName] = uiputfile(['*.' format],'Сохранить искаженное изображение');
if FileName~=0
    imwrite(Noised(:,:,:,get(handles.NoisedMenu,'Value')),[PathName FileName],format);
end


% МЕНЮ "СОХРАНИТЬ ВСЕ ИСКАЖЕННЫЕ ИЗОБРАЖЕНИЯ"
function SaveAllNoised_Callback(~, ~, ~)

global Noised;                           % зашумленный вариант
global format;

[FileName, PathName] = uiputfile(['*.' format],'Сохранить все искаженные изображения');
if FileName~=0
    for i = 1:size(Noised,4)
        imwrite(Noised(:,:,:,i),[PathName '(' num2str(i) ') ' FileName],format);
    end
end


% МЕНЮ "СОХРАНИТЬ ГИСТОГРАММУ" ЗАШУМЛЕННОГО ИЗОБРАЖЕНИЯ
function SaveNoisedHist_Callback(hObject, ~, handles)

SaveOriginalHist_Callback(hObject, 0, handles);


% МЕНЮ "КОПИРОВАТЬ ГИСТОГРАММУ" ЗАШУМЛЕННОГО ИЗОБРАЖЕНИЯ
function CopyNoisedHist_Callback(hObject, eventdata, handles)

CopyOriginalHist_Callback(hObject, eventdata, handles);


%%%%%%%%%%%%%%%%%%% МЕНЮ ОТФИЛЬТРОВАННОГО ИЗОБРАЖЕНИЯ %%%%%%%%%%%%%%%%%%%%%


% МЕНЮ "ПРОСМОТР" ОРИГИНАЛА
function View_Filtered_Callback(hObject, ~, handles)

View_Original_Callback(hObject,0,handles);


% МЕНЮ "КОПИРОВАТЬ" ОТФИЛЬТРОВАННОЕ ИЗОБРАЖЕНИЕ В БУФЕР
function CopyFiltered_Callback(hObject, ~, handles)

CopyOriginalImage_Callback(hObject,0,handles);


% МЕНЮ "СОХРАНИТЬ ОТФИЛЬТРОВАННОЕ ИЗОБРАЖЕНИЕ"
function SaveFiltered_Callback(~, ~, handles)

global Filtered;                           % зашумленный вариант
global format;
    
[FileName, PathName] = uiputfile(['*.' format],'Сохранить обработанное изображение');
if FileName~=0
    imwrite(Filtered(:,:,:,get(handles.FilteredMenu,'Value')),[PathName FileName],format);
end


% МЕНЮ "СОХРАНИТЬ ВСЕ ЗАШУМЛЕННЫЕ ИЗОБРАЖЕНИЯ"
function SaveAllFiltered_Callback(~, ~, ~)

global Filtered;                           % зашумленный вариант
global format;
    
[FileName, PathName] = uiputfile(['*.' format],'Сохранить все обработанные изображения');
if FileName~=0
    for i = 1:size(Filtered,4)
        imwrite(Filtered(:,:,:,i),[PathName '(' num2str(i) ') ' FileName],format);
    end
end


% МЕНЮ "СОХРАНИТЬ ГИСТОГРАММУ" ОТФИЛЬТРОВАННОГО ИЗОБРАЖЕНИЯ
function SaveFilteredHist_Callback(hObject, ~, handles)

SaveOriginalHist_Callback(hObject, 0, handles);


% МЕНЮ "КОПИРОВАТЬ ГИСТОГРАММУ" ОТФИЛЬТРОВАННОГО ИЗОБРАЖЕНИЯ
function CopyFilteredHist_Callback(hObject, eventdata, handles)

CopyOriginalHist_Callback(hObject, eventdata, handles);


%%%%%%%%%%%%%%%%%% МЕНЮ "СПИСОК "ИСКАЖЕНИЕ-ОБРАБОТКА"" %%%%%%%%%%%%%%%%%%%%


% МЕНЮ "ПОКАЗАТЬ МАСКУ ОБРАБОТКИ"
function ShowFilterMask_Callback(hObject,eventdata,handles)

List = handles.NoiseFilterList.String;          % список
FiltStr = List{handles.NoiseFilterList.Value};  % нужная строка
                       
where = strfind(FiltStr,'%%');                  % ищем хэш в строке

if ~isempty(where)                              % если он есть
    hash = FiltStr(where(1)+2:where(2)-1);      % считываем только его
    Data = zeros(size(hash,2));                 % массив маски
    hash = double(hash) - 500;                  % переводим хэш в 10ую систему
    
    for y = 1:size(hash,2)                      % каждый символ хэша 
        bin_str = dec2bin(hash(y));             % раскладываем в строку
        for x = 1:size(bin_str,2)               % каждую двоичную цифру
            Data(y,x) = str2double(bin_str(x)); % кладем в ячейку массива
        end
    end
    
    try
        imtool(Data);
    catch
        OpenImageOutside(Data);
    end
    
else    
    h = errordlg('В выбранной строке отсутствует хэш','KAAIP');
    set(h, 'WindowStyle', 'modal');    
end


% МЕНЮ "ШУМ-"ФИЛЬТР": "СОХРАНИТЬ КАК ТЕКСТ"
function SaveNFListAsText_Callback(~, ~, handles)

S = get(handles.NoiseFilterList,'String');  % считываем список

for x = 1:size(S,1)        % для каждой стркои списка
                
    S(x) = regexprep(S(x),char(963),'sigma');   % находим и заменям символы
    S(x) = regexprep(S(x),char(955),'lambda');
    S(x) = regexprep(S(x),char(945),'alpha');
    S(x) = regexprep(S(x),char(178),'^(2)');
    S(x) = regexprep(S(x),char(186),' гр.');
    S(x) = regexprep(S(x),char(8734),'inf');
    S(x) = regexprep(S(x),char(8594),'-->');
    S(x) = regexprep(S(x),char(946),'beta');  
    
end

    % спрашиваем куда сохранить
[FileName, PathName] = uiputfile(['*.' 'txt'],'Сохранить список "Шум-Фильтр"');
if FileName~=0
    file_txt = fopen([PathName FileName],'wt');     % создаем текстовый файл
    
    for i = 1:size(S,1)                     % построчно вносим в него список
        fprintf(file_txt,'%s\r\n',S{i});
    end
    fclose(file_txt);                       % закрываем файл
    
end


% МЕНЮ "КОПИРОВАТЬ" СПИСОК "ШУМ-ОБРАБОТКА"
function CopyNoiseFilterList_Callback(~, ~, handles)

ClipboardCopyObject(handles.NoiseFilterList,0);


% МЕНЮ "КОПИРОВАТЬ ГРАФИК PSNR"
function CopyPSNR_Callback(~, ~, handles)

ClipboardCopyObject(handles.Diagram,150);


% МЕНЮ "СОХРАНИТЬ ГРАФИК PSNR"
function SavePSNR_Callback(~, ~, handles)

global Assessment_N;        % массив оценок искаженных изображений
global Assessment_F;        % массив оценок обработанных изображений

[FileName, PathName] = uiputfile({'*.jpg';'*.bmp';'*.tif';'*.png';'*.xlsx'},'Сохранить график');
if FileName~=0   
    
    DotPositions = strfind(FileName,'.');            % считываем точки в названии
    format = FileName(DotPositions(end)+1:end);      % считали формат файла после последней точки

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
            
            ColTitles{x} = ['№ ' num2str(x)];
        end        
        
        xlswrite([PathName FileName],{'Оценка\Искаженные изображения'},1,'A1');
        xlswrite([PathName FileName],cellstr(RowTitles),1,'A2');
        xlswrite([PathName FileName],ColTitles,1,'B1');
        xlswrite([PathName FileName],Data_N,1,'B2');
        
        
        xlswrite([PathName FileName],{'Оценка\Обработанные изображения'},1,'A10');
        xlswrite([PathName FileName],cellstr(RowTitles),1,'A11');
        xlswrite([PathName FileName],ColTitles,1,'B10');
        xlswrite([PathName FileName],Data_F,1,'B11');
        
    else
        SaveObjectAsImage(handles.Diagram,[PathName FileName]);
    end
end


% МЕНЮ "ДОБАВИТЬ ИЗОБРАЖЕНИЕ"
function AddImageToList_Callback(hObject, eventdata, handles)

global Original;                  % оригинал изображения
global Noised;              % зашумленный вариант
global Filtered;            % отфильтрованное изображение
global Assessment_N;              % оценки зашумленных изображений
global Assessment_F;              % оценки отфильтрованных изображений

[FileName, PathName] = uigetfile({'*.jpg';'*.tif';'*.bmp';'*.png'},...
                                    'Выберите файл исходного изображения',...
                                    [cd '\Test Images']);    % вызов диалога 
if ~FileName                                 % Проверка, был ли выбран файл
    return;
end

DotPositions = strfind(FileName,'.');            % считываем точки в названии
format = FileName(DotPositions(end)+1:end);      % считали формат файла после последней точки

if strcmp(format,'gif')                  % !гифки не читаем
    h = errordlg('gif формат не поддерживается','KAAIP');
    set(h, 'WindowStyle', 'modal');
    return;
end

try             % пытаемся открыть картинку
    Temp = imread([PathName FileName]);         % загружаем ее
catch           % если файл не смог быть открытым :'(
    h = errordlg('С файлом что-то не так. Откройте другой','KAAIP');
    set(h, 'WindowStyle', 'modal');
    return;
end

if length(size(Original)) ~= length(size(Temp)) || ~all(size(Original) == size(Temp))   % если размерность не совпала - ошибка
    h = errordlg('Размерности выбранного изображения и исходного не совпадают. Откройте другое изображение','KAAIP');
    set(h, 'WindowStyle', 'modal');
    return;
end

Noised(:,:,:,end+1) = Original;
Filtered(:,:,:,end+1) = Temp;

str = cell(size(Noised,4),1);
for p = 1:size(Filtered,4)
    str{p} = ['Изображение № ' num2str(p)];
end

set(handles.NoisedMenu,'String',str,'Value',1,'Enable','on');
set(handles.FilteredMenu,'String',str,'Value',1,'Enable','on');

% если число фильтраций свыше 10, настроим слайдер
if size(Noised,4) > 10
    set(handles.GraphSlider,'Min',1,...
        'Max',size(Noised,4)-9,...
        'Enable','on',...
        'SliderStep',[1/(size(Noised,4)-10) 10/(size(Noised,4)-10)]);
end

% меняем список "Искажение-обработка"
new_str = [ num2str(p) ...
            ') Исходное изображение ' char(8594) ...
            ' Искажение отсутствует ' char(8594) ...
            ' Пользовательское изображение'];
        
NewList = vertcat(get(handles.NoiseFilterList,'String'),new_str);
set(handles.NoiseFilterList,'String',NewList);

if size(Noised,4) > 1       % если в списке более 1й обработки, тогда можно что-то удалять
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

% вызовем подфункцию, которая нарисует графики и обновить картинки
ShowMenu_Callback(hObject, eventdata, handles);
AssessMenu_Callback(hObject, eventdata, handles);


% МЕНЮ "УДАЛИТЬ ВЫБРАННУЮ ПОЗИЦИЮ"
function DeleteListPosition_Callback(hObject, eventdata, handles)

global Noised;              % зашумленный вариант
global Filtered;            % отфильтрованное изображение
global Assessment_N;              % оценки зашумленных изображений
global Assessment_F;              % оценки отфильтрованных изображений

answer = questdlg(...
        'Просто защитный диалог. Удалить позицию?',...
        'Удаление позиции','Да','Нет','Нет');
if ~strcmp(answer,'Да')             % если ответ "Да", тогда не войдет в цикл
    return;                         % с выходом из всего отклика
end

DeletePos = get(handles.NoiseFilterList,'Value');
List = get(handles.NoiseFilterList,'String');

Noised(:,:,:,DeletePos) = [];
Filtered(:,:,:,DeletePos) = [];
Assessment_N(DeletePos) = [];
Assessment_F(DeletePos) = [];

List(DeletePos) = [];
for i = DeletePos : size(Noised,4)    % во всех следующих строках убавляем порядковый номер
    List(i) = regexprep(List(i),num2str(i + 1),num2str(i),'once');
end

str = cell(size(Noised,4),1);       % выпадающие списки меняем
for p = 1:size(Filtered,4)
    str{p} = ['Изображение № ' num2str(p)];
end

set(handles.NoisedMenu,'String',str,'Value',1,'Enable','on');
set(handles.FilteredMenu,'String',str,'Value',1,'Enable','on');
set(handles.NoiseFilterList,'String',List,'Value',1);

% если число обработок свыше 10, настроим слайдер
if size(Noised,4) > 10
    set(handles.GraphSlider,'Min',1,...
        'Value',1,...
        'Max',size(Noised,4)-9,...
        'Enable','on',...
        'SliderStep',[1/(size(Noised,4)-10) 10/(size(Noised,4)-10)]);
    
else    % иначе сделаем недоступным
    set(handles.GraphSlider,'Enable','off');
end

% вызовем подфункцию, которая нарисует графики и обновить картинки
ShowMenu_Callback(hObject, eventdata, handles);
AssessMenu_Callback(hObject, eventdata, handles);

if size(Noised,4) == 1       % если в списке меннее 1й обработки, тогда нельзя удалять
    set(handles.DeleteListPosition,'Enable','off');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%% СЛАЙДЕРЫ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% СЛАЙДЕР КАНАЛОВ
function ChannelSlider_Callback(hObject, ~, handles)

global Assessment_N;              % пиковое с/ш зашумленного изображения
global Assessment_F;              % пиковое с/ш отфильтрованного изображения

ch = get(handles.ChannelSlider,'Value');
string = get(handles.AssessMenu,'String');              
Assess =  char(string(get(handles.AssessMenu,'Value')));
MenuString = get(handles.ShowMenu,'String');
WhatToShow = MenuString(get(handles.ShowMenu,'Value'));
NMV = handles.NoisedMenu.Value;
FMV = handles.FilteredMenu.Value;

if hObject ~= handles.ShowButton
    
    if ch == 0          % если не полутоновое изображение
        
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
    dB = ' дБ';
else
    dB = '';
end

switch char(WhatToShow)       % смотрим, что нужно показать
    
    case {'Изображения','SSIM-изображения'}   
        
        if ch == 0
            handles.ChannelString.String = 'RGB';
        else
            handles.ChannelString.String = ['Канал № ' num2str(ch)];
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
            
            if strcmp(char(WhatToShow),'Изображения')   % для SSIM оценку не выводим
                
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
            
            if strcmp(char(WhatToShow),'Изображения')   % для SSIM оценку не выводим
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

    case {'Гистограммы полутонов','Гистограммы HSV'}
        
        if ch == 0 && strcmp(char(WhatToShow),'Гистограммы полутонов')
            handles.ChannelString.String = 'RGB';
        elseif ch == 0 && strcmp(char(WhatToShow),'Гистограммы HSV')            
            handles.ChannelString.String = 'HSV';
        else
            handles.ChannelString.String = ['Канал № ' num2str(ch)];
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
        assert(0,'Строка меню "Показывать" считалась не корректно');        
end       

  
% СЛАЙДЕР ГРАФИКОВ
function GraphSlider_Callback(hObject, ~, handles)

global Assessment_N;        % массив оценок искаженных изображений

% всегда показываю 10 значений, а данный отклик лишь меняет пределы осей

if hObject == handles.NoiseFilterList      % если не пустой, то там выбранная пользователем строка меню "шум-обработка"        
    BarMin = get(handles.NoiseFilterList,'Value');
else
    BarMin = round(get(handles.GraphSlider,'Value'));  % считываем значение слайдера
end
 
BarMax = BarMin + 9;                    % нашли последний отображаемый столбец

if BarMax >= size(Assessment_N,2)       % если он больше, чем размер массива оценок
    BarMax = size(Assessment_N,2);      % меняем оба предела
    BarMin = size(Assessment_N,2) - 9;
end

if BarMin < 1
    BarMin = 1;
end

set(handles.GraphSlider,'Value',BarMin);
ylim(handles.Diagram,[BarMin-0.5 BarMax+0.5]);   % устанавливаем предел по оси Х
 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% КНОПКИ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% КНОПКА "ОТОБРАЗИТЬ"
function ShowButton_Callback(hObject, eventdata, handles)

set(handles.ChannelSlider,'Value',0);             % задаем значение слайдера
ChannelSlider_Callback(hObject, eventdata, handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% СПИСКИ  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ВЫПАДАЮЩИЙ СПИСОК НА ПАНЕЛИ ЗАШУМЛЕННЫХ ИЗОБРАЖЕНИЙ
function NoisedMenu_Callback(hObject, eventdata, handles)

set(handles.FiltAgainNoised,'Label',...
    ['Обработать искаженное изображение № ' num2str(get(handles.NoisedMenu,'Value'))]);
ChannelSlider_Callback(hObject, eventdata, handles);


% ВЫПАДАЮЩИЙ СПИСОК НА ПАНЕЛИ ОТФИЛЬТРОВАННЫХ ИЗОБРАЖЕНИЙ
function FilteredMenu_Callback(hObject, eventdata, handles)

set(handles.FiltAgain,'Label',...
    ['Обработать ранее обработанное  изображение № ' num2str(get(handles.FilteredMenu,'Value'))]);
ChannelSlider_Callback(hObject, eventdata, handles);


% ВЫПАДАЮЩИЙ СПИСОК "ВЫБОР ХАРАКТЕРИСТИКИ"
function AssessMenu_Callback(hObject, eventdata, handles)

global Assessment_N;        % массив оценок искаженных изображений
global Assessment_F;        % массив оценок обработанных изображений

AssessType = get(handles.AssessMenu,'Value');   % тип оценки для отображения
AssessStr = get(handles.AssessMenu,'String');   % строка с названиями оценок

% если пользователь занулил оба чека, делаем 1 вызывающего
if handles.ViewNoisedCheck.Value == 0 && handles.ViewFilteredCheck.Value == 0      
    set(hObject,'Value',1);
end
NoiseCheck = handles.ViewNoisedCheck.Value;     % если 1, то отображаем оценки искажения
FilterCheck = handles.ViewFilteredCheck.Value;  % если 1, то отображаем оценки обработки


Y = zeros(size(Assessment_N,2),2);      % вектор значений
Ticks = cell(size(Assessment_N,2),1);   % подписи значений на оси

for i = 1:size(Assessment_N,2)
                
    % создаем вектор значений для barh
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

if size(Assessment_N,2) == 1    % если совершили обработку только одной итерацией
    Y(end+1,:) = Y;             % добавим вторую строку для корректной работы barh
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
    title(handles.Diagram,strcat(AssessStr(AssessType),', дБ'),'FontSize',10);
else
    title(handles.Diagram,AssessStr(AssessType),'FontSize',10);
end
    
GraphSlider_Callback(hObject,eventdata,handles);
ChannelSlider_Callback(hObject, eventdata, handles);


% СПИСОК "ИСКАЖЕНИЕ-ОБРАБОТКА"
function NoiseFilterList_Callback(hObject, eventdata, handles)

ChosenOne = get(handles.NoiseFilterList,'Value');       % какой элемент списка выбран

set(handles.NoisedMenu,'Value',ChosenOne);              % отображаю картинки
set(handles.FilteredMenu,'Value',ChosenOne);
FilteredMenu_Callback(hObject, eventdata, handles);     % вызов 

if strcmp(get(handles.GraphSlider,'Enable'),'on') == 1
    GraphSlider_Callback(hObject, ChosenOne, handles)       % меняю график оценок
end


% ВЫПАДАЮЩИЙ СПИСОК "ПОКАЗАТЬ"
function ShowMenu_Callback(hObject, eventdata, handles)

global Original;            % оригинал изображения
global Noised;              % зашумленный вариант
global Filtered;            % отфильтрованное изображение
global Assessment_N;              % пиковое с/ш зашумленного изображения
global Assessment_F;              % пиковое с/ш отфильтрованного изображения

% считываем собственное значение и вставляем нужное изображение в контейнер
% оси UserData, затем слайдер выберет нужный канал/изображение и пр.

MenuString = get(handles.ShowMenu,'String');
WhatToShow = MenuString(get(handles.ShowMenu,'Value'));

if size(Original,3) ~= 1            % если не полутоновое изображение
    ch(1) = handles.Red.Value;
    ch(2) = handles.Green.Value;
    ch(3) = handles.Blue.Value;
else
    ch = 1;
end

switch char(WhatToShow)       % смотрим, что нужно показать
    
    case 'Изображения'
        
        setappdata(handles.OriginalAxes,'Image',Original);        
        handles.uipanel8.Visible = 'on';
        
        OI = imshow(Original(:,:,ch),'Parent',handles.OriginalAxes);  
        set(OI,'UIContextMenu',handles.OriginalImageContextMenu,'Tag','ImObject');   
        set(handles.OriginalAxes,'Position',[20 50 300 300]);       % ставим ось на место, после гистограмм
                       
        if ~isempty(Noised)
            setappdata(handles.NoiseAxes,'Image',Noised);
            ON = imshow(Noised(:,:,ch,handles.NoisedMenu.Value),'Parent',handles.NoiseAxes); 
            set(ON,'UIContextMenu',handles.NoisedImageContextMenu,'Tag','ImObject');
            set(handles.NoiseAxes,'Position',[20 50 300 300]);      % ставим ось на место, после гистограмм
            
            setappdata(handles.FiltAxes,'Image',Filtered);
            OF = imshow(Filtered(:,:,ch,handles.FilteredMenu.Value),'Parent',handles.FiltAxes);
            set(OF,'UIContextMenu',handles.FilteredImageContextMenu,'Tag','ImObject');
            set(handles.FiltAxes,'Position',[20 50 300 300]);
        end
        
    case {'Гистограммы полутонов','Гистограммы HSV'}
        
        if strcmp('Гистограммы полутонов',char(WhatToShow))
            
            Im_O = Original;        % преднастройка изображений для гистограмм
                
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
        
    case 'SSIM-изображения'
        
        setappdata(handles.OriginalAxes,'Image',Original);   
        Im_N = zeros(size(Original,1),size(Original,2),size(Original,3),size(Assessment_N,2),'uint8');
        Im_F = zeros(size(Im_N),'uint8');
        
        for x = 1:size(Assessment_N,2)
            Im_N(:,:,:,x) = Assessment_N(x).SSIM_Image;
            Im_F(:,:,:,x) = Assessment_F(x).SSIM_Image;
        end           
        
        handles.uipanel8.Visible = 'on';
        
        OI = imshow(Original(:,:,ch),'Parent',handles.OriginalAxes);  
        set(OI,'UIContextMenu',handles.OriginalImageContextMenu,'Tag','ImObject');   % привязываем контекстное меню
        set(handles.OriginalAxes,'Position',[20 50 300 300]);       % ставим ось на место, после гистограмм
        
        setappdata(handles.NoiseAxes,'Image',Im_N); 
        ON = imshow(Im_N(:,:,ch,handles.NoisedMenu.Value),'Parent',handles.NoiseAxes);
        set(ON,'UIContextMenu',handles.NoisedImageContextMenu,'Tag','ImObject'); % приктлеиваем контекстное меню к ней
        set(handles.NoiseAxes,'Position',[20 50 300 300]);      % ставим ось на место, после гистограмм
        
        setappdata(handles.FiltAxes,'Image',Im_F); 
        OF = imshow(Im_F(:,:,ch,handles.FilteredMenu.Value),'Parent',handles.FiltAxes);
        set(OF,'UIContextMenu',handles.FilteredImageContextMenu,'Tag','ImObject');
        set(handles.FiltAxes,'Position',[20 50 300 300]);
        
    otherwise
        
        assert(0,'Строка меню "Показывать" считалась не корректно');        
end

ChannelSlider_Callback(hObject, eventdata, handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% МЕНЮ ФИЛЬТРАЦИЯ %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% МЕНЮ "ОТКРЫТЬ МЕНЮ ВЫБОРА"
function Filtration_Callback(hObject, eventdata, handles)

global Parametrs;           % параметры эксперимента (шумы и фильтры)
global Noises;              % список параметров зашумления
global Filters;             % список параметров фильтрации
global Noised;              % зашумленный вариант
global Filtered;            % отфильтрованное изображение
global FilteredAsOriginal;  % ранее обработанное изображение
global ContinueProcessing;  % лог переменная того, что нужно продолжить обработку, не удаляя результат предыдущей
global StatAndMLT;
global CV
global Original;

Noises(:,:) = [];       
Filters = struct([]);  
Parametrs = cell(1);        
        
Menu = open('menu.fig');
menu_handles = guihandles(Menu);

scr_res = get(0, 'ScreenSize');             % считываем разрешение экрана и окна
fig = get(Menu,'Position');         % меняем позицию окна
set(Menu,   'Position',[(scr_res(3)-fig(3))/2 (scr_res(4)-fig(4))/2 fig(3) fig(4)],...
            'CloseRequestFcn','delete(gcf);'); 
        
% а ежели нужно продолжить обработку - запоминаем сей факт
if hObject == handles.ContinueProcessing
    ContinueProcessing = true;
else
    ContinueProcessing = false;
end
      
        
% коли запустили из меню "использовать отфильтрованное изображение №"
if hObject == handles.FiltAgain(1) || hObject == handles.FiltAgain(2)      
    
    FilteredAsOriginal = Filtered(:,:,:,get(handles.FilteredMenu,'Value'));
    
elseif hObject == handles.FiltAgainNoised(1) || hObject == handles.FiltAgainNoised(2)    
    
    FilteredAsOriginal = Noised(:,:,:,get(handles.NoisedMenu,'Value'));
else        
    FilteredAsOriginal = [];
end

set(menu_handles.ProcessingOrderString,'String',...
    ['Выбранное изображение ' char(8594) ' Искажение ' char(8594) ' Обработка']);
    
% привязываем к объектам функции откликов
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
%%%%%%%%%%%%%%%%%%%%%%%%%%% ФУНКЦИИ ОКНА "MENU" %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% СПИСКИ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% СПИСОК ШУМОВ
function NoiseType_Callback(~, ~, menu_handles)

global Original;            % исходное изображение


NoiseType = get(menu_handles.NoiseType,'Value');     % считываем номер выбранного шума

NoiseWithHist = [2 4 5 11 12];            % номера шумов, для кот. строим гистограмму
NoiseWith_A = [6 7 8 9 10];           % ----//-----, с параметром А
NoiseWith_B = [2 4 5 10];            % ----//-----, с параметром В

% прячем слайдеры и тексты
set([menu_handles.A;...
    menu_handles.Aslider;...
    menu_handles.text13;...
    menu_handles.text12;...
    menu_handles.B;...
    menu_handles.Bslider;...
    menu_handles.HistButton],'Visible','off');    

set(menu_handles.NoisedImageHistButton,'Visible','on'); % нужна для каждого случая, кроме отсутствия шума

if  any(NoiseWith_A == NoiseType)                       % если выбраны шумы, которым нужен слайдер А
    set([menu_handles.A menu_handles.Aslider],'Visible','on');    % показываем тексты и слайдер
    set(menu_handles.text12,'Visible','on');                 
end

if  any(NoiseWithHist == NoiseType)                     % выбраны шумы, для которых строится гистограмма
    set([menu_handles.A menu_handles.Aslider],'Visible','on');    % показываем тексты и слайдер
    set(menu_handles.text12,'Visible','on');                  
    set(menu_handles.HistButton,'Visible','on');    
end

if  any(NoiseWith_B == NoiseType)                       % если выбран шумы, которым нужен слайдер В
    set([menu_handles.A menu_handles.Aslider],'Visible','on');    % показываем тексты и слайдер
    set([menu_handles.text12 menu_handles.text13],'Visible','on');                  
    set([menu_handles.B menu_handles.Bslider],'Visible','on');    % отображаем слайдер
end

switch  get(menu_handles.NoiseType,'Value')
    case 1          % ОТСУТСТВУЕТ ШУМ   
        
        set(menu_handles.NoisedImageHistButton,'Visible','off');        
            
    case 2          % НОРМАЛЬНЫЙ ШУМ
        set(menu_handles.A,'String',[char(963) ' = ']);       % меняем установки слайдера
        set(menu_handles.text12,'String','80');
        set(menu_handles.Aslider,'Value',80,'Max',255,'Min',1,'SliderStep',[1/254 10/254]);  
        set(menu_handles.B,'String',[char(956) ' = ']);                      % меняем установки слайдера
        set(menu_handles.text13,'String','0');
        set(menu_handles.Bslider,'Value',0,'Max',255,'Min',-255,'SliderStep',[1/510 10/510]);  
        
    case 3          % ШУМ ПУАССОНА
          
    case 4          %  ЛАПЛАСА ШУМ
        set(menu_handles.A,'String',[char(945) ' = ']);       % меняем установки слайдера
        set(menu_handles.text12,'String','1');
        set(menu_handles.Aslider,'Value',1,'Max',40,'Min',1,'SliderStep',[1/39 10/39]);
        set(menu_handles.B,'String',[char(956) ' = ']);                      % меняем установки слайдера
        set(menu_handles.text13,'String','0');
        set(menu_handles.Bslider,'Value',0,'Max',255,'Min',-255,'SliderStep',[1/510 10/510]);
        
    case 5         % РАВНОМЕРНЫЙ ШУМ  
        set(menu_handles.A,'String','A =');                      % меняем установки слайдера
        set(menu_handles.text12,'String','0');
        set(menu_handles.Aslider,'Value',0,'Max',254,'Min',-255,'SliderStep',[1/509 10/509]);
        set(menu_handles.B,'String','B =');                      % меняем установки слайдера
        set(menu_handles.text13,'String','100');
        set(menu_handles.Bslider,'Value',100,'Max',255,'Min',-254,'SliderStep',[1/509 10/509]);         
        
    case 6          % СПЕКЛ-ШУМ 
        set(menu_handles.A,'String',[char(963) char(178) ' = ']);       % меняем установки слайдера
        set(menu_handles.text12,'String','80');
        set(menu_handles.Aslider,'Value',80,'Max',255,'Min',1,'SliderStep',[1/254 10/254]);
        
    case {7,8,9}          % СОЛЬ-ПЕРЕЦ ШУМ, СОЛЬ ШУМ, ПЕРЕЦ ШУМ  
        set(menu_handles.A,'String','Искажение,%:');
        set(menu_handles.text12,'String','10');
        set(menu_handles.Aslider,'Value',10,'Max',100,'Min',1,'SliderStep',[1/99 10/99]);
        
    case 10         % РАЗМЫТИЕ ШУМ        
        set(menu_handles.A,'String','Число точек: ');
        set(menu_handles.text12,'String','10');
        set(menu_handles.Aslider,'Value',10,'Max',max(size(Original)),'Min',1,...
            'SliderStep',[1/(max(size(Original))-1) 10/(max(size(Original))-1)]); 
        set(menu_handles.B,'String',['Угол,' char(186) ': ']);                      % меняем установки слайдера
        set(menu_handles.text13,'String','0');
        set(menu_handles.Bslider,'Value',0,'Max',360,'Min',0,'SliderStep',[1/360 10/360]);    
        
    case 11          % РЭЛЕЯ ШУМ 
        set(menu_handles.A,'String',[char(963) ' = ']);       % меняем установки слайдера
        set(menu_handles.text12,'String','0.5');
        set(menu_handles.Aslider,'Value',0.5,'Max',1,'Min',0.01,'SliderStep',[0.01/0.99 0.1/0.99]);  
        
    case 12          % ЭКСПОНЕНЦИАЛЬНЫЙ ШУМ    
        set(menu_handles.A,'String',[char(955) ' = ']);       % меняем установки слайдера
        set(menu_handles.text12,'String','1');
        set(menu_handles.Aslider,'Value',1,'Max',40,'Min',1,'SliderStep',[1/39 10/39]);
end


% СПИСОК ФИЛЬТРОВ
function FilterType_Callback(~,~,menu_handles)

global Original;        % зашумленный вариант

FilterType = get(menu_handles.FilterType,'Value');   %считываем значение выбранного фильтра

FilterWithMaskTable = [2 5 11 28];                         % номера фильтров, которым нужно 1я таблица
FilterWithMaskTable1 = 5;                         % номера фильтров, которым нужно 2я таблица
FilterWithMenu1 = [2 6 8 9 11 13:14 19 22 24:28];
FilterWithMenu2 = [2:6 7 9 10 11 14 25:26 28:30 34:35];                       % номера фильтров, которым нужно 2е меню
FilterWithMenu3 = [4 9 15 17 18 25 29:31 34];        % номера фильтров, которым нужно 3е меню

                                                % номера фильтров, которым нужны слайдеры  
FilterWith_FirstSlider = [3 5:9 10:12 13 15:18 20:23 24:27 29 31:33 35];        
FilterWith_SecondSlider = [4 5:9 10:12 16 29 32:35];      
FilterWith_ThirdSlider = [5 7:11 16 33 34];
FilterWith_FourthSlider = [4 5 7:10 29 33:35];
FilterWith_FifthSlider = [8 9 33];
FilterWith_SixthSlider = 9;
FilterWith_SeventhSlider = [9 29 34];
FilterWith_EigthSlider = 9;

FilterWith_Exp_alpha_Button = [5 6 8 11 33];    % фильтры с кнопками
FilterWith_Exp_beta_Button = [4:6 32];        
        
FilterWithIndends = [2 6 8 11 13:14 19:27];  % фильтры с выбором типа расширения границ

% прячем, устанавливаем в 1 и активируем все элементы, а потом открываем то, что нужно
ItemsToHide = get(menu_handles.uipanel3,'Children');
set(ItemsToHide,'Visible','off','Enable','on');
set(menu_handles.FilterType,'Visible','on');
set(menu_handles.IndentMenu,'String',{'зеркальное','нули','круговое','копия'});
set(menu_handles.MaskText,'String','');
set([...
    menu_handles.IndentMenu;...
    menu_handles.FiltParMenu1;...
    menu_handles.FiltParMenu2;...
    menu_handles.FiltParMenu3;...
    ],'Value',1);

%%%% смотрим, какие элементы нужно показать
if any(FilterWithIndends == FilterType)       % если выбранному фильтру нужно меню расширения границ
   set([menu_handles.IndentMenu; menu_handles.IndentText],'Visible','on');
end

if any(FilterWithMenu1 == FilterType)       % если выбранному фильтру нужно 1е меню
   set([menu_handles.FiltParMenu1; menu_handles.FiltParText1],'Visible','on');
end

if any(FilterWithMenu2 == FilterType)       % если выбранному фильтру нужно 2е меню
    set([menu_handles.FiltParMenu2; menu_handles.FiltParText2],'Visible','on');
end

if any(FilterWithMenu3 == FilterType)       % если выбранному фильтру нужно 3е меню
    set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on');
end

if any(FilterWithMaskTable == FilterType)    % если выбранному фильтру нужно меню масок
    set([menu_handles.MaskText menu_handles.MaskTable],'Visible','on');
end

if any(FilterWithMaskTable1 == FilterType)    % если выбранному фильтру нужно меню масок
    set([menu_handles.MaskText menu_handles.MaskTable1],'Visible','on');
end

if any(FilterWith_FirstSlider == FilterType)       % если выбранному фильтру нужен 1й слайдер
    set([menu_handles.AlphaText;...
        menu_handles.AlphaSlider;...
        menu_handles.AlphaValText],'Visible','on');
end

if  any(FilterWith_SecondSlider == FilterType)       % если выбранному фильтру нужен 2й слайдер
    set([menu_handles.BetaText;
        menu_handles.BetaSlider;...
        menu_handles.BetaValText],'Visible','on');
end

if  any(FilterWith_ThirdSlider == FilterType)       % если выбранному фильтру нужен 3й слайдер
    set([menu_handles.GammaText;
        menu_handles.GammaSlider;...
        menu_handles.GammaValText],'Visible','on');
end

if  any(FilterWith_FourthSlider == FilterType)       % если выбранному фильтру нужен 4й слайдер
    set([menu_handles.DeltaText;
        menu_handles.DeltaSlider;...
        menu_handles.DeltaValText],'Visible','on');
end

if  any(FilterWith_FifthSlider == FilterType)       % если выбранному фильтру нужен 5й слайдер
    set([menu_handles.EpsilonText;
        menu_handles.EpsilonSlider;...
        menu_handles.EpsilonValText],'Visible','on');
end

if  any(FilterWith_SixthSlider == FilterType)       % если выбранному фильтру нужен 6й слайдер
    set([menu_handles.ZetaText;
        menu_handles.ZetaSlider;...
        menu_handles.ZetaValText],'Visible','on');
end

if  any(FilterWith_SeventhSlider == FilterType)       % если выбранному фильтру нужен 7й слайдер
    set(menu_handles.EtaSlider,'Visible','on');
end

if  any(FilterWith_EigthSlider == FilterType)       % если выбранному фильтру нужен 8й слайдер
    set([menu_handles.TetaText;
        menu_handles.TetaSlider;...
        menu_handles.TetaValText],'Visible','on');
end

if  any(FilterWith_Exp_alpha_Button == FilterType)       % если выбранному фильтру нужны кнопки построения графиков
    set(menu_handles.FiltParButton1,'Visible','on');
end

if  any(FilterWith_Exp_beta_Button == FilterType)       % если выбранному фильтру нужны кнопки построения графиков
    set(menu_handles.FiltParButton2,'Visible','on');
end

% установки параметров в зависимости от фильтра
switch FilterType
    case 1       % БЕЗ ОБРАБОТКИ
        
    case 2       % МЕДИАННЫЕ
        set(menu_handles.FiltParText1,'String','Размер маски');
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9'});
        set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',34,...
            'Position',[400 5 182 182],...
            'ColumnWidth',{60 60 60});
        set(menu_handles.MaskText,'String','Маска фильтра','Position',[400 200 182 18]);
        
        set(menu_handles.FiltParText2,'String','Выбор медианы');
        set(menu_handles.FiltParMenu2,'String',{'классический','мин. разности','адаптивный','N-мерный'}); 
        
        set(menu_handles.FiltParText3,'String','Порядок N');
        set(menu_handles.FiltParMenu3,'String',{'1';'2';'3';char(8734)});
        
        set(menu_handles.IndentMenu,'String',{'зеркальное','нули'});
        
    case 3          % БИНАРИЗАЦИЯ
        
        set(menu_handles.FiltParText1,'String','Размер маски');    
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9','11x11','13x13','15x15','17x17','19x19',...
            '21x21','23x23','25x25','27x27','29x29','31x31','33x33','35x35','37x37','39x39','41x41','43x43','45x45',});
            
        set(menu_handles.FiltParText2,'String','Тип');
        set(menu_handles.FiltParMenu2,'String',{'С глобальным порогом','Оцу',...
                                                'Брэдли-Рота','Ниблэка','Кристиана',...
                                                'Бернсена','Саувола','C адаптивным порогом'});          
        
        set(menu_handles.AlphaText,'String','Порог: ');
        set(menu_handles.AlphaSlider,'Min',1,'Max',255,'Value',100,'SliderStep',[1/254 10/254]);
        set(menu_handles.AlphaValText,'String','100');
        
        set(menu_handles.BetaText,'String','k: ');
        set(menu_handles.BetaSlider,'Min',-1,'Max',1,'Value',0.5,'SliderStep',[0.01/2 0.1/2]);
        set(menu_handles.BetaValText,'String','0.5');        
        
        set(menu_handles.GammaText,'String','R: ');
        set(menu_handles.GammaSlider,'Min',1,'Max',255,'Value',50,'SliderStep',[1/254 1/254]);
        set(menu_handles.GammaValText,'String','50');         
        
        
        set(menu_handles.DeltaText,'String','Размер примитива: ');        
        set(menu_handles.DeltaSlider,'Min',1,'Max',size(Original,1),'Value',1,...
                                    'SliderStep',[1/(size(Original,1)-1) 10/(size(Original,1)-1)]);
        set(menu_handles.DeltaValText,'String','1x1');
        
        set(menu_handles.EtaSlider,'Min',1,'Max',size(Original,2),'Value',1,...
                                    'SliderStep',[1/(size(Original,2)-1) 10/(size(Original,2)-1)]); 
        
    case 4      % МОРФОЛОГИЧЕСКАЯ ОБРАБОТКА (Ч/Б)     
        
        set(menu_handles.FiltParButton2,'String','Показать');            
        
        set(menu_handles.FiltParText2,'String','Операция');
        set(menu_handles.FiltParMenu2,'String',{'Дилатация',...
                                                'Эрозия',...
                                                'Размыкание',...
                                                'Замыкание',...
                                                'Дно шляпы',...
                                                'Верх шляпы',...
                                                'Заполнение отверстий',...
                                                'Очистка границ',...
                                                'Выделение периметра',...
                                                'Конечная эрозия',...
                                                'Успех/неудача',...
                                                'Соединение',...
                                                'Очитка изолированных пикселей',...
                                                'Диагональное заполнение',...
                                                'Н-разбиение',...
                                                'Из фона на передний план',...
                                                'Удаление внутрених пикселей',...
                                                'Сжатие до точки/кольца',...
                                                'Остов',...
                                                'Удаление отростков',...
                                                'Утолщение',...
                                                'Утончение'});      
        
        set(menu_handles.FiltParText3,'String','Примитив');   
        set(menu_handles.FiltParMenu3,'String',{'Ромб',...
                                                'Круг',...
                                                'Линия',...
                                                'Восьмиугольник',...
                                                'Пара точек',...
                                                'Прямоугольник',...
                                                'Пользовательская'});  
        
        Max = floor(min(size(Original,1),size(Original,1))/2)-1;
        set(menu_handles.BetaSlider,'Min',1,'Max',Max,...
                        'Value',1,'SliderStep',[1/(Max-1) 10/(Max-1)]);
        set(menu_handles.BetaText,'String','R = ');
        set(menu_handles.BetaValText,'String','1');       
        
        set(menu_handles.DeltaSlider,'Min',0,'Max',1000,'Value',1,'SliderStep',[1/1000 10/1000]);
        set(menu_handles.DeltaText,'String','Кол-во итераций:');
        set(menu_handles.DeltaValText,'String','1');
        
    case 5      % ПОЛУТОНОВАЯ МОРФОЛОГИЧЕСКАЯ ОБРАБОТКА
        
        set(menu_handles.FiltParText2,'String','Операция');
        set(menu_handles.FiltParMenu2,'String',{'Дилатация',...
                                                'Эрозия',...
                                                'Размыкание',...
                                                'Замыкание',...
                                                'Дно шляпы',...
                                                'Верх шляпы',...
                                                'Заполнение отверстий',...
                                                'Очистка границ',...
                                                'Выделение периметра',...
                                                'Конечная эрозия',...
                                                'Расширенный минимум',...
                                                'Расширенный максимум',...
                                                'Н-минимум',...
                                                'Н-максимум',...
                                                'Локальный минимум',...
                                                'Локальный максимум'});
                                            
        set(menu_handles.FiltParText3,'String','Кол-во связей');
        
        switch size(Original,3)
            case 1
                conn = {'4','8'};
            case 3
                conn = {'6','18','26'};                
            otherwise                
                conn = {'минимальное','максиамльное'};    
        end
        
        set(menu_handles.FiltParMenu3,'String',conn); 
                                            
        set(menu_handles.FiltParButton1,'String','Задать');
        set(menu_handles.FiltParButton2,'String','Показать');
        
        set(menu_handles.AlphaText,'String','Яркость: ');
        set(menu_handles.AlphaSlider,'Min',0,'Max',255,'Value',100,'SliderStep',[1/255 10/255]);
        set(menu_handles.AlphaValText,'String','100');
        
        set(menu_handles.BetaText,'String','Строка: ');
        set(menu_handles.BetaSlider,'Min',1,'Max',7,'Value',1,'SliderStep',[1/6 1/6]);
        set(menu_handles.BetaValText,'String','1');        
        
        set(menu_handles.GammaText,'String','Столбец:');
        set(menu_handles.GammaSlider,'Min',1,'Max',7,'Value',1,'SliderStep',[1/6 1/6]);
        set(menu_handles.GammaValText,'String','1'); 
        
        set(menu_handles.DeltaText,'String','Кол-во итераций:');
        set(menu_handles.DeltaSlider,'Min',0,'Max',1000,'Value',1,'SliderStep',[1/1000 10/1000]);
        set(menu_handles.DeltaValText,'String','1');
        
        m = zeros(7);
        m(4,4) = 1;
        
        set(menu_handles.MaskText,'String','Лог-яркостная маска','Position',[400 256 182 18]);        
        set(menu_handles.MaskTable, 'Data',m,'FontSize',8,...
            'Position',[405 130 170 128],...
            'ColumnWidth',{24 24 24 24 24 24 24});        
        
        set(menu_handles.MaskTable1, 'Data',100*m,'FontSize',8,...
            'Position',[405 1 170 128],...
            'ColumnWidth',{24 24 24 24 24 24 24});
        
    case 6      % БИЛАТЕРАЛЬНЫЕ 
        
        set(menu_handles.FiltParText1,'String','Размер маски');   
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9'}); 
        set(menu_handles.FiltParText3,'String','Порядок');    
        set(menu_handles.FiltParMenu3,'String',{'1';'2';'3';char(8734)});
        set(menu_handles.FiltParText2,'String','Целевой пиксель');
        set(menu_handles.FiltParMenu2,'String',{'исходный','медиана','ср. арифметическое','мин. разность','адаптивная медиана','N-мерная медиана'});
        
        set(menu_handles.AlphaSlider,'Min',0.01,'Max',3,'Value',0.01,'SliderStep',[0.01/2.99 0.1/2.99]);
        set(menu_handles.AlphaText,'String',[char(945) ' = ']);
        set(menu_handles.AlphaValText,'String','0.01');
        
        set(menu_handles.BetaSlider,'Min',0.01,'Max',3,'Value',0.01,'SliderStep',[0.01/2.99 0.1/2.99]);
        set(menu_handles.BetaText,'String',[char(946) ' = ']);
        set(menu_handles.BetaValText,'String','0.01');
        
        set(menu_handles.FiltParButton1,'String','exp(alpha)');
        set(menu_handles.FiltParButton2,'String','exp(beta)');
               
    case 7      % СЛЕПАЯ ОБРАТНАЯ СВЕРТКА
         
        set(menu_handles.FiltParText2,'String','Режим');
        set(menu_handles.FiltParMenu2,'String',{'Без очистки "звонов"','Очистка "звонов"'});
        
        NumOfRows = floor(size(Original,1) / 2);       % половинное кол-во строк для PSF
        NumOfCols = floor(size(Original,2) / 2);       % половинное кол-во столбцов для PSF
        
        set(menu_handles.AlphaSlider,'Min',1,'Max',NumOfRows,'Value',10,'SliderStep',[1/(NumOfRows-2) 10/(NumOfRows-2)]);
        set(menu_handles.AlphaText,'String','Кол-во строк:');
        set(menu_handles.AlphaValText,'String','10');
        
        set(menu_handles.BetaSlider,'Min',1,'Max',NumOfCols,'Value',10,'SliderStep',[1/(NumOfCols-2) 10/(NumOfCols-2)]);
        set(menu_handles.BetaText,'String','Кол-во столбцов:');
        set(menu_handles.BetaValText,'String','10'); 
        
        set(menu_handles.GammaSlider,'Min',1,'Max',100,'Value',10,'SliderStep',[1/99 10/99]);
        set(menu_handles.GammaText,'String','Кол-во итераций:');
        set(menu_handles.GammaValText,'String','10');
        
        set(menu_handles.DeltaSlider,'Min',0,'Max',255,'Value',0,'SliderStep',[1/255 10/255]);
        set(menu_handles.DeltaText,'String','Порог:');
        set(menu_handles.DeltaValText,'String','0');  
        
    case 8      % ФИЛЬТР ГАБОРА
        
        set(menu_handles.FiltParButton1,'String','Маска');
        
        set(menu_handles.FiltParText1,'String','Размер маски');    
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
        
        set(menu_handles.DeltaText,'String',[char(968) ', гр.:']);
        set(menu_handles.DeltaSlider,'Min',0,'Max',360,'Value',0,'SliderStep',[1/360 10/360]);
        set(menu_handles.DeltaValText,'String','0');    
                        
        set(menu_handles.EpsilonText,'String',[char(952) ', гр.:']);
        set(menu_handles.EpsilonSlider,'Min',0,'Max',360,'Value',0,'SliderStep',[1/360 10/360]);
        set(menu_handles.EpsilonValText,'String','0'); 
        
    case 9      % ПРЕОБРАЗОВАНИЕ ХАФА
        
        set(menu_handles.FiltParText1,'String','Результат');
        set(menu_handles.FiltParMenu1,'String',{'Изображение','Изображение и SHT'});
        
        set(menu_handles.FiltParText2,'String',char(916,920,',',186,': ')');   % ДельтаТета
        set(menu_handles.FiltParMenu2,'String',{'0.1','0.2','0.5','1','2','5','10','12','15','20','45','60'});
        set(menu_handles.FiltParMenu2,'Value',3);
        
        set(menu_handles.FiltParText3,'String','Порог, % от max: ');
        set(menu_handles.FiltParMenu3,'String',{'1','5','10','20','25','40','50','60','70','75','80','85',...
                                                '90','91','92','93','94','95','96','97','98','99','100'});
        set(menu_handles.FiltParMenu3,'Value',9);
        
        BW = Original(:,:,1);                   % 2D изображение 
        [MinMask,MaxMask] = SuppressMaskRecount(BW,-90,89,1,1);
        
        set(menu_handles.AlphaText,'String',[char(920) 'ниж.,' char(186) ': ']); % Тета
        set(menu_handles.AlphaSlider,'Min',-90,'Max',88,'Value',-90,'SliderStep',[1/178 10/178]);
        set(menu_handles.AlphaValText,'String','-90');
        
        set(menu_handles.BetaText,'String',[char(920) 'верх. ' char(186) ': ']); % Тета
        set(menu_handles.BetaSlider,'Min',-89,'Max',89,'Value',89,'SliderStep',[1/178 10/178]);
        set(menu_handles.BetaValText,'String','89'); 
        
        set(menu_handles.GammaText,'String',char(916,961,': ')'); % ДельтаРо
        set(menu_handles.GammaSlider,'Min',0.1,'Max',floor(norm(size(BW))*9)/10,'Value',1,...
                                    'SliderStep',[0.1/(floor(norm(size(BW))*9)/10) 1/(floor(norm(size(BW))*9)/10)]);
        set(menu_handles.GammaValText,'String','1');
        
        set(menu_handles.DeltaText,'String','Маска подавления: ');        
        set(menu_handles.DeltaSlider,'Min',MinMask(1),'Max',MaxMask(1),'Value',MinMask(1),...
                                    'SliderStep',[2/(MaxMask(1)-MinMask(1)) 10/(MaxMask(1)-MinMask(1))]);
        set(menu_handles.DeltaValText,'String',[num2str(MinMask(1)) 'x' num2str(MinMask(2))]);
        
        set(menu_handles.EtaSlider,'Min',MinMask(2),'Max',MaxMask(2),'Value',MinMask(2),...
                                    'SliderStep',[2/(MaxMask(2)-MinMask(2)) 10/(MaxMask(2)-MinMask(2))]);        
                        
        set(menu_handles.EpsilonText,'String','Мин. длина линии: ');
        set(menu_handles.EpsilonSlider,'Min',2,'Max',norm(size(BW)),'Value',5,...
                                    'SliderStep',[1/(norm(size(BW))-2) 10/(norm(size(BW))-2)]);
        set(menu_handles.EpsilonValText,'String','5');        
        
        set(menu_handles.ZetaText,'String','Макс. разрыв: ');
        set(menu_handles.ZetaSlider,'Min',1,'Max',norm(size(BW)),'Value',3,...
                                    'SliderStep',[1/(norm(size(BW))-1) 10/(norm(size(BW))-1)]);
        set(menu_handles.ZetaValText,'String','3');        
                        
        set(menu_handles.TetaText,'String','Кол-во пиков: ');
        set(menu_handles.TetaSlider,'Min',1,'Max',1000,'Value',5,'SliderStep',[1/999 10/999]);
        set(menu_handles.TetaValText,'String','5')
        
    case 10     % ДЕКОРРЕЛЯЦИОННОЕ РАСТЯЖЕНИЕ        
        
        set(menu_handles.FiltParText2,'String','Тип');
        set(menu_handles.FiltParMenu2,'String',{'Без контрастирования','С контрастированием'}); 
        
        
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
                        
        set(menu_handles.EpsilonText,'String','Нижний порог: ');
        set(menu_handles.EpsilonSlider,'Min',0,'Max',254,'Value',0,'SliderStep',[1/254 10/254]);
        set(menu_handles.EpsilonValText,'String','0');        
        
        set(menu_handles.ZetaText,'String','Верхний порог: ');
        set(menu_handles.ZetaSlider,'Min',1,'Max',255,'Value',255,'SliderStep',[1/254 10/254]);
        set(menu_handles.ZetaValText,'String','255');
        
    case 11                 % ПРОИЗВОЛЬНЫЙ ФИЛЬТР(КОРРЕЛЯЦИОННЫЙ)
          
        set(menu_handles.MaskText,'String','Маска фильтра','Position',[400 200 182 18]);
        set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',30,...
            'Position',[400 5 182 164],...
            'ColumnWidth',{60 60 60});
        
        set(menu_handles.FiltParText1,'String','Размер маски');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9'});
        
        set(menu_handles.FiltParText2,'String','Результат обработки');
        set(menu_handles.FiltParMenu2,'String',{'Не вычитать','Вычитать'}); 
        
        set(menu_handles.FiltParButton1,'String','Задать');
        
        set(menu_handles.AlphaSlider,'Min',-99,'Max',99,'Value',1,'SliderStep',[1/198 10/198]);
        set(menu_handles.AlphaText,'String','Значение: ');
        set(menu_handles.AlphaValText,'String','1');              
        
        set(menu_handles.BetaText,'String','Строка:');
        set(menu_handles.BetaSlider,'Min',1,'Max',3,'Value',1,'SliderStep',[1/2 1/2]);
        set(menu_handles.BetaValText,'String','1'); 
        
        set(menu_handles.GammaText,'String','Столбец:');
        set(menu_handles.GammaSlider,'Min',1,'Max',3,'Value',1,'SliderStep',[1/2 1/2]);
        set(menu_handles.GammaValText,'String','1');
        
        
    case 12                 % ФИЛЬТР ВИННЕРА
        set(menu_handles.AlphaSlider,'Min',1,'Max',size(Original,2),'Value',5,'SliderStep',[1/(size(Original,2)-1) 10/(size(Original,2)-1)]);
        set(menu_handles.AlphaText,'String','Длина области: ');
        set(menu_handles.AlphaValText,'String','5');
        
        set(menu_handles.BetaText,'String','Ширина области: ');
        set(menu_handles.BetaSlider,'Min',1,'Max',size(Original,1),'Value',5,'SliderStep',[1/(size(Original,1)-1) 10/(size(Original,1)-1)]);
        set(menu_handles.BetaValText,'String','5'); 
        
        
    case {13,22}      % НИЗКИХ ЧАСТОТ ГАУССА, ГАУССА+ЛАПЛАСА
        
        set(menu_handles.FiltParText1,'String','Размер маски');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9'});
        
        set(menu_handles.AlphaSlider,'Min',0.01,'Max',5,'Value',0.5,'SliderStep',[0.01/4.99 0.1/4.99]);
        set(menu_handles.AlphaText,'String',[char(963) ' = ']);
        set(menu_handles.AlphaValText,'String','0.5');
                
    case 14                 % УСРЕДНЯЮЩИЕ
        
        set(menu_handles.FiltParText1,'String','Размер маски');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9'});
        
        set(menu_handles.FiltParText2,'String','Тип:');
        set(menu_handles.FiltParMenu2,'String',{'среднее арифметическое',...
                                                'среднее геометрическое',...
                                                'гармоническое среднее',...
                                                'контргармоническое среднее',...
                                                'максимум',...
                                                'минимум',...
                                                'средняя точка',...
                                                'среднее усеченное'}); 
                
    case 15            % СОБЕЛЯ
        
        set(menu_handles.AlphaSlider,'Min',0,'Max',255,'Value',50,'SliderStep',[1/255 10/255]);
        set(menu_handles.AlphaText,'String','Порог: ');
        set(menu_handles.AlphaValText,'String','50');
        
        set(menu_handles.FiltParText3,'String','Направление');
        set(menu_handles.FiltParMenu3,'Value',1,'String',{  'Гориз. (утончение)';...
                                                            'Гориз. (без утончения)';...
                                                            'Верт. (утончение)';...
                                                            'Верт. (без утончения)';...
                                                            'Оба (утончение)';...
                                                            'Оба (без утончения)'});
        
    case 16                 % ФИЛЬТР КЕННИ    
        
        set(menu_handles.AlphaSlider,'Min',-1,'Max',149,'Value',50,'SliderStep',[1/150 10/150]);
        set(menu_handles.AlphaText,'String','Нижний порог: ');
        set(menu_handles.AlphaValText,'String','50');
        
        set(menu_handles.BetaText,'String','Верхний порог: ');
        set(menu_handles.BetaSlider,'Min',51,'Max',256,'Value',150,'SliderStep',[1/205 10/205]);
        set(menu_handles.BetaValText,'String','150'); 
        
        set(menu_handles.GammaText,'String',[char(963) ' = ']);
        set(menu_handles.GammaSlider,'Min',0.01,'Max',3,'Value',0.5,'SliderStep',[0.01/2.99 0.1/2.99]);
        set(menu_handles.GammaValText,'String','0.5');
        
    case 17                 % ПРЕВИТТА
        set(menu_handles.AlphaSlider,'Min',0,'Max',255,'Value',50,'SliderStep',[1/255 10/255]);
        set(menu_handles.AlphaText,'String','Порог: ');
        set(menu_handles.AlphaValText,'String','50');
        
        set(menu_handles.FiltParText3,'String','Направление');
        set(menu_handles.FiltParMenu3,'Value',1,'String',{   'Горизонтальное';...
                                                            'Вертикальное';...
                                                            'Оба'});
                                                        
    case 18                 % ФИЛЬТР РОБЕРСТА
        
        set(menu_handles.AlphaSlider,'Min',0,'Max',255,'Value',50,'SliderStep',[1/255 10/255]);
        set(menu_handles.AlphaText,'String','Порог: ');
        set(menu_handles.AlphaValText,'String','50');
        
        set(menu_handles.FiltParText3,'String','Режим');
        set(menu_handles.FiltParMenu3,'Value',1,'String',{'Утончение';'Без уточнения'});
        
    case 19                 % ДИСКОВЫЙ     
        
        set(menu_handles.FiltParText1,'String','Размер маски');      
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9','11x11','13x13','15x15','17x17','19x19'});
        
    case 20                 % ФИЛЬТР ЛАПЛАСА ФВЧ 
        
        set(menu_handles.AlphaSlider,'Min',0.01,'Max',1,'Value',0.2,'SliderStep',[0.01/0.99 0.1/0.99]);
        set(menu_handles.AlphaText,'String','СКО = ');
        set(menu_handles.AlphaValText,'String','0.2');
                
    case 21                 % ПОВЫШЕНИЯ РЕЗКОСТИ
        
        set(menu_handles.AlphaSlider,'Min',0,'Max',1,'Value',0.1,'SliderStep',[0.01 0.1]);
        set(menu_handles.AlphaText,'String','a = ');
        set(menu_handles.AlphaValText,'String','0.1'); 
                        
    case 23                 % АДАПТИВНЫЙ МЕДИАННЫЙ
        
        set(menu_handles.FiltParMenu1,'String',{'3x3'});
        set(menu_handles.IndentMenu,'String',{'зеркальное','нули'});
        M = min(size(Original,1),size(Original,2));
        M = M - 1 + mod(M,2);             % делаем нечетным        
        
        set(menu_handles.AlphaSlider,'Min',3,'Max',M,'Value',5,'SliderStep',[2/(M-3) 10/(M-3)]);
        set(menu_handles.AlphaText,'String','Smax = ');
        set(menu_handles.AlphaValText,'String','5');
        
    case 24             % ГАММА - ФИЛЬТР
        
        set(menu_handles.FiltParText1,'String','Размер маски');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9','11х11'});
        
        set(menu_handles.AlphaText,'String','Число выборок: ');
        set(menu_handles.AlphaSlider,'Min',1,'Max',25,'Value',1,'SliderStep',[1/24 10/24]);
        set(menu_handles.AlphaValText,'String','1'); 
        
    case 25             % ФИЛЬТРЫ ЛИ
        
        set(menu_handles.FiltParText1,'String','Размер маски');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9','11х11'});
        
        set(menu_handles.FiltParText2,'String','Тип фильтра');
        set(menu_handles.FiltParMenu2,'String',{'оригинальный','улучшенный'}); 
        
        set(menu_handles.FiltParText3,'String','Модель помехи');
        set(menu_handles.FiltParMenu3,'String',{'аддитивная','мультипликативная','аддитивная + мультипликативная'});
              
       
        set(menu_handles.AlphaText,'String',[char(963) char(178) ' адд. помехи: ']);
        set(menu_handles.AlphaSlider,'Min',1,'Max',255,'Value',50,'SliderStep',[1/254 10/254]);
        set(menu_handles.AlphaValText,'String','50'); 
        
        set(menu_handles.BetaText,'String',[char(956) ' адд. помехи: ']);
        set(menu_handles.BetaSlider,'Min',-255,'Max',255,'Value',0,'SliderStep',[1/510 10/510]);
        set(menu_handles.BetaValText,'String','0'); 
        
        set(menu_handles.GammaText,'String',[char(963) char(178) ' мульт. помехи: ']);
        set(menu_handles.GammaSlider,'Min',1,'Max',255,'Value',50,'SliderStep',[1/254 10/254]);
        set(menu_handles.GammaValText,'String','50');
        
        set(menu_handles.DeltaText,'String',[char(956) ' мульт. помехи: ']);
        set(menu_handles.DeltaSlider,'Min',-255,'Max',255,'Value',0,'SliderStep',[1/510 10/510]);
        set(menu_handles.DeltaValText,'String','0');        
                        
        set(menu_handles.EpsilonText,'String','Число выборок: ');
        set(menu_handles.EpsilonSlider,'Min',1,'Max',25,'Value',1,'SliderStep',[1/24 10/24]);
        set(menu_handles.EpsilonValText,'String','1');   
        
        set(menu_handles.ZetaText,'String','Коэфф. затухания: ');
        set(menu_handles.ZetaSlider,'Min',0.01,'Max',5,'Value',1,'SliderStep',[0.01/4.99 0.1/4.99]);
        set(menu_handles.ZetaValText,'String','1');   
        
    case 26                 % ФРОСТА       
                        
        set(menu_handles.FiltParText1,'String','Размер маски');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9','11х11'});
        
        set(menu_handles.FiltParText2,'String','Тип фильтра');
        set(menu_handles.FiltParMenu2,'String',{'оригинальный','улучшенный'}); 
        
        
        set(menu_handles.AlphaText,'String','Коэфф. затухания: ');
        set(menu_handles.AlphaSlider,'Min',0.01,'Max',5,'Value',1,'SliderStep',[0.01/4.99 0.1/4.99]);
        set(menu_handles.AlphaValText,'String','1'); 
        
        set(menu_handles.BetaText,'String','Число выборок: ');
        set(menu_handles.BetaSlider,'Min',1,'Max',25,'Value',1,'SliderStep',[1/24 10/24]);
        set(menu_handles.BetaValText,'String','1');   
                
    case 27                 % КУАНА 
        
        set(menu_handles.FiltParText1,'String','Размер маски');  
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9','11х11'});
        
        set(menu_handles.AlphaText,'String','Число выборок: ');
        set(menu_handles.AlphaSlider,'Min',1,'Max',25,'Value',1,'SliderStep',[1/24 10/24]);
        set(menu_handles.AlphaValText,'String','1'); 
         
    case 28                 % ФИЛЬТР ЛОКАЛЬНЫХ СТАТИСТИК        
        
        set(menu_handles.FiltParText1,'String','Размер маски');      
        set(menu_handles.FiltParMenu1,'String',{'3x3','5x5','7x7','9x9'});
        
        set(menu_handles.FiltParText2,'String','Тип:');
        set(menu_handles.FiltParMenu2,'String',{'Предельный',...
                                                'Энтропийный',...
                                                'СКО'});       
        
        set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',34,...
            'Position',[400 5 182 182],...
            'ColumnWidth',{60 60 60});
        
    case 29                 % ПОРОГОВАЯ ОБРАБОТКА
        
        set(menu_handles.FiltParText3,'String','Обработка');   
        set(menu_handles.FiltParMenu3,'String',{'Пропускание','Подавление'});
        
        if size(Original,3) == 3
            str = {'RGB';'HSV'};
        else
            str = {'RGB'};
        end
        
        set(menu_handles.FiltParText2,'String','Цветовая модель');    
        set(menu_handles.FiltParMenu2,'String',str);
        
        
        set(menu_handles.AlphaText,'String','Значение обработки: ');
        set(menu_handles.AlphaSlider,'Min',0,'Max',255,'Value',1,'SliderStep',[1/255 10/255]);
        set(menu_handles.AlphaValText,'String','0'); 
        
        set(menu_handles.BetaText,'String','Номер канала:');
        set(menu_handles.BetaValText,'String','1'); 
        
        if size(Original,3) == 1
            set(menu_handles.BetaSlider,'Enable','off');
        else
            set(menu_handles.BetaSlider,'Min',1,'Max',size(Original,3),...
                'Value',1,'SliderStep',[1/(size(Original,3)-1) 1/(size(Original,3)-1)]);
        end
        
        set(menu_handles.DeltaText,'String','Полоса: ');        
        set(menu_handles.DeltaSlider,'Min',0,'Max',254,'Value',0,...
                                    'SliderStep',[1/254 10/254]);
        set(menu_handles.DeltaValText,'String',['0 ' char(8804) ' I ' char(8804) ' 255']);
        
        set(menu_handles.EtaSlider,'Min',1,'Max',255,'Value',255,'SliderStep',[1/254 10/254]);                        
        
    case 30                 % ГРАДИЕНТ        
        
        set(menu_handles.FiltParText2,'String','Результат');
        set(menu_handles.FiltParMenu2,'String',{'Амплитуда градиента',...
                                                'Направление градиента',...
                                                'Направленный градиент по Ох',...
                                                'Направленный градиент по Оy'}); 
        
        set(menu_handles.FiltParText3,'String','Метод');
        set(menu_handles.FiltParMenu3,'String',{'Собеля','Превитта','Центральной разности','Средней разности','Робертса'});         
        
    case 31                 % ЭКВАЛИЗАЦИЯ ГИСТОГРАММЫ
        
        set(menu_handles.AlphaSlider,'Min',1,'Max',255,'Value',64,'SliderStep',[1/254 10/254]);
        set(menu_handles.AlphaValText,'String','64'); 
        set(menu_handles.AlphaText,'String','Число уровней:');
        
        set(menu_handles.FiltParText3,'String','Цветовая модель');        
        if size(Original,3) == 3
            set(menu_handles.FiltParMenu3,'Value',1,'String',{'RGB';'HSV'});
        else
            set([menu_handles.FiltParMenu3 menu_handles.FiltParText3],'Visible','off');
        end
        
    case 32             % КВАНТОВАНИЕ        
        
        set(menu_handles.AlphaSlider,'Min',1,'Max',7,'Value',4,'SliderStep',[1/6 1/6]);
        set(menu_handles.AlphaValText,'String','4'); 
        set(menu_handles.AlphaText,'String','Бит/пиксель: ');      
        
        set(menu_handles.FiltParButton2,'String','Iвых(Iвх)');
                
        set(menu_handles.BetaText,'String','Коэффициент нелинейности: ');
        set(menu_handles.BetaSlider,'Min',0.01,'Max',20,'Value',1,'SliderStep',[0.01/19.99 0.1/19.99]);
        set(menu_handles.BetaValText,'String','1');         
        
    case 33             % КОНТРАСТИРОВАНИЕ C ГАММА-КОРРЕКЦИЕЙ
        
        set(menu_handles.AlphaText,'String','Гамма: ');
        set(menu_handles.AlphaSlider,'Min',0.01,'Max',20,'Value',1,'SliderStep',[0.01/19.99 0.1/19.99]);
        set(menu_handles.AlphaValText,'String','1');
        
        set(menu_handles.BetaText,'String','Верхний порог: ');
        set(menu_handles.BetaSlider,'Min',0,'Max',254,'Value',0,'SliderStep',[1/254 10/254]);
        set(menu_handles.BetaValText,'String','0'); 
        
        set(menu_handles.GammaText,'String','Нижний порог: ');
        set(menu_handles.GammaSlider,'Min',1,'Max',255,'Value',255,'SliderStep',[1/254 10/254]);
        set(menu_handles.GammaValText,'String','255');
        
        set(menu_handles.DeltaText,'String','Нижний порог: ');
        set(menu_handles.DeltaSlider,'Min',0,'Max',254,'Value',0,'SliderStep',[1/254 10/254]);
        set(menu_handles.DeltaValText,'String','0');
        
        set(menu_handles.EpsilonText,'String','Верхний порог: ');
        set(menu_handles.EpsilonSlider,'Min',1,'Max',255,'Value',255,'SliderStep',[1/254 10/254]);
        set(menu_handles.EpsilonValText,'String','255');
        
        set(menu_handles.FiltParButton1,'String','Iвых(Iвх)');
        
    case 34         % ДЕТЕКТОР ОКРУЖНОСТЕЙ        
        
        set(menu_handles.FiltParText2,'String','Алгоритм');
        set(menu_handles.FiltParMenu2,'Value',1,'String',{'Хафа';'Атертона и Кирбисона'});
        
        set(menu_handles.FiltParText3,'String','Цели');
        set(menu_handles.FiltParMenu3,'Value',1,'String',{'Темнее фона';'Светлее фона'});
        
        set(menu_handles.BetaText,'String','Чувствительность: ');
        set(menu_handles.BetaSlider,'Min',0.01,'Max',1,'Value',0.5,'SliderStep',[0.01/0.99 0.1/0.99]);
        set(menu_handles.BetaValText,'String','0.5'); 
        
        set(menu_handles.GammaText,'String','Градиентный порог: ');
        set(menu_handles.GammaSlider,'Min',1,'Max',255,'Value',100,'SliderStep',[1/254 10/254]);
        set(menu_handles.GammaValText,'String','100');
        
        MS = floor(min(size(Original,2),size(Original,1))/2);
        if MS <= 10
           MS = 11; 
        end
        
        set(menu_handles.DeltaText,'String','Целевой радиус: ');        
        set(menu_handles.DeltaSlider,'Min',10,'Max',MS,'Value',10,...
                                    'SliderStep',[1/(MS-10) 10/(MS-10)]);
        set(menu_handles.DeltaValText,'String',['10' char(8804) 'R' char(8804) '11']);
        
        set(menu_handles.EtaSlider,'Min',10,'Max',MS,'Value',11,...
                                    'SliderStep',[1/(MS-10) 10/(MS-10)]); 
                                
    case 35     % ДЕТЕКТОР КЛЮЧЕВЫХ ТОЧЕК
        
        set(menu_handles.FiltParText2,'String','Детектор');
        set(menu_handles.FiltParMenu2,'String',{'BRISK',...
                                                'углов (FAST)',...
                                                'углов (Харриса)',...
                                                'углов (мин. собств. значений)',...
                                                'SURF'});
       
        set(menu_handles.AlphaText,'String','Мин. качество: ');
        set(menu_handles.AlphaSlider,'Min',0,'Max',1,'Value',0.1,'SliderStep',[0.01/1 0.1/1]);
        set(menu_handles.AlphaValText,'String','0.1');
        
        set(menu_handles.BetaText,'String','Мин. контраст: ');
        set(menu_handles.BetaSlider,'Min',0.01,'Max',0.99,'Value',0.1,'SliderStep',[0.01/0.98 0.1/0.98]);
        set(menu_handles.BetaValText,'String','0.1'); 
        
        set(menu_handles.DeltaText,'String','Число октав: ');
        set(menu_handles.DeltaSlider,'Min',0,'Max',6,'Value',2,'SliderStep',[1/6 1/6]);
        set(menu_handles.DeltaValText,'String','2');
        
        set(menu_handles.GammaText,'String','Размер фильтра: ');
        
        set(menu_handles.EpsilonText,'String','Уровней масштаба: ');
        set(menu_handles.EpsilonSlider,'Min',3,'Max',10,'Value',3,'SliderStep',[1/7 10/7]);
        set(menu_handles.EpsilonValText,'String','3');
        
        set(menu_handles.ZetaText,'String','Порог: ');
        set(menu_handles.ZetaSlider,'Min',1,'Max',20000,'Value',500,'SliderStep',[1/19999 10/19999]);
        set(menu_handles.ZetaValText,'String','500'); 
end


% СПИСОК "ИСКАЖЕНИЕ-ОБРАБОТКА"
function NoiseFilterString_Callback(~, ~, menu_handles)

% меняем значение слайдера удаления и текстовой строки
Value = get(menu_handles.NoiseFilterString,'Value');
set(menu_handles.DeleteSlider,'Value',Value);
set(menu_handles.DeleteNumber,'String',num2str(Value));


% ПЕРВЫЙ СПИСОК
function FiltParMenu1_Callback(~, ~, menu_handles)

% формируем таблицу маски

NumOfRows = get(menu_handles.FiltParMenu1,'Value');

switch get(menu_handles.FilterType,'Value')     % тип обработки
    
    case {2,28}      % медианный фильтр
        
        switch NumOfRows       % считываем значение маски
            
            case 1          % маска 3х3
                
                set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',34,...
                    'Position',[400 5 182 182],...
                    'ColumnWidth',{60 60 60});
                
            case 2          % маска 5х5
                set(menu_handles.MaskTable,'Data',ones(5),'FontSize',19,...
                    'Position',[405 5 177 177],...
                    'ColumnWidth',{35 35 35 35 35});
            case 3          % маска 7х7
                
                set(menu_handles.MaskTable, 'Data',ones(7),'FontSize',12,...
                    'Position',[405 5 177 163],...
                    'ColumnWidth',{25 25 25 25 25 25 25});
            case 4          % маска 9х9
                set(menu_handles.MaskTable, 'Data',ones(9),'FontSize',10,...
                    'Position',[400 5 182 182],...
                    'ColumnWidth',{20 20 20 20 20 20 20 20 20});
        end
        
    case 11     % произвольный фильтр
        
        switch NumOfRows       % считываем значение маски
            
            case 1 
                set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',30,...
                    'Position',[400 5 182 164],...
                    'ColumnWidth',{60 60 60});
                
            case 2          % маска 5х5
                set(menu_handles.MaskTable,'Data',ones(5),'FontSize',16,...
                    'Position',[405 5 177 152],...
                    'ColumnWidth',{35 35 35 35 35});
            case 3          % маска 7х7
                
                set(menu_handles.MaskTable, 'Data',ones(7),'FontSize',11,...
                    'Position',[405 5 177 156],...
                    'ColumnWidth',{25 25 25 25 25 25 25});
            case 4          % маска 9х9
                set(menu_handles.MaskTable, 'Data',ones(9),'FontSize',8,...
                    'Position',[400 5 182 164],...
                    'ColumnWidth',{20 20 20 20 20 20 20 20 20});            
        end
        
        
        set(menu_handles.BetaSlider,'Min',1,'Max',2*NumOfRows+1,'Value',1,'SliderStep',[1/(2*NumOfRows) 1/(2*NumOfRows)]);
        set(menu_handles.BetaValText,'String','1');
        
        set(menu_handles.GammaSlider,'Min',1,'Max',2*NumOfRows+1,'Value',1,'SliderStep',[1/(2*NumOfRows) 1/(2*NumOfRows)]);
        set(menu_handles.GammaValText,'String','1');
        
    case 14         % усредняющие фильтры
        
        if get(menu_handles.FiltParMenu2,'Value') == 8
            
            MaskSize = 2*get(menu_handles.FiltParMenu1,'Value')+1;
            
            set(menu_handles.AlphaSlider,'Min',2,'Max',MaskSize^2-3,'Value',2,...
                'SliderStep',[2/(MaskSize^2-5) 10/(MaskSize^2-5)]);
            
            set(menu_handles.AlphaValText,'String','2');
        end
        
end


% ВТОРОЙ СПИСОК
function FiltParMenu2_Callback(~,~,menu_handles)

global Original;

switch get(menu_handles.FilterType,'Value')     % тип обработки
    
    case 2                                      % медианный фильтр
        if get(menu_handles.FiltParMenu2,'Value') == 1
            set(menu_handles.IndentMenu,'String',{'зеркальное','нули'}); 
            set([menu_handles.MaskTable menu_handles.MaskText],'Visible','on');
        else
            set(menu_handles.IndentMenu,'String',{'зеркальное','нули','круговое','копия'}); 
            set([menu_handles.MaskTable menu_handles.MaskText],'Visible','off');
            
        end        
        
        if get(menu_handles.FiltParMenu2,'Value') == 4
            set([menu_handles.FiltParMenu3 menu_handles.FiltParText3],'Visible','on');
        else
            set([menu_handles.FiltParMenu3 menu_handles.FiltParText3],'Visible','off');
        end
        
    case 3          % бинаризация
        
        switch get(menu_handles.FiltParMenu2,'Value') 
            
            case 1  % пороговая                
                
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
                
            case 2  % Оцу
                
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
                
            case {3,4,5}  % Брэдли-Рота, Ниблэка, Кристиана
                
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
                
            case 6  % Бернсена
                
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
                
            case 7  % Саувола
                
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
                
            case 8  % с адаптивным порогом
                
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
        
    case 4          % морфологическая обработка
        
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
            
            case {1,2,3,4,5,6}  % дилатация, эрозия, размыкание, ... верх шляпы
                               
                set(menu_handles.FiltParButton2,'Visible','on','String','Показать');  
                set(menu_handles.FiltParMenu3,'Value',1);
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on'); 
            
                set(menu_handles.FiltParText3,'String','Морф. структура');   
                set(menu_handles.FiltParMenu3,'String',{'Ромб',...
                                                        'Круг',...
                                                        'Линия',...
                                                        'Восьмиугольник',...
                                                        'Пара точек',...
                                                        'Прямоугольник',...
                                                        'Пользовательская'}); 
                                                    
                Max = floor(min(size(Original,1),size(Original,1))/2)-1;
                set(menu_handles.BetaSlider,'Min',1,'Max',Max,...
                    'Value',1,'SliderStep',[1/(Max-1) 10/(Max-1)]);
                set(menu_handles.BetaText,'String','R = ');
                set(menu_handles.BetaValText,'String','1');
                
                set([   menu_handles.BetaSlider;...
                        menu_handles.BetaText;...
                        menu_handles.BetaValText],...
                        'Visible','on');
                    
                            
                                                    
            case {7,8,9}   % заполнение, очитка, периметр   
                
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on');
                set(menu_handles.FiltParMenu3,'Value',1);
                set(menu_handles.FiltParText3,'String','Кол-во связей');
                set(menu_handles.FiltParMenu3,'String',{'4','8'});   
                
            case 10     % конечная эрозия
                
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on');
                set(menu_handles.FiltParMenu3,'Value',1);
                set(menu_handles.FiltParText3,'String','Параметры');
                set(menu_handles.FiltParMenu3,'String',{'эвклидова (4-св.)',...
                                                        'эвклидова (8-св.)',...
                                                        'городской квартал (4-св.)',...
                                                        'городской квартал (8-св.)',...
                                                        'шахматная доска (4-св.)',...
                                                        'шахматная доска (8-св.)',...
                                                        'квази-эвклидова (4-св.)',...
                                                        'квази-эвклидова (8-св.)'});
            
            
                
            case 11     % успех/неудача
                
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','off');
                set(menu_handles.FiltParButton2,'Visible','on','String','Задать');                              
                
                set(menu_handles.BetaSlider,'Min',-1,'Max',1,...
                    'Value',0,'SliderStep',[1/2 1/2]);
                set(menu_handles.BetaText,'String','Значение:');
                set(menu_handles.BetaValText,'String','0');  
                
                set(menu_handles.GammaSlider,'Min',1,'Max',4,...
                    'Value',1,'SliderStep',[1/3 1/3]);
                set(menu_handles.GammaText,'String','Размер матрицы:');
                set(menu_handles.GammaValText,'String','3х3');               
                
                set(menu_handles.EpsilonSlider,'Min',1,'Max',3,...
                    'Value',1,'SliderStep',[1/2 1/2]);
                set(menu_handles.EpsilonText,'String','Строка:');
                set(menu_handles.EpsilonValText,'String','1');                 
                
                set(menu_handles.ZetaSlider,'Min',1,'Max',3,...
                    'Value',1,'SliderStep',[1/2 1/2]);
                set(menu_handles.ZetaText,'String','Столбец:');
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
        
    case 5          % полутоновая морфология
        
        % все спрятали, нужное откроется в кейсах
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
            
        % выставим свойства меню по умолчанию, в case 10 оно меняется    
        set(menu_handles.FiltParText3,'String','Кол-во связей');
        switch size(Original,3)
            case 1
                conn = {'4','8'};
            case 3
                conn = {'6','18','26'};
            otherwise
                conn = {'минимальное','максимальное'};
        end

        set(menu_handles.FiltParMenu3,'String',conn);
            
        
        switch get(menu_handles.FiltParMenu2,'Value')
            case {1,2,3,4,5,6}  % дилатация...верх шляпы                   
                
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
                    
                set(menu_handles.FiltParButton1,'Visible','on','String','Задать');   
                
            case 7    % заполнение отверстий                
                
            case {8,9,15,16}    % очистка границ, выделение периметра лок. минимум, лок макс.
                
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on');  
                
            case 10             % конечная эрозия
                
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on');
                
                switch size(Original,3)
                    case 1
                        conn = {'эвклидова (4-св.)',...
                                'эвклидова (8-св.)',...
                                'городской квартал (4-св.)',...
                                'городской квартал (8-св.)',...
                                'шахматная доска (4-св.)',...
                                'шахматная доска (8-св.)',...
                                'квази-эвклидова (4-св.)',...
                                'квази-эвклидова (8-св.)'};
                    case 3
                        conn = {'эвклидова (6-св.)',...
                                'эвклидова (18-св.)',...
                                'эвклидова (26-св.)',...                                
                                'городской квартал (6-св.)',...
                                'городской квартал (18-св.)',...
                                'городской квартал (26-св.)',...                                
                                'шахматная доска (6-св.)',...
                                'шахматная доска (18-св.)',...
                                'шахматная доска (26-св.)',...                                
                                'квази-эвклидова (6-св.)',...
                                'квази-эвклидова (18-св.)',...
                                'квази-эвклидова (26-св.)'};
                    otherwise
                        conn = {'эвклидова (мин-св.)',...
                                'эвклидова (макс-св.)',...
                                'городской квартал (мин-св.)',...
                                'городской квартал (макс-св.)',...
                                'шахматная доска (мин-св.)',...
                                'шахматная доска (макс-св.)',...
                                'квази-эвклидова (мин-св.)',...
                                'квази-эвклидова (макс-св.)'};
                end

                set(menu_handles.FiltParMenu3,'String',conn);
                
            case {11,12,13,14}  % расш. мин/макс, H-мин/макс
                
                set([menu_handles.FiltParText3 menu_handles.FiltParMenu3],'Visible','on');                
                
                set([   menu_handles.AlphaSlider;...
                        menu_handles.AlphaText;...
                        menu_handles.AlphaValText],...
                        'Visible','on');
        end
        
        
    case 6          % билатеральный фильтр
        
        if get(menu_handles.FiltParMenu2,'Value') == 6
            set([menu_handles.FiltParMenu3 menu_handles.FiltParText3],'Visible','on');
        else
            set([menu_handles.FiltParMenu3 menu_handles.FiltParText3],'Visible','off');
        end
        
    case 9          % преобразование Хафа
        
        % с изменение пределов Тета нужно поменять размеры маски подавления
        A = get(menu_handles.AlphaSlider,'Value');          % верхний предел по тета
        B = get(menu_handles.BetaSlider,'Value');           % верхний предел по тета
        RhoStep = get(menu_handles.GammaSlider,'Value');    % шаг по Ро
        STR = get(menu_handles.FiltParMenu2,'String');      % считваем шаг по Тета
        num = get(menu_handles.FiltParMenu2,'Value');
        ThetaStep = str2double(STR(num));
        BW = Original(:,:,1);                               % 2D изображение
        [MinMask,MaxMask] = SuppressMaskRecount(BW,A,B,ThetaStep,RhoStep);
        
        set(menu_handles.DeltaSlider,'Min',MinMask(1),'Max',MaxMask(1),'Value',MinMask(1),...
                                    'SliderStep',[2/(MaxMask(1)-MinMask(1)) 10/(MaxMask(1)-MinMask(1))]);
        set(menu_handles.DeltaValText,'String',[num2str(MinMask(1)) 'x' num2str(MinMask(2))]);
        
        set(menu_handles.EtaSlider,'Min',MinMask(2),'Max',MaxMask(2),'Value',MinMask(2),...
                                    'SliderStep',[2/(MaxMask(2)-MinMask(2)) 10/(MaxMask(2)-MinMask(2))]);
        
    case 10         % декорреляционное растяжение
        
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
        
    case 14         % усредняющие фильтры
        
        switch get(menu_handles.FiltParMenu2,'Value')
            
            case 4      % контргармоническое среднее
                set(menu_handles.AlphaSlider,'Min',-5,'Max',5,'Value',1.5,...
                                'Visible','on','SliderStep',[0.01/10 0.1/10]);
                set(menu_handles.AlphaText,'String','Порядок: ','Visible','on');
                set(menu_handles.AlphaValText,'String','1.5','Visible','on');
                
            case 8      % среднее усеченное
                
                MaskSize = 2*get(menu_handles.FiltParMenu1,'Value')+1;
                
                set(menu_handles.AlphaSlider,'Min',2,'Max',MaskSize^2-3,'Value',2,...
                    'Visible','on','SliderStep',[2/(MaskSize^2-5) 10/(MaskSize^2-5)]);
                
                set(menu_handles.AlphaText,'String','Порог: ','Visible','on');
                set(menu_handles.AlphaValText,'String','2','Visible','on');
                
            otherwise
                
                set([menu_handles.AlphaSlider;...
                    menu_handles.AlphaText;...
                    menu_handles.AlphaValText],...
                    'Visible','off');                
        end
        
    case 25     % фильтры Ли
        
        switch get(menu_handles.FiltParMenu2,'Value')
            
            case 1      % оригинальный
                
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
                
            case 2      % улучшенный
                
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
        
    case 26     % фильтр Фроста
        
        switch get(menu_handles.FiltParMenu2,'Value')
            
            case 1      % оригинальный
                
                set([  ...
                    menu_handles.BetaSlider;...
                    menu_handles.BetaText;...
                    menu_handles.BetaValText;...
                    ],'Visible','off');
                
            case 2      % улучшенный
                
                set([  ...
                    menu_handles.BetaSlider;...
                    menu_handles.BetaText;...
                    menu_handles.BetaValText;...
                    ],'Visible','on');
        end        
        
    case 30        % градиент
        
        switch get(menu_handles.FiltParMenu2,'Value')
            case {1,2}
                set(menu_handles.FiltParMenu3,'String',{'Собеля','Превитта',...
                    'Центральной разности','Средней разности','Робертса'});
                
            case {3,4}
                set(menu_handles.FiltParMenu3,'String',{'Собеля','Превитта',...
                    'Центральной разности','Средней разности'});
        end
        
    case 34     % детектор окружностей
        
        switch get(menu_handles.FiltParMenu2,'Value')
            case 1      % алгоритм хафа
                
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
        
    case 35     % детектор ключевых точек
        
        s = size(Original);
        maxH = min(s(1),s(2));
        maxMEV = max(s(1),s(2));
                
        % прячем все, потом будем открывать попунктно
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


% ТРЕТИЙ СПИСОК
function FiltParMenu3_Callback(~,~,menu_handles)

global Original;

switch get(menu_handles.FilterType,'Value')     % тип обработки
        
    case 4                  % морфологическая обработка
        
        if get(menu_handles.FiltParMenu2,'Value') < 7
            Max = floor(min(size(Original,1),size(Original,1))/2)-1;            
            set(menu_handles.FiltParButton2,'Visible','on');
                
            switch get(menu_handles.FiltParMenu3,'Value')
                
                case 1      % ромб
                    
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
                    
                case 2      % круг
                    
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
                    
                case 3      % линия
                    
                    set(menu_handles.BetaSlider,'Min',3,'Max',Max,...
                        'Value',3,'SliderStep',[1/(Max-3) 10/(Max-3)]);
                    set(menu_handles.BetaText,'String','Длина:');
                    set(menu_handles.BetaValText,'String','3');
                    
                    set(menu_handles.GammaSlider,'Min',0,'Max',360,...
                        'Value',0,'SliderStep',[1/360 10/360]);
                    set(menu_handles.GammaText,'String','Угол, гр.:');
                    set(menu_handles.GammaValText,'String','0');
                    
                    set([   menu_handles.GammaSlider;...
                        menu_handles.GammaText;...
                        menu_handles.GammaValText],...
                        'Visible','on');
                    
                    set([   menu_handles.MaskTable;...
                        menu_handles.MaskText],...
                        'Visible','off');
                    
                case 4      % 8-угольник
                    
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
                    
                case 5      % пара точек
                    
                    set(menu_handles.BetaSlider,'Min',1,'Max',floor(size(Original,1)/2),...
                        'Value',1,'SliderStep',[1/(floor(size(Original,1)/2)-1) 10/(floor(size(Original,1)/2)-1)]);
                    set(menu_handles.BetaText,'String','Стр. сдвиг:');
                    set(menu_handles.BetaValText,'String','1');
                    
                    set(menu_handles.GammaSlider,'Min',1,'Max',floor(size(Original,2)/2),...
                        'Value',1,'SliderStep',[1/(floor(size(Original,2)/2)-1) 10/(floor(size(Original,2)/2)-1)]);
                    set(menu_handles.GammaText,'String','Столб. сдвиг:');
                    set(menu_handles.GammaValText,'String','1');
                    
                    set([   menu_handles.GammaSlider;...
                        menu_handles.GammaText;...
                        menu_handles.GammaValText],...
                        'Visible','on');
                    
                    set([   menu_handles.MaskTable;...
                        menu_handles.MaskText],...
                        'Visible','off');
                    
                case 6      % прямоугольник
                    
                    set(menu_handles.BetaSlider,'Min',1,'Max',floor(size(Original,1)/2),...
                        'Value',1,'SliderStep',[1/(floor(size(Original,1)/2)-1) 10/(floor(size(Original,1)/2)-1)]);
                    set(menu_handles.BetaText,'String','Кол-во строк:');
                    set(menu_handles.BetaValText,'String','1');
                    
                    set(menu_handles.GammaSlider,'Min',1,'Max',floor(size(Original,2)/2),...
                        'Value',1,'SliderStep',[1/(floor(size(Original,2)/2)-1) 10/(floor(size(Original,2)/2)-1)]);
                    set(menu_handles.GammaText,'String','Кол-во столбцов:');
                    set(menu_handles.GammaValText,'String','1');
                    
                    set([   menu_handles.GammaSlider;...
                        menu_handles.GammaText;...
                        menu_handles.GammaValText],...
                        'Visible','on');
                    
                    set([   menu_handles.MaskTable;...
                        menu_handles.MaskText],...
                        'Visible','off');
                    
                    
                    
                case 7      % пользовательская
                             
                    set(menu_handles.FiltParButton2,'Visible','off');
                
                    set(menu_handles.BetaSlider,'Min',1,'Max',4,...
                        'Value',1,'SliderStep',[1/3 1/3]);
                    set(menu_handles.BetaText,'String','Размер матрицы:');
                    set(menu_handles.BetaValText,'String','3х3');
                    
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
        
    case 25         % фильтры Ли
        
        switch get(menu_handles.FiltParMenu3,'Value')
            
            case 1      % аддитивная модель
                
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
                
            case 2      % мультипликативная модель
                
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
                    
            case 3      % аддитивная + мультипликативная модель
                
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% СЛАЙДЕРЫ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% СЛАЙДЕР "А" ПАРАМЕТРОВ ШУМА
function Aslider_Callback(~, ~, menu_handles)

A = get(menu_handles.Aslider,'Value');          % ПОЛУЧИЛИ ЗНАЧЕНИЕ СЛАЙДЕРА
        
switch get(menu_handles.NoiseType,'Value');     % считываем номер выбранного шума  
    
    case {2,4,6,7,8,9,10,12}          % НОРМАЛЬНЫЙ,ЭКСПОНЕНЦИАЛЬНЫЙ,ЛАПЛАСА,СПЕКЛ,РАЗМЫТИЕ ШУМ
        A = round(A);
        
    case 11                      % РЭЛЕЯ ШУМ
        A = round(A*100)/100;
        
    case 5         % РАВНОМЕРНЫЙ ШУМ
        
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


% СЛАЙДЕР "Б" ПАРАМЕТРОВ ШУМА
function Bslider_Callback(~, ~, menu_handles)

B = get(menu_handles.Bslider,'Value');          % считываем значение слайдера

switch get(menu_handles.NoiseType,'Value');     % считываем номер выбранного шума  
    
    case {2,4,10}           % НОРМАЛЬНЫЙ,ЛАПЛАСА,РАЗМЫТИЕ ШУМ  
        B = round(B);
        
    case 5                 % РАВНОМЕРНЫЙ ШУМ
        
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


% СЛАЙДЕР ВЫБОРА УДАЛЕНИЯ ПОЗИЦИИ
function DeleteSlider_Callback(~, ~, menu_handles)

D = get(menu_handles.DeleteSlider,'Value');  % считываем значение слайдера

set(menu_handles.NoiseFilterString,'Value',D);           
set(menu_handles.DeleteSlider,'Value',D);                % меняем значение слайдера
set(menu_handles.DeleteNumber,'String',num2str(D));      % меняем номер позиции


% СЛАЙДЕР ПАРАМЕТРА "АЛЬФА"
function AlphaSlider_Callback(~, ~, menu_handles)

global Original;

A = get(menu_handles.AlphaSlider,'Value');
RewriteTextString = 0;                  % не надо переписывать текстовую строку

switch get(menu_handles.FilterType,'Value')
             
    case {3,4,5,7,12,24,27,29,31,32}         % ПОРОГОВЫЙ
        A = round(A);
        
    case {6,8,13,20,21,22,33,35}    % БИЛАТЕРАЛЬНЫЙ, ГАБОРА, НИЗКИХ ЧАСТОТ ГАУССА, ГАУССА+ЛАПЛАСА, 
               
        A = round(A*100)/100;
        
    case 9      % ПРЕОБРАЗОВАНИЕ ХАФА        

        A = round(A);
        if A == 88
            set(menu_handles.BetaSlider,'Enable','off');     % блокируем слайдер
        else
            set(menu_handles.BetaSlider,'Enable','on');      % иначе меняем пределы второго слайдера
            set(menu_handles.BetaSlider,'Min',A+1,...
                'SliderStep',[1/(89-1-A) 10/(89-1-A)]);
        end
        
        % с изменение пределов Тета нужно поменять размеры маски подавления
        B = get(menu_handles.BetaSlider,'Value');           % верхний предел по тета
        RhoStep = get(menu_handles.GammaSlider,'Value');    % шаг по Ро
        STR = get(menu_handles.FiltParMenu2,'String');      % считваем шаг по Тета
        num = get(menu_handles.FiltParMenu2,'Value');
        ThetaStep = str2double(STR(num));
        BW = Original(:,:,1);                               % 2D изображение
        [MinMask,MaxMask] = SuppressMaskRecount(BW,A,B,ThetaStep,RhoStep);
        
        set(menu_handles.DeltaSlider,'Min',MinMask(1),'Max',MaxMask(1),'Value',MinMask(1),...
                                    'SliderStep',[2/(MaxMask(1)-MinMask(1)) 10/(MaxMask(1)-MinMask(1))]);
        set(menu_handles.DeltaValText,'String',[num2str(MinMask(1)) 'x' num2str(MinMask(2))]);
        
        set(menu_handles.EtaSlider,'Min',MinMask(2),'Max',MaxMask(2),'Value',MinMask(2),...
                                    'SliderStep',[2/(MaxMask(2)-MinMask(2)) 10/(MaxMask(2)-MinMask(2))]);

    
    case 10     % ДЕКОРРЕЛЯЦИОННОЕ РАСТЯЖЕНИЕ
        
        A = round(A);
        
        if A == size(Original,2)-1
            set(menu_handles.BetaSlider,'Enable','off');     % блокируем слайдер
        else
            set(menu_handles.BetaSlider,'Enable','on');      % иначе меняем пределы второго слайдера
            set(menu_handles.BetaSlider,'Min',A+1,...
                'SliderStep',[1/(size(Original,2)-1-A) 10/(size(Original,2)-1-A)]);
        end
        
    case {11,25}
        A = round(A);
                        
    case 14                 % усредняющий фильтр
        
        if get(menu_handles.FiltParMenu2,'Value') == 4            
            A = round(A*100)/100;       % округлили до целого   
            
        elseif get(menu_handles.FiltParMenu2,'Value') == 8  % если фильтр усеченное 
            
            A = round(A);       % округлили до целого
            A = A - mod(A,2);                           % сделали четным
        end
                
    case {15,17,18}
        
        A = round(A);
        
        if A == 0
           A = 'авто';
        end        
        
    case 16         %      
        A = round(A);
        
        if  A == 254
            set(menu_handles.BetaSlider,'Enable','off');
        else
            set(menu_handles.BetaSlider,'Enable','on');
            set(menu_handles.BetaSlider,'Min',A+1,'SliderStep',[1/(256-A-1) 10/(256-A-1)]);
        end
        
        if A == -1              % в случае фильтра кенни может быть выставлено автом.определение порога
            set(menu_handles.AlphaValText,'String','авто');
            set(menu_handles.BetaValText,'String','авто');
            set(menu_handles.BetaSlider,'Enable','off');
            RewriteTextString = 1;   % в этом случае не переписываем строку
        else            
            set(menu_handles.BetaValText,'String',num2str(get(menu_handles.BetaSlider,'Value')));
            RewriteTextString = 0;
        end 
        
    case 23  %  АДАПТИВНЫЙ МЕДИАННЫЙ
        
        A = round(A);        
        A = A - 1 + mod(A,2);             % делаем нечетным 
        
    case 26    % ФРОСТА
        A = round(A*100)/100;     
        
        
    case 30         % ПОРОГОВЫЙ ПОЛОСОВОЙ 
        
        A = round(A);
        
        if  A == 254
            set(menu_handles.BetaSlider,'Enable','off');
        else
            set(menu_handles.BetaSlider,'Enable','on');
            set(menu_handles.BetaSlider,'Min',A+1,'SliderStep',[1/(255-A-1) 10/(255-A-1)]);
        end
end

if RewriteTextString == 0            % если ее нужно переписывать
    if isnumeric(A) == 1            
        set(menu_handles.AlphaSlider,'Value',A);
        set(menu_handles.AlphaValText,'String',num2str(A));
    else
        set(menu_handles.AlphaValText,'String',A);
    end
end


% СЛАЙДЕР ПАРАМЕТРА "БЕТА"
function BetaSlider_Callback(~, ~, menu_handles)

global Original;

B = get(menu_handles.BetaSlider,'Value');
RewriteTextString = 0;                  % не надо переписывать текстовую строку

switch get(menu_handles.FilterType,'Value')
    
    case {3,6,8,32,34,35}       % бинаризация, билатеральный
        
        B = round(B*100)/100;           % округляем
    
    case 4      % морфологическая обработка (ч/б)
        
        switch get(menu_handles.FiltParMenu2,'Value')       % тип обработки
            
            case {1,2,3,4,5,6}
                B = round(B);
                    
                if get(menu_handles.FiltParMenu3,'Value') == 4   % восьмиугольник
                    
                    B = B - mod(B,3);
                
                elseif get(menu_handles.FiltParMenu3,'Value') == 7
                    
                    set(menu_handles.BetaSlider,'Value',B);
                    
                    switch B       % считываем значение маски
                        
                        case 1          % маска 3х3
                            
                            set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',34,...
                                'Position',[400 5 182 182],...
                                'ColumnWidth',{60 60 60});
                            
                        case 2          % маска 5х5
                            set(menu_handles.MaskTable,'Data',ones(5),'FontSize',19,...
                                'Position',[405 5 177 177],...
                                'ColumnWidth',{35 35 35 35 35});
                        case 3          % маска 7х7
                            
                            set(menu_handles.MaskTable, 'Data',ones(7),'FontSize',12,...
                                'Position',[405 5 177 163],...
                                'ColumnWidth',{25 25 25 25 25 25 25});
                        case 4          % маска 9х9
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
                
    case 9      % ПРЕОБРАЗОВАНИЕ ХАФА
        
        B = round(B);
        if B == -89
            set(menu_handles.AlphaSlider,'Enable','off');
        else
            set(menu_handles.AlphaSlider,'Enable','on');
            set(menu_handles.AlphaSlider,'Max',B-1,'SliderStep',[1/(B-1+90) 10/(B-1+90)]);
        end
        
        
        % с изменение пределов Тета нужно поменять размеры маски подавления
        A = get(menu_handles.AlphaSlider,'Value');          % верхний предел по тета
        RhoStep = get(menu_handles.GammaSlider,'Value');    % шаг по Ро
        STR = get(menu_handles.FiltParMenu2,'String');      % считваем шаг по Тета
        num = get(menu_handles.FiltParMenu2,'Value');
        ThetaStep = str2double(STR(num));
        BW = Original(:,:,1);                               % 2D изображение
        [MinMask,MaxMask] = SuppressMaskRecount(BW,A,B,ThetaStep,RhoStep);
        
        set(menu_handles.DeltaSlider,'Min',MinMask(1),'Max',MaxMask(1),'Value',MinMask(1),...
                                    'SliderStep',[2/(MaxMask(1)-MinMask(1)) 10/(MaxMask(1)-MinMask(1))]);
        set(menu_handles.DeltaValText,'String',[num2str(MinMask(1)) 'x' num2str(MinMask(2))]);
        
        set(menu_handles.EtaSlider,'Min',MinMask(2),'Max',MaxMask(2),'Value',MinMask(2),...
                                    'SliderStep',[2/(MaxMask(2)-MinMask(2)) 10/(MaxMask(2)-MinMask(2))]);
        
    case 10        % ДЕКОРРЕЛЯЦИОННОЕ РАСТЯЖЕНИЕ
        
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
        
        if B == 256              % в случае фильтра кенни может быть выставлено автом.определение порога
            set(menu_handles.AlphaValText,'String','авто');
            set(menu_handles.BetaValText,'String','авто');
            set(menu_handles.AlphaSlider,'Enable','off');
            RewriteTextString = 1;   % в этом случае не переписываем строку
        else            
            set(menu_handles.AlphaValText,'String',num2str(get(menu_handles.AlphaSlider,'Value')));
            RewriteTextString = 0;
        end
        
   case 30            % ПОРОГОВЫЙ ПОЛОСОВОЙ   
        B = round(B);  
        
        if B == 1
            set(menu_handles.AlphaSlider,'Enable','off');
        else
            set(menu_handles.AlphaSlider,'Enable','on');
            set(menu_handles.AlphaSlider,'Max',B-1,'SliderStep',[1/(B-1) 10/(B-1)]);
        end          
        
    case 33
        
        B = round(B);           % округляем
        
        if B == 254                                     % если пришли к пределу 
            set(menu_handles.GammaSlider,'Enable','off');     % блокируем слайдер
        else
            set(menu_handles.GammaSlider,'Enable','on');      % иначе меняем пределы второго слайдера
            set(menu_handles.GammaSlider,'Min',B+1,'SliderStep',[1/(255-B-1) 10/(255-B-1)]);
        end        
        
end

if RewriteTextString == 0            % если ее нужно переписывать
    if isnumeric(B) == 1  
        set(menu_handles.BetaSlider,'Value',B);
        set(menu_handles.BetaValText,'String',num2str(B));
    else
        set(menu_handles.BetaValText,'String',B);
    end
end


% СЛАЙДЕР ПАРАМЕТРА "ГАММА"
function GammaSlider_Callback(~, ~, menu_handles)

global Original;

G = get(menu_handles.GammaSlider,'Value');

switch get(menu_handles.FilterType,'Value')         
        
    case {3,5,7,8,11,25,34}      % СЛЕПАЯ ОБРАТНАЯ СВЕРТКА    
         G = round(G);
         
    case 4
        G = round(G);
        set(menu_handles.GammaSlider,'Value',G);
        
        if get(menu_handles.FiltParMenu2,'Value') == 11     % успех/неудача
            
            
            switch G       % считываем значение маски
                
                case 1          % маска 3х3
                    
                    set(menu_handles.MaskTable, 'Data',ones(3),'FontSize',34,...
                        'Position',[400 5 182 182],...
                        'ColumnWidth',{60 60 60});
                    
                case 2          % маска 5х5
                    set(menu_handles.MaskTable,'Data',ones(5),'FontSize',19,...
                        'Position',[405 5 177 177],...
                        'ColumnWidth',{35 35 35 35 35});
                case 3          % маска 7х7
                    
                    set(menu_handles.MaskTable, 'Data',ones(7),'FontSize',12,...
                        'Position',[405 5 177 163],...
                        'ColumnWidth',{25 25 25 25 25 25 25});
                case 4          % маска 9х9
                    set(menu_handles.MaskTable, 'Data',ones(9),'FontSize',10,...
                        'Position',[400 5 182 182],...
                        'ColumnWidth',{20 20 20 20 20 20 20 20 20});
            end           
                        
            set(menu_handles.EpsilonSlider,'Min',1,'Max',2*G+1,...
                'Value',1,'SliderStep',[1/(2*G) 1/(2*G)]);
            set(menu_handles.EpsilonText,'String','Строка:');
            set(menu_handles.EpsilonValText,'String','1');
            
            set(menu_handles.ZetaSlider,'Min',1,'Max',2*G+1,...
                'Value',1,'SliderStep',[1/(2*G) 1/(2*G)]);
            set(menu_handles.ZetaText,'String','Столбец:');
            set(menu_handles.ZetaValText,'String','1');
            
            G = [num2str(2*G+1) 'x' num2str(2*G+1)];
        end
                 
    case 9      % ПРЕОБРАЗОВАНИЕ ХАФА
        
        G = round(G*10)/10;
        
        % с изменение пределов Тета нужно поменять размеры маски подавления
        A = get(menu_handles.AlphaSlider,'Value');          % верхний предел по тета
        B = get(menu_handles.BetaSlider,'Value');           % верхний предел по тета
        STR = get(menu_handles.FiltParMenu2,'String');      % считваем шаг по Тета
        num = get(menu_handles.FiltParMenu2,'Value');
        ThetaStep = str2double(STR(num));
        BW = Original(:,:,1);                               % 2D изображение
        [MinMask,MaxMask] = SuppressMaskRecount(BW,A,B,ThetaStep,G);
        
        set(menu_handles.DeltaSlider,'Min',MinMask(1),'Max',MaxMask(1),'Value',MinMask(1),...
                                    'SliderStep',[2/(MaxMask(1)-MinMask(1)) 10/(MaxMask(1)-MinMask(1))]);
        set(menu_handles.DeltaValText,'String',[num2str(MinMask(1)) 'x' num2str(MinMask(2))]);
        
        set(menu_handles.EtaSlider,'Min',MinMask(2),'Max',MaxMask(2),'Value',MinMask(2),...
                                    'SliderStep',[2/(MaxMask(2)-MinMask(2)) 10/(MaxMask(2)-MinMask(2))]);
        
        
        
    case 10     % ДЕКОРРЕЛЯЦИОННОЕ РАСТЯЖЕНИЕ
        
         G = round(G);
         
         if G == size(Original,1)-1
             set(menu_handles.DeltaSlider,'Enable','off');     % блокируем слайдер
         else
             set(menu_handles.DeltaSlider,'Enable','on');      % иначе меняем пределы второго слайдера
             set(menu_handles.DeltaSlider,'Min',G+1,...
             'SliderStep',[1/(size(Original,1)-1-G) 10/(size(Original,1)-1-G)]);
         end  
         
         
    case 16
        G = round(G*100)/100;               % ФИЛЬТР КЕННИ
        
    case 33
        
        G = round(G);
        
        if G == 1
            set(menu_handles.BetaSlider,'Enable','off');
        else
            set(menu_handles.BetaSlider,'Enable','on');
            set(menu_handles.BetaSlider,'Max',G-1,'SliderStep',[1/(G-1) 10/(G-1)]);
        end
        
    case 35         % ключточки
        
        G = round(G);
        G = G - 1 + mod(G,2);    % округлили и сделали нечетным        
        
end

if isnumeric(G) == 1
    set(menu_handles.GammaSlider,'Value',G);
    set(menu_handles.GammaValText,'String',num2str(G));
else
    set(menu_handles.GammaValText,'String',G);
end
    

% СЛАЙДЕР ПАРАМЕТРА "ДЕЛЬТА"
function DeltaSlider_Callback(~, ~, menu_handles)

D = get(menu_handles.DeltaSlider,'Value');

switch get(menu_handles.FilterType,'Value') 
    
    case 3      % бинаризация
            
         D = round(D);
         Et = get(menu_handles.EtaSlider,'Value');
         Et = round(Et);
        
         set(menu_handles.DeltaSlider,'Value',D);
         set(menu_handles.DeltaValText,'String',[num2str(D) 'x' num2str(Et)]);
         
         return;
       
    case {4,5}      % морфологическая обработка        
          
         D = round(D);
         if D == 0
             D = char(8734);
         end
        
    case {7,8,25,35}      % СЛЕПАЯ ОБРАТНАЯ СВЕРТКА    
         D = round(D);                 
        
    case 9          % ПРЕОБРАЗОВАНИЕ ХАФА   
         D = round(D);
         D = D + mod(D,2) - 1;          
         
         Et = get(menu_handles.EtaSlider,'Value');
         Et = round(Et);
         Et = Et + mod(Et,2) - 1;
         
         set(menu_handles.DeltaSlider,'Value',D);
         set(menu_handles.DeltaValText,'String',[num2str(D) 'x' num2str(Et)]);
         
         return;         
         
    case 10        % ДЕКОРРЕЛЯЦИОННОЕ РАСТЯЖЕНИЕ
        
        D = round(D);
        if D == 2
            set(menu_handles.GammaSlider,'Enable','off');
        else
            set(menu_handles.GammaSlider,'Enable','on');
            set(menu_handles.GammaSlider,'Max',D-1,'SliderStep',[1/(D-2) 10/(D-2)]);
        end
        
        
    case 33
        D = round(D);           % округляем
        
        if D == 254                                     % если пришли к пределу 
            set(menu_handles.EpsilonSlider,'Enable','off');     % блокируем слайдер
        else
            set(menu_handles.EpsilonSlider,'Enable','on');      % иначе меняем пределы второго слайдера
            set(menu_handles.EpsilonSlider,'Min',D+1,'SliderStep',[1/(255-D-1) 10/(255-D-1)]);
        end
        
    case 29
        D = round(D);           % округляем 
        Et = get(menu_handles.EtaSlider,'Value');
        if D >= Et
            D = Et;
        end
        
        set(menu_handles.DeltaSlider,'Value',D);
        set(menu_handles.DeltaValText,'String',[num2str(D) ' ' char(8804) ' I ' char(8804) ' ' num2str(Et)]);
        return;
        
    case 34
        D = round(D);           % округляем 
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


% СЛАЙДЕР ПАРАМЕТРА "ЭПСИЛОН"
function EpsilonSlider_Callback(~, ~, menu_handles)

E = get(menu_handles.EpsilonSlider,'Value');

switch get(menu_handles.FilterType,'Value')
    
    case {4,8,9,25,35}                  % морфо обра-ка (ч/б) 
        E = round(E);        
     
    case 10                 % ДЕКОРРЕЛЯЦИОННОЕ РАСТЯЖЕНИЕ
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


% СЛАЙДЕР ПАРАМЕТРА "ДЗЕТА"
function ZetaSlider_Callback(~,~,menu_handles)

Z = get(menu_handles.ZetaSlider,'Value');

switch get(menu_handles.FilterType,'Value')
    
    case {4,9,35}                  % морфо обра-ка (ч/б) 
        Z = round(Z);
        
    case 10        % ДЕКОРРЕЛЯЦИОННОЕ РАСТЯЖЕНИЕ
        Z = round(Z);
        
        if Z == 1
            set(menu_handles.EpsilonSlider,'Enable','off');
        else
            set(menu_handles.EpsilonSlider,'Enable','on');
            set(menu_handles.EpsilonSlider,'Max',Z-1,'SliderStep',[1/(Z-1) 10/(Z-1)]);
        end
        
    case 25     % фильтры Ли
        
        Z = round(Z*100)/100;
        
end

set(menu_handles.ZetaSlider,'Value',Z);
set(menu_handles.ZetaValText,'String',num2str(Z));


% СЛАЙДЕР ПАРАМЕТРА "ИТА"
function EtaSlider_Callback(~,~,menu_handles)

Et = get(menu_handles.EtaSlider,'Value');

switch get(menu_handles.FilterType,'Value')
    
    case 3          % бинаризация
        
         Et = round(Et);
         D = get(menu_handles.DeltaSlider,'Value');
         D = round(D);
         
         set(menu_handles.EtaSlider,'Value',Et);
         set(menu_handles.DeltaValText,'String',[num2str(D) 'x' num2str(Et)]);
         
         return;
    
    case 9          % преобразование Хафа        
        
         Et = round(Et);
         Et = Et + mod(Et,2) - 1;
        
         D = get(menu_handles.DeltaSlider,'Value');
         D = round(D);
         D = D + mod(D,2) - 1;    
         
         set(menu_handles.EtaSlider,'Value',Et);
         set(menu_handles.DeltaValText,'String',[num2str(D) 'x' num2str(Et)]);
         return;
         
    case 29         % детектор окружностей
        
         Et = round(Et);   
         D = get(menu_handles.DeltaSlider,'Value'); 
         
         if Et <= D
             Et = D;
         end
         
         set(menu_handles.EtaSlider,'Value',Et);
         set(menu_handles.DeltaValText,'String',[num2str(D) ' ' char(8804) ' I ' char(8804) ' ' num2str(Et)]);
         return;
         
    case 34         % детектор окружностей
        
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


% СЛАЙДЕР ПАРАМЕТРА "ТЕТА"
function TetaSlider_Callback(~,~,menu_handles)

Teta = get(menu_handles.TetaSlider,'Value');

switch get(menu_handles.FilterType,'Value')
    
    case 9          % преобразование Хафа        
        
         Teta = round(Teta);   
end

set(menu_handles.TetaSlider,'Value',Teta);
set(menu_handles.TetaValText,'String',num2str(Teta));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% КНОПКИ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% КНОПКА "ПРЕДВАРИТЕЛЬНЫЙ ПРОСМОТР"
function PreviewButton_Callback(~, ~, menu_handles)

global Original;
global FilteredAsOriginal;

% если обработке подлежит не исходное изображение
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


% КНОПКА "ГИСТОГРАММА ИЗОБРАЖЕНИЯ"
function ImageHistButton_Callback(~, ~, ~)

global Original;
global FilteredAsOriginal;      % ранее обработанное изображение

if isempty(FilteredAsOriginal)  % узнаем, какое изображение выбрал пользователь
    Image = Original;
else
    Image = FilteredAsOriginal;
end

BuildHist(NewFigureWihAxes(),Image,'Гистограмма выбранного изображения');


% КНОПКА "ГИСТОГРАММА ШУМА"
function HistButton_Callback(~, ~, menu_handles)

global Original;

Image = Noising(zeros(size(Original)),...
                get(menu_handles.NoiseType,'Value'),...
                get(menu_handles.Aslider,'Value'),....
                get(menu_handles.Bslider,'Value'));
    
BuildHist(NewFigureWihAxes(),Image(:,:,1),'Гистограмма шума');
    

% КНОПКА "ГИСТОГРАММА С ШУМОМ"
function NoisedImageHistButton_Callback(~, ~, menu_handles)

global Original;
global FilteredAsOriginal;      % ранее обработанное изображение

if isempty(FilteredAsOriginal)  % узнаем, какое изображение выбрал пользователь
    Image = Original;
else
    Image = FilteredAsOriginal;
end

Image = Noising(Image,get(menu_handles.NoiseType,'Value'),...
        get(menu_handles.Aslider,'Value'),get(menu_handles.Bslider,'Value'));    

BuildHist(NewFigureWihAxes(),Image,'Гистограмма искаженного выбранного изображения');
    

% КНОПКА "ДОБАВИТЬ"
function AddButton_Callback(~, ~, menu_handles)

global Original;
global Noises;              % список параметров зашумления
global Filters;             % список параметров фильтрации
global Parametrs;           % параметры эксперимента (шумы и фильтры)


Current = size(Noises,1) + 1;        % номер строки, в которую запишем новое значение

% СЧИТЫВАЕМ ЗНАЧЕНИЯ СЛАЙДЕРОВ С ПАНЕЛЕЙ "ИСКАЖЕНИЕ" И "ОБРАБОТКА"

set([   menu_handles.DeleteNumber;...
        menu_handles.DeleteButton;...
        menu_handles.ApplyButton],...
        'Enable','on');

Noises(Current,1) = get(menu_handles.NoiseType,'Value');            % считываем тип шума (1 столбец)
Noises(Current,2) = get(menu_handles.Aslider,'Value');              % параметр А (2 столбец)
Noises(Current,3) = get(menu_handles.Bslider,'Value');              % считываем В параметр (3 столбец)
Noises(Current,4) = get(menu_handles.UsePreviousFiltImage,'Value'); % считываем галочки "исп. предыдущего изобр."

Filters(Current).FilterType = get(menu_handles.FilterType,'Value');           % считываем тип фильтра
Filters(Current).Indent = get(menu_handles.IndentMenu,'Value');           % считываем значение типа обработки краев
Filters(Current).FPM1 = get(menu_handles.FiltParMenu1,'Value');       % и размер маски
Filters(Current).FPM2 = get(menu_handles.FiltParMenu2,'Value');          % считываем значение второго меню
Filters(Current).FPM3 = get(menu_handles.FiltParMenu3,'Value');          % считываем порядок

Filters(Current).Alpha = get(menu_handles.AlphaSlider,'Value');          % считываем параметр альфа
Filters(Current).Beta = get(menu_handles.BetaSlider,'Value');           % считываем параметр бета
Filters(Current).Gamma = get(menu_handles.GammaSlider,'Value');          % считываем значение слайдера гамма
Filters(Current).Delta = get(menu_handles.DeltaSlider,'Value');           % считываем параметр дельта
Filters(Current).Epsilon = get(menu_handles.EpsilonSlider,'Value');          % считываем значение слайдера эпсилон
Filters(Current).Zeta = get(menu_handles.ZetaSlider,'Value');          % считываем значение слайдера дзета
Filters(Current).Eta = get(menu_handles.EtaSlider,'Value');          % считываем значение слайдера ита
Filters(Current).Theta = get(menu_handles.TetaSlider,'Value');          % считываем значение слайдера тета

Filters(Current).mask = get(menu_handles.MaskTable,'Data');            % получили маску
Filters(Current).mask1 = get(menu_handles.MaskTable1,'Data');            % получили маску1

F(Current,1) = Filters(Current).FilterType;           % считываем тип фильтра (1 столбец)
F(Current,2) = 2*Filters(Current).FPM1 + 1;       % и размер маски  (2 столбец)
F(Current,10) = Filters(Current).FPM2;          % считываем значение второго меню
F(Current,4) = Filters(Current).FPM3;          % считываем порядок (4 столбец)

F(Current,3) = Filters(Current).Alpha;          % считываем параметр альфа (3 столбец)
F(Current,5) = Filters(Current).Indent;           % считываем значение типа обработки краев
F(Current,6) = Filters(Current).Beta;           % считываем параметр бета (6 столбец)
F(Current,7) = Filters(Current).Gamma;          % считываем значение слайдера гамма
F(Current,8) = Filters(Current).Delta;           % считываем параметр дельта
F(Current,9) = Filters(Current).Epsilon;          % считываем значение слайдера эпсилон
F(Current,11) = Filters(Current).Zeta;          % считываем значение слайдера дзета
F(Current,12) = Filters(Current).Eta;          % считываем значение слайдера ита
F(Current,13) = Filters(Current).Theta;          % считываем значение слайдера тета

if size(F,1) > 1
    set(menu_handles.DeleteSlider,'Enable','on');
    set(menu_handles.DeleteSlider,  'Max',size(F,1),...
        'SliderStep',[1/(size(F,1)-1) 1/(size(F,1)-1)]);
end

% ФОРМИРУЕМ СПИСОК "ИСКАЖЕНИЕ-ОБРАБОТКА"
                            
NoiseType = get(menu_handles.NoiseType,'String');        % считываем список шумов
FilterType = get(menu_handles.FilterType,'String');      % считываем список фильтров
IndentStr = {'зеркальное','нули','круговое','копия'};    % список обработки краев изображения


% начинаем формировать и наращивать строку

Parametrs(Current) = strcat(num2str(Current),{')'});    % прописываем в начало порядковый номер

if Noises(Current,4) == 1                       % если взяли с предыдущего этапа - прописываем    
    Parametrs(Current) = strcat(Parametrs(Current),' Предыдущее обработанное изображение',[' ' char(8594)]);
end

Parametrs(Current) = strcat(Parametrs(Current),{' '},NoiseType(Noises(Current,1)));      % вписываем наращивание строки тип искажения

switch Noises(Current,1)     % если шум:
    case 1             % Без искажения - ничего не добавляем
        
    case 2              % нормальный
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' char(963) ' = ' num2str(Noises(Current,2))],[', ' char(956) ' = ' num2str(Noises(Current,3))]);
    case 3              % экспоненциальный
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' char(955) ' = ' num2str(Noises(Current,2))]);
    case 4              % Лапласа
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' char(945) ' = ' num2str(Noises(Current,2))],[', ' char(956) ' = ' num2str(Noises(Current,3))]);
    case 5              % Рэлея
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' char(963) ' = ' num2str(Noises(Current,2))]);
    case 6              % Спекл
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' char(963) char(178) ' = ' num2str(Noises(Current,2))]);
    case 7              % Соль-перец
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' num2str(Noises(Current,2)) ' %']);
    case 8              % Соль
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' num2str(Noises(Current,2)) ' %']);
    case 9              % Перец
        Parametrs(Current) = strcat(Parametrs(Current),',',[' ' num2str(Noises(Current,2)) ' %']);
    case 10             % Размытие шум
        Parametrs(Current) = strcat(Parametrs(Current),[', пикс.: ' num2str(Noises(Current,2))],...
            [', напр.: ' num2str(Noises(Current,3)) char(186) ' ']);
    case 11              % равномерный
        Parametrs(Current) = strcat(Parametrs(Current),[' A = ' num2str(Noises(Current,2))],...
            [', B = ' num2str(Noises(Current,3))]);
    case 12             % шум Пуассона - ничего не добавляем
        
end

%%%%%
% ВАЖНЫЙ СПИСОК
% фильтры, которым нужно расширение границ
IndentNeeded = [2 6 8 11 13 14 19:27];
%%%%%%%%

if any(IndentNeeded == F(Current,1))    % прописываем вариант обработки краев
    Parametrs(Current) = strcat(Parametrs(Current),[' ' char(8594) ' [' IndentStr{F(Current,5)} ']']);
end

s = char(FilterType(F(Current,1)));             % смотрим, какая строка в меню обработки выбрана

Parametrs(Current) = strcat(Parametrs(Current),[' ' char(8594)],[' ' s]);         % просто вписываем строку с обработкой

% вычисляем хеш маски
if F(Current,1) ~= 4 && F(Current,10) ~= 11     % для морф успех/неудача не считаем
    
    filtmask = get(menu_handles.MaskTable,'Data');  % считали маску
    c = zeros(1,size(filtmask,1));                      % сюда запишем 10чный код
    
    for x = 1:size(filtmask,1)          % для каждой строки
        a = num2str(filtmask(x,:));     % считываем ее
        c(x) = bin2dec(a) + 500;        % переводим в 10ку и получаем и добавляем константу
    end
    
    % строчка с хешем
    hash = [': %%' char(c) '%%'];
end

% размер маски и ее хеш
mask = [' ' num2str(F(Current,2)) 'x' num2str(F(Current,2))];                  

switch F(Current,1)     % если фильтр
    
    case 1              % без обработки
        
    case 2              % медианный
        
        switch F(Current,10)          % какой тип медианного фильтра выбран
            case 1
                type = 'классический';
                Ord = '';
            case 2
                type = 'мин. разности';
                Ord = '';
            case 3
                type = 'адаптивный';
                Ord = '';
            case 4
                type = 'N-мерный';
                if F(Current,4) == 4
                    Ord = [', порядок фильтра: ' char(8734)];
                else
                    Ord = [', порядок фильтра: ' num2str(F(Current,4))];
                end
                
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),[' (' type '),' mask hash Ord]);
        
    case 3              % бинаризация
        
        switch F(Current,10)          % какой тип выбран
            case 1
                type = [' (с глобальным порогом: ' num2str(F(Current,3)) ')'];
            case 2
                type = ' (Оцу)';
            case 3
                type = [' (Брэдли-Рота: k = ' num2str(F(Current,6)) '),' mask ', зерк.'];
            case 4
                type = [' (Ниблэка: k = ' num2str(F(Current,6)) '),' mask ', зерк.'];
            case 5
                type = [' (Кристиана: k = ' num2str(F(Current,6)) '),' mask ', зерк.'];
            case 6
                type = [' (Бернсена),' mask ', зерк.'];
            case 7
                type = [' (Саувола: k = ' num2str(F(Current,6)) ', R = ' num2str(F(Current,7)) '),' mask ', зерк.'];
            case 8
                 type = [' (с адаптивным порогом: примитив '...
                     num2str(F(Current,8)) 'x' num2str(F(Current,12)) ' с порогом ' num2str(F(Current,3)) ')'];
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type);
        
    case 4              % морфологическая обработка
        
        if F(Current,10) < 6           % для дилатации...шляп выбираем форму
            switch F(Current,4)
                case 1
                    subtype = [' ромб (R = ' num2str(F(Current,6)) '),'];
                case 2
                    subtype = [' круг (R = ' num2str(F(Current,6)) '),'];
                case 3
                    subtype = [' линия (Длина: ' num2str(F(Current,6)) ', угол. ' num2str(F(Current,7)) ' гр.),'];
                case 4
                    subtype = [' восьмиугольник (R = ' num2str(F(Current,6)) '),'];
                case 5
                    subtype = [' пара точек (стр./столб. сдвиг = ' num2str(F(Current,6)) '/' num2str(F(Current,7)) '),'];
                case 6
                    subtype = [' прямоугольник (' num2str(F(Current,6)) 'x' num2str(F(Current,7)) '),'];
                case 7
                    subtype = [' пользовательская маска,' num2str(F(Current,6)) 'x' num2str(F(Current,6)) hash];
            end
        elseif F(Current,10) > 6 && F(Current,10) < 10  % для реконструкций и т.д.
            
            if F(Current,4) == 1
                subtype = '4-связ.,';
            else
                subtype = '8-связ.,';
            end
            
        elseif F(Current,10) == 10      % конечная эрозия
            
            switch F(Current,4)
                case 1
                    subtype = ' (эвклидова (4-связная)),';
                case 2
                    subtype = ' (эвклидова (8-связная)),';
                case 3
                    subtype = ' (городской квартал (4-связная)),';
                case 4
                    subtype = ' (городской квартал (8-связная)),';
                case 5
                    subtype = ' (шахматная доска (4-связная)),';
                case 6
                    subtype = ' (шахматная доска (8-связная)),';
                case 7
                    subtype = ' (квази-эвклидова (4-связная)),';
                case 8
                    subtype = ' (квази-эвклидова (8-связная)),';
            end            
            
        elseif F(Current,10) == 11
            subtype = [' пользовательская маска, ' num2str(1+2*F(Current,7)) 'x' num2str(1+2*F(Current,7)) ','];
            
            
        else    % всем остальным не нужны доп. параметры
            subtype = '';
            
        end
        
        switch F(Current,10)
            case 1
                type = ' дилатация:';
            case 2
                type = ' эрозия:';
            case 3
                type = ' размыкание:';
            case 4
                type = ' замыкание:';
            case 5
                type = ' дно шляпы: ';
            case 6
                type = ' верх шляпы: ';
            case 7
                type = ' заполнение отверстий: ';
            case 8
                type = ' очистка границ: ';
            case 9
                type = ' выделение периметра: ';
            case 10
                type = ' реконструкцияконечная эрозия: ';
            case 11
                type = ' успех/неудача: ';
            case 12
                type = ' соединение: ';
            case 13
                type = ' очистка изолированных пикселей: ';
            case 14
                type = ' диагональное заполнение: ';
            case 15
                type = ' Н-разбиение: ';
            case 16
                type = ' из фона на передний план: ';
            case 17
                type = ' удаление внутренних пикселей: ';
            case 18
                type = ' сжатие до точки/кольца: ';
            case 19
                type = ' остов: ';
            case 20
                type = ' удаление отростков: ';
            case 21
                type = ' утолщение: ';
            case 22
                type = ' утончение: ';
        end
        
        if F(Current,8) == 0
            it_num = ' до стабилизации';
        else
            it_num = num2str(F(Current,8));
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),':',type,subtype,' кол-во итераций:',it_num);
        
    case 5              % полутоновая морфология
        
        switch F(Current,10)
            case {1,2,3,4,5,6}
                subtype = ' пользовательская маска,';
                
            case 7
                subtype = '';
                
            case {8,9,15,16}
                
                switch size(Original,3)
                    case 1
                        conn = {'4','8'};
                    case 3
                        conn = {'6','18','26'};
                    otherwise
                        conn = {'минимальное','максимальное'};
                end
                
                subtype = [' кол-во связей: ' conn{F(Current,4)} ','];
                
            case 10
                switch size(Original,3)
                    case 1
                        conn = {'эвклидова (4-св.)',...
                            'эвклидова (8-св.)',...
                            'городской квартал (4-св.)',...
                            'городской квартал (8-св.)',...
                            'шахматная доска (4-св.)',...
                            'шахматная доска (8-св.)',...
                            'квази-эвклидова (4-св.)',...
                            'квази-эвклидова (8-св.)'};
                    case 3
                        conn = {'эвклидова (6-св.)',...
                            'эвклидова (18-св.)',...
                            'эвклидова (26-св.)',...
                            'городской квартал (6-св.)',...
                            'городской квартал (18-св.)',...
                            'городской квартал (26-св.)',...
                            'шахматная доска (6-св.)',...
                            'шахматная доска (18-св.)',...
                            'шахматная доска (26-св.)',...
                            'квази-эвклидова (6-св.)',...
                            'квази-эвклидова (18-св.)',...
                            'квази-эвклидова (26-св.)'};
                    otherwise
                        conn = {'эвклидова (мин-св.)',...
                            'эвклидова (макс-св.)',...
                            'городской квартал (мин-св.)',...
                            'городской квартал (макс-св.)',...
                            'шахматная доска (мин-св.)',...
                            'шахматная доска (макс-св.)',...
                            'квази-эвклидова (мин-св.)',...
                            'квази-эвклидова (макс-св.)'};
                end
                
                subtype = [' ' conn{F(Current,4)}];
                
            case {11,12,13,14}
                
                switch size(Original,3)
                    case 1
                        conn = {'4','8'};
                    case 3
                        conn = {'6','18','26'};
                    otherwise
                        conn = {'минимальное','максимальное'};
                end
                
                subtype = [' кол-во связей: ' conn{F(Current,4)} ', H = ' num2str(F(Current,3)) ','];
        end
        
        
        switch F(Current,10)
            case 1
                type = 'дилатация:';
            case 2
                type = 'эрозия:';
            case 3
                type = 'размыкание:';
            case 4
                type = 'замыкание:';
            case 5
                type = 'дно шляпы: ';
            case 6
                type = 'верх шляпы: ';
            case 7
                type = 'заполнение отверстий: ';
            case 8
                type = 'очистка границ: ';
            case 9
                type = 'выделение периметра: ';
            case 10
                type = 'конечная эрозия: ';
            case 11
                type = 'расширенный минимум: ';
            case 12
                type = 'расширенный максимум: ';
            case 13
                type = 'Н-мининмум: ';
            case 14
                type = 'Н-максимум: ';
            case 15
                type = 'локальный минимум: ';
            case 16
                type = 'локальный максимум: ';
        end
        
        if F(Current,8) == 0
            it_num = ' до стабилизации';
        else
            it_num = num2str(F(Current,8));
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),' (',type,subtype,' кол-во итераций:',{' '},it_num,')');
        
    case 6              % билатеральные
        
        switch F(Current,10)          % какой подтип фильтра выбран
            case 1
                type = 'исходный';
                Ord = '';
            case 2
                type = 'медиана';
                Ord = '';
            case 3
                type = 'ср. арифметическое';
                Ord = '';
            case 4
                type = 'мин. разность';
                Ord = '';
            case 5
                type = 'адаптивная медиана';
                Ord = '';
            case 6
                type = 'N-мерная медиана';
                if F(Current,4) == 4
                    Ord = ['порядок фильтра: ' char(8734) ', '];
                else
                    Ord = ['порядок фильтра: ' num2str(F(Current,4)) ', '];
                end
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),[' (' type '), ' mask ', ' Ord char(945) ' = ' num2str(F(Current,3))...
            ', ' char(946) ' = ' num2str(F(Current,6))]);
        
        
        
    case 7              % слепая обрабтная свертка
        switch F(Current,10)          % какой тип выбран
            case 1
                type = ' (без очистки "звонов"), ';
            case 2
                type = ' (очистка "звонов"),';
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type,...
            [' размерность PSF: ' num2str(F(Current,3)) 'x' num2str(F(Current,6)) ', число итераций: ' num2str(F(Current,7)) ', порог отклонения: ' num2str(F(Current,8))]);
        
    case 8              % фильтр Габора
        
        type = [[' ' char(963) '_x = '] num2str(F(Current,3)) [', ' char(963) '_y = '] num2str(F(Current,6))...
            ', ' char(955) ' = ' num2str(F(Current,7)) ', ' char(968) ' = '  num2str(F(Current,8)) char(186) ...
            ', ' char(952) ' = '  num2str(F(Current,9)) char(186)];
        Parametrs(Current) = strcat(Parametrs(Current),',',type, ', ', mask);
        
    case 9              % преобразвание Хафа
        
        str2 = get(menu_handles.FiltParMenu2,'String');
        str3 = get(menu_handles.FiltParMenu3,'String');
        
        theta = str2(F(Current,10));
        thresh = str3(F(Current,4));
        
        Filters(Current).FPM2 = str2double(theta);
        Filters(Current).FPM3 = str2double(thresh);
        
        Parametrs(Current) = strcat(Parametrs(Current),...
            [char('(',920,' ','=',' ')' num2str(F(Current,3)) ':' char(theta) ':' num2str(F(Current,6))...
             char(186,',',916,961,' ','=',' ')' num2str(F(Current,7)) '); число пиков: ' num2str(F(Current,13))],...
            [', порог пика: ' char(thresh) '% от max, размер маски подавления: ' num2str(F(Current,8)) 'x' num2str(F(Current,12)) ','],...
            [' min длина линии: ' num2str(F(Current,9)) ' с разрывом до ' num2str(F(Current,11)) ' пикс.']);
        
    case 10             % декорреляционное растяжение
        
        switch F(Current,10)          % какой тип выбран
            case 1
                type = ', без контрастирования';
            case 2
                type = [', контрастирование: ' num2str(F(Current,9)) ' | ' num2str(F(Current,11))];
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),...
            [' (' num2str(F(Current,3)) ':' num2str(F(Current,6)) ';' num2str(F(Current,7)) ':' num2str(F(Current,8)) ')'],type);
        
    case 11             %  произвольный фильтр
        
        switch F(Current,10)          % какой тип выбран
            case 1
                type = ', без вычитания';
            case 2
                type = ', с вычитанием';
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type, ', ', mask,hash);
        
    case 12         % фильтр Виннера
        
        Parametrs(Current) = strcat(Parametrs(Current),[', ' num2str(F(Current,3)) 'x' num2str(F(Current,6))]);
        
    case {13,22}  % Гауссовские
        
        Parametrs(Current) = strcat(Parametrs(Current),[', ' mask hash ', СКО = ' num2str(F(Current,3))]);
        
    case 14         % усредняющий фильтр
        
        switch F(Current,10)          % какой тип выбран
            case 1
                type = ' (среднее арифметическое';
            case 2
                type = ' (среднее геометрическое';
            case 3
                type = ' (гармоническое среднее';
            case 4
                type = [' (контргармоническое среднее, порядок: ' num2str(F(Current,3))];
            case 5
                type = ' (максимум';
            case 6
                type = ' (минимум';
            case 7
                type = ' (средняя точка';
            case 8
                type = [' (среднее усеченное, число усеченных элементов: ' num2str(F(Current,3))];
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type,['), ' mask]);
        
    case 15       % фильтр Собеля
        
        switch F(Current,4)
            case 1
                dir = 'гориз. (утончение)';
            case 2
                dir = 'гориз. (без утончения)';
            case 3
                dir = 'верт. (утончение)';
            case 4
                dir = 'верт. (без утончения)';
            case 5
                dir = 'оба. (утончение)';
            case  6
                dir = 'оба. (без утончения)';
        end
        
        if F(Current,3) == 0
            Parametrs(Current) = strcat(Parametrs(Current),[', порог: авто, ' dir]);
        else
            Parametrs(Current) = strcat(Parametrs(Current),[', порог: ' num2str(F(Current,3)) ', ' dir]);
        end
        
    case 16       % фильтр Кенни
        
        if F(Current,6) == 256 || F(Current,3) == -1
            Parametrs(Current) = strcat(Parametrs(Current),',',' авто | авто',[', СКО = ' num2str(F(Current,7))]);
        else
            Parametrs(Current) = strcat(Parametrs(Current),[', ' num2str(F(Current,3)) ' | ' num2str(F(Current,6)) ', СКО = ' num2str(F(Current,7))]);
        end
        
    case 17         % фильтр Превитта
        
        if F(Current,4)== 1
            dir = 'гориз.';
        elseif F(Current,4)== 2
            dir = 'верт.';
        elseif F(Current,4)== 3
            dir = 'оба';
        end
        
        if F(Current,3) == 0
            Parametrs(Current) = strcat(Parametrs(Current),[', порог: авто, ' dir]);
        else
            Parametrs(Current) = strcat(Parametrs(Current),[', порог: ' num2str(F(Current,3)) ', ' dir]);
        end
        
    case 18       % фильтр Робертса
        
        if F(Current,4)== 1
            dir = 'утончение';
        elseif F(Current,4)== 2
            dir = 'без утончения';
        end
        
        if F(Current,3) == 0
            Parametrs(Current) = strcat(Parametrs(Current),[', порог: авто, ' dir]);
        else
            Parametrs(Current) = strcat(Parametrs(Current),[', порог: ' num2str(F(Current,3)) ', ' dir]);
        end
        
    case 19     % дисковый фильтр
        Parametrs(Current) = strcat(Parametrs(Current),[', ' mask]);
        
    case 20         % Лапласа ФВЧ
        
        Parametrs(Current) = strcat(Parametrs(Current),[', СКО = ' num2str(F(Current,3))]);
        
    case 21  % Гауссовские
        
        Parametrs(Current) = strcat(Parametrs(Current),[', ' mask ', a = ' num2str(F(Current,3))]);
        
    case 23  % Адаптивный медианный
        
        Parametrs(Current) = strcat(Parametrs(Current),[', от' mask ' до ' num2str(F(Current,3)) 'x' num2str(F(Current,3))]);
        
    case 24     % Гамма-фильтр
        
        type = [',' mask ', ' ...
                'число выборок = ' num2str(F(Current,3))];
        
        Parametrs(Current) = strcat(Parametrs(Current),type);
        
    case 25     % фильтры Ли
        
        switch Filters(Current).FPM2
            
            case 1      % оригинальный фильтр
                
                switch Filters(Current).FPM3
                    
                    case 1      % аддитивная модель
                        
                        type = [' (оригинальный, аддитивная модель помехи): '...
                                mask ', ' ...
                                char(963) char(178) ' = ' num2str(F(Current,3)) ', '...
                                char(956) ' = ' num2str(F(Current,6))];
                        
                    case 2      % мультипликативная модель
                        
                        type = [' (оригинальный, мультипликативная модель помехи): '...
                                mask ', ' ...
                                char(963) char(178) ' = ' num2str(F(Current,7)) ', '...
                                char(956) ' = ' num2str(F(Current,8)) ', '...
                                'число выборок = ' num2str(F(Current,9))];
                        
                    case 3      % адд. + мультип.                        
                        
                        type = [' (оригинальный, адд.+мульт. модель помехи): '...
                                mask ', ' ...
                                char(963) char(178) ' адд.помех = ' num2str(F(Current,3)) ', '...
                                char(956) ' адд.помех = ' num2str(F(Current,6)) ', ' ...
                                char(963) char(178) ' мульт.помех = ' num2str(F(Current,7)) ', '...
                                char(956) ' мульт.помех = ' num2str(F(Current,8)) ', '...
                                'число выборок = ' num2str(F(Current,9))];
                end
                
            case 2      % улучшенный фильтр
                
                type = [' (улучшенный): ' ...
                        mask ', ' ...
                        'коэфф. затухания = ' num2str(F(Current,11)) ', '...
                        'число выборок = ' num2str(F(Current,9))];
                
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type);
        
    case 26     % фильтр Фроста
        switch Filters(Current).FPM2
            
            case 1      % оригинальный фильтр
                
                type = [' (оригинальный): ' ...
                        mask ', ' ...
                        'коэфф. затухания = ' num2str(F(Current,3))];
                
            case 2      % улучшенный фильтр
                
                type = [' (улучшенный): ' ...
                        mask ', ' ...
                        'коэфф. затухания = ' num2str(F(Current,3)) ', '...
                        'число выборок = ' num2str(F(Current,6))];
                
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type);
        
    case 27     % фильтр Куана
        
        type = [',' mask ', ' ...
                'число выборок = ' num2str(F(Current,3))];
        
        Parametrs(Current) = strcat(Parametrs(Current),type);        
        
    case 28     % Фильтр локальных статистик
        
        switch F(Current,10)
            case 1
                type = ' (предельный),';
            case 2
                type = ' (энтропийный),';                
            case 3
                type = ' (СКО),';                
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),type,mask); 
        
    case 29     % Пороговая обработка
        
        if F(Current,4) == 1
            type = [' (Пропускание -> ' num2str(F(Current,3)) '):'];
        elseif F(Current,4) == 2
            type = [' (Подавление -> ' num2str(F(Current,3)) '):'];
        end
        
        if F(Current,10 )== 1
            RGBHSV = ' RGB';
        elseif F(Current,10) == 2
            RGBHSV = ' HSV';
        end
        
        range = [', ' num2str(F(Current,8)) ' ' char(8804) ' I ' char(8804) ' ' num2str(F(Current,12))];
        
        Parametrs(Current) = strcat(Parametrs(Current),type,RGBHSV,[', канал № ' num2str(F(Current,6))],range);
        
    case 30     % градиент        
        
        switch F(Current,10)
            case 1
                type = 'Амплитуда градиента';
            case 2
                type = 'Направление градиента';                
            case 3
                type = 'Направленный градиент по Ох';                     
            case 4
                type = 'Направленный градиент по Оy';               
        end
        
        switch F(Current,4)
            case 1
                method = ' Собеля';
            case 2
                method = ' Превитта';          
            case 3
                method = ' центральной разности';                
            case 4
                method = ' средней разности';           
            case 5
                method = ' Робертса';                
        end
        
        Parametrs(Current) = strcat(Parametrs(Current),' (',type,method,')');        
        
    case 31     % эквализация
        
        if F(Current,4)== 1
            typ = 'Цветовое пространство: RGB';
        elseif F(Current,4)== 2
            typ = 'Цветовое пространство: HSV';
        end
        Parametrs(Current) = strcat(Parametrs(Current),[' (' num2str(typ) '), ' 'Число уровней: ' num2str(F(Current,3))]);
        
    case 32     % квантование
        
       Parametrs(Current) = strcat(Parametrs(Current),[': бит/пиксель: ' num2str(F(Current,3)) ', k = ' num2str(F(Current,6))]);
        
    case 33     % контрастирование с гамма-коррекцией
        
        Parametrs(Current) = strcat(Parametrs(Current),...
            [', ' char(947) ' = ' num2str(F(Current,3)) ' (' num2str(F(Current,6)) ' | ' num2str(F(Current,7)) ' :: ' num2str(F(Current,8)) ' | ' num2str(F(Current,9)) ')']);
    
    case 34     % детектор окружностей
        
        if F(Current,10) == 1
            type = ['(Хафа): чувств-ть: ' num2str(F(Current,6)) ','];
        elseif F(Current,10) == 2
            type = '(Атертона и Кирбисона):';            
        end
        
        if F(Current,4) == 1
            targets = ' цели темнее фона,';
        elseif F(Current,4) == 2
            targets = ' цели светлее фона,';            
        end        
        
        Parametrs(Current) = strcat(Parametrs(Current),...
            [type targets ' порог: ' num2str(F(Current,7)) ', '...
            num2str(F(Current,8)) char(8804) 'R' char(8804) num2str(F(Current,12))]);
        
    case 35     % детектор ключевых точек
        
        switch F(Current,10)    
            case 1      % BRISK
                Parametrs(Current) = strcat(Parametrs(Current),...
                    [' (BRISK), мин. качество: ' num2str(F(Current,3))...
                    ', мин. контраст: ' num2str(F(Current,6)) ...
                    ', число октав: ' num2str(F(Current,8))]);
                
            case 2      % FAST
                Parametrs(Current) = strcat(Parametrs(Current),...  
                    [' (углов FAST), мин. качество: ' num2str(F(Current,3))...
                    ', мин. контраст: ' num2str(F(Current,6))]);     
            
            case 3      % HARRIS
                Parametrs(Current) = strcat(Parametrs(Current),...
                    [' (углов Харриса), мин. качество: ' num2str(F(Current,3))...
                    ', размер окна: ' num2str(F(Current,7)) 'x' num2str(F(Current,7))]);    
            
            case 4      % MinEagenVals
                Parametrs(Current) = strcat(Parametrs(Current),... 
                    [' (углов (мин. собст. знач.)), мин. качество: ' num2str(F(Current,3))...
                    ', размер окна: ' num2str(F(Current,7)) 'x' num2str(F(Current,7))]);
            
            case 5      % SURF
               Parametrs(Current) = strcat(Parametrs(Current),... 
                    [' (SURF), порог: ' num2str(F(Current,11))...
                    ', число уровней мастаба: ' num2str(F(Current,9)) ...
                    ', число октав: ' num2str(F(Current,8))]);
        end
        
end

set(menu_handles.UsePreviousFiltImage,'Enable','on');   % разблокируем галочку
set(menu_handles.NoiseFilterString,'String',Parametrs,'FontSize',10); 


% КНОПКА "УДАЛИТЬ ПОЗИЦИЮ"
function DeleteButton_Callback(~, ~, menu_handles)

global Noises;              % список параметров зашумления
global Filters;             % список параметров фильтрации
global Parametrs;           % параметры эксперимента 

Nums2del = get(menu_handles.DeleteSlider,'Value');    % считываем номер позиции для удаления

% продоводим очищение зависимых от предыдущего изображения операций
if Nums2del(1) ~= size(Noises,1)              % если выбран не последний пункт списка
    for x = Nums2del(1)+1:size(Noises,1)      % начиная со следующего, проверяем
        
        if Noises(x,4) == 1           % если он зависит от предыдущего
            Nums2del(end+1) = x;             %#ok<AGROW>
        else
            break;                  % иначе выходим отсюда
        end
    end
end

Noises(Nums2del,:) = [];          % убираем позиции из всех массивов
Filters(Nums2del) = [];      
Parametrs(Nums2del) = [];

for i = Nums2del(1) : size(Noises,1)    % во всех следующих строках убавляем порядковый номер
    Parametrs(i) = regexprep(Parametrs(i),num2str(i + size(Nums2del,2) ),num2str(i),'once');
end


if isempty(Noises)                              % если массив стал пустой
    
    set(menu_handles.DeleteSlider,'Value',1);        % меняем значение слайдера
    set(menu_handles.DeleteNumber,'String','1');     % меняем номер позиции
    set(menu_handles.NoiseFilterString,'Value',1,'String','');
    set([   menu_handles.DeleteSlider;...
            menu_handles.DeleteNumber;...
            menu_handles.DeleteButton;...
            menu_handles.UsePreviousFiltImage;...
            menu_handles.ApplyButton],...            
            'Enable','off');
        
elseif size(Noises,1) == 1          % если осталась только одна строка
    
    set(menu_handles.NoiseFilterString,'Value',1);
    set(menu_handles.DeleteSlider,'Value',1);        % меняем значение слайдера
    set(menu_handles.DeleteNumber,'String','1');     % меняем номер позиции
    set([   menu_handles.DeleteSlider;...
            menu_handles.DeleteNumber],...            
            'Enable','off');
        
    set(menu_handles.NoiseFilterString,'String',Parametrs);
    
else
    
    if Nums2del(1) == 1              % определяем новое значение выделенной строки в списке
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


% КНОПКА "ОТМЕНА"
function CancelButton_Callback(~, ~, menu_handles)

global Noises;              % список параметров зашумления
global Filters;             % список параметров фильтрации

Noises(:,:) = [];       % при закрытии зануляем
Filters(:,:) = [];
delete(menu_handles.menu);


% КНОПКА "EXP(ALPHA)"
function FiltParButton1_Callback(~, ~, menu_handles)

scr_res = get(0, 'ScreenSize');
alpha = get(menu_handles.AlphaSlider,'Value');

switch get(menu_handles.FilterType,'Value') 
    
    case 5                      % полутоновая морфология
        
        Data = get(menu_handles.MaskTable1,'Data');      % матрица коэффициентов
        beta = get(menu_handles.BetaSlider,'Value');     % целевая строка
        gamma = get(menu_handles.GammaSlider,'Value');  % целевой столбец
        
        Data(beta,gamma) = alpha;                       % заменили
        set(menu_handles.MaskTable1,'Data',Data);        % вставили назад
        return;
        
    case 6                     % билатеральный фильтр

        x = 0:255;
        graph = exp(-alpha*(abs(x)));
        GraphTitle = { 'Зависимость коэффициента доверия от модуля разности яркости пикселей';...
                'K(\DeltaI) = exp(-\alpha|\DeltaI|),';...
                ['где \alpha = ' num2str(alpha)]};     
            
    case 8                  % фильтр Габора
        
        X = 2*get(menu_handles.FiltParMenu1,'Value')+1;
        sigma_x = get(menu_handles.AlphaSlider,'Value');
        sigma_y = get(menu_handles.BetaSlider,'Value');
        lambda = get(menu_handles.GammaSlider,'Value');
        psi = get(menu_handles.DeltaSlider,'Value');
        theta = get(menu_handles.EpsilonSlider,'Value');        
        
        [x,y] = meshgrid(-fix(X/2):fix(X/2),-fix(X/2):fix(X/2));
        
        % Поворот
        x_theta = x*cos(theta) + y*sin(theta);
        y_theta = -x*sin(theta) + y*cos(theta);
        
        graph = exp(-0.5*(x_theta.^2/sigma_x^2 + y_theta.^2/sigma_y^2))* cos(2*pi*x_theta./lambda + psi);        
        
        figure('Color',[1 1 1],'Position',[(scr_res(3)-800)/2 (scr_res(4)-600)/2 800 600],'NumberTitle','off');
        surf(graph);
        GraphTitle = {'Маска фильтра Габора';...
                        ['\sigma_x = ' num2str(sigma_x) ', \sigma_y = ' num2str(sigma_y)...
                        ', \lambda = ' num2str(lambda) ', \theta = '  num2str(theta) ', \psi = '  num2str(psi)]};
        title(GraphTitle,'FontName','Times New Roman');
        set(gca,'FontSize',12);
        set(gca,'XTick',1:2:X,'XLim',[1 X],'YTick',1:2:X,'YLim',[1 X]);
        
        return;
        
            
    case 11             % произвольный фильтр
        
        Data = get(menu_handles.MaskTable,'Data');      % матрица коэффициентов
        beta = get(menu_handles.BetaSlider,'Value');     % целевая строка
        gamma = get(menu_handles.GammaSlider,'Value');  % целевой столбец
        
        Data(beta,gamma) = alpha;                       % заменили
        set(menu_handles.MaskTable,'Data',Data);        % вставили назад
        return;
        
    case 33                     % контрастирвоание с гамма-коррекцией
        
        x = 0:0.0001:1;
        graph = 255*(x.^alpha);
        x = x*255;
        GraphTitle = { 'Кривая гамма-коррекции';...
                ['I(вых) = I(вх)^{\gamma}, где \gamma = ' num2str(alpha)]};
        

end

figure('Color',[1 1 1],'Position',[(scr_res(3)-800)/2 (scr_res(4)-600)/2 800 600],'NumberTitle','off'); 
plot(x,graph,'LineWidth',3);
title(GraphTitle,'FontName','Times New Roman');
set(gca,'XTick',0:20:260,'XLim',[0 260]);   
set(gca,'FontSize',12);


% КНОПКА "EXP(BETA)"
function FiltParButton2_Callback(~, ~, menu_handles)

scr_res = get(0, 'ScreenSize');
beta = get(menu_handles.BetaSlider,'Value');
gamma = get(menu_handles.GammaSlider,'Value');

switch get(menu_handles.FilterType,'Value') 
    
    case 4              % морфологическая обработка
        
        switch get(menu_handles.FiltParMenu2,'Value')
            
            case {1,2,3,4,5,6}      % дилатация ...шляпы
                
                switch get(menu_handles.FiltParMenu3,'Value')
                    
                    case 1          % Ромб             
                        structure = strel('diamond',beta);
                    case 2          % Круг
                        structure = strel('disk',beta);
                    case 3          % Линия
                        structure = strel('line',beta,gamma);
                    case 4          % Восьмиугольник
                        structure = strel('octagon',beta);
                    case 5          % Пара точек
                        structure = strel('pair',[beta gamma]);
                    case 6          % Прямоугольник
                        structure = strel('rectangle',[beta gamma]);
                end
                
                object = getnhood(structure);
                
                try
                    imtool(object);
                catch
                    OpenImageOutside(object);
                end
                
                return;
                
            case 11     % успех/неудача
        
                Data = get(menu_handles.MaskTable,'Data');      % матрица коэффициентов
                epsilon = get(menu_handles.EpsilonSlider,'Value');     % целевая строка
                zeta = get(menu_handles.ZetaSlider,'Value');  % целевой столбец
                
                Data(epsilon,zeta) = beta;                       % заменили
                set(menu_handles.MaskTable,'Data',Data);        % вставили назад
                return;
        end
        
    case 5      % полутоновая морфология
        
        Data = menu_handles.MaskTable1.Data;
        LogicData = menu_handles.MaskTable.Data;        
        object = Data.*LogicData/255;        
        
        try
            imtool(object);
        catch
            OpenImageOutside(object);
        end
        
        return;
        
    case 6                     % билатеральные фильтры
        
        xmax = 2*get(menu_handles.FiltParMenu1,'Value');        
        x = 0:0.1:xmax;
        graph = exp(-beta*(x));        
        Xlimits = 0:1:xmax;
        GraphTitle = {'Зависимость коэффициента доверия от суммы модулей разности индексов пикселей';...
            'K(i,j) = exp(-\beta(|i-i_{0}|+|j-j_{0}|)),';...
            ['где \beta = ' num2str(beta)]};
        Ylimits = inf;
        
    case 32             % квантование
        
        x = 0:0.001:1;
        graph = (2^get(menu_handles.AlphaSlider,'Value')-1)*(x.^beta);
        x = x*255;
        GraphTitle = {  'Характеристика квантования';
                        ['I(вых) = I(вх)^{k}, где k = ' num2str(beta)]}; 
        Xlimits = 0:30:270;
        if get(menu_handles.AlphaSlider,'Value') < 6
            Ylimits = [0 1 3 7 15 31];
        else
            Ylimits = [0 3 7 15 31 63 127]; % тут двойка сливается с 4 и 0, убираем
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

if get(menu_handles.FilterType,'Value') == 31       % для квантования нарисуем уровни квантования
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


% КНОПКА "ВЫПОЛНИТЬ"
function ApplyButton_Callback(hObject, eventdata, menu_handles, handles)

global Original;            % исходное изображение
global Noised;              % зашумленный вариант
global Filtered;            % отфильтрованное изображение
global Noises;              % список параметров зашумления
global Filters;             % список параметров фильтрации
global Parametrs;           % параметры эксперимента (шумы и фильтры)
global Assessment_N;        % массив оценок искаженных изображений
global Assessment_F;        % массив оценок обработанных изображений
global FilteredAsOriginal;    % переменная, которая определеят, что зашумляем
global ContinueProcessing;  % лог переменная того, что нужно продолжить обработку, не удаляя результат предыдущей


if ContinueProcessing          % если продолжаем обработку, то определим с какой позиции
    start = size(Noised,4) + 1; 
else
    start = 1;
end

% временные массивы, чтобы не удалять старые данные в случае отмены
Temp_Filtered = zeros(size(Original,1),size(Original,2),size(Original,3),size(Noises,1),'uint8');
Temp_Noised = zeros(size(Original,1),size(Original,2),size(Original,3),size(Noises,1),'uint8');
str = cell(size(Noises,1),1);

%%%%%%%%%%%%%%%%%  ВЫПОЛНЕНИЕ ЗАШУМЛЕНИЯ И ФИЛЬТРАЦИИ %%%%%%%%%%%%%%%%%%%%%
set(gcf,'Visible','off');
Wait = waitbar(0,'Обработка изображения № 1',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(Wait,'canceling',0);
Wait.WindowStyle = 'modal';

for k = 1:size(Noises,1)
    
    %     set(Wait, 'WindowStyle','modal');
    waitbar(k/(size(Noises,1)+1),Wait,['Обработка изображения № ' num2str(k)]);
    
    %%%%%%%%%%% ИСКАЖЕНИЕ  
    try
        % если используем предыдущее отфильтрованное изображение   
        if Noises(k,4) == 1            
            Im = Temp_Filtered(:,:,:,k-1);            
        else
            Im = Original;
        end
        
        % надо ли использовать предыдущ отфильтр. как зашумленное
        if isempty(FilteredAsOriginal)
            
            Temp_Noised(:,:,:,k) = Noising( Im,...
                Noises(k,1),...
                Noises(k,2),...
                Noises(k,3));  % зашумили
            
        else                  % исп. отфильтрованное как зашумленное
            Temp_Noised(:,:,:,k) = Noising( FilteredAsOriginal,...
                Noises(k,1),...
                Noises(k,2),...
                Noises(k,3));  % зашумили
        end
        
    catch ME
        delete(Wait);
        delete(menu_handles.menu);      % закрываем меню-окно
        errordlg({['Искажение изображения потерпело неудачу в строке № ' num2str(ME.stack(1).line)]; ME.message},'KAAIP','modal');
        return;
    end
    
    %%%%%%%%%%%%%%%%%% ОБРАБОТКА
    
    try
        Temp_Filtered(:,:,:,k) = Filtration(Temp_Noised(:,:,:,k),Filters(k));
    catch ME
        delete(Wait);
        delete(menu_handles.menu);      % закрываем меню-окно
        errordlg({['Обработка изображения потерпела неудачу в строке № ' num2str(ME.stack(1).line)];...
                ME.message},'KAAIP','modal');
        return;
    end
    
    drawnow;         % обновляем значение кнопки отмены, чтобы она работала сразу
    
    if getappdata(Wait,'canceling') == 1          % если нажали кнопку отмены - выходим из цикла
        delete(Wait);
        delete(menu_handles.menu);      % закрываем меню-окно
        return;
    end
    
end

if ContinueProcessing          % если продолжаем обработку, то определим с какой позиции
    
    % поменяем порядковые номер обработок (влияет только, если start > 1)
    for i = 1:size(Noises,1)     % во всех следующих строках убавляем порядковый номер
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

set(findobj('Parent',Wait,'Style','pushbutton'),'Enable','off');    % чтобы пользователь отменой ничего не сбил

for p = 1:size(Filtered,4)
    str{p} = ['Изображение № ' num2str(p)];
end

waitbar(k/(size(Noises,1)+1),Wait,'Расчет критериев оценки');

% нужен ли расчет SSIM-характеристик
if menu_handles.SSIM_check.Value == 1
    SSIM = 2;
else
    SSIM = 0;
end

% проведем оценку полученных изображений и округлим ее до сотых
Assessment_N = [];
Assessment_F = [];
Assessment_N = GetAssessment(Original,Noised,SSIM);
Assessment_F = GetAssessment(Original,Filtered,SSIM);

% УСТАНОВКИ ОСНОВНОГО ОКНА
set(handles.NoisedMenu,'String',str,'Value',1,'Enable','on');
set(handles.FilteredMenu,'String',str,'Value',1,'Enable','on');
handles.AssessMenu.Value = 1;
set(handles.Noised,'Enable','on');
set(handles.Filtered,'Enable','on');

ShowMenuString = handles.ShowMenu.String;
if ~strcmp(ShowMenuString{end},'SSIM-изображения');
    ShowMenuString{end+1} = 'SSIM-изображения';
end
handles.ShowMenu.String = ShowMenuString;

% если число фильтраций свыше 10, настроим слайдер
if size(Noised,4) > 10
    set(handles.GraphSlider,'Min',1,...
        'Value',1,...
        'Max',size(Noised,4)-9,...
        'Enable','on',...
        'SliderStep',[1/(size(Noised,4)-10) 10/(size(Noised,4)-10)]);
    
else    % иначе сделаем недоступным
    set(handles.GraphSlider,'Enable','off');
end

% вызовем подфункцию, которая нарисует графики и обновить картинки
ShowMenu_Callback(hObject, eventdata, handles);
AssessMenu_Callback(hObject, eventdata, handles);

% выставляем начальные значения и делаем видимыми объекты
set(handles.FiltAgain,'Label','Обработать ранее обработанное изображение № 1');
set(handles.FiltAgainNoised,'Label','Обработать искаженное изображение № 1');

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

if size(Noised,4) > 1       % если в списке более 1й обработки, тогда можно что-то удалять
    set(handles.DeleteListPosition,'Enable','on');
end

delete(menu_handles.menu);          % закрываем меню-окно
delete(Wait);                       % модальное окно закрываем, и пользователь не успеет накосячить
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ТАБЛИЦА %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ОТКЛИК ВЫДЕЛЕНИЯ ЭЛЕМЕНТА ТАБЛИЦЫ
function MaskTable_CellSelectionCallback(~, eventdata, menu_handles)

% какого то хера заходит дважды в отклик, причем второй раз обнуляет индексы,
% поэтому такой костыль с проверкой на их значение (?0)

switch get(menu_handles.FilterType,'Value')
    
    case {2,5,28}      % медианный фильтр и полуотоновая морфология
        
        if size(eventdata.Indices,1) > 0
            Data = get(menu_handles.MaskTable,'Data');
            Data(eventdata.Indices(1),eventdata.Indices(2)) = abs(Data(eventdata.Indices(1),eventdata.Indices(2)) - 1);
            set(menu_handles.MaskTable,'Data',Data);
            
            if any(any(Data)) == 0          % если пользователь обнулил всю матрицу - исправляем, добавив по центру единицу
                Data((size(Data,1)+1)/2,(size(Data,1)+1)/2) = 1;
                set(menu_handles.MaskTable,'Data',Data);
            end
        end
        
    case 4      % морфологическая обработка 
            
        if size(eventdata.Indices,1) > 0
            Data = get(menu_handles.MaskTable,'Data');            
                
            if get(menu_handles.FiltParMenu2,'Value') == 11     % успех/неудача
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
                
                if any(any(Data)) == 0          % если пользователь обнулил всю матрицу - исправляем, добавив по центру единицу
                    Data((size(Data,1)+1)/2,(size(Data,1)+1)/2) = 1;
                    set(menu_handles.MaskTable,'Data',Data);
                end
            end
        end
            
            
    case 11     % произвольный фильтр
        
        if size(eventdata.Indices,1) > 0
            set(menu_handles.BetaSlider,'Value',eventdata.Indices(1));
            set(menu_handles.BetaValText,'String',num2str(eventdata.Indices(1)));
            set(menu_handles.GammaSlider,'Value',eventdata.Indices(2));
            set(menu_handles.GammaValText,'String',num2str(eventdata.Indices(2)));            
        end
                
                
end


% ОТКЛИК ВЫДЕЛЕНИЯ ЭЛЕМЕНТА ТАБЛИЦЫ 1
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


% КОНТЕКТНОЕ МЕНЮ "КОПИРОВАТЬ МАСКУ КАК ИЗОБРАЖЕНИЕ"
function CopyMask_Callback(~, ~, menu_handles)
    
if gco == menu_handles.MaskTable
    ClipboardCopyObject(menu_handles.MaskTable,0);
    
elseif gco == menu_handles.MaskTable1
    ClipboardCopyObject(menu_handles.MaskTable1,0);
end


% КОНТЕКТНОЕ МЕНЮ "СОХРАНИТЬ МАСКУ КАК ИЗОБРАЖЕНИЕ"
function SaveMask_Callback(~, ~, ~)    
    
[FileName, PathName] = uiputfile({'*.jpg';'*.bmp';'*.tif';'*.png'},'Сохранить маску');

if FileName~=0 
    SaveObjectAsImage(gco,[PathName FileName]);
end

    
% КОНТЕКТНОЕ МЕНЮ "СОХРАНИТЬ МАСКУ КАК ТАБЛИЦУ"
function SaveMaskXLSX_Callback(~, ~, ~)

Data = get(gco,'Data');

[FileName, PathName] = uiputfile('*.xlsx','Сохранить маску');

if FileName~=0 
    xlswrite([PathName FileName],Data);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ФУНКЦИИ  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ФУНКЦИЯ АДДИТИВНОГО ЗАШУМЛЕНИЯ В ЗАВИСИМОСТИ ОТ ВЫБРАННОГО ТИПА ШУМА
function Noised = Noising(Image,NoiseType,A,B)
% Noised - выходное зашумленное изображение, размер которого совпадает с
%   входным
% Image - входное изображение, кол-во каналов не ограничено
% NoiseType - тип шума
% A - параметр шума для каждого распределения
% В - второй параметр шума только для равномерного распределения

Noised = double(Image);  

for CH = 1:size(Noised,3)                % для каждого канала цвета 
    
    switch NoiseType                                              

        case 2                                  % НОРМАЛЬНОЕ РАСПРЕДЕЛЕНИЕ
            
            N = B/255 + (A/255).*randn(size(Noised,1),size(Noised,2));       % мат.ожидание+дисперсия(шумовая матрица)    
            N = round(N*255);
            Noised(:,:,CH) = Noised(:,:,CH) + N;
                               
        case 3                             % ШУМ ПУАССОНА
            
            Noised = imnoise(Image,'poisson');

        case 4                                  % ЛАПЛАСА РАСПРЕДЕЛЕНИЕ
            
            N = rand(size(Noised,1),size(Noised,2));        % раномерно зашумленная матрица        
            
            for j = 1:size(Noised,1)                          % в каждый столбец
                for i = 1:size(Noised,2)                      % в каждую строку
                    if N(j,i) <= 0.5                        % из за закона распределения используем
                            N(j,i) = 0.5 + log(2*N(j,i))/A;  
                    else                                    % такую формулу на двух интервалах
                            N(j,i) = 0.5 - log(2*(1-N(j,i)))/A;
                    end
                end
            end
            
            N = N - 0.5 + B/255;
            N = round(N*255);            
            Noised(:,:,CH) = Noised(:,:,CH) + N;

        case 5                         % РАВНОМЕРНОЕ РАСПРЕДЕЛЕНИЕ
            
            N = rand(size(Noised,1),size(Noised,2));        % рандомная шумовая матрица
            N = round(N*(B-A)+A);        % в 256 оттенках
            Noised(:,:,CH) = Noised(:,:,CH) + N;
            
        case 6                                  % СПЕКЛ-ШУМ
            
            Noised = imnoise(Image,'speckle',A/255);
            
        case 7                                  % СОЛЬ-ПЕРЕЦ ШУМ
            
            Noised = imnoise(Image,'salt & pepper',A*0.01);
            
        case 8                                  % СОЛЬ-ШУМ
            
            for i = 1:size(Noised,1)*size(Noised,2)*A*0.01      % для заданного количества пикселей
                x = fix(rand(1)*(size(Noised,2)-1))+1;       % узнаем случ. координату по Х
                y = fix(rand(1)*(size(Noised,1)-1))+1;       % узнаем случ. координату по Y
                Noised(y,x,CH) = 255;                        % меняем случайно выбранный пиксель на белый
            end
            
        case 9                                  % ПЕРЕЦ-ШУМ
            
            for i = 1:size(Noised,1)*size(Noised,2)*A*0.01      % для заданного количества пикселей
                x = fix(rand(1)*(size(Noised,2)-1))+1;       % узнаем случ. координату по Х
                y = fix(rand(1)*(size(Noised,1)-1))+1;       % узнаем случ. координату по Y
                Noised(y,x,CH) = 0;                          % меняем случайно выбранный пиксель на белый
            end
            
        case 10                                 % РАЗМЫТИЕ ШУМ
            
            filtemask = fspecial('motion', A, B);
            Noised(:,:,CH) = imfilter(Noised(:,:,CH),filtemask,'circular');
            
        case 11                                  % РЭЛЕЯ РАСПРЕДЕЛЕНИЕ
            
            N = raylrnd(A,size(Noised,1),size(Noised,2));
            N = round(N*255);
            Noised(:,:,CH) = Noised(:,:,CH) + N; 
            
        case 12                                  % ЭКСПОНЕНЦИАЛЬНОЕ РАСПРЕДЕЛЕНИЕ
            
            N = exprnd(1/A,size(Noised,1),size(Noised,2));            
            N = round(N*255);
            Noised(:,:,CH) = Noised(:,:,CH) + N; 
    end    
end

if ~isfloat(Image) 
    Noised = uint8(Noised);
end


% ФУНКЦИЯ ФИЛЬТРАЦИИ 
function Filtered = Filtration(Image,Filters)

% Filtered - выходное изображение, размер которого совпадает с входным
% Image - входное изображение, возможно и многоканальное

FilterType = Filters.FilterType;   % считываем тип фильтра
IndentNumber = Filters.Indent;     % считываем значение типа обработки краев
FPM1 = Filters.FPM1;               % и размер маски
FPM2 = Filters.FPM2;               % считываем значение второго меню
FPM3 = Filters.FPM3;               % считываем порядок

alpha = Filters.Alpha;             % считываем параметр альфа
beta =  Filters.Beta;              % считываем параметр бета
gamma = Filters.Gamma;             % считываем значение слайдера гамма
delta = Filters.Delta;             % считываем параметр дельта
epsilon = Filters.Epsilon;         % считываем значение слайдера эпсилон
zeta = Filters.Zeta;               % считываем значение слайдера дзета
eta =   Filters.Eta;               % считываем значение слайдера ита
theta = Filters.Theta;             % считываем значение слайдера тета

Mask = Filters.mask;               % получили маску
Mask1 = Filters.mask1;             % получили маску1

if FilterType == 1                  % елси не нужно обработки - копируем и уходим
    Filtered = Image;
    return;
end

MaskSize = 2*FPM1 + 1;
MaskElements = MaskSize^2;          % количество элементов в маске
Filtered = zeros(size(Image));      % выделяем память
Image = im2double(Image);           % ТЕПЕРЬ изображения от 0 до 1 !!!!

switch IndentNumber                 % выбираем тип обработки краев изображения
    case 1
        IndentType = 'symmetric';   % для всех нормальных фильтров
        IndentTypeMed = 'symmetric';% для медианного фильтра (старая функция в нем дремлет)
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

% ЗАГОНЯЕМ ФИЛЬТР В ЭТОТ ЦИКЛ

for CH = 1:size(Image,3)        % для каждого канала цвета 
    
    switch FilterType
        case 1                  % НЕТ ОБРАБОТКИ            
            
        case 2                  % МЕДИАННЫЙ ФИЛЬТР
            
            switch FPM2
                case 1          % классический
                    CenterElement = round((size(find(Mask == 1),1)+1)/2);           % узнаем центр. элемент
                    Filtered(:,:,CH) = ordfilt2(Image(:,:,CH),CenterElement,Mask,IndentTypeMed);  % фильтруем
                    
                case 2          % мин. разности
                    
                    ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);      % получили векторы-столбцы
                    Col = zeros(size(Image,1)*size(Image,2),1);         % выходное изображение сюда запишем                  
                    Ro = zeros(MaskElements,1);                         % столбец для рассчета расстояний
                    
                    for x = 1:size(ImCol,2)         % для каждой маски
                        
                        for y = 1:MaskElements
                            Ro(y) = abs(ImCol(y,x)*MaskElements - sum(ImCol(:,x))); % расчет расстояний между пикселями
                        end
                        [~,I] = min(Ro);        % получаем адрес минимального расстояния
                        Col(x) = ImCol(I,x);    % присваеваем вектору-столбцу новое значение
                    end
                    
                    Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH)); % превращаем столбцы в изображение
                    
                case 3          % адаптивный
                    
                    ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);
                    Col = zeros(size(Image,1)*size(Image,2),1);
                    central = (MaskElements+1)/2;             % номер целевого пикселя маски
                    
                    for x = 1:size(ImCol,2)                                 % для каждого столбца
                        ImCol(:,x) = round(255*sort(ImCol(:,x),'ascend'));  % сортируем по возрастанию, как в медианной фильтрации
                        
                        if ImCol(central+1,x)-ImCol(central-1,x) ~= 0       % если ближайшие от центра пиксели отличаются по яркости
                            
                            Intermediate = (ImCol(central-1,x):ImCol(central+1,x))';    % строим ряд значений яркостей
                            
                            R = zeros(size(Intermediate));      % вектор для расчета расстояний между значениями яркости    
                            for y = 1:size(Intermediate,1)      % для каждого значения ищем сумму расстояний
                                R(y) = abs(Intermediate(y)*size(Intermediate,1) - sum(Intermediate(:)));
                            end
                            
                            [~,I] = min(R);                     % получаем адрес минимального расстояния
                            Col(x) = Intermediate(I)/255;       % присваеваем вектору-столбцу новое значение
                        else
                            Col(x) = ImCol(central,x)/255;      % иначе, просто медиана
                        end
                    end
                    
                    Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));  % превращаем столбцы в изображение
                    
                case 4          % N-мерный
                    
                    for RGB = 1:size(Image,3)
                        ImCol(:,:,RGB) = image2col(Image(:,:,RGB),MaskSize,IndentType);
                    end
                    
                    Col = zeros(size(Image,1)*size(Image,2),1,size(Image,3));   % RGB-мерный вектор-столбец с выходными пикселями
                    
                    for x = 1:size(ImCol,2)                             % для каждого столбца
                        K = double(ImCol(:,x,:));                       % считываем по столбцу
                        Ro = zeros(MaskElements);                       % зануляем вектор для рассчета расстояний
                        
                        for y = 1:MaskElements
                            for z = 1:MaskElements
                                if FPM3 ~= 4                           % если порядок фильтра не "бесонечность"
                                    for RGB = 1:size(Image,3)
                                        Ro(y,z) = Ro(y,z) + (abs(K(y,1,RGB) - K(z,1,RGB)))^FPM3;   % считал сумму квадратов расстояний
                                    end
                                    Ro(y,z) = Ro(y,z)^(1/FPM3);        % внес сумму под корень
                                else
                                    Ro(y) = Ro(y) + max(abs(K(y,1,1:size(Image,3)) - K(z,1,1:size(Image,3))));
                                end
                            end
                        end
                        
                        [~,I] = min(sum(Ro,2));     % получаем адрес минимального расстояния
                        Col(x,:,:) = K(I,:,:);      % присваеваем вектору-столбцу новое значение
                    end
                    
                    for RGB = 1:size(Image,3)       % выстраиваем выходное изображение
                        Filtered(:,:,RGB) = Col2Filtered(Col(:,:,RGB),Image(:,:,RGB));
                    end
                    
                    Filtered = uint8(Filtered*255);
                    return;
            end
            
        case 3                  % БИНАРИЗАЦИЯ
            
            switch FPM2
                
                case 1  % пороговая
                    
                    if size(Image,3) > 3            % для многоканальных изображений
                        for ch = 1:size(Image,3)    % обрабатываем каждый канал как полутоновый
                            Filtered(:,:,ch) = im2bw(Image(:,:,ch),alpha/255);
                        end
                    else
                        
                        Filtered(:,:,1) = im2bw(Image,alpha/255);
                        for x = 2:size(Image,3)
                            Filtered(:,:,x) = Filtered(:,:,1);
                        end
                    end
                    
                case 2  % Оцу
                    
                    if size(Image,3) > 3            % для многоканальных изображений
                        for ch = 1:size(Image,3)    % обрабатываем каждый канал как полутоновый                            
                            Filtered(:,:,ch) = im2bw(Image(:,:,ch),graythresh(Image(:,:,ch)));
                        end
                    else                            % для полутоновых и RGB
                        Filtered(:,:,1) = im2bw(Image,graythresh(Image));
                        for x = 2:size(Image,3)
                            Filtered(:,:,x) = Filtered(:,:,1);
                        end
                    end
                    
                case {3,4,5,6,7,8}      % все оконно-адаптивные методы
                    
                    if size(Image,3) == 3           % для RGB
                        Image = rgb2gray(Image);    % получили полутоновое
                    end
                    
                    for ch = 1:size(Image,3)    % обрабатываем каждый канал как полутоновый
                        
                        Im = Image(:,:,ch);
                        ImCol = image2col(Im,MaskSize,'symmetric');   % столбцы-вектора масок
                        Col = ImCol((MaskElements+1)/2,:)';                        
                        
                        switch FPM2
                            
                            case 3      % Брэдли-Рота
                                
                                Mu = mean(ImCol,1)';
                                Col(Col >= Mu*(1+beta)) = 1;
                                Col(Col < Mu*(1+beta)) = 0;
                                
                            case 4      % Ниблэка
                                
                                Mu = mean(ImCol,1)';
                                D = (std(ImCol,1).^2)';
                                T = Mu + D*beta;
                                Col(Col >= T) = 1;
                                Col(Col < T) = 0;
                                
                                
                            case 5      % Кристиана
                                
                                Mu = mean(ImCol,1)';
                                D = (std(ImCol,1).^2)';
                                M = min(Im(:));
                                R = max(D);
                                T = Mu - beta.*(1-D./R).*(Mu-M);
                                Col(Col >= T) = 1;
                                Col(Col < T) = 0;
                                
                            case 6      % Бернсена
                                
                                T = ((max(ImCol,[],1) - min(ImCol,[],1)) / 2)';
                                Col(Col >= T) = 1;
                                Col(Col < T) = 0;
                                
                            case 7      % Саувола
                                
                                Mu = mean(ImCol,1)';
                                D = (std(ImCol,1).^2)';
                                T = Mu.*(1 - beta.*(1-D./gamma));
                                Col(Col >= T) = 1;
                                Col(Col < T) = 0;
                                
                            case 8      % с адаптивным порогом                                
                                
                                T0 = graythresh(Image);     % глобальный порог
                                primitive = strel('arbitrary',ones(delta,eta),alpha/255*ones(delta,eta));   % примитив
                                f0 = imopen(Image,primitive);   % размыкание, которое выдаст фон 
                                
                                Col = ImCol((MaskElements+1)/2,:);
                                
                                f0Cols = image2col(f0,3,'symmetric');
                                f0Col = f0Cols(5,:)+T0;
                                
                                Col(Col >= f0Col) = 1;
                                Col(Col < f0Col) = 0;                        
                        end
                        
                        Filtered(:,:,ch) = Col2Filtered(Col,Im);
                    end
                    
            end          
            
            if size(Image,3) ~= size(Filtered,3)      % если RGB, тогда скопируем каналы
                for x = 2:size(Filtered,3)
                    Filtered(:,:,x) = Filtered(:,:,1);
                end
            end
            
            Filtered = uint8(Filtered*255);
            return;
            
        case 4                  % МОРФОЛОГИЧЕСКАЯ ОБРАБОТКА (Ч/Б)
                                   
            BW_Image = getBW(Image);          % BW - логическое изображение 
            
            % определяем параметры обработки
            if FPM2 < 7               % для дилатации...шляп
                
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
                
            elseif FPM2 > 6 && FPM2 < 10   % со связями
                
                structure = FPM3*4;                
                
            elseif FPM2 == 10    % конечная эрозия
                
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
                
            elseif FPM2 == 11                     % успех/провал
                structure = Mask;
            end
            
            if delta == 0
                delta = inf;        % будем работать до стабилизации
            end
            
            for ch = 1:size(BW_Image,3)            % ДА НАЧНЕТСЯ ЖЕ ОБРАБОТКА
                
                BW_Im = BW_Image(:,:,ch);
                
                if FPM2 < 12      % для фильтров не из bwmorph
                    
                    n = 1;
                    
                    while delta >= n   
                        
                        Im_gauge = BW_Im;
                        
                        switch FPM2
                            case 1              % дилатация
                                BW_Im = imdilate(BW_Im,structure);
                                
                            case 2              % эрозия
                                BW_Im = imerode(BW_Im,structure);
                                
                            case 3              % размыкание
                                BW_Im = imopen(BW_Im,structure);
                                
                            case 4              % замыкание
                                BW_Im = imclose(BW_Im,structure);
                                
                            case 5              % дно шляпы
                                BW_Im = imbothat(BW_Im,structure);
                                
                            case 6              % верх шляпы
                                BW_Im = imtophat(BW_Im,structure);
                                
                            case 7              % заполнение отверстий
                                BW_Im = imfill(BW_Im,structure,'holes');
                                
                            case 8              % очистка границ
                                BW_Im = imclearborder(BW_Im,structure);
                                
                            case 9              % выделение периметра
                                BW_Im = bwperim(BW_Im,structure);
                                
                            case 10              % реконструкция
                                BW_Im = bwulterode(BW_Im,add,structure);
                                
                            case 11              % успех/неудача
                                BW_Im = bwhitmiss(BW_Im,structure);
                        end                        
                        
                        if BW_Im == Im_gauge        % если изображение не изменилось, выходим из цикла
                            break;
                        end
                        
                        n = n + 1;
                        
                    end
                    
                else            % тут bwmorph, который сам обрабаывает до бесконечности
                    
                    switch FPM2
                        case 12              % соединение
                            BW_Im = bwmorph(BW_Im,'bridge',delta);
                            
                        case 13              % очистка изолированных пикселей
                            BW_Im = bwmorph(BW_Im,'clean',delta);
                            
                        case 14              % диагональное заполнение
                            BW_Im = bwmorph(BW_Im,'diag',delta);
                            
                        case 15              % Н-разбиение
                            BW_Im = bwmorph(BW_Im,'hbreak',delta);
                            
                        case 16              % из фона на передний план
                            BW_Im = bwmorph(BW_Im,'majority',delta);
                            
                        case 17              % удаление внутренних пикселей
                            BW_Im = bwmorph(BW_Im,'remove',delta);
                            
                        case 18              % сжатие до точки/кольца
                            BW_Im = bwmorph(BW_Im,'shrink',delta);
                            
                        case 19              % остов
                            BW_Im = bwmorph(BW_Im,'skel',delta);
                            
                        case 20              % удаление отростков
                            BW_Im = bwmorph(BW_Im,'spur',delta);
                            
                        case 21              % утолщение
                            BW_Im = bwmorph(BW_Im,'thicken',delta);
                            
                        case 22              % утончение
                            BW_Im = bwmorph(BW_Im,'thin',delta);
                            
                    end
                end
                
                BW_Image(:,:,ch) = BW_Im;
                
            end
            
            Filtered = uint8(double(BW_Image)*255); % переводим в 256 оттенков
            
            if size(Image,3) ~= size(BW_Image,3)  % если число каналов вх и вых изображений не совпал
                for x = 2:size(Image,3)
                    Filtered(:,:,x) = Filtered(:,:,1);
                end
            end
            
            return;
            
        case 5                  % ПОЛУТОНОВАЯ МОРФОЛОГИЧЕСКАЯ ОБРАБОТКА
            
            if FPM2 < 7               % для дилатации...шляп
               
                structure = strel('arbitrary',Mask,Mask1/255);
                
                % для фильтров со связями
            elseif  (FPM2 > 7 && FPM2 < 10) ||...
                    (FPM2 > 10 && FPM2 < 17)
                
                switch size(Image,3)        % смотрим сколько каналов 
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
                
            elseif FPM2 == 10    % конечная эрозия
                
                if size(Image,3) ~= 3       % для полутонового и мультиканального изображения
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
                    
                    if mod(FPM3,2) == 1            % проверяем четность
                        if size(Image,3) == 1       % для полутонового
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
                    
                else        % для 3-D                    
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
                    
                    if mod(FPM3,2) == 1            % проверяем кратность 3м
                        structure = 6;
                        
                    elseif mod(FPM3,2) == 2
                        structure = 18;
                        
                    elseif mod(FPM3,2) == 0
                        structure = 26;
                        
                    end             
                end
            end
            
            if delta == 0
                delta = inf;        % будем работать до стабилизации
            end
            n = 1;                          % начинаем цикл            
            Grey_Im = Image;   % задали массив
            
            % пока число заданных циклов delta не достигнуто 
            % или изображение не стабилизировалось выполняем цикл
            while delta >= n
                
                Im_gauge = Grey_Im;        % если нет стабилизации, запомнили обработанное
                
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
                
                if Grey_Im == Im_gauge     % сравнили изменения                  
                    break;
                end
                
                n = n + 1;              % увеличиваем счетчик   
                
            end
            
            Filtered = uint8(Grey_Im*255);
            return;
               
        case 6                  % БИЛАТЕРАЛЬНЫЙ ФИЛЬТР   
            
            indent = (MaskSize - 1)/2;                              % граница расширения матрицы
            central = (MaskSize + 1)/2;                             % целевой пиксель маски                                            % граница расширения матрицы
            N = padarray(Image(:,:,CH),[indent indent],IndentType,'both'); % расширили матрицу
            
            switch FPM2
                
                case 1         % БИЛАТЕРАЛЬНЫЙ ФИЛЬТР                    

                    ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);   % столбцы-вектора масок
                    Col = zeros(size(Image,1)*size(Image,2),1);             % вектор-столбец выходных пикселей
                    
                    Beta = SpacialWeightCount(MaskSize);                    % значения пространственных весов в маске
                    [~,BetaWeight] = meshgrid(1:size(ImCol,2),Beta);       % задаем их матрицей, а не строкой
                    [ImColCenters,~] = meshgrid(ImCol((MaskSize^2+1)/2,:),1:size(ImCol,1));
                    
                    AlphaWeight = alpha*255*abs(ImColCenters - ImCol);         % значения яркостных весов
                    Weights = exp(-AlphaWeight - beta*BetaWeight);             % значения пространственных весов
                    Col = sum(Weights.*ImCol,1)./sum(Weights,1);            % итоговые значения
                    
                    Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));
            
                case 2                  % БИЛАТЕРАЛЬНЫЙ ФИЛЬТР (МЕДИАНА)                    

                    ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);   % столбцы-вектора масок
                    Col = zeros(size(Image,1)*size(Image,2),1);             % вектор-столбец выходных пикселей
                    
                    Beta = SpacialWeightCount(MaskSize);                    % значения пространственных весов в маске
                    [~,BetaWeight] = meshgrid(1:size(ImCol,2),Beta);
                    med = sort(ImCol,1);
                    ImCol((MaskSize^2 + 1)/2,:) = med((MaskSize^2 + 1)/2,:);          % центральные пиксели маски равны медиане
                    [ImColCenters,~] = meshgrid(ImCol((MaskSize^2 + 1)/2,:),1:size(ImCol,1));
                    
                    AlphaWeight = (alpha*255)*abs(ImColCenters - ImCol);          % значения яркостных весов
                    Weights = exp(-AlphaWeight - beta*BetaWeight);          % значения конечных весов
                    Col = sum(Weights.*ImCol,1)./sum(Weights,1);    
                    Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));
            
                case 3                    % БИЛАТЕРАЛЬНЫЙ ФИЛЬТР (СРЕДНЕЕ АРИФМЕТИЧЕСКОЕ)
                                         
                    ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);   % столбцы-вектора масок
                    Col = zeros(size(Image,1)*size(Image,2),1);             % вектор-столбец выходных пикселей
                    
                    Beta = SpacialWeightCount(MaskSize);                    % значения пространственных весов в маске
                    [~,BetaWeight] = meshgrid(1:size(ImCol,2),Beta);
                    ImCol((MaskSize^2 + 1)/2,:) = sum(ImCol,1)./MaskElements;          % центральные пиксели маски равны медиане
                    [ImColCenters,~] = meshgrid(ImCol((MaskSize^2 + 1)/2,:),1:size(ImCol,1));
                    
                    AlphaWeight = (alpha*255)*abs(ImColCenters - ImCol);          % значения яркостных весов
                    Weights = exp(-AlphaWeight - beta*BetaWeight);          % значения конечных весов
                    Col = sum(Weights.*ImCol,1)./sum(Weights,1);    
                    Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));
                    
                case 4                        % БИЛАТЕРАЛЬНЫЙ ФИЛЬТР (МИНИМАЛЬНОЙ РАЗНОСТИ)
                    
                    for j = 1:size(Image,1)                                 % для каждого столбца
                        for i = 1:size(Image,2)                             % для каждой строки
                            w = zeros(MaskSize);                            % пустая матрица коэффициентов 3х3
                            S = N(j:j+MaskSize-1,i:i+MaskSize-1);           % считываем матрицу 3х3
                            
                            str = double(sort(S(:)));                       % берем минимальную разность
                            Ro = zeros(MaskElements,1);                     % зануляем столбец для рассчета расстояний
                            
                            for y = 1:MaskElements
                                Ro(y) = abs(str(y)*MaskElements - sum(str(:))); % нашли суммы расстояний
                            end

                            [~,I] = min(Ro);                            % получаем адрес минимального расстояния                             
                            S(central,central) = str(I);                % присваеваем вектору-столбцу новое значение                            
                            
                            for l = 1:MaskSize                              % для каждого столбца ядра фильтра
                                for k = 1:MaskSize                          % для каждой строки ядра фильтра вычисляем коэффициент
                                    w(l,k) = exp(-alpha*255*abs(S(central,central)-S(l,k)) - beta*(abs(central-k)+abs(central-l)));
                                end
                            end
                            
                            S = S.*w;       % перемножаем коэффициенты поэлементно со значениями яркостей
                            Filtered(j,i,CH) = sum(S(:))/sum(w(:));    % возвращаем отфильтрованное значение 
                        end
                    end
                    
                    
                case 5                  % БИЛАТЕРАЛЬНЫЙ ФИЛЬТР (АДАПТИВНЫЙ)
                    
                    leftLim = (MaskElements-1)/2;                           % границы расширения матрицы
                    rightLim = (MaskElements+3)/2;
                                       
                    for j = 1:size(Image,1)                                 % для каждого столбца                        
                        for i = 1:size(Image,2)                             % для каждой строки
                            
                            w = zeros(MaskSize);                            % пустая матрица коэффициентов
                            S = N(j:j+MaskSize-1,i:i+MaskSize-1);           % считываем матрицу
                            
                            str = round(255*sort(S(:),'ascend'));           % сортируем элементы маски
                            
                            if str(rightLim) - str(leftLim) ~= 0
                                Intermediate = str(leftLim):str(rightLim);  % строим ряд значений
                                
                                Ro = zeros(size(Intermediate));
                                for y = 1:size(Intermediate,1)
                                    Ro(y) = abs(Intermediate(y)*size(Intermediate,1) - sum(Intermediate(:)));
                                end
                                
                                [~,I] = min(Ro);                            % получаем адрес минимального расстояния
                                S(central,central) = Intermediate(I)/255;       % присваеваем вектору-столбцу новое значение
                            end
                            
                            for l = 1:MaskSize                              % для каждого столбца ядра фильтра
                                for k = 1:MaskSize                          % для каждой строки ядра фильтра вычисляем коэффициент
                                    w(l,k) = exp(-alpha*255*abs(S(central,central)-S(l,k)) -  beta*(abs(central-k)+abs(central-l)));
                                end
                            end
                            
                            S = S.*w;       % перемножаем коэффициенты поэлементно со значениями яркостей
                            Filtered(j,i,CH) = sum(S(:))/sum(w(:));    % возвращаем отфильтрованное значение 
                        end
                    end                    
                    
                case 6                  % БИЛАТЕРАЛЬНЫЙ ФИЛЬТР (N-МЕРНЫЙ)
                    
                    central = (MaskSize + 1)/2;
                    
                    for RGB = 1:size(Image,3)
                        ImCol(:,:,RGB) = image2col(Image(:,:,RGB),MaskSize,IndentType);
                    end
                    
                    Col = zeros(size(Image,1)*size(Image,2),1,size(Image,3));                % RGB-мерный вектор-столбец
                    
                    for x = 1:size(ImCol,2)                     % для каждого столбца
                        w = zeros(MaskSize^2,1);                    % обнуляем матрицу коэффициентов 3х3
                        S = ImCol(:,x,:);                       % считываем матрицу в форме вектора столбца в RGB каналах
                        Ro = zeros(MaskElements);               % зануляем вектор для рассчета расстояний
                        
                        if FPM3 ~= 4                           % если не бесконечный порядок фильтра выбран
                            for y = 1:MaskElements
                                for z = 1:MaskElements
                                    for RGB = 1:size(Image,3)
                                        Ro(y,z) = Ro(y,z) + (abs(S(y,1,RGB) - S(z,1,RGB)))^FPM3;
                                    end
                                    Ro(y,z) = Ro(y,z)^(1/FPM3);    % ((х-х)^p+(y-y)^p+(z-z)^p)^(1/p)
                                end
                            end
                        else                                        % выбрали все-таки бесконечный...
                            for y = 1:MaskElements
                                for z = 1:MaskElements
                                    Ro(y) = Ro(y) + max(abs(S(y,1,1:size(Image,3)) - S(z,1,1:size(Image,3))));
                                end
                            end
                        end
                        
                        [~,I] = min(sum(Ro,2));                         % получаем адрес минимального расстояния
                        S(central,1,:) = S(I,1,:);              % присваиваем как центральный пиксель
                        
                        %%%%%%%%%%%%%%%%%%% выбор коэффициентов маски фильтра %%%%%%%%%
                        
                        for l = 1:MaskElements                  % для каждого столбца ядра фильтра
                            w(l) = exp(-alpha*255*(Ro(I,l)));       % вычисляем коэффициент
                        end
                        
                        w_beta = zeros(size(w));
                        p = 1;
                        for l = 1:MaskSize                              % для каждого столбца ядра фильтра
                            for k = 1:MaskSize                          % для каждой строки ядра фильтра
                                w_beta(p) = exp(-beta*(abs(I-k)+abs(I-l)));    % вычисляем коэффициент
                                p = p + 1;
                            end
                        end
                        
                        for RGB = 1:size(Image,3)            % для каждого канала
                            summ = zeros(1);
                            S(:,:,RGB) = S(:,:,RGB).*w.*w_beta;       % перемножаем коэффициенты поэлементно со значениями яркостей
                            
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
            
        case 7                  % СЛЕПАЯ ОБРАТНАЯ СВЕРТКА
            
            % получили матрицу PSF и обработанное без очитки изображение
            [PreFiltered, PSF] = deconvblind(Image,ones(alpha,beta),gamma,delta);
            if FPM2 == 2       % если надо делать очистку 
                
                Filtered = edgetaper(Image,PSF);        % проводим ее с полученной PSF
                
                % очищенное изображение подвергаем обратной свертке по
                % методу Люси-Ричардсона
                Filtered = deconvlucy(Filtered,PSF,gamma,delta);
                
            else                
                Filtered = PreFiltered; 
            end            
            
            Filtered = uint8(Filtered*255);
            return;
            
        case 8                  % ФИЛЬТР ГАБОРА
            
            [x,y] = meshgrid(-fix(MaskSize/2):fix(MaskSize/2),-fix(MaskSize/2):fix(MaskSize/2));
            
            % Поворот
            x_theta = x*cos(epsilon) + y*sin(epsilon);
            y_theta = -x*sin(epsilon) + y*cos(epsilon);
            
            filtemask = exp(-0.5*(x_theta.^2/alpha^2 + y_theta.^2/beta^2))*cos(2*pi*x_theta./gamma + delta);
            Filtered(:,:,CH) = imfilter(Image(:,:,CH),filtemask,IndentType);
            
            
        case 9                  % ПРЕОБРАЗОВАНИЕ ХАФА
            
            BW = getBW(Image);          % BW - логическое изображение 
                            
            for ch = 1:size(BW,3)
                [H,Theta,Rho] = hough(BW(:,:,ch),'RhoResolution',gamma,'Theta',alpha:FPM2:beta);
                Threshold = max(H(:))*FPM3/100;
                peaks = houghpeaks(H,theta,'Threshold',Threshold,'NHoodSize',[delta eta]);
                lines = houghlines(BW(:,:,ch),Theta,Rho,peaks,'FillGap',zeta,'MinLength',epsilon);
                
                for x = 1:length(lines)
                    
                    xi = lines(x).point1(1):lines(x).point2(1);     % область значений
                    X = [lines(x).point1(1) lines(x).point2(1)];    % координты точек
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
                
                if FPM1 == 2      % если нужно вывести STM
                    
                    try
                        imtool(H/max(H(:)));
                    catch
                        OpenImageOutside(H/max(H(:)));
                    end
                end
            end
            
            Filtered = uint8(Filtered*255); % переводим в 256 оттенков
            
            if size(Image,3) ~= size(BW,3)  % если число каналов вх и вых изображений не совпал
                for x = 2:size(Image,3)
                    Filtered(:,:,x) = Filtered(:,:,1);
                end
            end
            
            return;
            
            
        case 10                 % ДЕКОРРЕЛЯЦИОННОЕ РАСТЯЖЕНИЕ
            
            % формируем массивы индексов
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
                
                case 1          % без контрастирования
                   Filtered = decorrstretch(Image,'SampleSubs',{row, col}); 
                    
                case 2          % с контрастированием
                   Filtered = decorrstretch(Image,'SampleSubs',{row, col},'Tol',[epsilon/255 zeta/255]);                    
            end
            
            Filtered = uint8(Filtered*256);
            return;
            
            
        case 11                 % ПРОИЗВОЛЬНЫЙ ФИЛЬТР        
            
            Filtered(:,:,CH) = imfilter(Image(:,:,CH),Mask,IndentType);            
            
            if FPM2 == 2          % с вычитанием                
                Filtered(:,:,CH) = Image(:,:,CH) - Filtered(:,:,CH);
            end            
            
            
        case 12                 % ФИЛЬТР ВИННЕРА
            
            Filtered(:,:,CH) = wiener2(Image(:,:,CH),[alpha beta]);
            
        case 13                  % НИЗКИХ ЧАСТОТ ГАУССА   
                        
            filtemask = fspecial('gaussian',MaskSize,alpha);
            Filtered(:,:,CH) = imfilter(Image(:,:,CH),filtemask,IndentType); 
            
        case 14                  % УСРЕДНЯЮЩИЙ ФИЛЬТР
            
            switch FPM2
                case 1              % ср. арифмет
                    filtemask = fspecial('average',MaskSize);  
                    Filtered(:,:,CH) = imfilter(Image(:,:,CH),filtemask,IndentType);
                    
                case 2              % ср. геометрич
                    Filtered(:,:,CH) = exp(imfilter(log(Image(:,:,CH)),ones(MaskSize),IndentType)).^(1/MaskSize/MaskSize);                    
                    
                case 3              % гармон. ср
                    Filtered(:,:,CH) = MaskSize^2 ./ imfilter(1./(Image(:,:,CH)+eps),ones(MaskSize),IndentType);
                    
                case 4              % контр. гармониче. ср.
                    Filtered(:,:,CH) = imfilter(Image(:,:,CH).^(alpha+1),ones(MaskSize),IndentType);
                    Filtered(:,:,CH) = Filtered(:,:,CH) ./ (imfilter(Image(:,:,CH).^(alpha),ones(MaskSize),IndentType)+eps);
                        
                case 5              % максимум
                    Filtered(:,:,CH) = ordfilt2(Image(:,:,CH),MaskSize^2,ones(MaskSize),IndentType);
                    
                case 6              % минимум
                    Filtered(:,:,CH) = ordfilt2(Image(:,:,CH),1,ones(MaskSize),IndentType);
                    
                case 7              % средняя точка
                    F1 = ordfilt2(Image(:,:,CH),MaskSize^2,ones(MaskSize),IndentType);
                    F2 = ordfilt2(Image(:,:,CH),1,ones(MaskSize),IndentType);
                    Filtered(:,:,CH) = imlincomb(0.5,F1,0.5,F2);                    
                    
                case 8              % среднее усеченное
                    Filtered(:,:,CH) = imfilter(Image(:,:,CH),ones(MaskSize),IndentType);
                    for k = 1:alpha/2
                        Filtered(:,:,CH) = imsubtract(Filtered(:,:,CH),ordfilt2(Image(:,:,CH),k,ones(MaskSize),IndentType));
                    end
                    
                    for k = (MaskSize^2 - (alpha/2) + 1):MaskSize^2
                        Filtered(:,:,CH) = imsubtract(Filtered(:,:,CH),ordfilt2(Image(:,:,CH),k,ones(MaskSize),IndentType));                        
                    end
                    
                    Filtered(:,:,CH) = Filtered(:,:,CH) / (MaskSize^2 - alpha);    
            end
            
            
        case 15                  % СОБЕЛЯ
            
            if alpha == 0       % если 0, тогда нужен автоматический выбор порога
                alpha = [];
            else
                alpha = alpha/255;
            end
            
            switch FPM3        % по выбору пользователя выбираем режим
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
            
        case 16                  % КЕННИ
            
            if alpha == 0  || beta == 256     % если 0, тогда нужен автоматический выбор порога
                thresh = [];
            else
                thresh = [alpha/255 beta/255];
            end
            
            Filtered(:,:,CH) = edge(Image(:,:,CH),'canny',thresh,gamma);           
            
            
        case 17                  % ПРЕВИТТА
            
            if alpha == 0       % если 0, тогда нужен автоматический выбор порога
                alpha = [];
            else
                alpha = alpha/255;
            end
            
            switch FPM3        % по выбору пользователя выбираем режим
                case 1
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'prewitt',alpha,'horizontal');
                case 2
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'prewitt',alpha,'horizontal');
                case 3
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'prewitt',alpha,'vertical');
            end
            
        case 18                  % РОБЕРТСА
            
            if alpha == 0       % если 0, тогда нужен автоматический выбор порога
                alpha = [];
            else
                alpha = alpha/255;
            end
            
            switch FPM3        % по выбору пользователя выбираем режим
                case 1
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'sobel',alpha,'thinning');
                case 2
                    Filtered(:,:,CH) = edge(Image(:,:,CH),'sobel',alpha,'nothinning');
            end
            
        case 19                  % ДИСКОВЫЙ    
            
            filtemask = fspecial('disk', 0.5*(MaskSize-1));
            Filtered(:,:,CH) = imfilter(Image(:,:,CH),filtemask,IndentType); 
            
        case 20                  % ВЫСОКИХ ЧАСТОТ ЛАПЛАСА  
            
            filtemask = fspecial('laplacian',alpha);
            Filtered(:,:,CH) = Image(:,:,CH) - imfilter(Image(:,:,CH),filtemask,IndentType); 
            
        case 21                  % ПОВЫШЕНИЯ РЕЗКОСТИ 
            
            filtemask = fspecial('unsharp',alpha);
            Filtered(:,:,CH) = imfilter(Image(:,:,CH),filtemask,IndentType); 
            
        case 22                  % ГАУССА + ЛАПЛАСА
            
            filtemask = fspecial('log',MaskSize,alpha);
            Filtered(:,:,CH) = Image(:,:,CH) - imfilter(Image(:,:,CH),filtemask,IndentType); 
            
                                % фильтр взят из книги Гонсалеса, Вуддса
        case 23                  % АДАПТИВНЫЙ МЕДИАННЫЙ             
            
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
        
        
        case 24     % ГАММА-ФИЛЬТР
            
            ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);             % столбцы-вектора масок
            Col = zeros(size(Image,1)*size(Image,2),1);           % вектор-столбец выходных пикселей 
            
            Pc = ImCol((MaskSize^2 + 1)/2,:);       % значение центрального пиксела
            Lm = mean(ImCol,1);                     % средняя яркость маски      
            SD = std(ImCol,1);              % CКО маски
            
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
            
        % ссылка на ресурс с фильтрами: 
        % http://desktop.arcgis.com/ru/arcmap/10.3/manage-data/raster-and-images/speckle-function.htm
        % http://www.pcigeomatics.com/geomatica-help/concepts/orthoengine_c/chapter_823.html
        % http://www.pcigeomatics.com/geomatica-help/concepts/orthoengine_c/chapter_824.html
        % http://www.pcigeomatics.com/geomatica-help/concepts/orthoengine_c/chapter_822.html
        case 25                 % ФИЛЬТР ЛИ      
            
            ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);             % столбцы-вектора масок
            Col = zeros(size(Image,1)*size(Image,2),1);           % вектор-столбец выходных пикселей 
            
            Pc = ImCol((MaskSize^2 + 1)/2,:);       % значение центрального пиксела
            Lv = std(ImCol,1).^2;                   % локальная дисперсия
            Lm = mean(ImCol,1);                     % средняя яркость маски
            
            switch FPM2                
                case 1      % оригинальный фильтр   
                    
                    AV = alpha/255;                 % переведенная на интервал 0...1 дисперсия
                    A = beta/255;                   % среднее значение
                    Mv = gamma/255;
                    M = delta/255;                            
                    
                    switch FPM3                        
                        case 1      % аддитивная модель                            
                            
                            K = Lv./(Lv + AV);
                            Col = Lm + K.*(Pc - Lm); 
                            
                        case 2      % мультипликативная модель
                            
                            K = M.*Lv ./ ( (Lm.^2.*Mv) + (M.^2.*Lv));
                            Col = Lm + K.*(Pc - M.*Lm);   
                            
                        case 3      % адд. + мультип.
                            
                            K = M.*Lv ./ ( (Lm.^2.*Mv) + (M.^2.*Lv) + AV);
                            Col = Lm + K.*(Pc - M.*Lm - A);                           
                            
                    end
                    
                case 2      % улучшенный фильтр
                    
                    D = zeta;                       % коэффициент затухания
                    Cu = 1 / epsilon^0.5;           % число выборок
                    Cmax = (1 + 2/epsilon)^0.5;     % максиамльный коэффициент дисперсии помех
                    SD = std(ImCol,1);              % CКО маски
                    Ci = SD./Lm;                    % коэфициент дисперсии изоражения
                    
                    Col(Ci <= Cu) = Lm(Ci <= Cu);
                    Col(Ci >= Cmax) = Pc(Ci >= Cmax);                   
                    
                    K(Ci > Cu & Ci < Cmax) = exp( -D.*(Ci(Ci > Cu & Ci < Cmax) - Cu) ./ (Cmax - Ci(Ci > Cu & Ci < Cmax)) );
                    
                    Col(Ci > Cu & Ci < Cmax) =  Lm(Ci > Cu & Ci < Cmax) .* ...
                                                K(Ci > Cu & Ci < Cmax) + Pc(Ci > Cu & Ci < Cmax) ...
                                                .* (1 - K(Ci > Cu & Ci < Cmax)); 
                    
            end
            
            Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));
            
        case 26                 % ФИЛЬТР ФРОСТА
            
            ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);             % столбцы-вектора масок
            Col = zeros(size(Image,1)*size(Image,2),1);           % вектор-столбец выходных пикселей 
            
            Lm = mean(ImCol,1);                     % средняя яркость маски
            SWC = SpacialWeightCount(MaskSize);     % значения пространственных весов в маске
            
            switch FPM2                
                case 1      % оригинальный фильтр 
                    
                    Lv = std(ImCol,1).^2;                   % локальная дисперсия
                    B = alpha .* (Lv ./ Lm.^2);
                    K = exp(-SWC*B);
                    Col = sum((ImCol .* K ),1)./sum(K,1);
                
                case 2      % улучшенный фильтр
                
                    Pc = ImCol((MaskSize^2 + 1)/2,:);       % значение центрального пиксела
                    SD = std(ImCol,1);              % CКО маски
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
            
        case 27             % ФИЛЬТР КУАНА
            
            ImCol = image2col(Image(:,:,CH),MaskSize,IndentType);             % столбцы-вектора масок
            Col = zeros(size(Image,1)*size(Image,2),1);           % вектор-столбец выходных пикселей 
            
            Pc = ImCol((MaskSize^2 + 1)/2,:);       % значение центрального пиксела
            Lm = mean(ImCol,1);                     % средняя яркость маски                      
            SD = std(ImCol,1);              % CКО маски
                    
            Cu = 1/(alpha)^0.5;
            Ci = SD./Lm;
            
            K = (1 - (Cu ./ Ci)) / (1 + Cu);
            Col = Pc.*K + Lm.*(1 - K);
                        
            Filtered(:,:,CH) = Col2Filtered(Col,Image(:,:,CH));
            
        case 28             % ФИЛЬТР ЛОКАЛЬНОЙ СТАТИСТИКИ
            
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
            
        case 29             % ПОРОГОВЫЙ ФИЛЬТР    
            
           if FPM2 == 2     % HSV
                Image = rgb2hsv(Image);
           end               
           
           WorkChannel = Image(:,:,beta);
           
           switch FPM3
               case 1       % пропускание
                   WorkChannel(delta/255 <= WorkChannel | WorkChannel >= eta/255) = alpha/255;
               case 2       % подавление
                   WorkChannel(delta/255 >= WorkChannel | WorkChannel <= eta/255) = alpha/255;                   
           end
           
           Image(:,:,beta) = WorkChannel;
           
           if FPM3 == 2     % HSV
               Image = hsv2rgb(Image);
           end
           
           Filtered = Image;
           Filtered = uint8(Filtered*255);
           return;
           
            
        case 30         % ГРАДИЕНТ
            
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
                
        case 31         % ЭВАЛИЗАЦИЯ ГИСТОГРАММЫ
            
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
           
        case 32         % КВАНТОВАНИЕ
                                
            quants = zeros(1,2^alpha-1);            
            x = 0:0.001:1;
            graph = (2^alpha-1)*(x.^beta);  % вычислили кривую нелинейного квантования
            y = 1;                          % первый уровень
            quants(1,1) = 0;                % нулевое значение
            
            for z = 1:size(x,2)
                if graph(z) > y             % если превысили текущий уровень
                    quants(1,y+1) = x(z);        % запоминаем значение,
                    y = y + 1;              % с которого начинаем записывать в следующий квант
                end
            end
            
            % формируем вектор значений для каждого кванта
            levels = 0:1/(2^alpha-1):1;
            
            % по столбцам изменяем значения            
            for x = 1:size(Image,1)
                [~,Filtered(x,:,CH)] = quantiz(Image(x,:,CH),quants,levels);
            end            
            
        case 33         % КОНТРАСТИРОВАНИЕ С ГАММА-КОРРЕКЦИЕЙ
            
            Filtered(:,:,CH) = imadjust(Image(:,:,CH),[beta/255 gamma/255],[delta/255 epsilon/255],alpha);
            
        case 34         % ДЕТЕКТОР ОКРУЖНОСТЕЙ
            
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
            
            switch size(Image,3)        % смотрим сколько каналов   
                
                case 3                  % триколор
                     
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
                    
                otherwise               % мультиканальные                    
                    
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
            
        case 35     % ДЕТЕКТОР КЛЮЧЕВЫХ ТОЧЕК/УГЛОВ
            
            % переводим в полутоновки
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
            
            coords = double(round(points.Location));    % координаты ключточек
            init_coords = coords;                       % делаем копию
            M = size(coords,1);
            i = 1;
            
            for x = -2:2        % смещение для крестика
                coords(i*M+1:i*M+M,:) = [init_coords(:,1)+x init_coords(:,2)-x];
                i = i + 1;
            end
            
            for x = 2:-1:-2        % смещение для крестика
                coords(i*M+1:i*M+M,:) = [init_coords(:,1)+x init_coords(:,2)+x];
                i = i + 1;
            end
            
            % если есть выход за пределы изображения - делаем предельным
            coords(coords(:,1) > size(Image,2)) = size(Image,2);
            coords(coords(:,2) > size(Image,1)) = size(Image,1);
            
            coords(end+1,1) = size(Image,2);             % добавляем правую нижнюю
            coords(end,2) = size(Image,1);               % точку для разреж. матрицы 
            
            % превращаем координаты из разреж матрицы в лог матрицу   
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
    

% ФУНКЦИЯ СОЗДАНИЯ ВЕКТОРОВ МАСОК
function ImCol = image2col(Image,MaskSize,IndentType)
% подобна im2col
% ImCol - выходной массив, где каждый столбец - элементы маски целевого пикселя
%   Движение по изображению
% 
% | 1 | 2 | 3 |   |       |   | 1 | 2 | 3 |  
% | 4 | 5 | 6 |   |   ->  |   | 4 | 5 | 6 |
% | 7 | 8 | 9 |   |       |   | 7 | 8 | 9 |
% |   |   |   |   |       |   |   |   |   |

% Image - входное изображение, только с одним каналом
% MaskSize - размер маски: "3" - 3х3, "5" - 5х5, "7" - 7х7, "9" - 9х9

indent = (MaskSize - 1)/2;                                  % граница расширения матрицы
N = padarray(Image,[indent indent],IndentType,'both');      % расширили матрицу
ImCol = zeros(MaskSize^2,size(Image,1)*size(Image,2));      % задали размер матрицы с векторами масок
z = 1;        

for j = indent+1 : size(N,1) - indent               % в пределах обработки находится 
    for i = indent+1 : size(N,2) - indent           % только исходное изображение                
        V = N(-indent+j:j+indent,-indent+i:i+indent);   % считываем маску
        ImCol(:,z) = V(:);            % вставляем в массив элементы маски
        z = z + 1;
    end
end


% ФУНКЦИЯ ФОРМИРОВАНИЯ ВЫХОДНОГО ИЗОБРАЖЕНИЯ ИЗ ВЕКТОРА-СТОЛБЦА
function Filtered = Col2Filtered(Col,Image)
% Filtered - выходное изображение, размер которого равен размеру Image
% Col - вектор столбец
% Image - входное изображение 

k = 1;
Filtered = zeros(size(Image));

for y = 1:size(Image,1)
    for x = 1:size(Image,2)
        Filtered (y,x) = Col(k);         % попиксельно раскладываем отфильтрованное
        k = k + 1;                       % изображение в исходный размер
    end
end


% ФУНКЦИЯ ОЦЕНКИ ОРИГИНАЛА И ОБРАБОТАННОГО ИЗОБРАЖЕНИЯ
function Assessment = GetAssessment(Orig_Im,Im,SSIM)

% Orig_Im - исходное изображение
% Im - НАБОР преобразованных изображений
% Assessment - структура с параметрами оценки
% если SSIM == 0 - его не нужно считать совсем
% если SSIM == 1 - нужно для 2D изображения в анализаторе
% если SSIM == 2 - считаем всё

assert( size(Im,1) == size(Orig_Im,1) &&...
        size(Im,2) == size(Orig_Im,2) &&...
        size(Im,3) == size(Orig_Im,3),...
        'Размерности изображений для сравнения не равны');
assert(~isempty( Orig_Im < 0) ,'Первый массив не является изображением (есть отриц. элементы)');
assert(~isempty( Im < 0) ,'Второй массив не является изображением (есть отриц. элементы)');

Orig_Im = double(Orig_Im);          % переводим в дубль-формат, иначе ошибки вычислений будут
Im = double(Im);

% структура оценки: поля с (RGB+1) x N_изобр. величинами оценок для каждого из изорбражений; 
%  MAE,NAE,MSE,NMSE,SNR,PSNR,SSIM:
% |                     | chan sum  | 1-st chan | ...   | N-th chan     
% |     (1-st image)    | 0.25      | 0.11      |       | 0.33  
% |     (2-st image)    | 0.5       | 0.13      |       | 0.33  
% | 	(3-st image)    | 0.2       | 0.14      |       | 0.33  
% |     (4-st image)    | 0.245     | 0.15      |       | 0.33
% 
% SSIM_Image: изображение размерностью с оригинал

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
                
Square = size(Im,1)*size(Im,2);         % длина х ширина = площадь

% задали размеры массивов
AE = zeros(size(Im,3),1);         % средняя абсолютная ошибка
SE = zeros(size(Im,3),1);         % средняя квадратичная ошибка
MAE = zeros(size(Im,3),1);         % средняя абсолютная ошибка
MSE = zeros(size(Im,3),1);         % средняя квадратичная ошибка
NAE = zeros(size(Im,3),1);         % нормированная абсолютная ошибка
NMSE = zeros(size(Im,3),1);        % нормированная среднеквадратическая ошибка
SNR = zeros(size(Im,3),1);         % отношение сигнал/шум
PSNR = zeros(size(Im,3),1);        % пиковое отношение сигнал/шум

ORIG_SQR = zeros(size(Im,3),1);     % сумма квадратов всех значений яркости изображения
ORIG_SUM = zeros(size(Im,3),1);     % сумма всех значений яркости изображения

for X = 1:size(Im,4)        % для всех отфильтрованных/зашумленных изображений  
    for RGB = 1:size(Im,3)      
        
        A = Orig_Im(:,:,RGB);           % превращаем изображения в векторы-столбцы
        B = Im(:,:,RGB,X);              % для увеличения скорости расчета
        A = A(:);
        B = B(:);
        
        SE(RGB) = sum( (A - B).^2 );   % сумма квадратических ошибок
        AE(RGB) = sum( abs(A - B) );   % сумма абсолютных ошибок
        ORIG_SQR(RGB) = sum( A.^2 );   % сумма квадратов значений исх. изоб-я
        ORIG_SUM(RGB) = sum(A);        % сумма значений исх. изоб-я

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
    
    if SSIM == 1         % если вызвал анализатор, то выходим
        return;
    end
    
    Assessment(X).MAE(1) = sum(MAE)/size(Im,3);      % заполняем структуру оценками
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


% ФУНКЦИЯ РАСЧЕТ ИНВАРИАНТНЫХ МОМЕНТОВ
function phi = invmoments(F)
    
if ( ~ismatrix(F) || issparse(F) || ~isreal(F) || ~(isnumeric(F)) || islogical(F) )
    error('Изображение не подходит!');
end

F = double(F);
phi = compute_phi(compute_eta(compute_m(F)));


% ПОДФУНКЦИЯ ДЛЯ РАСЧЕТА ИНВАРИАНТНЫХ МОМЕНТОВ
function m = compute_m(F)
    
[M, N] = size(F);
[x, y] = meshgrid(1:N,1:M);

x = x(:);
y = y(:);
F = F(:);

m.m00 = sum(F);

if (m.m00 == 0)     % защита от деления на ноль
    m.m00 = eps;
end

% центральные моменты
m.m10 = sum(x .* F);
m.m01 = sum(y .* F);
m.m11 = sum(x .* y .* F);
m.m20 = sum(x.^2 .* F);
m.m02 = sum(y.^2 .* F);
m.m30 = sum(x.^3 .* F);
m.m03 = sum(y.^3 .* F);
m.m12 = sum(x .* y.^2 .*F);
m.m21 = sum(x.^2 .* y .* F);


% ПОДФУНКЦИЯ ДЛЯ РАСЧЕТА ИНВАРИАНТНЫХ МОМЕНТОВ
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


% ПОДФУНКЦИЯ ДЛЯ РАСЧЕТА ИНВАРИАНТНЫХ МОМЕНТОВ
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
    

% ФУНКЦИЯ СОЗДАЕТ СТРОКУ, СОСТОЯЩУЮ ИЗ "number" СТРОК
function NumbersOfImages = createSTR (number,ImageOrNot)

NumbersOfImages = cell(1,number);

for k = 1:number
    
    if ImageOrNot == 1
        NumbersOfImages{k} = ['Изображение № ' num2str(k)];
    else
        NumbersOfImages{k} = ['Канал № ' num2str(k)];
    end
        
end


% ФУНКЦИЯ КОПИРУЕТ ИЗОБРАЖЕНИЕ В БУФЕР
function ClipboardCopyImage(Image)
    
    % если 1920х1080 то окно все равно не может быть больше разрешения,
    % будет кромка 22 пикселя сверху (снизу и по бокам хз)

res = get(0, 'ScreenSize');         % считываем разрешение экрана
w = size(Image,2);                  % ширину картинки
h = size(Image,1);                  % и ее высоту
res(4) = res(4) - 22;           % срезали кромку
M = w/res(3);                   % узнали, насколько экран длиннее изображения
N = h/res(4);                   % узнали, насколько экран шире изображения

if floor(M) == 0 && floor(N) == 0     % экран длиннее и шире картинки
    new_w = w;
    new_h = h;
    
else    % когда хоть одна из сторон или обе больше, чем сторона экрана
        % смотрим, кто больше, и подгоняем под нее
        
    if M > N               % ширина больше или равна  
        new_h = round(h/(w/res(3)));   %     
        new_w = res(3);
        
    elseif N > M            % если это ширина
        new_h = res(4);
        new_w = round(w/(h/res(4)));   %   
      
    elseif N == M 
        new_w = w;
        new_h = h;        
    end
end

% обязательно убираем все меню
H = figure('Position',[1 1 new_w new_h],'Menubar','none','Toolbar','none','Visible','off');
H_axes = axes('Position',[0 0 1 1]);     % ось на все окно
imshow(Image,'Border','tight','Parent',H_axes);
hgexport(H,'-clipboard');  
close(H);


% ФУНКЦИЯ КОПИРУЕТ ОБЪЕКТ В БУФЕР КАК ИЗОБРАЖЕНИЕ
function ClipboardCopyObject(ObjHandle,X_indent)

% создаем фигуру
ObjPos = get(ObjHandle,'Position');

switch get(ObjHandle,'type')
    
    case 'axes'         % для осей надо добавить отступы снизу и слева под подписи
                 
        ObjPos(1) = 50 + X_indent;
        ObjPos(2) = 50; 
        FigPos(3) = ObjPos(3) + 80 + X_indent;
        FigPos(4) = ObjPos(4) + 100;
        
    case 'uicontrol'    % если элементы управления
        
        switch  get(ObjHandle,'style')
            case 'listbox'  % и список
                
                str = get(ObjHandle,'String');
                Width = length(str{1});         % начинаем искать максимум ширины
                
                for x = 1:size(str,1)
                    if length(str{x}) > Width
                        Width = length(str{x});
                    end
                end
                
                ObjPos(4) = 16 * size(str,1);    % вычисляем нужные высоту/ширину
                ObjPos(3) = 8 * Width;
                
                FigPos(1) = 1;      % задаем позицию окна
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
                
                hgexport(H,'-clipboard');                     % копируем фигуру в буфер
                close(H);
                
                return;
                
        end 
        
    case 'uitable'       % для таблиц
        
        ObjPos(1) = 1;
        ObjPos(2) = 1;    
        FigPos = ObjPos;
end

% окно задаю видимым, иначе система не скопирует его !!!!
H = figure('Visible','on','Position',[50 50 FigPos(3) FigPos(4)],'Menubar','none','Toolbar','none');  

Object = copyobj(ObjHandle,H);            % копируем объект в новое окно

set(Object,'Position',ObjPos)  % задаем место установки осей в новом окне
hgexport(H,'-clipboard');                     % копируем фигуру в буфер
close(H);


% ФУНКЦИЯ СОХРАНЯЕТ ОБЪЕКТ
function SaveObjectAsImage(ObjHandle,FileName)
    
switch get(ObjHandle,'type')    % от типа копируемого в окно объекта выставляем размеры
    
    case 'axes'                 % для осей 
        
        H = figure('Visible','off','Position',[0 0 500 300]);    % создаем окно, которое сохраним как картинку
        
        set(H,  'PaperUnits','points',...               % выставляем единицы изм фигуры
                'PaperPosition',[0 0 500 300]);         % задаем позицию на печати
            
        ObjPosition = [50 20 430 250];
        
    case 'uitable'              % для таблиц 
        
        ObjPosition = get(ObjHandle,'Position');        % размер объекта
        ObjPosition (1) = 1;
        ObjPosition (2) = 1; 
        
        % создаем окно, которое сохраним как картинку
        H = figure('Visible','on','Position',ObjPosition);    

        set(H,  'PaperUnits','points',...                           % выставляем единицы изм фигуры
                'PaperPosition',[0 0 ObjPosition(3)*0.75 ObjPosition(4)*0.75]);   % задаем позицию на печати       
end

Obj = copyobj(ObjHandle,H); 
set(Obj,'Position',ObjPosition);        % меняем позицию осей с графиком

saveas(H,FileName);            % сохраняем как картинку
close(H);    
    

% ФУНКЦИЯ ВЫЧИСЛЕНИЯ РАЗРЕШАЮЩЕЙ СПОСОБНОСТИ ТОЧКИ
function Value = PointResolution(row,point,ResLevel)
    
assert(point < length(row) || point >= 1,...
    ['Точка (point = ' num2str(point) ') не пренадлежит строке row']);
assert(isnumeric(row),'row задан не числами');
assert(isnumeric([point ResLevel]),'point и ResLevel - не числа');

Value = 0;                          % изначально РС = 0

% если  начали с краевой точки или соседи больше
if  point == 1 ||...        
    point == length(row) ||...
    row(point) <= row(point-1) ||...
    row(point) <= row(point+1)
                
    return;         % значит нельзя определить РС
end

for up = point+1:length(row)        % идем вверх по точке
    
    if row(up) < ResLevel           % если ниже порога
        break;                      % выходим
    else
        Value = Value+1;            % иначе +1 к РС
    end
end

for down = point-1:-1:1             % идем вниз
    if row(down) < ResLevel         % если ниже порога
        break;                      % выходим
    else
        Value = Value+1;            % иначе +1 к РС
    end
end

% если дошли до начала/конца строки, тогда нельзя определить РС
if down == 1 || up == length(row)          
    Value = 0;
    return;
end

Value = Value+1;    % сама точка добавляет значение РС
    

% ФУНКЦИЯ ИЗМЕНЯЮЩАЯ РАСПОЛОЖЕНИЕ ОСИ ДЛЯ ГИСТОГРАММЫ/ИЗОБРАЖЕНИЯ
function NewPosition = ChangeAxesPosition(Position,whatfor)
    
assert( size(Position,1) == 1 && size(Position,2) == 4,...
        'Неверно заданы координаты расположения осей "Position"');

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
        
        assert(0,'Вызов функции изменения размера с отсутствующим "whatfor"');
end


% ФУНКЦИЯ, КОТОРАЯ СТРОИТ НОВОЕ ОКНО С ОСЬЮ ПО ЦЕНТРУ ЭКРАНА
function Ax = NewFigureWihAxes()

scr_res = get(0, 'ScreenSize');                 % считываем разрешение экрана
figure( 'Color',[1 1 1],'NumberTitle','off',...
        'Position',[(scr_res(3)-700)/2 (scr_res(4)-400)/2 700 400]);

Ax = axes('Units','pixels','Position',[50 30 620 320]);


% ФУНКЦИЯ, КОТОРАЯ СТРОИТ ГИСТОГРАММУ В ЗАДАННЫХ ОСЯХ
function ObjectHandle = BuildHist(ax,Image,title_str)

% проверяем сколько каналов у изображения
% и назначаем цвет для каждого канала 

assert(size(Image,3) ~= 2 && size(Image,4) == 1,'Image не является изображением');

switch size(Image,3)
    case 1      % канал
        color = [0 0 0];
        
    case 3      % RGB
        color = [1 0 0; 0 1 0; 0 0 1];
        
    otherwise   % многоканальные изображения
        color = colormap(gcf,hsv(size(Image,3))); 
end

if any(Image(:) < 0)        % если есть отрицательные значения (для гистограмм шума)
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

if any(Image(:) < 0)        % если есть отрицательные значения
    xlim(ax,[-270 270]); 
else
    xlim(ax,[-10 270]);
end

hold(ax,'off');
title(ax,title_str);


% ФУНКЦИЯ, ВЫЧИСЛЯЮЩАЯ СТАТИЧЕСКИЕ ХАРАКТЕРИСТИКИ ТЕКСТУРЫ ИЗОБРАЖЕНИЯ
function texture = statxture(Image,scale)
% texture - МАТРИЦА ИЗ 6 ЭЛЕМЕНТОВ: СРЕДНЕГО ЗНАЧЕНИЯ, СКО, ГЛАДКОСТИ,
% ТРЕТЬЕГО МОМЕНТА, ОДНОРОДНОСТИ И ЭНТРОПИИ
% Гонсалес, Вудс: с. 610-611

if nargin == 1
    scale = ones(1,6);
else
    assert(length(scale(:)) == 6,'Scale состоит не из 6 элементов');
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


% ФУНКЦИЯ, ВЫЧИСЛЯЮЩАЯ n СТАТ. ЦЕНТРАЛЬНЫХ МОМЕНТОВ ГИСТОГРАММЫ p ИЗОБРАЖЕНИЯ
function [v, unv] = statmoments(p,n)
% Гонсалес, Вудс: с. 609-610

if length(p) ~= 256
    error('p должен содежать 256 элементов');
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


% ФУНКЦИЯ, РАСЧИТЫВАЮЩАЯ МИН. И МАКС. РАЗМЕРЫ МАСКИ ПОДАВЛЕНИЯ В ПРЕОБРАЗОВАНИИ ХАФА
function [MinMask,MaxMask] = SuppressMaskRecount(BW,Theta0,Theta1,ThetaStep,RhoStep)

assert(size(BW,3) == 1,'На вход подано не полутоновое изображение');
assert(size(BW,4) == 1,'На вход подано не изображение');
assert(isnumeric([Theta0 Theta1 ThetaStep RhoStep]),'На вход подано не число');

Rho = -norm(size(BW)):RhoStep:norm(size(BW));
Theta = Theta0:ThetaStep:Theta1;

MinMask(1) = 1;     % мин. значения стороны маски подавления
MinMask(2) = 1;     % мин. значения стороны маски подавления

MaxMask(1) = round(length(Rho)/2);
MaxMask(2) = round(length(Theta)/2);
MaxMask(1) = MaxMask(1) - mod(MaxMask(1),2) - 1;  % максимальный размер маски подавления нечетный
MaxMask(2) = MaxMask(2) - mod(MaxMask(2),2) - 1;  % максимальный размер маски подавления нечетный

MaxMask(MaxMask < 2) = 3;


% ФУНКЦИЯ, ВЫДАЮЩАЯ НА ВЫХОДЕ 2D БИНАРНОЕ ИЗОБРАЖЕНИЕ
function BW = getBW(Image)

% если Image является бинарным (только 0 и макс. значение), тогда просто
% преобразуем его к виду 0 и 1; иначе проведем бинаризацию Оцу;
% если все каналы Image одинаковы, тогда размерность BW будет 2D, иначе
% будет возвращен size(Image,3)-мерный массив двухмерных изображений

Image(Image == max(Image(:))) = 1;

if any(Image(:) ~= 0 & Image(:) ~= 1)        % если это не логический массив, проведем бинаризацию по Оцу
    
    if size(Image,3) > 3            % для многоканальных изображений
        
        BW = zeros(size(Image));
        for ch = 1:size(Image,3)    % обрабатываем каждый канал как полутоновый
            BW(:,:,ch) = im2bw(Image(:,:,ch),graythresh(Image(:,:,ch)));
        end
        
    else                            % для полутоновых и RGB
        BW(:,:) = im2bw(Image,graythresh(Image));
    end
    
else                        % если уже подан логический массив
    
    if size(Image,3) == 1   % и если это 2D логический массив
        BW = Image;     	% просто передаем его
    else                    % иначе сравниваем каналы между собой
        
        equal = true;       % считаем их изначально равными
        for ch = 1:size(Image,3)-1
            if ~isequal(Image(:,:,ch),Image(:,:,ch+1))
                equal = false;  % как только нашли неравные
                break;
            end            
        end
        
        if equal
            BW = Image(:,:,1);  % просто передаем первый канал
        else
            BW = Image;     	% просто передаем все каналы
        end
    end
end


% ФУНКЦИЯ, ВЫСЧИТЫВАЮЩАЯ ПРОСТРАНСТВЕННЫЕ ВЕСА МАСКИ
function SWC = SpacialWeightCount(MaskSize)

SWC = zeros(MaskSize^2,1);      % вектор-столбец со значениями весов
center = (MaskSize + 1)/2;
z = 1;

for x = 1:MaskSize
    for y = 1:MaskSize
        SWC(z) = abs(center - x) + abs(center - y);
        z = z + 1;
    end
end


% ФУНКЦИЯ, СОХРАНЯЮЩАЯ ГИСТОГРАММУ В ФОРМАТЕ XLSX
function SaveHistAsXLSX(ax,FileName)

Hist_Data = get(findobj('Parent',ax,'DisplayStyle','stairs'));

assert(~isempty(Hist_Data),'Не нашел в заданных осях объект гистограмм со свойством отображения лестницей');

Data = zeros(size(Hist_Data,1)+1,Hist_Data(1).NumBins);
Ticks = cell(size(Hist_Data,1)+1,1);

for x = 1:size(Hist_Data,1)
    Data(x,:) = Hist_Data(x).Values;
    Ticks{x,1} = ['Канал № ' num2str(x)];
end

Data(end,:) = Hist_Data(x).BinLimits(1):Hist_Data(x).BinLimits(2);
Ticks{end} = 'Значения яркости';

xlswrite(FileName,Ticks,1);
xlswrite(FileName,Data,1,'B1');


% ФУНКЦИЯ, ВЫДАЮЩАЯ КООРДИНАТЫ ТОЧЕК ОКРУЖНОСТИ
function points = GetCirclePoints(center_x,center_y,R,Image)

phi = 1:180/(2*R*pi):360;           % считаем окружность
points_x = center_x + R*cosd(phi);
points_y = center_y + R*sind(phi);

points_x = round(points_x);     % округляем
points_y = round(points_y);

% проверки на выход за пределы изображения. Не менять порядок x и y!!!! 
points_y( points_x > size(Image,2) | points_x < 1 ) = [];      
points_x( points_x > size(Image,2) | points_x < 1 ) = [];

points_x( points_y > size(Image,1) | points_y < 1 ) = [];
points_y( points_y > size(Image,1) | points_y < 1 ) = [];

% загоняем в один массив
points(:,1) = points_x;
points(:,2) = points_y;

% убираем повторяющиеся пары
points = unique(points,'rows');


% ФУНКЦИЯ, ОТКРЫВАЮЩАЯ КАРТИНУК ПРИЛОЖЕНИЕМ ВИНДЫ
function OpenImageOutside(Image)

global format;

% сохраняем картинку в корне и открываем ее осевым просмотрщиком
% перед закрытием удаляем файл
imwrite(Image,['TempImage.' format]);
winopen(['TempImage.' format]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% ФУНКЦИИ "IMAGE ANALYZER" %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% МЕНЮ ЗАПУСКА ОКНА "IMAGE ANALYZER"
function RunImageAnalyzer_Callback(hObject, eventdata, ~) %#ok<DEFNU>

global Original;
global Noised;

ImageAnalyzer = openfig('ImageAnalyzer.fig');       % открываем окно
analyzer_handles = guihandles(ImageAnalyzer);       % считываем указатели на его объекты

scr_res = get(0, 'ScreenSize');             % считываем разрешение экрана и окна
fig = get(ImageAnalyzer,'Position');        % меняем позицию окна

set(ImageAnalyzer,'Position',[(scr_res(3)-fig(3))/2 (scr_res(4)-fig(4))/2 fig(3) fig(4)]);    
set(ImageAnalyzer,'CloseRequestFcn','delete(gcf);');

% связываем объекты и методы
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

% если исходное изображение содержит только один канал, блокируем
% контекстные меню

if size(Original,3) == 1
    set(analyzer_handles.SaveAreaRGBMenu,'Enable','off');
    set(analyzer_handles.ViewAreaRGBMenu,'Enable','off');
else
    set(analyzer_handles.SaveAreaRGBMenu,'Enable','on');
    set(analyzer_handles.ViewAreaRGBMenu,'Enable','on');    
end

% УСТАНАВЛИВАЕМ МЕНЮ, СЛАЙДЕРЫ И ЗАПУСКАЕМ 

if isempty(Noised) == 1
    set(analyzer_handles.ImageMenu,'String','Исходное изображение');
else
    set(analyzer_handles.ImageMenu,'String',...
    {'Исходное изображение';'Зашумленное изображение';'Отфильтрованное изображение'});
end

set(analyzer_handles.ImageMenu,'Value',1);
set(analyzer_handles.NumderImageMenu,'Value',1,'String','Изображение № 1');
set(analyzer_handles.ChannelImageMenu,'Value',1,'String',createSTR(size(Original,3),0));

set(analyzer_handles.X0_Slider,'Min',1,'Max',size(Original,2),...
    'Value',1,'SliderStep',[1/(size(Original,2)-1) 10/(size(Original,2)-1)]);

set(analyzer_handles.X1_Slider,'Min',1,'Max',size(Original,2),...
    'Value',size(Original,2),'SliderStep',[1/(size(Original,2)-1) 10/(size(Original,2)-1)]);

set(analyzer_handles.RowSlider,'Min',1,'Max',size(Original,2),...
   'Value',1,'SliderStep',[1/(size(Original,2)-1) 10/(size(Original,2)-1)]);

% слайдеры сделаны со знаком "-" для инверсия только, чтобы рамка менялась
% по направлению с ползунком
set(analyzer_handles.Y0_Slider,'Max',-1,'Min',-size(Original,1),...
                'Value',-1,'SliderStep',[1/(size(Original,1)-1) 10/(size(Original,1)-1)]);

set(analyzer_handles.Y1_Slider,'Max',-1,'Min',-size(Original,1),...
    'Value',-size(Original,1),'SliderStep',[1/(size(Original,1)-1) 10/(size(Original,1)-1)]);

set(analyzer_handles.StringSlider,'Max',-1,'Min',-size(Original,1),...
               'Value',-1,'SliderStep',[1/(size(Original,1)-1) 10/(size(Original,1)-1)]);
           

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

Image = Original(:,:,1);

% считаваем координаты новой (Y-ки с инверсией)
Y0 = -(round(get(analyzer_handles.Y0_Slider,'Value')));
Y1 = -(round(get(analyzer_handles.Y1_Slider,'Value')));
X0 = round(get(analyzer_handles.X0_Slider,'Value'));
X1 = round(get(analyzer_handles.X1_Slider,'Value'));
Xrow = round(get(analyzer_handles.RowSlider,'Value'));
Ystring = -round(get(analyzer_handles.StringSlider,'Value'));
    

% СОЗДАЕМ ВСЕ ОБЪЕКТЫ ЗДЕСЬ, В ФУНКЦИИ-ОТРИСОВКЕ БУДЕМ ИХ ТОЛЬКО ОБНОВЛЯТЬ
Area = imshow(Original(:,:,1),'Parent',analyzer_handles.AreaAxes);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Hist = BuildHist(analyzer_handles.AreaAxesHist,Image(Y0:Y1,X0:X1),'Гистограмма');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
ResLevel = double(Image(Ystring,Xrow)*get(analyzer_handles.ResLevelSlider,'Value'));

    
line(0:X1-X0+2,ones(1,X1-X0+3)*(Ystring-Y0+1),'Color','g','LineStyle','--','LineWidth',1.5,'Parent',analyzer_handles.AreaAxes);
line(ones(1,Y1-Y0+3)*(Xrow-X0+1),0:Y1-Y0+2,'Color','m','LineStyle','--','LineWidth',1.5,'Parent',analyzer_handles.AreaAxes);
 
bar(X0:X1,Original(Ystring,X0:X1,1),0.4,'Parent',analyzer_handles.RowAxes);
xlim(analyzer_handles.RowAxes,[X0-1 X1+1]);
ylim(analyzer_handles.RowAxes,[0 260]);

line(X0-1:X1+1,ones(1,X1-X0+3)*ResLevel,'Color','r','LineWidth',1.5,'Parent',analyzer_handles.RowAxes);
line(ones(1,256)*Xrow,1:256,'Color','m','LineWidth',1.5,'LineStyle','--','Parent',analyzer_handles.RowAxes);
title(analyzer_handles.RowAxes,['Значения яркости пикселей в строке № ' num2str(Ystring)],'FontSize',12);

% рисуем график столбца
bar(Y0:Y1,Original(Y0:Y1,Xrow,1),0.4,'Parent',analyzer_handles.ColAxes);
xlim(analyzer_handles.ColAxes,[Y0-1 Y1+1]);
ylim(analyzer_handles.ColAxes,[0 260]);

line(Y0-1:Y1+1,ones(1,Y1-Y0+3)*ResLevel,'Color','r','LineWidth',1.5,'Parent',analyzer_handles.ColAxes);
line(ones(1,256)*Ystring,1:256,'Color','g','LineWidth',1.5,'LineStyle','--','Parent',analyzer_handles.ColAxes);
title(analyzer_handles.ColAxes,['Значения яркости пикселей в столбце № ' num2str(Xrow)]);
    
% задаем контекстные меню
set(Area,'UIContextMenu',analyzer_handles.AreaContextMenu);  
set(Hist,'UIContextMenu',analyzer_handles.HistContextMenu);   

% title(analyzer_handles.AreaAxesHist,{'Гистограмма области интереса';''});
xlim(analyzer_handles.AreaAxesHist,[0 260]);          

% запуск отрисовки
ImageMenu_Callback(hObject, eventdata, analyzer_handles);

% делаем окно модальным
set(ImageAnalyzer,'Visible','on','WindowStyle','modal');


% ФУНКЦИЯ-ОТРИСОВКА, НА КОТОРУЮ ССЫЛАЮТСЯ ВСЕ ОСТАЛЬНЫЕ
function ImageMenu_Callback(hObject, ~, analyzer_handles)

global Original;            % исходное изображение
global Noised;              % зашумленный вариант
global Filtered;            % отфильтрованное изображение

try     % при долгой загрузке и закрытии - теряются указатели на объекты, а трай не шумит

    % ищем объекты в осях
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

        case 1  % исходное изображение

            set(analyzer_handles.NumderImageMenu,'String','Изображение № 1','Value',1);
            Image = Original(:,:,get(analyzer_handles.ChannelImageMenu,'Value'));

        case 2  % зашумленное изображение

            set(analyzer_handles.NumderImageMenu,'String',createSTR(size(Noised,4),1));
            Image = Noised(:,:,get(analyzer_handles.ChannelImageMenu,'Value'),...
                get(analyzer_handles.NumderImageMenu,'Value'));

        case 3  % отфильтрованное изображение

            set(analyzer_handles.NumderImageMenu,'String',createSTR(size(Filtered,4),1));
            Image = Filtered(:,:,get(analyzer_handles.ChannelImageMenu,'Value'),...
                get(analyzer_handles.NumderImageMenu,'Value'));
    end

    % СЧИТЫВАЕТ ЗНАЧЕНИЯ УПРАВЛЯЮЩИХ ЭЛЕМЕНТОВ
    Y0 = -(round(get(analyzer_handles.Y0_Slider,'Value')));  % считываем координаты новой (Y-ки с инверсией)
    Y1 = -(round(get(analyzer_handles.Y1_Slider,'Value')));
    X0 = round(get(analyzer_handles.X0_Slider,'Value'));
    X1 = round(get(analyzer_handles.X1_Slider,'Value'));
    Xrow = round(get(analyzer_handles.RowSlider,'Value'));
    Ystring = -round(get(analyzer_handles.StringSlider,'Value'));
    ResLevel = double(round(Image(Ystring,Xrow)*get(analyzer_handles.ResLevelSlider,'Value')));
    set(analyzer_handles.text7,'String',[num2str(get(analyzer_handles.ResLevelSlider,'Value')) ' ('  num2str(ResLevel) ')']);

    % пишем текст в строки
    set(analyzer_handles.X0,'String',num2str(X0));
    set(analyzer_handles.Y0,'String',num2str(Y0));
    set(analyzer_handles.X1,'String',num2str(X1));
    set(analyzer_handles.Y1,'String',num2str(Y1));


    % если не эти объекты вызвали, тогда необходима перерисовка -
    % не загружаем систему, где не надо менять картинку
    if hObject ~= analyzer_handles.StringSlider &&...
            hObject ~= analyzer_handles.RowSlider &&...
            hObject ~= analyzer_handles.ResLevelSlider

        % по выбранной радиокнопке
        switch get(analyzer_handles.ROIRadioButton,'Value')     % рисуем область интереса
            case 1
                set(Area,'CData',Image(Y0:Y1,X0:X1));

            case 0
                Spectre = fft2(Image(Y0:Y1,X0:X1));     % получил спектр области интереса
                Spectre = fftshift(Spectre);            % центрировал
                Spectre = abs(Spectre);                 % получил модуль
                SpectreImage = log(1 + Spectre);        % перевел в логарифм. шкалу, чтобы было видно
                SpectreImage = uint8(SpectreImage*255/max(SpectreImage(:))); % перевел в 8 бит и нормировал

                set(Area,'CData',SpectreImage);                             % вставили в ось спектр
                setappdata(analyzer_handles.AreaAxes,'Spectre',Spectre);    % запомнили ее
        end
    end


    % отрисовывае графики строк/столбцов по выбранной радиокнопке
    switch get(analyzer_handles.ROIRadioButton,'Value')

        case 1      % для области интереса

            % если нужно перестраивать графики столбца и строки
            if hObject ~= analyzer_handles.ResLevelSlider

                % расписываем текстовые строки
                set(analyzer_handles.RowNumberText,'String',num2str(Xrow));
                set(analyzer_handles.StringNumberText,'String',num2str(Ystring));

                % рисуем график строки
                set(RowGraph,'XData',X0:X1,'YData',Image(Ystring,X0:X1));
                xlim(analyzer_handles.RowAxes,[X0-1 X1+1]);
                set(RowGraphSecondLine,'XData',ones(1,256)*Xrow);
                ylim(analyzer_handles.RowAxes,[0 260]);
                title(analyzer_handles.RowAxes,['Значения яркости пикселей в строке № ' num2str(Ystring)]);

                % рисуем график столбца
                set(ColGraph,'XData',Y0:Y1,'YData',Image(Y0:Y1,Xrow));
                xlim(analyzer_handles.ColAxes,[Y0-1 Y1+1]);
                set(ColGraphSecondLine,'XData',ones(1,256)*Ystring);
                ylim(analyzer_handles.ColAxes,[0 260]);
                title(analyzer_handles.ColAxes,['Значения яркости пикселей в столбце № ' num2str(Xrow)]);

            end

            % линии значения уровня разреш. способности
            set(ColGraphFirstLine,'XData',Y0-1:Y1+1,'YData',ones(1,Y1-Y0+3)*ResLevel,'Visible','on');
            set(RowGraphFirstLine,'XData',X0-1:X1+1,'YData',ones(1,X1-X0+3)*ResLevel,'Visible','on');


        case 0        % или ее спектра

            Spectre = getappdata(analyzer_handles.AreaAxes,'Spectre');

            % расписываем текстовые строки
            set(analyzer_handles.RowNumberText,'String',num2str(Xrow-X0+1));
            set(analyzer_handles.StringNumberText,'String',num2str(Ystring-Y0+1));

            % рисуем график строки
            set(RowGraph,'XData',1:size(Spectre,2),'YData',Spectre(Ystring-Y0+1,:));
            xlim(analyzer_handles.RowAxes,[1 size(Spectre,2)]);
            ylim(analyzer_handles.RowAxes,[0 max(Spectre(Ystring-Y0+1,:))]);
            title(analyzer_handles.RowAxes,['Модуль значений спектра в строке № ' num2str(Ystring-Y0+1)]);

            % рисуем график столбца
            set(ColGraph,'XData',1:size(Spectre,1),'YData',Spectre(:,Xrow-X0+1));
            xlim(analyzer_handles.ColAxes,[1 size(Spectre,1)]);
            ylim(analyzer_handles.ColAxes,[0 max(Spectre(:,Xrow-X0+1))]);
            title(analyzer_handles.ColAxes,['Модуль значений спектра в столбце № ' num2str(Xrow-X0+1)]);

            % линии значения уровня разреш. способности
            set(ColGraphFirstLine,'Visible','off');
            set(RowGraphFirstLine,'Visible','off');
    end

    % рисуем две линии, соответствующие отрисовке строки и столбца
    set(RowOnArea,'XData',0:X1-X0+2,'YData',ones(1,X1-X0+3)*(Ystring-Y0+1));
    set(ColOnArea,'XData',ones(1,Y1-Y0+3)*(Xrow-X0+1),'YData',0:Y1-Y0+2);

    % меняем пределы осей, увеличивая область интереса, чтобы увеличивалось
    % изображение в оси
    xlim(analyzer_handles.AreaAxes,[1 X1-X0+1.01]);
    ylim(analyzer_handles.AreaAxes,[1 Y1-Y0+1.01]);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % строим гистограмму области интереса
    set(Hist,'Data',Image(Y0:Y1,X0:X1));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % обновляем отрисовку
    drawnow();

    if get(analyzer_handles.SpectreRadioButton,'Value')    % если строили спектр

        % то прописываем пустую строку для вывода пользователю и выходим
        set([analyzer_handles.AssesmentText analyzer_handles.AssesmentValueText],'String','');
        set(analyzer_handles.text10,'Visible','off');
        return;
    end

    PixBr = Image(Ystring,Xrow);        % яркость пикселя

    if X0 == X1         % если вместо ряда пиксель, то и не вычислим РС
        RowRes = 0;
    else                % разреш. способность в строке
        RowRes = PointResolution(Image(Ystring,X0:X1),Xrow-X0+1,ResLevel);
    end

    if Y0 == Y1         % если вместо столбца пиксель, то и не вычислим РС
        ColRes = 0;
    else                % разреш способность в столбце
        ColRes = PointResolution(Image(Y0:Y1,Xrow),Ystring-Y0+1,ResLevel);
    end

    % для устранения излишних расчетов, смотрим какой объект вызвал
    % отрисовку

    if      hObject ~= analyzer_handles.StringSlider &&...
            hObject ~= analyzer_handles.RowSlider &&...
            hObject ~= analyzer_handles.ResLevelSlider

        % пошли рассчитывать все характеристики
        Texture = statxture(Image(Y0:Y1,X0:X1));    % характеристики текстуры
        InvMoments = abs(log(invmoments(Image(Y0:Y1,X0:X1))));      % расчет инвариантных моментов

        % расчитав - сохраняем их
        setappdata(analyzer_handles.ImageAnalyzer,'Texture',Texture);
        setappdata(analyzer_handles.ImageAnalyzer,'InvMoments',InvMoments);

    else        % для остальных объектов - только берем и памяти прошлые значения

        % вызываем ранее рассчитанные
        Texture = getappdata(analyzer_handles.ImageAnalyzer,'Texture');
        InvMoments = getappdata(analyzer_handles.ImageAnalyzer,'InvMoments');

    end

    if get(analyzer_handles.ImageMenu,'Value') == 1     % если исходное изображение
        % прописываем строку и вставляем в текстовое поле
        asses_str = ...
            [ {'Математическое ожидание: '};...
            {'Среднеквадратическое отклонение: '};...
            {'Гладкость: '};...
            {'Третий момент: '};...
            {'Однородность: '};...
            {'Энтропия: '};...
            {'Коэффициент вариации: '};...
            {' '};...
            {'1-й инвариантный момент: '};...
            {'2-й инвариантный момент: '};...
            {'3-й инвариантный момент: '};...
            {'4-й инвариантный момент: '};...
            {'5-й инвариантный момент: '};...
            {'6-й инвариантный момент: '};...
            {'7-й инвариантный момент: '};...
            {' '};...
            {'Яркость выбранного пикселя: '};...
            {'Разрешающая способность в строке: '};...
            {'Разрешающая способность в столбце: '}];

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

    else        % если выбрано зашумленное или отфильтрованное изображение

        Im = double(Image(Y0:Y1,X0:X1));     % перевели в дубль фрагмент и исходное изображение
        Orig_Im = double(Original(:,:,get(analyzer_handles.ChannelImageMenu,'Value')));

        Assessment = GetAssessment(Orig_Im(Y0:Y1,X0:X1),Im,1);

        asses_str = ...
            [ {'Математическое ожидание: '};...
            {'Среднеквадратическое отклонение: '};...
            {'Гладкость: '};...
            {'Третий момент: '};...
            {'Однородность: '};...
            {'Энтропия: '};...
            {'Коэффициент вариации: '};...
            {' '};...
            {'MAE: '};...
            {'NAE: '};...
            {'MSE: '};...
            {'NMSE: '};...
            {'SNR, дБ: '};...
            {'PSNR, дБ: '};...
            {'SSIM: '};...
            {' '};...
            {'1-й инвариантный момент: '};...
            {'2-й инвариантный момент: '};...
            {'3-й инвариантный момент: '};...
            {'4-й инвариантный момент: '};...
            {'5-й инвариантный момент: '};...
            {'6-й инвариантный момент: '};...
            {'7-й инвариантный момент: '};...
            {' '};...
            {'Яркость выбранного пикселя: '};...
            {'Разрешающая способность в строке: '};...
            {'Разрешающая способность в столбце: '}];

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

    % прописываем строку для вывода пользователю
    set(analyzer_handles.text10,'Visible','on');        % заголовок характеристик
    set(analyzer_handles.AssesmentText,'String',asses_str,'FontSize',9);
    set(analyzer_handles.AssesmentValueText,'String',asses_val_str,'FontSize',9);

catch    
end


% СЛАЙДЕР Х0
function X0_Slider_Callback(hObject, eventdata, analyzer_handles)

X0 = round(get(analyzer_handles.X0_Slider,'Value'));    % иначе берем со слайдера
X1 = round(get(analyzer_handles.X1_Slider,'Value'));    % считываем слайдера-соседа

if X0 >= X1                                             % если пользователь выбрал больше соседнего
    set(analyzer_handles.X0_Slider,'Value',X1);         % ставим значение соседа
    set(analyzer_handles.RowSlider,'Enable','off');     % блокируем слайдер выбора строки
    
    set(analyzer_handles.RowNumberText,'Enable','off'); % блокируем edit строки
    set(analyzer_handles.RowNumberText,'String',num2str(X1));    % вписываем фиксированное значение
else    
    set(analyzer_handles.X0_Slider,'Value',X0);         % елси значение в пределах
    
    set(analyzer_handles.RowSlider,'Enable','on');      % активируем слайдер и edit
    set(analyzer_handles.RowSlider,'Min',X0,'Max',X1,...    % устанавливаем новые значения слайдеру и edit
               'Value',X0,'SliderStep',[1/(X1-X0) 10/(X1-X0)]);
           
    set(analyzer_handles.RowNumberText,'Enable','on');  % блокируем edit строки
    set(analyzer_handles.RowNumberText,'String',num2str(X0));  % вписываем значение
end

ImageMenu_Callback(hObject, eventdata, analyzer_handles);


% СЛАЙДЕР Х1
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
           
    set(analyzer_handles.RowNumberText,'Enable','on');  % блокируем edit строки
    set(analyzer_handles.RowNumberText,'String',num2str(X1));  % блокируем edit строки
end
           
ImageMenu_Callback(hObject, eventdata, analyzer_handles);


% СЛАЙДЕР Y0
function Y0_Slider_Callback(hObject, eventdata, analyzer_handles)

Y0 = -(round(get(analyzer_handles.Y0_Slider,'Value')));
Y1 = -(round(get(analyzer_handles.Y1_Slider,'Value')));

if Y0 >= Y1  
    set(analyzer_handles.Y0_Slider,'Value',-Y1);
    set(analyzer_handles.StringSlider,'Enable','off');
    set(analyzer_handles.StringNumberText,'Enable','off'); % блокируем edit строки
    set(analyzer_handles.StringNumberText,'String',num2str(Y1));    % вписываем фиксированное значение
    
else   
    set(analyzer_handles.Y0_Slider,'Value',-Y0);
    set(analyzer_handles.StringSlider,'Enable','on');
    set(analyzer_handles.StringSlider,'Max',-Y0,'Min',-Y1,...
               'Value',-Y0,'SliderStep',[1/(Y1-Y0) 10/(Y1-Y0)]);
    set(analyzer_handles.StringNumberText,'Enable','on'); % блокируем edit строки
    set(analyzer_handles.StringNumberText,'String',num2str(Y0));    % вписываем фиксированное значение
end
           
ImageMenu_Callback(hObject, eventdata, analyzer_handles);


% СЛАЙДЕР Y1
function Y1_Slider_Callback(hObject, eventdata, analyzer_handles)

Y0 = -(round(get(analyzer_handles.Y0_Slider,'Value')));
Y1 = -(round(get(analyzer_handles.Y1_Slider,'Value')));

if Y1 <= Y0  
    set(analyzer_handles.Y1_Slider,'Value',-Y0);
    set(analyzer_handles.StringSlider,'Enable','off');
    set(analyzer_handles.StringNumberText,'Enable','off'); % блокируем edit строки
    set(analyzer_handles.StringNumberText,'String',num2str(Y0));    % вписываем фиксированное значение
else    
    set(analyzer_handles.Y1_Slider,'Value',-Y1);
    set(analyzer_handles.StringSlider,'Enable','on');
    set(analyzer_handles.StringSlider,'Max',-Y0,'Min',-Y1,...
               'Value',-Y0,'SliderStep',[1/(Y1-Y0) 10/(Y1-Y0)]);
           
    set(analyzer_handles.StringNumberText,'Enable','on'); % блокируем edit строки
    set(analyzer_handles.StringNumberText,'String',num2str(Y1));    % вписываем фиксированное значение
end

ImageMenu_Callback(hObject, eventdata, analyzer_handles);


% СЛАЙДЕР УРОВНЯ ДЛЯ ОПЕРДЕЛЕНИЯ РАЗРЕШАЮЩЕЙ СПОСОБНОСТИ
function ResLevelSlider_Callback(hObject, eventdata, analyzer_handles)

set(analyzer_handles.text7,'String',num2str(get(analyzer_handles.ResLevelSlider,'Value')));
% запуска отрисовки
ImageMenu_Callback(hObject, eventdata, analyzer_handles);


% КОНТЕКСТНОЕ МЕНЮ "ПРОСМОТР В ПОЛУТОНАХ" 
function ViewAreaMonoMenu_Callback(hObject, eventdata, analyzer_handles)

% соседняя функция сама все отрисует
ViewAreaRGBMenu_Callback(hObject, eventdata, analyzer_handles);


% КОНТЕКСТНОЕ МЕНЮ "ПРОСМОТР ПОЛНОЦВЕТНЫЙ" 
function ViewAreaRGBMenu_Callback(hObject, ~, analyzer_handles)

global Original;            % исходное изображение
global Noised;              % зашумленный вариант
global Filtered;            % отфильтрованное изображение

% считали координаты фрагмента
Y0 = -(round(get(analyzer_handles.Y0_Slider,'Value')));
Y1 = -(round(get(analyzer_handles.Y1_Slider,'Value')));
X0 = round(get(analyzer_handles.X0_Slider,'Value'));
X1 = round(get(analyzer_handles.X1_Slider,'Value'));

% если вызвана с другой функции, то необходиом показать только один канал
if hObject == analyzer_handles.ViewAreaMonoMenu
    RGB = 1;
else
    RGB = 1:3;
end

% выбираем изображение
switch get(analyzer_handles.ImageMenu,'Value')
    
    case 1  % исходное изображение
        
        Image = Original(:,:,RGB);           % посмотрели, какое используется изображение
        
    case 2  % зашумленное изображение
        
        Image = Noised(:,:,RGB,get(analyzer_handles.NumderImageMenu,'Value'));
        
    case 3  % отфильтрованное изображение
        
        Image = Filtered(:,:,RGB,get(analyzer_handles.NumderImageMenu,'Value'));
end

Image = Image(Y0:Y1,X0:X1,:);  % вырезали фрагмент

try     
    imtool(Image); 
catch
    OpenImageOutside(Image); 
end


% КОНТЕКСТНОЕ МЕНЮ "КОПИРОВАТЬ" 
function CopyAreaMenu_Callback(~, ~, analyzer_handles)

% ищем объект с картинкой в осях с нажатым контектным меню
I = findobj('Parent',analyzer_handles.AreaAxes,'UIContextMenu',analyzer_handles.AreaContextMenu);
Image = get(I,'CData');

ClipboardCopyImage(Image);


% КОНТЕКСТНОЕ МЕНЮ "СОХРАНИТЬ В ПОЛУТОНАХ"
function SaveAreaMenu_Callback(~, ~, analyzer_handles)

global format;

% ищем объект с картинкой в осях с нажатым контекcтным меню
I = findobj('Parent',analyzer_handles.AreaAxes,'UIContextMenu',analyzer_handles.AreaContextMenu);
Image = get(I,'CData');

[FileName, PathName] = uiputfile(['*.' format],'Сохранить полутоновый фрагмент изображения');
if FileName~=0
    imwrite(Image,[PathName FileName],format);
end


% КОНТЕКСТНОЕ МЕНЮ "СОХРАНИТЬ ПОЛНОЦВЕТНЫЙ"
function SaveAreaRGBMenu_Callback(~, ~, analyzer_handles)

global Original;            % исходное изображение
global Noised;              % зашумленный вариант
global Filtered;            % отфильтрованное изображение
global format;

% запрос места хранения и имени файла
[FileName, PathName] = uiputfile(['*.' format],'Сохранить полноцветный фрагмент изображения');

if FileName ~= 0          % имя и путь есть
    switch get(analyzer_handles.ImageMenu,'Value')
        
        case 1  % исходное изображение
            
            Image = Original;           % посмотрели, какое используется изображение
            
        case 2  % зашумленное изображение
            
            Image = Noised(:,:,:,get(analyzer_handles.NumderImageMenu,'Value'));
            
        case 3  % отфильтрованное изображение
            
            Image = Filtered(:,:,:,get(analyzer_handles.NumderImageMenu,'Value'));
    end
    
    % считали координаты фрагмента
    Y0 = -(round(get(analyzer_handles.Y0_Slider,'Value')));
    Y1 = -(round(get(analyzer_handles.Y1_Slider,'Value')));
    X0 = round(get(analyzer_handles.X0_Slider,'Value'));
    X1 = round(get(analyzer_handles.X1_Slider,'Value'));
    
    
    I = Image(Y0:Y1,X0:X1,:,:);                 % вырезали фрагмент
    
    imwrite(I,[PathName FileName],format);      % сохранили
end


% КОНТЕКСТНОЕ МЕНЮ "КОПИРОВАТЬ ГИСТОГРАММУ" 
function CopyHist_Callback(~, ~, analyzer_handles)

ClipboardCopyObject(analyzer_handles.AreaAxesHist,0); 


% КОНТЕКСТНОЕ МЕНЮ "СОХРАНИТЬ ГИСТОГРАММУ"
function SaveHist_Callback(~, ~, analyzer_handles)

[FileName, PathName] = uiputfile({'*.jpg';'*.bmp';'*.tif';'*.png';'*.xlsx'},'Сохранить гистограмму');

if FileName~=0    
    
    DotPositions = strfind(FileName,'.');            % считываем точки в названии
    format = FileName(DotPositions(end)+1:end);      % считали формат файла после последней точки

    if strcmp(format,'xlsx')                
        SaveHistAsXLSX(analyzer_handles.AreaAxesHist,[PathName FileName]);
    else        
        SaveObjectAsImage(analyzer_handles.AreaAxesHist,[PathName FileName]);
    end
end


% ФУНКЦИЯ ДЛЯ ПАРЫ РАДИОКНОПОК "ОБЛАСТЬ ИНТЕРЕСА/СПЕКТР"
function ROIorSpectre_Callback(hObject, eventdata, analyzer_handles)
        
if ~get(hObject,'Value')        % чтобы на панели не оставались обе кнопке с "0"
    set(hObject,'Value',1);
    return;
end

ImageMenu_Callback(hObject, eventdata, analyzer_handles);


% ОТКЛИК edit СТРОК/СТОЛБЦОВ 
function XY_Callback (hObject, ~, analyzer_handles)
    
H = str2double(get(hObject,'String'));     % считал значение вызываемого поля 

if isnan(H)                            % если не число - ошибка
    errordlg('Введите в строку числовое значение','KAAIP');
    set(gcf,'WindowStyle', 'modal');
    return;
end

switch hObject                  % для каждого edit сопоставим слайдер
    case analyzer_handles.X0        
        
        SliderObject = analyzer_handles.X0_Slider;  % вызов слайдера
        Slider = 'X0_Slider';                       % взовем потом по имени объекта
                
    case analyzer_handles.X1 
        
        SliderObject = analyzer_handles.X1_Slider;
        Slider = 'X1_Slider';          
        
    case analyzer_handles.Y0                
        
        SliderObject = analyzer_handles.Y0_Slider;  % вызов слайдера
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
        warning('вызов объекта, который не является edit');
        return;
end

H = round(H);               % округлим
Min = get(SliderObject,'Min');
Max = get(SliderObject,'Max');

if H < Min     % при выходе за пределы присваиваем предельное значение
    H = Min;
elseif H > Max
    H = Max;
end

set(SliderObject,'Value',H);     % устанавливаем значение в слайдер
feval([Slider '_Callback'],hObject,H,analyzer_handles);    % вызываем отклик    


% КОНТЕКСТНОЕ МЕНЮ "СОХРАНИТЬ СТРОКУ ОЦЕНОК КАК TXT"
function SaveAssessmentTXT_Callback (~, ~, analyzer_handles)

[FileName, PathName] = uiputfile(['*.' 'txt'],'Сохранить характеристики области интереса');

if FileName ~= 0
    
    AssesmentName = get(analyzer_handles.AssesmentText,'String');
    AssesmentVal = get(analyzer_handles.AssesmentValueText,'String');
    Assess = strcat(AssesmentName,{' '},AssesmentVal);
    
    file_txt = fopen([PathName FileName],'wt');     % создаем текстовый файл
    
    for i = 1:size(Assess,1)                     % построчно вносим в него список
        fprintf(file_txt,'%s\r\n',Assess{i});
    end
    fclose(file_txt);                       % закрываем файл   
    
end


% КОНТЕКСТНОЕ МЕНЮ "СОХРАНИТЬ СТРОКУ ОЦЕНОК КАК XLSX"
function SaveAssessmentXLSX_Callback (~, ~, analyzer_handles)

[FileName, PathName] = uiputfile('*.xlsx','Сохранить значения оценки');

if FileName ~= 0
    
    DotPositions = strfind(FileName,'.');            % считываем точки в названии
    format = FileName(DotPositions(end)+1:end);
    
    if strcmp(format,'xlsx')
        AssesmentName = get(analyzer_handles.AssesmentText,'String');
        AssesmentVal = get(analyzer_handles.AssesmentValueText,'String');
        xlswrite([PathName FileName],AssesmentName,1);
        xlswrite([PathName FileName],AssesmentVal,1,'B1');
    else
        errordlg('Выберите формат .xlsx','Ошибка сохранения значений оценки');
        return;
    end
end

