$InFile = "C:\users\David\Desktop\DavesStuff\Resources\SingleHeroForParsing.txt"

function openStreams ($FilePath=$InFile) {
    if($FilePath -eq $null){
        throw [System.IO.FileNotFoundException] "$FilePath not found"
    }

    closeStreams

    $fs = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
    $bs = [System.IO.BufferedStream]::new($fs)
    $script:sr = [System.IO.StreamReader]::new($bs)
}

function closeStreams () {
    if ($fs -ne $null) {
        $fs.Dispose()
        $fs = $null
    }
    if ($bs -ne $null) {
        $bs.Dispose()
        $bs = $null
    }
    if ($sr -ne $null) {
        $sr.Dispose()
        $sr = $null
    }
}

function getNextChar([System.IO.StreamReader]$stream=$sr){
    $t = $stream.Read()
    return [char]$t 
}

$symtab = [System.Collections.Generic.List[System.Object]]::new()

openStreams

while (-not $sr.EndOfStream){
    $c = getNextChar
    switch -Regex ($c) {
        '\s' { break } #match against any whitespace, and skip it
        '{' { $symtab.Add('{'); break }
        '}' { $symtab.add('}'); break }
        '/' { if ( getNextChar -eq '/'){ $sr.ReadLine() } ; break }
        default { break }
    }

    if ($c -eq '"') {
        $buffer = ""
        do {
            $buffer += $c
            $c = getNextChar    
        } while ($c -ne '"')
        $buffer += '"'
        $symtab.Add($buffer)
    }
}

closeStreams