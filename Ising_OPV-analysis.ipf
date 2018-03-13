#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 6.3 // Minimum Igor version required
#pragma version = 0.1-alpha

// Copyright (c) 2018 Michael C. Heiber
// This source file is part of the Ising_OPV_Analysis project, which is subject to the MIT License.
// For more information, see the LICENSE file that accompanies this software.
// The Ising_OPV_Analysis project can be found on Github at https://github.com/MikeHeiber/Ising_OPV_Analysis

Function IOPV_BinaryConverter()
	String original_folder = GetDataFolder(1)
	// Get path to set from user
	NewPath/O/Q/M="Choose morphology set folder" set_path
	if(V_flag!=0)
		return NaN
	endif
	PathInfo set_path
	String path_string = S_path
	String set_id = ParseFilePath(0,path_string,":",1,0)
	// Setup data folder
	NewDataFolder/O/S root:Ising_OPV
	NewDataFolder/O/S $(set_id)
	// Choose morphology
	Variable morph_num = 0
	// Load morphology file
	LoadWave/N=tempWave/D/J/K=1/L={0,0,0,0,0}/O/P=set_path/Q "morphology_"+num2str(morph_num)+".txt"
	Wave tempWave0 = $("tempWave0")
	WaveStats/Q tempWave0
	Variable size = V_npnts
	Variable Length = tempWave0[1]
	Variable Width = tempWave0[2]
	Variable Height = tempWave0[3]
	Variable Num_types = tempWave0[7]
	Make/O/I/N=(Num_types) counts = 0
	Variable x
	Variable y
	Variable z
	Variable i = 8+2*Num_types
	Variable site_type
	Variable site_count = 0
	// Load morphology data into 3D wave
	Make/B/U/N=(Length,Width,Height)/O data
	for(x=0;x<Length;x+=1)
		for(y=0;y<Width;y+=1)
			for(z=0;z<Height;z+=1)
				if(site_count==0 && i<size)
					site_type = trunc(tempWave0[i]/(10^(strlen(num2str(tempWave0[i]))-1)))
					site_count = tempWave0[i]-site_type*(10^(strlen(num2str(tempWave0[i]))-1))
					i += 1
				endif
				data[x][y][z] = site_type
				site_count -= 1
			endfor
		endfor
	endfor
	// Output data to binary file
	Variable refnum
	Open/P=set_path refnum as "morphology"+num2str(morph_num)+"_"+num2str(Length)+"x"+num2str(Width)+"x"+num2str(Height)+"_16bit.raw"
	for(z=0;z<Height;z+=1)
		for(x=0;x<Length;x+=1)
			for(y=0;y<Width;y+=1)
				int type = data[x][y][z]
				FBinWrite/F=1/U refnum, type
			endfor
		endfor
	endfor
	// Close File
	Close refnum
	// Cleanup
	KillPath set_path
	KillWaves tempWave0 counts data
	SetDataFolder original_folder
End

Function IOPV_ImportMorphologySet()
	String original_folder = GetDataFolder(1)
	// Get path to set from user
	NewPath/O/Q/M="Choose morphology set folder" set_path
	if(V_flag!=0)
		return NaN
	endif
	// Get set import mode from the user
	String menu_list = "Import Full Set Data;Import Set Summary"
	Variable import_mode
	Prompt import_mode, "Import mode:", popup, menu_list
	DoPrompt "Choose a morphology set import mode:" import_mode
	import_mode -= 1
	// Get set id name
	PathInfo set_path
	String path_string = S_path
	String set_id = ParseFilePath(0,path_string,":",1,0)
	KillPath set_path
	// Setup data folder
	NewDataFolder/O/S root:Ising_OPV
	// Import Morphology Data
	IOPV_ImportMorphologyData(set_id,path_string,import_mode)
	// Cleanup
	SetDataFolder original_folder
End

