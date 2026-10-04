// Copyright 2016 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "DolphinQt/AboutDialog.h"

#include <QLabel>
#include <QTextEdit>
#include <QVBoxLayout>
#include <QtGlobal>

#include "Common/Version.h"

#include "DolphinQt/Resources.h"

AboutDialog::AboutDialog(QWidget* parent) : QDialog(parent)
{
  setWindowTitle(tr("About BaijiSteamVR"));

  const QString text =
      QStringLiteral(R"(
<p style='font-size:38pt; font-weight:400;'>BaijiSteamVR</p>

<p style='font-size:18pt;'>%VERSION%</p>

<p>
BaijiSteamVR is a free and open-source GameCube and Wii emulator.
</p>

<p>
<a href='https://github.com/thejerf/baijiSteamVR'>BaijiSteamVR project page</a>
</p>

<p>
Licensed under GPL-2.0-or-later. See COPYING and LICENSES in the installation for license texts.
)")
          .replace(QStringLiteral("%VERSION%"),
                   QString::fromUtf8(Common::GetScmDescStr().c_str()));

  QLabel* text_label = new QLabel(text);
  text_label->setTextInteractionFlags(Qt::TextBrowserInteraction);
  text_label->setOpenExternalLinks(true);

  QLabel* copyright = new QLabel(
      QStringLiteral("<small>%1</small>")
          .arg(
              // i18n: This message uses curly quotes in English. If you want to use curly quotes
              // in your translation, please use the type of curly quotes that's appropriate for
              // your language. If you aren't sure which type is appropriate, see
              // https://en.wikipedia.org/wiki/Quotation_mark#Specific_language_features
               tr("\u00A9 2003-2024+ Dolphin Team. \u201cGameCube\u201d and \u201cWii\u201d are "
                  "trademarks of Nintendo. BaijiSteamVR is not affiliated with Nintendo.")));

  QLabel* logo = new QLabel();
  logo->setPixmap(Resources::GetAppIcon().pixmap(200, 200));
  logo->setContentsMargins(30, 0, 30, 0);

  QVBoxLayout* main_layout = new QVBoxLayout;
  QHBoxLayout* h_layout = new QHBoxLayout;

  setLayout(main_layout);
  main_layout->setSizeConstraint(QLayout::SetFixedSize);
  main_layout->addLayout(h_layout);
  main_layout->addWidget(copyright);
  copyright->setAlignment(Qt::AlignCenter);
  copyright->setContentsMargins(0, 15, 0, 0);

  h_layout->setAlignment(Qt::AlignLeft);
  h_layout->addWidget(logo);
  h_layout->addWidget(text_label);
}
