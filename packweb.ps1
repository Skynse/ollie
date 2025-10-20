flutter build web --release
cd build/web
$HASH = (Get-FileHash main.dart.js -Algorithm MD5).Hash.ToLower()
Rename-Item -Path main.dart.js -NewName main.$HASH.dart.js
Rename-Item -Path flutter_bootstrap.js -NewName flutter_bootstrap.$HASH.js

# Update references in index.html
(Get-Content index.html) -replace 'main.dart.js', "main.$HASH.dart.js" | Set-Content index.html
(Get-Content index.html) -replace 'flutter_bootstrap.js', "flutter_bootstrap.$HASH.js" | Set-Content index.html

# Update main.dart.js reference in flutter_bootstrap
(Get-Content flutter_bootstrap.$HASH.js) -replace 'main.dart.js', "main.$HASH.dart.js" | Set-Content flutter_bootstrap.$HASH.js

# Add version.json
$timestamp = Get-Date -UFormat %s
Set-Content -Path version.json -Value "{\""version\"": \""$timestamp\""}"
vercel deploy --prod
