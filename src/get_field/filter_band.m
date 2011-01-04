% 'filter_band.m': plot a field after band filtering in the GUI get_field 
%  GUI_input=filter_band(hget_field)
%
% OUTPUT: 
% GUI_input: option for display in the GUI get_field
%
%INPUT:
% hget_field: handles of the GUI get_field
%
function filter_band(Field,hget_field)

if ~isempty(VarIndex.x)
    VarName_x=Field.ListVarName{VarIndex.x};
end

prompt={'selected period (nbre of points)'};
   def={'10'};
   dlgTitle='primary period';
   lineNo=1;
   answer=inputdlg(prompt,dlgTitle,lineNo,def);
period=round(str2num(answer{1}));
filt_vector=ones(1,period)/period;% averaging vector
VarName_y=Field.ListVarName(VarIndex.y);
% hfig
if isempty(str2num(hfig))
    figure
else
figure(str2num(hfig))
end
for ivar=1:length(VarName_y)
    eval(['Var= filter(filt_vector,1,Field.' VarName_y{ivar} ');']);

    plot(Var)
    grid on
    hold on
end

 