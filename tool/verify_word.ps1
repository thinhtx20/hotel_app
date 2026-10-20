$word = New-Object -ComObject Word.Application
$word.Visible = $false
try {
    $doc = $word.Documents.Open('d:\duan\hotel_app\So_Do_Kien_Truc_Luxe_Grand_Hotel.docx')
    Write-Host "SUCCESS: Opened cleanly!"
    Write-Host "Paragraph Count: $($doc.Paragraphs.Count)"
    Write-Host "Inline Shapes: $($doc.InlineShapes.Count)"
    Write-Host "Tables: $($doc.Tables.Count)"
    $doc.Close()
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
} finally {
    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
}
