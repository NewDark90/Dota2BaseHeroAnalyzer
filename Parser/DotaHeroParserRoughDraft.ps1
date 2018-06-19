<######################################################################################################################
# ScriptName:
#	DotaHeroParser.ps1
# Purpose:
#	To parse the dota hero file and turn it into json
# Function:
#	First part: does lexical analysis and adds terminal symbols to the symbol table
#	Second part: uses the symbol table to parse and output to a file
# Author:
#	David Dow
# Date:
#	6/14/2018
######################################################################################################################>

$inFile = "C:\Users\David\Desktop\Dota2BaseHeroAnalyzer\Parser\unparsed_npc_heroes.txt"
$outfile = "C:\users\David\Desktop\Dota2BaseHeroAnalyzer\Parser\ParsedFile.json"

#This function is used to close the streams (filestream, bufferedstream, streamreader)
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

#This function is used to open the streams (filestream, bufferedstream, streamreader)
#of a give filepath
function openStreams ($FilePath=$InFile) {

    #if the file doesn't exist, exit
    if (-not $(test-path -path $Filepath)){
        read-host -Prompt "The file `'$filepath`' was not found. `nPress enter to exit"
        exit
    }

    #if there are already openstreams, close them
    closeStreams

    #open the streams ( now with .Net classes! )
    $fs = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
    $bs = [System.IO.BufferedStream]::new($fs)
    #change the scope of the streamreader so it can be used by other functions
    $script:sr = [System.IO.StreamReader]::new($bs)
}

#gets the utf representation of the next character in the stream,
#then typecasts it to a char and returns it 
function getNextChar([System.IO.StreamReader]$stream=$sr){
    $t = $stream.Read()
    return [char]$t 
}

#create a symbol table ( AKA a list of objects. Aren't generics great? )
$symtab = [System.Collections.Generic.List[System.Object]]::new()

#START THE LEXICAL ANALYSIS'

#call openStreams so we can gain access to the stream reader,
#and read the file one character at a time
openStreams

#do this while loop until the stream is done
while ($sr.Peek -ne -1){
    #assign the next character in the stream to a temp variable
    $c = getNextChar
    #if the variable is some sort of whitespace, break out of the loop and go to the next iteration.
    #doing this because I don't want any stinking whitespace in my symbol table.
    #also, check for c++ style single line comments (aka "//"), and get rid of them like a dirty habit
    #as well as add '{' and '}' to the symbol table
    switch -Regex ($c) {
        '\s' { break }
        #the [system.char]::Parse() dohickey is used so that the '{' and '}'
        #don't get typecast to strings when entering the symtab. A minor inconvenience really 
        '{' { $symtab.Add( [System.Char]::parse("{")); break }
        '}' { $symtab.add([System.Char]::parse("}")); break }
        '/' { if ( $(getNextChar) -eq '/'){ $sr.ReadLine() | Out-Null } ; break }
        #if nothing matches, get outta the switch case
        default { break }
    }

    #used to add strings to the symbol table
    if ($c -eq '"') {
        $buffer = ""
        do {
            $buffer += $c
            $c = getNextChar
            if ($buffer.Length -ge 100){
                error
            }    
        } while ($c -ne '"')
        $buffer += '"'
        $symtab.Add($buffer)
    }
}

#zip everything up
closeStreams

#LEXICAL ANALYSIS IS COMPLETE!

#Now it's time for some symbol table functions
#and parsing functions

#I'm treating the symbol table like a big stack.

#When getting the symbol table entry, it returns 
#the first element. 
function getSymtabEntry ($table=$symtab) {
    return $table.Item(0)
}

#I don't have any push functions on my stack,
#but I have pop functions to get rid of stuff in
#the stack. 
function popSymtab ($table=$symtab <#now with twice the memory!#>) {
    if ($table.Count -gt 0){
        $table.removeat(0)
    }
    else{
        write-output "table empty"
        write-output "exiting"
        exit
    }
}

