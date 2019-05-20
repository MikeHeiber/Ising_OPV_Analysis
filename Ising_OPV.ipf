#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 6.3 // Minimum Igor version required
#pragma version = 1.0-beta.1

// Copyright (c) 2018-2019 Michael C. Heiber
// This source file is part of the Ising_OPV_Analysis project, which is subject to the MIT License.
// For more information, see the LICENSE file that accompanies this software.
// The Ising_OPV_Analysis project can be found on Github at https://github.com/MikeHeiber/Ising_OPV_Analysis

#include <KBColorizeTraces>

Menu "Ising_OPV"
	"Import Morphology Set", /Q, IOPV_ImportMorphologySetGUI()
	"Graph Composition Map", /Q, IOPV_GraphCompositionMapGUI()
	"Graph Cross Section", /Q, IOPV_GraphCrossSectionGUI()
	"Graph Film Depth Data", /Q, IOPV_GraphDepthDataGUI()
	"Graph Tortuosity Map", /Q, IOPV_GraphTortuosityMapsGUI()
	"Graph Tortusity Histograms", /Q, IOPV_GraphTortuosityHistsGUI()	
End

Window IOPV_Morphology_Table() : Table
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Ising_OPV:
	Edit/W=(396.75,85.25,1848.75,584) version_name,job_name,tomo_set,calc_time_avg,calc_time_stdev
	AppendToTable N_morphologies,Length,Width,Height,blend_ratio_avg,blend_ratio_stdev
	AppendToTable domain1_size_avg,domain1_size_stdev,domain2_size_avg,domain2_size_stdev
	AppendToTable domain1_anisotropy_avg,domain1_anisotropy_stdev,domain2_anisotropy_avg
	AppendToTable domain2_anisotropy_stdev,tortuosity1_avg,tortuosity1_stdev,tortuosity2_avg
	AppendToTable tortuosity2_stdev,iav_ratio_avg,iav_ratio_stdev,island_frac1_avg,island_frac1_stdev
	AppendToTable island_frac2_avg,island_frac2_stdev,iv_frac_avg,iv_frac_stdev
	ModifyTable format(Point)=1,width(Point)=35,width(version_name)=71,width(job_name)=54
	ModifyTable width(tomo_set)=95,width(calc_time_avg)=74,width(calc_time_stdev)=82
	ModifyTable width(N_morphologies)=82,width(Length)=41,width(Width)=38,width(Height)=40
	ModifyTable width(domain1_size_avg)=92,width(domain1_size_stdev)=100,width(domain2_size_avg)=92
	ModifyTable width(domain2_size_stdev)=100,width(domain1_anisotropy_avg)=119,width(domain1_anisotropy_stdev)=127
	ModifyTable width(domain2_anisotropy_avg)=119,width(domain2_anisotropy_stdev)=127
	SetDataFolder fldrSav0
EndMacro
