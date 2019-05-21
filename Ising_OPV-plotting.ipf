#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 6.3 // Minimum Igor version required
#pragma version = 1.0-beta.1

// Copyright (c) 2018-2019 Michael C. Heiber
// This source file is part of the Ising_OPV_Analysis project, which is subject to the MIT License.
// For more information, see the LICENSE file that accompanies this software.
// The Ising_OPV_Analysis project can be found on Github at https://github.com/MikeHeiber/Ising_OPV_Analysis

Function IOPV_GraphCompositionMapGUI()
	String original_folder = GetDataFolder(1)
	// Get path to set from user
	NewPath/O/Q/M="Choose morphology set folder" set_path
	if(V_flag!=0)
		SetDataFolder original_folder
		return NaN
	endif
	// Get morphology set id name
	PathInfo set_path
	String path_string = S_path
	String set_id = ParseFilePath(0,path_string,":",1,0)
	// Load set info
	LoadWave/N=stringWave/J/K=2/P=set_path/Q "analysis_summary.txt"
	Wave/T stringWave0
	int Length = str2num(StringFromList(0,stringWave0[2],","))
	int morph_num_max = str2num(StringFromList(8,stringWave0[0]," "))-1
	// Cleanup
	KillWaves stringWave0
	KillPath set_path
	// Get info from user
	Variable morph_num
	Variable unit_size=1
	Variable scale_size
	Prompt morph_num, "Enter a morphology section number (0-"+num2str(morph_num_max)+")"
	Prompt unit_size, "Enter the pixel size (nm)"
	Prompt scale_size, "(Optional) Enter the scalebar size (nm):"
	DoPrompt "Enter Morphology Information:", morph_num, unit_size, scale_size
	// User cancelled operation
	if(V_flag==1)
		SetDataFolder original_folder
		return NaN
	endif
	// Check for valid user input
	if(morph_num<0 || morph_num>=morph_num_max)
		V_flag = -1
	endif
	if(!(unit_size>0))
		V_flag = -1
	endif
	if(scale_size<0)
		V_flag = -1
	endif
	if(V_flag==-1)
		DoAlert 0, "Invalid Entry! Try again."
		SetDataFolder original_folder
		return NaN
	endif
	SetDataFolder original_folder
	// Graph the cross section image
	if(scale_size==0)
		Print "•IOPV_GraphCompositionMap("+num2str(unit_size)+",\""+path_string+"\","+num2str(morph_num)+")"
		IOPV_GraphCompositionMap(unit_size,path_string,morph_num)
	else
		Print "•IOPV_GraphCompositionMap("+num2str(unit_size)+",\""+path_string+"\","+num2str(morph_num)+",scalebar_size="+num2str(scale_size)+")"
		IOPV_GraphCompositionMap(unit_size,path_string,morph_num,scalebar_size=scale_size)
	endif
End

