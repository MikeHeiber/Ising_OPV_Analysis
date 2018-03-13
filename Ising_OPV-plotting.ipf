#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 6.3 // Minimum Igor version required
#pragma version = 0.1-alpha

Function IOPV_GraphCompositionMap(x_vals,y_vals,comp) : Graph
	Wave x_vals
	Wave y_vals
	Wave comp
	WaveStats/Q x_vals
	Variable X_max = V_max+1
	WaveStats/Q y_vals
	Variable Y_max = V_max+1
	Make/O/D/N=(X_max,Y_max) comp_matrix
	Variable i
	for(i=0;i<numpnts(x_vals);i++)
		comp_matrix[x_vals[i]][y_vals[i]] = comp[i]
	endfor
	KillWaves x_vals y_vals comp
	Display
	AppendMatrixContour comp_matrix
	ModifyContour comp_matrix update=0,manLevels={0.1,0.2,5},ctabLines={*,*,BlueHot256,0}
	ModifyContour comp_matrix fill=1,ctabFill={*,*,BlueHot256,0},boundary=1,labels=0
	ModifyGraph margin(left)=56,margin(top)=14,margin(right)=70,margin(bottom)=42
	ModifyGraph width=900,height=650
	ModifyGraph hideTrace('comp_matrix=boundary')=1
	ModifyGraph mirror=1,standoff=0,tick=1
	ColorScale/C/N=text0/F=0/A=RT/X=1/Y=1/E=2  ctab={0,1,BlueHot256,0}
	ColorScale/C/N=text0 fsize=12
End

Function IOPV_GraphCrossSections(unit_size,[path_str,morph_num])
	Variable unit_size
	String path_str
	Variable morph_num
	String original_folder = GetDataFolder(1)
	if(!ParamIsDefault(path_str))
		NewPath/O/Q tempPath, path_str
		LoadWave/N=tempWave/D/J/K=1/L={0,0,0,0,0}/O/P=tempPath/Q "morphology_"+num2str(morph_num)+".txt"
		KillPath tempPath
	else
		LoadWave/N=tempWave/D/J/K=1/L={0,0,0,0,0}/O/Q 
	endif	
	Wave tempWave0 = $("tempWave0")
	WaveStats/Q tempWave0
	Variable size = V_npnts
	Variable Length = tempWave0[1]
	Variable Width = tempWave0[2]
	Variable Height = tempWave0[3]
	Variable i
	for(i=0;i<Length;i+=1)
		IOPV_GraphCrossSection(i,unit_size,path_str=path_str)
		NewPath/O/Q tempPath, path_str
		String window_name = "CrossSection"+num2istr(i)
		DoWindow/C $(window_name)
		SavePICT/O/P=tempPath/E=-5/B=72
		KillWindow $(window_name)
	endfor	
	KillWaves tempWave0
	SetDataFolder original_folder
End

Function IOPV_GraphCrossSection(slice_num,unit_size,[path_str,morph_num]) : Graph
	Variable slice_num
	Variable unit_size
	String path_str
	Variable morph_num
	String original_folder = GetDataFolder(1)
	if(!ParamIsDefault(path_str))
		NewPath/O/Q tempPath, path_str
		LoadWave/N=tempWave/D/J/K=1/L={0,0,0,0,0}/O/P=tempPath/Q "morphology_"+num2str(morph_num)+".txt"
		KillPath tempPath
	else
		LoadWave/N=tempWave/D/J/K=1/L={0,0,0,0,0}/O/Q 
	endif	
	Wave tempWave0 = $("tempWave0")
	WaveStats/Q tempWave0
	Variable size = V_npnts
	Variable Length = tempWave0[1]
	Variable Width = tempWave0[2]
	Variable Height = tempWave0[3]
	Variable Num_types = tempWave0[7]
	Make/O/I/N=(Width*Height,Num_types) $("y-data_"+num2str(slice_num)+"_"+num2str(morph_num))
	Make/O/I/N=(Width*Height,Num_types) $("z-data_"+num2str(slice_num)+"_"+num2str(morph_num))
	Wave y_data = $("y-data_"+num2str(slice_num)+"_"+num2str(morph_num))
	Wave z_data = $("z-data_"+num2str(slice_num)+"_"+num2str(morph_num))
	Make/O/I/N=(Num_types) counts = 0
	Variable x
	Variable y
	Variable z
	Variable i = 8+2*Num_types
	Variable site_type
	Variable site_count = 0
	for(x=0;x<Length;x+=1)
		for(y=0;y<Width;y+=1)
			for(z=0;z<Height;z+=1)
				if(site_count==0 && i<size)
					site_type = trunc(tempWave0[i]/(10^(strlen(num2str(tempWave0[i]))-1)))
					site_count = tempWave0[i]-site_type*(10^(strlen(num2str(tempWave0[i]))-1))
					i += 1
				endif
				if(x==slice_num)
					y_data[counts[site_type-1]][site_type-1] = y
					z_data[counts[site_type-1]][site_type-1] = z
					counts[site_type-1] += 1
				endif
				site_count -= 1
				if(x>slice_num)
					break
				endif
			endfor
			if(x>slice_num)
				break
			endif
		endfor
		if(x>slice_num)
			break
		endif
	endfor
	Variable max_counts = 0
	for(i=0;i<Num_types;i++)
		if(counts[i]>max_counts)
			max_counts = counts[i]
		endif
	endfor
	for(i=0;i<Num_types;i++)
		DeletePoints/M=0 max_counts+1,(Width*Height-max_counts-1),y_data
		DeletePoints/M=0 max_counts+1,(Width*Height-max_counts-1),z_data
	endfor
	KillWaves tempWave0 counts
	Display z_data[][0] vs y_data[][0]
	for(i=1;i<Num_types;i++)
		AppendToGraph z_data[][i] vs y_data[][i]
	endfor
	ModifyGraph margin(left)=4,margin(bottom)=4,margin(top)=11,margin(right)=4,gfSize=7
	ModifyGraph height=133*Height/60,width={Aspect,Width/Height}
	ModifyGraph mode=3
	ModifyGraph marker=16
	ModifyGraph lSize=2
	// Red/Blue
	for(i=0;i<Num_types;i++)
		if(i==0)
			ModifyGraph rgb[0]=(1,4,52428)
		endif
		if(i==1)	
			ModifyGraph rgb[1]=(65535,0,0)
		endif
		if(i==2)
			ModifyGraph rgb[2]=(0,65535,0)
		endif
	endfor
	ModifyGraph msize=1
	ModifyGraph tick=1
	ModifyGraph mirror=1
	ModifyGraph nticks=0
	ModifyGraph noLabel(bottom)=1
	ModifyGraph standoff=0
	ModifyGraph tlOffset(left)=-1,tlOffset(bottom)=-2
	SetAxis left 0,*
	SetAxis bottom 0,*
	ColorScale/C/N=text1/D={0.5,0.5,-1}/F=0/Z=1/G=(0,0,0)/B=1/A=LB/X=(60/Height)/Y=(-400/Height)
	ColorScale/C/N=text1  ctab={0,100,Grays16,0}, vert=0, frame=0.5, height=12
	ColorScale/C/N=text1 widthPct=2200/Width, nticks=0, lblMargin=23
	ColorScale/C/N=text1 frameRGB=(0,0,0), axisRange={NaN,1,0}
	AppendText "\\Z09\\f01" + num2str(20*unit_size) + " nm"
	TextBox/C/N=text0/F=0/Z=1/A=LT/X=0.5/Y=(-450/Height) "x = "+num2str(slice_num)
	SetDataFolder original_folder
