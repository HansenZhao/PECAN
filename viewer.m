function varargout = viewer(varargin)
% VIEWER MATLAB code for viewer.fig
%      VIEWER, by itself, creates a new VIEWER or raises the existing
%      singleton*.
%
%      H = VIEWER returns the handle to a new VIEWER or the handle to
%      the existing singleton*.
%
%      VIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIEWER.M with the given input arguments.
%
%      VIEWER('Property','Value',...) creates a new VIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before viewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to viewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help viewer

% Last Modified by GUIDE v2.5 30-Aug-2017 20:28:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @viewer_OpeningFcn, ...
                   'gui_OutputFcn',  @viewer_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


% --- Executes just before viewer is made visible.
function viewer_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to viewer (see VARARGIN)

% Choose default command line output for viewer
handles.output = hObject;
handles.hController = varargin{1};
handles.pop_name_1.Enable = 'off';
handles.pop_style_1.Enable = 'off';
handles.pop_name_2.Enable = 'off';
handles.pop_style_2.Enable = 'off';
handles.btn_load.Enable = 'off';
handles.btn_clear.Enable = 'off';
handles.edt_region.Enable = 'off';
handles.btn_slice.Enable = 'off';
handles.edt_res.Enable = 'off';
handles.edt_interp.Enable = 'off';
handles.edt_clim.Enable = 'off';
handles.edt_stepNum.Enable = 'off';
handles.btn_last.Enable = 'off';
handles.btn_next.Enable = 'off';
handles.rd_isImages.Enable = 'off';
handles.rd_isAVI.Enable = 'off';
handles.btn_save.Enable = 'off';
handles.edt_filedName.Enable = 'off';
handles.pop_method.Enable = 'off';
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes viewer wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = viewer_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles;


% --- Executes on button press in btn_save.
function btn_save_Callback(hObject, eventdata, handles)
% hObject    handle to btn_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in rd_isImages.
function rd_isImages_Callback(hObject, eventdata, handles)
% hObject    handle to rd_isImages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rd_isImages


% --- Executes on button press in rd_isAVI.
function rd_isAVI_Callback(hObject, eventdata, handles)
% hObject    handle to rd_isAVI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rd_isAVI



