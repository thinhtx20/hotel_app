$word = New-Object -ComObject Word.Application
$word.Visible = $false
try {
    $doc = $word.Documents.Open('d:\duan\hotel_app\So_Do_Kien_Truc_Luxe_Grand_Hotel.docx')
    $pages = $doc.ComputeStatistics(2)
    Write-Host "Page Count: $pages"
    $i = 1
    foreach ($s in $doc.InlineShapes) {
        Write-Host "Image ${i}: Width = $($s.Width) pt, Height = $($s.Height) pt"
        $i++
    }
    foreach ($sec in $doc.Sections) {
        $pg = $sec.PageSetup
        Write-Host "Section PageSetup: Width = $($pg.PageWidth), Height = $($pg.PageHeight), TopMargin = $($pg.TopMargin), BottomMargin = $($pg.BottomMargin), LeftMargin = $($pg.LeftMargin), RightMargin = $($pg.RightMargin)"
    }
    $doc.Close()
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
} finally {
    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
}