End

Proc IOPV_GraphStyle() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z margin(left)=34,margin(bottom)=31,margin(top)=8,margin(right)=8,width=240.945
	ModifyGraph/Z height={Aspect,0.8}
EndMacro

Proc IOPV_CompositionMapStyle() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z margin(left)=60,margin(bottom)=48,margin(top)=14,margin(right)=85
	ModifyGraph/Z expand=-1,width=700,height=700
	ModifyGraph/Z mode=3
	ModifyGraph/Z marker=16
	ModifyGraph/Z msize=1
	ModifyGraph/Z gaps=0
	ModifyGraph/Z zColor[0]={:'001_CB':comp1,0,1,YellowHot,1}
	ModifyGraph/Z zColorMin[0]=(1,9611,39321)
	ModifyGraph/Z tick=1
	ModifyGraph/Z zero(bottom)=1
	ModifyGraph/Z mirror=1
	ModifyGraph/Z fSize=20
	ModifyGraph/Z standoff=0
EndMacro

Function IOPV_GraphInterfaceHist(job_num) : Graph
	String job_num
	Wave wave_y1 = $("root:data:interface_dist_hist1_"+job_num)
	Wave wave_y2 = $("root:data:interface_dist_hist2_"+job_num)
	WaveStats/Q wave_y1
	Make/O/D/N=(V_npnts) $("root:data:interface_distances")
	Wave wave_x = $("root:data:interface_distances")
	Variable i
	for(i=0;i<V_npnts;i+=1)
		wave_x[i] = i+1
	endfor
	Display wave_y1 vs wave_x
	AppendToGraph wave_y2 vs wave_x
	ModifyGraph width=226.772,height=170.079
	ModifyGraph margin(left)=31,margin(bottom)=28,margin(top)=6,margin(right)=6,gfSize=9
	ModifyGraph mode=5
	ModifyGraph lSize=2
	ModifyGraph rgb[0]=(0,15872,65280),rgb[1]=(52224,0,0)
	ModifyGraph hbFill=2
	ModifyGraph useBarStrokeRGB=1
	ModifyGraph offset[0]={-0.5,0},offset[1]={-0.5,0.5}
	ModifyGraph tick=2
	ModifyGraph tick(bottom)=1
	ModifyGraph mirror=1
	ModifyGraph standoff=0
	Label left "Site Fraction"
	Label bottom "Distance to Interface (nm)"
	SetAxis left 0,1
	Legend/C/N=text0/F=0
End

Function IOPV_GraphTortuosityHist(job_num) : Graph
	String job_num
	Wave wave_x = $("root:data:tortuosity_values")
	Wave wave_y1 = $("root:data:tortuosity_hist1_"+job_num)
	Wave wave_y2 = $("root:data:tortuosity_hist2_"+job_num)
	Display wave_y1 vs wave_x
	AppendToGraph wave_y2 vs wave_x
	ModifyGraph width=226.772,height=170.079
	ModifyGraph margin(left)=31,margin(bottom)=28,margin(top)=6,margin(right)=9,gfSize=9
	ModifyGraph mode=5
	ModifyGraph lSize=2
	ModifyGraph rgb[0]=(0,15872,65280),rgb[1]=(52224,0,0)
	ModifyGraph hbFill=2
	ModifyGraph useBarStrokeRGB=1
	ModifyGraph offset[0]={-0.01,0},offset[1]={-0.01,0.5}
	ModifyGraph tick=2
	ModifyGraph tick(bottom)=1
	ModifyGraph mirror=1
	ModifyGraph standoff=0
	Label left "Site Fraction"
	Label bottom "Tortuosity"
	SetAxis left 0,1
	SetAxis bottom 0.99,1.5
	Legend/C/N=text0/F=0
End