Function IOPV_GraphCompositionMap(unit_size,path_str,morph_num,[scalebar_size]) : Graph
	Variable unit_size
	String path_str
	int morph_num
	Variable scalebar_size
	String original_folder = GetDataFolder(1)
	String set_id = StringFromList(ItemsInList(path_str,":")-1,path_str,":")
	SetDataFolder root:
	NewDataFolder/O/S Ising_OPV
	NewDataFolder/O/S $(set_id)
	NewPath/O/Q tempPath, path_str
	LoadWave/J/W/A/K=0/L={0,1,0,0,0}/P=tempPath/Q "areal_composition_map_"+num2str(morph_num)+".txt"
	KillPath tempPath
	Wave X_Position
	Wave Y_Position
	Wave Composition1
	Wave Composition2
	WaveStats/Q X_Position
	int X_max = V_max+1
	WaveStats/Q Y_Position
	int Y_max = V_max+1
	Make/O/N=(X_max,Y_max) $("composition_map1_"+num2str(morph_num)), $("composition_map2_"+num2str(morph_num))
	Wave composition_map1 = $("composition_map1_"+num2str(morph_num))
	Wave composition_map2 = $("composition_map2_"+num2str(morph_num))
	int i
	for(i=0;i<numpnts(Composition1);i+=1)
		composition_map1[X_Position[i]][Y_Position[i]] = Composition1[i]
		composition_map2[X_Position[i]][Y_Position[i]] = Composition2[i]
	endfor
	// Tortuosity Map 1
	NewImage/S=0/N=Composition_Map composition_map1;DelayUpdate
	ModifyImage $("composition_map1_"+num2str(morph_num)) ctab={0,1,RedWhiteBlue,0},minRGB=0,maxRGB=0
	SetAxis/A left
	IOPV_GraphStyleLinLin()
	ModifyGraph width=200,height=200
	ModifyGraph tick=3,noLabel=2
	ModifyGraph margin(left)=2,margin(bottom)=2,margin(right)=45,margin(top)=12
	TextBox/C/N=text0/F=0/A=LT/X=1.00/Y=1.00/E=2/Z=1 ("Set "+set_id+", Section "+num2str(morph_num))
	ColorScale/C/N=text1/F=0/A=RT/X=0.5/Y=4.00/E=2 width=10,heightPct=44,image=$("composition_map1_"+num2str(morph_num)),lblMargin=1,nticks=4,tickLen=4.00;DelayUpdate
	ColorScale/C/N=text1 "Donor Volume Fraction"
	if(ParamIsDefault(scalebar_size))
		scalebar_size = round(unit_size*X_max*0.20/10)*10
	endif
	Variable scalebar_pnts = (200*scalebar_size/(unit_size*X_max))
	ColorScale/C/N=text2/F=0/Z=1/B=1/A=LB/X=2.00/Y=2.00 vert=0,side=2,width=scalebar_pnts,height=13,image=$("composition_map1_"+num2str(morph_num)),axisRange={0.4999,0.5},nticks=0;DelayUpdate
	Variable indent_pct = 2 + 50*scalebar_pnts/200 - 50*18/200
	TextBox/C/N=text3/F=0/Z=1/B=1/A=LB/X=(indent_pct)/Y=4.00 "\\f01"+num2str(scalebar_size)+" nm"
	// Cleanup
	KillWaves X_Position Y_Position Composition1 Composition2 
	SetDataFolder original_folder
End

Function IOPV_GraphCrossSectionGUI()
	String original_folder = GetDataFolder(1)
	// Get path to set from user
	NewPath/O/Q/M="Choose morphology set folder" set_path
	if(V_flag!=0)
		SetDataFolder original_folder
		return NaN
	endif
	// Get morphology set id name
	PathInfo set_path
	String path_string = S_path
	String set_id = ParseFilePath(0,path_string,":",1,0)
	// Load set info
	LoadWave/N=stringWave/J/K=2/P=set_path/Q "analysis_summary.txt"
	Wave/T stringWave0
	int Length = str2num(StringFromList(0,stringWave0[2],","))
	int morph_num_max = str2num(StringFromList(8,stringWave0[0]," "))-1
	// Cleanup
	KillWaves stringWave0
	KillPath set_path
	// Get info from user
	Variable morph_num
	Variable slice_num
	Variable unit_size = 1
	Variable scale_size
	Prompt morph_num, "Enter a morphology section number (0-"+num2str(morph_num_max)+")"
	Prompt slice_num, "Enter a slice number (0-"+num2str(Length-1)+")"
	Prompt unit_size, "Enter the pixel size (nm)"
	Prompt scale_size, "(Optional) Enter the scalebar size (nm):"
	DoPrompt "Enter Cross Section Information:", morph_num, slice_num, unit_size, scale_size
	// User cancelled operation
	if(V_flag==1)
		SetDataFolder original_folder
		return NaN
	endif
	// Check for valid user input
	if(morph_num<0 || morph_num>=morph_num_max)
		V_flag = -1
	endif
	if(slice_num<0 || slice_num>=Length)
		V_flag = -1
	endif
	if(!(unit_size>0))
		V_flag = -1
	endif
	if(scale_size<0)
		V_flag = -1
	endif
	if(V_flag==-1)
		DoAlert 0, "Invalid Entry! Try again."
		SetDataFolder original_folder
		return NaN
	endif
	SetDataFolder original_folder
	// Graph the cross section image
	if(scale_size==0)
		Print "•IOPV_GraphCrossSection("+num2str(slice_num)+","+num2str(unit_size)+",\""+path_string+"\","+num2str(morph_num)+")"
		IOPV_GraphCrossSection(slice_num,unit_size,path_string,morph_num)
	else
		Print "•IOPV_GraphCrossSection("+num2str(slice_num)+","+num2str(unit_size)+",\""+path_string+"\","+num2str(morph_num)+",scalebar_size="+num2str(scale_size)+")"
		IOPV_GraphCrossSection(slice_num,unit_size,path_string,morph_num,scalebar_size=scale_size)
	endif
