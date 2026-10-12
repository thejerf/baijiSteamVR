// Copyright 2020 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "DolphinQt/Config/ToolTipControls/BalloonTip.h"

#include <algorithm>
#include <cstdlib>
#include <memory>

#include <QApplication>
#include <QBitmap>
#include <QBrush>
#include <QCursor>
#include <QFont>
#include <QLabel>
#include <QPainter>
#include <QPainterPath>
#include <QPen>
#include <QPoint>
#include <QRect>
#include <QSize>
#include <QString>
#include <QVBoxLayout>

#if defined(__APPLE__)
#include <QToolTip>
#endif

#include "DolphinQt/QtUtils/QueueOnObject.h"
#include "DolphinQt/Settings.h"

namespace
{
std::unique_ptr<BalloonTip> s_the_balloon_tip = nullptr;
// Remember the parent ToolTipWidget so cursor-related events can see whether the cursor is inside
// the parent's bounding box or not. Use this variable instead of BalloonTip's parent() member
// because the ToolTipWidget isn't responsible for deleting the BalloonTip and so doesn't set its
// parent member.
QWidget* s_parent = nullptr;
}  // namespace

void BalloonTip::ShowBalloon(const QString& title, const QString& message,
                             const QPoint& target_arrow_tip_position,
                             const QRect& target_widget_rect_global, QWidget* const parent,
                             const ShowArrow show_arrow, const int border_width)
{
  HideBalloon();
  if (message.isEmpty() && title.isEmpty())
    return;

#if defined(__APPLE__)
  (void)target_widget_rect_global;
  QString the_message = message;
  the_message.replace(QStringLiteral("<dolphin_emphasis>"), QStringLiteral("<b>"));
  the_message.replace(QStringLiteral("</dolphin_emphasis>"), QStringLiteral("</b>"));
  QToolTip::showText(target_arrow_tip_position, the_message, parent);
#else
  s_the_balloon_tip =
      std::make_unique<BalloonTip>(PrivateTag{}, title, message, parent, border_width);
  s_the_balloon_tip->UpdateBoundsAndRedraw(target_arrow_tip_position, target_widget_rect_global,
                                           show_arrow, border_width);
#endif
}

void BalloonTip::HideBalloon()
{
  s_parent = nullptr;
#if defined(__APPLE__)
  QToolTip::hideText();
#else
  if (s_the_balloon_tip == nullptr)
    return;
  s_the_balloon_tip->hide();
  s_the_balloon_tip.reset();
#endif
}

BalloonTip::BalloonTip(PrivateTag, const QString& title, QString message, QWidget* const parent,
                       const int border_width)
    : QWidget(nullptr, Qt::ToolTip)
{
  s_parent = parent;
  setMouseTracking(true);

  const QWidget* const owner_window = parent->window();
  m_owner_rect = QRect(owner_window->mapToGlobal(QPoint(0, 0)), owner_window->size());

  QColor window_color;
  QColor text_color;
  QColor dolphin_emphasis;
  Settings::Instance().GetToolTipStyle(window_color, text_color, dolphin_emphasis, m_border_color,
                                       parent->palette(), palette());
  const auto style_sheet = QStringLiteral("background-color: #%1; color: #%2;")
                               .arg(window_color.rgba(), 0, 16)
                               .arg(text_color.rgba(), 0, 16);
  setStyleSheet(style_sheet);

  // Replace text in our our message if specific "tags" are used
  message.replace(QStringLiteral("<dolphin_emphasis>"),
                  QStringLiteral("<font color=\"#%1\"><b>").arg(dolphin_emphasis.rgba(), 0, 16));
  message.replace(QStringLiteral("</dolphin_emphasis>"), QStringLiteral("</b></font>"));

  auto* const balloontip_layout = new QVBoxLayout;
  balloontip_layout->setSizeConstraint(QLayout::SetNoConstraint);
  setLayout(balloontip_layout);

  const float border_half_width = border_width / 2.0;
  const int rounded_corner_margin = border_half_width / 4;
  const int horizontal_margin = border_width + rounded_corner_margin + 12;
  const int bounded_horizontal_margin =
      std::min(horizontal_margin, std::max(0, (m_owner_rect.width() - 1) / 2));
  const int max_width = std::max(1, m_owner_rect.width() - 2 * bounded_horizontal_margin);
  const int vertical_margin = bounded_horizontal_margin + 18;
  balloontip_layout->setContentsMargins(bounded_horizontal_margin, vertical_margin,
                                        bounded_horizontal_margin, vertical_margin);

  const auto create_label = [=](const QString& text) {
    QLabel* const label = new QLabel;
    balloontip_layout->addWidget(label);

    label->setText(text);
    label->setTextFormat(Qt::RichText);

    label->setMaximumWidth(max_width);

    if (label->sizeHint().width() > max_width)
    {
      label->setWordWrap(true);
      label->setMinimumWidth(max_width);
    }

    return label;
  };

  if (!title.isEmpty())
  {
    QLabel* const title_label = create_label(title);

    QFont title_font = title_label->font();
    title_font.setBold(true);
    title_label->setFont(title_font);
  }

  if (!message.isEmpty())
    create_label(message);
}

