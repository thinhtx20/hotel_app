# Chuẩn bị hình minh họa lấy từ báo cáo UI/UX cho báo cáo BTL KT&TKPM:
# - cắt viền trắng các sơ đồ User Flow
# - ghép ảnh chụp màn hình ứng dụng thành từng hình theo vai trò, có nhãn dưới mỗi màn
# Đầu vào: thư mục ảnh trích từ PDF (img_<objectId>.png/jpg). Đầu ra: docs/bai_tap_lon_ktpm/hinh
param(
  [Parameter(Mandatory = $true)][string]$SourceDir,
  [string]$OutDir = (Join-Path $PSScriptRoot '..\..\docs\bai_tap_lon_ktpm\hinh')
)
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class ImgTrim {
  // Trả về khung chứa nội dung (bỏ viền gần trắng), có chừa lề pad px
  public static Rectangle ContentBounds(Bitmap bmp, int threshold, int pad) {
    var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
    var data = bmp.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format24bppRgb);
    int stride = data.Stride; var buf = new byte[stride * bmp.Height];
    Marshal.Copy(data.Scan0, buf, 0, buf.Length); bmp.UnlockBits(data);
    int minX = bmp.Width, minY = bmp.Height, maxX = -1, maxY = -1;
    for (int y = 0; y < bmp.Height; y++) for (int x = 0; x < bmp.Width; x++) {
      int i = y * stride + x * 3;
      if (buf[i] < threshold || buf[i + 1] < threshold || buf[i + 2] < threshold) {
        if (x < minX) minX = x; if (x > maxX) maxX = x; if (y < minY) minY = y; if (y > maxY) maxY = y;
      }
    }
    if (maxX < 0) return rect;
    minX = Math.Max(0, minX - pad); minY = Math.Max(0, minY - pad);
    maxX = Math.Min(bmp.Width - 1, maxX + pad); maxY = Math.Min(bmp.Height - 1, maxY + pad);
    return new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
  }
}
'@

New-Item -ItemType Directory -Force $OutDir | Out-Null

function Save-Trimmed($src, $dest) {
  $img = New-Object System.Drawing.Bitmap (Join-Path $SourceDir $src)
  $r = [ImgTrim]::ContentBounds($img, 235, 12)
  $crop = $img.Clone($r, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $crop.Save((Join-Path $OutDir $dest), [System.Drawing.Imaging.ImageFormat]::Png)
  $crop.Dispose(); $img.Dispose()
}

function Save-Montage($items, $dest) {
  $h = 900; $gap = 36; $labelH = 70
  $imgs = $items | ForEach-Object { [System.Drawing.Image]::FromFile((Join-Path $SourceDir $_[0])) }
  $widths = $imgs | ForEach-Object { [int]($_.Width * $h / $_.Height) }
  $total = [int](($widths | Measure-Object -Sum).Sum + $gap * ($imgs.Count + 1))
  $bmp = New-Object System.Drawing.Bitmap -ArgumentList $total, ([int]($h + $labelH + $gap))
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::White)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $font = New-Object System.Drawing.Font('Arial', 22, [System.Drawing.FontStyle]::Bold)
  $fmt = New-Object System.Drawing.StringFormat; $fmt.Alignment = 'Center'
  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200, 205, 212)), 2
  $x = $gap
  for ($i = 0; $i -lt $imgs.Count; $i++) {
    $g.DrawImage($imgs[$i], $x, $gap / 2, $widths[$i], $h)
    $g.DrawRectangle($pen, $x, $gap / 2, $widths[$i], $h)
    $label = $items[$i][1]
    $g.DrawString($label, $font, [System.Drawing.Brushes]::Black, (New-Object System.Drawing.RectangleF ($x - $gap / 2), ($h + $gap / 2 + 14), ($widths[$i] + $gap), $labelH), $fmt)
    $x += $widths[$i] + $gap
  }
  $bmp.Save((Join-Path $OutDir $dest), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose(); $imgs | ForEach-Object { $_.Dispose() }
}