End

Function IOPV_GraphCrossSections(unit_size,path_str,morph_num)
	Variable unit_size
	String path_str
	Variable morph_num
	String original_folder = GetDataFolder(1)
	NewPath/O/Q tempPath, path_str
	LoadWave/N=tempWave/D/J/K=1/L={0,0,0,0,0}/O/P=tempPath/Q "morphology_"+num2str(morph_num)+".txt"
	KillPath tempPath	
	Wave tempWave0 = $("tempWave0")
	WaveStats/Q tempWave0
	Variable size = V_npnts
	Variable Length = tempWave0[1]
	Variable Width = tempWave0[2]
	Variable Height = tempWave0[3]
	Variable i
	for(i=0;i<Length;i+=1)
		IOPV_GraphCrossSection(i,unit_size,path_str,morph_num)
		NewPath/O/Q tempPath, path_str
		String window_name = "CrossSection"+num2istr(i)
		DoWindow/C $(window_name)
		SavePICT/O/P=tempPath/E=-5/B=72
		KillWindow $(window_name)
	endfor	
	KillWaves tempWave0
	SetDataFolder original_folder
End

Function IOPV_GraphCrossSection(slice_num,unit_size,path_str,morph_num,[scalebar_size]) : Graph
	int slice_num
	Variable unit_size
	String path_str
	int morph_num
	Variable scalebar_size
	String original_folder = GetDataFolder(1)
	String set_id = StringFromList(ItemsInList(path_str,":")-1,path_str,":")
	SetDataFolder root:
	NewDataFolder/O/S Ising_OPV
	NewDataFolder/O/S $(set_id)
	NewPath/O/Q tempPath, path_str
	LoadWave/N=tempWave/D/J/K=1/L={0,0,0,0,0}/O/P=tempPath/Q "morphology_"+num2str(morph_num)+".txt"
	KillPath tempPath
	Wave tempWave0 = $("tempWave0")
	WaveStats/Q tempWave0
	Variable size = V_npnts
	Variable Length = tempWave0[1]
	Variable Width = tempWave0[2]
	Variable Height = tempWave0[3]
	Variable Num_types = tempWave0[7]
	Make/O/B/N=(Width,Height) $("site_data_"+num2str(slice_num)+"_"+num2str(morph_num))
	Wave site_data = $("site_data_"+num2str(slice_num)+"_"+num2str(morph_num))
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
					site_data[y][z] = site_type
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
	KillWaves tempWave0 counts
	NewImage/K=0/N=Cross_Section site_data
	SetAxis/A left
	IOPV_GraphStyleLinLin()
	ModifyGraph margin(left)=2,margin(bottom)=2,margin(top)=12,margin(right)=2
	Variable section_width = 200*Width/Height
	ModifyGraph height=200,width=section_width
	TextBox/C/N=text0/F=0/Z=1/A=LT/X=0.5/Y=0.5/E=2 ("Set "+set_id+", Section "+num2str(morph_num)+", x = "+num2str(slice_num))
	// Red/Blue
	String image_name = "site_data_"+num2str(slice_num)+"_"+num2str(morph_num)
	ModifyImage $(image_name) explicit=1,eval={1,1,4,52428},eval={2,65535,0,0},eval={0,-1,-1,-1},eval={255,-1,-1,-1}
	ModifyGraph nticks=0
	if(ParamIsDefault(scalebar_size))
		scalebar_size = round(unit_size*Length*0.20/10)*10
	endif
	Variable scalebar_pnts = (section_width*scalebar_size/(unit_size*Length))
	ColorScale/C/N=text2/F=0/Z=1/B=1/A=LB/X=2.00/Y=2.00 vert=0,side=2,width=scalebar_pnts,height=13,image=$(image_name),ctab={0,100,Grays16,0},axisRange={0,1},nticks=0;DelayUpdate
	Variable indent_pct = 2 + 50*scalebar_pnts/section_width - 50*18/section_width
	TextBox/C/N=text3/F=0/Z=1/B=1/A=LB/X=(indent_pct)/Y=4.00 "\\f01"+num2str(scalebar_size)+" nm"
	SetDataFolder original_folder