bool BalloonTip::IsCursorInsideWidgetBoundingBox(const QWidget& widget)
{
  const QPoint local_cursor_position = widget.mapFromGlobal(QCursor::pos());
  return widget.rect().contains(local_cursor_position);
}

bool BalloonTip::IsCursorOnBalloonTip()
{
  return s_the_balloon_tip != nullptr &&
         QApplication::widgetAt(QCursor::pos()) == s_the_balloon_tip.get();
}

bool BalloonTip::IsWidgetBalloonTipActive(const QWidget& widget)
{
  return &widget == s_parent;
}

// Hiding the balloon causes the BalloonTip widget to be deleted. Triggering that deletion while
// inside a BalloonTip event handler leads to a use-after-free crash or worse, so queue the deletion
// for later.
static void QueueHideBalloon()
{
  QueueOnObject(s_parent, BalloonTip::HideBalloon);
}

void BalloonTip::enterEvent(QEnterEvent* const event)
{
  if (!IsCursorInsideWidgetBoundingBox(*s_parent))
    QueueHideBalloon();

  QWidget::enterEvent(event);
}

void BalloonTip::mouseMoveEvent(QMouseEvent* const event)
{
  if (!IsCursorInsideWidgetBoundingBox(*s_parent))
    QueueHideBalloon();

  QWidget::mouseMoveEvent(event);
}

void BalloonTip::leaveEvent(QEvent* const event)
{
  if (QApplication::widgetAt(QCursor::pos()) != s_parent)
    QueueHideBalloon();

  QWidget::leaveEvent(event);
}

void BalloonTip::paintEvent(QPaintEvent* const event)
{
  QPainter painter(this);
  painter.drawPixmap(rect(), m_pixmap);

  QWidget::paintEvent(event);
}

