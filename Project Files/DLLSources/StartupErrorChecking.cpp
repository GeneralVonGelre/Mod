#include "CvGameCoreDll.h"
#include "AlertWindow.h"
#include "StartupErrorChecking.h"

#include <iostream>
#include <sstream>
#include <fstream>

enum WindowType
{
	WINDOW_DLL_LOCATION,
	WINDOW_NO_INI_FILE,
	WINDOW_PUBLIC_MAPS_DISABLED,
};

template <int T>
static AlertWindow::returnTypes showWindow()
{
	// only specialized templates should be used
	BOOST_STATIC_ASSERT(0);
}

template <int T>
static AlertWindow::returnTypes showWindow(const char*)
{
	// only specialized templates should be used
	BOOST_STATIC_ASSERT(0);
}

template <int T>
static AlertWindow::returnTypes showWindow(const char*, int, int)
{
	// only specialized templates should be used
	BOOST_STATIC_ASSERT(0);
}


template <>
static AlertWindow::returnTypes showWindow<WINDOW_DLL_LOCATION>()
{
	AlertWindow window;

	window.header = "TXT_KEY_ALERT_MOD_IN_DOCUMENTS_HEADER";
	window.message = "TXT_KEY_ALERT_MOD_IN_DOCUMENTS";
	window.setIcon(AlertWindow::iconTypes::IconError);
	window.setButtonLayout(AlertWindow::Buttons::BtnAboutRetryIgnore);
	return window.openWindow();
}

template <>
static AlertWindow::returnTypes showWindow<WINDOW_NO_INI_FILE>(const char* iniFile)
{
	AlertWindow window;

	window.header = "TXT_KEY_ALERT_CONFIGURATION_ERROR_HEADER";
	window.message = "TXT_KEY_ALERT_CONFIGURATION_ERROR";
	window.setIcon(AlertWindow::iconTypes::IconError);
	window.setButtonLayout(AlertWindow::Buttons::BtnAboutRetryIgnore);
	window.addArgument(iniFile);
	return window.openWindow();
}

template <>
static AlertWindow::returnTypes showWindow<WINDOW_PUBLIC_MAPS_DISABLED>()
{
	AlertWindow window;

	window.header = "TXT_KEY_ALERT_PUBLIC_MAPS_DISABLED_HEADER";
	window.message = "TXT_KEY_ALERT_PUBLIC_MAPS_DISABLED";
	window.setButtonLayout(AlertWindow::Buttons::BtnYesNo);
	return window.openWindow();
}


static void TestDLLLocation()
{
	std::string name_exe = GetDLLPath(false);
	std::string name_dll = GetDLLPath(true);
	name_dll.resize(name_exe.size());

	if (name_exe != name_dll)
	{
		AlertWindow::returnTypes returnValue = showWindow<WINDOW_DLL_LOCATION>();
		if (returnValue.getVar() == returnValue.clickedAbout)
		{
			exit(1);
		}
	}
}

static void checkPublicMapSetting()
{
	const std::string modPath = gDLL->getModName();
	const std::string modName = modPath.substr(5, modPath.length() - 6);
	const std::string iniFile = modPath + modName + ".ini";

	std::vector<std::string> file_content;

	try
	{
		std::ifstream input(iniFile.c_str());
		std::stringstream buffer;
		buffer << input.rdbuf();
		input.close();

		for (std::string line; std::getline(buffer, line); )
		{
			file_content.push_back(line);
			if (line.substr(0, 15) == "AllowPublicMaps")
			{
				if (line == "AllowPublicMaps = 0")
				{
					return;
				}
			}
		}
	}
	catch (const std::exception&)
	{
		// make the game silently ignore file read crashes
		return;
	}

	try
	{
		std::ofstream output(iniFile.c_str());
		for (unsigned i = 0; i < file_content.size(); i++)
		{
			const std::string& line = file_content[i];
			if (line.substr(0, 15) == "AllowPublicMaps")
			{
				output << "AllowPublicMaps = 0" << std::endl;
			}
			else
			{
				output << line << std::endl;
			}
		}
		output.close();
	}
	catch (const std::exception&)
	{
		AlertWindow::returnTypes returnVal = showWindow<WINDOW_NO_INI_FILE>(iniFile.c_str());
		switch (returnVal.getVar())
		{
		case AlertWindow::returnTypes::clickedAbout: exit(0);
		case AlertWindow::returnTypes::clickedRetry: 
			checkPublicMapSetting();
			return;
		case AlertWindow::returnTypes::clickedIgnore:
			break;
		default:
			FAssertMsg(0, "Unmatched case");
		}

		return;
	}

	{
		AlertWindow::returnTypes returnVal = showWindow<WINDOW_PUBLIC_MAPS_DISABLED>();
		if (returnVal.getVar() == returnVal.clickedYes)
		{
			exit(0);
		}
	}
}


namespace StartupCheck
{
	void testAllWindows()
	{
		showWindow<WINDOW_DLL_LOCATION>();
		showWindow<WINDOW_NO_INI_FILE>("test file");
		showWindow<WINDOW_PUBLIC_MAPS_DISABLED>();
	}

	void GlobalInitXMLCheck()
	{
		FAssert(gDLL != NULL);
		TestDLLLocation();
		checkPublicMapSetting();
	}
}