End

Function IOPV_GraphDepthDataGUI()
	String set_id
	String original_folder = GetDataFolder(1)
	// Build the set list
	String set_list = ""
	SetDataFolder root:Ising_OPV:
	DFREF dfr1 = GetDataFolderDFR()
	Variable N_folders = CountObjectsDFR(dfr1,4)
	String folder_name
	Variable i
	for(i=0;i<N_folders;i+=1)
		folder_name = GetIndexedObjNameDFR(dfr1,4,i)
		SetDataFolder :$(folder_name)
		Wave composition_data = $"donor_composition"
		if(WaveExists(composition_data))
			set_list = AddListItem(folder_name,set_list)
		endif
		SetDataFolder ::
	endfor
	// Prompt user to choose the morphology set
	Prompt set_id, "Choose the morphology set:", popup, set_list
	DoPrompt "Make Selection",set_id
	// User cancelled operation
	if(V_flag==1)
		SetDataFolder original_folder
		return NaN
	endif
	Print "•IOPV_GraphDepthData(\""+set_id+"\")"
	IOPV_GraphDepthData(set_id)
	SetDataFolder original_folder
End

Function IOPV_GraphDepthData(set_id)
	String set_id
	String original_folder = GetDataFolder(1)
	SetDataFolder root:Ising_OPV:$set_id
	Wave domain_size
	Wave donor_composition
	Display/N=Depth_Data domain_size
	IOPV_GraphStyleLinLin()
	AppendToGraph/R donor_composition
	ModifyGraph margin(left)=28, margin(bottom)=26, margin(right)=40
	ModifyGraph tick=2,standoff=0
	ModifyGraph lsize=2,rgb(domain_size)=(0,0,65535),rgb(donor_composition)=(65535,0,0)
	Label left "Domain size (nm)"
	Label bottom "Film Depth, z-position"
	Label right "Donor Volume Fraction"
	TextBox/C/N=text0/F=0/Z=1/A=RT/X=5/Y=7/E=0 ("Set "+set_id)
	SetDataFolder original_folder
End

Function IOPV_GraphTortuosityHistsGUI()
	String set_id
	String original_folder = GetDataFolder(1)
	// Build the set list
	String set_list = ""
	SetDataFolder root:Ising_OPV:
	DFREF dfr1 = GetDataFolderDFR()
	Variable N_folders = CountObjectsDFR(dfr1,4)
	String folder_name
	Variable i
	for(i=0;i<N_folders;i+=1)
		folder_name = GetIndexedObjNameDFR(dfr1,4,i)
		SetDataFolder :$(folder_name)
		Wave tortuosity_data = $"tortuosity_hist1"
		if(WaveExists(tortuosity_data))
			set_list = AddListItem(folder_name,set_list)
		endif
		SetDataFolder ::
	endfor
	// Prompt user to choose the morphology set
	Prompt set_id, "Choose the morphology set:", popup, set_list
	DoPrompt "Make Selection",set_id
	// User cancelled operation
	if(V_flag==1)
		SetDataFolder original_folder
		return NaN
	endif
	Print "•IOPV_GraphTortuosityHistograms(\""+set_id+"\")"
	IOPV_GraphTortuosityHistograms(set_id)
	SetDataFolder original_folder
End

