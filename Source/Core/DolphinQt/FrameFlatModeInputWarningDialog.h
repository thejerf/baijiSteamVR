// Copyright 2026 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QDialog>

class QCheckBox;
class QWidget;

class FrameFlatModeInputWarningDialog final : public QDialog
{
  Q_OBJECT

public:
  static void ShowUnlessDisabled(QWidget* parent = nullptr);

private:
  explicit FrameFlatModeInputWarningDialog(QWidget* parent = nullptr);

  QCheckBox* m_never_show_again = nullptr;
};
