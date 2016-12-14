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

Copy & Rename the *main.swift* to folder in your PATH, for example:

`sudo cp main.swift /usr/local/bin/i1n`

## Execution
Run the *i1n* script from the root of your project:

`i1n`

Sample output:

```bash
Searching for english localization file...

	English localization file found:
  
	 /Users/ido.mizrachi/Dev/MyProject/Resources/en.lproj/Localizable.strings
   
Parsing all keys in the english localization file...

	Done
  
Search for missing keys in non-english localization files...

Finished, no missing localization entries.
```

##Demo 
You can run *i1n* on the Demo project to see it in action.

![alt text][report]

# Thanks
To <a href=http://twitter.com/catalinred>Catalin Rosu</a> for the HTML template!


[report]: https://raw.githubusercontent.com/idomizrachi/i1n/4f08ed8df166ff9d167391d2d813955d6831a715/Demo/Demo-Report.png "Report"