Save-Trimmed 'img_28.png' 'userflow_1_dat_phong.png'
Save-Trimmed 'img_31.png' 'userflow_2_luu_tru.png'
Save-Trimmed 'img_35.png' 'userflow_3_ca_truc.png'
Copy-Item (Join-Path $SourceDir 'img_8.png') (Join-Path $OutDir 'khach_san_luxe_grand.png') -Force

Save-Montage @(@('img_39.jpg', 'a) Trang chủ – tìm phòng'), @('img_40.jpg', 'b) Chi tiết phòng'), @('img_61.jpg', 'c) Xác nhận đặt phòng'), @('img_65.jpg', 'd) Chuyến đi của tôi')) 'man_hinh_khach_hang.png'
Save-Montage @(@('img_49.jpg', 'a) Sơ đồ phòng'), @('img_70.jpg', 'b) Nhận phòng hôm nay'), @('img_79.png', 'c) Đổi phòng'), @('img_69.jpg', 'd) Trả phòng hôm nay')) 'man_hinh_le_tan.png'
Save-Montage @(@('img_80.png', 'a) Chi tiết hóa đơn'), @('img_82.png', 'b) Ghi nhận thu tiền'), @('img_71.jpg', 'c) Mở ca trực'), @('img_72.jpg', 'd) Chốt ca & bàn giao')) 'man_hinh_thu_ngan_ca_truc.png'
Save-Montage @(@('img_66.jpg', 'a) Hóa đơn của tôi (khách)'), @('img_52.jpg', 'b) Báo cáo quản trị'), @('img_53.jpg', 'c) Doanh thu & ca trực')) 'man_hinh_hoa_don_quan_tri.png'

# Ảnh từng màn hình cho Chương 4 của báo cáo tốt nghiệp (dấu phẩy đơn ngôi giữ mảng một phần tử)
Save-Montage @(, @('img_39.jpg', 'Trang chủ – tìm phòng')) 'tn_trang_chu.png'
Save-Montage @(@('img_40.jpg', 'a) Ảnh & thông tin phòng'), @('img_41.jpg', 'b) Điểm nổi bật, tiện nghi'), @('img_42.jpg', 'c) Tiện nghi chi tiết'), @('img_48.jpg', 'd) Đánh giá của khách')) 'tn_chi_tiet_phong.png'
Save-Montage @(@('img_61.jpg', 'a) Thông tin đặt phòng'), @('img_62.jpg', 'b) Tổng tiền & tiền cọc')) 'tn_xac_nhan_dat_phong.png'
Save-Montage @(@('img_65.jpg', 'a) Đơn đặt phòng của tôi'), @('img_66.jpg', 'b) Hóa đơn của tôi')) 'tn_don_va_hoa_don.png'
Save-Montage @(, @('img_49.jpg', 'Sơ đồ phòng theo tầng')) 'tn_so_do_phong.png'
Save-Montage @(@('img_70.jpg', 'a) Nhận phòng hôm nay'), @('img_69.jpg', 'b) Trả phòng hôm nay')) 'tn_luot_khach_hom_nay.png'
Save-Montage @(, @('img_79.png', 'Đổi phòng cho khách')) 'tn_doi_phong.png'
Save-Montage @(@('img_80.png', 'a) Bảng kê hóa đơn'), @('img_81.png', 'b) Sổ thu tiền của hóa đơn'), @('img_82.png', 'c) Ghi nhận thu tiền')) 'tn_hoa_don_thu_tien.png'
Save-Montage @(@('img_71.jpg', 'a) Mở ca trực'), @('img_72.jpg', 'b) Chốt ca & bàn giao')) 'tn_ca_truc.png'
Save-Montage @(@('img_52.jpg', 'a) KPI hôm nay'), @('img_53.jpg', 'b) Ca trực, doanh thu 7 ngày, cơ cấu buồng phòng')) 'tn_dashboard.png'
Get-ChildItem $OutDir | Select-Object Name, Length
