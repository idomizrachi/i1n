# i1n - The safe way to heavenly localization 
i1n will scan your Xcode project and compare the keys in your english localization file
to all other available languages.
The result is a report with all keys available in for english but missing for other languages.

**This project is still in early stages.**

## Requirements 
This is a swift script file written in Swift 3, and assume you have Xcode 8 installed.

## Installation
Add execution permissions to the *main.swift*:
`chmod +x main.swift`

Copy & Rename the main.swift to folder in your PATH, for example:
`sudo cp main.swift /usr/local/bin/i1n`

