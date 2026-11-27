// Copyright 2026 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include <gtest/gtest.h>

#include <string>

#include "Common/CommonPaths.h"
#include "Common/Config/Config.h"
#include "Common/FileUtil.h"
#include "Common/IOFile.h"
#include "Core/Config/GraphicsSettings.h"
#include "Core/ConfigLoaders/BaseConfigLoader.h"
#include "Core/ConfigManager.h"
#include "UICommon/UICommon.h"
#include "VideoCommon/VideoConfig.h"

namespace
{
class ConfigTestScope final
{
public:
  ConfigTestScope() : m_user_dir(File::CreateTempDir())
  {
    UICommon::SetUserDirectory(m_user_dir);
    Config::Init();
    Config::AddLayer(ConfigLoaders::GenerateBaseConfigLoader());
    SConfig::Init();
  }

  ~ConfigTestScope()
  {
    SConfig::Shutdown();
    Config::Shutdown();
    if (!m_user_dir.empty())
      File::DeleteDirRecursively(m_user_dir);
  }

  const std::string& UserDir() const { return m_user_dir; }

private:
  std::string m_user_dir;
};
}  // namespace

TEST(VRImmersiveDefaults, DefaultsDifferWithoutLocks)
{
  ConfigTestScope scope;
  ASSERT_FALSE(scope.UserDir().empty());

  // Unset keys use Immersive VR defaults when immersive_vr is true, and global defaults otherwise.
  EXPECT_TRUE(GetVRExactScreenDepth(false));
  EXPECT_EQ(GetVRAutoNativeEfbEffects(false),
            Config::GFX_VR_AUTO_NATIVE_EFB_EFFECTS.GetDefaultValue());
  EXPECT_FALSE(GetVRExactScreenDepth(true));
  EXPECT_TRUE(GetVRAutoNativeEfbEffects(true));

  // Explicit Base (GFX.ini) values take precedence over Immersive defaults.
  Config::SetBase(Config::GFX_VR_EXACT_SCREEN_DEPTH, true);
  Config::SetBase(Config::GFX_VR_AUTO_NATIVE_EFB_EFFECTS, false);
  EXPECT_TRUE(GetVRExactScreenDepth(true));
  EXPECT_FALSE(GetVRAutoNativeEfbEffects(true));

  // Deleting keys from Base (as VR Reset does) restores Immersive defaults.
  Config::DeleteKey(Config::LayerType::Base, Config::GFX_VR_EXACT_SCREEN_DEPTH);
  Config::DeleteKey(Config::LayerType::Base, Config::GFX_VR_AUTO_NATIVE_EFB_EFFECTS);
  EXPECT_FALSE(GetVRExactScreenDepth(true));
  EXPECT_TRUE(GetVRAutoNativeEfbEffects(true));
  EXPECT_TRUE(GetVRExactScreenDepth(false));
}

TEST(VRImmersiveDefaults, PerGameCurrentRunOverridesBaseAndImmersiveDefaults)
{
  ConfigTestScope scope;
  ASSERT_FALSE(scope.UserDir().empty());

  // Simulates a user per-game VR override (e.g. Pikmin 2 turning Exact Screen Depth on).
  Config::SetBase(Config::GFX_VR_PRESENTATION_MODE, OpenXRPresentationMode::Immersive);
  Config::SetCurrent(Config::GFX_VR_EXACT_SCREEN_DEPTH, true);
  Config::SetCurrent(Config::GFX_VR_AUTO_NATIVE_EFB_EFFECTS, false);

  g_Config.Refresh();
  EXPECT_TRUE(g_Config.vr_exact_screen_depth);
  EXPECT_FALSE(g_Config.vr_auto_native_efb_effects);

  // Clearing per-game overrides restores Immersive defaults on refresh.
  Config::DeleteKey(Config::LayerType::CurrentRun, Config::GFX_VR_EXACT_SCREEN_DEPTH);
  Config::DeleteKey(Config::LayerType::CurrentRun, Config::GFX_VR_AUTO_NATIVE_EFB_EFFECTS);

  g_Config.Refresh();
  EXPECT_FALSE(g_Config.vr_exact_screen_depth);
  EXPECT_TRUE(g_Config.vr_auto_native_efb_effects);
}

#ifdef BAIJI_STEAMVR
TEST(VRImmersiveDefaults, BundledProfileSkippedInImmersiveButUserProfileWins)
{
  ConfigTestScope scope;
  ASSERT_FALSE(scope.UserDir().empty());

  // Linux builds read Sys from the install path unless built with LINUX_LOCAL_DEV, so without it the
  // bundled profile is never loaded and this test would pass whatever ApplyGameVRConfigOverrides does.
  if (!File::Exists(File::GetSysDirectory() + GAMESETTINGSVR_DIR DIR_SEP "GMBE8P.ini"))
  {
    GTEST_SKIP() << "Bundled Sys/GameSettingsVR not found at " << File::GetSysDirectory()
                 << " (on Linux, build with -DLINUX_LOCAL_DEV=ON or install first).";
  }

  // GMBE8P has a bundled Sys/GameSettingsVR/GMBE8P.ini with ExactScreenDepth = True.
  // In Immersive VR, the bundled value must NOT override Immersive's default (false).
  Config::SetBase(Config::GFX_VR_PRESENTATION_MODE, OpenXRPresentationMode::Immersive);
  SConfig::GetInstance().SetRunningGameMetadata("GMBE8P");
  g_Config.Refresh();
  EXPECT_FALSE(g_Config.vr_exact_screen_depth);

  // In Stereo Screen, the bundled profile applies normally (true, which is also the global default).
  Config::SetBase(Config::GFX_VR_PRESENTATION_MODE, OpenXRPresentationMode::StereoScreen);
  SConfig::GetInstance().ReloadGameVRConfigOverrides();
  g_Config.Refresh();
  EXPECT_TRUE(g_Config.vr_exact_screen_depth);

  // A user GameSettingsVR file for GMBE8P DOES win in Immersive VR.
  const std::string user_vr_dir = File::GetUserPath(D_GAMESETTINGSVR_IDX);
  ASSERT_TRUE(File::CreateFullPath(user_vr_dir));
  ASSERT_TRUE(File::WriteStringToFile(
      user_vr_dir + "GMBE8P.ini",
      "[Graphics.VR]\nExactScreenDepth = True\nAutoNativeEfbEffects = False\n"));

  Config::SetBase(Config::GFX_VR_PRESENTATION_MODE, OpenXRPresentationMode::Immersive);
  SConfig::GetInstance().ReloadGameVRConfigOverrides();
  g_Config.Refresh();
  EXPECT_TRUE(g_Config.vr_exact_screen_depth);
  EXPECT_FALSE(g_Config.vr_auto_native_efb_effects);

  SConfig::GetInstance().ResetRunningGameMetadata();
}
#endif
