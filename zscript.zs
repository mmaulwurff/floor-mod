// SPDX-FileCopyrightText: 2022 Alexander Kromm <mmaulwurff@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

version 4.8

class fm_EventHandler : EventHandler
{
  override void WorldTick()
  {
    if (!mIsInitialized) initialize();
    if (fm_enabled != mLastEnabled || fm_damage_cap != mLastDamageCap) setEnabled();
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
    }
  }

  private void setEnabled()
  {
    mLastEnabled = fm_enabled;

    if (fm_enabled) updateDamageCap();
    else disable();
  }

  private void updateDamageCap()
  {
    mLastDamageCap = fm_damage_cap;

    int sectorsCount = mDamagingSectorsIndices.size();
    for (int i = 0; i < sectorsCount; ++i)
    {
      Sector aSector = level.sectors[mDamagingSectorsIndices[i]];
      int originalDamage = mDamagingSectorsOriginalDamage[i];
      aSector.damageAmount = min(originalDamage, fm_damage_cap);
    }
  }

  private void disable()
  {
    int sectorsCount = mDamagingSectorsIndices.size();
    for (int i = 0; i < sectorsCount; ++i)
    {
      Sector aSector = level.sectors[mDamagingSectorsIndices[i]];
      aSector.damageAmount = mDamagingSectorsOriginalDamage[i];
    }
  }

  private bool mIsInitialized;

  private Array<int> mDamagingSectorsIndices;
  private Array<int> mDamagingSectorsOriginalDamage;

  private bool mLastEnabled;
  private int mLastDamageCap;
}
