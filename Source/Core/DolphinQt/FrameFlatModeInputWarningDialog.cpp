// Copyright 2026 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "DolphinQt/FrameFlatModeInputWarningDialog.h"

#include <QCheckBox>
#include <QDialogButtonBox>
#include <QLabel>
#include <QVBoxLayout>

#include "Common/Config/Config.h"
#include "Core/Config/MainSettings.h"
#include "DolphinQt/Resources.h"

void FrameFlatModeInputWarningDialog::ShowUnlessDisabled(QWidget* parent)
{
  if (Config::Get(Config::MAIN_SKIP_FLAT_MODE_INPUT_WARNING))
    return;

  FrameFlatModeInputWarningDialog dialog(parent);
  if (dialog.exec() == QDialog::Accepted && dialog.m_never_show_again->isChecked())
    Config::SetBase(Config::MAIN_SKIP_FLAT_MODE_INPUT_WARNING, true);
}

FrameFlatModeInputWarningDialog::FrameFlatModeInputWarningDialog(QWidget* parent) : QDialog(parent)
{
  setWindowTitle(tr("Flat-Mode Input Reminder"));
  setWindowIcon(Resources::GetAppIcon());

  auto* const layout = new QVBoxLayout(this);
  auto* const reminder = new QLabel(
      tr("Remember, you must click out of laser pointing mode before trying to control the game! "
         "Otherwise the game will seem like it has no controls."),
      this);
  reminder->setWordWrap(true);
  layout->addWidget(reminder);

  m_never_show_again = new QCheckBox(tr("Never See This Dialog Again"), this);
  layout->addWidget(m_never_show_again);

  auto* const buttons = new QDialogButtonBox(QDialogButtonBox::Ok, this);
  connect(buttons, &QDialogButtonBox::accepted, this, &QDialog::accept);
  layout->addWidget(buttons);
}