Function IOPV_ImportMorphologyData(set_id,path_string,mode)
	String set_id
	String path_string
	Variable mode
	if(mode>1)
		Print "Error Importing Morphology Set!  Invalid data import mode."
	endif
	String original_folder = GetDataFolder(1)
	SetDataFolder root:Ising_OPV
	// Setup job table
	Variable target_index
	Wave/T job_name
	if(!WaveExists(job_name))
		target_index = 0
		Make/T/N=1 job_name
		Make/T/N=1 version_name
		Make/T/N=1 tomo_set
		Make/D/N=1 N_morphologies
		Make/D/N=1 Length
		Make/D/N=1 Width
		Make/D/N=1 Height
		Make/D/N=1 blend_ratio_avg
		Make/D/N=1 blend_ratio_stdev
		Make/D/N=1 domain1_size_avg
		Make/D/N=1 domain1_size_stdev
		Make/D/N=1 domain2_size_avg
		Make/D/N=1 domain2_size_stdev
		Make/D/N=1 domain1_anisotropy_avg
		Make/D/N=1 domain1_anisotropy_stdev
		Make/D/N=1 domain2_anisotropy_avg
		Make/D/N=1 domain2_anisotropy_stdev
		Make/D/N=1 iav_ratio_avg
		Make/D/N=1 iav_ratio_stdev
		Make/D/N=1 iv_frac_avg
		Make/D/N=1 iv_frac_stdev
		Make/D/N=1 tortuosity1_avg
		Make/D/N=1 tortuosity1_stdev
		Make/D/N=1 tortuosity2_avg
		Make/D/N=1 tortuosity2_stdev
		Make/D/N=1 island_frac1_avg
		Make/D/N=1 island_frac1_stdev
		Make/D/N=1 island_frac2_avg
		Make/D/N=1 island_frac2_stdev
		Make/D/N=1 calc_time_avg
		Make/D/N=1 calc_time_stdev
	else
		Wave/T version_name
		Wave/T tomo_set
		Wave/D N_morphologies
		Wave/D Length
		Wave/D Width
		Wave/D Height
		Wave/D blend_ratio_avg
		Wave/D blend_ratio_stdev
		Wave/D domain1_size_avg
		Wave/D domain1_size_stdev
		Wave/D domain2_size_avg
		Wave/D domain2_size_stdev
		Wave/D domain1_anisotropy_avg
		Wave/D domain1_anisotropy_stdev
		Wave/D domain2_anisotropy_avg
		Wave/D domain2_anisotropy_stdev
		Wave/D iav_ratio_avg
		Wave/D iav_ratio_stdev
		Wave/D iv_frac_avg
		Wave/D iv_frac_stdev
		Wave/D tortuosity1_avg
		Wave/D tortuosity1_stdev
		Wave/D tortuosity2_avg
		Wave/D tortuosity2_stdev
		Wave/D island_frac1_avg
		Wave/D island_frac1_stdev
		Wave/D island_frac2_avg
		Wave/D island_frac2_stdev
		Wave/D calc_time_avg
		Wave/D calc_time_stdev
		FindValue /TEXT=(set_id) /TXOP=2 job_name
		target_index = V_value
		if(target_index==-1)
			target_index = numpnts(job_name)
		endif	
	endif
	NewPath/O/Q set_path, path_string
	// Load morphology set data files
	if(mode==0)
		NewDataFolder/O/S $(set_id)
		LoadWave/N=tempWave/D/J/K=1/L={0,0,0,0,0}/O/P=set_path/Q "interfacial_distance_histograms.txt"
		Duplicate/O $("tempWave1") interface_dist_hist1
		Duplicate/O $("tempWave2") interface_dist_hist2
		LoadWave/N=tempWave/D/J/K=1/L={0,0,0,0,0}/O/P=set_path/Q "tortuosity_histograms.txt"
		Duplicate/O $("tempWave1") tortuosity_hist1
		Duplicate/O $("tempWave2") tortuosity_hist2
		LoadWave/N=tempWave/D/J/K=1/L={0,0,0,0,0}/O/P=set_path/Q "correlation_data_avg.txt"
		Duplicate/O $("tempWave1") correlation1
		Duplicate/O $("tempWave2") correlation2
		KillWaves $"tempWave0" $"tempWave1" $"tempWave2"
	endif
	String file_list = IndexedFile(set_path,-1,".txt")
	String analysis_filename
	if(ItemsInList(file_list))
		analysis_filename = StringFromList(0,ListMatch(file_list,"analysis_summary*"))
	else
		Print "Error! Parameter file not found!"
		return NaN
	endif
	LoadWave/N=stringWave/J/K=2/P=set_path/Q analysis_filename
	Wave/T stringWave0
	LoadWave/N=tempWave/D/J/K=1/L={0,2,0,0,0}/O/P=set_path/Q/M analysis_filename
	Wave tempWave0
	Variable N_morphs = str2num(StringFromList(0,StringFromList(1,stringWave0[0],"containing ")," "))
	String version = RemoveEnding(StringFromList(1,stringWave0[0],"Ising_OPV v"))
	if(StringMatch(stringWave0[numpnts(stringWave0)-1],"Morphologies imported from tomogram file*"))
		tomo_set[target_index] = {StringFromList(1,stringWave0[numpnts(stringWave0)-1],": ")}
	else
		tomo_set[target_index] = "N/A"
	endif
	job_name[target_index] = {set_id}
	version_name[target_index] = {version}
	N_morphologies[target_index] = {N_morphs}
	Length[target_index] = {tempWave0[0][0]}
	Width[target_index] = {tempWave0[0][1]}
	Height[target_index] = {tempWave0[0][2]}
	blend_ratio_avg[target_index] = {tempWave0[0][3]}
	blend_ratio_stdev[target_index] = {tempWave0[0][4]}
	domain1_size_avg[target_index] = {tempWave0[0][5]}
	domain1_size_stdev[target_index] = {tempWave0[0][6]}
	domain2_size_avg[target_index] = {tempWave0[0][7]}
	domain2_size_stdev[target_index] = {tempWave0[0][8]}
	domain1_anisotropy_avg[target_index] = {tempWave0[0][9]}
	domain1_anisotropy_stdev[target_index] = {tempWave0[0][10]}
	domain2_anisotropy_avg[target_index] = {tempWave0[0][11]}
	domain2_anisotropy_stdev[target_index] = {tempWave0[0][12]}
	iav_ratio_avg[target_index] = {tempWave0[0][13]}
	iav_ratio_stdev[target_index] = {tempWave0[0][14]}
	iv_frac_avg[target_index] = {tempWave0[0][15]}
	iv_frac_stdev[target_index] = {tempWave0[0][16]}
	tortuosity1_avg[target_index] = {tempWave0[0][17]}
	tortuosity1_stdev[target_index] = {tempWave0[0][18]}
	tortuosity2_avg[target_index] = {tempWave0[0][19]}
	tortuosity2_stdev[target_index] = {tempWave0[0][20]}
	island_frac1_avg[target_index] = {tempWave0[0][21]}
	island_frac1_stdev[target_index] = {tempWave0[0][22]}
	island_frac2_avg[target_index] = {tempWave0[0][23]}
	island_frac2_stdev[target_index] = {tempWave0[0][24]}
	calc_time_avg[target_index] = {tempWave0[0][25]}
	calc_time_stdev[target_index] = {tempWave0[0][26]}
	// Graph a cross sectional image
	PathInfo	set_path
	IOPV_GraphCrossSection(floor(Width[target_index]/2+0.5),1.0,path_str=S_path,morph_num=0)
	// Cleanup
	KillPath set_path
	KillWaves stringWave0
	SetDataFolder original_folder
End