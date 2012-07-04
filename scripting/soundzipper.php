<?php

// Adding files to a .zip file, no zip file exists it creates a new ZIP file

// increase script timeout value
ini_set('max_execution_time', 5000);

echo "<title>TF2 Zip Sounds Creator</title>";

// create object
$zip = new ZipArchive();

// open archive 
if ($zip->open('rbtf2sounds.zip', ZIPARCHIVE::CREATE) !== TRUE) {
    die ("Could not open archive");
}

// initialize an iterator
// pass it the directory to be processed
$iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator("server/sound/"));

// iterate over the directory
// add each file found to the archive
while($iterator->valid()) {

    $key = $iterator->key();
    if (!$iterator->isDot()) {
        $zip->addFile(realpath($iterator->key()), "sound/".$iterator->getSubPathName()) or die ("ERROR: Could not add file: $key");
    }

    $iterator->next();
}

// close and save archive
$zip->close();
echo "Zip created!";
?>
