$word = New-Object -ComObject Word.Application
$word.Visible = $false
try {
    $doc = $word.Documents.Open('d:\duan\hotel_app\So_Do_Kien_Truc_Luxe_Grand_Hotel.docx')
    $pages = $doc.ComputeStatistics(2)
    Write-Host "Total Pages: $pages"
    
    # Check each page by selecting pages
    for ($p = 1; $p -le $pages; $p++) {
        $range = $doc.GoTo(1, 1, $p) # wdGoToPage, wdGoToAbsolute, pageNumber
        $range.End = $doc.GoTo(1, 1, [Math]::Min($p + 1, $pages)).Start
        if ($p -eq $pages) { $range.End = $doc.Content.End }
        $text = $range.Text.Trim().Replace("`r", " ").Replace("`n", " ")
        if ($text.Length -gt 100) { $text = $text.Substring(0, 100) + "..." }
        Write-Host "Page ${p} [Shapes: $($range.InlineShapes.Count), Tables: $($range.Tables.Count)]: $text"
    }
    $doc.Close()
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
} finally {
    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
}
