// SPDX-FileCopyrightText: 2022 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

version 4.8

class fm_EventHandler : EventHandler
{
  override void WorldTick()
  {
    if (!mIsInitialized) initialize();

    if (fm_damage_limit_enabled != mLastDamageLimitEnabled || fm_damage_limit != mLastDamageLimit)
    {
      updateDamageLimit();
    }

    if (fm_damage_leak_enabled != mLastDamageLeakEnabled)
    {
      updateDamageLeak();
    }

    mDamageInformation = getDamageInformation();
  }

  override void NetWorkProcess(ConsoleEvent event)
  {
    if (event == NULL || event.player != consolePlayer) return;

    if      (event.name == "fm_detector_on" )    mDamageDetectionEnabled = true;
    else if (event.name == "fm_detector_off")    mDamageDetectionEnabled = false;
    else if (event.name == "fm_detector_toggle") mDamageDetectionEnabled = !mDamageDetectionEnabled;
  }

  override void RenderOverlay(RenderEvent event)
  {
    if (mDamageInformation.length() == 0) return;

    Font aFont = NewConsoleFont;
    let scaleVector = StatusBar.getHudScale();
    double scale = scaleVector.x;
    double x = int(0.5 * (Screen.getWidth()  - scale * aFont.stringWidth(mDamageInformation)));
    double y = int(0.1 * (Screen.getHeight() - scale * aFont.getHeight()));

    Screen.drawText( NewConsoleFont, Font.CR_White, x, y, mDamageInformation
                   , DTA_ScaleX, scale
                   , DTA_ScaleY, scale
                   );
  }

// private: ////////////////////////////////////////////////////////////////////////////////////////

  private void initialize()
  {
    mIsInitialized = true;

    int sectorsCount = level.sectors.size();
    for (int i = 0; i < sectorsCount; ++i)
    {
      Sector aSector = level.sectors[i];

      if (aSector.damageType == 'None') continue;

      mDamagingSectorsIndices.push(i);
      mDamagingSectorsOriginalDamage.push(aSector.damageAmount);
      mDamagingSectorsOriginalLeak.push(aSector.leakyDamage);
    }

    updateDamageLimit();
    updateDamageLeak();
  }

  private void updateDamageLimit()
  {
    mLastDamageLimitEnabled = fm_damage_limit_enabled;
    mLastDamageLimit        = fm_damage_limit;

    if (fm_damage_limit_enabled) applyDamageLimit();
    else restoreDamage();
  }

  private void applyDamageLimit()
  {
    int sectorsCount = mDamagingSectorsIndices.size();
    for (int i = 0; i < sectorsCount; ++i)
    {
      Sector aSector = level.sectors[mDamagingSectorsIndices[i]];
      int originalDamage = mDamagingSectorsOriginalDamage[i];
      aSector.damageAmount = min(originalDamage, fm_damage_limit);
    }
  }

  private void restoreDamage()
  {
    int sectorsCount = mDamagingSectorsIndices.size();
    for (int i = 0; i < sectorsCount; ++i)
    {
      Sector aSector = level.sectors[mDamagingSectorsIndices[i]];
      aSector.damageAmount = mDamagingSectorsOriginalDamage[i];
    }
  }

  private void updateDamageLeak()
  {
    mLastDamageLeakEnabled = fm_damage_leak_enabled;

    if (fm_damage_leak_enabled) restoreDamageLeak();
    else disableDamageLeak();
  }

  private void restoreDamageLeak()
  {
    int sectorsCount = mDamagingSectorsIndices.size();
    for (int i = 0; i < sectorsCount; ++i)
    {
      Sector aSector = level.sectors[mDamagingSectorsIndices[i]];
      aSector.leakyDamage = mDamagingSectorsOriginalLeak[i];
    }
  }

  private void disableDamageLeak()
  {
    int sectorsCount = mDamagingSectorsIndices.size();
    for (int i = 0; i < sectorsCount; ++i)
    {
      Sector aSector = level.sectors[mDamagingSectorsIndices[i]];
      aSector.leakyDamage = 0;
    }
  }

  private string getDamageInformation()
  {
    if (!mDamageDetectionEnabled) return "";

    let player = players[consolePlayer].mo;
    if (player == NULL) return "";

    FLineTraceData trace;
    player.lineTrace(player.angle, RANGE, player.pitch, offsetz: player.viewHeight, data: trace);
    if (trace.hitType != FLineTraceData.TRACE_HitFloor || trace.hitSector == NULL) return "";

    int originalDamageAmount = 0;
    bool isOriginalDamageAmount = true;
    int sectorsCount = mDamagingSectorsIndices.size();
    for (int i = 0; i < sectorsCount; ++i)
    {
      Sector aSector = level.sectors[mDamagingSectorsIndices[i]];
      if (trace.hitSector.index() != aSector.index()) continue;

      originalDamageAmount = mDamagingSectorsOriginalDamage[i];
      isOriginalDamageAmount = (aSector.damageAmount == originalDamageAmount);
      break;
    }

    return isOriginalDamageAmount ?
      string.format( StringTable.localize("$FM_DAMAGE"), originalDamageAmount) :
      string.format( StringTable.localize("$FM_DAMAGE_ORIGINAL")
                   , trace.hitSector.damageAmount
                   , originalDamageAmount
                   );
  }

  const RANGE = 1024.0;

  private bool mIsInitialized;

  private Array<int> mDamagingSectorsIndices;
  private Array<int> mDamagingSectorsOriginalDamage;
  private Array<int> mDamagingSectorsOriginalLeak;

  private bool mLastDamageLimitEnabled;
  private int  mLastDamageLimit;

  private bool mLastDamageLeakEnabled;

  private bool   mDamageDetectionEnabled;
  private string mDamageInformation;
}