Function IOPV_GraphTortuosityHistograms(set_id) : Graph
	String set_id
	String original_folder = GetDataFolder(1)
	SetDataFolder root:Ising_OPV:$set_id
	Wave tortuosity_hist1, tortuosity_hist2
	Display/N=Tortuosity_Histograms tortuosity_hist1,tortuosity_hist2
	IOPV_GraphStyleLinLin()
	ModifyGraph margin(bottom)=25
	SetAxis bottom 1,*
	ModifyGraph mode=5,hbFill=2,useBarStrokeRGB=1
	ModifyGraph rgb(tortuosity_hist1)=(1,4,52428),rgb(tortuosity_hist2)=(52428,1,1)
	ModifyGraph offset={-0.006,0}
	Label left "Probability"
	Label bottom "Tortuosity"
	TextBox/C/N=text0/F=0/Z=1/A=RT/X=5/Y=7/E=0 ("Set "+set_id)
	SetDataFolder original_folder
End

Function IOPV_GraphTortuosityMapsGUI()
	String original_folder = GetDataFolder(1)
	// Get path to set from user
	NewPath/O/Q/M="Choose morphology set folder" set_path
	if(V_flag!=0)
		SetDataFolder original_folder
		return NaN
	endif
	// Get morphology set id name
	PathInfo set_path
	String path_string = S_path
	String set_id = ParseFilePath(0,path_string,":",1,0)
	// Load set info
	LoadWave/N=stringWave/J/K=2/P=set_path/Q "analysis_summary.txt"
	Wave/T stringWave0
	int Length = str2num(StringFromList(0,stringWave0[2],","))
	int morph_num_max = str2num(StringFromList(8,stringWave0[0]," "))-1
	// Cleanup
	KillWaves stringWave0
	KillPath set_path
	// Get info from user
	Variable morph_num
	Variable unit_size=1
	Variable scale_size
	Prompt morph_num, "Enter a morphology section number (0-"+num2str(morph_num_max)+")"
	Prompt unit_size, "Enter the pixel size (nm)"
	Prompt scale_size, "(Optional) Enter the scalebar size (nm):"
	DoPrompt "Enter Cross Section Information:", morph_num, unit_size, scale_size
	// User cancelled operation
	if(V_flag==1)
		SetDataFolder original_folder
		return NaN
	endif
	// Check for valid user input
	if(morph_num<0 || morph_num>=morph_num_max)
		V_flag = -1
	endif
	if(!(unit_size>0))
		V_flag = -1
	endif
	if(scale_size<0)
		V_flag = -1
	endif
	if(V_flag==-1)
		DoAlert 0, "Invalid Entry! Try again."
		SetDataFolder original_folder
		return NaN
	endif
	SetDataFolder original_folder
	// Graph the cross section image
	if(scale_size==0)
		Print "•IOPV_GraphTortuosityMaps("+num2str(unit_size)+",\""+path_string+"\","+num2str(morph_num)+")"
		IOPV_GraphTortuosityMaps(unit_size,path_string,morph_num)
	else
		Print "•IOPV_GraphTortuosityMaps("+num2str(unit_size)+",\""+path_string+"\","+num2str(morph_num)+",scalebar_size="+num2str(scale_size)+")"
		IOPV_GraphTortuosityMaps(unit_size,path_string,morph_num,scalebar_size=scale_size)
	endif
End

