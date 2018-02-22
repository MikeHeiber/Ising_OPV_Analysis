#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion = 6.3 // Minimum Igor version required
#pragma version = 0.1-alpha

// Copyright (c) 2018 Michael C. Heiber
// This source file is part of the Ising_OPV_Analysis project, which is subject to the MIT License.
// For more information, see the LICENSE file that accompanies this software.
// The Ising_OPV_Analysis project can be found on Github at https://github.com/MikeHeiber/Ising_OPV_Analysis

#include <KBColorizeTraces>

Menu "Ising_OPV"
	"Import Morphology Set", /Q, IOPV_ImportMorphologySet()
End