#this function is a general purpose emitter function.
#it doesn't do newlines in the file, and it appends rather than
#overwrites. This way, I can impose some neato structure on my json.
#NOTE: I can still emit the `n (newline) character to the file, 
#and that works
function emit($out, $file=$outfile){
    Out-File -FilePath $file -InputObject $out -NoNewline -Append
}

function emittabs($tabcount){
    emit -out $( "`t" * $tabcount)
}

function emitnewline(){
    emit -out "`n"
}

#General purpose error function because I'm a hack 
function error(){
    closeStreams
    write-output "There was an error during parsing."
    write-output "Sorry if this error system is shitty."
    read-host -Prompt "Press enter to exit"
    exit
}

#PARSING TIME!

#before parsing though...
#If the output file exists:EXTERMINATE
if (test-path $outfile){
    remove-item $outfile
}

#some vars to aid in the process of parsing
$indent = 0
$stringRegex = '".*"'

#Time to talk about the boring stuff:  Grammar
#for those interested, it may make sense.
#I'm not even sure what type of grammar this is
#or even if it's a very good one.
#But I made it, and hand parsed with it.
#it seemed to work okay.
#
#GRAMMAR:
#
# props -> prop rest
# prop  -> attr val
# rest  -> prop rest | ε
# attr  -> "string"
# val   -> "string" | obj
# obj   -> { props | ε }

function props() {
    prop
    rest
}

function prop() {
    # prop -> attr val ( needs to be translated to attr:val. newlines added in val())

    #for every property, emit tabs preceeding them.
    if($indent -gt 0){
        #emittabs -tabcount $indent
    }
    
    attr
    emit -out ':'
    val
}

#Rest is used to match properties or objects of the same depth.
function rest() {
    # rest -> ε when it finds a '}'
    # go back to obj function ( obj -> { props | ε } ).
    # There are no more properties at the current nest depth to match.
    if( $(getSymtabEntry) -match "}" ){
        return
    }
    #rest -> prop rest
    #since prop starts with an attr, and attr is always going to be a string,
    #we want to make sure the next entry in the symtab is a string, or else it's an error
    elseif ( $(getSymtabEntry) -match $stringRegex ) {
        emit -out ','
        prop    #prop -> attr val and attr -> string. Let attr handle the popping of stack
        rest    #if there are more properties at the same nest depth, call again later
        return
    }
    else{
        error
    }
}

function attr() {
    if( $(getSymTabEntry) -match $stringregex ){
        emit -out $(getSymtabEntry)
        popSymTab
        return
    }
    else{
        error
    }
}

function val(){
    #val -> string | obj
    #if it matches a string regex, act accordingly
    #otherwise, treat it as an object.
    #if all else fails, it's an error
    if( $(getSymtabEntry) -match $stringRegex ){
        emit -out $(getSymtabEntry)
        popSymtab
    }
    elseif ( $(getSymTabEntry -match '{')){
        obj
    }
    else{
        error 
    }
}

#TODO: Figure this out later
function obj(){
    #obj -> { props | ε }
    #obj needs to match the top of the stack to '{', or it's an error.
    #then, it needs to pop, and look at the next item
    #in the stack. If it's a }, then the object is empty.
    #if it's a string, then it should call props. 
    #props -> prop rest, prop -> attr val, attr -> string.
    #this means that if it's not a string or }, it should be
    #an error.
    if( $(getSymtabEntry) -match '{'){
        emit -out '{'
        popSymtab

        #obj -> { ε }
        if ( $(getSymtabEntry) -match '}' ){
            emitnewline
            emittabs -tabcount $indent
            emit -out '}'
            popSymtab
            return
        }
        #obj -> { props }
        elseif ( $(getSymtabEntry) -match $stringRegex ) {
            props
            if ( $(getSymtabEntry) -match '}' ){
                emit -out '}'
                popsymtab
                return
            }
            else{
                error
            }
        }
        else{
            error
        }
    }
    else{
        error
    }
}

#When trying out a json validator, it liked
#everything wrapped around {},
#so this calls the inital state parse function which
#will call all the rest of the parse functions, and
#wrap all the output in {}
emit -out '{'
props
emit -out '}'