Function IOPV_GraphTortuosityMaps(unit_size,path_str,morph_num,[scalebar_size]) : Graph
	Variable unit_size
	String path_str
	int morph_num
	Variable scalebar_size
	String original_folder = GetDataFolder(1)
	String set_id = StringFromList(ItemsInList(path_str,":")-1,path_str,":")
	SetDataFolder root:
	NewDataFolder/O/S Ising_OPV
	NewDataFolder/O/S $(set_id)
	NewPath/O/Q tempPath, path_str
	LoadWave/J/W/A/K=0/L={0,1,0,0,0}/P=tempPath/Q "areal_tortuosity_map_"+num2str(morph_num)+".txt"
	KillPath tempPath
	Wave X_Position
	Wave Y_Position
	Wave Tortuosity1
	Wave Tortuosity2
	WaveStats/Q X_Position
	int X_max = V_max+1
	WaveStats/Q Y_Position
	int Y_max = V_max+1
	Make/O/N=(X_max,Y_max) $("tortuosity_map1_"+num2str(morph_num)), $("tortuosity_map2_"+num2str(morph_num))
	Wave tortuosity_map1 = $("tortuosity_map1_"+num2str(morph_num))
	Wave tortuosity_map2 = $("tortuosity_map2_"+num2str(morph_num))
	int i
	for(i=0;i<numpnts(Tortuosity1);i+=1)
		tortuosity_map1[X_Position[i]][Y_Position[i]] = Tortuosity1[i]
		tortuosity_map2[X_Position[i]][Y_Position[i]] = Tortuosity2[i]
	endfor
	// Tortuosity Map 1
	NewImage/S=0/N=Tortuosity_Map tortuosity_map1;DelayUpdate
	ModifyImage $("tortuosity_map1_"+num2str(morph_num)) ctab={1,1.4,Blue,0},minRGB=(26214,0,0),maxRGB=0
	SetAxis/A left
	IOPV_GraphStyleLinLin()
	ModifyGraph width=200,height=200
	ModifyGraph tick=3,noLabel=2
	ModifyGraph margin(left)=2,margin(bottom)=2,margin(right)=45,margin(top)=12
	TextBox/C/N=text0/F=0/A=LT/X=1.00/Y=1.00/E=2/Z=1 ("Set "+set_id+", Section "+num2str(morph_num))
	ColorScale/C/N=text1/F=0/A=RT/X=0.5/Y=5.00/E=2 width=10,heightPct=35,image=$("tortuosity_map1_"+num2str(morph_num)),lblMargin=1,nticks=4,tickLen=4.00;DelayUpdate
	ColorScale/C/N=text1 "Donor Tortuosity"
	if(ParamIsDefault(scalebar_size))
		scalebar_size = round(unit_size*X_max*0.20/10)*10
	endif
	Variable scalebar_pnts = (200*scalebar_size/(unit_size*X_max))
	ColorScale/C/N=text2/F=0/Z=1/B=1/A=LB/X=2.00/Y=2.00 vert=0,side=2,width=scalebar_pnts,height=13,image=$("tortuosity_map1_"+num2str(morph_num)),axisRange={1.3999,1.4},nticks=0;DelayUpdate
	Variable indent_pct = 2 + 50*scalebar_pnts/200 - 50*18/200
	TextBox/C/N=text3/F=0/Z=1/B=1/A=LB/X=(indent_pct)/Y=4.00 "\\f01"+num2str(scalebar_size)+" nm"
	// Tortuosity Map 2
	NewImage/S=0/N=Tortuosity_Map tortuosity_map2;DelayUpdate
	ModifyImage $("tortuosity_map2_"+num2str(morph_num)) ctab= {1,1.4,Red,0},minRGB=(0,2,26214),maxRGB=0
	SetAxis/A left
	IOPV_GraphStyleLinLin()
	ModifyGraph width=200,height=200
	ModifyGraph tick=3,noLabel=2
	ModifyGraph margin(left)=2,margin(bottom)=2,margin(right)=45,margin(top)=12
	TextBox/C/N=text0/F=0/A=LT/X=1.00/Y=1.00/E=2/Z=1 ("Set "+set_id+", Section "+num2str(morph_num))
	ColorScale/C/N=text1/F=0/A=RT/X=0.50/Y=5.00/E=2 width=10,heightPct=35,image=$("tortuosity_map2_"+num2str(morph_num)),lblMargin=1,nticks=4,tickLen=4.00;DelayUpdate
	ColorScale/C/N=text1 "Acceptor Tortuosity"
	ColorScale/C/N=text2/F=0/Z=1/B=1/A=LB/X=2.00/Y=2.00 vert=0,side=2,width=scalebar_pnts,height=13,image=$("tortuosity_map2_"+num2str(morph_num)),axisRange={1.3999,1.4},nticks=0;DelayUpdate
	TextBox/C/N=text3/F=0/Z=1/B=1/A=LB/X=(indent_pct)/Y=4.00 "\\f01"+num2str(scalebar_size)+" nm"
	// Cleanup
	KillWaves X_Position Y_Position Tortuosity1 Tortuosity2 
	SetDataFolder original_folder
End

Function IOPV_GraphStyleLinLin() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z gfSize=8,expand=1.5, width=198.425,height=141.732
	ModifyGraph/Z log=0
	ModifyGraph/Z margin(left)=34,margin(bottom)=31,margin(top)=8,margin(right)=8
	ModifyGraph/Z tick=2,mirror=1,standoff=0
End

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