function edt_res_Callback(hObject, ~, handles)
% hObject    handle to edt_res (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~handles.hController.onResSet(get(hObject,'String'))
    hObject.String = '';
end
% Hints: get(hObject,'String') returns contents of edt_res as text
%        str2double(get(hObject,'String')) returns contents of edt_res as a double



function edt_interp_Callback(hObject, ~, handles)
% hObject    handle to edt_interp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~handles.hController.onInterpSet(get(hObject,'String'))
    hObject.String = '';
end
% Hints: get(hObject,'String') returns contents of edt_interp as text
%        str2double(get(hObject,'String')) returns contents of edt_interp as a double



function edt_clim_Callback(hObject, ~, handles)
% hObject    handle to edt_clim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~handles.hController.onClimSet(get(hObject,'String'))
    hObject.String = '';
end
% Hints: get(hObject,'String') returns contents of edt_clim as text
%        str2double(get(hObject,'String')) returns contents of edt_clim as a double


% --- Executes on button press in btn_last.
function btn_last_Callback(~, ~, handles)
% hObject    handle to btn_last (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hController.onLast();

% --- Executes on button press in btn_next.
function btn_next_Callback(~, ~, handles)
% hObject    handle to btn_next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hController.onNext();


function edt_stepNum_Callback(hObject, ~, handles)
% hObject    handle to edt_stepNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 if ~handles.hController.onStepNumberSet(get(hObject,'String'))
     hObject = '';
 end
% Hints: get(hObject,'String') returns contents of edt_stepNum as text
%        str2double(get(hObject,'String')) returns contents of edt_stepNum as a double

function edt_region_Callback(hObject, eventdata, handles)
% hObject    handle to edt_region (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~handles.hController.onSliceEdit(get(hObject,'String'));
    hObject.String = '';
end
% Hints: get(hObject,'String') returns contents of edt_region as text
%        str2double(get(hObject,'String')) returns contents of edt_region as a double

% --- Executes on button press in btn_slice.
function btn_slice_Callback(hObject, eventdata, handles)
% hObject    handle to btn_slice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hController.onSlice();


% --- Executes on selection change in pop_model.
function pop_model_Callback(hObject, ~, handles)
% hObject    handle to pop_model (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
v = get(hObject,'Value');
if v > 1
    contents = cellstr(get(hObject,'String'));
    if handles.hController.setModel(contents{get(hObject,'Value')});
        hObject.Enable = 'off';
        handles.btn_load.Enable = 'on';
    else
        set(hObject,'Value',1);
    end
end
% Hints: contents = cellstr(get(hObject,'String')) returns pop_model contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_model


% --- Executes on button press in btn_load.
function btn_load_Callback(hObject, ~, handles)
% hObject    handle to btn_load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hObject.Enable = 'off';
if handles.hController.onLoad()
    handles.btn_clear.Enable = 'on';
    handles.edt_region.Enable = 'on';
    handles.btn_slice.Enable = 'on';
else
    hObject.Enable = 'on';
end


% --- Executes on button press in btn_clear.
function btn_clear_Callback(hObject, ~, handles)
% hObject    handle to btn_clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hController.onClear();
hObject.Enable = 'off';
handles.pop_model.Enable = 'on';
handles.pop_model.Value = 1;
handles.btn_load.Enable = 'off';

handles.pop_name_1.Enable = 'off';
handles.pop_style_1.Enable = 'off';
handles.pop_name_2.Enable = 'off';
handles.pop_style_2.Enable = 'off';
handles.edt_region.Enable = 'off';
handles.btn_slice.Enable = 'off';
handles.edt_res.Enable = 'off';
handles.edt_interp.Enable = 'off';
handles.edt_clim.Enable = 'off';
handles.edt_stepNum.Enable = 'off';
handles.btn_last.Enable = 'off';
handles.btn_next.Enable = 'off';
handles.rd_isImages.Enable = 'off';
handles.rd_isAVI.Enable = 'off';
handles.btn_save.Enable = 'off';
handles.edt_filedName.Enable = 'off'
handles.pop_method.Enable = 'off'

handles.txt_frame.String = 'NaN';
handles.txt_current.String = 'NaN';


% --- Executes on selection change in pop_name_1.
function pop_name_1_Callback(hObject, eventdata, handles)
% hObject    handle to pop_name_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_name_1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_name_1


% --- Executes on selection change in pop_style_1.
function pop_style_1_Callback(hObject, eventdata, handles)
% hObject    handle to pop_style_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_style_1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_style_1


% --- Executes on selection change in pop_name_2.
function pop_name_2_Callback(hObject, eventdata, handles)
% hObject    handle to pop_name_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_name_2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_name_2


% --- Executes on selection change in pop_style_2.
function pop_style_2_Callback(hObject, eventdata, handles)
% hObject    handle to pop_style_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_style_2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_style_2



function edt_filedName_Callback(hObject, eventdata, handles)
% hObject    handle to edt_filedName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hController.onFieldNameSet(get(hObject,'String'));
% Hints: get(hObject,'String') returns contents of edt_filedName as text
%        str2double(get(hObject,'String')) returns contents of edt_filedName as a double


% --- Executes on selection change in pop_method.
function pop_method_Callback(hObject, eventdata, handles)
% hObject    handle to pop_method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
v = get(hObject,'Value');
if v > 1
  contents = cellstr(get(hObject,'String'));
  handles.hController.onMethodSet(contents{v});
end
% Hints: contents = cellstr(get(hObject,'String')) returns pop_method contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_method


% --- Executes on button press in btn_confirm.
function btn_confirm_Callback(hObject, ~, handles)
% hObject    handle to btn_confirm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.hController.onConfirm()
    handles.edt_filedName.Enable = 'on';
    handles.pop_method.Enable = 'on';
    handles.pop_method.Enable = 'on';
    if strcmp(handles.hController.modelClass,'Point Based Model')
      handles.edt_res.Enable = 'on';
    end
    handles.edt_interp.Enable = 'on';
    handles.edt_clim.Enable = 'on';
    handles.edt_stepNum.Enable = 'on';
    handles.pop_model.Enable = 'on';
    handles.btn_last.Enable = 'on';
    handles.btn_next.Enable = 'on';
    
    handles.edt_region.Enable = 'off';
    handles.btn_slice.Enable = 'off';
    hObject.Enable = 'off';
end


% --- Executes on button press in btn_refresh.
function btn_refresh_Callback(hObject, eventdata, handles)
% hObject    handle to btn_refresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hController.onRefresh();