void BalloonTip::UpdateBoundsAndRedraw(const QPoint& target_arrow_tip_position,
                                       const QRect& target_widget_rect_global,
                                       const ShowArrow show_arrow, const int border_full_width)
{
  const float border_half_width = border_full_width / 2.0;

  // This should be odd so that the arrow tip is a single pixel wide.
  constexpr int preferred_arrow_full_width = 35;

  // Distance between the label layout and the inner rectangle border edge
  constexpr int balloon_interior_padding = 12;
  // Prevent the corners of the label layout from portruding into the rounded rectangle corners at
  // larger border sizes.
  const int rounded_corner_margin = border_half_width / 4;
  const int nominal_horizontal_margin =
      border_full_width + rounded_corner_margin + balloon_interior_padding;
  const int horizontal_margin =
      std::min(nominal_horizontal_margin, std::max(0, (m_owner_rect.width() - 1) / 2));
  const int preferred_arrow_height = (1 + preferred_arrow_full_width) / 2;
  const int vertical_margin = horizontal_margin + preferred_arrow_height;

  // Create enough space around the layout containing the title and message to draw the balloon and
  // both arrow tips (at most one of which will be visible)
  layout()->setContentsMargins(horizontal_margin, vertical_margin, horizontal_margin,
                               vertical_margin);

  QSize size_hint = sizeHint();
  size_hint.setWidth(std::min(size_hint.width(), m_owner_rect.width()));
  size_hint.setHeight(std::min(size_hint.height(), m_owner_rect.height()));

  // Keep the balloon beside its target, choosing the side with more room if it must be clipped.
  const int space_above = std::max(0, target_widget_rect_global.top() - m_owner_rect.top());
  const int space_below =
      std::max(0, m_owner_rect.bottom() - target_widget_rect_global.bottom());
  const bool arrow_at_bottom =
      size_hint.height() <= space_above ||
      (size_hint.height() > space_below && space_above >= space_below);
  const int available_height = arrow_at_bottom ? space_above : space_below;
  size_hint.setHeight(std::min(size_hint.height(), std::max(1, available_height)));

  // The content layout may prefer a larger size, but the visible tooltip is always bounded by its
  // owning window.
  setMaximumSize(m_owner_rect.size());
  resize(size_hint);

  // Reduce the arrow with the available height/width so even unusually small windows have a
  // non-negative rounded-rectangle area.
  int arrow_full_width =
      show_arrow == ShowArrow::Yes ?
          std::min(preferred_arrow_full_width, size_hint.width() - border_full_width) :
          0;
  if (arrow_full_width > 0 && arrow_full_width % 2 == 0)
    --arrow_full_width;
  const int max_arrow_height = std::max(0, (size_hint.height() - border_full_width - 1) / 2);
  const int max_arrow_width = max_arrow_height > 0 ? 2 * max_arrow_height - 1 : 0;
  arrow_full_width = std::max(0, std::min(arrow_full_width, max_arrow_width));
  const float arrow_half_width = arrow_full_width / 2.0;
  // The y distance between the inner edge of the rectangle border and the inner tip of the arrow
  // border, and also the distance between the outer edge of the rectangle border and the outer tip
  // of the arrow border.
  const int arrow_height = (1 + arrow_full_width) / 2;

  // These positions represent the middle of each edge of the BalloonTip's rounded rectangle
  const float rect_width = std::max(0, size_hint.width() - border_full_width);
  const float rect_height =
      std::max(0, size_hint.height() - border_full_width - 2 * arrow_height);
  const float rect_top = border_half_width + arrow_height;
  const float rect_bottom = rect_top + rect_height;
  const float rect_left = border_half_width;
  // rect_right isn't used for anything

  // Qt defines the radius of a rounded rectangle as "the radius of the ellipses defining the
  // corner". Unlike the rectangle's edges this corresponds to the outside of the rounded curve
  // instead of its middle, so we add the full width to the inner radius instead of the half width
  const float corner_base_inner_radius = 7.0;
  const float corner_outer_radius = corner_base_inner_radius + border_full_width;

  // This value is arbitrary but works well.
  const int base_arrow_x_offset = 34;
  // Adjust the offset inward to compensate for the border and rounded corner widths. This ensures
  // the arrow is on the flat part of the top/bottom border.
  const int adjusted_arrow_x_offset =
      base_arrow_x_offset + border_full_width + static_cast<int>(border_half_width);
  // If the border is wide enough (or the BalloonTip small enough) the offset might end up past the
  // midpoint; if that happens just use the midpoint instead
  const int centered_arrow_x_offset = (size_hint.width() - arrow_full_width) / 2;
  // If the arrow is on the left this is the distance between the left edge of the BalloonTip and
  // the left edge of the arrow interior; otherwise the distance between the right edges.
  const int arrow_nearest_edge_x_offset =
      std::min(adjusted_arrow_x_offset, centered_arrow_x_offset);
  const int left_arrow_tip_x = static_cast<int>(arrow_nearest_edge_x_offset + arrow_half_width);
  const int right_arrow_tip_x =
      static_cast<int>(size_hint.width() - arrow_nearest_edge_x_offset - arrow_full_width +
                       arrow_half_width);
  const int rightmost_valid_x =
      std::max(m_owner_rect.left(), m_owner_rect.right() - size_hint.width() + 1);
  const int left_arrow_window_x = std::clamp(target_arrow_tip_position.x() - left_arrow_tip_x,
                                             m_owner_rect.left(), rightmost_valid_x);
  const int right_arrow_window_x = std::clamp(target_arrow_tip_position.x() - right_arrow_tip_x,
                                              m_owner_rect.left(), rightmost_valid_x);
  const int left_arrow_error =
      std::abs(left_arrow_window_x + left_arrow_tip_x - target_arrow_tip_position.x());
  const int right_arrow_error =
      std::abs(right_arrow_window_x + right_arrow_tip_x - target_arrow_tip_position.x());
  const bool arrow_at_left = left_arrow_error <= right_arrow_error;
  const int actual_balloontip_global_x = arrow_at_left ? left_arrow_window_x : right_arrow_window_x;

  QPainterPath rect_path;
  if (rect_width > 0 && rect_height > 0)
  {
    rect_path.addRoundedRect(rect_left, rect_top, rect_width, rect_height, corner_outer_radius,
                             corner_outer_radius);
  }

  // The default pen cap style Qt::SquareCap extends drawn lines one half width before the starting
  // point and one half width after the ending point such that the starting and ending points are
  // surrounded by drawn pixels in both dimensions instead of just for the width. This is a
  // reasonable default but we need to draw lines precisely, and this behavior causes problems when
  // drawing lines of length and width 1 (which we do for the arrow interior, and also the arrow
  // border when border_full_width is 1). For those lines to correctly end up as a pixel we would
  // need to offset the start and end points by 0.5 inward. However, doing that would lead them to
  // be at the same point, and if the endpoints of a line are the same Qt simply doesn't draw it
  // regardless of the cap style.
  //
  // Using Qt::FlatCap instead fixes the issue.

  m_pixmap = QPixmap(size_hint);

  QPen border_pen(m_border_color, border_full_width);
  border_pen.setCapStyle(Qt::FlatCap);

  QPainter balloon_painter(&m_pixmap);
  balloon_painter.setPen(border_pen);
  balloon_painter.setBrush(palette().color(QPalette::Window));
  balloon_painter.drawPath(rect_path);

  QBitmap mask_bitmap(size_hint);
  mask_bitmap.fill(Qt::color0);

  QPen mask_pen(Qt::color1, border_full_width);
  mask_pen.setCapStyle(Qt::FlatCap);

  QPainter mask_painter(&mask_bitmap);
  mask_painter.setPen(mask_pen);
  mask_painter.setBrush(QBrush(Qt::color1));
  mask_painter.drawPath(rect_path);

  const float arrow_base_y =
      arrow_at_bottom ? rect_bottom - border_half_width : rect_top + border_half_width;

  const float arrow_tip_vertical_offset = arrow_at_bottom ? arrow_height : -arrow_height;
  const float arrow_tip_interior_y = arrow_base_y + arrow_tip_vertical_offset;
  const float arrow_base_left_edge_x =
      arrow_at_left ? arrow_nearest_edge_x_offset :
                      size_hint.width() - arrow_nearest_edge_x_offset - arrow_full_width;
  const float arrow_base_right_edge_x = arrow_base_left_edge_x + arrow_full_width;
  const float arrow_tip_x = arrow_base_left_edge_x + arrow_half_width;

  if (show_arrow == ShowArrow::Yes && arrow_full_width > 0)
  {
    // Drawing diagonal lines in Qt is filled with edge cases and inexplicable behavior. Getting it
    // to do what you want at one border size is simple enough, but doing so flexibly is an exercise
    // in futility. Some examples:
    // * For some values of x, diagonal lines of width x and x+1 are drawn exactly the same.
    // * When drawing a triangle where p1 and p3 have exactly the same y value, they can be drawn at
    // different heights.
    // * Lines of width 1 sometimes get drawn one pixel past where they should even with FlatCap,
    // but only on the left side (regardless of which direction the stroke was).
    //
    // Instead of dealing with all that, fake it with vertical lines which are much better behaved.
    // Draw a bunch of vertical lines with width 1 to form the arrow border and interior.

    QPainterPath arrow_border_path;
    QPainterPath arrow_interior_fill_path;
    const float y_end_offset = arrow_at_bottom ? border_full_width : -border_full_width;

    // Draw the arrow border and interior lines from the outside inward. Each loop iteration draws
    // one pair of border lines and one pair of interior lines.
    for (int i = 1; i <= arrow_half_width; i++)
    {
      const float x_offset_from_arrow_base_edge = i - 0.5;
      const float border_y_start = arrow_base_y + (arrow_at_bottom ? i : -i);
      const float border_y_end = border_y_start + y_end_offset;
      const float interior_y_start = arrow_base_y;
      const float interior_y_end = border_y_start;
      const float left_line_x = arrow_base_left_edge_x + x_offset_from_arrow_base_edge;
      const float right_line_x = arrow_base_right_edge_x - x_offset_from_arrow_base_edge;

      arrow_border_path.moveTo(left_line_x, border_y_start);
      arrow_border_path.lineTo(left_line_x, border_y_end);

      arrow_border_path.moveTo(right_line_x, border_y_start);
      arrow_border_path.lineTo(right_line_x, border_y_end);

      arrow_interior_fill_path.moveTo(left_line_x, interior_y_start);
      arrow_interior_fill_path.lineTo(left_line_x, interior_y_end);

      arrow_interior_fill_path.moveTo(right_line_x, interior_y_start);
      arrow_interior_fill_path.lineTo(right_line_x, interior_y_end);
    }
    // The middle border line
    arrow_border_path.moveTo(arrow_tip_x, arrow_tip_interior_y);
    arrow_border_path.lineTo(arrow_tip_x, arrow_tip_interior_y + y_end_offset);

    // The middle interior line
    arrow_interior_fill_path.moveTo(arrow_tip_x, arrow_base_y);
    arrow_interior_fill_path.lineTo(arrow_tip_x, arrow_tip_interior_y);

    border_pen.setWidth(1);

    balloon_painter.setPen(border_pen);
    balloon_painter.drawPath(arrow_border_path);

    QPen arrow_interior_fill_pen(palette().color(QPalette::Window), 1);
    arrow_interior_fill_pen.setCapStyle(Qt::FlatCap);
    balloon_painter.setPen(arrow_interior_fill_pen);
    balloon_painter.drawPath(arrow_interior_fill_path);

    mask_pen.setWidth(1);
    mask_painter.setPen(mask_pen);

    mask_painter.drawPath(arrow_border_path);
    mask_painter.drawPath(arrow_interior_fill_path);
  }

  setMask(mask_bitmap);

  // Anchor the popup edge to the source widget edge selected for this side, so its border doesn't
  // cut through the widget.
  const int preferred_balloontip_global_y =
      arrow_at_bottom ? target_widget_rect_global.top() - size_hint.height() :
                        target_widget_rect_global.bottom() + 1;
  const int lowest_valid_y =
      std::max(m_owner_rect.top(), m_owner_rect.bottom() - size_hint.height() + 1);
  const int actual_balloontip_global_y =
      std::clamp(preferred_balloontip_global_y, m_owner_rect.top(), lowest_valid_y);

  move(actual_balloontip_global_x, actual_balloontip_global_y);

  show();
}
